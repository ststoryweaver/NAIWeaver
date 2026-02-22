import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../theme/theme_extensions.dart';
import '../../utils/app_snackbar.dart';
import '../../utils/responsive.dart';
import '../../widgets/comparison_slider.dart';
import '../../../l10n/app_localizations.dart';

class UpscaleComparisonView extends StatefulWidget {
  final Uint8List originalBytes;
  final Uint8List upscaledBytes;
  final String outputName;
  final VoidCallback onSave;
  final bool autoSave;

  const UpscaleComparisonView({
    super.key,
    required this.originalBytes,
    required this.upscaledBytes,
    required this.outputName,
    required this.onSave,
    this.autoSave = false,
  });

  @override
  State<UpscaleComparisonView> createState() => _UpscaleComparisonViewState();
}

class _UpscaleComparisonViewState extends State<UpscaleComparisonView> {
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoSave) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _handleSave();
      });
    }
  }

  void _handleSave() {
    if (_saved) return;
    widget.onSave();
    setState(() => _saved = true);
    showAppSnackBar(context, 'SAVED: ${widget.outputName}');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final l = AppLocalizations.of(context);
    final mobile = isMobile(context);

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        toolbarHeight: mobile ? 48 : 32,
        leading: IconButton(
          icon: Icon(Icons.close,
              size: mobile ? 22 : 16, color: t.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'UPSCALE COMPARE',
          style: TextStyle(
            letterSpacing: 4,
            fontSize: t.fontSize(mobile ? 14 : 10),
            fontWeight: FontWeight.w900,
            color: t.textSecondary,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!widget.autoSave)
            TextButton(
              onPressed: _saved ? null : _handleSave,
              child: Text(
                _saved ? 'SAVED' : 'SAVE',
                style: TextStyle(
                  color: _saved ? t.textDisabled : t.accentSuccess,
                  fontSize: t.fontSize(mobile ? 12 : 9),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: ComparisonSlider(
        beforeBytes: widget.originalBytes,
        afterBytes: widget.upscaledBytes,
        beforeLabel: l.comparisonBefore.toUpperCase(),
        afterLabel: l.comparisonAfter.toUpperCase(),
      ),
    );
  }
}
