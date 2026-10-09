package de.datenschild.email;

import de.datenschild.device.Device;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "monitored_email",
        uniqueConstraints = @UniqueConstraint(columnNames = {"device_id", "email_mac"}))
public class MonitoredEmail {

    @Id
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "device_id")
    private Device device;

    /** AES-GCM-verschlüsselt, wird nur für Abfrage und Benachrichtigung entschlüsselt. */
    @Column(name = "email_cipher", nullable = false, length = 1024)
    private String emailCipher;

    @Column(name = "email_mac", nullable = false, length = 64)
    private String emailMac;

    @Column(nullable = false)
    private String maskedEmail;

    private boolean verified;

    @Column(length = 64)
    private String codeHash;

    private Instant codeExpiresAt;

    private int failedAttempts;

    @Column(length = 20000)
    private String knownBreaches = "";

    @Column(nullable = false)
    private Instant createdAt;

    private Instant verifiedAt;

    private Instant lastCheckedAt;

    protected MonitoredEmail() {}

    public MonitoredEmail(Device device, String emailCipher, String emailMac, String maskedEmail) {
        this.id = UUID.randomUUID();
        this.device = device;
        this.emailCipher = emailCipher;
        this.emailMac = emailMac;
        this.maskedEmail = maskedEmail;
        this.createdAt = Instant.now();
    }

    public List<String> knownBreachList() {
        return knownBreaches == null || knownBreaches.isBlank()
                ? List.of()
                : Arrays.asList(knownBreaches.split("\n"));
    }

    public void setKnownBreaches(List<String> names) {
        this.knownBreaches = String.join("\n", names);
        this.lastCheckedAt = Instant.now();
    }

    public void newCode(String codeHash, Instant expiresAt) {
        this.codeHash = codeHash;
        this.codeExpiresAt = expiresAt;
        this.failedAttempts = 0;
    }

    public void markVerified() {
        this.verified = true;
        this.verifiedAt = Instant.now();
        this.codeHash = null;
        this.codeExpiresAt = null;
    }

    public void registerFailedAttempt() { this.failedAttempts++; }

    public UUID getId() { return id; }
    public Device getDevice() { return device; }
    public String getEmailCipher() { return emailCipher; }
    public String getMaskedEmail() { return maskedEmail; }
    public boolean isVerified() { return verified; }
    public String getCodeHash() { return codeHash; }
    public Instant getCodeExpiresAt() { return codeExpiresAt; }
    public int getFailedAttempts() { return failedAttempts; }
    public Instant getLastCheckedAt() { return lastCheckedAt; }
}
