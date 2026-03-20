// lib/features/intervention/data/intervention_techniques.dart

import '../models/intervention_model.dart';

/// 📚 Complete library of all intervention techniques.
/// Each technique has fully guided steps with timers where appropriate.
class InterventionTechniques {
  // ─────────────────────────────────────────────────────────────
  //  EMERGENCY
  // ─────────────────────────────────────────────────────────────

  static const InterventionModel emergencyReset = InterventionModel(
    id: 'emergency_reset',
    title: '🚨 Emergency Reset',
    subtitle: 'Immediate crisis intervention',
    message:
        'You are in a high-intensity surge. This 60-second protocol will activate your parasympathetic nervous system and break the urge cycle.',
    actionText: 'Begin Emergency Reset',
    technique: 'Emergency Breathing',
    category: InterventionCategory.emergency,
    isEmergency: true,
    estimatedMinutes: 2,
    emoji: '🚨',
    minIntensity: 8,
    maxIntensity: 10,
    steps: [
      InterventionStep(
        instruction: 'STOP everything right now.',
        subtext: 'Put down your phone face-down. Stand up if you can.',
        durationSeconds: 4,
      ),
      InterventionStep(
        instruction: 'Breathe IN slowly',
        subtext: 'Fill your lungs completely — 5 counts',
        durationSeconds: 5,
        isBreathIn: true,
      ),
      InterventionStep(
        instruction: 'HOLD',
        subtext: 'Hold at the top — 2 counts',
        durationSeconds: 2,
        isHold: true,
      ),
      InterventionStep(
        instruction: 'Breathe OUT slowly',
        subtext: 'Release completely — 7 counts',
        durationSeconds: 7,
        isBreathOut: true,
      ),
      InterventionStep(
        instruction: 'Breathe IN slowly',
        subtext: 'Again — 5 counts',
        durationSeconds: 5,
        isBreathIn: true,
      ),
      InterventionStep(
        instruction: 'HOLD',
        subtext: '2 counts',
        durationSeconds: 2,
        isHold: true,
      ),
      InterventionStep(
        instruction: 'Breathe OUT slowly',
        subtext: 'Release — 7 counts',
        durationSeconds: 7,
        isBreathOut: true,
      ),
      InterventionStep(
        instruction: 'Breathe IN slowly',
        subtext: 'Last cycle — 5 counts',
        durationSeconds: 5,
        isBreathIn: true,
      ),
      InterventionStep(
        instruction: 'HOLD',
        subtext: '2 counts',
        durationSeconds: 2,
        isHold: true,
      ),
      InterventionStep(
        instruction: 'Breathe OUT slowly',
        subtext: 'Complete release — 7 counts',
        durationSeconds: 7,
        isBreathOut: true,
      ),
      InterventionStep(
        instruction: 'The urge is already weakening.',
        subtext:
            'Urges peak at 3–5 minutes. You have already outlasted it.',
        durationSeconds: 5,
      ),
      InterventionStep(
        instruction: 'Now, physically change your location.',
        subtext:
            'Walk to another room, go outside, or get a cold glass of water.',
        durationSeconds: 0,
      ),
    ],
  );

  // ─────────────────────────────────────────────────────────────
  //  4-4-6 BREATHING
  // ─────────────────────────────────────────────────────────────

  static const InterventionModel breathing446 = InterventionModel(
    id: 'breathing_446',
    title: '🫁 4-4-6 Breathing',
    subtitle: 'Calm your nervous system',
    message:
        'The 4-4-6 breathing pattern activates the vagus nerve, reducing cortisol and breaking the physiological urge response within 3–4 cycles.',
    actionText: 'Start Breathing',
    technique: '4-4-6 Breathing',
    category: InterventionCategory.breathing,
    estimatedMinutes: 3,
    emoji: '🫁',
    minIntensity: 4,
    maxIntensity: 9,
    steps: [
      InterventionStep(
        instruction: 'Find a comfortable position.',
        subtext:
            'Sit or stand. Place one hand on your chest, one on your belly.',
        durationSeconds: 4,
      ),
      InterventionStep(
        instruction: 'Breathe IN through your nose',
        subtext: '4 counts — feel your belly expand',
        durationSeconds: 4,
        isBreathIn: true,
      ),
      InterventionStep(
        instruction: 'HOLD',
        subtext: '4 counts — stay relaxed',
        durationSeconds: 4,
        isHold: true,
      ),
      InterventionStep(
        instruction: 'Breathe OUT through your mouth',
        subtext: '6 counts — longer out than in',
        durationSeconds: 6,
        isBreathOut: true,
      ),
      InterventionStep(
        instruction: 'Breathe IN through your nose',
        subtext: '4 counts',
        durationSeconds: 4,
        isBreathIn: true,
      ),
      InterventionStep(
        instruction: 'HOLD',
        subtext: '4 counts',
        durationSeconds: 4,
        isHold: true,
      ),
      InterventionStep(
        instruction: 'Breathe OUT through your mouth',
        subtext: '6 counts',
        durationSeconds: 6,
        isBreathOut: true,
      ),
      InterventionStep(
        instruction: 'Breathe IN through your nose',
        subtext: '4 counts — feel the calm building',
        durationSeconds: 4,
        isBreathIn: true,
      ),
      InterventionStep(
        instruction: 'HOLD',
        subtext: '4 counts',
        durationSeconds: 4,
        isHold: true,
      ),
      InterventionStep(
        instruction: 'Breathe OUT through your mouth',
        subtext: '6 counts — release everything',
        durationSeconds: 6,
        isBreathOut: true,
      ),
      InterventionStep(
        instruction: 'Notice the shift.',
        subtext:
            'Your heart rate has slowed. The urge has less power now.',
        durationSeconds: 0,
      ),
    ],
  );

  // ─────────────────────────────────────────────────────────────
  //  5-4-3-2-1 GROUNDING
  // ─────────────────────────────────────────────────────────────

  static const InterventionModel grounding54321 = InterventionModel(
    id: 'grounding_54321',
    title: '🌿 5-4-3-2-1 Grounding',
    subtitle: 'Anchor to the present moment',
    message:
        'Anxiety and urges pull you out of the present. This sensory grounding technique interrupts the urge circuit by engaging your prefrontal cortex.',
    actionText: 'Start Grounding',
    technique: 'Grounding',
    category: InterventionCategory.grounding,
    estimatedMinutes: 4,
    emoji: '🌿',
    minIntensity: 3,
    maxIntensity: 8,
    steps: [
      InterventionStep(
        instruction: 'Take one deep breath first.',
        subtext: 'In through the nose, out through the mouth.',
        durationSeconds: 5,
      ),
      InterventionStep(
        instruction: 'Name 5 things you can SEE.',
        subtext:
            'Look around slowly. Say each one out loud or in your head.',
        durationSeconds: 0,
      ),
      InterventionStep(
        instruction: 'Name 4 things you can TOUCH.',
        subtext:
            'Feel the texture. The chair beneath you. Your clothes. The air.',
        durationSeconds: 0,
      ),
      InterventionStep(
        instruction: 'Name 3 things you can HEAR.',
        subtext:
            'Listen beyond the obvious. Background hum, distant traffic, your breath.',
        durationSeconds: 0,
      ),
      InterventionStep(
        instruction: 'Name 2 things you can SMELL.',
        subtext:
            'Even subtle scents count. The room, your clothes, outside air.',
        durationSeconds: 0,
      ),
      InterventionStep(
        instruction: 'Name 1 thing you can TASTE.',
        subtext: 'Even the current taste of your mouth counts.',
        durationSeconds: 0,
      ),
      InterventionStep(
        instruction: 'You are here. Right now.',
        subtext:
            'The urge exists in your thoughts — but you are in the present. That is real.',
        durationSeconds: 0,
      ),
    ],
  );

  // ─────────────────────────────────────────────────────────────
  //  COGNITIVE REFRAMING
  // ─────────────────────────────────────────────────────────────

  static const InterventionModel cognitiveReframing = InterventionModel(
    id: 'cognitive_reframe',
    title: '🧠 Cognitive Reframe',
    subtitle: 'Challenge the urge thought',
    message:
        'Your brain is sending a false alarm. Cognitive reframing exposes the distorted thinking behind the urge, reducing its emotional power.',
    actionText: 'Start Reframing',
    technique: 'Cognitive Reframing',
    category: InterventionCategory.cognitive,
    estimatedMinutes: 3,
    emoji: '🧠',
    minIntensity: 3,
    maxIntensity: 8,
    steps: [
      InterventionStep(
        instruction: 'Identify the urge thought.',
        subtext:
            'What is the exact thought driving the urge right now? Say it clearly in your mind.',
        durationSeconds: 0,
      ),
      InterventionStep(
        instruction: 'Ask: Is this thought 100% true?',
        subtext:
            'Most urge thoughts are exaggerations. "I need this" is almost never literally true.',
        durationSeconds: 0,
      ),
      InterventionStep(
        instruction: 'Ask: What would happen if I waited 10 minutes?',
        subtext:
            'Urges peak and fall. In 10 minutes, the intensity will be lower.',
        durationSeconds: 0,
      ),
      InterventionStep(
        instruction: 'Ask: What has this cost me in the past?',
        subtext:
            'Think of one real consequence. Hold it clearly in your mind.',
        durationSeconds: 0,
      ),
      InterventionStep(
        instruction: 'Now, build the counter-thought.',
        subtext:
            'Replace the urge thought with: "This feeling is temporary. My streak is worth more than this moment."',
        durationSeconds: 0,
      ),
      InterventionStep(
        instruction: 'Say it once more — out loud if you can.',
        subtext:
            '"This feeling is temporary. I am stronger than this moment."',
        durationSeconds: 4,
      ),
    ],
  );

  // ─────────────────────────────────────────────────────────────
  //  SOCIAL REDIRECT
  // ─────────────────────────────────────────────────────────────

  static const InterventionModel socialRedirect = InterventionModel(
    id: 'social_redirect',
    title: '🤝 Social Redirect',
    subtitle: 'Break isolation with connection',
    message:
        'Loneliness and isolation amplify urges. Human connection activates oxytocin, which directly counteracts the dopamine craving circuit.',
    actionText: 'Start Redirect',
    technique: 'Social Redirect',
    category: InterventionCategory.social,
    estimatedMinutes: 3,
    emoji: '🤝',
    minIntensity: 2,
    maxIntensity: 8,
    steps: [
      InterventionStep(
        instruction: 'Acknowledge the isolation.',
        subtext:
            'You are not broken. Loneliness is a biological signal for connection — not a character flaw.',
        durationSeconds: 0,
      ),
      InterventionStep(
        instruction: 'Think of one safe person.',
        subtext:
            'Someone who has been supportive, non-judgmental. A friend, family member, or mentor.',
        durationSeconds: 0,
      ),
      InterventionStep(
        instruction: 'Send them one message right now.',
        subtext:
            'It doesn\'t have to mention your struggle. "Hey, thinking of you" is enough.',
        durationSeconds: 0,
      ),
      InterventionStep(
        instruction: 'If no one comes to mind — go somewhere with people.',
        subtext:
            'A café, a walk outside, anywhere there is ambient human presence.',
        durationSeconds: 0,
      ),
      InterventionStep(
        instruction: 'You took the first step.',
        subtext:
            'Connection breaks the isolation loop. The urge has already weakened.',
        durationSeconds: 0,
      ),
    ],
  );

  // ─────────────────────────────────────────────────────────────
  //  PHYSICAL DISCHARGE
  // ─────────────────────────────────────────────────────────────

  static const InterventionModel physicalDischarge = InterventionModel(
    id: 'physical_discharge',
    title: '⚡ Physical Discharge',
    subtitle: 'Move the energy out of your body',
    message:
        'Urge energy is physical. Moving your body redirects dopamine into movement, burning off the physiological charge behind the urge.',
    actionText: 'Start Moving',
    technique: 'Physical Discharge',
    category: InterventionCategory.physical,
    estimatedMinutes: 3,
    emoji: '⚡',
    minIntensity: 5,
    maxIntensity: 10,
    steps: [
      InterventionStep(
        instruction: 'Stand up right now.',
        subtext: 'Do not stay in the same position. Change your body state.',
        durationSeconds: 3,
      ),
      InterventionStep(
        instruction: 'Do 10 jumping jacks.',
        subtext:
            'Count out loud. Physical exertion disrupts the urge signal.',
        durationSeconds: 0,
      ),
      InterventionStep(
        instruction: 'Now do 10 push-ups or wall push-ups.',
        subtext:
            'If you can\'t do full push-ups, wall push-ups work just as well.',
        durationSeconds: 0,
      ),
      InterventionStep(
        instruction: 'Take 5 slow deep breaths.',
        subtext: 'In through the nose, out through the mouth. Let it settle.',
        durationSeconds: 20,
        isBreathIn: true,
      ),
      InterventionStep(
        instruction: 'Walk outside for at least 2 minutes.',
        subtext:
            'Fresh air and movement are the most underrated urge tools. Go now.',
        durationSeconds: 0,
      ),
    ],
  );

  // ─────────────────────────────────────────────────────────────
  //  MICRO RESET (default low-intensity)
  // ─────────────────────────────────────────────────────────────

  static const InterventionModel microReset = InterventionModel(
    id: 'micro_reset',
    title: '🛑 Micro Reset',
    subtitle: 'Pause and recenter',
    message:
        'Even a brief intentional pause interrupts automatic urge behavior. Small resets build the neural pathway of self-interruption over time.',
    actionText: 'Begin Reset',
    technique: 'Micro Reset',
    category: InterventionCategory.breathing,
    estimatedMinutes: 2,
    emoji: '🛑',
    minIntensity: 1,
    maxIntensity: 5,
    steps: [
      InterventionStep(
        instruction: 'Pause whatever you are doing.',
        subtext: 'Put your phone down. Close your eyes for 5 seconds.',
        durationSeconds: 5,
      ),
      InterventionStep(
        instruction: 'Take 3 deliberate breaths.',
        subtext: 'Slow, full breaths. Each one longer than the last.',
        durationSeconds: 12,
        isBreathIn: true,
      ),
      InterventionStep(
        instruction: 'Ask: What do I actually need right now?',
        subtext:
            'Water? Rest? Movement? The urge is often a misdirected need.',
        durationSeconds: 0,
      ),
      InterventionStep(
        instruction: 'Give yourself what you actually need.',
        subtext: 'Address the real need. The urge often dissolves on its own.',
        durationSeconds: 0,
      ),
    ],
  );

  // ─────────────────────────────────────────────────────────────
  //  ALL TECHNIQUES MAP
  // ─────────────────────────────────────────────────────────────

  static const Map<String, InterventionModel> byTechnique = {
    'Emergency Breathing': emergencyReset,
    '4-4-6 Breathing': breathing446,
    'Grounding': grounding54321,
    'Cognitive Reframing': cognitiveReframing,
    'Social Redirect': socialRedirect,
    'Physical Discharge': physicalDischarge,
    'Micro Reset': microReset,
  };

  static const List<InterventionModel> all = [
    emergencyReset,
    breathing446,
    grounding54321,
    cognitiveReframing,
    socialRedirect,
    physicalDischarge,
    microReset,
  ];
}