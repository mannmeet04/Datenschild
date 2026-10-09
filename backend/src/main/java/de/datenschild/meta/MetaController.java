package de.datenschild.meta;

import de.datenschild.breach.BreachProvider;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class MetaController {

    private final BreachProvider provider;

    public MetaController(BreachProvider provider) {
        this.provider = provider;
    }

    /** Quellenangabe für die App (Lizenzpflicht der Datenanbieter). */
    @GetMapping("/api/v1/meta")
    public Map<String, String> meta() {
        return Map.of("attribution", provider.attribution());
    }
}
