import 'package:flutter/material.dart';
import '../theme/theme_extensions.dart';

/// Controller for a progress dialog that can be updated and closed.
class ProgressDialogController {
  StateSetter? _setState;
  BuildContext? _dialogContext;
  int _completed = 0;
  int _total = 0;

  int get completed => _completed;
  int get total => _total;

  void update(int completed, int total) {
    _completed = completed;
    _total = total;
    _setState?.call(() {});
  }

  void close() {
    if (_dialogContext != null && Navigator.canPop(_dialogContext!)) {
      Navigator.pop(_dialogContext!);
    }
    _dialogContext = null;
    _setState = null;
  }
}

/// Shows a non-dismissible progress dialog with a linear progress indicator.
/// Returns a [ProgressDialogController] to update progress and close.
ProgressDialogController showProgressDialog(
  BuildContext context, {
  required String title,
  Color? progressColor,
}) {
  final controller = ProgressDialogController();
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        controller._setState = setState;
        controller._dialogContext = ctx;
        final t = ctx.tRead;
        return AlertDialog(
          backgroundColor: t.surfaceHigh,
          title: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: t.fontSize(10),
              letterSpacing: 2,
              color: t.textSecondary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                value: controller._total > 0
                    ? controller._completed / controller._total
                    : 0,
                backgroundColor: t.borderSubtle,
                color: progressColor ?? t.accent,
              ),
              const SizedBox(height: 12),
              Text(
                '${controller._completed}/${controller._total}',
                style: TextStyle(
                  color: t.textDisabled,
                  fontSize: t.fontSize(10),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
  return controller;
}
