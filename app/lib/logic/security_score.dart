import '../models/breach.dart';
import 'action_plan.dart';

class ScoreResult {
  final int score;
  final List<ActionItem> openActions;

  const ScoreResult(this.score, this.openActions);

  String get label {
    if (score >= 85) return 'Sehr gut geschützt';
    if (score >= 65) return 'Gut, aber ausbaufähig';
    if (score >= 40) return 'Handlungsbedarf';
    return 'Dringender Handlungsbedarf';
  }
}

/// Max. Abzug pro Leak, damit viele alte Leaks den Score nicht sofort auf 0 drücken.
const _maxPenaltyPerBreach = 30;

ScoreResult computeScore(List<Breach> breaches, Set<String> done) {
  var penalty = 0;
  final open = <ActionItem>[];

  for (final item in generalActions) {
    if (!done.contains(item.id)) {
      penalty += item.weight;
      open.add(item);
    }
  }
  for (final breach in breaches) {
    var breachPenalty = 0;
    for (final item in actionsForBreach(breach)) {
      if (!done.contains(item.id)) {
        breachPenalty += item.weight;
        open.add(item);
      }
    }
    penalty += breachPenalty > _maxPenaltyPerBreach ? _maxPenaltyPerBreach : breachPenalty;
  }

  open.sort((a, b) => b.weight.compareTo(a.weight));
  return ScoreResult((100 - penalty).clamp(0, 100).toInt(), open);
}
