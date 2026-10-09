import 'package:flutter/material.dart';

import '../models/breach.dart';
import '../services/api_client.dart';
import '../state/app_state.dart';
import 'breach_detail_screen.dart';
import 'widgets.dart';

class EmailsScreen extends StatelessWidget {
  final AppState state;

  const EmailsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addEmail(context),
        icon: const Icon(Icons.add),
        label: const Text('Adresse hinzufügen'),
      ),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) => RefreshIndicator(
          onRefresh: state.reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Text('Überwachte E-Mail-Adressen', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Wir prüfen täglich, ob deine Adressen in neuen Datenlecks auftauchen, und benachrichtigen dich per E-Mail.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              if (state.loading && state.emails.isEmpty) const Center(child: CircularProgressIndicator()),
              for (final email in state.emails) _EmailCard(email: email, state: state),
              if (state.attribution.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(state.attribution, style: Theme.of(context).textTheme.labelSmall),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addEmail(BuildContext context) async {
    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('E-Mail-Adresse hinzufügen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'E-Mail-Adresse'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Du bekommst einen Bestätigungscode. Ergebnisse zeigen wir nur für Adressen, die dir gehören.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Weiter')),
        ],
      ),
    );
    if (email == null || email.isEmpty || !context.mounted) return;
    try {
      final added = await state.api.addEmail(email);
      state.replaceEmail(added);
      if (context.mounted) await verifyDialog(context, state, added);
    } on ApiException catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}

Future<void> verifyDialog(BuildContext context, AppState state, MonitoredEmail email) async {
  final controller = TextEditingController();
  final code = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Code eingeben'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Wir haben einen 6-stelligen Code an ${email.maskedEmail} geschickt.'),
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(labelText: 'Bestätigungscode'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Später')),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Bestätigen')),
      ],
    ),
  );
  if (code == null || code.isEmpty) return;
  try {
    state.replaceEmail(await state.api.verify(email.id, code));
  } on ApiException catch (e) {
    if (context.mounted) showError(context, e);
  }
}

class _EmailCard extends StatelessWidget {
  final MonitoredEmail email;
  final AppState state;

  const _EmailCard({required this.email, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = email.breaches.length;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(
              !email.verified ? Icons.hourglass_empty : count == 0 ? Icons.verified_user : Icons.warning_amber,
              color: !email.verified ? null : count == 0 ? Colors.green.shade600 : Colors.red.shade700,
            ),
            title: Text(email.maskedEmail),
            subtitle: Text(!email.verified
                ? 'Noch nicht bestätigt'
                : count == 0
                    ? 'Keine Leaks gefunden'
                    : '$count ${count == 1 ? 'Leak' : 'Leaks'} gefunden'),
            trailing: PopupMenuButton<String>(
              onSelected: (action) => _onMenu(context, action),
              itemBuilder: (_) => [
                if (email.verified) const PopupMenuItem(value: 'refresh', child: Text('Jetzt prüfen')),
                if (!email.verified) const PopupMenuItem(value: 'resend', child: Text('Code erneut senden')),
                const PopupMenuItem(value: 'delete', child: Text('Überwachung beenden')),
              ],
            ),
          ),
          if (!email.verified)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: OutlinedButton(
                onPressed: () => verifyDialog(context, state, email),
                child: const Text('Code eingeben'),
              ),
            ),
          for (final breach in email.breaches)
            ListTile(
              dense: true,
              title: Text(breach.title),
              subtitle: Text([
                if (breach.breachDate != null) breach.breachDate!,
                if (breach.dataClasses.isNotEmpty) '${breach.dataClasses.length} Datenarten',
              ].join(' · ')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BreachDetailScreen(breach: breach, state: state),
              )),
            ),
          if (email.lastCheckedAt != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'Zuletzt geprüft: ${MaterialLocalizations.of(context).formatShortDate(email.lastCheckedAt!)}',
                style: theme.textTheme.labelSmall,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onMenu(BuildContext context, String action) async {
    try {
      switch (action) {
        case 'refresh':
          state.replaceEmail(await state.api.refresh(email.id));
        case 'resend':
          await state.api.resendCode(email.id);
          if (context.mounted) await verifyDialog(context, state, email);
        case 'delete':
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Überwachung beenden?'),
              content: Text('${email.maskedEmail} wird sofort von unserem Server gelöscht.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Löschen')),
              ],
            ),
          );
          if (confirmed == true) await state.deleteEmail(email.id);
      }
    } on ApiException catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}
