import 'package:flutter/material.dart';
import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/vision_tokens.dart';
import '../../../core/utils/responsive.dart';
import '../../generation/services/metadata_import_service.dart';

/// Shows a dialog letting the user pick which metadata categories to import.
/// Returns the selected categories, or null if cancelled.
Future<Set<ImportCategory>?> showImportMetadataDialog(
  BuildContext context, {
  required MetadataImportResult result,
}) {
  return showDialog<Set<ImportCategory>>(
    context: context,
    builder: (ctx) => _ImportMetadataDialog(result: result),
  );
}

class _ImportMetadataDialog extends StatefulWidget {
  final MetadataImportResult result;

  const _ImportMetadataDialog({required this.result});

  @override
  State<_ImportMetadataDialog> createState() => _ImportMetadataDialogState();
}

class _ImportMetadataDialogState extends State<_ImportMetadataDialog> {
  late final Set<ImportCategory> _available;
  late final Set<ImportCategory> _selected;

  @override
  void initState() {
    super.initState();
    _available = widget.result.availableCategories;
    _selected = Set.from(_available);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final l = context.l;
    final mobile = isMobile(context);

    return AlertDialog(
      backgroundColor: t.surfaceHigh,
      title: Text(
        l.importDialogTitle,
        style: TextStyle(
          fontSize: t.fontSize(mobile ? 14 : 10),
          letterSpacing: 2,
          color: t.textSecondary,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: SizedBox(
        width: mobile ? double.maxFinite : 400,
        child: _available.isEmpty
            ? Text(
                l.importNothingAvailable,
                style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(10)),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final cat in ImportCategory.values)
                    _checkTile(
                      _categoryLabel(cat, l),
                      _selected.contains(cat),
                      _available.contains(cat),
                      (v) {
                        setState(() {
                          if (v!) {
                            _selected.add(cat);
                          } else {
                            _selected.remove(cat);
                          }
                        });
                      },
                      t,
                      mobile,
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            l.commonCancel,
            style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9)),
          ),
        ),
        TextButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.pop(context, Set<ImportCategory>.from(_selected)),
          child: Text(
            l.importActionImport,
            style: TextStyle(
              color: _selected.isEmpty ? t.textDisabled : t.accent,
              fontSize: t.fontSize(9),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  String _categoryLabel(ImportCategory cat, dynamic l) {
    switch (cat) {
      case ImportCategory.prompt:
        return l.importCategoryPrompt;
      case ImportCategory.negativePrompt:
        return l.importCategoryNegative;
      case ImportCategory.characters:
        return l.importCategoryCharacters;
      case ImportCategory.seed:
        return l.importCategorySeed;
      case ImportCategory.styles:
        return l.importCategoryStyles;
      case ImportCategory.settings:
        return l.importCategorySettings;
    }
  }

  Widget _checkTile(
    String name,
    bool checked,
    bool enabled,
    ValueChanged<bool?> onChanged,
    VisionTokens t,
    bool mobile,
  ) {
    return SizedBox(
      height: mobile ? 36 : 28,
      child: CheckboxListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: checked,
        onChanged: enabled ? onChanged : null,
        activeColor: t.accent,
        title: Text(
          name,
          style: TextStyle(
            color: enabled ? t.textSecondary : t.textDisabled,
            fontSize: t.fontSize(mobile ? 12 : 10),
          ),
        ),
      ),
    );
  }
}
