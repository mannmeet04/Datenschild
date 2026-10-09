import 'package:flutter/foundation.dart';

import '../logic/security_score.dart';
import '../models/breach.dart';
import '../services/api_client.dart';
import '../services/local_store.dart';

class AppState extends ChangeNotifier {
  final ApiClient api;
  final LocalStore store;

  AppState({ApiClient? api, LocalStore? store})
      : api = api ?? ApiClient(),
        store = store ?? LocalStore();

  List<MonitoredEmail> emails = [];
  Set<String> doneActions = {};
  String attribution = '';
  bool loading = false;
  String? error;

  Future<void> init() async {
    doneActions = await store.doneActions();
    notifyListeners();
    await reload();
    try {
      attribution = await api.attribution();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> reload() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      emails = await api.listEmails();
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Alle Leaks über alle bestätigten Adressen, ohne Doppelte.
  List<Breach> get breaches {
    final byName = <String, Breach>{};
    for (final email in emails.where((e) => e.verified)) {
      for (final b in email.breaches) {
        byName.putIfAbsent(b.name, () => b);
      }
    }
    final list = byName.values.toList()
      ..sort((a, b) => (b.breachDate ?? '').compareTo(a.breachDate ?? ''));
    return list;
  }

  ScoreResult get score => computeScore(breaches, doneActions);

  bool isDone(String actionId) => doneActions.contains(actionId);

  Future<void> toggleAction(String actionId) async {
    doneActions = {...doneActions};
    if (!doneActions.remove(actionId)) doneActions.add(actionId);
    notifyListeners();
    await store.saveDoneActions(doneActions);
  }

  void replaceEmail(MonitoredEmail updated) {
    final index = emails.indexWhere((e) => e.id == updated.id);
    if (index >= 0) {
      emails = [...emails]..[index] = updated;
    } else {
      emails = [...emails, updated];
    }
    notifyListeners();
  }

  Future<void> deleteEmail(String id) async {
    await api.deleteEmail(id);
    emails = emails.where((e) => e.id != id).toList();
    notifyListeners();
  }

  Future<void> deleteEverything() async {
    await api.deleteEverything();
    await store.clear();
    emails = [];
    doneActions = {};
    notifyListeners();
  }
}
