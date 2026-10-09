package de.datenschild.crypto;

import de.datenschild.config.AppProperties;
import org.springframework.stereotype.Service;

import javax.crypto.Cipher;
import javax.crypto.Mac;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.HexFormat;

/**
 * Verschlüsselung personenbezogener Daten (Art. 32 DSGVO).
 * E-Mail-Adressen werden mit AES-256-GCM verschlüsselt gespeichert; für Suchen
 * wird ein HMAC verwendet, damit die Klartextadresse nie im Index steht.
 */
@Service
public class CryptoService {

    private static final int IV_LENGTH = 12;
    private static final int TAG_BITS = 128;

    private final SecureRandom random = new SecureRandom();
    private final SecretKeySpec encryptionKey;
    private final SecretKeySpec macKey;

    public CryptoService(AppProperties properties) {
        String master = properties.crypto() == null ? null : properties.crypto().masterKey();
        if (master == null || master.isBlank()) {
            throw new IllegalStateException("app.crypto.master-key fehlt (APP_CRYPTO_MASTER_KEY setzen)");
        }
        byte[] masterBytes = Base64.getDecoder().decode(master);
        if (masterBytes.length < 32) {
            throw new IllegalStateException("app.crypto.master-key muss mindestens 32 Byte lang sein");
        }
        // Getrennte Schlüssel für Verschlüsselung und HMAC aus einem Master-Schlüssel ableiten
        this.encryptionKey = new SecretKeySpec(hmac(masterBytes, "datenschild-enc"), "AES");
        this.macKey = new SecretKeySpec(hmac(masterBytes, "datenschild-mac"), "HmacSHA256");
    }

    public String encrypt(String plaintext) {
        try {
            byte[] iv = new byte[IV_LENGTH];
            random.nextBytes(iv);
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.ENCRYPT_MODE, encryptionKey, new GCMParameterSpec(TAG_BITS, iv));
            byte[] encrypted = cipher.doFinal(plaintext.getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(
                    ByteBuffer.allocate(iv.length + encrypted.length).put(iv).put(encrypted).array());
        } catch (GeneralSecurityException e) {
            throw new IllegalStateException("Verschlüsselung fehlgeschlagen", e);
        }
    }

    public String decrypt(String ciphertext) {
        try {
            byte[] data = Base64.getDecoder().decode(ciphertext);
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.DECRYPT_MODE, encryptionKey, new GCMParameterSpec(TAG_BITS, data, 0, IV_LENGTH));
            return new String(cipher.doFinal(data, IV_LENGTH, data.length - IV_LENGTH), StandardCharsets.UTF_8);
        } catch (GeneralSecurityException e) {
            throw new IllegalStateException("Entschlüsselung fehlgeschlagen", e);
        }
    }

    /** Deterministischer, geheimer Hash – für Eindeutigkeit und Codes. */
    public String mac(String value) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(macKey);
            return HexFormat.of().formatHex(mac.doFinal(value.getBytes(StandardCharsets.UTF_8)));
        } catch (GeneralSecurityException e) {
            throw new IllegalStateException(e);
        }
    }

    public static String sha256(String value) {
        try {
            return HexFormat.of().formatHex(
                    MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (GeneralSecurityException e) {
            throw new IllegalStateException(e);
        }
    }

    public String randomToken() {
        byte[] bytes = new byte[32];
        random.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    public String randomCode() {
        return String.format("%06d", random.nextInt(1_000_000));
    }

    /** Vergleich in konstanter Zeit, um Timing-Angriffe zu vermeiden. */
    public static boolean constantTimeEquals(String a, String b) {
        if (a == null || b == null) {
            return false;
        }
        return MessageDigest.isEqual(a.getBytes(StandardCharsets.UTF_8), b.getBytes(StandardCharsets.UTF_8));
    }

    private static byte[] hmac(byte[] key, String label) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(key, "HmacSHA256"));
            return mac.doFinal(label.getBytes(StandardCharsets.UTF_8));
        } catch (GeneralSecurityException e) {
            throw new IllegalStateException(e);
        }
    }
}
