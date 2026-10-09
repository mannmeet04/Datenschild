import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

class PasswordCheckResult {
  /// Wie oft das Passwort in bekannten Leaks vorkam (0 = nicht gefunden).
  final int breachCount;
  final PasswordStrength strength;

  const PasswordCheckResult(this.breachCount, this.strength);
}

enum PasswordStrength { sehrSchwach, schwach, mittel, stark }

/// Prüft Passwörter per k-Anonymität: Nur die ersten 5 Zeichen des SHA-1-Hashes
/// verlassen das Gerät. Das Passwort selbst wird nie übertragen oder gespeichert.
class PasswordCheckService {
  final http.Client _http;

  PasswordCheckService({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  Future<PasswordCheckResult> check(String password) async {
    final hash = sha1.convert(utf8.encode(password)).toString().toUpperCase();
    final prefix = hash.substring(0, 5);
    final suffix = hash.substring(5);

    // Add-Padding verhindert, dass die Antwortgröße Rückschlüsse zulässt
    final response = await _http
        .get(Uri.parse('$pwnedPasswordsUrl$prefix'), headers: {'Add-Padding': 'true'})
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Passwortprüfung derzeit nicht möglich (${response.statusCode})');
    }
    return PasswordCheckResult(countInRange(response.body, suffix), estimateStrength(password));
  }

  static int countInRange(String body, String suffix) {
    for (final line in const LineSplitter().convert(body)) {
      final parts = line.split(':');
      if (parts.length == 2 && parts[0].trim() == suffix) {
        return int.tryParse(parts[1].trim()) ?? 0;
      }
    }
    return 0;
  }

  static const _common = [
    'passwort', 'password', 'hallo', 'schatz', 'qwertz', 'qwerty', 'asdf', 'dragon', 'fussball',
    'schalke', 'master', 'sommer', 'winter', 'liebe', 'admin', 'welcome', 'letmein', '123456',
  ];

  /// Einfache Offline-Schätzung (Länge, Zeichenarten, bekannte Muster).
  static PasswordStrength estimateStrength(String password) {
    if (password.length < 8) return PasswordStrength.sehrSchwach;
    var classes = 0;
    if (RegExp(r'[a-zäöüß]').hasMatch(password)) classes++;
    if (RegExp(r'[A-ZÄÖÜ]').hasMatch(password)) classes++;
    if (RegExp(r'\d').hasMatch(password)) classes++;
    if (RegExp(r'[^A-Za-z0-9äöüÄÖÜß]').hasMatch(password)) classes++;

    var points = password.length >= 16 ? 3 : password.length >= 12 ? 2 : 1;
    points += classes >= 3 ? 2 : classes == 2 ? 1 : 0;
    final lower = password.toLowerCase();
    if (_common.any(lower.contains)) points -= 2;
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) points -= 1;
    if (RegExp(r'(19|20)\d\d').hasMatch(password)) points -= 1;

    if (points >= 5) return PasswordStrength.stark;
    if (points >= 3) return PasswordStrength.mittel;
    if (points >= 1) return PasswordStrength.schwach;
    return PasswordStrength.sehrSchwach;
  }
}
