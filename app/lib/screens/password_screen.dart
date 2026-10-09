import 'package:flutter/material.dart';

import '../services/password_check.dart';
import 'widgets.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _controller = TextEditingController();
  final _service = PasswordCheckService();
  bool _obscure = true;
  bool _checking = false;
  PasswordCheckResult? _result;

  @override
  void dispose() {
    _controller.clear();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final password = _controller.text;
    if (password.isEmpty) return;
    setState(() => _checking = true);
    try {
      final result = await _service.check(password);
      setState(() => _result = result);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Passwort prüfen', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Dein Passwort verlässt dieses Gerät nicht. Wir senden nur die ersten 5 Zeichen eines '
          'Fingerabdrucks (SHA-1-Hash) und vergleichen den Rest lokal (k-Anonymität).',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          obscureText: _obscure,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.visiblePassword,
          onChanged: (_) => setState(() => _result = null),
          onSubmitted: (_) => _check(),
          decoration: InputDecoration(
            labelText: 'Passwort',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _checking ? null : _check,
          icon: _checking
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.search),
          label: const Text('Prüfen'),
        ),
        if (_result != null) ...[
          const SizedBox(height: 16),
          _ResultCard(result: _result!),
        ],
        const SizedBox(height: 24),
        Text('So sieht ein gutes Passwort aus', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text('• Mindestens 12 Zeichen – besser eine Passphrase aus 4–5 zufälligen Wörtern\n'
            '• Für jeden Dienst ein eigenes Passwort\n'
            '• Keine Namen, Geburtsdaten oder Tastaturmuster\n'
            '• Am einfachsten: ein Passwort-Manager erzeugt und merkt sich alles'),
        const SizedBox(height: 24),
        Text('Passwortprüfung: Pwned Passwords von Have I Been Pwned (CC BY 4.0)',
            style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final PasswordCheckResult result;

  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final leaked = result.breachCount > 0;
    final (strengthText, strengthValue, strengthColor) = switch (result.strength) {
      PasswordStrength.sehrSchwach => ('Sehr schwach', 0.15, Colors.red.shade700),
      PasswordStrength.schwach => ('Schwach', 0.4, Colors.deepOrange),
      PasswordStrength.mittel => ('Mittel', 0.7, Colors.amber.shade800),
      PasswordStrength.stark => ('Stark', 1.0, Colors.green.shade600),
    };
    return Card(
      color: leaked ? Theme.of(context).colorScheme.errorContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(leaked ? Icons.warning_amber : Icons.check_circle,
                  color: leaked ? Colors.red.shade700 : Colors.green.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  leaked
                      ? 'Dieses Passwort wurde ${result.breachCount}× in Datenlecks gefunden. Nicht mehr verwenden!'
                      : 'Nicht in bekannten Datenlecks gefunden.',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ]),
            const SizedBox(height: 16),
            Text('Stärke: $strengthText'),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: strengthValue, color: strengthColor, minHeight: 8),
          ],
        ),
      ),
    );
  }
}
