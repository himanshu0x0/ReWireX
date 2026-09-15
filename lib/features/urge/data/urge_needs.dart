import 'urge_types.dart';

/// The underlying need the user may be trying to satisfy when an urge appears.
///
/// IMPORTANT:
/// - [key] is stable and can be stored in Firestore / analytics.
/// - A need is NOT a diagnosis and should not be presented as one.
/// - Multiple needs can be valid for the same urge.
/// - The UI should normally ask the user to choose what fits rather than
///   claiming that ReWireX knows exactly what they need.
enum NeedType {
  relief,
  connection,
  control,
  clarity,
  space,
  release,
  validation,
  reassurance,
  structure,
  escape,
  stimulation,
  selfCompassion,
  unknown,
}

extension NeedTypeX on NeedType {
  String get key => switch (this) {
        NeedType.relief => 'relief',
        NeedType.connection => 'connection',
        NeedType.control => 'control',
        NeedType.clarity => 'clarity',
        NeedType.space => 'space',
        NeedType.release => 'release',
        NeedType.validation => 'validation',
        NeedType.reassurance => 'reassurance',
        NeedType.structure => 'structure',
        NeedType.escape => 'escape',
        NeedType.stimulation => 'stimulation',
        NeedType.selfCompassion => 'self_compassion',
        NeedType.unknown => 'unknown',
      };

  String get title => switch (this) {
        NeedType.relief => 'I need relief',
        NeedType.connection => 'I need connection',
        NeedType.control => 'I need control',
        NeedType.clarity => 'I need clarity',
        NeedType.space => 'I need some space',
        NeedType.release => 'I need to release this feeling',
        NeedType.validation => 'I need to feel heard',
        NeedType.reassurance => 'I need reassurance',
        NeedType.structure => 'I need structure',
        NeedType.escape => 'I need a break from this',
        NeedType.stimulation => 'I need something engaging',
        NeedType.selfCompassion => 'I need to be kinder to myself',
        NeedType.unknown => 'I’m not sure what I need',
      };

  String get subtitle => switch (this) {
        NeedType.relief =>
          'The pressure needs to come down before I decide what to do.',
        NeedType.connection =>
          'I do not want to handle this completely alone.',
        NeedType.control =>
          'I want something I can control right now.',
        NeedType.clarity =>
          'I need to understand what is actually happening.',
        NeedType.space =>
          'I need distance before I respond or act.',
        NeedType.release =>
          'I need a safe way to let some of this energy out.',
        NeedType.validation =>
          'I want someone to understand what I am experiencing.',
        NeedType.reassurance =>
          'I need a sense that things can still be okay.',
        NeedType.structure =>
          'I need a simple next step instead of more decisions.',
        NeedType.escape =>
          'I need a temporary change of environment or attention.',
        NeedType.stimulation =>
          'I need something healthy to occupy my attention.',
        NeedType.selfCompassion =>
          'I am being hard on myself and need a gentler response.',
        NeedType.unknown =>
          'That is okay. We can figure it out together.',
      };

  String get emoji => switch (this) {
        NeedType.relief => '😮‍💨',
        NeedType.connection => '🫂',
        NeedType.control => '💪',
        NeedType.clarity => '🧠',
        NeedType.space => '🚪',
        NeedType.release => '⚡',
        NeedType.validation => '🗣️',
        NeedType.reassurance => '❤️',
        NeedType.structure => '🧭',
        NeedType.escape => '🌿',
        NeedType.stimulation => '⚡',
        NeedType.selfCompassion => '🤍',
        NeedType.unknown => '❓',
      };

  static NeedType fromKey(String? value) {
    final key = value?.trim().toLowerCase();

    for (final need in NeedType.values) {
      if (need.key == key) return need;
    }

    return NeedType.unknown;
  }
}

/// The needs ReWireX should consider first for a given urge.
///
/// This is a ROUTING PRIORITY, not a diagnosis.
/// The user can always choose a different need in the UI.
const Map<UrgeType, List<NeedType>> defaultNeedsByUrge = {
  UrgeType.sendAngryMessage: [
    NeedType.validation,
    NeedType.space,
    NeedType.control,
    NeedType.relief,
  ],
  UrgeType.confront: [
    NeedType.control,
    NeedType.release,
    NeedType.validation,
    NeedType.space,
  ],
  UrgeType.retaliate: [
    NeedType.control,
    NeedType.release,
    NeedType.validation,
    NeedType.space,
  ],
  UrgeType.relapse: [
    NeedType.relief,
    NeedType.escape,
    NeedType.stimulation,
    NeedType.connection,
    NeedType.structure,
  ],
  UrgeType.isolate: [
    NeedType.space,
    NeedType.relief,
    NeedType.connection,
    NeedType.selfCompassion,
  ],
  UrgeType.doomscroll: [
    NeedType.escape,
    NeedType.stimulation,
    NeedType.relief,
    NeedType.structure,
  ],
  UrgeType.overthink: [
    NeedType.clarity,
    NeedType.reassurance,
    NeedType.relief,
    NeedType.structure,
  ],
  UrgeType.escape: [
    NeedType.relief,
    NeedType.space,
    NeedType.escape,
    NeedType.connection,
  ],
  UrgeType.shutDown: [
    NeedType.relief,
    NeedType.space,
    NeedType.selfCompassion,
    NeedType.connection,
    NeedType.structure,
  ],
  UrgeType.breakSomething: [
    NeedType.release,
    NeedType.control,
    NeedType.space,
    NeedType.relief,
  ],
  UrgeType.seekReassurance: [
    NeedType.reassurance,
    NeedType.connection,
    NeedType.validation,
    NeedType.clarity,
  ],
  UrgeType.giveUp: [
    NeedType.connection,
    NeedType.selfCompassion,
    NeedType.structure,
    NeedType.reassurance,
    NeedType.relief,
  ],
  UrgeType.unknown: [
    NeedType.relief,
    NeedType.clarity,
    NeedType.connection,
  ],
};

/// Maps the existing free-text urge names from [urge_data.dart] to the
/// new stable [NeedType] routing system.
///
/// This lets the current UrgeLogScreen continue working while we gradually
/// move the app toward the new Urge Rescue architecture.
List<NeedType> needsForLegacyUrge(String urgeType) {
  final value = urgeType.trim().toLowerCase();

  switch (value) {
    // Social & Digital
    case 'check social media':
    case 'watch stories':
    case 'scroll feed':
    case 'check messages':
    case 'look up someone':
      return const [
        NeedType.escape,
        NeedType.stimulation,
        NeedType.reassurance,
      ];

    case 'text ex / old flame':
    case 'send risky message':
      return const [
        NeedType.connection,
        NeedType.reassurance,
        NeedType.validation,
      ];

    case 'stalk profile':
    case 'browse dating apps':
      return const [
        NeedType.reassurance,
        NeedType.connection,
        NeedType.stimulation,
      ];

    // Thoughts & rumination
    case 'overthinking':
    case 'replaying memories':
    case 'catastrophizing':
    case 'comparing myself':
      return const [
        NeedType.clarity,
        NeedType.reassurance,
        NeedType.relief,
      ];

    case 'fantasy / daydreaming':
      return const [
        NeedType.escape,
        NeedType.stimulation,
        NeedType.relief,
      ];

    case 'justify old behavior':
    case 'planning to relapse':
      return const [
        NeedType.relief,
        NeedType.escape,
        NeedType.reassurance,
      ];

    // Avoidance & escape
    case 'watch pornography':
    case 'binge watch':
    case 'excessive gaming':
    case 'mindless browsing':
      return const [
        NeedType.escape,
        NeedType.relief,
        NeedType.stimulation,
      ];

    case 'sleep escape':
      return const [
        NeedType.relief,
        NeedType.escape,
        NeedType.selfCompassion,
      ];

    case 'avoid responsibility':
      return const [
        NeedType.relief,
        NeedType.escape,
        NeedType.structure,
      ];

    case 'isolation':
      return const [
        NeedType.space,
        NeedType.relief,
        NeedType.connection,
      ];

    // Substances / compulsive consumption
    case 'smoke / vape':
    case 'drink alcohol':
    case 'use cannabis':
    case 'energy drink / caffeine':
    case 'junk food binge':
    case 'sugar craving':
      return const [
        NeedType.relief,
        NeedType.stimulation,
        NeedType.escape,
      ];

    // Physical / behavioural
    case 'self-harm urge':
      return const [
        NeedType.relief,
        NeedType.connection,
        NeedType.space,
      ];

    case 'physical aggression':
    case 'break something':
    case 'reckless behavior':
    case 'risk-taking':
      return const [
        NeedType.release,
        NeedType.control,
        NeedType.space,
        NeedType.relief,
      ];

    case 'impulsive purchase':
      return const [
        NeedType.stimulation,
        NeedType.escape,
        NeedType.control,
      ];

    case 'gambling':
      return const [
        NeedType.stimulation,
        NeedType.escape,
        NeedType.control,
      ];

    // Relationship patterns
    case 'seek validation':
      return const [
        NeedType.validation,
        NeedType.connection,
        NeedType.reassurance,
      ];

    case 'people pleasing':
      return const [
        NeedType.reassurance,
        NeedType.validation,
        NeedType.connection,
      ];

    case 'jealousy spiral':
      return const [
        NeedType.reassurance,
        NeedType.clarity,
        NeedType.validation,
      ];

    case 'pick a fight':
      return const [
        NeedType.release,
        NeedType.validation,
        NeedType.control,
        NeedType.space,
      ];

    case 'withdraw / ghost':
      return const [
        NeedType.space,
        NeedType.relief,
        NeedType.connection,
      ];

    case 'codependent check-in':
      return const [
        NeedType.reassurance,
        NeedType.connection,
        NeedType.validation,
      ];

    default:
      return const [
        NeedType.relief,
        NeedType.clarity,
        NeedType.connection,
      ];
  }
}

/// Convenience helper for the new typed urge flow.
List<NeedType> needsForUrge(UrgeType urge) =>
    defaultNeedsByUrge[urge] ?? const [NeedType.relief, NeedType.clarity];

/// Returns a deduplicated list while preserving priority order.
///
/// Useful when the engine combines:
/// - default needs for an urge,
/// - user history,
/// - current emotion,
/// - contextual signals.
List<NeedType> prioritizeNeeds(Iterable<NeedType> needs) {
  final result = <NeedType>[];
  final seen = <NeedType>{};

  for (final need in needs) {
    if (seen.add(need)) {
      result.add(need);
    }
  }

  if (result.isEmpty) {
    result.add(NeedType.unknown);
  }

  return result;
}
