package de.datenschild.device;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

/**
 * Pseudonymes Gerät statt Benutzerkonto: kein Name, kein Passwort, keine Telefonnummer
 * (Datenminimierung, Art. 5 Abs. 1 lit. c DSGVO).
 */
@Entity
@Table(name = "device")
public class Device {

    @Id
    private UUID id;

    @Column(nullable = false, unique = true, length = 64)
    private String tokenHash;

    @Column(length = 512)
    private String pushToken;

    @Column(nullable = false)
    private Instant createdAt;

    @Column(nullable = false)
    private Instant lastSeenAt;

    protected Device() {}

    public Device(String tokenHash) {
        this.id = UUID.randomUUID();
        this.tokenHash = tokenHash;
        this.createdAt = Instant.now();
        this.lastSeenAt = createdAt;
    }

    public UUID getId() { return id; }
    public String getTokenHash() { return tokenHash; }
    public String getPushToken() { return pushToken; }
    public void setPushToken(String pushToken) { this.pushToken = pushToken; }
    public Instant getLastSeenAt() { return lastSeenAt; }
    public void touch() { this.lastSeenAt = Instant.now(); }
}
