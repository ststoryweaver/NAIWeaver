import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  final Widget child;

  const ModelGate({
    super.key,
    required this.capability,
    required this.feature,
    required this.child,
  });

  static String reason(NaiModel model, String feature) =>
      '$feature is not available on ${model.label} yet — kept, but not sent. '
      'Switch to V4.5 to use it.';

  @override
  Widget build(BuildContext context) {
    final model = context.select<GenerationNotifier?, NaiModel?>(
      (n) => n?.state.model,
    );
    if (model == null || capability(model.caps)) return child;
    return Tooltip(
      message: reason(model, feature),
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

  const ModelGateBanner({
    super.key,
    required this.capability,
    required this.feature,
  });

  @override
  Widget build(BuildContext context) {
    final model = context.select<GenerationNotifier?, NaiModel?>(
      (n) => n?.state.model,
    );
    if (model == null || capability(model.caps)) return const SizedBox.shrink();
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
                ModelGate.reason(model, feature),
                style: TextStyle(fontSize: 11, color: color, letterSpacing: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
