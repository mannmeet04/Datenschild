import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Zeigt Datenschutzerklärung / Impressum aus assets/legal an.
class LegalScreen extends StatelessWidget {
  final String title;
  final String asset;

  const LegalScreen({super.key, required this.title, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(asset),
        builder: (context, snapshot) => snapshot.hasData
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SelectableText(snapshot.data!),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
