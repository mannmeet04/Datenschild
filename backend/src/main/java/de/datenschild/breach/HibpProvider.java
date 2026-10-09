package de.datenschild.breach;

import com.fasterxml.jackson.databind.JsonNode;
import de.datenschild.config.AppProperties;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.util.ArrayList;
import java.util.List;

/**
 * Have I Been Pwned (kostenpflichtiger API-Key nötig, https://haveibeenpwned.com/API/Key).
 * Lizenz CC BY 4.0 – Quellenangabe in der App ist Pflicht.
 */
@Component
@ConditionalOnProperty(name = "app.breach.provider", havingValue = "hibp")
public class HibpProvider implements BreachProvider {

    private final RestClient client;

    public HibpProvider(AppProperties properties, RestClient.Builder builder) {
        String apiKey = properties.breach().hibpApiKey();
        if (apiKey == null || apiKey.isBlank()) {
            throw new IllegalStateException("APP_HIBP_API_KEY fehlt für Provider 'hibp'");
        }
        this.client = builder
                .baseUrl("https://haveibeenpwned.com/api/v3")
                .defaultHeader(HttpHeaders.USER_AGENT, properties.breach().userAgent())
                .defaultHeader("hibp-api-key", apiKey)
                .build();
    }

    @Override
    public List<String> findBreachNames(String email) {
        try {
            JsonNode body = client.get()
                    .uri(u -> u.path("/breachedaccount/{account}").queryParam("truncateResponse", "true").build(email))
                    .retrieve().body(JsonNode.class);
            List<String> names = new ArrayList<>();
            if (body != null) {
                body.forEach(b -> names.add(b.path("Name").asText()));
            }
            return names;
        } catch (HttpClientErrorException.NotFound e) {
            return List.of();
        } catch (RestClientException e) {
            throw new BreachProviderException("HIBP nicht erreichbar", e);
        }
    }

    @Override
    public List<BreachInfo> loadCatalog() {
        try {
            JsonNode body = client.get().uri("/breaches").retrieve().body(JsonNode.class);
            List<BreachInfo> result = new ArrayList<>();
            if (body == null) {
                return result;
            }
            for (JsonNode b : body) {
                List<String> dataClasses = new ArrayList<>();
                b.path("DataClasses").forEach(d -> dataClasses.add(d.asText()));
                result.add(new BreachInfo(
                        b.path("Name").asText(),
                        b.path("Title").asText(),
                        XposedOrNotProvider.textOrNull(b, "Domain"),
                        XposedOrNotProvider.textOrNull(b, "BreachDate"),
                        null,
                        dataClasses,
                        b.path("PwnCount").asLong(),
                        stripHtml(XposedOrNotProvider.textOrNull(b, "Description")),
                        XposedOrNotProvider.textOrNull(b, "LogoPath"),
                        b.path("IsSensitive").asBoolean(false),
                        b.path("IsVerified").asBoolean(false)));
            }
            return result;
        } catch (RestClientException e) {
            throw new BreachProviderException("HIBP-Katalog nicht erreichbar", e);
        }
    }

    @Override
    public String attribution() {
        return "Leak-Daten bereitgestellt von Have I Been Pwned (haveibeenpwned.com), CC BY 4.0";
    }

    private static String stripHtml(String html) {
        return html == null ? null : html.replaceAll("<[^>]+>", "");
    }
}
