import '../models/urge_intervention_model.dart';
import '../data/urge_needs.dart';
import '../data/urge_types.dart';

/// Built-in ReWireX rescue interventions.
///
/// The catalog is intentionally code-defined rather than user-generated.
/// AI/routing code should rank/select from these interventions instead of
/// inventing new actions at runtime.
const List<UrgeInterventionModel> urgeInterventionCatalog = [
  UrgeInterventionModel(
    id: 'message_shield',
    title: 'Message Shield',
    subtitle: 'Pause before sending anything you may regret.',
    description:
        'Create a short buffer between the urge and the message. The goal is not to suppress the feeling; it is to prevent an impulsive action while the urge settles.',
    rescuePath: UrgeRescuePath.messageShield,
    supportedUrges: [
      UrgeType.sendAngryMessage,
      UrgeType.confront,
      UrgeType.retaliate,
      UrgeType.seekReassurance,
    ],
    supportedNeeds: [
      NeedType.space,
      NeedType.control,
      NeedType.relief,
      NeedType.validation,
      NeedType.reassurance,
    ],
    steps: [
      InterventionStep(
        id: 'message_shield_pause',
        title: 'Pause sending',
        instruction: 'Do not send, post, or call for the next few minutes.',
        helperText: 'Keep the draft if needed. Just create a pause before acting.',
        estimatedSeconds: 20,
      ),
      InterventionStep(
        id: 'message_shield_draft',
        title: 'Move it out of the chat',
        instruction: 'Write what you want to say in a private note instead of the conversation.',
        helperText: 'This gives the emotion somewhere to go without escalating the situation.',
        estimatedSeconds: 90,
      ),
      InterventionStep(
        id: 'message_shield_reset',
        title: 'Create distance',
        instruction: 'Put the phone down and take a short walk or sit somewhere away from the conversation.',
        helperText: 'Come back only after the urge has had time to change.',
        estimatedSeconds: 120,
      ),
      InterventionStep(
        id: 'message_shield_recheck',
        title: 'Recheck the urge',
        instruction: 'Rate how strong the urge to send the message feels now.',
        helperText: 'A lower urge is progress even when the emotion is still present.',
        estimatedSeconds: 30,
        skippable: true,
      ),
    ],
    estimatedDurationSeconds: 260,
    safetyLevel: InterventionSafetyLevel.standard,
    isEnvironmental: false,
    requiresConnection: false,
    canAutoStart: true,
    priority: 100,
    completionMessage: 'You created space before acting. That pause matters.',
    fallbackMessage: 'Keep the message unsent and move to a calmer space before deciding what to do next.',
  ),

  UrgeInterventionModel(
    id: 'distance_and_release',
    title: 'Distance & Release',
    subtitle: 'Step away from conflict and let the intensity come down safely.',
    description:
        'Use a short separation from the trigger, safe movement, and a clear pause before making a decision or confronting someone.',
    rescuePath: UrgeRescuePath.distanceAndRelease,
    supportedUrges: [
      UrgeType.confront,
      UrgeType.retaliate,
      UrgeType.breakSomething,
    ],
    supportedNeeds: [
      NeedType.space,
      NeedType.release,
      NeedType.control,
      NeedType.relief,
      NeedType.validation,
    ],
    steps: [
      InterventionStep(
        id: 'distance_leave',
        title: 'Create distance',
        instruction: 'Move away from the person, argument, or object that is keeping the urge high.',
        helperText: 'Choose a place where you can stay without escalating the situation.',
        estimatedSeconds: 45,
      ),
      InterventionStep(
        id: 'distance_safe_movement',
        title: 'Use safe movement',
        instruction: 'Take a brisk walk or slowly move your body for a couple of minutes.',
        helperText: 'The goal is to discharge some tension without hurting yourself, another person, or property.',
        estimatedSeconds: 120,
      ),
      InterventionStep(
        id: 'distance_words',
        title: 'Name the need',
        instruction: 'Finish this sentence privately: “Right now I need ____ before I deal with this.”',
        helperText: 'Common needs include space, control, respect, clarity, or relief.',
        estimatedSeconds: 45,
      ),
      InterventionStep(
        id: 'distance_recheck',
        title: 'Recheck the urge',
        instruction: 'Rate the urge to confront, retaliate, or damage something now.',
        helperText: 'If the urge is still rising or feels difficult to control, use the safety/connection layer next.',
        estimatedSeconds: 30,
      ),
    ],
    estimatedDurationSeconds: 240,
    safetyLevel: InterventionSafetyLevel.caution,
    isEnvironmental: true,
    requiresConnection: false,
    canAutoStart: false,
    priority: 95,
    completionMessage: 'You created distance instead of feeding the conflict.',
    fallbackMessage: 'Stay away from the trigger and move to the safety/connection layer if the urge is not settling.',
  ),

  UrgeInterventionModel(
    id: 'recovery_rescue',
    title: 'Recovery Rescue',
    subtitle: 'Interrupt the relapse loop before it becomes an action.',
    description:
        'A short recovery-focused sequence for moments when an old habit or relapse behavior feels especially tempting.',
    rescuePath: UrgeRescuePath.recoveryRescue,
    supportedUrges: [
      UrgeType.relapse,
      UrgeType.escape,
      UrgeType.doomscroll,
      UrgeType.seekReassurance,
    ],
    supportedNeeds: [
      NeedType.relief,
      NeedType.escape,
      NeedType.connection,
      NeedType.structure,
      NeedType.stimulation,
    ],
    steps: [
      InterventionStep(
        id: 'recovery_name',
        title: 'Name the loop',
        instruction: 'Say what is happening: “I am having an urge. I do not have to act on it right now.”',
        helperText: 'Separate the feeling of wanting from the decision to act.',
        estimatedSeconds: 30,
      ),
      InterventionStep(
        id: 'recovery_change_context',
        title: 'Change the context',
        instruction: 'Leave the place, app, screen, or situation that makes the old behavior easier.',
        helperText: 'Small environment changes can interrupt a strong habit cue.',
        estimatedSeconds: 60,
      ),
      InterventionStep(
        id: 'recovery_next_action',
        title: 'Choose one safe next action',
        instruction: 'Pick one short activity that supports recovery: shower, walk, food, study reset, hobby, or a trusted person.',
        helperText: 'Choose something realistic for the next few minutes, not a perfect plan for the whole day.',
        estimatedSeconds: 90,
      ),
      InterventionStep(
        id: 'recovery_recheck',
        title: 'Recheck the urge',
        instruction: 'Rate the relapse urge again and compare it with your starting score.',
        helperText: 'Even a small reduction is useful information for your recovery pattern.',
        estimatedSeconds: 30,
      ),
    ],
    estimatedDurationSeconds: 210,
    safetyLevel: InterventionSafetyLevel.standard,
    isEnvironmental: true,
    requiresConnection: false,
    canAutoStart: true,
    priority: 100,
    completionMessage: 'You interrupted the old loop and gave yourself another choice.',
    fallbackMessage: 'Change your environment and use a trusted support path if the urge keeps getting stronger.',
  ),

  UrgeInterventionModel(
    id: 'connection_rescue',
    title: 'Connection Rescue',
    subtitle: 'Replace isolation with a small, safe point of connection.',
    description:
        'Use a low-pressure connection step when the urge is driven by loneliness, reassurance seeking, shutting down, or wanting to give up.',
    rescuePath: UrgeRescuePath.connectionRescue,
    supportedUrges: [
      UrgeType.isolate,
      UrgeType.seekReassurance,
      UrgeType.giveUp,
      UrgeType.shutDown,
      UrgeType.escape,
    ],
    supportedNeeds: [
      NeedType.connection,
      NeedType.reassurance,
      NeedType.validation,
      NeedType.selfCompassion,
      NeedType.relief,
    ],
    steps: [
      InterventionStep(
        id: 'connection_choose',
        title: 'Choose one safe person',
        instruction: 'Pick one trusted person you can contact without needing to explain everything.',
        helperText: 'One person is enough. You do not need a large conversation.',
        estimatedSeconds: 30,
      ),
      InterventionStep(
        id: 'connection_message',
        title: 'Send a simple check-in',
        instruction: 'Send: “I am having a difficult moment. Can you stay with me for a few minutes?”',
        helperText: 'Keep it simple. The goal is connection, not solving the whole problem.',
        estimatedSeconds: 45,
      ),
      InterventionStep(
        id: 'connection_stay',
        title: 'Stay connected',
        instruction: 'Wait with the person or remain in a shared/safe space while the urge settles.',
        helperText: 'Avoid making major decisions while the urge is still high.',
        estimatedSeconds: 120,
      ),
      InterventionStep(
        id: 'connection_recheck',
        title: 'Recheck the urge',
        instruction: 'Rate the urge again after the connection step.',
        helperText: 'Notice whether being less alone changed the intensity.',
        estimatedSeconds: 30,
      ),
    ],
    estimatedDurationSeconds: 225,
    safetyLevel: InterventionSafetyLevel.caution,
    isEnvironmental: false,
    requiresConnection: true,
    canAutoStart: false,
    priority: 92,
    completionMessage: 'You chose connection instead of facing the moment alone.',
    fallbackMessage: 'Stay near a trusted person or safe support channel if the urge remains difficult to manage.',
  ),

  UrgeInterventionModel(
    id: 'environment_reset',
    title: 'Environment Reset',
    subtitle: 'Make the trigger harder to access for a few minutes.',
    description:
        'Reduce access to the cue that is feeding the urge, then move into a different activity or place.',
    rescuePath: UrgeRescuePath.environmentReset,
    supportedUrges: [
      UrgeType.doomscroll,
      UrgeType.escape,
      UrgeType.relapse,
      UrgeType.overthink,
    ],
    supportedNeeds: [
      NeedType.escape,
      NeedType.stimulation,
      NeedType.structure,
      NeedType.relief,
      NeedType.space,
    ],
    steps: [
      InterventionStep(
        id: 'environment_remove_cue',
        title: 'Reduce the cue',
        instruction: 'Close the app, put the device away, or move away from the place connected to the urge.',
        helperText: 'Make the impulsive option slightly harder to reach.',
        estimatedSeconds: 30,
      ),
      InterventionStep(
        id: 'environment_change_place',
        title: 'Change your setting',
        instruction: 'Move to a brighter, shared, or more purposeful space.',
        helperText: 'A change of context can break an automatic sequence.',
        estimatedSeconds: 60,
      ),
      InterventionStep(
        id: 'environment_small_task',
        title: 'Start a tiny task',
        instruction: 'Do one small task for five minutes: water, tidy one area, stretch, read, or begin a study task.',
        helperText: 'Choose something concrete enough to start immediately.',
        estimatedSeconds: 150,
      ),
      InterventionStep(
        id: 'environment_recheck',
        title: 'Recheck the urge',
        instruction: 'Rate the urge again after the environment change.',
        helperText: 'Notice which context changes help you most.',
        estimatedSeconds: 30,
      ),
    ],
    estimatedDurationSeconds: 270,
    safetyLevel: InterventionSafetyLevel.standard,
    isEnvironmental: true,
    requiresConnection: false,
    canAutoStart: true,
    priority: 88,
    completionMessage: 'You changed the context instead of letting the trigger control the next step.',
    fallbackMessage: 'Keep the trigger out of reach and switch to a safer support or connection path if needed.',
  ),

  UrgeInterventionModel(
    id: 'thought_reset',
    title: 'Thought Reset',
    subtitle: 'Slow the thought loop and return to what is actionable now.',
    description:
        'Use a short structured reset when overthinking, replaying, or catastrophizing is increasing the urge.',
    rescuePath: UrgeRescuePath.thoughtReset,
    supportedUrges: [
      UrgeType.overthink,
      UrgeType.seekReassurance,
      UrgeType.giveUp,
    ],
    supportedNeeds: [
      NeedType.clarity,
      NeedType.reassurance,
      NeedType.control,
      NeedType.structure,
      NeedType.relief,
    ],
    steps: [
      InterventionStep(
        id: 'thought_label',
        title: 'Label the loop',
        instruction: 'Write one sentence describing what your mind keeps replaying or predicting.',
        helperText: 'Keep the description factual and brief.',
        estimatedSeconds: 45,
      ),
      InterventionStep(
        id: 'thought_separate',
        title: 'Separate fact from prediction',
        instruction: 'Write one thing you know now and one thing your mind is only predicting.',
        helperText: 'This is not about forcing positive thoughts. It is about clearer thinking.',
        estimatedSeconds: 75,
      ),
      InterventionStep(
        id: 'thought_next',
        title: 'Pick one next action',
        instruction: 'Choose one small action you can take in the next ten minutes.',
        helperText: 'Actionable beats perfect.',
        estimatedSeconds: 60,
      ),
      InterventionStep(
        id: 'thought_recheck',
        title: 'Recheck the urge',
        instruction: 'Rate the urge again after the thought reset.',
        helperText: 'Notice whether clarity changed the urge.',
        estimatedSeconds: 30,
      ),
    ],
    estimatedDurationSeconds: 210,
    safetyLevel: InterventionSafetyLevel.standard,
    isEnvironmental: false,
    requiresConnection: false,
    canAutoStart: true,
    priority: 90,
    completionMessage: 'You slowed the loop and focused on what is actually actionable.',
    fallbackMessage: 'Stay with one small next step and use connection support if the thoughts keep escalating.',
  ),

  UrgeInterventionModel(
    id: 'activation_rescue',
    title: 'Activation Rescue',
    subtitle: 'Make the next few minutes easier to enter when everything feels heavy.',
    description:
        'A tiny-start sequence for shutdown, low motivation, and escape urges where a large plan would feel overwhelming.',
    rescuePath: UrgeRescuePath.activationRescue,
    supportedUrges: [
      UrgeType.shutDown,
      UrgeType.giveUp,
      UrgeType.escape,
      UrgeType.isolate,
    ],
    supportedNeeds: [
      NeedType.structure,
      NeedType.selfCompassion,
      NeedType.relief,
      NeedType.connection,
      NeedType.space,
    ],
    steps: [
      InterventionStep(
        id: 'activation_sit_up',
        title: 'Change one position',
        instruction: 'Sit up, stand up, or move to a different safe place.',
        helperText: 'The first goal is movement, not productivity.',
        estimatedSeconds: 30,
      ),
      InterventionStep(
        id: 'activation_basic_need',
        title: 'Meet one basic need',
        instruction: 'Choose one: drink water, wash your face, eat something, or step outside for a moment.',
        helperText: 'Pick the easiest option available right now.',
        estimatedSeconds: 90,
      ),
      InterventionStep(
        id: 'activation_microtask',
        title: 'Start a two-minute task',
        instruction: 'Do one tiny task and stop when the timer ends unless you naturally want to continue.',
        helperText: 'Starting is the goal; finishing everything is not required.',
        estimatedSeconds: 120,
      ),
      InterventionStep(
        id: 'activation_recheck',
        title: 'Recheck the urge',
        instruction: 'Rate the urge again and note whether your energy or willingness changed.',
        helperText: 'Small changes still count.',
        estimatedSeconds: 30,
      ),
    ],
    estimatedDurationSeconds: 270,
    safetyLevel: InterventionSafetyLevel.standard,
    isEnvironmental: false,
    requiresConnection: false,
    canAutoStart: true,
    priority: 86,
    completionMessage: 'You made the next step smaller instead of demanding a full recovery at once.',
    fallbackMessage: 'Stay near supportive people and use the connection/safety layer if the heaviness becomes harder to manage.',
  ),

  UrgeInterventionModel(
    id: 'basic_grounding',
    title: 'Basic Grounding',
    subtitle: 'Slow down and orient yourself before choosing the next step.',
    description:
        'A low-risk fallback when the urge type or need is unclear. It creates a pause so the app can recheck what is happening.',
    rescuePath: UrgeRescuePath.basicGrounding,
    supportedUrges: const [UrgeType.unknown],
    supportedNeeds: [NeedType.relief, NeedType.clarity, NeedType.space],
    steps: [
      InterventionStep(
        id: 'grounding_pause',
        title: 'Pause',
        instruction: 'Stop the current action and put yourself somewhere safe and steady.',
        helperText: 'Do not make a major decision while the urge is peaking.',
        estimatedSeconds: 30,
      ),
      InterventionStep(
        id: 'grounding_orientation',
        title: 'Orient to the moment',
        instruction: 'Name where you are, what you are doing, and what you need most right now.',
        helperText: 'Keep the answer simple and concrete.',
        estimatedSeconds: 60,
      ),
      InterventionStep(
        id: 'grounding_next',
        title: 'Choose one safe next action',
        instruction: 'Pick the smallest helpful action available: move, drink water, step away, or contact support.',
        helperText: 'You only need the next safe step.',
        estimatedSeconds: 60,
      ),
      InterventionStep(
        id: 'grounding_recheck',
        title: 'Recheck the urge',
        instruction: 'Rate the urge again and continue to a more specific rescue path if needed.',
        helperText: 'A clearer score helps ReWireX choose the next intervention.',
        estimatedSeconds: 30,
      ),
    ],
    estimatedDurationSeconds: 180,
    safetyLevel: InterventionSafetyLevel.caution,
    isEnvironmental: false,
    requiresConnection: false,
    canAutoStart: true,
    priority: 10,
    completionMessage: 'You created a pause and identified the next safe step.',
    fallbackMessage: 'Use a specific rescue path or the safety/connection layer once the situation is clearer.',
  ),
];

/// Returns an intervention by its stable id.
UrgeInterventionModel? interventionById(String id) {
  for (final intervention in urgeInterventionCatalog) {
    if (intervention.id == id) return intervention;
  }
  return null;
}

/// Returns interventions for a rescue path, preserving catalog order.
List<UrgeInterventionModel> interventionsForPath(UrgeRescuePath path) {
  return urgeInterventionCatalog
      .where((intervention) => intervention.rescuePath == path)
      .toList(growable: false);
}

/// Ranks the built-in interventions for the current urge and optional need.
///
/// Safety-review interventions are kept in the result so the caller can route
/// them through the safety layer rather than accidentally hiding them.
List<UrgeInterventionModel> rankInterventions({
  required UrgeType urge,
  NeedType? need,
  bool includeSafetyReview = true,
}) {
  final ranked = urgeInterventionCatalog
      .where(
        (intervention) =>
            includeSafetyReview ||
            intervention.safetyLevel != InterventionSafetyLevel.safetyReviewRequired,
      )
      .map(
        (intervention) =>
            _ScoredIntervention(intervention, intervention.matchScore(urge: urge, need: need)),
      )
      .where((entry) => entry.score > 0)
      .toList(growable: false);

  final sorted = [...ranked]
    ..sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return b.intervention.priority.compareTo(a.intervention.priority);
    });

  return sorted
      .map((entry) => entry.intervention)
      .toList(growable: false);
}

/// Picks the best catalog intervention and falls back to Basic Grounding.
UrgeInterventionModel bestInterventionFor({
  required UrgeType urge,
  NeedType? need,
}) {
  final ranked = rankInterventions(urge: urge, need: need);
  return ranked.isNotEmpty
      ? ranked.first
      : interventionById('basic_grounding')!;
}

/// Returns the default rescue intervention for the enum's predefined path.
UrgeInterventionModel defaultInterventionForUrge(UrgeType urge) {
  final path = urge.defaultRescuePath;
  final pathInterventions = interventionsForPath(path);

  if (pathInterventions.isNotEmpty) return pathInterventions.first;
  return interventionById('basic_grounding')!;
}

class _ScoredIntervention {
  const _ScoredIntervention(this.intervention, this.score);

  final UrgeInterventionModel intervention;
  final int score;
}
