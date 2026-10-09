package de.datenschild.email;

import de.datenschild.breach.BreachCatalog;
import de.datenschild.breach.BreachInfo;
import de.datenschild.breach.BreachProvider;
import de.datenschild.breach.BreachProviderException;
import de.datenschild.config.AppProperties;
import de.datenschild.crypto.CryptoService;
import de.datenschild.device.Device;
import de.datenschild.notify.Notifier;
import de.datenschild.web.ApiException;
import de.datenschild.web.RateLimiter;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

@Service
public class EmailService {

    public record EmailView(String id, String maskedEmail, boolean verified, Instant lastCheckedAt,
                            List<BreachInfo> breaches) {}

    private final MonitoredEmailRepository emails;
    private final CryptoService crypto;
    private final Notifier notifier;
    private final BreachProvider provider;
    private final BreachCatalog catalog;
    private final RateLimiter rateLimiter;
    private final AppProperties.Limits limits;

    public EmailService(MonitoredEmailRepository emails, CryptoService crypto, Notifier notifier,
                        BreachProvider provider, BreachCatalog catalog, RateLimiter rateLimiter,
                        AppProperties properties) {
        this.emails = emails;
        this.crypto = crypto;
        this.notifier = notifier;
        this.provider = provider;
        this.catalog = catalog;
        this.rateLimiter = rateLimiter;
        this.limits = properties.limits();
    }

    @Transactional(readOnly = true)
    public List<EmailView> list(Device device) {
        return emails.findByDeviceOrderByCreatedAtAsc(device).stream().map(this::toView).toList();
    }

    @Transactional
    public EmailView add(Device device, String rawEmail) {
        rateLimiter.check("add:" + device.getId(), 5, Duration.ofHours(1));
        String email = normalize(rawEmail);
        String mac = crypto.mac(email);
        if (emails.existsByDeviceAndEmailMac(device, mac)) {
            throw new ApiException(HttpStatus.CONFLICT, "Diese Adresse wird bereits überwacht");
        }
        if (emails.countByDevice(device) >= limits.maxEmailsPerDevice()) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "Maximale Anzahl an Adressen erreicht");
        }
        MonitoredEmail entry = new MonitoredEmail(device, crypto.encrypt(email), mac, mask(email));
        issueCode(entry, email);
        return toView(emails.save(entry));
    }

    @Transactional
    public void resendCode(Device device, UUID id) {
        MonitoredEmail entry = find(device, id);
        if (entry.isVerified()) {
            return;
        }
        rateLimiter.check("resend:" + id, 3, Duration.ofHours(1));
        issueCode(entry, crypto.decrypt(entry.getEmailCipher()));
    }

    /**
     * Erst nach Bestätigung des Codes werden Leaks angezeigt. So kann niemand fremde
     * Adressen ausspähen (anders als bei einer offenen Suche).
     */
    @Transactional(noRollbackFor = ApiException.class)
    public EmailView verify(Device device, UUID id, String code) {
        MonitoredEmail entry = find(device, id);
        if (entry.isVerified()) {
            return toView(entry);
        }
        if (entry.getCodeHash() == null || entry.getFailedAttempts() >= limits.maxVerifyAttempts()) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "Bitte fordere einen neuen Code an");
        }
        if (entry.getCodeExpiresAt().isBefore(Instant.now())) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "Der Code ist abgelaufen");
        }
        if (!CryptoService.constantTimeEquals(entry.getCodeHash(), crypto.mac(entry.getId() + ":" + code))) {
            entry.registerFailedAttempt();
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "Falscher Code");
        }
        entry.markVerified();
        try {
            entry.setKnownBreaches(provider.findBreachNames(crypto.decrypt(entry.getEmailCipher())));
        } catch (BreachProviderException e) {
            // Bestätigung bleibt gültig; die Abfrage holt die nächtliche Überwachung oder "Aktualisieren" nach
        }
        return toView(entry);
    }

    @Transactional
    public EmailView refresh(Device device, UUID id) {
        MonitoredEmail entry = find(device, id);
        if (!entry.isVerified()) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "Adresse ist noch nicht bestätigt");
        }
        rateLimiter.check("refresh:" + id, 1, Duration.ofMinutes(5));
        entry.setKnownBreaches(provider.findBreachNames(crypto.decrypt(entry.getEmailCipher())));
        return toView(entry);
    }

    @Transactional
    public void delete(Device device, UUID id) {
        emails.delete(find(device, id));
    }

    private void issueCode(MonitoredEmail entry, String email) {
        String code = crypto.randomCode();
        entry.newCode(crypto.mac(entry.getId() + ":" + code),
                Instant.now().plus(Duration.ofMinutes(limits.verificationTtlMinutes())));
        notifier.sendVerificationCode(email, code);
    }

    private MonitoredEmail find(Device device, UUID id) {
        return emails.findByIdAndDevice(id, device).orElseThrow(ApiException::notFound);
    }

    private EmailView toView(MonitoredEmail e) {
        List<BreachInfo> breaches = e.isVerified() ? catalog.resolve(e.knownBreachList()) : List.of();
        return new EmailView(e.getId().toString(), e.getMaskedEmail(), e.isVerified(), e.getLastCheckedAt(), breaches);
    }

    static String normalize(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }

    /** "max.mustermann@gmail.com" → "m***n@gmail.com" */
    static String mask(String email) {
        int at = email.indexOf('@');
        String local = email.substring(0, at);
        String masked = local.length() <= 2
                ? local.charAt(0) + "***"
                : local.charAt(0) + "***" + local.charAt(local.length() - 1);
        return masked + email.substring(at);
    }
}
