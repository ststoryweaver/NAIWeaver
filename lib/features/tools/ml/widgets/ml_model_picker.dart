import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/ml/ml_device_capabilities.dart';
import '../../../../core/ml/ml_model_entry.dart';
import '../../../../core/ml/ml_model_registry.dart';
import '../../../../core/ml/ml_notifier.dart';
import '../../../../core/services/download_manager.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../l10n/app_localizations.dart';

/// Bottom sheet for picking an ML model of a given type.
/// Shows download status, tier badges, and device recommendations.
class MLModelPicker extends StatelessWidget {
  final MLModelType modelType;
  final String? selectedModelId;
  final ValueChanged<String?> onSelected;

  const MLModelPicker({
    super.key,
    required this.modelType,
    required this.selectedModelId,
    required this.onSelected,
  });

  /// Show the model picker as a bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required MLModelType modelType,
    required String? selectedModelId,
    required ValueChanged<String?> onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: context.tRead.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<MLNotifier>(),
        child: MLModelPicker(
          modelType: modelType,
          selectedModelId: selectedModelId,
          onSelected: onSelected,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ml = context.watch<MLNotifier>();
    final t = context.t;
    final caps = ml.deviceCapabilities;

    final models = MLModelRegistry.byType(modelType);

    final title = switch (modelType) {
      MLModelType.backgroundRemoval => 'BACKGROUND REMOVAL',
      MLModelType.upscale => 'UPSCALING',
      MLModelType.segmentation => 'SEGMENTATION',
    };

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      builder: (_, controller) => Column(
        children: [
          // Handle + title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: t.textMinimal,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: t.textSecondary,
                        fontSize: t.fontSize(11),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    if (caps != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: caps.hasGpuAcceleration
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          caps.deviceInfoLabel,
                          style: TextStyle(
                            color: caps.hasGpuAcceleration
                                ? Colors.green
                                : Colors.orange,
                            fontSize: t.fontSize(7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: t.borderSubtle),
          // Model list
          Expanded(
            child: ListView.builder(
              controller: controller,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: models.length,
              itemBuilder: (_, index) {
                final entry = models[index];
                final rec = caps?.recommendation(entry);
                final isUnavailable = rec == MLRecommendationLevel.unavailable;
                return _ModelPickerCard(
                  entry: entry,
                  isSelected: entry.id == selectedModelId,
                  isDownloaded: ml.isModelDownloaded(entry.id),
                  downloadState: ml.downloadState(entry.id),
                  deviceCaps: caps,
                  recommendation: rec,
                  isUnavailable: isUnavailable,
                  onTap: isUnavailable
                      ? null
                      : () {
                          if (ml.isModelDownloaded(entry.id)) {
                            onSelected(entry.id);
                            Navigator.pop(context);
                          } else {
                            ml.downloadModel(entry);
                          }
                        },
                  onDownload: isUnavailable ? null : () => ml.downloadModel(entry),
                  onCancel: () => ml.cancelDownload(entry.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelPickerCard extends StatelessWidget {
  final MLModelEntry entry;
  final bool isSelected;
  final bool isDownloaded;
  final DownloadState downloadState;
  final MLDeviceCapabilities? deviceCaps;
  final MLRecommendationLevel? recommendation;
  final bool isUnavailable;
  final VoidCallback? onTap;
  final VoidCallback? onDownload;
  final VoidCallback onCancel;

  const _ModelPickerCard({
    required this.entry,
    required this.isSelected,
    required this.isDownloaded,
    required this.downloadState,
    required this.deviceCaps,
    required this.recommendation,
    required this.isUnavailable,
    required this.onTap,
    required this.onDownload,
    required this.onCancel,
  });

  Color _tierColor(MLPerformanceTier tier) => switch (tier) {
        MLPerformanceTier.fast => Colors.green,
        MLPerformanceTier.balanced => Colors.blue,
        MLPerformanceTier.quality => Colors.purple,
      };

  String _tierLabel(MLPerformanceTier tier) => switch (tier) {
        MLPerformanceTier.fast => 'FAST',
        MLPerformanceTier.balanced => 'BALANCED',
        MLPerformanceTier.quality => 'QUALITY',
      };

  Color _recommendationColor(MLRecommendationLevel level) => switch (level) {
        MLRecommendationLevel.recommended => Colors.green,
        MLRecommendationLevel.slow => Colors.orange,
        MLRecommendationLevel.notRecommended => Colors.red,
        MLRecommendationLevel.unavailable => Colors.red,
      };

  String _recommendationLabel(BuildContext context, MLRecommendationLevel level, MLDeviceCapabilities caps, MLModelEntry entry) {
    final l = AppLocalizations.of(context);
    if (level == MLRecommendationLevel.unavailable) {
      if (caps.isDesktopOnlyOnMobile(entry)) return 'DESKTOP ONLY \u2014 MAY CRASH';
      return l.mlNotAvailableOnPlatform;
    }
    if (level == MLRecommendationLevel.notRecommended && caps.isLowRam(entry)) return l.mlLowRamWarning;
    return switch (level) {
      MLRecommendationLevel.recommended => l.mlRecommended,
      MLRecommendationLevel.slow => l.mlMayBeSlow,
      MLRecommendationLevel.notRecommended => l.mlNotRecommended,
      MLRecommendationLevel.unavailable => l.mlNotAvailableOnPlatform,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final isDownloading =
        downloadState.status == DownloadStatus.downloading;
    final hasError = downloadState.status == DownloadStatus.error;

    return Opacity(
      opacity: isUnavailable ? 0.45 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? t.accentEdit.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? t.accentEdit : t.borderSubtle,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Selection indicator
                  if (isDownloaded)
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 16,
                      color: isSelected ? t.accentEdit : t.textMinimal,
                    )
                  else
                    const SizedBox(width: 16),
                  const SizedBox(width: 8),
                  // Model name
                  Expanded(
                    child: Text(
                      entry.name,
                      style: TextStyle(
                        color: t.textPrimary,
                        fontSize: t.fontSize(10),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Tier badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _tierColor(entry.tier).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      _tierLabel(entry.tier),
                      style: TextStyle(
                        color: _tierColor(entry.tier),
                        fontSize: t.fontSize(7),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Description + size
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.description,
                      style: TextStyle(
                        color: t.textTertiary,
                        fontSize: t.fontSize(8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          entry.fileSizeLabel,
                          style: TextStyle(
                            color: t.textMinimal,
                            fontSize: t.fontSize(7),
                          ),
                        ),
                        if (recommendation != null) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _recommendationLabel(context, recommendation!, deviceCaps!, entry),
                              style: TextStyle(
                                color: _recommendationColor(recommendation!),
                                fontSize: t.fontSize(7),
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Download progress
                    if (isDownloading) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: downloadState.progress,
                              backgroundColor: t.borderSubtle,
                              valueColor: AlwaysStoppedAnimation(t.accentEdit),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(downloadState.progress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: t.textMinimal,
                              fontSize: t.fontSize(7),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: onCancel,
                            child: Icon(Icons.close, size: 14, color: t.textMinimal),
                          ),
                        ],
                      ),
                    ],
                    // Error
                    if (hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                size: 12, color: t.accentDanger),
                            const SizedBox(width: 4),
                            Text(
                              downloadState.errorMessage ?? 'Download failed',
                              style: TextStyle(
                                color: t.accentDanger,
                                fontSize: t.fontSize(7),
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: onDownload,
                              child: Text(
                                'RETRY',
                                style: TextStyle(
                                  color: t.accentEdit,
                                  fontSize: t.fontSize(7),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Download button (if not downloaded)
                    if (!isDownloaded && !isDownloading && !hasError && !isUnavailable)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: GestureDetector(
                          onTap: onDownload,
                          child: Text(
                            'DOWNLOAD',
                            style: TextStyle(
                              color: t.accentEdit,
                              fontSize: t.fontSize(8),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
