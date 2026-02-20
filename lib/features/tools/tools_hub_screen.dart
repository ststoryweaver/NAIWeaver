import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/l10n_extensions.dart';
import '../../core/services/preferences_service.dart';
import '../../core/utils/responsive.dart';
import '../../core/theme/theme_extensions.dart';
import 'widgets/wildcard_manager.dart';
import 'widgets/preset_manager.dart';
import 'widgets/style_editor.dart';
import 'widgets/app_settings.dart';
import 'widgets/tag_library_manager.dart';
import 'widgets/theme_builder.dart';
import 'widgets/pack_manager.dart';
import 'slideshow/widgets/slideshow_launcher.dart';
import 'cascade/widgets/cascade_editor.dart';
import 'img2img/widgets/img2img_editor.dart';
import 'widgets/references_manager.dart';

class ToolsHubScreen extends StatefulWidget {
  final String? initialToolId;
  const ToolsHubScreen({super.key, this.initialToolId});

  @override
  State<ToolsHubScreen> createState() => _ToolsHubScreenState();
}

class _ToolsHubScreenState extends State<ToolsHubScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSidebarExpanded = true;
  late String _activeToolId;

  late final PreferencesService _prefs;

  @override
  void initState() {
    super.initState();
    _prefs = Provider.of<PreferencesService>(context, listen: false);
    if (widget.initialToolId != null) {
      _activeToolId = widget.initialToolId!;
    } else {
      _activeToolId = _prefs.lastToolId ?? 'settings';
    }
  }

  void _selectTool(String id) {
    setState(() => _activeToolId = id);
    _prefs.setLastToolId(id);
  }

  List<ToolItem> _getTools(BuildContext context) {
    final l = context.l;
    return [
      ToolItem(id: 'wildcards', name: l.toolsWildcards.toUpperCase(), icon: Icons.style),
      ToolItem(id: 'tag_library', name: l.toolsTagLibrary.toUpperCase(), icon: Icons.local_offer),
      ToolItem(id: 'presets', name: l.toolsPresets.toUpperCase(), icon: Icons.tune),
      ToolItem(id: 'styles', name: l.toolsStyles.toUpperCase(), icon: Icons.auto_awesome),
      ToolItem(id: 'director_ref', name: l.toolsReferences.toUpperCase(), icon: Icons.photo_library),
      ToolItem(id: 'cascade', name: l.toolsCascadeEditor.toUpperCase(), icon: Icons.movie_filter),
      ToolItem(id: 'img2img', name: l.toolsImg2imgEditor.toUpperCase(), icon: Icons.brush),
      ToolItem(id: 'slideshow', name: l.toolsSlideshow.toUpperCase(), icon: Icons.slideshow),
      ToolItem(id: 'packs', name: l.toolsPacks.toUpperCase(), icon: Icons.inventory_2),
      ToolItem(id: 'theme', name: l.toolsTheme.toUpperCase(), icon: Icons.palette),
      ToolItem(id: 'settings', name: l.toolsSettings.toUpperCase(), icon: Icons.settings),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);
    final t = context.t;
    final l = context.l;
    final tools = _getTools(context);
    final activeTool = tools.firstWhere((tool) => tool.id == _activeToolId, orElse: () => tools.first);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        toolbarHeight: mobile ? 48 : 32,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: mobile ? 20 : 14, color: t.secondaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          mobile ? activeTool.name : l.toolsHub.toUpperCase(),
          style: TextStyle(
            letterSpacing: 4,
            fontSize: t.fontSize(mobile ? 12 : 10),
            fontWeight: FontWeight.w900,
            color: t.headerText,
          ),
        ),
        actions: mobile
            ? [
                IconButton(
                  icon: Icon(Icons.menu, size: 22, color: t.secondaryText),
                  onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                ),
              ]
            : null,
      ),
      endDrawer: mobile
          ? Drawer(
              backgroundColor: t.surfaceMid,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(l.toolsTitle.toUpperCase(), style: TextStyle(color: t.secondaryText, fontSize: t.fontSize(10), letterSpacing: 2, fontWeight: FontWeight.bold)),
                    ),
                    Divider(height: 1, color: t.borderMedium),
                    ...tools.map((tool) {
                      final isActive = _activeToolId == tool.id;
                      return ListTile(
                        leading: Icon(tool.icon, size: 20, color: isActive ? t.accent : t.secondaryText),
                        title: Text(
                          tool.name,
                          style: TextStyle(
                            fontSize: t.fontSize(12),
                            letterSpacing: 2,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            color: isActive ? t.accent : t.secondaryText,
                          ),
                        ),
                        selected: isActive,
                        selectedTileColor: t.borderSubtle,
                        onTap: () {
                          _selectTool(tool.id);
                          Navigator.pop(context); // close drawer
                        },
                      );
                    }),
                  ],
                ),
              ),
            )
          : null,
      body: mobile
          ? SafeArea(top: false, child: _buildToolContent())
          : Row(
              children: [
                _buildSidebar(t, tools),
                VerticalDivider(width: 1, color: t.borderMedium),
                Expanded(
                  child: _buildToolContent(),
                ),
              ],
            ),
    );
  }

  Widget _buildSidebar(dynamic t, List<ToolItem> tools) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isSidebarExpanded ? 180 : 56,
      color: t.surfaceMid,
      child: Column(
        children: [
          const SizedBox(height: 8),
          IconButton(
            icon: Icon(
              _isSidebarExpanded ? Icons.chevron_left : Icons.menu,
              size: 16,
              color: t.secondaryText,
            ),
            onPressed: () => setState(() => _isSidebarExpanded = !_isSidebarExpanded),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: tools.map((tool) => _buildSidebarItem(tool, t)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(ToolItem tool, dynamic t) {
    final bool isActive = _activeToolId == tool.id;
    return InkWell(
      onTap: () => _selectTool(tool.id),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: isActive ? t.accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 54,
              child: Icon(
                tool.icon,
                size: 16,
                color: isActive ? t.accent : t.secondaryText,
              ),
            ),
            if (_isSidebarExpanded)
              Expanded(
                child: Text(
                  tool.name,
                  style: TextStyle(
                    fontSize: t.fontSize(9),
                    letterSpacing: 2,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? t.accent : t.secondaryText,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolContent() {
    switch (_activeToolId) {
      case 'wildcards':
        return const WildcardManager();
      case 'tag_library':
        return const TagLibraryManager();
      case 'presets':
        return const PresetManager();
      case 'styles':
        return const StyleEditor();
      case 'director_ref':
        return const ReferencesManager();
      case 'cascade':
        return const CascadeEditor();
      case 'img2img':
        return const Img2ImgEditor();
      case 'slideshow':
        return const SlideshowLauncher();
      case 'packs':
        return const PackManager();
      case 'theme':
        return const ThemeBuilder();
      case 'settings':
        return const AppSettings();
      default:
        return const SizedBox.shrink();
    }
  }
}

class ToolItem {
  final String id;
  final String name;
  final IconData icon;

  ToolItem({required this.id, required this.name, required this.icon});
}
