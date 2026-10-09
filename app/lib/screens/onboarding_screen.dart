import 'package:flutter/material.dart';

import 'legal_screen.dart';

class OnboardingScreen extends StatelessWidget {
  final VoidCallback onDone;

  const OnboardingScreen({super.key, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Icon(Icons.shield, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('Willkommen bei Datenschild', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 24),
              const _Point(Icons.search, 'Finde heraus, ob deine Daten in Datenlecks aufgetaucht sind.'),
              const _Point(Icons.checklist, 'Erhalte einen konkreten Plan, was du jetzt tun solltest.'),
              const _Point(Icons.gavel, 'Nutze deine Rechte aus der DSGVO mit fertigen Vorlagen.'),
              const _Point(Icons.lock, 'Kein Konto, kein Tracking, keine Werbung. Passwörter verlassen nie dein Gerät.'),
              const Spacer(),
              Text(
                'Für die Überwachung speichern wir deine bestätigten E-Mail-Adressen verschlüsselt auf einem '
                'Server in der EU und fragen sie bei einem Leak-Dienst ab. Details in der Datenschutzerklärung.',
                style: theme.textTheme.bodySmall,
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const LegalScreen(title: 'Datenschutzerklärung', asset: 'assets/legal/datenschutz.txt'),
                )),
                child: const Text('Datenschutzerklärung lesen'),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: onDone, child: const Text('Los geht\'s')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Point(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
          ],
        ),
      );
}
