import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'dsgvo_screen.dart';
import 'emergency_screen.dart';
import 'legal_screen.dart';
import 'widgets.dart';

class MoreScreen extends StatelessWidget {
  final AppState state;

  const MoreScreen({super.key, required this.state});

  void _push(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const _Header('Werkzeuge'),
        ListTile(
          leading: const Icon(Icons.sos),
          title: const Text('Notfall-Hilfe'),
          subtitle: const Text('Handy, Karte oder Ausweis weg? Konto gehackt?'),
          onTap: () => _push(context, const EmergencyScreen()),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('DSGVO-Anfrage erstellen'),
          subtitle: const Text('Auskunft oder Löschung bei beliebigen Firmen'),
          onTap: () => _push(context, DsgvoScreen(state: state)),
        ),
        const _Header('Rechtliches'),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Datenschutzerklärung'),
          onTap: () => _push(context,
              const LegalScreen(title: 'Datenschutzerklärung', asset: 'assets/legal/datenschutz.txt')),
        ),
        ListTile(
          leading: const Icon(Icons.business),
          title: const Text('Impressum'),
          onTap: () => _push(context, const LegalScreen(title: 'Impressum', asset: 'assets/legal/impressum.txt')),
        ),
        ListTile(
          leading: const Icon(Icons.source_outlined),
          title: const Text('Datenquellen & Lizenzen'),
          onTap: () => showLicensePage(
            context: context,
            applicationName: 'Datenschild',
            applicationLegalese: '${state.attribution}\n'
                'Passwortprüfung: Pwned Passwords von Have I Been Pwned (CC BY 4.0)\n'
                '2FA-Informationen: 2fa.directory',
          ),
        ),
        const _Header('Deine Daten'),
        ListTile(
          leading: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
          title: const Text('Alle meine Daten löschen'),
          subtitle: const Text('Entfernt alle Adressen vom Server und setzt die App zurück'),
          onTap: () => _deleteAll(context),
        ),
      ],
    );
  }

  Future<void> _deleteAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alle Daten löschen?'),
        content: const Text(
            'Alle überwachten Adressen werden sofort und endgültig von unserem Server gelöscht. '
            'Deine erledigten Schritte auf diesem Gerät werden ebenfalls zurückgesetzt.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Endgültig löschen')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await state.deleteEverything();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alle Daten wurden gelöscht')));
      }
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}

class _Header extends StatelessWidget {
  final String text;

  const _Header(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );
}
