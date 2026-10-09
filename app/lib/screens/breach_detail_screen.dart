import 'package:flutter/material.dart';

import '../logic/action_plan.dart';
import '../logic/dsgvo_templates.dart';
import '../models/breach.dart';
import '../state/app_state.dart';
import 'dsgvo_screen.dart';
import 'widgets.dart';

/// Übersetzung der häufigsten Datenarten der Leak-Anbieter.
const _dataClassDe = {
  'email addresses': 'E-Mail-Adressen',
  'passwords': 'Passwörter',
  'names': 'Namen',
  'usernames': 'Benutzernamen',
  'phone numbers': 'Telefonnummern',
  'physical addresses': 'Postanschriften',
  'dates of birth': 'Geburtsdaten',
  'ip addresses': 'IP-Adressen',
  'genders': 'Geschlecht',
  'geographic locations': 'Standorte',
  'credit cards': 'Kreditkarten',
  'partial credit card data': 'Teile von Kreditkartendaten',
  'bank account numbers': 'Kontonummern',
  'security questions and answers': 'Sicherheitsfragen',
  'job titles': 'Berufsbezeichnungen',
  'employers': 'Arbeitgeber',
  'social media profiles': 'Social-Media-Profile',
  'government issued ids': 'Ausweisdaten',
  'private messages': 'Private Nachrichten',
};

String dataClassDe(String c) => _dataClassDe[c.toLowerCase()] ?? c;

class BreachDetailScreen extends StatelessWidget {
  final Breach breach;
  final AppState state;

  const BreachDetailScreen({super.key, required this.breach, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actions = actionsForBreach(breach);
    return Scaffold(
      appBar: AppBar(title: Text(breach.title)),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(spacing: 16, runSpacing: 4, children: [
              if (breach.breachDate != null) _Meta(Icons.event, 'Leak: ${breach.breachDate}'),
              if (breach.domain != null) _Meta(Icons.language, breach.domain!),
              if (breach.records != null) _Meta(Icons.people, '${_formatNumber(breach.records!)} Konten'),
              if (breach.verified) const _Meta(Icons.verified, 'Bestätigt'),
            ]),
            const SizedBox(height: 16),
            Text('Was ist geleakt?', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final c in breach.dataClasses) Chip(label: Text(dataClassDe(c)))],
            ),
            if (breach.description != null) ...[
              const SizedBox(height: 16),
              Text(breach.description!, style: theme.textTheme.bodyMedium),
              Text('(Beschreibung des Datenanbieters, englisch)', style: theme.textTheme.labelSmall),
            ],
            const SizedBox(height: 24),
            Text('Dein Handlungsplan', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (actions.isEmpty)
              const Card(child: ListTile(title: Text('Für diese Datenarten ist nichts weiter zu tun.'))),
            for (final item in actions) ActionTile(item: item, state: state),
            const SizedBox(height: 24),
            Text('Deine Rechte nach der DSGVO', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Du kannst ${breach.title} fragen, welche Daten gespeichert sind, und die Löschung verlangen.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            for (final type in DsgvoRequestType.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.description_outlined),
                  label: Text('${type.label} erstellen'),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => DsgvoScreen(state: state, breach: breach, initialType: type),
                  )),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatNumber(int n) {
    final s = n.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Meta(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ]);
}
