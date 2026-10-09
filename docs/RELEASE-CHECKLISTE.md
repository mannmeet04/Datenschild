# Checkliste vor der Veröffentlichung

> Keine Rechtsberatung. Datenschutzerklärung und Impressum vor dem Start anwaltlich prüfen lassen, z. B. über einen IT-Rechts-Anwalt oder die Händlerbund-/IT-Recht-Kanzlei-Pakete.

## Recht (Deutschland/EU)

- [ ] **Impressum (§ 5 DDG):** `app/assets/legal/impressum.txt` ausfüllen und zusätzlich auf einer Webseite veröffentlichen. Die Stores verlangen eine URL.
- [ ] **Datenschutzerklärung:** `app/assets/legal/datenschutz.txt` ausfüllen (Platzhalter, Hoster, Mail-Dienst) und als Webseite veröffentlichen.
- [ ] **Übermittlung in Drittländer prüfen:** Die Datenanbieter (XposedOrNot bzw. HIBP in Australien) sitzen außerhalb der EU. Rechtsgrundlage klären und in der Datenschutzerklärung nennen.
- [ ] **AVV abschließen** mit Hoster und Mail-Dienstleister (Art. 28 DSGVO).
- [ ] **Verzeichnis von Verarbeitungstätigkeiten** anlegen (Art. 30 DSGVO, kurze Tabelle genügt).
- [ ] **Nutzungsbedingungen der Datenanbieter** lesen:
  - XposedOrNot: Nutzungsbedingungen für die kommerzielle Nutzung prüfen.
  - HIBP: Für kommerzielle Nutzung ist ein Abo nötig, die Quellenangabe ist Pflicht.
- [ ] **Kein Tracking** einbauen. Sonst braucht es Einwilligung und Consent-Banner nach § 25 TDDDG.
- [ ] **Monetarisierung:** Bei Abos kommen Pflichten nach BGB hinzu, etwa Widerrufsbelehrung und der Kündigungsbutton (§ 312k BGB, gilt für Web; In-App-Käufe laufen über Apple/Google).
- [ ] **DSGVO-Vorlagen:** Der Hinweis „keine Rechtsberatung“ (RDG) muss bleiben.

## Technik

- [ ] Backend mit HTTPS betreiben, Server in der EU (z. B. Hetzner, IONOS, netcup).
- [ ] `APP_CRYPTO_MASTER_KEY` erzeugen und sicher sichern (Passwort-Manager).
- [ ] Datenbank-Backups einrichten. Die Backups sind verschlüsselt, weil die Spalte selbst verschlüsselt ist.
- [ ] `ddl-auto: update` durch Flyway-Migrationen ersetzen.
- [ ] Rate-Limits beobachten. Bei mehreren Server-Instanzen auf Redis umstellen.
- [ ] Monitoring: Health-Check `/actuator/health` überwachen.

## Google Play

- [ ] Entwicklerkonto anlegen (25 $ einmalig). Neue Privatkonten müssen vor dem Release 14 Tage mit 12 Testern testen.
- [ ] Formular „Datensicherheit“ ausfüllen: E-Mail-Adresse wird erhoben, verschlüsselt übertragen und ist löschbar. Keine Weitergabe zu Werbezwecken.
- [ ] Link zur Kontolöschung angeben. Die App hat „Alle meine Daten löschen“; zusätzlich ist eine Web-URL nötig.
- [ ] App-Kategorie: Tools, Zielgruppe ab 16 Jahren.

## Apple App Store

- [ ] Apple Developer Program abschließen (99 €/Jahr). Gebaut wird auf einem Mac oder mit einem Cloud-Build-Dienst (z. B. Codemagic).
- [ ] App Privacy (Nutrition Label) ausfüllen: „Contact Info → Email Address“, verknüpft mit der App-Funktion, kein Tracking.
- [ ] Für die Prüfung durch Apple in den App-Review-Notes erklären, wie der Bestätigungscode funktioniert. Den Prüfern eine Test-Adresse mitgeben.
- [ ] Rechtlich gilt man in der EU als „Trader“ (DSA). Adresse und Kontakt werden dann im Store angezeigt.
