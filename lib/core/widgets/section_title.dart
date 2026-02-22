import 'package:flutter/material.dart';
import '../theme/vision_tokens.dart';

/// A standardized section title used across tool panels.
class SectionTitle extends StatelessWidget {
  final String title;
  final VisionTokens t;

  const SectionTitle(this.title, {super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: t.textTertiary,
          fontSize: t.fontSize(8),
          letterSpacing: 2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
