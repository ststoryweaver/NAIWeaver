import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../../../../core/ml/ml_device_capabilities.dart';
import '../../../../core/ml/ml_model_entry.dart';
import '../../../../core/ml/ml_model_registry.dart';
import '../../../../core/ml/ml_notifier.dart';
import '../../../../core/services/download_manager.dart';
import '../../../../core/ml/ml_storage_service.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/vision_tokens.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../l10n/app_localizations.dart';

class MLModelsManager extends StatefulWidget {
  const MLModelsManager({super.key});

  @override
  State<MLModelsManager> createState() => _MLModelsManagerState();
}

class _MLModelsManagerState extends State<MLModelsManager> {
  MLStorageStats? _stats;
  List<_UnknownModel>? _unknownModels;

  @override
  void initState() {
    super.initState();
    _refreshStats();
    _scanUnknownModels();
  }

  Future<void> _refreshStats() async {
    final ml = context.read<MLNotifier>();
    final stats = await MLStorageService.getStats(ml.mlModelsDir);
    if (mounted) setState(() => _stats = stats);
  }

  Future<void> _scanUnknownModels() async {
    final ml = context.read<MLNotifier>();
    final dir = Directory(ml.mlModelsDir);
    if (!await dir.exists()) return;

    final knownFiles = MLModelRegistry.all.map((e) => e.filename).toSet();
    final unknown = <_UnknownModel>[];

    await for (final entity in dir.list()) {
      if (entity is File && (entity.path.endsWith('.onnx') || entity.path.endsWith('.ort'))) {
        final filename = p.basename(entity.path);
        if (!knownFiles.contains(filename)) {
          final stat = await entity.stat();
          unknown.add(_UnknownModel(
            path: entity.path,
            filename: filename,
            sizeBytes: stat.size,
          ));
        }
      }
    }

    if (mounted) setState(() => _unknownModels = unknown);
  }

  Future<void> _deleteUnknown(_UnknownModel model) async {
    try {
      await File(model.path).delete();
      _unknownModels?.remove(model);
      if (mounted) setState(() {});
      _refreshStats();
    } catch (e) {
      debugPrint('Failed to delete unknown model: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final mobile = isMobile(context);
    final ml = context.watch<MLNotifier>();
    final caps = ml.deviceCapabilities;

    return SingleChildScrollView(
      padding: EdgeInsets.all(mobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            context.l.mlModels.toUpperCase(),
            style: TextStyle(
              color: t.headerText,
              fontSize: t.fontSize(mobile ? 14 : 12),
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Download and manage on-device ML models for background removal and upscaling.',
            style: TextStyle(
              color: t.textDisabled,
              fontSize: t.fontSize(mobile ? 11 : 9),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),

          // Device info + stats row
          if (caps != null || _stats != null)
            Column(
              children: [
                if (caps != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: mobile ? 14 : 10,
                      vertical: mobile ? 10 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: t.borderSubtle,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          caps.hasGpuAcceleration
                              ? Icons.memory
                              : Icons.computer,
                          size: mobile ? 16 : 12,
                          color: caps.hasGpuAcceleration
                              ? t.accentSuccess
                              : t.accentEdit,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            caps.deviceInfoLabel,
                            style: TextStyle(
                              color: t.textSecondary,
                              fontSize: t.fontSize(mobile ? 11 : 9),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (caps != null && _stats != null)
                  const SizedBox(height: 8),
                if (_stats != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: mobile ? 14 : 10,
                      vertical: mobile ? 10 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: t.borderSubtle,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.storage, size: mobile ? 16 : 12, color: t.textDisabled),
                        const SizedBox(width: 8),
                        Text(
                          _stats!.downloadedCount == 0
                              ? 'No models downloaded'
                              : '${_stats!.downloadedCount} model${_stats!.downloadedCount == 1 ? '' : 's'} downloaded \u00b7 ${_stats!.diskUsageLabel}',
                          style: TextStyle(
                            color: t.textSecondary,
                            fontSize: t.fontSize(mobile ? 11 : 9),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 24),

          // Background Removal section
          _SectionHeader(title: 'BACKGROUND REMOVAL', icon: Icons.content_cut),
          const SizedBox(height: 8),
          ...MLModelRegistry.backgroundRemovalModels.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _MLModelCard(
              entry: entry,
              ml: ml,
              caps: caps,
              isSelected: ml.selectedBgRemovalModelId == entry.id,
              onSelect: () => ml.selectBgRemovalModel(entry.id),
              onDownload: () async {
                await ml.downloadModel(entry);
                _refreshStats();
              },
              onCancel: () => ml.cancelDownload(entry.id),
              onDelete: () => _confirmDelete(entry, ml),
            ),
          )),

          const SizedBox(height: 24),

          // Upscaling section
          _SectionHeader(title: 'UPSCALING', icon: Icons.zoom_out_map),
          const SizedBox(height: 8),
          ...MLModelRegistry.upscaleModels.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _MLModelCard(
              entry: entry,
              ml: ml,
              caps: caps,
              isSelected: ml.selectedUpscaleModelId == entry.id,
              onSelect: () => ml.selectUpscaleModel(entry.id),
              onDownload: () async {
                await ml.downloadModel(entry);
                _refreshStats();
              },
              onCancel: () => ml.cancelDownload(entry.id),
              onDelete: () => _confirmDelete(entry, ml),
            ),
          )),

          const SizedBox(height: 24),

          // Segmentation section
          _SectionHeader(title: 'SEGMENTATION', icon: Icons.auto_awesome),
          const SizedBox(height: 4),
          Text(
            'Interactive object selection using SAM. Downloads both encoder and decoder.',
            style: TextStyle(
              color: t.textMinimal,
              fontSize: t.fontSize(mobile ? 10 : 8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ...MLModelRegistry.segmentationModels.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _MLModelCard(
              entry: entry,
              ml: ml,
              caps: caps,
              isSelected: entry.id.contains('encoder')
                  ? ml.selectedSegmentationModelId == entry.id
                  : ml.selectedSegmentationModelId != null,
              onSelect: entry.id.contains('encoder')
                  ? () => ml.selectSegmentationModel(entry.id)
                  : () {},  // decoder follows encoder
              onDownload: () async {
                await ml.downloadModel(entry);
                _refreshStats();
              },
              onCancel: () => ml.cancelDownload(entry.id),
              onDelete: () => _confirmDelete(entry, ml),
            ),
          )),

          // Unknown models section
          if (_unknownModels != null && _unknownModels!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionHeader(title: 'UNKNOWN MODELS', icon: Icons.help_outline),
            const SizedBox(height: 4),
            Text(
              'Legacy or unrecognized .onnx/.ort files. Delete to free disk space.',
              style: TextStyle(
                color: t.textMinimal,
                fontSize: t.fontSize(mobile ? 10 : 8),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            ..._unknownModels!.map((model) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: EdgeInsets.all(mobile ? 14 : 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: t.borderSubtle),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            model.filename.toUpperCase(),
                            style: TextStyle(
                              color: t.textSecondary,
                              fontSize: t.fontSize(mobile ? 11 : 9),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            model.sizeLabel,
                            style: TextStyle(
                              color: t.textDisabled,
                              fontSize: t.fontSize(mobile ? 10 : 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _deleteUnknown(model),
                      child: Text(
                        'DELETE',
                        style: TextStyle(
                          color: t.accentDanger,
                          fontSize: t.fontSize(mobile ? 10 : 8),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(MLModelEntry entry, MLNotifier ml) async {
    final t = context.tRead;
    final mobile = isMobile(context);

    if (mobile) {
      showModalBottomSheet(
        context: context,
        backgroundColor: t.surfaceHigh,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.delete_outline, color: t.accentDanger),
                title: Text(
                  'DELETE ${entry.name.toUpperCase()}?',
                  style: TextStyle(color: t.accentDanger, fontSize: t.fontSize(12), letterSpacing: 1),
                ),
                subtitle: Text(
                  entry.fileSizeLabel,
                  style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(10)),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ml.deleteModel(entry);
                  _refreshStats();
                  _scanUnknownModels();
                },
              ),
              ListTile(
                leading: Icon(Icons.close, color: t.textDisabled),
                title: Text(
                  'CANCEL',
                  style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(12), letterSpacing: 1),
                ),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      );
    } else {
      final confirm = await showConfirmDialog(
        context,
        title: 'DELETE ${entry.name}?',
        message: 'This will free ${entry.fileSizeLabel} of disk space.',
        confirmLabel: 'DELETE',
        confirmColor: t.accentDanger,
      );
      if (confirm == true) {
        await ml.deleteModel(entry);
        _refreshStats();
        _scanUnknownModels();
      }
    }
  }
}

class _UnknownModel {
  final String path;
  final String filename;
  final int sizeBytes;

  _UnknownModel({required this.path, required this.filename, required this.sizeBytes});

  String get sizeLabel {
    if (sizeBytes >= 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (sizeBytes >= 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (sizeBytes >= 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$sizeBytes B';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final mobile = isMobile(context);
    return Row(
      children: [
        Icon(icon, size: mobile ? 16 : 12, color: t.accent),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: t.accent,
            fontSize: t.fontSize(mobile ? 11 : 9),
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _MLModelCard extends StatelessWidget {
  final MLModelEntry entry;
  final MLNotifier ml;
  final MLDeviceCapabilities? caps;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onDownload;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const _MLModelCard({
    required this.entry,
    required this.ml,
    required this.caps,
    required this.isSelected,
    required this.onSelect,
    required this.onDownload,
    required this.onCancel,
    required this.onDelete,
  });

  Color _recommendationColor(BuildContext context, MLRecommendationLevel level) {
    final t = context.t;
    return switch (level) {
      MLRecommendationLevel.recommended => t.accentSuccess,
      MLRecommendationLevel.slow => t.accentEdit,
      MLRecommendationLevel.notRecommended => t.accentDanger,
      MLRecommendationLevel.unavailable => t.accentDanger,
    };
  }

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

  String? _tierMatchLabel(MLDeviceCapabilities? caps) {
    if (caps == null) return null;
    final recommended = caps.recommendedTier;
    if (entry.deviceTier == MLDeviceTier.both) return null;
    if (entry.deviceTier == recommended) return 'RECOMMENDED FOR YOUR DEVICE';
    if (entry.deviceTier == MLDeviceTier.desktop && recommended == MLDeviceTier.mobile) {
      return 'MAY BE SLOW ON THIS DEVICE';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final mobile = isMobile(context);
    final state = ml.downloadState(entry.id);
    final isDownloaded = ml.isModelDownloaded(entry.id);
    final isDownloading = state.status == DownloadStatus.downloading;
    final hasError = state.status == DownloadStatus.error;

    final rec = caps?.recommendation(entry);
    final isUnavailable = rec == MLRecommendationLevel.unavailable;
    final tierMatch = _tierMatchLabel(caps);

    return Opacity(
      opacity: isUnavailable ? 0.45 : 1.0,
      child: GestureDetector(
        onTap: isUnavailable ? null : (isDownloaded ? onSelect : null),
        child: Container(
          padding: EdgeInsets.all(mobile ? 14 : 10),
          decoration: BoxDecoration(
            color: isDownloaded ? t.borderSubtle : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? t.accent : (isDownloaded ? t.borderMedium : t.borderSubtle),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Selection indicator
                  if (isDownloaded) ...[
                    Container(
                      width: mobile ? 18 : 14,
                      height: mobile ? 18 : 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? t.accent : t.borderMedium,
                          width: 2,
                        ),
                        color: isSelected ? t.accent : Colors.transparent,
                      ),
                      child: isSelected
                          ? Icon(Icons.check, size: mobile ? 10 : 8, color: t.background)
                          : null,
                    ),
                    const SizedBox(width: 10),
                  ],

                  // Model info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                entry.name.toUpperCase(),
                                style: TextStyle(
                                  color: isDownloaded ? t.textPrimary : t.textSecondary,
                                  fontSize: t.fontSize(mobile ? 12 : 10),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _TierBadge(tier: entry.tier),
                            const SizedBox(width: 4),
                            _DeviceTierBadge(deviceTier: entry.deviceTier),
                            if (rec != null) ...[
                              const SizedBox(width: 4),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: _recommendationColor(context, rec).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    _recommendationLabel(context, rec, caps!, entry),
                                    style: TextStyle(
                                      color: _recommendationColor(context, rec),
                                      fontSize: t.fontSize(6),
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${entry.description} \u00b7 ${entry.fileSizeLabel}',
                          style: TextStyle(
                            color: t.textDisabled,
                            fontSize: t.fontSize(mobile ? 10 : 8),
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (tierMatch != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            tierMatch,
                            style: TextStyle(
                              color: tierMatch.contains('SLOW') ? t.accentEdit : t.accentSuccess,
                              fontSize: t.fontSize(mobile ? 8 : 6),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Action buttons
                  if (isUnavailable)
                    if (isDownloaded)
                      InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.delete_outline, size: mobile ? 18 : 14, color: t.textDisabled),
                        ),
                      )
                    else
                      const SizedBox.shrink()
                  else if (isDownloading)
                    TextButton(
                      onPressed: onCancel,
                      child: Text(
                        'CANCEL',
                        style: TextStyle(
                          color: t.accentDanger,
                          fontSize: t.fontSize(mobile ? 10 : 8),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    )
                  else if (isDownloaded) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: mobile ? 14 : 11, color: t.accentSuccess),
                        const SizedBox(width: 4),
                        Text(
                          'DOWNLOADED',
                          style: TextStyle(
                            color: t.accentSuccess,
                            fontSize: t.fontSize(mobile ? 9 : 7),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onDelete,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.delete_outline, size: mobile ? 18 : 14, color: t.textDisabled),
                          ),
                        ),
                      ],
                    ),
                  ] else if (hasError)
                    TextButton(
                      onPressed: onDownload,
                      child: Text(
                        'RETRY',
                        style: TextStyle(
                          color: t.accent,
                          fontSize: t.fontSize(mobile ? 10 : 8),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    )
                  else
                    TextButton(
                      onPressed: onDownload,
                      child: Text(
                        'DOWNLOAD',
                        style: TextStyle(
                          color: t.accent,
                          fontSize: t.fontSize(mobile ? 10 : 8),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                ],
              ),

              // Download progress bar
              if (isDownloading) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: state.progress,
                          backgroundColor: t.borderSubtle,
                          color: t.accent,
                          minHeight: 3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(state.progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: t.textDisabled,
                        fontSize: t.fontSize(mobile ? 10 : 8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],

              // Error message
              if (hasError && state.errorMessage != null) ...[
                const SizedBox(height: 6),
                Text(
                  state.errorMessage!.toUpperCase(),
                  style: TextStyle(
                    color: t.accentDanger,
                    fontSize: t.fontSize(mobile ? 9 : 7),
                    letterSpacing: 0.5,
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

class _TierBadge extends StatelessWidget {
  final MLPerformanceTier tier;

  const _TierBadge({required this.tier});

  Color _color(VisionTokens t) => switch (tier) {
        MLPerformanceTier.fast => t.accentSuccess,
        MLPerformanceTier.balanced => t.accent,
        MLPerformanceTier.quality => t.accentEdit,
      };

  String get _label => switch (tier) {
        MLPerformanceTier.fast => 'FAST',
        MLPerformanceTier.balanced => 'BAL',
        MLPerformanceTier.quality => 'HQ',
      };

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = _color(t);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: c,
          fontSize: t.fontSize(6),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DeviceTierBadge extends StatelessWidget {
  final MLDeviceTier deviceTier;

  const _DeviceTierBadge({required this.deviceTier});

  Color _color(VisionTokens t) => switch (deviceTier) {
        MLDeviceTier.mobile => t.accentSuccess,
        MLDeviceTier.desktop => t.accentEdit,
        MLDeviceTier.both => t.accent,
      };

  String get _label => switch (deviceTier) {
        MLDeviceTier.mobile => 'MOBILE',
        MLDeviceTier.desktop => 'DESKTOP',
        MLDeviceTier.both => 'BOTH',
      };

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = _color(t);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: c,
          fontSize: t.fontSize(6),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
