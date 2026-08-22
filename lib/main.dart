import 'dart:async';
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'core/utils/app_snackbar.dart';
import 'core/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'core/l10n/locale_notifier.dart';
import 'core/l10n/l10n_extensions.dart';
import 'core/services/path_service.dart';
import 'core/services/preferences_service.dart';
import 'core/services/update_service.dart';
import 'core/widgets/update_prompt.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'core/utils/responsive.dart';
import 'core/utils/wheel_scroll.dart';
import 'core/widgets/help_dialog.dart';
import 'core/widgets/pin_lock_gate.dart';
import 'core/widgets/quick_action_overlay.dart';
import 'core/theme/theme_notifier.dart';
import 'core/theme/theme_extensions.dart';
import 'core/theme/vision_tokens.dart';
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
import 'features/generation/widgets/sidebar_ref_vibe_rail.dart';
import 'features/tools/slideshow/providers/slideshow_notifier.dart';
import 'features/tools/director_tools/providers/director_tools_notifier.dart';
import 'features/tools/enhance/providers/enhance_notifier.dart';
import 'features/text_gen/providers/text_gen_notifier.dart';
import 'features/characters/providers/character_library_notifier.dart';
import 'features/characters/gen/providers/character_gen_notifier.dart';
import 'features/characters/services/character_library_service.dart';
import 'features/characters/services/closet_service.dart';
import 'core/widgets/tag_suggestion_overlay.dart';
import 'core/jukebox/providers/jukebox_notifier.dart';
import 'core/jukebox/services/jukebox_audio_handler.dart';
import 'core/services/tag_service.dart';
import 'core/services/wiki_service.dart';
import 'core/services/wildcard_service.dart';
import 'package:audio_service/audio_service.dart';

class _AppWindowListener extends WindowListener {
  final PreferencesService _prefs;
  _AppWindowListener(this._prefs);

  @override
  void onWindowClose() async {
    try {
      final bounds = await windowManager.getBounds();
      final maximized = await windowManager.isMaximized();
      // Don't persist a degenerate rect (can happen if the window was minimized
      // or mid-animation when closing) — it would make the next launch's window
      // invisible.
      if (bounds.width >= 400 && bounds.height >= 300) {
        await _prefs.saveWindowState(
          x: bounds.left, y: bounds.top,
          w: bounds.width, h: bounds.height,
          maximized: maximized,
        );
      }
    } catch (_) {}
    await windowManager.destroy();
  }
}

void main() {
  runZonedGuarded(() async {
  // Rescales Android mouse-wheel deltas so one notch ≈ one text line
  // instead of 3-4 (issue #14).
  NaiWidgetsBinding.ensureInitialized();
  final paths = await PathService.initialize();
  await paths.ensureDirectories();
  await paths.seedAssets();
  final prefs = await SharedPreferences.getInstance();
  final secureStorage = FlutterSecureStorage(
    aOptions: const AndroidOptions(encryptedSharedPreferences: true),
  );
  final preferencesService = PreferencesService(prefs, secureStorage);
  await preferencesService.migrateApiKey();

  // Restore window state on desktop
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    final saved = preferencesService.windowBounds;
    // Only restore a saved rect if it's sane — a stale/garbage value (zero or
    // negative size, or a position far off any plausible screen) would leave
    // the window invisible. Otherwise fall back to a sensible default + center.
    final bool savedIsSane = saved != null &&
        saved.w >= 400 &&
        saved.h >= 300 &&
        saved.w <= 16384 &&
        saved.h <= 16384 &&
        saved.x > -16384 &&
        saved.x < 16384 &&
        saved.y > -16384 &&
        saved.y < 16384;
    if (savedIsSane) {
      await windowManager.setBounds(
          Rect.fromLTWH(saved.x, saved.y, saved.w, saved.h));
    } else {
      await windowManager.setSize(const Size(1280, 800));
      await windowManager.center();
    }
    if (preferencesService.windowMaximized) {
      await windowManager.maximize();
    }
    // Make sure the window is actually visible and frontmost regardless of what
    // was restored — guards against an off-screen restore on a now-disconnected
    // monitor.
    await windowManager.show();
    await windowManager.focus();
    windowManager.setPreventClose(true);
    windowManager.addListener(_AppWindowListener(preferencesService));
  }

  final customOut = preferencesService.customOutputDir;
  if (customOut.isNotEmpty) {
    // The custom dir can vanish (SD card ejected). Fall back to the default
    // for this session but keep the pref, so the override comes back with
    // the card.
    try {
      Directory(customOut).createSync(recursive: true);
      paths.outputDirOverride = customOut;
    } catch (e) {
      debugPrint('Custom output dir unavailable, using default: $e');
    }
  }

  final tagService = TagService(filePath: paths.tagFilePath);
  final wildcardService = WildcardService(wildcardDir: paths.wildcardDir);
  final wikiService = WikiService();
  final characterLibraryService =
      CharacterLibraryService(charactersDir: paths.charactersDir);
  final closetService = ClosetService(charactersDir: paths.charactersDir);

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
          create: (_) => DirectorRefNotifier()
            ..setDefaults(
              strength: preferencesService.refLastStrength,
              fidelity: preferencesService.refLastFidelity,
              prefs: preferencesService,
            ),
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
        ChangeNotifierProvider(
          create: (_) => TextGenNotifier(),
        ),
        ChangeNotifierProvider(
          create: (_) => CharacterLibraryNotifier(
            service: characterLibraryService,
            closetService: closetService,
          )..loadAll(),
        ),
        ChangeNotifierProxyProvider2<CharacterLibraryNotifier, TextGenNotifier, CharacterGenNotifier>(
          create: (context) => CharacterGenNotifier(
            library: Provider.of<CharacterLibraryNotifier>(context, listen: false),
            textGen: Provider.of<TextGenNotifier>(context, listen: false),
          ),
          update: (context, library, textGen, previous) =>
              (previous ?? CharacterGenNotifier(library: library, textGen: textGen))
                ..updateTextGen(textGen),
        ),
        Provider<TagService>.value(value: tagService),
        Provider<WildcardService>.value(value: wildcardService),
        Provider<WikiService>.value(value: wikiService),
        ChangeNotifierProxyProvider6<GalleryNotifier, DirectorRefNotifier, VibeTransferNotifier, DirectorToolsNotifier, EnhanceNotifier, TextGenNotifier, GenerationNotifier>(
          create: (context) => GenerationNotifier(
            preferences: preferencesService,
            tagService: tagService,
            wildcardService: wildcardService,
            outputDir: paths.outputDir,
            presetsFilePath: paths.presetsFilePath,
            stylesFilePath: paths.stylesFilePath,
            galleryNotifier: Provider.of<GalleryNotifier>(context, listen: false),
            characterLibrary:
                Provider.of<CharacterLibraryNotifier>(context, listen: false),
          ),
          update: (context, gallery, directorRef, vibeTransfer, directorTools, enhance, textGen, previous) {
            previous?.updateGalleryNotifier(gallery);
            previous?.updateDirectorRefNotifier(directorRef);
            previous?.updateVibeTransferNotifier(vibeTransfer);
            previous?.updateDirectorToolsNotifier(directorTools);
            previous?.updateEnhanceNotifier(enhance);
            previous?.updateTextGenNotifier(textGen);
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
  late VoidCallback _generationListener;
  bool _isTouchingSuggestions = false;
  int _tagSuggestionIndex = -1;
  final FocusNode _globalFocusNode = FocusNode(skipTraversal: true);

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
      _generationListener = () => _onGenerationStateChanged(notifier);
      notifier.addListener(_generationListener);
      _maybeCheckForUpdate();
    });
  }

  /// Background, once-per-day update check. Never blocks startup and never
  /// throws into the launch path; if an update is found (and not skipped),
  /// surfaces a non-intrusive SnackBar prompt.
  Future<void> _maybeCheckForUpdate() async {
    if (kIsWeb) return;
    try {
      final prefs = context.read<PreferencesService>();
      final now = DateTime.now().millisecondsSinceEpoch;
      const dayMs = 24 * 60 * 60 * 1000;
      if (now - prefs.lastUpdateCheck < dayMs) return;

      // Let first frame / model loading settle before hitting the network.
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;

      final info = await PackageInfo.fromPlatform();
      final result = await UpdateService.checkForUpdate(info.version);
      // Throttle regardless of outcome so a transient failure doesn't re-check
      // on every launch.
      await prefs.setLastUpdateCheck(now);

      if (!mounted) return;
      if (result.updateAvailable &&
          result.latestVersion != null &&
          result.latestVersion != prefs.skippedUpdateVersion) {
        showUpdatePrompt(context, result);
      }
    } catch (_) {
      // A launch-time update check must never crash or block the app.
    }
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

    // Show duplicate image warning
    if (state.duplicateImageDetected) {
      showAppSnackBar(
        context,
        context.l.duplicateImageWarning.toUpperCase(),
        color: Colors.orange,
        action: SnackBarAction(
          label: context.l.duplicateImageRandomize.toUpperCase(),
          textColor: Colors.orange,
          onPressed: () => notifier.updateSettings(randomizeSeed: true),
        ),
      );
      notifier.clearDuplicateWarning();
    }
  }

  /// Applies a main-prompt tag suggestion and surfaces the one outcome that
  /// needs user feedback: hitting the 6-character cap while routing a saved
  /// character to the editor.
  void _applyMainTagSuggestion(GenerationNotifier notifier, DanbooruTag tag) {
    final result = notifier.applyTagSuggestion(tag);
    if (result == ApplyTagResult.characterLimitReached && mounted) {
      showErrorSnackBar(context, context.l.charEditorCharacterLimitReached);
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

  void _cycleStyle(GenerationNotifier notifier, bool forward) {
    final styles = notifier.state.styles;
    if (styles.isEmpty) return;

    // Only cycle through non-default styles (preserve quality tags)
    final cyclableStyles = styles.where((s) => !s.isDefault).toList();
    if (cyclableStyles.isEmpty) return;

    final active = notifier.state.activeStyleNames;

    // Find current non-default active style
    final currentIndex = active.isNotEmpty
        ? cyclableStyles.indexWhere((s) => active.contains(s.name))
        : -1;

    final nextIndex = forward
        ? (currentIndex + 1) % cyclableStyles.length
        : (currentIndex - 1 + cyclableStyles.length) % cyclableStyles.length;

    // Only clear non-default active styles
    for (final name in [...active]) {
      if (!styles.any((s) => s.name == name && s.isDefault)) {
        notifier.toggleStyle(name);
      }
    }
    notifier.toggleStyle(cyclableStyles[nextIndex].name);

    ScaffoldMessenger.of(context).clearSnackBars();
    showAppSnackBar(context, cyclableStyles[nextIndex].name.toUpperCase());
  }

  void _adjustTagWeight(TextEditingController controller, double delta) {
    final text = controller.text;
    final sel = controller.selection;
    if (!sel.isValid || sel.baseOffset < 0) return;
    final cursor = sel.baseOffset;

    // Find tag boundaries (comma-delimited)
    int start = text.lastIndexOf(',', cursor - 1) + 1;
    int end = text.indexOf(',', cursor);
    if (end < 0) end = text.length;

    String tag = text.substring(start, end).trim();
    if (tag.isEmpty) return;

    // Parse existing weight: value::tag:: (NAI format) or legacy {tag:weight}
    double weight = 1.0;
    String bareTag = tag;

    // NAI format: 1.2::tag::
    final naiMatch = RegExp(r'^(-?[0-9.]+)::(.+)::$').firstMatch(tag);
    // Legacy format: {tag:weight}
    final legacyMatch = RegExp(r'^\{(.+):([0-9.-]+)\}$').firstMatch(tag);

    if (naiMatch != null) {
      weight = double.tryParse(naiMatch.group(1)!) ?? 1.0;
      bareTag = naiMatch.group(2)!;
    } else if (legacyMatch != null) {
      bareTag = legacyMatch.group(1)!;
      weight = double.tryParse(legacyMatch.group(2)!) ?? 1.0;
    } else if (tag.startsWith('{') && tag.endsWith('}')) {
      bareTag = tag.substring(1, tag.length - 1);
      weight = 1.05;
    }

    weight = ((weight + delta) * 10).round() / 10;

    // Format result using NAI's value::tag:: syntax
    String result;
    if ((weight - 1.0).abs() < 0.01) {
      result = bareTag;
    } else {
      result = '${weight.toStringAsFixed(1)}::$bareTag::';
    }

    // Preserve spacing
    final prefix = text.substring(start, start + (text.substring(start).length - text.substring(start).trimLeft().length));
    final newText = text.substring(0, start) + prefix + result + text.substring(end);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + prefix.length + result.length),
    );
  }

  @override
  void dispose() {
    _globalFocusNode.dispose();
    context.read<GenerationNotifier>().removeListener(_generationListener);
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
    final themeNotifier = context.watch<ThemeNotifier>();
    final useSidebar = isWidescreenLayout(context, themeNotifier.sidebarLayoutMode);
    final promptOnLeft = themeNotifier.sidebarPromptPosition == 'left';

    Widget scaffold = Focus(
      focusNode: _globalFocusNode,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.enter &&
            HardwareKeyboard.instance.isControlPressed) {
          final n = context.read<GenerationNotifier>();
          if (!n.state.isLoading) n.generate();
          return KeyEventResult.handled;
        }
        // Alt+Left/Right → cycle style (works when the prompt field is not
        // focused; the prompt field has its own copy of this binding).
        if (HardwareKeyboard.instance.isAltPressed &&
            !HardwareKeyboard.instance.isControlPressed &&
            (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
             event.logicalKey == LogicalKeyboardKey.arrowRight)) {
          _cycleStyle(context.read<GenerationNotifier>(),
              event.logicalKey == LogicalKeyboardKey.arrowRight);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          // First: collapse settings panel if expanded
          if (notifier.state.isSettingsExpanded) {
            notifier.toggleSettings();
            return;
          }
          // Second: show exit confirmation
          final confirmed = await showConfirmDialog(
            context,
            title: context.l.commonConfirm,
            message: context.l.mainExitConfirmation,
            confirmLabel: context.l.commonConfirm,
          );
          if (confirmed == true && context.mounted) {
            SystemNavigator.pop();
          }
        },
        child: Scaffold(
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
                Builder(builder: (context) {
                  // V5 on Opus is metered by a usage battery (free renders
                  // refill over time); V4.5 stays unlimited. Show the battery
                  // next to the Anlas count whenever a V5 model is active.
                  final usage = state.subscription?.usage;
                  final showBattery = state.model.isV5 && usage != null;
                  final low = usage?.isLow ?? false;
                  const warn = Color(0xFFFF9800);
                  final batteryColor = low ? warn : t.headerText;
                  final String tip;
                  if (showBattery) {
                    tip = 'Opus V5 allowance: ${usage.remainingPercent.toStringAsFixed(1)}% '
                        '(~${usage.imagesLeft} images) · refills ~${usage.percentPerDay.toStringAsFixed(1)}%/day '
                        '(~${usage.imagesPerDay} images). When empty, V5 renders cost Anlas; V4.5 stays free.\n'
                        '${context.l.mainRefreshAnlas}';
                  } else if (state.model.isV5 && state.subscription != null && !state.subscription!.isOpus) {
                    tip = 'V5 costs Anlas on your plan (V4.5 too, below Opus).\n${context.l.mainRefreshAnlas}';
                  } else {
                    tip = context.l.mainRefreshAnlas;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Tooltip(
                      message: tip,
                      child: InkWell(
                        onTap: () => notifier.fetchAnlas(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: mobile ? 10 : 8, vertical: mobile ? 4 : 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: low ? warn : t.borderMedium),
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
                              if (showBattery) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  low ? Icons.battery_alert : Icons.battery_charging_full,
                                  size: mobile ? 14 : 11,
                                  color: batteryColor,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${usage.remainingPercent.round()}% · ~${usage.imagesLeft}',
                                  style: TextStyle(
                                    color: batteryColor,
                                    fontSize: t.fontSize(mobile ? 10 : 8),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
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
            bottom: false,
            left: false,
            right: false,
            child: useSidebar
                ? _buildSidebarBody(context, notifier, state, isCascadeMode, mobile, t, promptOnLeft)
                : _buildDefaultBody(context, notifier, state, isCascadeMode, mobile, t),
          ),
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

  // — Default body (classic bottom-sheet layout) —
  Widget _buildDefaultBody(
    BuildContext context,
    GenerationNotifier notifier,
    GenerationState state,
    bool isCascadeMode,
    bool mobile,
    VisionTokens t,
  ) {
    return Stack(
      children: [
        Positioned.fill(
          bottom: mobile ? 140 : 115,
          child: ImagePreviewViewer(
            generatedImage: state.generatedImage,
            isLoading: state.isLoading,
            isDragging: state.isDragging,
            pulseAnimation: _pulseAnimation,
          ),
        ),

        const Positioned.fill(child: QuickActionOverlay()),

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
            child: _buildPromptArea(context, notifier, state, mobile, t),
          ),

        AdvancedSettingsPanel(
          onManageStyles: () {
            String? activeStyle;
            for (final name in notifier.state.activeStyleNames) {
              final style = notifier.state.styles.where((s) => s.name == name).firstOrNull;
              if (style != null && !style.isDefault) { activeStyle = name; break; }
            }
            activeStyle ??= notifier.state.activeStyleNames.isNotEmpty ? notifier.state.activeStyleNames.first : null;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ToolsHubScreen(initialToolId: 'styles', initialStyleName: activeStyle)),
            );
          },
          onEditStyle: (styleName) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ToolsHubScreen(initialToolId: 'styles', initialStyleName: styleName)),
            );
          },
          onSavePreset: () => _showSavePresetDialog(context, notifier),
        ),
      ],
    );
  }

  // — Sidebar body (widescreen layout) —
  Widget _buildSidebarBody(
    BuildContext context,
    GenerationNotifier notifier,
    GenerationState state,
    bool isCascadeMode,
    bool mobile,
    VisionTokens t,
    bool promptOnLeft,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthMode = context.watch<ThemeNotifier>().sidebarWidthMode;
    final double sidebarWidth;
    if (widthMode == 'compact') {
      sidebarWidth = (screenWidth * 0.28).clamp(300.0, 380.0);
    } else {
      sidebarWidth = (screenWidth * 0.38).clamp(420.0, 560.0);
    }

    return Row(
      children: [
        // Left sidebar
        SizedBox(
          width: sidebarWidth,
          child: Container(
            decoration: BoxDecoration(
              color: t.surfaceHigh,
              border: Border(right: BorderSide(color: t.borderStrong)),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ExpandedSettingsContent(
                    inSidebar: true,
                    onManageStyles: () {
                      String? activeStyle;
                      for (final name in notifier.state.activeStyleNames) {
                        final style = notifier.state.styles.where((s) => s.name == name).firstOrNull;
                        if (style != null && !style.isDefault) { activeStyle = name; break; }
                      }
                      activeStyle ??= notifier.state.activeStyleNames.isNotEmpty ? notifier.state.activeStyleNames.first : null;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ToolsHubScreen(initialToolId: 'styles', initialStyleName: activeStyle)),
                      );
                    },
                    onEditStyle: (styleName) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ToolsHubScreen(initialToolId: 'styles', initialStyleName: styleName)),
                      );
                    },
                    onSavePreset: () => _showSavePresetDialog(context, notifier),
                  ),
                ),
                if (promptOnLeft && !isCascadeMode)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    decoration: BoxDecoration(
                      color: t.surfaceHigh,
                      border: Border(top: BorderSide(color: t.borderMedium)),
                    ),
                    child: _buildPromptArea(context, notifier, state, mobile, t, useSidebarStyle: true),
                  ),
              ],
            ),
          ),
        ),

        // Right content area
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                bottom: (!promptOnLeft && !isCascadeMode) ? 115 : 0,
                child: ImagePreviewViewer(
                  generatedImage: state.generatedImage,
                  isLoading: state.isLoading,
                  isDragging: state.isDragging,
                  pulseAnimation: _pulseAnimation,
                ),
              ),

              const Positioned.fill(child: QuickActionOverlay()),

              // REF/VIBE rail on left edge of image area (next to sidebar)
              if (state.showDirectorRefShelf || state.showVibeTransferShelf)
                Positioned(
                  left: 8,
                  top: 8,
                  child: SidebarRefVibeRail(
                    showRef: state.showDirectorRefShelf,
                    showVibe: state.showVibeTransferShelf,
                  ),
                ),

              if (isCascadeMode)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.of(context).viewInsets.bottom > 0
                      ? MediaQuery.of(context).viewInsets.bottom
                      : 40.0 + MediaQuery.of(context).viewPadding.bottom,
                  child: const CascadePlaybackView(),
                ),

              if (!promptOnLeft && !isCascadeMode)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.of(context).viewInsets.bottom > 0
                      ? MediaQuery.of(context).viewInsets.bottom
                      : 40.0 + MediaQuery.of(context).viewPadding.bottom,
                  child: _buildPromptArea(context, notifier, state, mobile, t),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // — Shared prompt area widget —
  Widget _buildPromptArea(
    BuildContext context,
    GenerationNotifier notifier,
    GenerationState state,
    bool mobile,
    VisionTokens t, {
    bool useSidebarStyle = false,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: useSidebarStyle
          ? null
          : BoxDecoration(
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
          if (state.showDirectorRefShelf && !useSidebarStyle)
            const DirectorRefShelf(),
          if (state.showVibeTransferShelf && !useSidebarStyle)
            const VibeTransferShelf(),
          Selector<GenerationNotifier, String>(
            selector: (_, n) => n.state.characterEditorMode,
            builder: (context, mode, _) {
              if (mode == 'compact') return const CharacterShelf();
              return const SizedBox.shrink();
            },
          ),
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
                onTagSelected: (tag) {
                  _applyMainTagSuggestion(notifier, tag);
                  setState(() => _tagSuggestionIndex = -1);
                },
                selectedIndex: _tagSuggestionIndex,
              ),
            ),
          ),
          if (context.read<PreferencesService>().showSeedControl)
            _buildSeedRow(context, notifier, state, t),
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
                          setState(() => _tagSuggestionIndex = -1);
                        }
                      });
                    }
                  },
                  onKeyEvent: (node, event) {
                    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
                    final currentState = notifier.state;

                    // Ctrl+Enter → generate
                    if (event.logicalKey == LogicalKeyboardKey.enter &&
                        HardwareKeyboard.instance.isControlPressed) {
                      if (!currentState.isLoading) notifier.generate();
                      return KeyEventResult.handled;
                    }

                    // Alt+Left/Right → cycle style. (Was Ctrl+Shift+Arrow, but
                    // that collided with the OS word-by-word text-selection
                    // shortcut inside the prompt field — Alt+Arrow leaves native
                    // selection free.)
                    if (HardwareKeyboard.instance.isAltPressed &&
                        !HardwareKeyboard.instance.isControlPressed &&
                        (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                         event.logicalKey == LogicalKeyboardKey.arrowRight)) {
                      _cycleStyle(notifier, event.logicalKey == LogicalKeyboardKey.arrowRight);
                      return KeyEventResult.handled;
                    }

                    // Ctrl+Up/Down → adjust tag weight
                    if (HardwareKeyboard.instance.isControlPressed &&
                        (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                         event.logicalKey == LogicalKeyboardKey.arrowDown)) {
                      final up = event.logicalKey == LogicalKeyboardKey.arrowUp;
                      _adjustTagWeight(notifier.promptController, up ? 0.1 : -0.1);
                      return KeyEventResult.handled;
                    }

                    final suggestions = currentState.tagSuggestions;
                    if (suggestions.isEmpty) return KeyEventResult.ignored;

                    if (event.logicalKey == LogicalKeyboardKey.tab) {
                      if (HardwareKeyboard.instance.isShiftPressed) {
                        setState(() {
                          _tagSuggestionIndex = (_tagSuggestionIndex - 1)
                              .clamp(-1, suggestions.length - 1);
                        });
                      } else {
                        setState(() {
                          _tagSuggestionIndex = (_tagSuggestionIndex + 1) % suggestions.length;
                        });
                      }
                      return KeyEventResult.handled;
                    }
                    if (event.logicalKey == LogicalKeyboardKey.enter &&
                        _tagSuggestionIndex >= 0 &&
                        _tagSuggestionIndex < suggestions.length) {
                      _applyMainTagSuggestion(notifier, suggestions[_tagSuggestionIndex]);
                      setState(() => _tagSuggestionIndex = -1);
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.stylus,
                      },
                    ),
                    child: TextField(
                    controller: notifier.promptController,
                    maxLines: useSidebarStyle ? 5 : (mobile ? t.promptMaxLines + 2 : t.promptMaxLines + 1),
                    onChanged: (val) {
                      notifier.handleTagSuggestions(val, notifier.promptController.selection);
                      setState(() => _tagSuggestionIndex = -1);
                    },
                    onTapOutside: (_) {
                      Future.delayed(const Duration(milliseconds: 200), () {
                        if (!_isTouchingSuggestions) {
                          notifier.clearTagSuggestions();
                        }
                      });
                    },
                    onSubmitted: (_) {
                      if (state.tagSuggestions.isNotEmpty) {
                        _applyMainTagSuggestion(notifier, state.tagSuggestions.first);
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
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: mobile ? 64 : 58,
                width: mobile ? 64 : 58,
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : () {
                    FocusScope.of(context).unfocus();
                    notifier.generate();
                  },
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
    );
  }

  Widget _buildSeedRow(BuildContext context, GenerationNotifier notifier, GenerationState state, VisionTokens t) {
    final isRandom = state.randomizeSeed;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.casino, size: 12, color: isRandom ? t.accent : t.textDisabled),
          const SizedBox(width: 6),
          if (isRandom)
            Text('RANDOM', style: TextStyle(fontSize: t.fontSize(8), letterSpacing: 1, color: t.accent, fontWeight: FontWeight.bold))
          else
            Expanded(
              child: SizedBox(
                height: 24,
                child: TextField(
                  controller: notifier.seedController,
                  style: TextStyle(fontSize: t.fontSize(9), color: t.textSecondary, letterSpacing: 1),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: t.borderSubtle)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: t.borderSubtle)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: t.accent)),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ),
          if (!isRandom) const SizedBox(width: 6),
          InkWell(
            onTap: () => notifier.updateSettings(randomizeSeed: !isRandom),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                isRandom ? Icons.lock_open : Icons.shuffle,
                size: 14,
                color: t.textDisabled,
              ),
            ),
          ),
        ],
      ),
    );
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
