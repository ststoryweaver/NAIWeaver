import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_extensions.dart';
import '../../utils/responsive.dart';
import '../ml_notifier.dart';

class MLProcessingOverlay extends StatelessWidget {
  const MLProcessingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final ml = context.watch<MLNotifier>();
    if (!ml.isProcessing) return const SizedBox.shrink();

    final t = context.t;
    final mobile = isMobile(context);

    return Positioned.fill(
      child: Container(
        color: t.background.withValues(alpha: 0.85),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: mobile ? 40 : 32,
                height: mobile ? 40 : 32,
                child: CircularProgressIndicator(
                  value: ml.processingProgress > 0 ? ml.processingProgress : null,
                  strokeWidth: 2.5,
                  color: t.accent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                ml.processingStage.toUpperCase(),
                style: TextStyle(
                  color: t.textSecondary,
                  fontSize: t.fontSize(mobile ? 11 : 9),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              if (ml.processingProgress > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '${(ml.processingProgress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: t.textDisabled,
                    fontSize: t.fontSize(mobile ? 10 : 8),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
