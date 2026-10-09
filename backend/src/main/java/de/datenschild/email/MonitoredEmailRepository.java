package de.datenschild.email;

import de.datenschild.device.Device;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface MonitoredEmailRepository extends JpaRepository<MonitoredEmail, UUID> {

    List<MonitoredEmail> findByDeviceOrderByCreatedAtAsc(Device device);

    Optional<MonitoredEmail> findByIdAndDevice(UUID id, Device device);

    boolean existsByDeviceAndEmailMac(Device device, String emailMac);

    long countByDevice(Device device);

    List<MonitoredEmail> findByVerifiedTrue();

    List<MonitoredEmail> findByVerifiedFalseAndCreatedAtBefore(Instant cutoff);

    void deleteByDevice(Device device);
}
