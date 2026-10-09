import 'package:flutter/foundation.dart';

/// Backend-Adresse. Beim Bauen überschreiben:
/// flutter run --dart-define=API_BASE_URL=https://api.deine-domain.de
///
/// Standard: im Browser localhost, im Android-Emulator 10.0.2.2 (= der eigene PC).
const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

String get apiBaseUrl {
  if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
  return kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';
}

const String pwnedPasswordsUrl = 'https://api.pwnedpasswords.com/range/';
