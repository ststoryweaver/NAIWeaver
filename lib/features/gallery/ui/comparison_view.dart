import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/comparison_slider.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/gallery_notifier.dart';

class ComparisonView extends StatefulWidget {
  final GalleryItem itemA;
  final GalleryItem itemB;

  const ComparisonView({super.key, required this.itemA, required this.itemB});

  @override
  State<ComparisonView> createState() => _ComparisonViewState();
}

class _ComparisonViewState extends State<ComparisonView> {
  late GalleryItem _left;
  late GalleryItem _right;
  Map<String, dynamic>? _settingsLeft;
  Map<String, dynamic>? _settingsRight;
  Uint8List? _leftBytes;
  Uint8List? _rightBytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _left = widget.itemA;
    _right = widget.itemB;
    _loadData();
  }

  Future<void> _loadData() async {
    final gallery = Provider.of<GalleryNotifier>(context, listen: false);
    final metaA = await gallery.getMetadata(_left);
    final metaB = await gallery.getMetadata(_right);
    final bytesA = await _left.file.readAsBytes();
    final bytesB = await _right.file.readAsBytes();

    if (!mounted) return;
    setState(() {
      if (metaA != null && metaA.containsKey('Comment')) {
        _settingsLeft = parseCommentJson(metaA['Comment']!);
      }
      if (metaB != null && metaB.containsKey('Comment')) {
        _settingsRight = parseCommentJson(metaB['Comment']!);
      }
      _leftBytes = bytesA;
      _rightBytes = bytesB;
      _loading = false;
    });
  }

  void _swap() {
    setState(() {
      final tmp = _left;
      _left = _right;
      _right = tmp;
      final tmpS = _settingsLeft;
      _settingsLeft = _settingsRight;
      _settingsRight = tmpS;
      final tmpB = _leftBytes;
      _leftBytes = _rightBytes;
      _rightBytes = tmpB;
    });
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
          icon: Icon(Icons.close, size: mobile ? 22 : 16, color: t.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'COMPARE',
          style: TextStyle(
            letterSpacing: 4,
            fontSize: t.fontSize(mobile ? 14 : 10),
            fontWeight: FontWeight.w900,
            color: t.textSecondary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.swap_horiz, size: mobile ? 22 : 16, color: t.textDisabled),
            tooltip: 'Swap',
            onPressed: _swap,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: t.accent))
                : ComparisonSlider(
                    beforeBytes: _leftBytes!,
                    afterBytes: _rightBytes!,
                    beforeLabel: l.comparisonBefore.toUpperCase(),
                    afterLabel: l.comparisonAfter.toUpperCase(),
                  ),
          ),
          if (!_loading) _buildMetadataBar(mobile),
        ],
      ),
    );
  }

  Widget _buildMetadataBar(bool mobile) {
    final t = context.t;
    return Container(
      padding: EdgeInsets.all(mobile ? 12 : 8),
      decoration: BoxDecoration(
        color: t.surfaceHigh,
        border: Border(top: BorderSide(color: t.borderSubtle)),
      ),
      child: SafeArea(
        child: mobile
            ? Column(
                children: [
                  _buildMetadataRow(_settingsLeft, 'BEFORE', mobile),
                  const SizedBox(height: 8),
                  _buildMetadataRow(_settingsRight, 'AFTER', mobile),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _buildMetadataRow(_settingsLeft, 'BEFORE', mobile)),
                  SizedBox(
                    height: 30,
                    child: VerticalDivider(width: 16, color: t.borderMedium),
                  ),
                  Expanded(child: _buildMetadataRow(_settingsRight, 'AFTER', mobile)),
                ],
              ),
      ),
    );
  }

  Widget _buildMetadataRow(Map<String, dynamic>? settings, String label, bool mobile) {
    final t = context.t;
    if (settings == null) {
      return Text('$label: NO METADATA', style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(mobile ? 10 : 8), letterSpacing: 1));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _CompareChip(label: 'SEED', value: settings['seed']?.toString() ?? 'N/A'),
          _CompareChip(label: 'SCALE', value: settings['scale']?.toString() ?? 'N/A'),
          _CompareChip(label: 'STEPS', value: settings['steps']?.toString() ?? 'N/A'),
          _CompareChip(label: 'SAMPLER', value: settings['sampler']?.toString() ?? 'N/A'),
        ],
      ),
    );
  }
}

class _CompareChip extends StatelessWidget {
  final String label;
  final String value;

  const _CompareChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final mobile = isMobile(context);
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: EdgeInsets.symmetric(horizontal: mobile ? 8 : 6, vertical: mobile ? 4 : 2),
      decoration: BoxDecoration(
        color: t.borderSubtle,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label ', style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(mobile ? 8 : 7), fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(mobile ? 9 : 8), fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
