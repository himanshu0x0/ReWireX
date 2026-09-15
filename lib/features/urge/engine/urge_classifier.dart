// lib/features/urge/engine/urge_classifier.dart

import '../data/urge_types.dart';

/// How an urge classification was obtained.
enum UrgeClassificationSource {
  exact,
  keyword,
  semantic,
  fallback,
}

extension UrgeClassificationSourceX on UrgeClassificationSource {
  String get key => switch (this) {
        UrgeClassificationSource.exact => 'exact',
        UrgeClassificationSource.keyword => 'keyword',
        UrgeClassificationSource.semantic => 'semantic',
        UrgeClassificationSource.fallback => 'fallback',
      };
}

/// Result of converting a legacy/free-text urge into the typed urge taxonomy.
///
/// This classifier is intentionally conservative. It does not decide whether a
/// user has relapsed and it does not perform crisis diagnosis. Safety-sensitive
/// matches are surfaced as flags for the dedicated safety/crisis layer.
class UrgeClassification {
  final UrgeType type;
  final UrgeClassificationSource source;
  final double confidence;
  final String? matchedText;
  final bool safetySensitive;
  final List<String> matchedKeywords;

  const UrgeClassification({
    required this.type,
    required this.source,
    required this.confidence,
    this.matchedText,
    this.safetySensitive = false,
    this.matchedKeywords = const [],
  });

  bool get isUnknown => type == UrgeType.unknown;

  UrgeClassification copyWith({
    UrgeType? type,
    UrgeClassificationSource? source,
    double? confidence,
    String? matchedText,
    bool? safetySensitive,
    List<String>? matchedKeywords,
  }) {
    return UrgeClassification(
      type: type ?? this.type,
      source: source ?? this.source,
      confidence: confidence ?? this.confidence,
      matchedText: matchedText ?? this.matchedText,
      safetySensitive: safetySensitive ?? this.safetySensitive,
      matchedKeywords: matchedKeywords ?? this.matchedKeywords,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.key,
      'source': source.key,
      'confidence': confidence,
      'matchedText': matchedText,
      'safetySensitive': safetySensitive,
      'matchedKeywords': matchedKeywords,
    };
  }

  @override
  String toString() {
    return 'UrgeClassification(type: ${type.key}, source: ${source.key}, '
        'confidence: $confidence, safetySensitive: $safetySensitive)';
  }
}

/// Deterministic classifier used before routing a rescue session.
///
/// Priority:
/// 1. exact legacy label match
/// 2. high-signal phrase / keyword match
/// 3. conservative semantic-ish token matching
/// 4. unknown
///
/// It never automatically converts a logged urge into a relapse.
class UrgeClassifier {
  const UrgeClassifier();

  UrgeClassification classify(String? rawInput) {
    final input = normalize(rawInput);
    if (input.isEmpty) {
      return const UrgeClassification(
        type: UrgeType.unknown,
        source: UrgeClassificationSource.fallback,
        confidence: 0,
      );
    }

    final safetyMatch = _safetyKeywords.firstWhere(
      (keyword) => _containsTokenOrPhrase(input, keyword),
      orElse: () => '',
    );

    if (safetyMatch.isNotEmpty) {
      final mappedType = _safetyTypeByKeyword[safetyMatch] ?? UrgeType.unknown;
      return UrgeClassification(
        type: mappedType,
        source: UrgeClassificationSource.keyword,
        confidence: mappedType == UrgeType.unknown ? 0.96 : 0.92,
        matchedText: rawInput?.trim(),
        safetySensitive: true,
        matchedKeywords: [safetyMatch],
      );
    }

    final exact = _exactMatches[input];
    if (exact != null) {
      return UrgeClassification(
        type: exact,
        source: UrgeClassificationSource.exact,
        confidence: 1.0,
        matchedText: rawInput?.trim(),
        safetySensitive: _safetySensitive(exact),
        matchedKeywords: [input],
      );
    }

    final scored = <_Candidate>[];
    for (final entry in _keywordRules.entries) {
      final matches = <String>[];
      for (final keyword in entry.value) {
        if (_containsTokenOrPhrase(input, keyword)) {
          matches.add(keyword);
        }
      }

      if (matches.isNotEmpty) {
        final score = _keywordScore(matches);
        scored.add(
          _Candidate(
            type: entry.key,
            score: score,
            keywords: matches,
          ),
        );
      }
    }

    if (scored.isEmpty) {
      return const UrgeClassification(
        type: UrgeType.unknown,
        source: UrgeClassificationSource.fallback,
        confidence: 0.1,
      );
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    final best = scored.first;
    final second = scored.length > 1 ? scored[1] : null;

    // Do not make an aggressive guess when two unrelated urge families are
    // effectively tied. Let the UI ask the user to choose/clarify instead.
    if (second != null && (best.score - second.score) < 0.12) {
      return UrgeClassification(
        type: UrgeType.unknown,
        source: UrgeClassificationSource.semantic,
        confidence: 0.35,
        matchedText: rawInput?.trim(),
        safetySensitive:
            _safetySensitive(best.type) || _safetySensitive(second.type),
        matchedKeywords: [
          ...best.keywords,
          ...second.keywords,
        ],
      );
    }

    return UrgeClassification(
      type: best.type,
      source: UrgeClassificationSource.keyword,
      confidence: best.score.clamp(0.45, 0.92).toDouble(),
      matchedText: rawInput?.trim(),
      safetySensitive: _safetySensitive(best.type),
      matchedKeywords: best.keywords,
    );
  }

  /// Classifies a list and keeps the original order.
  List<UrgeClassification> classifyAll(Iterable<String?> inputs) {
    return inputs.map(classify).toList(growable: false);
  }

  /// Returns the typed urge when classification is sufficiently confident.
  UrgeType? classifyOrNull(String? rawInput, {double minConfidence = 0.60}) {
    final result = classify(rawInput);
    if (result.type == UrgeType.unknown ||
        result.confidence < minConfidence) {
      return null;
    }
    return result.type;
  }

  /// Normalizes legacy labels and free text into a comparison-safe form.
  static String normalize(String? value) {
    if (value == null) return '';

    return value
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9]+"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _containsTokenOrPhrase(String input, String keyword) {
    final normalizedKeyword = normalize(keyword);
    if (normalizedKeyword.isEmpty) return false;
    if (input == normalizedKeyword) return true;

    final pattern = RegExp(
      r'(^|\s)' + RegExp.escape(normalizedKeyword) + r'($|\s)',
    );
    return pattern.hasMatch(input);
  }

  static double _keywordScore(List<String> matches) {
    final uniqueMatches = matches.toSet();
    if (uniqueMatches.length >= 3) return 0.92;
    if (uniqueMatches.length == 2) return 0.78;
    return 0.60;
  }

  static bool _safetySensitive(UrgeType type) {
    return switch (type) {
      UrgeType.breakSomething => true,
      UrgeType.giveUp => true,
      UrgeType.retaliate => true,
      UrgeType.unknown => false,
      _ => false,
    };
  }

  // Explicit safety-sensitive language is surfaced to the dedicated
  // safety/crisis layer. Self-harm language intentionally remains Unknown
  // here so it cannot be routed into a normal behavioral intervention.
  static const List<String> _safetyKeywords = [
    'self harm',
    'self harm urge',
    'hurt myself',
    'harm myself',
    'kill myself',
    'suicidal',
    'suicide',
    'want to die',
    'end my life',
    'hurt someone',
    'attack someone',
  ];

  static const Map<String, UrgeType> _safetyTypeByKeyword = {
    'self harm': UrgeType.unknown,
    'self harm urge': UrgeType.unknown,
    'hurt myself': UrgeType.unknown,
    'harm myself': UrgeType.unknown,
    'kill myself': UrgeType.unknown,
    'suicidal': UrgeType.unknown,
    'suicide': UrgeType.unknown,
    'want to die': UrgeType.unknown,
    'end my life': UrgeType.unknown,
    'hurt someone': UrgeType.retaliate,
    'attack someone': UrgeType.retaliate,
  };

  static const Map<String, UrgeType> _exactMatches = {
    'check social media': UrgeType.doomscroll,
    'text ex old flame': UrgeType.seekReassurance,
    'stalk profile': UrgeType.seekReassurance,
    'check messages': UrgeType.seekReassurance,
    'browse dating apps': UrgeType.seekReassurance,
    'watch stories': UrgeType.doomscroll,
    'scroll feed': UrgeType.doomscroll,
    'send risky message': UrgeType.sendAngryMessage,
    'look up someone': UrgeType.seekReassurance,
    'overthinking': UrgeType.overthink,
    'replaying memories': UrgeType.overthink,
    'fantasy daydreaming': UrgeType.escape,
    'catastrophizing': UrgeType.overthink,
    'comparing myself': UrgeType.overthink,
    'justify old behavior': UrgeType.giveUp,
    'planning to relapse': UrgeType.relapse,
    'watch pornography': UrgeType.relapse,
    'binge watch': UrgeType.escape,
    'excessive gaming': UrgeType.escape,
    'mindless browsing': UrgeType.doomscroll,
    'sleep escape': UrgeType.escape,
    'avoid responsibility': UrgeType.escape,
    'isolation': UrgeType.isolate,
    'smoke vape': UrgeType.relapse,
    'drink alcohol': UrgeType.relapse,
    'use cannabis': UrgeType.relapse,
    'energy drink caffeine': UrgeType.escape,
    'junk food binge': UrgeType.escape,
    'sugar craving': UrgeType.escape,
    'self harm urge': UrgeType.unknown,
    'physical aggression': UrgeType.retaliate,
    'reckless behavior': UrgeType.breakSomething,
    'impulsive purchase': UrgeType.escape,
    'gambling': UrgeType.relapse,
    'risk taking': UrgeType.breakSomething,
    'seek validation': UrgeType.seekReassurance,
    'people pleasing': UrgeType.seekReassurance,
    'jealousy spiral': UrgeType.overthink,
    'pick a fight': UrgeType.confront,
    'withdraw ghost': UrgeType.shutDown,
    'codependent check in': UrgeType.seekReassurance,
  };

  static const Map<UrgeType, List<String>> _keywordRules = {
    UrgeType.sendAngryMessage: [
      'send angry message',
      'angry text',
      'rage text',
      'send a message',
      'send message',
      'text them',
      'text him',
      'text her',
      'send risky message',
    ],
    UrgeType.confront: [
      'confront',
      'pick a fight',
      'start a fight',
      'argue',
      'call them out',
    ],
    UrgeType.retaliate: [
      'retaliate',
      'revenge',
      'get back at',
      'hurt them back',
      'physical aggression',
      'hit someone',
    ],
    UrgeType.relapse: [
      'relapse',
      'use again',
      'drink again',
      'smoke again',
      'porn',
      'pornography',
      'gambling',
      'binge',
      'go back to the habit',
    ],
    UrgeType.isolate: [
      'isolate',
      'stay alone',
      'avoid everyone',
      'withdraw',
      'ghost everyone',
      'cut everyone off',
    ],
    UrgeType.doomscroll: [
      'doomscroll',
      'scroll feed',
      'scrolling',
      'social media',
      'check instagram',
      'check social media',
      'browse endlessly',
    ],
    UrgeType.overthink: [
      'overthink',
      'ruminate',
      'replay memory',
      'keep thinking',
      'spiraling thoughts',
      'catastrophize',
      'jealousy spiral',
    ],
    UrgeType.escape: [
      'escape',
      'avoid responsibility',
      'binge watch',
      'gaming',
      'mindless browsing',
      'sleep all day',
      'eat junk',
      'sugar craving',
    ],
    UrgeType.shutDown: [
      'shut down',
      'shutdown',
      'freeze',
      'go numb',
      'withdraw ghost',
      'stop talking',
    ],
    UrgeType.breakSomething: [
      'break something',
      'smash something',
      'destroy something',
      'reckless behavior',
      'risk taking',
    ],
    UrgeType.seekReassurance: [
      'seek reassurance',
      'need validation',
      'seek validation',
      'check their profile',
      'check messages',
      'dating app',
      'look them up',
      'ask them again',
      'need them to reply',
    ],
    UrgeType.giveUp: [
      'give up',
      'quit recovery',
      'why bother',
      'nothing matters',
      'justify old behavior',
    ],
  };
}

class _Candidate {
  final UrgeType type;
  final double score;
  final List<String> keywords;

  const _Candidate({
    required this.type,
    required this.score,
    required this.keywords,
  });
}
