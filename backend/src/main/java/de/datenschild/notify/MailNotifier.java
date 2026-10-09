package de.datenschild.notify;

import de.datenschild.breach.BreachInfo;
import de.datenschild.config.AppProperties;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.stream.Collectors;

@Component
@ConditionalOnProperty(name = "app.mail.enabled", havingValue = "true")
public class MailNotifier implements Notifier {

    private final JavaMailSender sender;
    private final String from;

    public MailNotifier(JavaMailSender sender, AppProperties properties) {
        this.sender = sender;
        this.from = properties.mail().from();
    }

    @Override
    public void sendVerificationCode(String email, String code) {
        send(email, "Dein Datenschild-Bestätigungscode: " + code, """
                Hallo,

                jemand (hoffentlich du) möchte diese E-Mail-Adresse in der App Datenschild überwachen lassen.

                Dein Bestätigungscode: %s

                Der Code ist 15 Minuten gültig. Wenn du das nicht warst, ignoriere diese E-Mail einfach –
                ohne Bestätigung wird die Adresse nach 24 Stunden automatisch gelöscht.

                Dein Datenschild-Team
                """.formatted(code));
    }

    @Override
    public void sendNewBreaches(String email, String maskedEmail, List<BreachInfo> breaches) {
        String list = breaches.stream()
                .map(b -> "  • " + b.title() + (b.breachDate() != null ? " (" + b.breachDate() + ")" : ""))
                .collect(Collectors.joining("\n"));
        send(email, "Datenschild: Neues Datenleck gefunden", """
                Hallo,

                deine Adresse %s ist in einem neuen Datenleck aufgetaucht:

                %s

                Öffne die App Datenschild – dort findest du einen Schritt-für-Schritt-Plan,
                was du jetzt tun solltest, und eine Vorlage für deine DSGVO-Auskunft.

                Du kannst die Überwachung jederzeit in der App beenden.

                Dein Datenschild-Team
                """.formatted(maskedEmail, list));
    }

    private void send(String to, String subject, String text) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(from);
        message.setTo(to);
        message.setSubject(subject);
        message.setText(text);
        sender.send(message);
    }
}
