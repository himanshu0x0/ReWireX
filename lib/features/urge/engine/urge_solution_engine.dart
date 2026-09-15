// lib/features/urge/engine/urge_solution_engine.dart

import '../data/urge_needs.dart';
import '../data/urge_solution_catalog.dart' as catalog;
import '../data/urge_types.dart';
import '../models/urge_session_model.dart';
import '../models/urge_solution_model.dart';
import 'need_engine.dart';

/// Simple backend-ready decision layer for Urge Rescue.
///
/// It silently analyzes the information already collected by the urge flow and
/// returns one primary action plus up to two alternatives. User-facing screens
/// never need to expose the need/rescue decision tree.
///
/// The current implementation is deterministic. A future LLM/AI service can
/// provide additional signals, but it must still select from the predefined
/// solution catalog.
class UrgeSolutionEngine {
  const UrgeSolutionEngine({this.needEngine = const NeedEngine()});

  final NeedEngine needEngine;

  UrgeSolutionPlan resolve(UrgeSessionModel session) {
    final inference = needEngine.inferFromSession(session);
    final need = inference.selectedNeed == NeedType.unknown
        ? NeedType.relief
        : inference.selectedNeed;

    final ranked = _scoreActions(session, need);
    final available = ranked.where((action) => action.available).toList();

    final primary = available.isNotEmpty ? available.first : ranked.first;

    final alternatives = available
        .where((action) => action.id != primary.id)
        .take(2)
        .toList(growable: false);

    return UrgeSolutionPlan(
      need: need,
      primary: primary,
      alternatives: alternatives,
      reason: _reason(session, need, primary),
      intervention: catalog.interventionForSolution(primary),
    );
  }

  List<UrgeSolutionAction> _scoreActions(
    UrgeSessionModel session,
    NeedType need,
  ) {
    final text = '${session.emotion} ${session.trigger} ${session.context} ${session.notes}'
        .toLowerCase();
    final intensity = (session.urgeBefore ?? 5).clamp(1, 10).toInt();

    final scored = <_ScoredAction>[];

    for (final action in catalog.urgeSolutionCatalog) {
      var score = action.priority.toDouble();

      // The unavailable chat option remains part of the intelligence model so
      // that the future Connect phase can immediately activate it.
      if (!action.available) score -= 150;

      // Need-level signals.
      switch (need) {
        case NeedType.connection:
        case NeedType.validation:
        case NeedType.reassurance:
          score += _bonus(action, const {
            UrgeSolutionActionType.chat: 95,
            UrgeSolutionActionType.truthDare: 72,
            UrgeSolutionActionType.recoveryStories: 68,
            UrgeSolutionActionType.journal: 25,
          });
          break;
        case NeedType.relief:
        case NeedType.selfCompassion:
          score += _bonus(action, const {
            UrgeSolutionActionType.music: 70,
            UrgeSolutionActionType.meditation: 62,
            UrgeSolutionActionType.grounding: 55,
            UrgeSolutionActionType.guidedRescue: 55,
          });
          break;
        case NeedType.clarity:
          score += _bonus(action, const {
            UrgeSolutionActionType.journal: 85,
            UrgeSolutionActionType.meditation: 35,
            UrgeSolutionActionType.grounding: 30,
          });
          break;
        case NeedType.stimulation:
        case NeedType.escape:
          score += _bonus(action, const {
            UrgeSolutionActionType.truthDare: 78,
            UrgeSolutionActionType.recoveryStories: 70,
            UrgeSolutionActionType.music: 60,
            UrgeSolutionActionType.environmentReset: 45,
          });
          break;
        case NeedType.space:
        case NeedType.control:
        case NeedType.release:
          score += _bonus(action, const {
            UrgeSolutionActionType.environmentReset: 78,
            UrgeSolutionActionType.movement: 70,
            UrgeSolutionActionType.grounding: 45,
          });
          break;
        case NeedType.structure:
          score += _bonus(action, const {
            UrgeSolutionActionType.journal: 55,
            UrgeSolutionActionType.environmentReset: 45,
            UrgeSolutionActionType.meditation: 30,
          });
          break;
        case NeedType.unknown:
          break;
      }

      // Emotion/context signals.
      if (_hasAny(text, const [
        'lonely',
        'alone',
        'ignored',
        'rejected',
        'left out',
        'missing someone',
      ])) {
        score += _bonus(action, const {
          UrgeSolutionActionType.chat: 130,
          UrgeSolutionActionType.truthDare: 105,
          UrgeSolutionActionType.recoveryStories: 82,
          UrgeSolutionActionType.journal: 30,
        });
      }

      if (_hasAny(text, const [
        'depressed',
        'sad',
        'empty',
        'low',
        'hopeless',
        'down',
      ])) {
        score += _bonus(action, const {
          UrgeSolutionActionType.music: 95,
          UrgeSolutionActionType.journal: 78,
          UrgeSolutionActionType.recoveryStories: 72,
          UrgeSolutionActionType.meditation: 65,
        });
      }

      if (_hasAny(text, const [
        'stress',
        'stressed',
        'anxious',
        'anxiety',
        'overwhelmed',
        'panic',
      ])) {
        score += _bonus(action, const {
          UrgeSolutionActionType.meditation: 100,
          UrgeSolutionActionType.grounding: 88,
          UrgeSolutionActionType.music: 50,
        });
      }

      if (_hasAny(text, const ['bored', 'scroll', 'phone', 'idle', 'nothing to do'])) {
        score += _bonus(action, const {
          UrgeSolutionActionType.truthDare: 100,
          UrgeSolutionActionType.recoveryStories: 88,
          UrgeSolutionActionType.music: 65,
          UrgeSolutionActionType.environmentReset: 50,
        });
      }

      if (_hasAny(text, const [
        'angry',
        'frustrated',
        'fight',
        'argument',
        'conflict',
        'ignored me',
      ])) {
        score += _bonus(action, const {
          UrgeSolutionActionType.environmentReset: 105,
          UrgeSolutionActionType.movement: 90,
          UrgeSolutionActionType.grounding: 75,
        });
      }

      // Intensity should influence the choice, but it should not overwhelm the
      // meaning of the user's emotion/trigger.
      if (intensity >= 8) {
        score += _bonus(action, const {
          UrgeSolutionActionType.guidedRescue: 120,
          UrgeSolutionActionType.grounding: 90,
          UrgeSolutionActionType.meditation: 45,
        });
      } else if (intensity <= 3) {
        score += _bonus(action, const {
          UrgeSolutionActionType.music: 25,
          UrgeSolutionActionType.journal: 25,
          UrgeSolutionActionType.truthDare: 25,
        });
      }

      // Typed urge signals.
      switch (session.urgeType) {
        case UrgeType.isolate:
          score += _bonus(action, const {
            UrgeSolutionActionType.chat: 120,
            UrgeSolutionActionType.truthDare: 95,
            UrgeSolutionActionType.recoveryStories: 85,
            UrgeSolutionActionType.journal: 35,
          });
          break;
        case UrgeType.doomscroll:
          score += _bonus(action, const {
            UrgeSolutionActionType.environmentReset: 110,
            UrgeSolutionActionType.truthDare: 75,
            UrgeSolutionActionType.music: 55,
          });
          break;
        case UrgeType.overthink:
          score += _bonus(action, const {
            UrgeSolutionActionType.journal: 110,
            UrgeSolutionActionType.grounding: 70,
            UrgeSolutionActionType.meditation: 65,
          });
          break;
        case UrgeType.relapse:
        case UrgeType.giveUp:
          score += _bonus(action, const {
            UrgeSolutionActionType.guidedRescue: 125,
            UrgeSolutionActionType.grounding: 90,
            UrgeSolutionActionType.journal: 50,
          });
          break;
        case UrgeType.sendAngryMessage:
        case UrgeType.confront:
        case UrgeType.retaliate:
        case UrgeType.breakSomething:
          score += _bonus(action, const {
            UrgeSolutionActionType.environmentReset: 110,
            UrgeSolutionActionType.movement: 95,
            UrgeSolutionActionType.grounding: 70,
          });
          break;
        case UrgeType.shutDown:
          score += _bonus(action, const {
            UrgeSolutionActionType.music: 65,
            UrgeSolutionActionType.meditation: 60,
            UrgeSolutionActionType.journal: 55,
            UrgeSolutionActionType.movement: 45,
          });
          break;
        case UrgeType.seekReassurance:
          score += _bonus(action, const {
            UrgeSolutionActionType.chat: 100,
            UrgeSolutionActionType.truthDare: 70,
            UrgeSolutionActionType.recoveryStories: 65,
            UrgeSolutionActionType.journal: 50,
          });
          break;
        case UrgeType.escape:
          score += _bonus(action, const {
            UrgeSolutionActionType.music: 55,
            UrgeSolutionActionType.truthDare: 65,
            UrgeSolutionActionType.environmentReset: 70,
          });
          break;
        case UrgeType.unknown:
          break;
      }

      scored.add(_ScoredAction(action, score));
    }

    scored.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return b.action.priority.compareTo(a.action.priority);
    });

    return scored.map((entry) => entry.action).toList(growable: false);
  }

  double _bonus(
    UrgeSolutionAction action,
    Map<UrgeSolutionActionType, double> bonuses,
  ) {
    return bonuses[action.type] ?? 0;
  }

  bool _hasAny(String text, List<String> terms) => terms.any(text.contains);

  String _reason(
    UrgeSessionModel session,
    NeedType need,
    UrgeSolutionAction primary,
  ) {
    switch (primary.type) {
      case UrgeSolutionActionType.chat:
        return 'Your pattern suggests connection may help most right now.';
      case UrgeSolutionActionType.truthDare:
        return 'A social, playful reset can interrupt the loop without asking you to solve everything right now.';
      case UrgeSolutionActionType.recoveryStories:
        return 'A recovery story can add perspective and remind you that difficult moments can change.';
      case UrgeSolutionActionType.music:
        return 'A change in emotional atmosphere may help before you decide what to do next.';
      case UrgeSolutionActionType.journal:
        return 'Getting the thoughts out may lower pressure and make the situation clearer.';
      case UrgeSolutionActionType.meditation:
        return 'Your current state looks overloaded, so the first goal is to slow the loop down.';
      case UrgeSolutionActionType.grounding:
        return 'The urge is pulling attention away from the present, so grounding is a strong first step.';
      case UrgeSolutionActionType.guidedRescue:
        if ((session.urgeBefore ?? 5) >= 8) {
          return 'The urge is intense, so ReWireX selected a short guided rescue that can start immediately.';
        }
        return 'This predefined rescue matches the urge and the need ReWireX inferred.';
      case UrgeSolutionActionType.environmentReset:
        return 'Your trigger and context suggest that changing the environment can break the automatic loop.';
      case UrgeSolutionActionType.movement:
        return 'Your body may be carrying part of the urge, so a brief movement reset is a useful next step.';
    }
  }
}

class _ScoredAction {
  const _ScoredAction(this.action, this.score);

  final UrgeSolutionAction action;
  final double score;
}
