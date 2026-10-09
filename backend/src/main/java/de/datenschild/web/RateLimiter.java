package de.datenschild.web;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Einfaches In-Memory-Rate-Limit (Fixed Window). Reicht für eine Instanz;
 * bei mehreren Instanzen durch Redis o. ä. ersetzen.
 */
@Component
public class RateLimiter {

    private record Window(Instant start, int count) {}

    private final Map<String, Window> windows = new ConcurrentHashMap<>();

    public void check(String key, int limit, Duration period) {
        Instant now = Instant.now();
        Window updated = windows.compute(key, (k, w) ->
                w == null || w.start().plus(period).isBefore(now) ? new Window(now, 1) : new Window(w.start(), w.count() + 1));
        if (updated.count() > limit) {
            throw ApiException.tooManyRequests();
        }
    }

    @Scheduled(fixedRate = 3_600_000)
    void cleanup() {
        Instant cutoff = Instant.now().minus(Duration.ofDays(1));
        windows.entrySet().removeIf(e -> e.getValue().start().isBefore(cutoff));
    }
}
