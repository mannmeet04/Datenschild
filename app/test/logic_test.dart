import 'package:datenschild/logic/action_plan.dart';
import 'package:datenschild/logic/dsgvo_templates.dart';
import 'package:datenschild/logic/security_score.dart';
import 'package:datenschild/models/breach.dart';
import 'package:datenschild/services/password_check.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const adobe = Breach(
    name: 'Adobe',
    title: 'Adobe',
    domain: 'adobe.com',
    dataClasses: ['Email addresses', 'Passwords', 'Usernames'],
  );

  test('Passwort-Leak erzeugt kritischen Schritt', () {
    final actions = actionsForBreach(adobe);
    expect(actions.map((a) => a.id), contains('Adobe:pw_change'));
    expect(actions.first.severity, Severity.kritisch);
    // "Usernames" darf nicht als "Names" zählen
    expect(actions.map((a) => a.id), isNot(contains('Adobe:schufa')));
  });

  test('Score steigt, wenn Schritte erledigt werden', () {
    final before = computeScore([adobe], {});
    final after = computeScore([adobe], {'Adobe:pw_change', 'Adobe:pw_reuse'});
    expect(after.score, greaterThan(before.score));
    expect(computeScore([], {for (final a in generalActions) a.id}).score, 100);
  });

  test('k-Anonymität: Treffer im Bereich wird gefunden', () {
    const body = '0018A45C4D1DEF81644B54AB7F969B88D65:3\r\nABCDEF:0\r\n';
    expect(PasswordCheckService.countInRange(body, '0018A45C4D1DEF81644B54AB7F969B88D65'), 3);
    expect(PasswordCheckService.countInRange(body, 'FFFF'), 0);
  });

  test('Passwortstärke', () {
    expect(PasswordCheckService.estimateStrength('passwort1'), PasswordStrength.sehrSchwach);
    expect(PasswordCheckService.estimateStrength('Kaffee-Wolke-Tisch-Regen7'), PasswordStrength.stark);
  });

  test('DSGVO-Brief enthält Frist und Firma', () {
    final letter = buildLetter(
      type: DsgvoRequestType.auskunft,
      company: 'Adobe',
      name: 'Max Muster',
      email: 'max@example.org',
      today: DateTime(2026, 1, 1),
    );
    expect(letter.body, contains('An: Adobe'));
    expect(letter.body, contains('31.01.2026'));
    expect(letter.body, contains('Max Muster'));
  });
}
