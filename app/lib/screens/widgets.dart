import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logic/action_plan.dart';
import '../state/app_state.dart';

Color severityColor(BuildContext context, Severity s) => switch (s) {
      Severity.kritisch => Colors.red.shade700,
      Severity.hoch => Colors.deepOrange,
      Severity.mittel => Colors.amber.shade800,
      Severity.niedrig => Theme.of(context).colorScheme.outline,
    };

Future<void> openUrl(BuildContext context, String url) async {
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Konnte $url nicht öffnen')));
  }
}

void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
}

/// Ein abhakbarer Schritt des Handlungsplans.
class ActionTile extends StatelessWidget {
  final ActionItem item;
  final AppState state;

  const ActionTile({super.key, required this.item, required this.state});

  @override
  Widget build(BuildContext context) {
    final done = state.isDone(item.id);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(value: done, onChanged: (_) => state.toggleAction(item.id)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          decoration: done ? TextDecoration.lineThrough : null,
                        ),
                  ),
                  const SizedBox(height: 4),
                  if (!done) Text(item.description, style: Theme.of(context).textTheme.bodySmall),
                  if (!done && item.url != null)
                    TextButton.icon(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () => openUrl(context, item.url!),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: Text(item.url!.startsWith('tel:') ? 'Jetzt anrufen' : 'Öffnen'),
                    ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: severityColor(context, item.severity), shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }
}
