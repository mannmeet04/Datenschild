import '../models/breach.dart';

enum Severity { niedrig, mittel, hoch, kritisch }

class ActionItem {
  final String id;
  final String title;
  final String description;
  final Severity severity;

  /// Punktabzug im Sicherheits-Score, solange der Schritt offen ist.
  final int weight;
  final String? url;

  const ActionItem({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.weight,
    this.url,
  });
}

/// Leitet aus den geleakten Datenarten konkrete Schritte ab.
/// Die Datenarten kommen im englischen Format der Anbieter ("Passwords", "Phone numbers" …).
List<ActionItem> actionsForBreach(Breach breach) {
  final classes = breach.dataClasses.map((c) => c.toLowerCase()).toList();
  bool has(List<String> keywords) => classes.any((c) => keywords.any(c.contains));
  final service = breach.title;
  final site = breach.domain == null ? null : 'https://${breach.domain}';
  final items = <ActionItem>[];

  void add(String key, String title, String description, Severity severity, int weight, [String? url]) =>
      items.add(ActionItem(
        id: '${breach.name}:$key',
        title: title,
        description: description,
        severity: severity,
        weight: weight,
        url: url,
      ));

  if (has(['password'])) {
    add('pw_change', 'Passwort bei $service ändern',
        'Dein Passwort für $service war im Leak. Ändere es sofort – auch wenn es nur verschlüsselt geleakt wurde.',
        Severity.kritisch, 20, site);
    add('pw_reuse', 'Dasselbe Passwort überall sonst ersetzen',
        'Angreifer probieren geleakte Passwörter automatisch bei anderen Diensten aus (Credential Stuffing). '
            'Ändere es überall, wo du es ebenfalls verwendest.',
        Severity.hoch, 10);
    add('2fa', 'Zwei-Faktor-Anmeldung bei $service aktivieren',
        'Mit 2FA oder Passkey reicht ein geleaktes Passwort allein nicht mehr zum Einloggen.',
        Severity.hoch, 5, 'https://2fa.directory/de/');
  }
  if (has(['security question'])) {
    add('questions', 'Sicherheitsfragen ändern',
        'Geleakte Sicherheitsfragen können zum Zurücksetzen von Passwörtern missbraucht werden.',
        Severity.hoch, 8);
  }
  if (has(['credit card', 'bank account', 'iban', 'payment', 'financial'])) {
    add('bank', 'Kontoauszüge prüfen und Bank informieren',
        'Achte auf unbekannte Abbuchungen und Lastschriften – du kannst SEPA-Lastschriften 8 Wochen lang '
            'zurückbuchen lassen. Bei Verdacht Karte sperren: Sperr-Notruf 116 116.',
        Severity.kritisch, 25, 'tel:116116');
  }
  if (has(['government', 'passport', 'social security', 'national id', 'driver'])) {
    add('id', 'Missbrauch deiner Ausweisdaten vorbeugen',
        'Erstatte bei Verdacht Anzeige (Online-Wache deines Bundeslandes) und beobachte deine Schufa-Daten.',
        Severity.kritisch, 25);
  }
  if (has(['date of birth', 'dates of birth']) && classes.contains('names')) {
    add('schufa', 'Kostenlose Schufa-Selbstauskunft anfordern',
        'Name und Geburtsdatum reichen Betrügern oft für Bestellungen auf Rechnung. Nach Art. 15 DSGVO '
            'bekommst du deine Schufa-Daten kostenlos.',
        Severity.mittel, 8, 'https://www.meineschufa.de/de/datenkopie');
  }
  if (has(['phone'])) {
    add('phone', 'Vor Betrugs-SMS und -Anrufen in Acht nehmen',
        'Rechne mit gefälschten SMS („Ihr Paket…“) und Anrufen, die sich auf $service beziehen. '
            'Klicke keine Links und gib keine Codes weiter.',
        Severity.mittel, 5);
  }
  if (has(['email'])) {
    add('phishing', 'Mit Phishing-Mails im Namen von $service rechnen',
        'Prüfe Absender und Links genau. Echte Firmen fragen nie per E-Mail nach Passwörtern oder TANs.',
        Severity.niedrig, 3);
  }
  if (has(['physical address', 'postal'])) {
    add('address', 'Auf unbestellte Pakete und Briefe achten',
        'Mit deiner Adresse sind Bestellbetrug und gefälschte Rechnungen möglich. Zahle keine Rechnungen '
            'für Dinge, die du nicht bestellt hast.',
        Severity.niedrig, 3);
  }
  return items;
}

/// Grundschutz, unabhängig von konkreten Leaks.
const List<ActionItem> generalActions = [
  ActionItem(
    id: 'general:pwmanager',
    title: 'Passwort-Manager nutzen',
    description: 'Ein Passwort-Manager erzeugt für jeden Dienst ein eigenes, starkes Passwort. '
        'Kostenlos und quelloffen z. B. Bitwarden oder KeePassXC.',
    severity: Severity.hoch,
    weight: 10,
  ),
  ActionItem(
    id: 'general:mail2fa',
    title: '2FA für dein E-Mail-Postfach aktivieren',
    description: 'Wer dein Postfach kontrolliert, kann fast alle Passwörter zurücksetzen. '
        'Schütze es zuerst.',
    severity: Severity.hoch,
    weight: 10,
  ),
  ActionItem(
    id: 'general:updates',
    title: 'Automatische Updates einschalten',
    description: 'Halte Betriebssystem und Apps aktuell – die meisten Angriffe nutzen bekannte, '
        'längst behobene Lücken.',
    severity: Severity.mittel,
    weight: 5,
  ),
  ActionItem(
    id: 'general:passkeys',
    title: 'Passkeys verwenden, wo möglich',
    description: 'Passkeys ersetzen Passwörter und sind gegen Phishing und Leaks immun.',
    severity: Severity.niedrig,
    weight: 5,
    url: 'https://www.passkeys.io/who-supports-passkeys',
  ),
];
