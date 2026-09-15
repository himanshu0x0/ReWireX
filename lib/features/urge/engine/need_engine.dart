// lib/features/urge/engine/need_engine.dart

import '../data/urge_needs.dart';
import '../data/urge_types.dart';
import '../models/urge_session_model.dart';

/// The inferred underlying need behind an urge.
///
/// This engine is intentionally explainable and deterministic. It ranks a
/// small set of predefined needs instead of generating new needs dynamically.
class NeedInference {
  final NeedType selectedNeed;
  final List<NeedType> rankedNeeds;
  final Map<NeedType, double> scores;
  final Map<NeedType, List<String>> reasons;

  const NeedInference({
    required this.selectedNeed,
    required this.rankedNeeds,
    required this.scores,
    required this.reasons,
  });

  double scoreFor(NeedType need) => scores[need] ?? 0;

  List<String> reasonsFor(NeedType need) => reasons[need] ?? const [];

  bool contains(NeedType need) => rankedNeeds.contains(need);

  Map<String, dynamic> toMap() {
    return {
      'selectedNeed': selectedNeed.key,
      'rankedNeeds': rankedNeeds.map((e) => e.key).toList(),
      'scores': {
        for (final entry in scores.entries) entry.key.key: entry.value,
      },
      'reasons': {
        for (final entry in reasons.entries)
          entry.key.key: List<String>.from(entry.value),
      },
    };
  }
}

/// Determines the likely need underneath a user's urge.
///
/// Priority:
/// 1. An explicitly selected need wins.
/// 2. Strong signals from urge type, emotion, trigger and context are scored.
/// 3. The predefined default need ordering breaks ties.
/// 4. The result stays within the safe NeedType taxonomy.
class NeedEngine {
  const NeedEngine();

  NeedInference infer({
    required UrgeType urge,
    String? emotion,
    String? trigger,
    String? context,
    NeedType? selectedNeed,
  }) {
    final candidates = needsForUrge(urge);
    final scores = <NeedType, double>{};
    final reasons = <NeedType, List<dynamic>>{};

    for (var index = 0; index < candidates.length; index++) {
      final need = candidates[index];
      scores[need] = _baseScore(need, candidates.length - index);
      reasons[need] = [];
    }

    _applyEmotionSignals(
      scores: scores,
      reasons: reasons,
      emotion: emotion,
    );
    _applyTriggerSignals(
      scores: scores,
      reasons: reasons,
      trigger: trigger,
    );
    _applyContextSignals(
      scores: scores,
      reasons: reasons,
      context: context,
    );

    // An explicit user choice should always dominate inference.
    if (selectedNeed != null) {
      scores[selectedNeed] = (scores[selectedNeed] ?? 0) + 2.0;
      reasons.putIfAbsent(selectedNeed, () => []).add('Selected by you');

      if (!candidates.contains(selectedNeed)) {
        candidates.insert(0, selectedNeed);
      }
    }

    final ranked = candidates.toList(growable: false)
      ..sort((a, b) {
        final scoreCompare =
            (scores[b] ?? 0).compareTo(scores[a] ?? 0);
        if (scoreCompare != 0) return scoreCompare;
        return candidates.indexOf(a).compareTo(candidates.indexOf(b));
      });

    final chosen = selectedNeed ?? ranked.firstOrNull ?? NeedType.unknown;

    return NeedInference(
      selectedNeed: chosen,
      rankedNeeds: ranked,
      scores: Map.unmodifiable(scores),
      reasons: Map.unmodifiable({
        for (final entry in reasons.entries)
          entry.key: List<String>.from(
            entry.value.map((value) => value.toString()),
          ),
      }),
    );
  }

  /// Scores only the needs applicable to the supplied urge.
  Map<NeedType, double> score({
    required UrgeType urge,
    String? emotion,
    String? trigger,
    String? context,
  }) {
    return infer(
      urge: urge,
      emotion: emotion,
      trigger: trigger,
      context: context,
    ).scores;
  }

  /// Convenience wrapper for a partially completed rescue session.
  NeedInference inferFromSession(UrgeSessionModel session) {
    return infer(
      urge: session.urgeType,
      emotion: session.emotion,
      trigger: session.trigger,
      context: session.context,
      selectedNeed: session.selectedNeed,
    );
  }

  /// Returns the top N needs without changing the underlying inference.
  List<NeedType> topNeeds({
    required UrgeType urge,
    String? emotion,
    String? trigger,
    String? context,
    int limit = 3,
  }) {
    final safeLimit = limit.clamp(1, 10);
    return infer(
      urge: urge,
      emotion: emotion,
      trigger: trigger,
      context: context,
    ).rankedNeeds.take(safeLimit).toList(growable: false);
  }

  double _baseScore(NeedType need, int priority) {
    // The default ordering supplied by urge_needs.dart is meaningful, so use
    // a small deterministic decay instead of a large arbitrary difference.
    return 1.0 + (priority * 0.15);
  }

  void _applyEmotionSignals({
    required Map<NeedType, double> scores,
    required Map<NeedType, List<dynamic>> reasons,
    required String? emotion,
  }) {
    final value = _normalize(emotion);
    if (value.isEmpty) return;

    final rules = <NeedType, List<dynamic>>{
      NeedType.relief: [
        'anxious',
        'angry',
        'stressed',
        'panicked',
        'restless',
        'sad',
        'empty',
        'numb',
        'frustrated',
      ],
      NeedType.connection: [
        'lonely',
        'hopeless',
        'sad',
        'empty',
        'insecure',
      ],
      NeedType.reassurance: [
        'insecure',
        'anxious',
        'confused',
        'overthinking',
      ],
      NeedType.clarity: [
        'confused',
        'overthinking',
        'insecure',
      ],
      NeedType.release: [
        'angry',
        'frustrated',
        'restless',
      ],
      NeedType.selfCompassion: [
        'ashamed',
        'guilty',
        'sad',
        'hopeless',
        'depressed',
      ],
      NeedType.space: [
        'angry',
        'overwhelmed',
        'stressed',
        'frustrated',
      ],
      NeedType.control: [
        'angry',
        'frustrated',
        'insecure',
      ],
      NeedType.structure: [
        'unfocused',
        'bored',
        'apathetic',
        'confused',
      ],
      NeedType.stimulation: [
        'bored',
        'apathetic',
        'numb',
      ],
      NeedType.escape: [
        'stressed',
        'sad',
        'anxious',
        'overwhelmed',
      ],
    };

    for (final entry in rules.entries) {
      if (_containsAny(value, entry.value)) {
        _add(
          scores,
          reasons,
          entry.key,
          0.35,
          'Emotion: ${emotion!.trim()}',
        );
      }
    }
  }

  void _applyTriggerSignals({
    required Map<NeedType, double> scores,
    required Map<NeedType, List<dynamic>> reasons,
    required String? trigger,
  }) {
    final value = _normalize(trigger);
    if (value.isEmpty) return;

    final rules = <NeedType, List<dynamic>>{
      NeedType.connection: [
        'ignored',
        'rejection',
        'seeing a couple',
        'missing the feeling',
      ],
      NeedType.validation: [
        'rejection',
        'criticism',
        'ignored',
        'social media post',
      ],
      NeedType.reassurance: [
        'ignored',
        'seeing their name',
        'old memory',
        'photo',
      ],
      NeedType.control: [
        'argument',
        'conflict',
        'rejection',
        'criticism',
      ],
      NeedType.release: [
        'argument',
        'conflict',
        'anxiety spike',
        'physical tension',
      ],
      NeedType.relief: [
        'work stress',
        'late night',
        'anxiety spike',
        'physical tension',
      ],
      NeedType.escape: [
        'boredom',
        'idle time',
        'work stress',
        'late night',
      ],
      NeedType.stimulation: [
        'boredom',
        'idle time',
        'phone in hand',
      ],
      NeedType.space: [
        'argument',
        'conflict',
        'rejection',
      ],
    };

    for (final entry in rules.entries) {
      if (_containsAny(value, entry.value)) {
        _add(
          scores,
          reasons,
          entry.key,
          0.40,
          'Trigger: ${trigger!.trim()}',
        );
      }
    }
  }

  void _applyContextSignals({
    required Map<NeedType, double> scores,
    required Map<NeedType, List<dynamic>> reasons,
    required String? context,
  }) {
    final value = _normalize(context);
    if (value.isEmpty) return;

    final rules = <NeedType, List<dynamic>>{
      NeedType.connection: [
        'alone at home',
        'alone',
        'commuting',
      ],
      NeedType.space: [
        'after a fight',
        'public',
        'friends',
      ],
      NeedType.relief: [
        'in bed',
        'late at night',
        'after drinking',
      ],
      NeedType.structure: [
        'work study',
        'idle',
        'alone at home',
      ],
      NeedType.escape: [
        'in bed',
        'late at night',
        'on phone',
        'alone at home',
      ],
      NeedType.stimulation: [
        'on phone',
        'commuting',
        'idle',
      ],
      NeedType.control: [
        'after a fight',
      ],
    };

    for (final entry in rules.entries) {
      if (_containsAny(value, entry.value)) {
        _add(
          scores,
          reasons,
          entry.key,
          0.25,
          'Context: ${context!.trim()}',
        );
      }
    }
  }

  void _add(
    Map<NeedType, double> scores,
    Map<NeedType, List<dynamic>> reasons,
    NeedType need,
    double amount,
    String reason,
  ) {
    if (!scores.containsKey(need)) return;
    scores[need] = (scores[need] ?? 0) + amount;
    final list = reasons.putIfAbsent(need, () => <dynamic>[]);
    list.add(reason);
  }

  static String _normalize(String? value) {
    if (value == null) return '';
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _containsAny(String input, Iterable<dynamic> values) {
    for (final value in values) {
      final normalized = _normalize(value?.toString());
      if (normalized.isEmpty) continue;

      final pattern =
          RegExp(r'(^|\\s)' + RegExp.escape(normalized) + r'($|\\s)');

      if (input == normalized || pattern.hasMatch(input)) {
        return true;
      }
    }

    return false;
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
