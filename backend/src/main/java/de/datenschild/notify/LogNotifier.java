package de.datenschild.notify;

import de.datenschild.breach.BreachInfo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.util.List;

/** Nur für die Entwicklung: schreibt Codes ins Log statt E-Mails zu verschicken. */
@Component
@ConditionalOnProperty(name = "app.mail.enabled", havingValue = "false", matchIfMissing = true)
public class LogNotifier implements Notifier {

    private static final Logger log = LoggerFactory.getLogger(LogNotifier.class);

    @Override
    public void sendVerificationCode(String email, String code) {
        log.warn("[DEV] Mailversand deaktiviert – Bestätigungscode: {}", code);
    }

    @Override
    public void sendNewBreaches(String email, String maskedEmail, List<BreachInfo> breaches) {
        log.info("[DEV] Neue Leaks für {}: {}", maskedEmail, breaches.stream().map(BreachInfo::name).toList());
    }
}
