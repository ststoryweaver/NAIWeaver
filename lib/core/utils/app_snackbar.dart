import 'package:flutter/material.dart';
import '../theme/theme_extensions.dart';

void showAppSnackBar(BuildContext context, String message, {Color? color}) {
  final t = context.tRead;
  final c = color ?? t.accentSuccess;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message, style: TextStyle(color: c, fontSize: t.fontSize(11))),
    backgroundColor: const Color(0xFF0A1A0A),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
      side: BorderSide(color: c.withValues(alpha: 0.3)),
    ),
  ));
}

void showErrorSnackBar(BuildContext context, String message) {
  final t = context.tRead;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message, style: TextStyle(color: t.accentDanger, fontSize: t.fontSize(11))),
    backgroundColor: const Color(0xFF1A0A0A),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
      side: BorderSide(color: t.accentDanger.withValues(alpha: 0.3)),
    ),
  ));
}
