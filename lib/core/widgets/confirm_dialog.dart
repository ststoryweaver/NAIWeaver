import 'package:flutter/material.dart';
import '../theme/theme_extensions.dart';

/// Shows a styled confirmation dialog and returns `true` if confirmed.
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  String? cancelLabel,
  Color? confirmColor,
  double? messageFontSize,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) {
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
        content: message != null
            ? Text(
                message,
                style: TextStyle(
                  color: t.textDisabled,
                  fontSize: messageFontSize ?? t.fontSize(10),
                ),
              )
            : null,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              (cancelLabel ?? 'CANCEL').toUpperCase(),
              style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              confirmLabel.toUpperCase(),
              style: TextStyle(
                color: confirmColor ?? t.accentDanger,
                fontSize: t.fontSize(9),
              ),
            ),
          ),
        ],
      );
    },
  );
}
