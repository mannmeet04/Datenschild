package de.datenschild.crypto;

import de.datenschild.config.AppProperties;
import org.junit.jupiter.api.Test;

import java.util.Base64;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class CryptoServiceTest {

    private static CryptoService withKey(String key) {
        return new CryptoService(new AppProperties(new AppProperties.Crypto(key), null, null, null, null));
    }

    private final CryptoService crypto = withKey(Base64.getEncoder().encodeToString(new byte[32]));

    @Test
    void roundTripUsesRandomIv() {
        String a = crypto.encrypt("max@example.org");
        String b = crypto.encrypt("max@example.org");
        assertThat(a).isNotEqualTo(b);
        assertThat(crypto.decrypt(a)).isEqualTo("max@example.org");
    }

    @Test
    void macIsDeterministic() {
        assertThat(crypto.mac("x")).isEqualTo(crypto.mac("x")).hasSize(64);
    }

    @Test
    void rejectsShortKey() {
        assertThatThrownBy(() -> withKey(Base64.getEncoder().encodeToString(new byte[16])))
                .isInstanceOf(IllegalStateException.class);
    }
}
