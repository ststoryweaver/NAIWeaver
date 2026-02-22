import 'dart:async';
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/l10n/locale_notifier.dart';
import 'core/l10n/l10n_extensions.dart';
import 'core/services/path_service.dart';
import 'core/services/preferences_service.dart';
import 'core/utils/responsive.dart';
import 'core/widgets/help_dialog.dart';
import 'core/widgets/pin_lock_gate.dart';
import 'core/widgets/quick_action_overlay.dart';
import 'core/theme/theme_notifier.dart';
import 'core/theme/theme_extensions.dart';
import 'features/generation/providers/generation_notifier.dart';
import 'features/generation/widgets/image_viewer.dart';
import 'features/generation/widgets/settings_panel.dart';
import 'features/tools/tools_hub_screen.dart';
import 'features/tools/providers/wildcard_notifier.dart';
import 'features/tools/providers/tag_library_notifier.dart';
import 'features/gallery/providers/gallery_notifier.dart';
import 'features/gallery/ui/gallery_screen.dart';
import 'features/generation/widgets/character_shelf.dart';
import 'core/ml/ml_notifier.dart';
import 'features/tools/cascade/providers/cascade_notifier.dart';
import 'features/tools/canvas/providers/canvas_notifier.dart';
import 'features/tools/img2img/providers/img2img_notifier.dart';
import 'features/tools/cascade/widgets/cascade_playback_view.dart';
import 'features/director_ref/providers/director_ref_notifier.dart';
import 'features/director_ref/widgets/director_ref_shelf.dart';
import 'features/vibe_transfer/providers/vibe_transfer_notifier.dart';
import 'features/generation/widgets/vibe_transfer_shelf.dart';
import 'features/tools/slideshow/providers/slideshow_notifier.dart';
import 'features/tools/director_tools/providers/director_tools_notifier.dart';
import 'features/tools/enhance/providers/enhance_notifier.dart';
import 'core/widgets/tag_suggestion_overlay.dart';
import 'core/jukebox/providers/jukebox_notifier.dart';
import 'core/jukebox/services/jukebox_audio_handler.dart';
import 'core/services/tag_service.dart';
import 'core/services/wildcard_service.dart';
import 'package:audio_service/audio_service.dart';

void main() {
  runZonedGuarded(() async {
  WidgetsFlutterBinding.ensureInitialized();
  final paths = await PathService.initialize();
  await paths.ensureDirectories();
  await paths.seedAssets();
  final prefs = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();
  final preferencesService = PreferencesService(prefs, secureStorage);
  await preferencesService.migrateApiKey();

  final customOut = preferencesService.customOutputDir;
  if (customOut.isNotEmpty) paths.outputDirOverride = customOut;

  final tagService = TagService(filePath: paths.tagFilePath);
  final wildcardService = WildcardService(wildcardDir: paths.wildcardDir);

  JukeboxAudioHandler? audioHandler;
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      audioHandler = await AudioService.init(
        builder: () => JukeboxAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'dev.naiweaver.app.jukebox',
          androidNotificationChannelName: 'NAIWeaver Jukebox',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
          androidNotificationIcon: 'mipmap/ic_launcher',
        ),
      );
    } catch (e) {
      debugPrint('AudioService init failed: $e');
    }
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };
  runApp(
    MultiProvider(
      providers: [
        Provider<PathService>.value(value: paths),
        Provider<PreferencesService>.value(value: preferencesService),
        ChangeNotifierProvider(
          create: (_) => ThemeNotifier(preferencesService),
        ),
        ChangeNotifierProvider(
          create: (_) => LocaleNotifier(preferencesService),
        ),
        ChangeNotifierProvider(
          create: (_) => GalleryNotifier(
            outputDir: paths.outputDir,
            prefs: preferencesService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => DirectorRefNotifier(),
        ),
        ChangeNotifierProvider(
          create: (_) => VibeTransferNotifier(),
        ),
        ChangeNotifierProvider(
          create: (_) => DirectorToolsNotifier(),
        ),
        ChangeNotifierProvider(
          create: (_) => EnhanceNotifier(),
        ),
        Provider<TagService>.value(value: tagService),
        Provider<WildcardService>.value(value: wildcardService),
        ChangeNotifierProxyProvider5<GalleryNotifier, DirectorRefNotifier, VibeTransferNotifier, DirectorToolsNotifier, EnhanceNotifier, GenerationNotifier>(
          create: (context) => GenerationNotifier(
            preferences: preferencesService,
            tagService: tagService,
            wildcardService: wildcardService,
            outputDir: paths.outputDir,
            presetsFilePath: paths.presetsFilePath,
            stylesFilePath: paths.stylesFilePath,
            galleryNotifier: Provider.of<GalleryNotifier>(context, listen: false),
          ),
          update: (context, gallery, directorRef, vibeTransfer, directorTools, enhance, previous) {
            previous?.updateGalleryNotifier(gallery);
            previous?.updateDirectorRefNotifier(directorRef);
            previous?.updateVibeTransferNotifier(vibeTransfer);
            previous?.updateDirectorToolsNotifier(directorTools);
            previous?.updateEnhanceNotifier(enhance);
            return previous!;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => WildcardNotifier(
            wildcardDir: paths.wildcardDir,
            tagService: tagService,
            wildcardService: wildcardService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => TagLibraryNotifier(
            tagService: tagService,
            examplesDir: paths.examplesDir,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => MLNotifier(
            mlModelsDir: paths.mlModelsDir,
            prefs: preferencesService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CascadeNotifier(),
        ),
        ChangeNotifierProvider(
          create: (_) => Img2ImgNotifier(),
        ),
        ChangeNotifierProvider(
          create: (_) => CanvasNotifier(),
        ),
        ChangeNotifierProvider(
          create: (_) => SlideshowNotifier()
            ..loadFromJson(preferencesService.slideshowConfigs)
            ..setDefaultConfigId(preferencesService.defaultSlideshowId),
        ),
        ChangeNotifierProvider(
          create: (_) {
            final n = JukeboxNotifier(
              soundfontsDir: paths.soundfontsDir,
              customSongsDir: paths.customSongsDir,
              customSongsJsonPath: paths.customSongsJsonPath,
              prefs: preferencesService,
            )..initialize();
            audioHandler?.attachNotifier(n);
            return n;
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          final themeNotifier = context.watch<ThemeNotifier>();
          final localeNotifier = context.watch<LocaleNotifier>();
          return ValueListenableBuilder<bool>(
            valueListenable: preferencesService.tooltipVisibilityNotifier,
            builder: (context, visible, child) => TooltipVisibility(
              visible: visible,
              child: child!,
            ),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              scrollBehavior: const MaterialScrollBehavior().copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.stylus,
                  PointerDeviceKind.mouse,
                },
              ),
              theme: themeNotifier.themeData,
              locale: localeNotifier.locale,
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: PinLockGate(
                prefs: preferencesService,
                child: const SimpleGeneratorApp(),
              ),
            ),
          );
        },
      ),
    ),
  );
  }, (error, stack) {
    debugPrint('Uncaught error: $error');
    debugPrint('$stack');
  });
}

class SimpleGeneratorApp extends StatefulWidget {
  const SimpleGeneratorApp({super.key});

  @override
  State<SimpleGeneratorApp> createState() => _SimpleGeneratorAppState();
}

class _SimpleGeneratorAppState extends State<SimpleGeneratorApp> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isTouchingSuggestions = false;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(_pulseController);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = context.read<GenerationNotifier>();
      notifier.addListener(() => _onGenerationStateChanged(notifier));
    });
  }

  void _onGenerationStateChanged(GenerationNotifier notifier) {
    if (!mounted) return;
    final state = notifier.state;

    // Control pulse animation
    if (state.isLoading) {
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
    } else {
      if (_pulseController.isAnimating) _pulseController.stop();
    }

    // Show auth error
    if (state.hasAuthError) {
      _showAuthError(context);
      notifier.clearAuthError();
    }

    // Show generation error
    if (state.errorMessage != null) {
      _showError(context, state.errorMessage!);
      notifier.clearError();
    }
  }

  void _showError(BuildContext context, String message) {
    final t = context.tRead;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1A0000),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: t.accentDanger, width: 0.5),
        ),
        content: Row(
          children: [
            Icon(Icons.error_outline, color: t.accentDanger, size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: t.accentDanger,
                  fontSize: t.fontSize(10),
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAuthError(BuildContext context) {
    final t = context.tRead;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1A0000),
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: t.accentDanger, width: 0.5),
        ),
        content: Row(
          children: [
            Icon(Icons.error_outline, color: t.accentDanger, size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l.mainAuthError.toUpperCase(),
                style: TextStyle(
                  color: t.accentDanger,
                  fontSize: t.fontSize(10),
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: context.l.mainSettings.toUpperCase(),
          textColor: t.textPrimary,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ToolsHubScreen(initialToolId: 'settings'),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildScaffold(context);
  }

  Widget _buildScaffold(BuildContext context) {
    final notifier = context.watch<GenerationNotifier>();
    final cascadeNotifier = context.watch<CascadeNotifier>();
    final state = notifier.state;

    final isCascadeMode = cascadeNotifier.state.activeCascade != null;

    final mobile = isMobile(context);
    final t = context.t;

    Widget scaffold = Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: t.background,
          appBar: AppBar(
            title: Image.asset(
              'assets/logo.png',
              height: 28,
              filterQuality: FilterQuality.medium,
              color: t.logoColor,
              colorBlendMode: BlendMode.srcIn,
            ),
            centerTitle: false,
            backgroundColor: t.background,
            elevation: 0,
            toolbarHeight: mobile ? 48 : 32,
            actions: [
              if (state.anlas != null && context.read<PreferencesService>().showAnlasTracker)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Tooltip(
                    message: context.l.mainRefreshAnlas,
                    child: InkWell(
                    onTap: () => notifier.fetchAnlas(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: mobile ? 10 : 8, vertical: mobile ? 4 : 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: t.borderMedium),
                        color: t.borderSubtle,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.toll, size: mobile ? 14 : 11, color: t.headerText),
                          const SizedBox(width: 4),
                          Text(
                            '${state.anlas}',
                            style: TextStyle(
                              color: t.headerText,
                              fontSize: t.fontSize(mobile ? 10 : 8),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ),
                ),
              IconButton(
                onPressed: () => showHelpDialog(context),
                icon: Icon(Icons.help_outline, color: t.headerText, size: mobile ? 20 : 16),
                tooltip: context.l.mainHelp,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GalleryScreen()),
                  );
                },
                child: Text(
                  context.l.mainGallery.toUpperCase(),
                  style: TextStyle(
                    color: t.headerText,
                    fontSize: t.fontSize(mobile ? 11 : 8),
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ToolsHubScreen()),
                  );
                },
                child: Text(
                  context.l.mainTools.toUpperCase(),
                  style: TextStyle(
                    color: t.headerText,
                    fontSize: t.fontSize(mobile ? 11 : 8),
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            bottom: false, // settings panel handles its own bottom safe area
            left: false,
            right: false,
            child: Stack(
            children: [
              ImagePreviewViewer(
                generatedImage: state.generatedImage,
                isLoading: state.isLoading,
                isDragging: state.isDragging,
                pulseAnimation: _pulseAnimation,
              ),

              const Positioned.fill(child: QuickActionOverlay()),

              // Cascade Mode Overlay
              if (isCascadeMode)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: mobile
                      ? (MediaQuery.of(context).viewInsets.bottom > 0
                          ? MediaQuery.of(context).viewInsets.bottom
                          : (48.0 + MediaQuery.of(context).viewPadding.bottom))
                      : (MediaQuery.of(context).viewInsets.bottom > 0
                        ? MediaQuery.of(context).viewInsets.bottom
                        : 40.0 + MediaQuery.of(context).viewPadding.bottom),
                  child: const CascadePlaybackView(),
                ),

              // Prompt Area (Standard Mode)
              if (!isCascadeMode)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: mobile
                      ? (MediaQuery.of(context).viewInsets.bottom > 0
                          ? MediaQuery.of(context).viewInsets.bottom
                          : (48.0 + MediaQuery.of(context).viewPadding.bottom))
                      : (MediaQuery.of(context).viewInsets.bottom > 0
                        ? MediaQuery.of(context).viewInsets.bottom
                        : 40.0 + MediaQuery.of(context).viewPadding.bottom),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), // Increased bottom padding for clearance
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          t.background.withValues(alpha: 0.8),
                          t.background,
                        ],
                        stops: const [0.4, 0.7, 1.0],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (state.showDirectorRefShelf)
                          const DirectorRefShelf(),
                        if (state.showVibeTransferShelf)
                          const VibeTransferShelf(),
                        Selector<GenerationNotifier, String>(
                          selector: (_, n) => n.state.characterEditorMode,
                          builder: (context, mode, _) {
                            if (mode == 'compact') return const CharacterShelf();
                            return const SizedBox.shrink();
                          },
                        ),
                        // Tag suggestion row — dedicated row with opaque backdrop
                        Listener(
                          behavior: HitTestBehavior.translucent,
                          onPointerDown: (_) => _isTouchingSuggestions = true,
                          onPointerUp: (_) => Future.delayed(
                            const Duration(milliseconds: 300),
                            () => _isTouchingSuggestions = false,
                          ),
                          onPointerCancel: (_) => _isTouchingSuggestions = false,
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            child: TagSuggestionOverlay(
                              suggestions: state.tagSuggestions,
                              onTagSelected: notifier.applyTagSuggestion,
                            ),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Focus(
                                onFocusChange: (hasFocus) {
                                  if (!hasFocus) {
                                    Future.delayed(const Duration(milliseconds: 200), () {
                                      if (!_isTouchingSuggestions) {
                                        notifier.clearTagSuggestions();
                                      }
                                    });
                                  }
                                },
                                child: TextField(
                                controller: notifier.promptController,
                                maxLines: mobile ? t.promptMaxLines + 2 : t.promptMaxLines + 1,
                                onChanged: (val) => notifier.handleTagSuggestions(val, notifier.promptController.selection),
                                onTapOutside: (_) {
                                  Future.delayed(const Duration(milliseconds: 200), () {
                                    if (!_isTouchingSuggestions) {
                                      notifier.clearTagSuggestions();
                                    }
                                  });
                                },
                                onSubmitted: (_) {
                                  if (state.tagSuggestions.isNotEmpty) {
                                    notifier.applyTagSuggestion(state.tagSuggestions.first);
                                  } else {
                                    notifier.generate();
                                  }
                                },
                                style: TextStyle(fontSize: t.promptFontSize - 1, letterSpacing: 0.5),
                                decoration: InputDecoration(
                                  hintText: context.l.mainEnterPrompt.toUpperCase(),
                                  hintStyle: TextStyle(fontSize: t.fontSize(mobile ? 12 : 9), letterSpacing: 2, color: t.hintText),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  fillColor: t.background.withValues(alpha: 0.8),
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: BorderSide(color: t.borderMedium),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: BorderSide(color: t.borderMedium),
                                  ),
                                ),
                              ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              height: mobile ? 64 : 58,
                              width: mobile ? 64 : 58,
                              child: ElevatedButton(
                                onPressed: state.isLoading ? null : notifier.generate,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  backgroundColor: t.accent,
                                  foregroundColor: t.background,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  elevation: 0,
                                ),
                                child: state.isLoading
                                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: t.background))
                                  : const Icon(Icons.arrow_forward_ios, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              AdvancedSettingsPanel(
                onManageStyles: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ToolsHubScreen(initialToolId: 'styles')),
                  );
                },
                onSavePreset: () => _showSavePresetDialog(context, notifier),
              ),
            ],
          ),
          ),
        );

    return isDesktopPlatform()
          ? DropTarget(
              onDragDone: (details) async {
                if (details.files.isNotEmpty) {
                  try {
                    await notifier.importImageMetadata(File(details.files.first.path));
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l.mainImportFailed(e.toString()))),
                    );
                  }
                }
              },
              onDragEntered: (details) => notifier.setDragging(true),
              onDragExited: (details) => notifier.setDragging(false),
              child: scaffold,
            )
          : scaffold;
  }

  void _showSavePresetDialog(BuildContext context, GenerationNotifier notifier) {
    final TextEditingController nameController = TextEditingController();
    final t = context.tRead;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: t.surfaceHigh,
        title: Text(context.l.mainSavePreset.toUpperCase(), style: TextStyle(fontSize: t.fontSize(10), letterSpacing: 2, color: t.textSecondary)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(13)),
          decoration: InputDecoration(
            hintText: context.l.mainPresetName.toUpperCase(),
            hintStyle: TextStyle(color: t.textMinimal, fontSize: t.fontSize(9)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.borderMedium)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l.commonCancel.toUpperCase(), style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9))),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                notifier.savePreset(nameController.text);
                Navigator.pop(context);
              }
            },
            child: Text(context.l.commonSave.toUpperCase(), style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(9))),
          ),
        ],
      ),
    );
  }
}
