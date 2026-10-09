import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logic/dsgvo_templates.dart';
import '../models/breach.dart';
import '../state/app_state.dart';
import 'widgets.dart';

/// Erstellt DSGVO-Anfragen. Name und Adresse bleiben auf dem Gerät.
class DsgvoScreen extends StatefulWidget {
  final AppState state;
  final Breach? breach;
  final DsgvoRequestType initialType;

  const DsgvoScreen({super.key, required this.state, this.breach, this.initialType = DsgvoRequestType.auskunft});

  @override
  State<DsgvoScreen> createState() => _DsgvoScreenState();
}

class _DsgvoScreenState extends State<DsgvoScreen> {
  late DsgvoRequestType _type = widget.initialType;
  late final _company = TextEditingController(text: widget.breach?.title ?? '');
  final _name = TextEditingController();
  final _email = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.state.store.letterName().then((n) {
      if (mounted && _name.text.isEmpty) setState(() => _name.text = n);
    });
  }

  @override
  void dispose() {
    _company.dispose();
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  DsgvoLetter get _letter => buildLetter(
        type: _type,
        company: _company.text.trim(),
        name: _name.text.trim(),
        email: _email.text.trim(),
        breachDate: widget.breach?.breachDate,
      );

  Future<void> _sendMail() async {
    await widget.state.store.saveLetterName(_name.text.trim());
    final letter = _letter;
    final uri = Uri(
      scheme: 'mailto',
      query: 'subject=${Uri.encodeComponent(letter.subject)}&body=${Uri.encodeComponent(letter.body)}',
    );
    if (!await launchUrl(uri) && mounted) {
      showError(context, 'Keine E-Mail-App gefunden – nutze „Kopieren“.');
    }
  }

  Future<void> _copy() async {
    await widget.state.store.saveLetterName(_name.text.trim());
    final letter = _letter;
    await Clipboard.setData(ClipboardData(text: '${letter.subject}\n\n${letter.body}'));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('In die Zwischenablage kopiert')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final letter = _letter;
    final domain = widget.breach?.domain;
    return Scaffold(
      appBar: AppBar(title: const Text('DSGVO-Anfrage')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<DsgvoRequestType>(
            segments: const [
              ButtonSegment(value: DsgvoRequestType.auskunft, label: Text('Auskunft')),
              ButtonSegment(value: DsgvoRequestType.loeschung, label: Text('Löschung')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _company,
            decoration: const InputDecoration(labelText: 'Unternehmen', border: OutlineInputBorder()),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Dein Name', border: OutlineInputBorder()),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-Mail-Adresse deines Kontos dort',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline),
                title: const Text('Wohin schicken?'),
                subtitle: Text(
                  'Die Adresse des Datenschutzbeauftragten steht in der Datenschutzerklärung '
                  '${domain != null ? 'von $domain' : 'des Unternehmens'} (oft datenschutz@…). '
                  'Das Unternehmen muss innerhalb eines Monats antworten. Kommt nichts, kannst du dich '
                  'kostenlos bei der Datenschutz-Aufsichtsbehörde beschweren.',
                ),
              ),
            ),
          ),
          if (domain != null)
            TextButton.icon(
              onPressed: () => openUrl(context, 'https://$domain'),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text('$domain öffnen'),
            ),
          const SizedBox(height: 8),
          Text('Vorschau', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText('Betreff: ${letter.subject}\n\n${letter.body}'),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(onPressed: _copy, icon: const Icon(Icons.copy), label: const Text('Kopieren')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _sendMail,
                icon: const Icon(Icons.send),
                label: const Text('Per E-Mail'),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => openUrl(context, 'https://www.bfdi.bund.de/DE/Service/Anschriften/Laender/Laender-node.html'),
            child: const Text('Datenschutz-Aufsichtsbehörden der Länder'),
          ),
          Text(
            'Mustervorlage zur Unterstützung – keine Rechtsberatung im Einzelfall.',
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
