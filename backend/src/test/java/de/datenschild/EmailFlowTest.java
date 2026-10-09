package de.datenschild;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import de.datenschild.breach.BreachInfo;
import de.datenschild.breach.BreachProvider;
import de.datenschild.notify.Notifier;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.concurrent.atomic.AtomicReference;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = "spring.datasource.url=jdbc:h2:mem:test")
@AutoConfigureMockMvc
class EmailFlowTest {

    static final AtomicReference<String> lastCode = new AtomicReference<>();

    @TestConfiguration
    static class Fakes {
        @Bean
        @Primary
        BreachProvider fakeProvider() {
            return new BreachProvider() {
                public List<String> findBreachNames(String email) {
                    return email.startsWith("pwned") ? List.of("Adobe") : List.of();
                }

                public List<BreachInfo> loadCatalog() {
                    return List.of(new BreachInfo("Adobe", "Adobe", "adobe.com", "2013-10-04", null,
                            List.of("Email addresses", "Passwords"), 152_000_000L, "Test", null, false, true));
                }

                public String attribution() {
                    return "Test";
                }
            };
        }

        @Bean
        @Primary
        Notifier capturingNotifier() {
            return new Notifier() {
                public void sendVerificationCode(String email, String code) {
                    lastCode.set(code);
                }

                public void sendNewBreaches(String email, String maskedEmail, List<BreachInfo> breaches) {}
            };
        }
    }

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;

    @Test
    void fullFlow() throws Exception {
        String token = read(mvc.perform(post("/api/v1/devices")).andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString()).path("token").asText();
        String auth = "Bearer " + token;

        JsonNode added = read(mvc.perform(post("/api/v1/emails").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"email\":\"Pwned.User@Example.org\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.maskedEmail").value("p***r@example.org"))
                .andExpect(jsonPath("$.verified").value(false))
                .andExpect(jsonPath("$.breaches").isEmpty())
                .andReturn().getResponse().getContentAsString());
        String id = added.path("id").asText();

        // Falscher Code wird abgelehnt, Leaks bleiben verborgen
        mvc.perform(post("/api/v1/emails/" + id + "/verify").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"code\":\"" + wrong(lastCode.get()) + "\"}"))
                .andExpect(status().isUnprocessableEntity());

        mvc.perform(post("/api/v1/emails/" + id + "/verify").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"code\":\"" + lastCode.get() + "\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.verified").value(true))
                .andExpect(jsonPath("$.breaches[0].name").value("Adobe"))
                .andExpect(jsonPath("$.breaches[0].dataClasses[1]").value("Passwords"));

        // Doppelte Adresse (andere Schreibweise) wird erkannt
        mvc.perform(post("/api/v1/emails").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"email\":\"pwned.user@example.org \"}"))
                .andExpect(status().isConflict());

        // Fremdes Gerät sieht nichts
        String other = "Bearer " + read(mvc.perform(post("/api/v1/devices"))
                .andReturn().getResponse().getContentAsString()).path("token").asText();
        mvc.perform(get("/api/v1/emails").header("Authorization", other))
                .andExpect(status().isOk()).andExpect(jsonPath("$").isEmpty());

        // Konto löschen entfernt alles
        mvc.perform(delete("/api/v1/devices/me").header("Authorization", auth)).andExpect(status().isNoContent());
        mvc.perform(get("/api/v1/emails").header("Authorization", auth)).andExpect(status().isUnauthorized());
    }

    @Test
    void rejectsMissingToken() throws Exception {
        mvc.perform(get("/api/v1/emails").header("Authorization", "Bearer nope"))
                .andExpect(status().isUnauthorized());
    }

    private JsonNode read(String body) throws Exception {
        return json.readTree(body);
    }

    private static String wrong(String code) {
        String w = code.equals("000000") ? "111111" : "000000";
        assertThat(w).isNotEqualTo(code);
        return w;
    }
}
