// lib/features/urge/data/urge_solution_catalog.dart

import '../models/urge_intervention_model.dart';
import '../models/urge_solution_model.dart';
import 'intervention_catalog.dart';

/// User-facing solution actions.
///
/// These are deliberately simple. The solution engine may rank them, but it
/// never invents a new action at runtime.
const List<UrgeSolutionAction> urgeSolutionCatalog = [
  UrgeSolutionAction(
    id: 'chat_someone',
    type: UrgeSolutionActionType.chat,
    title: 'Chat with someone',
    subtitle: 'Reach one person instead of staying alone with the urge.',
    description:
        'Connection is a strong fit for loneliness, rejection, and reassurance-seeking moments.',
    emoji: '💬',
    estimatedMinutes: 5,
    available: false,
    priority: 100,
  ),
  UrgeSolutionAction(
    id: 'truth_dare',
    type: UrgeSolutionActionType.truthDare,
    title: 'Play Truth & Dare',
    subtitle: 'Shift attention and get some social energy moving.',
    description:
        'A short game can interrupt isolation, boredom, and repetitive thinking.',
    emoji: '🎮',
    estimatedMinutes: 5,
    priority: 90,
  ),
  UrgeSolutionAction(
    id: 'recovery_stories',
    type: UrgeSolutionActionType.recoveryStories,
    title: 'Recovery Stories',
    subtitle: 'Read a journey or write your own story.',
    description:
        'A real recovery story can add perspective, hope, or a sense that you are not facing the moment alone.',
    emoji: '📖',
    estimatedMinutes: 5,
    priority: 76,
  ),
  UrgeSolutionAction(
    id: 'music_reset',
    type: UrgeSolutionActionType.music,
    title: 'Music reset',
    subtitle: 'Put on one calming or uplifting track.',
    description:
        'Change the emotional atmosphere for a few minutes before making your next choice.',
    emoji: '🎵',
    estimatedMinutes: 3,
    priority: 80,
  ),
  UrgeSolutionAction(
    id: 'journal_dump',
    type: UrgeSolutionActionType.journal,
    title: 'Write it out',
    subtitle: 'Empty the thoughts onto the page for two minutes.',
    description:
        'A short brain-dump can reduce mental pressure and make the situation clearer.',
    emoji: '📝',
    estimatedMinutes: 3,
    priority: 80,
  ),
  UrgeSolutionAction(
    id: 'mini_meditation',
    type: UrgeSolutionActionType.meditation,
    title: '1-minute meditation',
    subtitle: 'Pause, breathe, and notice what is happening right now.',
    description:
        'A brief attention reset can help when stress or emotional overload is driving the urge.',
    emoji: '🧘',
    estimatedMinutes: 1,
    priority: 78,
  ),
  UrgeSolutionAction(
    id: 'grounding_54321',
    type: UrgeSolutionActionType.grounding,
    title: '5-4-3-2-1 grounding',
    subtitle: 'Bring attention back to the present moment.',
    description:
        'Use your senses to interrupt spiraling or an intense urge.',
    emoji: '🌿',
    estimatedMinutes: 4,
    interventionId: 'basic_grounding',
    priority: 70,
  ),
  UrgeSolutionAction(
    id: 'guided_grounding',
    type: UrgeSolutionActionType.guidedRescue,
    title: 'Guided grounding rescue',
    subtitle: 'Follow a short predefined rescue when the urge feels intense.',
    description:
        'A predefined grounding sequence gives you something concrete to do immediately.',
    emoji: '🛟',
    estimatedMinutes: 3,
    interventionId: 'basic_grounding',
    priority: 70,
  ),
  UrgeSolutionAction(
    id: 'environment_reset',
    type: UrgeSolutionActionType.environmentReset,
    title: 'Change your environment',
    subtitle: 'Stand up and move away from the trigger.',
    description:
        'A small location change can break an automatic urge loop.',
    emoji: '🚶',
    estimatedMinutes: 3,
    priority: 65,
  ),
  UrgeSolutionAction(
    id: 'movement_reset',
    type: UrgeSolutionActionType.movement,
    title: 'Move for 2 minutes',
    subtitle: 'Stand up, walk, stretch, or do light movement.',
    description:
        'Use movement when your body feels charged, restless, or frustrated.',
    emoji: '⚡',
    estimatedMinutes: 2,
    priority: 60,
  ),
];

UrgeSolutionAction? solutionActionById(String id) {
  for (final action in urgeSolutionCatalog) {
    if (action.id == id) return action;
  }
  return null;
}

UrgeInterventionModel? interventionForSolution(UrgeSolutionAction action) {
  final id = action.interventionId;
  if (id == null) return null;
  return interventionById(id);
}
