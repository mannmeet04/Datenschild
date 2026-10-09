package de.datenschild.monitor;

import de.datenschild.breach.BreachCatalog;
import de.datenschild.breach.BreachProvider;
import de.datenschild.breach.BreachProviderException;
import de.datenschild.config.AppProperties;
import de.datenschild.crypto.CryptoService;
import de.datenschild.device.DeviceRepository;
import de.datenschild.device.DeviceService;
import de.datenschild.email.MonitoredEmail;
import de.datenschild.email.MonitoredEmailRepository;
import de.datenschild.notify.Notifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Component
public class MonitoringJob {

    private static final Logger log = LoggerFactory.getLogger(MonitoringJob.class);

    private final MonitoredEmailRepository emails;
    private final DeviceRepository devices;
    private final DeviceService deviceService;
    private final BreachProvider provider;
    private final BreachCatalog catalog;
    private final CryptoService crypto;
    private final Notifier notifier;
    private final AppProperties properties;

    public MonitoringJob(MonitoredEmailRepository emails, DeviceRepository devices, DeviceService deviceService,
                         BreachProvider provider, BreachCatalog catalog, CryptoService crypto, Notifier notifier,
                         AppProperties properties) {
        this.emails = emails;
        this.devices = devices;
        this.deviceService = deviceService;
        this.provider = provider;
        this.catalog = catalog;
        this.crypto = crypto;
        this.notifier = notifier;
        this.properties = properties;
    }

    @Scheduled(cron = "${app.monitor.cron}")
    public void checkAll() {
        List<UUID> ids = emails.findByVerifiedTrue().stream().map(MonitoredEmail::getId).toList();
        log.info("Überwachung startet für {} Adressen", ids.size());
        for (UUID id : ids) {
            try {
                checkOne(id);
                Thread.sleep(properties.monitor().delayMs());
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                return;
            } catch (BreachProviderException e) {
                log.warn("Anbieter nicht erreichbar, Überwachung wird abgebrochen: {}", e.getMessage());
                return;
            }
        }
    }

    void checkOne(UUID id) {
        MonitoredEmail entry = emails.findById(id).orElse(null);
        if (entry == null) {
            return;
        }
        String email = crypto.decrypt(entry.getEmailCipher());
        List<String> current = provider.findBreachNames(email);
        Set<String> known = new HashSet<>(entry.knownBreachList());
        List<String> added = current.stream().filter(n -> !known.contains(n)).toList();
        entry.setKnownBreaches(current);
        emails.save(entry);
        if (!added.isEmpty()) {
            notifier.sendNewBreaches(email, entry.getMaskedEmail(), catalog.resolve(added));
        }
    }

    /** Speicherbegrenzung (Art. 5 Abs. 1 lit. e DSGVO): Altdaten automatisch löschen. */
    @Scheduled(cron = "0 30 3 * * *")
    public void cleanup() {
        var limits = properties.limits();
        emails.deleteAll(emails.findByVerifiedFalseAndCreatedAtBefore(
                Instant.now().minus(Duration.ofHours(limits.unverifiedRetentionHours()))));
        devices.findByLastSeenAtBefore(Instant.now().minus(Duration.ofDays(limits.inactiveDeviceRetentionDays())))
                .forEach(deviceService::deleteEverything);
    }
}
