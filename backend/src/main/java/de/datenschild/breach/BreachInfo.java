package de.datenschild.breach;

import java.util.List;

public record BreachInfo(
        String name,
        String title,
        String domain,
        String breachDate,
        String industry,
        List<String> dataClasses,
        Long records,
        String description,
        String logoUrl,
        boolean sensitive,
        boolean verified) {

    /** Platzhalter, falls ein Leak (noch) nicht im Katalog ist. */
    public static BreachInfo unknown(String name) {
        return new BreachInfo(name, name, null, null, null, List.of(), null, null, null, false, false);
    }
}
