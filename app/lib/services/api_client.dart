import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/breach.dart';

class ApiException implements Exception {
  final int status;
  final String message;

  ApiException(this.status, this.message);

  @override
  String toString() => message;
}

/// Spricht mit dem Datenschild-Backend. Es gibt kein Benutzerkonto: Das Gerät
/// erhält ein zufälliges Token, das nur im sicheren Speicher (Keychain/Keystore) liegt.
class ApiClient {
  static const _tokenKey = 'device_token';
  static const _timeout = Duration(seconds: 20);

  final http.Client _http;
  final FlutterSecureStorage _storage;

  ApiClient({http.Client? httpClient, FlutterSecureStorage? storage})
      : _http = httpClient ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  Future<List<MonitoredEmail>> listEmails() async {
    final data = await _send('GET', '/api/v1/emails') as List;
    return data.map((e) => MonitoredEmail.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MonitoredEmail> addEmail(String email) async =>
      MonitoredEmail.fromJson(await _send('POST', '/api/v1/emails', body: {'email': email}));

  Future<MonitoredEmail> verify(String id, String code) async =>
      MonitoredEmail.fromJson(await _send('POST', '/api/v1/emails/$id/verify', body: {'code': code}));

  Future<void> resendCode(String id) => _send('POST', '/api/v1/emails/$id/resend');

  Future<MonitoredEmail> refresh(String id) async =>
      MonitoredEmail.fromJson(await _send('POST', '/api/v1/emails/$id/refresh'));

  Future<void> deleteEmail(String id) => _send('DELETE', '/api/v1/emails/$id');

  Future<String> attribution() async {
    final data = await _send('GET', '/api/v1/meta', auth: false) as Map<String, dynamic>;
    return data['attribution'] as String;
  }

  /// Recht auf Löschung: entfernt alle Daten auf dem Server und das lokale Token.
  Future<void> deleteEverything() async {
    final token = await _storage.read(key: _tokenKey);
    if (token != null) {
      await _send('DELETE', '/api/v1/devices/me');
    }
    await _storage.delete(key: _tokenKey);
  }

  Future<String> _token() async {
    final existing = await _storage.read(key: _tokenKey);
    if (existing != null) return existing;
    final data = await _send('POST', '/api/v1/devices', auth: false) as Map<String, dynamic>;
    final token = data['token'] as String;
    await _storage.write(key: _tokenKey, value: token);
    return token;
  }

  Future<dynamic> _send(String method, String path,
      {Object? body, bool auth = true, bool retried = false}) async {
    final request = http.Request(method, Uri.parse('$apiBaseUrl$path'));
    if (auth) request.headers['Authorization'] = 'Bearer ${await _token()}';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      response = await http.Response.fromStream(await _http.send(request).timeout(_timeout));
    } on TimeoutException {
      throw ApiException(0, 'Zeitüberschreitung – bitte Internetverbindung prüfen');
    } catch (_) {
      throw ApiException(0, 'Server nicht erreichbar – bitte Internetverbindung prüfen');
    }

    // Gerät wurde serverseitig gelöscht (z. B. nach langer Inaktivität): neu registrieren
    if (response.statusCode == 401 && auth && !retried) {
      await _storage.delete(key: _tokenKey);
      return _send(method, path, body: body, auth: auth, retried: true);
    }

    final text = utf8.decode(response.bodyBytes);
    if (response.statusCode >= 400) {
      String message = 'Fehler ${response.statusCode}';
      try {
        message = (jsonDecode(text) as Map<String, dynamic>)['error'] as String? ?? message;
      } catch (_) {}
      throw ApiException(response.statusCode, message);
    }
    return text.isEmpty ? null : jsonDecode(text);
  }
}
