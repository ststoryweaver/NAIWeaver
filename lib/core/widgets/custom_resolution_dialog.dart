import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n_extensions.dart';
import '../services/preferences_service.dart';
import '../theme/theme_extensions.dart';
import '../../features/generation/widgets/settings_panel.dart';

/// Snaps [value] to the nearest multiple of 64, clamped to 64–2048.
int _snapTo64(int value) => ((value / 64).round() * 64).clamp(64, 2048);

/// Shows a dialog for entering a custom resolution.
/// Returns a [ResolutionOption] if the user confirms, or null if cancelled.
Future<ResolutionOption?> showCustomResolutionDialog(BuildContext context) {
  final t = context.tRead;
  final l = context.l;

  final widthController = TextEditingController();
  final heightController = TextEditingController();
  final nameController = TextEditingController();
  String? widthError;
  String? heightError;
  String? widthWarning;
  String? heightWarning;

  /// Returns an error string if completely invalid, null otherwise.
  /// Sets the warning string on the caller side when snapping occurs.
  String? validateDimension(String value) {
    final n = int.tryParse(value);
    if (n == null || n < 1) return l.resCustomOutOfRange;
    return null;
  }

  return showDialog<ResolutionOption>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          void submit({required bool save}) {
            final wErr = validateDimension(widthController.text);
            final hErr = validateDimension(heightController.text);

            if (wErr != null || hErr != null) {
              setDialogState(() {
                widthError = wErr;
                heightError = hErr;
                widthWarning = null;
                heightWarning = null;
              });
              return;
            }

            var w = int.parse(widthController.text);
            var h = int.parse(heightController.text);

            // Snap to nearest 64 and warn if needed
            final snappedW = _snapTo64(w);
            final snappedH = _snapTo64(h);
            final wSnapped = snappedW != w;
            final hSnapped = snappedH != h;

            if (wSnapped || hSnapped) {
              // Show warning and update the text fields, but don't block
              setDialogState(() {
                widthError = null;
                heightError = null;
                if (wSnapped) {
                  widthWarning = '${l.resCustomMustBeMultiple} → $snappedW';
                  widthController.text = snappedW.toString();
                } else {
                  widthWarning = null;
                }
                if (hSnapped) {
                  heightWarning = '${l.resCustomMustBeMultiple} → $snappedH';
                  heightController.text = snappedH.toString();
                } else {
                  heightWarning = null;
                }
              });
              // Don't submit yet — let user see the snapped values and confirm
              return;
            }

            // Range check after snap
            if (w < 64 || w > 2048) {
              setDialogState(() { widthError = l.resCustomOutOfRange; widthWarning = null; });
              return;
            }
            if (h < 64 || h > 2048) {
              setDialogState(() { heightError = l.resCustomOutOfRange; heightWarning = null; });
              return;
            }

            final name = nameController.text.trim().isEmpty
                ? 'CUSTOM'
                : nameController.text.trim().toUpperCase();
            final option = ResolutionOption(name, w, h, isCustom: true);

            if (save) {
              final prefs = Provider.of<PreferencesService>(ctx, listen: false);
              AdvancedSettingsPanel.saveCustomResolution(prefs, option);
            }

            Navigator.pop(ctx, option);
          }

          Widget buildDimensionField({
            required TextEditingController controller,
            required String label,
            String? error,
            String? warning,
            bool autofocus = false,
          }) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: autofocus,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(13)),
                  onChanged: (_) {
                    // Clear warnings on edit
                    if (widthWarning != null || heightWarning != null) {
                      setDialogState(() { widthWarning = null; heightWarning = null; });
                    }
                  },
                  decoration: InputDecoration(
                    labelText: label,
                    labelStyle: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9), letterSpacing: 1),
                    errorText: error,
                    errorStyle: TextStyle(fontSize: t.fontSize(8)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.borderMedium)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.accent)),
                  ),
                ),
                if (warning != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      warning,
                      style: TextStyle(color: Colors.orange, fontSize: t.fontSize(8)),
                    ),
                  ),
              ],
            );
          }

          return AlertDialog(
            backgroundColor: t.surfaceHigh,
            title: Text(
              l.resCustomDialogTitle.toUpperCase(),
              style: TextStyle(
                color: t.textPrimary,
                fontSize: t.fontSize(11),
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: buildDimensionField(
                          controller: widthController,
                          label: l.resCustomWidth.toUpperCase(),
                          error: widthError,
                          warning: widthWarning,
                          autofocus: true,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Text('x', style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(14))),
                      ),
                      Expanded(
                        child: buildDimensionField(
                          controller: heightController,
                          label: l.resCustomHeight.toUpperCase(),
                          error: heightError,
                          warning: heightWarning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(13)),
                    decoration: InputDecoration(
                      labelText: l.resCustomName.toUpperCase(),
                      labelStyle: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9), letterSpacing: 1),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.borderMedium)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.accent)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  l.commonCancel.toUpperCase(),
                  style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9)),
                ),
              ),
              TextButton(
                onPressed: () => submit(save: false),
                child: Text(
                  l.resCustomUseOnce.toUpperCase(),
                  style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(9)),
                ),
              ),
              TextButton(
                onPressed: () => submit(save: true),
                child: Text(
                  l.resCustomSaveAndUse.toUpperCase(),
                  style: TextStyle(color: t.accent, fontSize: t.fontSize(9)),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
