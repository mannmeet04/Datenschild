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

/** Kostenlose API von XposedOrNot (https://xposedornot.com). */
@Component
@ConditionalOnProperty(name = "app.breach.provider", havingValue = "xon", matchIfMissing = true)
public class XposedOrNotProvider implements BreachProvider {

    private final RestClient client;

    public XposedOrNotProvider(AppProperties properties, RestClient.Builder builder) {
        this.client = builder
                .baseUrl("https://api.xposedornot.com/v1")
                .defaultHeader(HttpHeaders.USER_AGENT, properties.breach().userAgent())
                .build();
    }

    @Override
    public List<String> findBreachNames(String email) {
        try {
            JsonNode body = client.get().uri("/check-email/{email}", email).retrieve().body(JsonNode.class);
            List<String> names = new ArrayList<>();
            // Antwortformat: {"breaches": [["Adobe", "LinkedIn", ...]]}
            if (body != null && body.path("breaches").isArray()) {
                for (JsonNode group : body.path("breaches")) {
                    group.forEach(n -> names.add(n.asText()));
                }
            }
            return names;
        } catch (HttpClientErrorException.NotFound e) {
            return List.of();
        } catch (RestClientException e) {
            throw new BreachProviderException("XposedOrNot nicht erreichbar", e);
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
            for (JsonNode b : body.path("exposedBreaches")) {
                List<String> dataClasses = new ArrayList<>();
                b.path("exposedData").forEach(d -> dataClasses.add(d.asText()));
                result.add(new BreachInfo(
                        b.path("breachID").asText(),
                        b.path("breachID").asText(),
                        textOrNull(b, "domain"),
                        dateOnly(textOrNull(b, "breachedDate")),
                        textOrNull(b, "industry"),
                        dataClasses,
                        b.hasNonNull("exposedRecords") ? b.path("exposedRecords").asLong() : null,
                        textOrNull(b, "exposureDescription"),
                        textOrNull(b, "logo"),
                        b.path("sensitive").asBoolean(false),
                        b.path("verified").asBoolean(false)));
            }
            return result;
        } catch (RestClientException e) {
            throw new BreachProviderException("XposedOrNot-Katalog nicht erreichbar", e);
        }
    }

    @Override
    public String attribution() {
        return "Leak-Daten bereitgestellt von XposedOrNot (xposedornot.com)";
    }

    static String textOrNull(JsonNode node, String field) {
        String value = node.path(field).asText(null);
        return value == null || value.isBlank() ? null : value;
    }

    static String dateOnly(String isoDateTime) {
        return isoDateTime == null || isoDateTime.length() < 10 ? isoDateTime : isoDateTime.substring(0, 10);
    }
}
