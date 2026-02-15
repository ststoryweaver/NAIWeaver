import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/vision_tokens.dart';
import '../../../gallery/providers/gallery_notifier.dart';
import '../models/slideshow_config.dart';

class ImageSourceSelector extends StatelessWidget {
  final SlideshowConfig config;
  final ValueChanged<SlideshowConfig> onChanged;

  const ImageSourceSelector({
    super.key,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final l = context.l;
    final gallery = context.watch<GalleryNotifier>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.slideshowImageSource,
            style: TextStyle(
                color: t.textMinimal,
                fontSize: t.fontSize(8),
                letterSpacing: 1)),
        const SizedBox(height: 8),
        _buildRadio(t, ImageSourceType.allImages, l.slideshowAllImages,
            l.slideshowImageCount(gallery.activeItems.length)),
        _buildRadio(t, ImageSourceType.favorites, l.slideshowFavoritesLabel,
            l.slideshowImageCount(gallery.items.where((i) => i.isFavorite).length)),
        _buildRadio(t, ImageSourceType.album, l.slideshowAlbumLabel, null),
        if (config.sourceType == ImageSourceType.album) ...[
          const SizedBox(height: 4),
          _buildAlbumDropdown(context, t, gallery),
        ],
        _buildRadio(t, ImageSourceType.custom, l.slideshowCustomSelection,
            l.slideshowSelectedCount(config.customImageBasenames.length)),
        if (config.sourceType == ImageSourceType.custom) ...[
          const SizedBox(height: 4),
          _buildCustomPicker(context, t, gallery),
        ],
      ],
    );
  }

  Widget _buildRadio(
      VisionTokens t, ImageSourceType type, String label, String? subtitle) {
    final selected = config.sourceType == type;
    return InkWell(
      onTap: () => onChanged(config.copyWith(sourceType: type)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 16,
              color: selected ? t.accent : t.textDisabled,
            ),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: selected ? t.textPrimary : t.textSecondary,
                    fontSize: t.fontSize(10),
                    letterSpacing: 1)),
            if (subtitle != null) ...[
              const SizedBox(width: 8),
              Text(subtitle,
                  style: TextStyle(
                      color: t.textMinimal, fontSize: t.fontSize(8))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumDropdown(BuildContext context, VisionTokens t, GalleryNotifier gallery) {
    final l = context.l;
    final albums = gallery.albums;
    if (albums.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: 24),
        child: Text(l.slideshowNoAlbums,
            style: TextStyle(
                color: t.textMinimal,
                fontSize: t.fontSize(8),
                letterSpacing: 1)),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: t.borderSubtle,
          borderRadius: BorderRadius.circular(4),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: config.albumId,
            hint: Text(l.slideshowSelectAlbum,
                style: TextStyle(
                    color: t.textMinimal, fontSize: t.fontSize(9))),
            isExpanded: true,
            dropdownColor: t.surfaceHigh,
            style:
                TextStyle(color: t.textSecondary, fontSize: t.fontSize(10)),
            onChanged: (id) =>
                onChanged(config.copyWith(albumId: id)),
            items: albums.map((album) {
              final count = gallery.albumItemCount(album.id);
              return DropdownMenuItem(
                value: album.id,
                child: Text('${album.name.toUpperCase()} ($count)'),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomPicker(BuildContext context, VisionTokens t, GalleryNotifier gallery) {
    final l = context.l;
    final selected = config.customImageBasenames.toSet();
    final allItems = gallery.items;
    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l.slideshowCustomCount(selected.length, allItems.length),
                  style: TextStyle(
                      color: t.textMinimal,
                      fontSize: t.fontSize(8),
                      letterSpacing: 1)),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  if (selected.length == allItems.length) {
                    onChanged(
                        config.copyWith(customImageBasenames: []));
                  } else {
                    onChanged(config.copyWith(
                        customImageBasenames:
                            allItems.map((i) => i.basename).toList()));
                  }
                },
                child: Text(
                    selected.length == allItems.length
                        ? l.slideshowDeselectAll
                        : l.slideshowSelectAll,
                    style: TextStyle(
                        color: t.accent,
                        fontSize: t.fontSize(8),
                        letterSpacing: 1)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: allItems.length,
              itemBuilder: (context, index) {
                final item = allItems[index];
                final isSelected = selected.contains(item.basename);
                return InkWell(
                  onTap: () {
                    final updated = List<String>.from(
                        config.customImageBasenames);
                    if (isSelected) {
                      updated.remove(item.basename);
                    } else {
                      updated.add(item.basename);
                    }
                    onChanged(
                        config.copyWith(customImageBasenames: updated));
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Image.file(
                          File(item.file.path),
                          fit: BoxFit.cover,
                          cacheWidth: 100,
                          gaplessPlayback: true,
                        ),
                      ),
                      if (isSelected)
                        Container(
                          decoration: BoxDecoration(
                            color: t.accent.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: t.accent, width: 2),
                          ),
                          child: Icon(Icons.check, color: t.accent, size: 20),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
