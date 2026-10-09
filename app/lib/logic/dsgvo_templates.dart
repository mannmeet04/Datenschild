enum DsgvoRequestType { auskunft, loeschung }

extension DsgvoRequestTypeText on DsgvoRequestType {
  String get label => switch (this) {
        DsgvoRequestType.auskunft => 'Auskunft (Art. 15 DSGVO)',
        DsgvoRequestType.loeschung => 'Löschung (Art. 17 DSGVO)',
      };
}

class DsgvoLetter {
  final String subject;
  final String body;

  const DsgvoLetter(this.subject, this.body);
}

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

/// Allgemeine Mustervorlagen – keine Rechtsberatung im Einzelfall (RDG).
DsgvoLetter buildLetter({
  required DsgvoRequestType type,
  required String company,
  required String name,
  required String email,
  String? breachDate,
  DateTime? today,
}) {
  final now = today ?? DateTime.now();
  final deadline = now.add(const Duration(days: 30));
  final leak = breachDate == null
      ? 'Ich habe erfahren, dass meine Daten von einem Datenleck bei Ihnen betroffen sein könnten.'
      : 'Ich habe erfahren, dass meine Daten von einem Datenleck bei Ihnen (Zeitraum: $breachDate) '
          'betroffen sein könnten.';
  final signature = name.isEmpty ? '[Dein Name]' : name;
  final mail = email.isEmpty ? '[Deine E-Mail-Adresse]' : email;
  final recipient = 'An: ${company.isEmpty ? '[Unternehmen]' : company}\nz. Hd. Datenschutzbeauftragte/r\n\n';

  return switch (type) {
    DsgvoRequestType.auskunft => DsgvoLetter(
        'Auskunftsersuchen nach Art. 15 DSGVO',
        '''${recipient}Sehr geehrte Damen und Herren,

$leak

Ich bitte Sie daher gemäß Art. 15 DSGVO um Auskunft, ob Sie mich betreffende personenbezogene Daten verarbeiten. Falls ja, bitte ich um:

1. eine Kopie aller zu meiner Person gespeicherten Daten (Art. 15 Abs. 3 DSGVO),
2. die Verarbeitungszwecke und Rechtsgrundlagen,
3. die Empfänger oder Kategorien von Empfängern,
4. die geplante Speicherdauer,
5. die Herkunft der Daten, falls Sie sie nicht bei mir erhoben haben,
6. Informationen darüber, welche meiner Daten von dem Datenleck betroffen waren, und welche Maßnahmen Sie ergriffen haben (Art. 33, 34 DSGVO).

Zur Identifizierung: Mein Konto ist mit der E-Mail-Adresse $mail verknüpft.

Bitte beantworten Sie meine Anfrage unverzüglich, spätestens jedoch innerhalb eines Monats, also bis zum ${_date(deadline)} (Art. 12 Abs. 3 DSGVO). Die Auskunft ist kostenlos.

Sollte ich bis dahin keine Antwort erhalten, behalte ich mir vor, mich an die zuständige Datenschutz-Aufsichtsbehörde zu wenden.

Mit freundlichen Grüßen
$signature
${_date(now)}''',
      ),
    DsgvoRequestType.loeschung => DsgvoLetter(
        'Antrag auf Löschung nach Art. 17 DSGVO',
        '''${recipient}Sehr geehrte Damen und Herren,

$leak

Hiermit fordere ich Sie gemäß Art. 17 DSGVO auf, alle mich betreffenden personenbezogenen Daten unverzüglich zu löschen, soweit keine gesetzliche Aufbewahrungspflicht entgegensteht. Eine etwaige Einwilligung in die Verarbeitung meiner Daten widerrufe ich hiermit (Art. 7 Abs. 3 DSGVO), und ich widerspreche der Verarbeitung zu Werbezwecken (Art. 21 Abs. 2 DSGVO).

Falls Sie Daten aufgrund gesetzlicher Pflichten nicht löschen dürfen, bitte ich um Einschränkung der Verarbeitung (Art. 18 DSGVO) und um Mitteilung, welche Daten das betrifft und wie lange sie gespeichert bleiben.

Bitte informieren Sie auch alle Empfänger meiner Daten über die Löschung (Art. 19 DSGVO).

Zur Identifizierung: Mein Konto ist mit der E-Mail-Adresse $mail verknüpft.

Bitte bestätigen Sie mir die Löschung bis zum ${_date(deadline)} (Art. 12 Abs. 3 DSGVO).

Mit freundlichen Grüßen
$signature
${_date(now)}''',
      ),
  };
}
