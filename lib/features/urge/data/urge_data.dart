// lib/features/urge/data/urge_data.dart

/// 📚 Master data library for the urge logging system.
/// All lists are clinically informed and cover the full range of
/// addictive / compulsive behavior patterns seen internationally.
library;


// ─────────────────────────────────────────────────────────────
//  URGE TYPE
// ─────────────────────────────────────────────────────────────

class UrgeTypeCategory {
  final String name;
  final String emoji;
  final List<String> types;
  const UrgeTypeCategory(
      {required this.name, required this.emoji, required this.types});
}

const List<UrgeTypeCategory> urgeTypeCategories = [
  UrgeTypeCategory(
    name: 'Social & Digital',
    emoji: '📱',
    types: [
      'Check Social Media',
      'Text Ex / Old Flame',
      'Stalk Profile',
      'Check Messages',
      'Browse Dating Apps',
      'Watch Stories',
      'Scroll Feed',
      'Send Risky Message',
      'Look Up Someone',
    ],
  ),
  UrgeTypeCategory(
    name: 'Thoughts & Rumination',
    emoji: '🧠',
    types: [
      'Overthinking',
      'Replaying Memories',
      'Fantasy / Daydreaming',
      'Catastrophizing',
      'Comparing Myself',
      'Justify Old Behavior',
      'Planning to Relapse',
    ],
  ),
  UrgeTypeCategory(
    name: 'Avoidance & Escape',
    emoji: '🏃',
    types: [
      'Watch Pornography',
      'Binge Watch',
      'Excessive Gaming',
      'Mindless Browsing',
      'Sleep Escape',
      'Avoid Responsibility',
      'Isolation',
    ],
  ),
  UrgeTypeCategory(
    name: 'Substances',
    emoji: '⚡',
    types: [
      'Smoke / Vape',
      'Drink Alcohol',
      'Use Cannabis',
      'Energy Drink / Caffeine',
      'Junk Food Binge',
      'Sugar Craving',
    ],
  ),
  UrgeTypeCategory(
    name: 'Physical & Behavioral',
    emoji: '💥',
    types: [
      'Self-Harm Urge',
      'Physical Aggression',
      'Reckless Behavior',
      'Impulsive Purchase',
      'Gambling',
      'Risk-Taking',
    ],
  ),
  UrgeTypeCategory(
    name: 'Relationship Patterns',
    emoji: '💔',
    types: [
      'Seek Validation',
      'People Pleasing',
      'Jealousy Spiral',
      'Pick a Fight',
      'Withdraw / Ghost',
      'Codependent Check-In',
    ],
  ),
];

/// Flat list of all urge type strings (for backward compatibility)
List<String> get allUrgeTypes => urgeTypeCategories
    .expand((cat) => cat.types)
    .toList();

// ─────────────────────────────────────────────────────────────
//  EMOTIONS
// ─────────────────────────────────────────────────────────────

class EmotionData {
  final String name;
  final String emoji;
  final int colorValue; // ARGB int
  final bool isNegative;

  const EmotionData({
    required this.name,
    required this.emoji,
    required this.colorValue,
    this.isNegative = true,
  });
}

const List<EmotionData> allEmotions = [
  // ── High-activation negative ─────────────────────────────
  EmotionData(name: 'Anxious',    emoji: '😰', colorValue: 0xFFAB47BC),
  EmotionData(name: 'Angry',      emoji: '😡', colorValue: 0xFFE53935),
  EmotionData(name: 'Frustrated', emoji: '😤', colorValue: 0xFFEF6C00),
  EmotionData(name: 'Stressed',   emoji: '😫', colorValue: 0xFFE91E63),
  EmotionData(name: 'Panicked',   emoji: '😨', colorValue: 0xFFC62828),
  EmotionData(name: 'Restless',   emoji: '🫨', colorValue: 0xFF7B1FA2),
  // ── Low-activation negative ──────────────────────────────
  EmotionData(name: 'Lonely',     emoji: '🥺', colorValue: 0xFF5C6BC0),
  EmotionData(name: 'Sad',        emoji: '😢', colorValue: 0xFF1E88E5),
  EmotionData(name: 'Empty',      emoji: '😶', colorValue: 0xFF546E7A),
  EmotionData(name: 'Hopeless',   emoji: '😞', colorValue: 0xFF37474F),
  EmotionData(name: 'Depressed',  emoji: '😔', colorValue: 0xFF263238),
  EmotionData(name: 'Numb',       emoji: '😐', colorValue: 0xFF607D8B),
  EmotionData(name: 'Ashamed',    emoji: '😳', colorValue: 0xFF6D4C41),
  EmotionData(name: 'Guilty',     emoji: '😣', colorValue: 0xFF4E342E),
  // ── Cognitive ────────────────────────────────────────────
  EmotionData(name: 'Overthinking', emoji: '🌀', colorValue: 0xFF00838F),
  EmotionData(name: 'Confused',   emoji: '🤯', colorValue: 0xFF00ACC1),
  EmotionData(name: 'Insecure',   emoji: '😟', colorValue: 0xFF00897B),
  // ── Boredom / Avoidance ──────────────────────────────────
  EmotionData(name: 'Bored',      emoji: '😑', colorValue: 0xFF78909C),
  EmotionData(name: 'Apathetic',  emoji: '😒', colorValue: 0xFF90A4AE),
  EmotionData(name: 'Unfocused',  emoji: '💭', colorValue: 0xFF80CBC4),
  // ── Positive (for contrast / tracking wins) ─────────────
  EmotionData(name: 'Calm',       emoji: '😌', colorValue: 0xFF00C853, isNegative: false),
  EmotionData(name: 'Motivated',  emoji: '💪', colorValue: 0xFF00BFA5, isNegative: false),
  EmotionData(name: 'Grateful',   emoji: '🙏', colorValue: 0xFF43A047, isNegative: false),
  EmotionData(name: 'Proud',      emoji: '😊', colorValue: 0xFF7CB342, isNegative: false),
  EmotionData(name: 'Hopeful',    emoji: '✨', colorValue: 0xFFFDD835, isNegative: false),
];

EmotionData emotionByName(String name) =>
    allEmotions.firstWhere((e) => e.name == name,
        orElse: () => const EmotionData(
            name: 'Unknown', emoji: '❓', colorValue: 0xFF607D8B));

// ─────────────────────────────────────────────────────────────
//  TRIGGERS
// ─────────────────────────────────────────────────────────────

class TriggerData {
  final String name;
  final String emoji;
  const TriggerData({required this.name, required this.emoji});
}

const List<TriggerData> allTriggers = [
  TriggerData(name: 'Seeing their name',    emoji: '👁'),
  TriggerData(name: 'A song / sound',       emoji: '🎵'),
  TriggerData(name: 'Being alone at night', emoji: '🌙'),
  TriggerData(name: 'Rejection / criticism',emoji: '💬'),
  TriggerData(name: 'Boredom',              emoji: '😑'),
  TriggerData(name: 'Argument / conflict',  emoji: '⚡'),
  TriggerData(name: 'Feeling ignored',      emoji: '🔇'),
  TriggerData(name: 'Late night hours',     emoji: '🕚'),
  TriggerData(name: 'Seeing a couple',      emoji: '👫'),
  TriggerData(name: 'Social media post',    emoji: '📸'),
  TriggerData(name: 'Stress at work',       emoji: '💼'),
  TriggerData(name: 'Physical tiredness',   emoji: '😴'),
  TriggerData(name: 'Alcohol / substances', emoji: '🍺'),
  TriggerData(name: 'Old memory / photo',   emoji: '📷'),
  TriggerData(name: 'Idle / unstructured time', emoji: '⏳'),
  TriggerData(name: 'Phone in hand',        emoji: '📱'),
  TriggerData(name: 'Missing the feeling',  emoji: '💭'),
  TriggerData(name: 'Anxiety spike',        emoji: '😰'),
  TriggerData(name: 'Physical tension',     emoji: '🔥'),
  TriggerData(name: 'No specific trigger',  emoji: '🎲'),
];

// ─────────────────────────────────────────────────────────────
//  CONTEXT (Where / situation)
// ─────────────────────────────────────────────────────────────

class ContextData {
  final String name;
  final String emoji;
  const ContextData({required this.name, required this.emoji});
}

const List<ContextData> allContexts = [
  ContextData(name: 'Alone at home',     emoji: '🏠'),
  ContextData(name: 'In bed',            emoji: '🛏'),
  ContextData(name: 'At work / studying',emoji: '💼'),
  ContextData(name: 'With friends',      emoji: '👥'),
  ContextData(name: 'In public',         emoji: '🏙'),
  ContextData(name: 'Commuting',         emoji: '🚇'),
  ContextData(name: 'After a fight',     emoji: '⚡'),
  ContextData(name: 'Late at night',     emoji: '🌙'),
  ContextData(name: 'After drinking',    emoji: '🍺'),
  ContextData(name: 'On my phone',       emoji: '📱'),
  ContextData(name: 'Outside',           emoji: '🌳'),
  ContextData(name: 'Gym / exercising',  emoji: '💪'),
];

// ─────────────────────────────────────────────────────────────
//  BODY LOCATIONS
// ─────────────────────────────────────────────────────────────

const List<String> bodyLocations = [
  'Chest tightness',
  'Throat tension',
  'Stomach knot',
  'Racing heart',
  'Jaw clenching',
  'Restless hands',
  'Leg tension',
  'Head pressure',
  'Shallow breathing',
  'Full body heat',
  'Not sure',
];