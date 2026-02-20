import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/l10n/locale_notifier.dart';
import '../../../core/services/path_service.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/services/update_service.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/pin_lock_gate.dart';
import '../../gallery/providers/gallery_notifier.dart';
import '../../generation/providers/generation_notifier.dart';
import '../tools_hub_screen.dart';
import 'demo_image_picker.dart';

class AppSettings extends StatefulWidget {
  const AppSettings({super.key});

  @override
  State<AppSettings> createState() => _AppSettingsState();
}

class _AppSettingsState extends State<AppSettings> {
  late TextEditingController _apiKeyController;
  bool _isObscured = true;
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = context.read<PreferencesService>();
    final key = await prefs.getApiKey();
    if (mounted) {
      _apiKeyController.text = key;
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<GenerationNotifier>();
    final state = notifier.state;
    final t = context.t;
    final l = context.l;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(l.settingsApiSettings.toUpperCase(), t),
          const SizedBox(height: 16),
          _buildApiKeyField(notifier, t),
          const SizedBox(height: 32),
          _buildHeader(l.settingsGeneralSettings.toUpperCase(), t),
          const SizedBox(height: 16),
          _buildAutoSaveToggle(notifier, state.autoSaveImages, t),
          if (isDesktopPlatform()) ...[
            const SizedBox(height: 12),
            _buildOutputFolderRow(t),
          ],
          const SizedBox(height: 12),
          _buildSmartStyleImportToggle(t),
          const SizedBox(height: 12),
          _buildRememberSessionToggle(t),
          const SizedBox(height: 12),
          _buildImg2ImgImportPromptToggle(t),
          const SizedBox(height: 12),
          _buildDefaultSaveAlbumDropdown(t),
          const SizedBox(height: 12),
          _buildLanguageDropdown(t),
          const SizedBox(height: 32),
          _buildHeader(l.settingsUiSettings.toUpperCase(), t),
          const SizedBox(height: 16),
          _buildAnlasTrackerToggle(t),
          const SizedBox(height: 12),
          _buildShelfToggle(
            label: l.settingsEditButton.toUpperCase(),
            description: l.settingsEditButtonDesc,
            value: state.showEditButton,
            onChanged: (_) => notifier.toggleShowEditButton(),
            t: t,
          ),
          const SizedBox(height: 12),
          _buildShelfToggle(
            label: l.settingsDirectorRefShelf.toUpperCase(),
            description: l.settingsDirectorRefShelfDesc,
            value: state.showDirectorRefShelf,
            onChanged: (_) => notifier.toggleDirectorRefShelf(),
            t: t,
          ),
          const SizedBox(height: 12),
          _buildShelfToggle(
            label: l.settingsVibeTransferShelf.toUpperCase(),
            description: l.settingsVibeTransferShelfDesc,
            value: state.showVibeTransferShelf,
            onChanged: (_) => notifier.toggleVibeTransferShelf(),
            t: t,
          ),
          const SizedBox(height: 12),
          _buildCharEditorModeToggle(notifier, state, t),
          const SizedBox(height: 12),
          _buildThemeBuilderButton(t),
          const SizedBox(height: 32),
          _buildHeader(l.settingsExport.toUpperCase(), t),
          const SizedBox(height: 16),
          _buildStripMetadataToggle(t),
          const SizedBox(height: 32),
          _buildHeader(l.settingsSecurity.toUpperCase(), t),
          const SizedBox(height: 16),
          _buildPinLockSection(t),
          const SizedBox(height: 32),
          _buildHeader(l.settingsDemoMode.toUpperCase(), t),
          const SizedBox(height: 16),
          _buildDemoModeSection(t),
          const SizedBox(height: 32),
          _buildHeader(l.settingsLinks.toUpperCase(), t),
          const SizedBox(height: 16),
          _buildGithubButton(t),
          if (!kIsWeb) ...[
            const SizedBox(height: 12),
            _buildUpdateCheckButton(t),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(String title, dynamic t) {
    return Text(
      title,
      style: TextStyle(
        color: t.secondaryText,
        fontSize: t.fontSize(10),
        letterSpacing: 2,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildApiKeyField(GenerationNotifier notifier, dynamic t) {
    final l = context.l;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.settingsApiKeyLabel.toUpperCase(),
          style: TextStyle(color: t.textTertiary, fontSize: t.fontSize(9), letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _apiKeyController,
          obscureText: _isObscured,
          style: TextStyle(color: t.headerText, fontSize: t.fontSize(12), fontFamily: 'monospace'),
          decoration: InputDecoration(
            filled: true,
            fillColor: t.borderSubtle,
            hintText: l.settingsApiKeyHint,
            hintStyle: TextStyle(color: t.textDisabled),
            suffixIcon: IconButton(
              icon: Icon(
                _isObscured ? Icons.visibility_off : Icons.visibility,
                size: 16,
                color: t.textDisabled,
              ),
              onPressed: () => setState(() => _isObscured = !_isObscured),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: t.borderMedium),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: t.borderMedium),
            ),
          ),
          onChanged: (val) => notifier.updateApiKey(val),
        ),
      ],
    );
  }

  Widget _buildAutoSaveToggle(GenerationNotifier notifier, bool value, dynamic t) {
    final l = context.l;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.settingsAutoSave.toUpperCase(),
                style: TextStyle(color: t.headerText, fontSize: t.fontSize(11), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                l.settingsAutoSaveDesc,
                style: TextStyle(color: t.textTertiary, fontSize: t.fontSize(9)),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: (val) => notifier.toggleAutoSave(val),
          activeThumbColor: t.accent,
          activeTrackColor: t.borderStrong,
          inactiveThumbColor: t.textDisabled,
          inactiveTrackColor: t.borderSubtle,
        ),
      ],
    );
  }

  Widget _buildOutputFolderRow(dynamic t) {
    final prefs = context.read<PreferencesService>();
    final l = context.l;
    return StatefulBuilder(
      builder: (context, setLocalState) {
        final customDir = prefs.customOutputDir;
        final hasCustom = customDir.isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.settingsOutputFolder.toUpperCase(),
              style: TextStyle(color: t.headerText, fontSize: t.fontSize(11), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              l.settingsOutputFolderDesc,
              style: TextStyle(color: t.textTertiary, fontSize: t.fontSize(9)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: t.borderMedium),
                      borderRadius: BorderRadius.circular(4),
                      color: t.borderSubtle,
                    ),
                    child: Text(
                      hasCustom ? customDir : l.settingsOutputFolderDefault,
                      style: TextStyle(
                        color: hasCustom ? t.headerText : t.textDisabled,
                        fontSize: t.fontSize(10),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () async {
                    final dir = await FilePicker.platform.getDirectoryPath();
                    if (dir != null && context.mounted) {
                      await prefs.setCustomOutputDir(dir);
                      if (!context.mounted) return;
                      final paths = context.read<PathService>();
                      paths.outputDirOverride = dir;
                      await paths.ensureDirectories();
                      if (!context.mounted) return;
                      context.read<GalleryNotifier>().setOutputDir(dir);
                      context.read<GenerationNotifier>().setOutputDir(dir);
                      setLocalState(() {});
                    }
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: t.borderMedium),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      l.settingsOutputFolderBrowse.toUpperCase(),
                      style: TextStyle(
                        color: t.secondaryText,
                        fontSize: t.fontSize(9),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                if (hasCustom) ...[
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () async {
                      await prefs.setCustomOutputDir('');
                      if (!context.mounted) return;
                      final paths = context.read<PathService>();
                      paths.outputDirOverride = null;
                      final defaultDir = paths.outputDir;
                      context.read<GalleryNotifier>().setOutputDir(defaultDir);
                      context.read<GenerationNotifier>().setOutputDir(defaultDir);
                      setLocalState(() {});
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: t.borderMedium),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(Icons.close, size: 14, color: t.textDisabled),
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStripMetadataToggle(dynamic t) {
    final prefs = context.read<PreferencesService>();
    final l = context.l;
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.settingsStripMetadata.toUpperCase(),
                    style: TextStyle(color: t.headerText, fontSize: t.fontSize(11), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.settingsStripMetadataDesc,
                    style: TextStyle(color: t.textTertiary, fontSize: t.fontSize(9)),
                  ),
                ],
              ),
            ),
            Switch(
              value: prefs.stripMetadataOnExport,
              onChanged: (val) async {
                await prefs.setStripMetadataOnExport(val);
                setLocalState(() {});
              },
              activeThumbColor: t.accent,
              activeTrackColor: t.borderStrong,
              inactiveThumbColor: t.textDisabled,
              inactiveTrackColor: t.borderSubtle,
            ),
          ],
        );
      },
    );
  }

  Widget _buildShelfToggle({
    required String label,
    required String description,
    required bool value,
    required Function(bool) onChanged,
    required dynamic t,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: t.headerText, fontSize: t.fontSize(11), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(color: t.textTertiary, fontSize: t.fontSize(9)),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: t.accent,
          activeTrackColor: t.borderStrong,
          inactiveThumbColor: t.textDisabled,
          inactiveTrackColor: t.borderSubtle,
        ),
      ],
    );
  }

  Widget _buildAnlasTrackerToggle(dynamic t) {
    final prefs = context.read<PreferencesService>();
    final l = context.l;
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.settingsAnlasTracker.toUpperCase(),
                    style: TextStyle(color: t.headerText, fontSize: t.fontSize(11), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.settingsAnlasTrackerDesc,
                    style: TextStyle(color: t.textTertiary, fontSize: t.fontSize(9)),
                  ),
                ],
              ),
            ),
            Switch(
              value: prefs.showAnlasTracker,
              onChanged: (val) async {
                await prefs.setShowAnlasTracker(val);
                setLocalState(() {});
              },
              activeThumbColor: t.accent,
              activeTrackColor: t.borderStrong,
              inactiveThumbColor: t.textDisabled,
              inactiveTrackColor: t.borderSubtle,
            ),
          ],
        );
      },
    );
  }

  Widget _buildCharEditorModeToggle(GenerationNotifier notifier, GenerationState state, dynamic t) {
    final l = context.l;
    return _buildShelfToggle(
      label: l.settingsCharEditorMode.toUpperCase(),
      description: l.settingsCharEditorModeDesc,
      value: state.characterEditorMode == 'expanded',
      onChanged: (_) {
        final newMode = state.characterEditorMode == 'expanded' ? 'compact' : 'expanded';
        notifier.setCharacterEditorMode(newMode);
      },
      t: t,
    );
  }

  Widget _buildSmartStyleImportToggle(dynamic t) {
    final prefs = context.read<PreferencesService>();
    final l = context.l;
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.settingsSmartStyleImport.toUpperCase(),
                    style: TextStyle(color: t.headerText, fontSize: t.fontSize(11), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.settingsSmartStyleImportDesc,
                    style: TextStyle(color: t.textTertiary, fontSize: t.fontSize(9)),
                  ),
                ],
              ),
            ),
            Switch(
              value: prefs.smartStyleImport,
              onChanged: (val) async {
                await prefs.setSmartStyleImport(val);
                setLocalState(() {});
              },
              activeThumbColor: t.accent,
              activeTrackColor: t.borderStrong,
              inactiveThumbColor: t.textDisabled,
              inactiveTrackColor: t.borderSubtle,
            ),
          ],
        );
      },
    );
  }

  Widget _buildRememberSessionToggle(dynamic t) {
    final prefs = context.read<PreferencesService>();
    final l = context.l;
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.settingsRememberSession.toUpperCase(),
                    style: TextStyle(color: t.headerText, fontSize: t.fontSize(11), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.settingsRememberSessionDesc,
                    style: TextStyle(color: t.textTertiary, fontSize: t.fontSize(9)),
                  ),
                ],
              ),
            ),
            Switch(
              value: prefs.rememberSession,
              onChanged: (val) async {
                final gen = context.read<GenerationNotifier>();
                await prefs.setRememberSession(val);
                if (!val) {
                  gen.deleteSessionSnapshot();
                }
                setLocalState(() {});
              },
              activeThumbColor: t.accent,
              activeTrackColor: t.borderStrong,
              inactiveThumbColor: t.textDisabled,
              inactiveTrackColor: t.borderSubtle,
            ),
          ],
        );
      },
    );
  }

  Widget _buildImg2ImgImportPromptToggle(dynamic t) {
    final prefs = context.read<PreferencesService>();
    final l = context.l;
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.settingsImg2ImgImportPrompt.toUpperCase(),
                    style: TextStyle(color: t.headerText, fontSize: t.fontSize(11), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.settingsImg2ImgImportPromptDesc,
                    style: TextStyle(color: t.textTertiary, fontSize: t.fontSize(9)),
                  ),
                ],
              ),
            ),
            Switch(
              value: prefs.img2imgImportPrompt,
              onChanged: (val) async {
                await prefs.setImg2ImgImportPrompt(val);
                setLocalState(() {});
              },
              activeThumbColor: t.accent,
              activeTrackColor: t.borderStrong,
              inactiveThumbColor: t.textDisabled,
              inactiveTrackColor: t.borderSubtle,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDefaultSaveAlbumDropdown(dynamic t) {
    final prefs = context.read<PreferencesService>();
    final gallery = context.watch<GalleryNotifier>();
    final l = context.l;
    return StatefulBuilder(
      builder: (context, setLocalState) {
        final currentId = prefs.defaultSaveAlbumId;
        final albums = gallery.albums;
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.settingsSaveToAlbum.toUpperCase(),
                    style: TextStyle(color: t.headerText, fontSize: t.fontSize(11), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.settingsSaveToAlbumDesc,
                    style: TextStyle(color: t.textTertiary, fontSize: t.fontSize(9)),
                  ),
                ],
              ),
            ),
            DropdownButton<String>(
              value: currentId != null && albums.any((a) => a.id == currentId) ? currentId : null,
              hint: Text(l.commonNone.toUpperCase(), style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(10))),
              dropdownColor: t.surfaceHigh,
              underline: const SizedBox.shrink(),
              style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(10), letterSpacing: 1),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(l.commonNone.toUpperCase(), style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(10))),
                ),
                for (final album in albums)
                  DropdownMenuItem<String>(
                    value: album.id,
                    child: Text(album.name.toUpperCase(), style: TextStyle(fontSize: t.fontSize(10))),
                  ),
              ],
              onChanged: (val) async {
                await prefs.setDefaultSaveAlbumId(val);
                setLocalState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageDropdown(dynamic t) {
    final localeNotifier = context.watch<LocaleNotifier>();
    final l = context.l;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.settingsLanguage.toUpperCase(),
                style: TextStyle(color: t.headerText, fontSize: t.fontSize(11), fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        DropdownButton<Locale>(
          value: localeNotifier.locale,
          dropdownColor: t.surfaceHigh,
          underline: const SizedBox.shrink(),
          style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(10), letterSpacing: 1),
          items: const [
            DropdownMenuItem(
              value: Locale('en'),
              child: Text('ENGLISH'),
            ),
            DropdownMenuItem(
              value: Locale('ja'),
              child: Text('日本語'),
            ),
          ],
          onChanged: (locale) {
            if (locale != null) {
              localeNotifier.setLocale(locale);
            }
          },
        ),
      ],
    );
  }

  Widget _buildThemeBuilderButton(dynamic t) {
    final l = context.l;
    return InkWell(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ToolsHubScreen(initialToolId: 'theme')),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: t.borderMedium),
          borderRadius: BorderRadius.circular(4),
          color: t.borderSubtle,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.palette, color: t.secondaryText, size: 16),
            const SizedBox(width: 12),
            Text(
              l.settingsThemeBuilder.toUpperCase(),
              style: TextStyle(
                color: t.secondaryText,
                fontSize: t.fontSize(10),
                letterSpacing: 1,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinLockSection(dynamic t) {
    final prefs = context.read<PreferencesService>();
    final l = context.l;
    return StatefulBuilder(
      builder: (context, setSectionState) {
        final pinEnabled = prefs.pinEnabled;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShelfToggle(
              label: l.settingsPinLock.toUpperCase(),
              description: l.settingsPinLockDesc,
              value: pinEnabled,
              onChanged: (_) async {
                if (!pinEnabled) {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => _SetPinDialog(t: t),
                  );
                  if (result == true) {
                    setSectionState(() {});
                  }
                } else {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => _VerifyPinDialog(prefs: prefs, t: t),
                  );
                  if (result == true) {
                    await prefs.setPinEnabled(false);
                    await prefs.setPinHash('');
                    await prefs.setPinSalt('');
                    await prefs.setPinLockOnResume(false);
                    await prefs.setPinBiometricEnabled(false);
                    setSectionState(() {});
                  }
                }
              },
              t: t,
            ),
            if (pinEnabled) ...[
              const SizedBox(height: 12),
              _buildShelfToggle(
                label: l.settingsLockOnResume.toUpperCase(),
                description: l.settingsLockOnResumeDesc,
                value: prefs.pinLockOnResume,
                onChanged: (_) async {
                  await prefs.setPinLockOnResume(!prefs.pinLockOnResume);
                  setSectionState(() {});
                },
                t: t,
              ),
              const SizedBox(height: 12),
              _buildShelfToggle(
                label: l.settingsBiometricUnlock.toUpperCase(),
                description: l.settingsBiometricUnlockDesc,
                value: prefs.pinBiometricEnabled,
                onChanged: (_) async {
                  if (!prefs.pinBiometricEnabled) {
                    final auth = LocalAuthentication();
                    final canCheck = await auth.canCheckBiometrics || await auth.isDeviceSupported();
                    if (!canCheck) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l.settingsBiometricsUnavailable,
                              style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(11)),
                            ),
                            backgroundColor: t.surfaceHigh,
                          ),
                        );
                      }
                      return;
                    }
                  }
                  await prefs.setPinBiometricEnabled(!prefs.pinBiometricEnabled);
                  setSectionState(() {});
                },
                t: t,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDemoModeSection(dynamic t) {
    final gallery = context.watch<GalleryNotifier>();
    final prefs = context.read<PreferencesService>();
    final l = context.l;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildShelfToggle(
                label: l.settingsDemoMode.toUpperCase(),
                description: l.settingsDemoModeDesc,
                value: gallery.demoMode,
                onChanged: (_) {
                  gallery.demoMode = !gallery.demoMode;
                },
                t: t,
              ),
            ),
            IconButton(
              icon: Icon(Icons.settings, size: 18, color: t.textDisabled),
              onPressed: () => _showDemoPrefixSettings(prefs, t),
              tooltip: l.settingsEditPositivePrefix,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
              splashRadius: 18,
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DemoImagePicker()),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: t.borderMedium),
              borderRadius: BorderRadius.circular(4),
              color: t.borderSubtle,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.photo_library, color: t.secondaryText, size: 16),
                const SizedBox(width: 12),
                Text(
                  l.settingsSelectDemoImages.toUpperCase(),
                  style: TextStyle(
                    color: t.secondaryText,
                    fontSize: t.fontSize(10),
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${gallery.demoSafeCount})',
                  style: TextStyle(
                    color: t.textDisabled,
                    fontSize: t.fontSize(9),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l.settingsTagSuggestionsHidden,
          style: TextStyle(color: t.textTertiary, fontSize: t.fontSize(9), fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Future<void> _showDemoPrefixSettings(PreferencesService prefs, dynamic t) async {
    final posCtrl = TextEditingController(text: prefs.demoPositivePrefix);
    final negCtrl = TextEditingController(text: prefs.demoNegativePrefix);
    final l = context.l;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surfaceHigh,
        title: Text(
          l.settingsDemoPrefixes.toUpperCase(),
          style: TextStyle(
            fontSize: t.fontSize(10),
            letterSpacing: 2,
            color: t.textSecondary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.settingsPositivePrefix.toUpperCase(),
              style: TextStyle(color: t.textTertiary, fontSize: t.fontSize(9), letterSpacing: 1),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: posCtrl,
              autofocus: true,
              style: TextStyle(color: t.headerText, fontSize: t.fontSize(11)),
              decoration: InputDecoration(
                filled: true,
                fillColor: t.borderSubtle,
                hintStyle: TextStyle(color: t.textDisabled),
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
            const SizedBox(height: 16),
            Text(
              l.settingsNegativePrefix.toUpperCase(),
              style: TextStyle(color: t.textTertiary, fontSize: t.fontSize(9), letterSpacing: 1),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: negCtrl,
              style: TextStyle(color: t.headerText, fontSize: t.fontSize(11)),
              decoration: InputDecoration(
                filled: true,
                fillColor: t.borderSubtle,
                hintStyle: TextStyle(color: t.textDisabled),
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.l.commonCancel.toUpperCase(), style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l.commonSave.toUpperCase(), style: TextStyle(color: t.accent, fontSize: t.fontSize(9))),
          ),
        ],
      ),
    );

    if (saved == true) {
      await prefs.setDemoPositivePrefix(posCtrl.text);
      await prefs.setDemoNegativePrefix(negCtrl.text);
      setState(() {});
    }
    posCtrl.dispose();
    negCtrl.dispose();
  }

  Widget _buildGithubButton(dynamic t) {
    final l = context.l;
    return InkWell(
      onTap: () {
        launchUrl(Uri.parse('https://github.com/ststoryweaver/NAIWeaver'));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: t.borderMedium),
          borderRadius: BorderRadius.circular(4),
          color: t.borderSubtle,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.code, color: t.secondaryText, size: 16),
            const SizedBox(width: 12),
            Text(
              l.settingsGithubRepository.toUpperCase(),
              style: TextStyle(
                color: t.secondaryText,
                fontSize: t.fontSize(10),
                letterSpacing: 1,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildUpdateCheckButton(dynamic t) {
    final l = context.l;
    return InkWell(
      onTap: _isCheckingUpdate
          ? null
          : () async {
              setState(() => _isCheckingUpdate = true);
              try {
                final packageInfo = await PackageInfo.fromPlatform();
                final result =
                    await UpdateService.checkForUpdate(packageInfo.version);

                if (!mounted) return;

                if (result.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l.settingsUpdateCheckFailed,
                        style: TextStyle(
                            color: t.textPrimary, fontSize: t.fontSize(11)),
                      ),
                      backgroundColor: t.surfaceHigh,
                    ),
                  );
                } else if (result.updateAvailable) {
                  _showUpdateDialog(
                      t, result.latestVersion!, result.releaseUrl!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l.settingsUpToDate,
                        style: TextStyle(
                            color: t.textPrimary, fontSize: t.fontSize(11)),
                      ),
                      backgroundColor: t.surfaceHigh,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isCheckingUpdate = false);
              }
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: t.borderMedium),
          borderRadius: BorderRadius.circular(4),
          color: t.borderSubtle,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isCheckingUpdate)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: t.secondaryText,
                ),
              )
            else
              Icon(Icons.system_update, color: t.secondaryText, size: 16),
            const SizedBox(width: 12),
            Text(
              l.settingsCheckForUpdates.toUpperCase(),
              style: TextStyle(
                color: t.secondaryText,
                fontSize: t.fontSize(10),
                letterSpacing: 1,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateDialog(dynamic t, String version, String releaseUrl) {
    final l = context.l;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surfaceHigh,
        title: Text(
          l.settingsUpdateAvailable.toUpperCase(),
          style: TextStyle(
            fontSize: t.fontSize(10),
            letterSpacing: 2,
            color: t.textSecondary,
          ),
        ),
        content: Text(
          l.settingsUpdateAvailableDesc(version),
          style: TextStyle(
            color: t.textPrimary,
            fontSize: t.fontSize(11),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l.commonClose.toUpperCase(),
              style: TextStyle(
                  color: t.textDisabled, fontSize: t.fontSize(9)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              launchUrl(Uri.parse(releaseUrl));
            },
            child: Text(
              l.settingsUpdateDownload.toUpperCase(),
              style:
                  TextStyle(color: t.accent, fontSize: t.fontSize(9)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetPinDialog extends StatefulWidget {
  final dynamic t;
  const _SetPinDialog({required this.t});

  @override
  State<_SetPinDialog> createState() => _SetPinDialogState();
}

class _SetPinDialogState extends State<_SetPinDialog> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final l = context.l;
    return AlertDialog(
      backgroundColor: t.surfaceHigh,
      title: Text(l.settingsSetPin.toUpperCase(), style: TextStyle(fontSize: t.fontSize(10), letterSpacing: 2, color: t.textSecondary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pinController,
            obscureText: true,
            maxLength: 8,
            keyboardType: TextInputType.number,
            style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(16), letterSpacing: 8),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: l.settingsPinDigitsHint,
              hintStyle: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9), letterSpacing: 2),
              counterText: '',
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.borderMedium)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmController,
            obscureText: true,
            maxLength: 8,
            keyboardType: TextInputType.number,
            style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(16), letterSpacing: 8),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: l.commonConfirm.toUpperCase(),
              hintStyle: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9), letterSpacing: 2),
              counterText: '',
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.borderMedium)),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: t.accentDanger, fontSize: t.fontSize(9))),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.commonCancel.toUpperCase(), style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9))),
        ),
        TextButton(
          onPressed: () async {
            final pin = _pinController.text;
            final confirm = _confirmController.text;
            if (pin.length < 4 || pin.length > 8 || !RegExp(r'^\d{4,8}$').hasMatch(pin)) {
              setState(() => _error = l.settingsPinMustBeDigits);
              return;
            }
            if (pin != confirm) {
              setState(() => _error = l.settingsPinsDoNotMatch);
              return;
            }
            final prefs = context.read<PreferencesService>();
            final salt = generateSalt();
            final hash = hashPinPbkdf2(salt, pin);
            await prefs.setPinSalt(salt);
            await prefs.setPinHash(hash);
            await prefs.setPinHashVersion(2);
            await prefs.setPinEnabled(true);
            if (context.mounted) Navigator.pop(context, true);
          },
          child: Text(l.commonSet.toUpperCase(), style: TextStyle(color: t.accent, fontSize: t.fontSize(9))),
        ),
      ],
    );
  }
}

class _VerifyPinDialog extends StatefulWidget {
  final PreferencesService prefs;
  final dynamic t;
  const _VerifyPinDialog({required this.prefs, required this.t});

  @override
  State<_VerifyPinDialog> createState() => _VerifyPinDialogState();
}

class _VerifyPinDialogState extends State<_VerifyPinDialog> {
  final _pinController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final l = context.l;
    return AlertDialog(
      backgroundColor: t.surfaceHigh,
      title: Text(l.settingsEnterCurrentPin.toUpperCase(), style: TextStyle(fontSize: t.fontSize(10), letterSpacing: 2, color: t.textSecondary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pinController,
            obscureText: true,
            maxLength: 8,
            keyboardType: TextInputType.number,
            style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(16), letterSpacing: 8),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: l.settingsEnterPinHint.toUpperCase(),
              hintStyle: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9), letterSpacing: 2),
              counterText: '',
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.borderMedium)),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: t.accentDanger, fontSize: t.fontSize(9))),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.commonCancel.toUpperCase(), style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9))),
        ),
        TextButton(
          onPressed: () {
            final pin = _pinController.text;
            final expectedHash = widget.prefs.pinHash;
            final salt = widget.prefs.pinSalt;
            final enteredHash = verifyPinHash(salt, pin, widget.prefs.pinHashVersion);
            if (enteredHash == expectedHash) {
              Navigator.pop(context, true);
            } else {
              setState(() => _error = l.settingsIncorrectPin);
            }
          },
          child: Text(l.commonConfirm.toUpperCase(), style: TextStyle(color: t.accentDanger, fontSize: t.fontSize(9))),
        ),
      ],
    );
  }
}
