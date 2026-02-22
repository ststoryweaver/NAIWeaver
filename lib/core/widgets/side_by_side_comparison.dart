import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/theme_extensions.dart';

/// A side-by-side comparison widget showing two images fully visible.
///
/// Uses [Row] on wide/landscape screens, [Column] on narrow/portrait.
/// Each image has its own [InteractiveViewer] for independent zoom/pan.
class SideBySideComparison extends StatelessWidget {
  final Uint8List beforeBytes;
  final Uint8List afterBytes;
  final String? beforeLabel;
  final String? afterLabel;

  const SideBySideComparison({
    super.key,
    required this.beforeBytes,
    required this.afterBytes,
    this.beforeLabel,
    this.afterLabel,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > constraints.maxHeight;

        final beforePanel = _ImagePanel(
          bytes: beforeBytes,
          label: beforeLabel,
        );
        final afterPanel = _ImagePanel(
          bytes: afterBytes,
          label: afterLabel,
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: beforePanel),
              VerticalDivider(width: 2, thickness: 2, color: t.borderMedium),
              Expanded(child: afterPanel),
            ],
          );
        } else {
          return Column(
            children: [
              Expanded(child: beforePanel),
              Divider(height: 2, thickness: 2, color: t.borderMedium),
              Expanded(child: afterPanel),
            ],
          );
        }
      },
    );
  }
}

class _ImagePanel extends StatelessWidget {
  final Uint8List bytes;
  final String? label;

  const _ImagePanel({required this.bytes, this.label});

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Stack(
      fit: StackFit.expand,
      children: [
        InteractiveViewer(
          maxScale: 16.0,
          minScale: 0.1,
          child: Center(
            child: Image.memory(bytes),
          ),
        ),
        if (label != null)
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                label!,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: t.fontSize(10),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
