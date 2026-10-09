package de.datenschild.breach;

import java.util.List;

/**
 * Quelle für Leak-Daten. Datenschild speichert selbst KEINE geleakten Datensätze
 * (§ 202d StGB), sondern fragt ausschließlich bei seriösen Diensten nach.
 */
public interface BreachProvider {

    /** Namen der Leaks, in denen die Adresse vorkommt; leer, wenn keine. */
    List<String> findBreachNames(String email);

    /** Öffentlicher Katalog aller bekannten Leaks (Metadaten, keine Personendaten). */
    List<BreachInfo> loadCatalog();

    /** Pflicht-Quellenangabe, die in der App angezeigt wird. */
    String attribution();
}
