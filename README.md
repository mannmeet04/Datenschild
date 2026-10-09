# Datenschild

Datenlecks erkennen, verstehen und handeln. Eine App für iOS und Android mit eigenem Backend, ausgerichtet auf DSGVO und deutsches Recht.

| Ordner     | Inhalt                                                     |
|------------|------------------------------------------------------------|
| `backend/` | Spring Boot 3.5 (Java 21): Geräte, E-Mail-Überwachung, Benachrichtigungen |
| `app/`     | Flutter-App (iOS und Android)                              |
| `docs/`    | Ideen und Roadmap, Checkliste für die Store-Veröffentlichung |

## Funktionen (MVP)

- **Passwort-Check:** Abfrage per k-Anonymität direkt aus der App. Das Passwort verlässt nie das Gerät.
- **E-Mail-Check mit Überwachung:** Die Adresse muss erst per 6-stelligem Code bestätigt werden. Danach prüft der Server sie täglich und schickt bei neuen Leaks eine Mail.
- **Handlungsplan:** konkrete Schritte je nach geleakter Datenart (Passwort, IBAN, Ausweis, Telefonnummer …).
- **Sicherheits-Score:** 0 bis 100. Er steigt, wenn Schritte abgehakt werden, und wird nur lokal berechnet.
- **DSGVO-Generator:** Vorlagen für Auskunft (Art. 15) und Löschung (Art. 17), zum Kopieren oder Versenden per Mail.
- **Notfall-Hilfe:** Anleitungen, wenn Karte, Handy oder Ausweis weg sind oder ein Konto gehackt wurde.
- **Alle Daten löschen:** direkt in der App, so wie es Apple und Google verlangen.

## Datenquellen

| Zweck          | Standard (kostenlos)                    | Optional                                      |
|----------------|-----------------------------------------|-----------------------------------------------|
| E-Mail-Leaks   | XposedOrNot (`APP_BREACH_PROVIDER=xon`) | HIBP (`APP_BREACH_PROVIDER=hibp` + `APP_HIBP_API_KEY`) |
| Passwörter     | Pwned Passwords (kostenlos, ohne Key)   | –                                             |

Datenschild speichert selbst **keine** Leak-Datensätze, sonst droht Datenhehlerei nach § 202d StGB. Gespeichert werden nur die Namen der Leaks, in denen eine bestätigte Adresse vorkommt.

## Backend starten

```bash
cd backend
mvn spring-boot:run
```

- Läuft auf `http://localhost:8080` mit H2-Datenbank und dem Profil `dev`.
- Im Profil `dev` wird keine Mail verschickt. Bestätigungscodes erscheinen stattdessen im Log.

Für die Produktion (Profil `prod`, PostgreSQL, SMTP) werden diese Umgebungsvariablen gebraucht:

```
SPRING_PROFILES_ACTIVE=prod
APP_CRYPTO_MASTER_KEY=<base64, 32+ Byte, z. B. openssl rand -base64 32>
DB_URL=jdbc:postgresql://…  DB_USER=…  DB_PASSWORD=…
SMTP_HOST=…  SMTP_USER=…  SMTP_PASSWORD=…  APP_MAIL_FROM=no-reply@deine-domain.de
```

> Den Master-Key sicher aufbewahren. Geht er verloren, lassen sich die gespeicherten Adressen nicht mehr entschlüsseln.

Den Server immer hinter HTTPS betreiben, z. B. mit Caddy oder nginx. Der Hoster sollte in der EU sitzen, und mit ihm muss ein Auftragsverarbeitungsvertrag (AVV) abgeschlossen werden.

### API

| Methode | Pfad                          | Zweck                              |
|---------|-------------------------------|------------------------------------|
| POST    | `/api/v1/devices`             | Gerät registrieren → Token         |
| DELETE  | `/api/v1/devices/me`          | Alles löschen (Art. 17 DSGVO)      |
| GET     | `/api/v1/emails`              | Überwachte Adressen und ihre Leaks |
| POST    | `/api/v1/emails`              | Adresse hinzufügen (Code wird verschickt) |
| POST    | `/api/v1/emails/{id}/verify`  | Code bestätigen                    |
| POST    | `/api/v1/emails/{id}/resend`  | Code neu senden                    |
| POST    | `/api/v1/emails/{id}/refresh` | Sofort prüfen                      |
| DELETE  | `/api/v1/emails/{id}`         | Überwachung beenden                |
| GET     | `/api/v1/meta`                | Quellenangabe                      |

## App starten

Voraussetzung ist das [Flutter SDK](https://docs.flutter.dev/get-started/install/windows).

```bash
cd app
flutter create --org de.datenschild --platforms=android,ios .
flutter pub get
flutter test
flutter run
```

`flutter create .` erzeugt die Ordner `android/` und `ios/`, ohne den vorhandenen Code zu überschreiben. Danach:

1. **Android:** In `android/app/src/main/AndroidManifest.xml` über `<application>` folgende Zeile einfügen:
   `<uses-permission android:name="android.permission.INTERNET"/>`
2. **Lokales Backend im Emulator:** Android blockiert unverschlüsseltes HTTP. Für die Entwicklung `android:usesCleartextTraffic="true"` ins `<application>`-Tag von `android/app/src/debug/AndroidManifest.xml` eintragen.
3. **Produktions-Backend:** `flutter build appbundle --dart-define=API_BASE_URL=https://api.deine-domain.de`

## Vor dem Store-Release

Siehe [docs/RELEASE-CHECKLISTE.md](docs/RELEASE-CHECKLISTE.md).
