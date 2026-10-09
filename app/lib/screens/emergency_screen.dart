import 'package:flutter/material.dart';

import 'widgets.dart';

class _Step {
  final String text;
  final String? url;
  final String? urlLabel;

  const _Step(this.text, [this.url, this.urlLabel]);
}

class _Scenario {
  final IconData icon;
  final String title;
  final List<_Step> steps;

  const _Scenario(this.icon, this.title, this.steps);
}

const _scenarios = [
  _Scenario(Icons.credit_card_off, 'Bankkarte verloren oder Betrug am Konto', [
    _Step('Karte sofort sperren – rund um die Uhr, kostenlos.', 'tel:116116', 'Sperr-Notruf 116 116'),
    _Step('Bank informieren und unbekannte Buchungen reklamieren.'),
    _Step('Bei Diebstahl oder Betrug Anzeige bei der Polizei erstatten (auch online möglich).'),
  ]),
  _Scenario(Icons.phone_android, 'Handy verloren oder gestohlen', [
    _Step('Gerät orten und sperren bzw. löschen (Google „Mein Gerät finden“ / Apple „Wo ist?“).',
        'https://www.google.com/android/find', 'Mein Gerät finden'),
    _Step('SIM-Karte beim Mobilfunkanbieter sperren lassen – sonst können SMS-Codes abgefangen werden.'),
    _Step('Passwörter von E-Mail, Banking und Messenger ändern und fremde Sitzungen abmelden.'),
    _Step('Diebstahl bei der Polizei anzeigen (IMEI bereithalten).'),
  ]),
  _Scenario(Icons.badge, 'Personalausweis verloren', [
    _Step('Verlust beim Bürgeramt oder bei der Polizei melden – der Ausweis wird gesperrt.'),
    _Step('Online-Ausweisfunktion sperren lassen.', 'tel:116116', 'Sperr-Notruf 116 116'),
    _Step('Kostenlose Schufa-Selbstauskunft anfordern und auf unbekannte Verträge achten.',
        'https://www.meineschufa.de/de/datenkopie', 'Schufa-Datenkopie'),
  ]),
  _Scenario(Icons.no_accounts, 'Konto gehackt', [
    _Step('Passwort über „Passwort vergessen“ zurücksetzen und alle Sitzungen abmelden.'),
    _Step('E-Mail-Postfach zuerst absichern – darüber lassen sich alle anderen Konten übernehmen.'),
    _Step('Zwei-Faktor-Anmeldung aktivieren.', 'https://2fa.directory/de/', '2FA-Verzeichnis'),
    _Step('Kontakte warnen, falls in deinem Namen Nachrichten verschickt wurden.'),
    _Step('Hilfe und Infos vom BSI.',
        'https://www.bsi.bund.de/DE/Themen/Verbraucherinnen-und-Verbraucher/Cyber-Sicherheitslage/Methoden-der-Cyber-Kriminalitaet/Identitaetsdiebstahl/identitaetsdiebstahl_node.html',
        'BSI: Identitätsdiebstahl'),
  ]),
  _Scenario(Icons.sms_failed, 'Auf Phishing hereingefallen', [
    _Step('Eingegebene Passwörter sofort ändern.'),
    _Step('Bankdaten oder TAN weitergegeben? Sofort Bank anrufen und Konto sperren lassen.', 'tel:116116',
        'Sperr-Notruf 116 116'),
    _Step('Phishing-Mail an die Verbraucherzentrale melden.',
        'https://www.verbraucherzentrale.nrw/phishing-radar', 'Phishing-Radar'),
  ]),
];

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notfall-Hilfe')),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          for (final scenario in _scenarios)
            Card(
              child: ExpansionTile(
                leading: Icon(scenario.icon),
                title: Text(scenario.title),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                children: [
                  for (final (i, step) in scenario.steps.indexed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(radius: 12, child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(step.text),
                                if (step.url != null)
                                  TextButton.icon(
                                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                    onPressed: () => openUrl(context, step.url!),
                                    icon: Icon(step.url!.startsWith('tel:') ? Icons.call : Icons.open_in_new,
                                        size: 16),
                                    label: Text(step.urlLabel ?? 'Öffnen'),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Bei akuter Gefahr: Polizei 110.'),
          ),
        ],
      ),
    );
  }
}
