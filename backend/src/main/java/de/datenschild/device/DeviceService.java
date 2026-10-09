package de.datenschild.device;

import de.datenschild.crypto.CryptoService;
import de.datenschild.email.MonitoredEmailRepository;
import de.datenschild.web.ApiException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;

@Service
public class DeviceService {

    public record Registration(String deviceId, String token) {}

    private final DeviceRepository devices;
    private final MonitoredEmailRepository emails;
    private final CryptoService crypto;

    public DeviceService(DeviceRepository devices, MonitoredEmailRepository emails, CryptoService crypto) {
        this.devices = devices;
        this.emails = emails;
        this.crypto = crypto;
    }

    @Transactional
    public Registration register() {
        String token = crypto.randomToken();
        Device device = devices.save(new Device(CryptoService.sha256(token)));
        // Das Token wird nur dieses eine Mal im Klartext herausgegeben
        return new Registration(device.getId().toString(), token);
    }

    @Transactional
    public Device authenticate(String authorizationHeader) {
        if (authorizationHeader == null || !authorizationHeader.startsWith("Bearer ")) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "Nicht angemeldet");
        }
        String token = authorizationHeader.substring("Bearer ".length()).trim();
        Device device = devices.findByTokenHash(CryptoService.sha256(token))
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Nicht angemeldet"));
        // Nur grob aktualisieren, um Schreiblast zu sparen
        if (device.getLastSeenAt().isBefore(Instant.now().minus(Duration.ofHours(1)))) {
            device.touch();
        }
        return device;
    }

    @Transactional
    public void updatePushToken(Device device, String pushToken) {
        device.setPushToken(pushToken);
        devices.save(device);
    }

    /** Recht auf Löschung (Art. 17 DSGVO) – entfernt alles, was zu diesem Gerät gehört. */
    @Transactional
    public void deleteEverything(Device device) {
        emails.deleteByDevice(device);
        devices.delete(device);
    }
}
