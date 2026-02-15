import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/responsive.dart';
import '../../gallery/providers/gallery_notifier.dart';

class DemoImagePicker extends StatefulWidget {
  const DemoImagePicker({super.key});

  @override
  State<DemoImagePicker> createState() => _DemoImagePickerState();
}

class _DemoImagePickerState extends State<DemoImagePicker> {
  int? _crossAxisCount;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _crossAxisCount ??= isMobile(context) ? 2 : 3;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final l = context.l;
    final gallery = context.watch<GalleryNotifier>();
    final mobile = isMobile(context);
    final items = gallery.allItems;
    final maxCols = mobile ? 3 : 5;
    final minCols = mobile ? 2 : 3;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        toolbarHeight: mobile ? 56 : 40,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: mobile ? 20 : 14, color: t.textDisabled),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l.demoImagesSelected(gallery.demoSafeCount),
          style: TextStyle(
            letterSpacing: 2,
            fontSize: mobile ? t.fontSize(13) : t.fontSize(10),
            fontWeight: FontWeight.w900,
            color: t.textSecondary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.grid_view, size: mobile ? 20 : 16, color: t.textDisabled),
            onPressed: () {
              setState(() {
                _crossAxisCount = _crossAxisCount! >= maxCols ? minCols : _crossAxisCount! + 1;
              });
            },
          ),
          TextButton(
            onPressed: () {
              gallery.addToDemoSafe(items);
            },
            child: Text(
              l.demoAll,
              style: TextStyle(
                color: t.accent,
                fontSize: mobile ? t.fontSize(11) : t.fontSize(9),
                letterSpacing: 1,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              gallery.clearDemoSafe();
            },
            child: Text(
              l.demoClear,
              style: TextStyle(
                color: t.accentDanger,
                fontSize: mobile ? t.fontSize(11) : t.fontSize(9),
                letterSpacing: 1,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Text(
                l.demoNoImages,
                style: TextStyle(color: t.textMinimal, fontSize: t.fontSize(10), letterSpacing: 2),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 80),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _crossAxisCount!,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return GestureDetector(
                  onTap: () => gallery.toggleDemoSafe(item),
                  child: Container(
                    decoration: BoxDecoration(
                      color: t.borderSubtle,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: item.isDemoSafe ? t.accentSuccess : t.borderSubtle,
                        width: item.isDemoSafe ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(item.file, fit: BoxFit.cover),
                        if (item.isDemoSafe)
                          Container(color: t.background.withValues(alpha: 0.3)),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: mobile ? 24 : 20,
                            height: mobile ? 24 : 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: item.isDemoSafe
                                  ? t.accentSuccess
                                  : t.background.withValues(alpha: 0.5),
                              border: Border.all(
                                color: item.isDemoSafe
                                    ? t.accentSuccess
                                    : t.accent.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                            child: item.isDemoSafe
                                ? Icon(Icons.check, size: mobile ? 14 : 12, color: t.background)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
