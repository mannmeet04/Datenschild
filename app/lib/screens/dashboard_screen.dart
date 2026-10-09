import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'widgets.dart';

class DashboardScreen extends StatelessWidget {
  final AppState state;
  final VoidCallback onOpenEmails;

  const DashboardScreen({super.key, required this.state, required this.onOpenEmails});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final score = state.score;
        final theme = Theme.of(context);
        final color = score.score >= 65
            ? Colors.green.shade600
            : score.score >= 40
                ? Colors.amber.shade800
                : Colors.red.shade700;
        final verifiedCount = state.emails.where((e) => e.verified).length;

        return RefreshIndicator(
          onRefresh: state.reload,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Dein Sicherheits-Score', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: 160,
                  height: 160,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: score.score / 100,
                        strokeWidth: 12,
                        color: color,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                      Center(
                        child: Text('${score.score}', style: theme.textTheme.displayMedium?.copyWith(color: color)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(child: Text(score.label, style: theme.textTheme.titleMedium)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _Stat(label: 'Überwachte Adressen', value: '$verifiedCount'),
                  _Stat(label: 'Gefundene Leaks', value: '${state.breaches.length}'),
                  _Stat(label: 'Offene Schritte', value: '${score.openActions.length}'),
                ],
              ),
              if (state.error != null) ...[
                const SizedBox(height: 12),
                Card(
                  color: theme.colorScheme.errorContainer,
                  child: ListTile(leading: const Icon(Icons.cloud_off), title: Text(state.error!)),
                ),
              ],
              if (verifiedCount == 0) ...[
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.mail),
                    title: const Text('Füge deine E-Mail-Adresse hinzu'),
                    subtitle: const Text('Wir prüfen, ob sie in Datenlecks vorkommt, und warnen dich bei neuen.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: onOpenEmails,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text('Deine nächsten Schritte', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              if (score.openActions.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.verified, color: Colors.green),
                    title: Text('Alles erledigt – stark!'),
                  ),
                ),
              for (final item in score.openActions.take(6)) ActionTile(item: item, state: state),
            ],
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              children: [
                Text(value, style: Theme.of(context).textTheme.headlineSmall),
                Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      );
}
