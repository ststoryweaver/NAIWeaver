import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/director_ref/providers/director_ref_notifier.dart';
import '../../features/generation/providers/generation_notifier.dart';
import '../models/nai_model.dart';

/// Greys out (and blocks input to) a feature the active NovelAI model does
/// not support — e.g. Vibe Transfer / Character Reference on V5 at launch.
///
/// The control stays visible with a tooltip explaining *why*, so users learn
/// the model boundary instead of hunting for a missing button. Data behind the
/// control is kept; the request builder simply does not send it.
///
/// Works anywhere a [GenerationNotifier] is in scope; without one it renders
/// [child] untouched.
class ModelGate extends StatelessWidget {
  /// Picks the capability to test from the active model.
  final bool Function(NaiCaps caps) capability;

  /// Short feature name for the tooltip ("Vibe Transfer").
  final String feature;

  /// When true, this control is also disabled while a Character/Precise
  /// Reference is active — the two cannot be sent together (issue #24).
  final bool conflictsWithDirectorRef;

  final Widget child;

  const ModelGate({
    super.key,
    required this.capability,
    required this.feature,
    this.conflictsWithDirectorRef = false,
    required this.child,
  });

  static String reason(NaiModel model, String feature) =>
      '$feature is not available on ${model.label} yet — kept, but not sent. '
      'Switch to V4.5 to use it.';

  /// Shown when Vibe Transfer is suppressed by an active Character/Precise
  /// Reference rather than by the model (issue #24).
  static const String vibeConflictReason =
      'Vibe Transfer is disabled while a Character Reference is active — '
      'NovelAI does not accept both, and sending them together corrupts the '
      'generated image. Remove or disable the reference to use Vibe Transfer.';

  /// True when a Director reference is active, so the request builder will
  /// drop any vibes. False when no [DirectorRefNotifier] is in scope.
  static bool vibeBlockedByDirector(BuildContext context) =>
      context.select<DirectorRefNotifier?, bool>(
        (d) => d != null && d.buildPayload() != null,
      );

  @override
  Widget build(BuildContext context) {
    final model = context.select<GenerationNotifier?, NaiModel?>(
      (n) => n?.state.model,
    );
    if (model == null) return child;
    final unsupported = !capability(model.caps);
    final conflicted = !unsupported &&
        conflictsWithDirectorRef &&
        vibeBlockedByDirector(context);
    if (!unsupported && !conflicted) return child;
    return Tooltip(
      message: unsupported ? reason(model, feature) : vibeConflictReason,
      child: IgnorePointer(
        child: Opacity(opacity: 0.35, child: child),
      ),
    );
  }
}

/// Inline notice for full-page managers (Vibe Transfer / Character Reference
/// tools): explains that the active model ignores the feature, without
/// greying out the whole page.
class ModelGateBanner extends StatelessWidget {
  final bool Function(NaiCaps caps) capability;
  final String feature;

  /// See [ModelGate.conflictsWithDirectorRef].
  final bool conflictsWithDirectorRef;

  const ModelGateBanner({
    super.key,
    required this.capability,
    required this.feature,
    this.conflictsWithDirectorRef = false,
  });

  @override
  Widget build(BuildContext context) {
    final model = context.select<GenerationNotifier?, NaiModel?>(
      (n) => n?.state.model,
    );
    if (model == null) return const SizedBox.shrink();
    final unsupported = !capability(model.caps);
    final conflicted = !unsupported &&
        conflictsWithDirectorRef &&
        ModelGate.vibeBlockedByDirector(context);
    if (!unsupported && !conflicted) return const SizedBox.shrink();
    final color = Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.6)),
          color: color.withValues(alpha: 0.08),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 14, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                unsupported
                    ? ModelGate.reason(model, feature)
                    : ModelGate.vibeConflictReason,
                style: TextStyle(fontSize: 11, color: color, letterSpacing: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
