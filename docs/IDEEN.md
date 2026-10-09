# Ideen und Roadmap

## Version 1.1: schnelle Erfolge

- **Push-Benachrichtigungen** über Firebase Cloud Messaging. Der Endpunkt `PUT /api/v1/devices/me/push-token` existiert bereits.
- **2FA-Finder:** Daten von 2fa.directory (offene API) einbinden und pro Leak anzeigen: „Bei Adobe geht 2FA per App, hier ist der Link.“
- **Passwort-Generator** für Passphrasen aus deutschen Wörtern, offline.
- **Home-Screen-Widget** mit dem Score.
- **Dunkles Design und Barrierefreiheit:** prüfen, ob alles mit großen Schriften, TalkBack und VoiceOver funktioniert.

## Version 1.2: Alleinstellungsmerkmale

- **Warnmeldungen aus Deutschland:** RSS des BSI (CERT-Bund/WID) und Phishing-Radar der Verbraucherzentrale als Feed in der App.
- **Phishing-Quiz:** 10 echte Beispiel-Mails (DHL, Sparkasse, ELSTER, PayPal). Beantworten, ob echt oder Fake, mit Erklärung.
- **Konten-Inventar:** Die Nutzerin oder der Nutzer pflegt lokal eine Liste der eigenen Konten. Die App erinnert ans Löschen ungenutzter Konten und verlinkt direkt zur Löschseite (Daten von JustDeleteMe).
- **DSGVO-Fristen-Tracker:** Anfrage wurde verschickt? Die App erinnert nach 30 Tagen und erstellt dann die Beschwerde an die zuständige Landesbehörde.
- **Domain-Überwachung** für Selbstständige und kleine Firmen, mit Nachweis über einen DNS-TXT-Eintrag.

## Version 2: Monetarisierung (Freemium)

| Kostenlos                     | Premium (z. B. 1,99 €/Monat)                       |
|-------------------------------|----------------------------------------------------|
| 1 E-Mail-Adresse, täglicher Check | bis 10 Adressen, stündlicher Check, Push       |
| Passwort-Check                | Familienmodus (bis 5 Personen, mit deren Einwilligung) |
| Handlungsplan, DSGVO-Vorlagen | Fristen-Tracker, Domain-Überwachung                |

Wichtig: Werbung oder der Verkauf von Daten widerspricht dem Markenversprechen. Die App finanziert sich nur über Abos.

## Später

- **Passkey-Login** für ein optionales Konto, um mehrere Geräte zu synchronisieren (Ende-zu-Ende-verschlüsselt).
- **Browser-Erweiterung**, die beim Registrieren auf einer Seite warnt, wenn diese bereits ein Leak hatte.
- **B2B-Version** für Vereine und Handwerksbetriebe: Mitarbeiter-Adressen überwachen, DSGVO-Meldung nach Art. 33 vorbereiten.
- **Mehrsprachigkeit:** Englisch, Türkisch, Polnisch und Arabisch (große Gruppen in Deutschland).
