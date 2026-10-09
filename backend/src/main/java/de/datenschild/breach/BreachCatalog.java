package de.datenschild.breach;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/** Zwischenspeicher für die Leak-Metadaten (wird höchstens einmal täglich neu geladen). */
@Service
public class BreachCatalog {

    private static final Logger log = LoggerFactory.getLogger(BreachCatalog.class);
    private static final Duration MAX_AGE = Duration.ofHours(24);

    private final BreachProvider provider;
    private volatile Map<String, BreachInfo> byName = Map.of();
    private volatile Instant loadedAt = Instant.EPOCH;

    public BreachCatalog(BreachProvider provider) {
        this.provider = provider;
    }

    public List<BreachInfo> resolve(List<String> names) {
        refreshIfStale();
        Map<String, BreachInfo> snapshot = byName;
        return names.stream()
                .map(n -> snapshot.getOrDefault(n.toLowerCase(), BreachInfo.unknown(n)))
                .toList();
    }

    private synchronized void refreshIfStale() {
        if (loadedAt.plus(MAX_AGE).isAfter(Instant.now())) {
            return;
        }
        try {
            byName = provider.loadCatalog().stream()
                    .collect(Collectors.toMap(b -> b.name().toLowerCase(), Function.identity(), (a, b) -> a));
            loadedAt = Instant.now();
            log.info("Leak-Katalog geladen: {} Einträge", byName.size());
        } catch (BreachProviderException e) {
            // Alten Stand weiterverwenden, in 10 Minuten erneut versuchen
            loadedAt = Instant.now().minus(MAX_AGE).plus(Duration.ofMinutes(10));
            log.warn("Leak-Katalog konnte nicht geladen werden: {}", e.getMessage());
        }
    }
}
