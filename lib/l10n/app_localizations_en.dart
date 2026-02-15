// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSave => 'Save';

  @override
  String get commonClose => 'Close';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonRename => 'Rename';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonSet => 'Set';

  @override
  String get commonNone => 'None';

  @override
  String get commonExport => 'Export';

  @override
  String get commonOverwrite => 'OVERWRITE';

  @override
  String get commonSaveChanges => 'SAVE CHANGES';

  @override
  String get mainGallery => 'Gallery';

  @override
  String get mainTools => 'Tools';

  @override
  String get mainSave => 'Save';

  @override
  String get mainEdit => 'Edit';

  @override
  String get mainEnterPrompt => 'Enter Prompt';

  @override
  String get mainHelp => 'Help';

  @override
  String get mainAuthError => 'Authentication error: please check API settings';

  @override
  String get mainSettings => 'Settings';

  @override
  String mainImportFailed(String error) {
    return 'Failed to import settings: $error';
  }

  @override
  String get mainSavePreset => 'Save Preset';

  @override
  String get mainPresetName => 'Preset Name';

  @override
  String get mainAdvancedSettings => 'Advanced Settings';

  @override
  String get settingsApiSettings => 'API Settings';

  @override
  String get settingsGeneralSettings => 'General Settings';

  @override
  String get settingsUiSettings => 'UI Settings';

  @override
  String get settingsExport => 'Export';

  @override
  String get settingsSecurity => 'Security';

  @override
  String get settingsDemoMode => 'Demo Mode';

  @override
  String get settingsLinks => 'Links';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsApiKeyLabel => 'NovelAI API Key';

  @override
  String get settingsApiKeyHint => 'pst-xxxx...';

  @override
  String get settingsAutoSave => 'Auto-Save Images';

  @override
  String get settingsAutoSaveDesc =>
      'Automatically save all generated images to the output folder';

  @override
  String get settingsSmartStyleImport => 'Smart Style Import';

  @override
  String get settingsSmartStyleImportDesc =>
      'Strip style tags from imported prompts and restore style selections instead';

  @override
  String get settingsRememberSession => 'Remember Session';

  @override
  String get settingsRememberSessionDesc =>
      'Auto-save your prompt, settings, and references for crash recovery';

  @override
  String get settingsSaveToAlbum => 'Save to Album';

  @override
  String get settingsSaveToAlbumDesc =>
      'Auto-add new generations to this album';

  @override
  String get settingsEditButton => 'Edit Button';

  @override
  String get settingsEditButtonDesc =>
      'Show the edit/inpainting button on the image viewer';

  @override
  String get settingsDirectorRefShelf => 'Director Reference Shelf';

  @override
  String get settingsDirectorRefShelfDesc =>
      'Show the reference image shelf on the main screen';

  @override
  String get settingsVibeTransferShelf => 'Vibe Transfer Shelf';

  @override
  String get settingsVibeTransferShelfDesc =>
      'Show the vibe transfer shelf on the main screen';

  @override
  String get settingsThemeBuilder => 'Theme Builder';

  @override
  String get settingsStripMetadata => 'Strip Metadata on Export';

  @override
  String get settingsStripMetadataDesc =>
      'Remove generation data (prompt, settings) from exported images';

  @override
  String get settingsPinLock => 'PIN Lock';

  @override
  String get settingsPinLockDesc =>
      'Require a PIN (4-8 digits) to open the app';

  @override
  String get settingsLockOnResume => 'Lock on Resume';

  @override
  String get settingsLockOnResumeDesc =>
      'Re-lock app when returning from background';

  @override
  String get settingsBiometricUnlock => 'Biometric Unlock';

  @override
  String get settingsBiometricUnlockDesc => 'Use fingerprint or face unlock';

  @override
  String get settingsBiometricsUnavailable =>
      'Biometrics not available on this device';

  @override
  String get settingsSetPin => 'Set PIN';

  @override
  String get settingsPinDigitsHint => '4-8 digits';

  @override
  String get settingsPinMustBeDigits => 'PIN must be 4-8 digits';

  @override
  String get settingsPinsDoNotMatch => 'PINs do not match';

  @override
  String get settingsEnterCurrentPin => 'Enter Current PIN';

  @override
  String get settingsEnterPinHint => 'Enter PIN';

  @override
  String get settingsIncorrectPin => 'Incorrect PIN';

  @override
  String get settingsDemoModeDesc =>
      'Only show demo-safe images in the gallery';

  @override
  String get settingsSelectDemoImages => 'Select Demo Images';

  @override
  String get settingsTagSuggestionsHidden =>
      'Tag suggestions are hidden while demo mode is active';

  @override
  String get settingsPositivePrefix => 'Positive Prefix';

  @override
  String get settingsNegativePrefix => 'Negative Prefix';

  @override
  String get settingsEditPositivePrefix => 'Edit Positive Prefix';

  @override
  String get settingsEditNegativePrefix => 'Edit Negative Prefix';

  @override
  String get settingsDemoPrefixes => 'Demo Prefixes';

  @override
  String get settingsNotSet => '(not set)';

  @override
  String get settingsGithubRepository => 'GitHub Repository';

  @override
  String get settingsGithubPlaceholder => 'GitHub link placeholder';

  @override
  String get galleryTitle => 'Gallery';

  @override
  String get galleryDemoTitle => 'Gallery (Demo)';

  @override
  String get gallerySearchTags => 'Search Tags...';

  @override
  String gallerySelectedCount(int count) {
    return '$count Selected';
  }

  @override
  String get galleryDeselectAll => 'Deselect all';

  @override
  String get gallerySelectAll => 'Select all';

  @override
  String get galleryFavoritesFilter => 'Favorites filter';

  @override
  String get gallerySort => 'Sort';

  @override
  String get gallerySelectMode => 'Select mode';

  @override
  String galleryColumnsCount(int count) {
    return '$count columns';
  }

  @override
  String get gallerySortDateNewest => 'Date (Newest)';

  @override
  String get gallerySortDateOldest => 'Date (Oldest)';

  @override
  String get gallerySortNameAZ => 'Name (A-Z)';

  @override
  String get gallerySortNameZA => 'Name (Z-A)';

  @override
  String get gallerySortSizeLargest => 'Size (Largest)';

  @override
  String get gallerySortSizeSmallest => 'Size (Smallest)';

  @override
  String get galleryNoDemoImages => 'No demo images selected';

  @override
  String get galleryNoFavorites => 'No Favorites';

  @override
  String get galleryNoImagesInAlbum => 'No Images in Album';

  @override
  String get galleryNoImagesFound => 'No Images Found';

  @override
  String get galleryAll => 'All';

  @override
  String galleryCopiedCount(int count) {
    return '$count Copied';
  }

  @override
  String galleryImagesCopiedCount(int count) {
    return '$count Images Copied';
  }

  @override
  String galleryPasteInto(String name) {
    return 'Paste Into $name';
  }

  @override
  String galleryPastedIntoAlbum(int count, String name) {
    return '$count images pasted into $name';
  }

  @override
  String get galleryClearClipboard => 'Clear Clipboard';

  @override
  String get galleryNewAlbum => 'New Album';

  @override
  String get galleryAlbumName => 'Album Name';

  @override
  String get galleryRenameAlbum => 'Rename Album';

  @override
  String get galleryAddToAlbum => 'Add to Album';

  @override
  String galleryDeleteCount(int count) {
    return 'Delete $count images?';
  }

  @override
  String get galleryCannotUndo => 'This cannot be undone.';

  @override
  String get galleryCompare => 'Compare';

  @override
  String get galleryCopy => 'Copy';

  @override
  String get galleryPaste => 'Paste';

  @override
  String get galleryAlbum => 'Album';

  @override
  String get galleryFavorite => 'Favorite';

  @override
  String gallerySavedToDeviceCount(int saved, int total) {
    return 'Saved $saved/$total to device gallery';
  }

  @override
  String galleryExportDialogTitle(int count) {
    return 'Export $count Images';
  }

  @override
  String galleryExportedToFolder(int count, String folder) {
    return 'Exported $count images to $folder';
  }

  @override
  String galleryExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String galleryImagesCopied(int count) {
    return '$count images copied';
  }

  @override
  String galleryImagesPasted(int count) {
    return '$count images pasted';
  }

  @override
  String get galleryDeleteImage => 'Delete Image?';

  @override
  String get gallerySavedToDevice => 'Saved to device gallery';

  @override
  String get galleryExportImageDialog => 'Export Image';

  @override
  String gallerySavedTo(String name) {
    return 'Saved to $name';
  }

  @override
  String get galleryToggleFavorite => 'Toggle favorite';

  @override
  String get galleryExportImage => 'Export image';

  @override
  String get galleryDeleteImageTooltip => 'Delete image';

  @override
  String get galleryNoPrompt => 'No Prompt';

  @override
  String get galleryNoMetadata => 'No Metadata';

  @override
  String get galleryPrompt => 'Prompt';

  @override
  String get galleryImg2img => 'IMG2IMG';

  @override
  String get galleryCharRef => 'Char Ref';

  @override
  String get galleryVibe => 'Vibe';

  @override
  String get gallerySlideshow => 'Slideshow';

  @override
  String get galleryAddedAsCharRef => 'Added as character reference';

  @override
  String get galleryAddedAsVibe => 'Added as vibe transfer';

  @override
  String galleryVibeTransferFailed(String error) {
    return 'Vibe transfer failed: $error';
  }

  @override
  String get galleryScale => 'Scale';

  @override
  String get gallerySteps => 'Steps';

  @override
  String get gallerySampler => 'Sampler';

  @override
  String get gallerySeed => 'Seed';

  @override
  String get panelAdvancedSettings => 'Advanced Settings';

  @override
  String get panelDimensions => 'Dimensions';

  @override
  String get panelSeed => 'Seed';

  @override
  String get panelCustom => 'Custom';

  @override
  String get panelSteps => 'Steps';

  @override
  String get panelScale => 'Scale';

  @override
  String get panelSampler => 'Sampler';

  @override
  String get panelPostProcessing => 'Post-Processing';

  @override
  String get panelStyles => 'Styles';

  @override
  String get panelManageStyles => 'Manage Styles';

  @override
  String get panelEnabled => 'Enabled';

  @override
  String get panelNoStylesDefined => 'No Styles Defined';

  @override
  String get panelNegativePrompt => 'Negative Prompt';

  @override
  String get panelPresets => 'Presets';

  @override
  String get panelNoPresetsSaved => 'No Presets Saved';

  @override
  String get panelDeletePreset => 'Delete Preset';

  @override
  String panelDeletePresetConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get panelSaveToAlbum => 'Save to Album';

  @override
  String get panelNew => 'New';

  @override
  String get panelNewAlbum => 'New Album';

  @override
  String get panelAlbumName => 'Album Name';

  @override
  String get resNormalPortrait => 'Normal Portrait';

  @override
  String get resNormalLandscape => 'Normal Landscape';

  @override
  String get resNormalSquare => 'Normal Square';

  @override
  String get resLargePortrait => 'Large Portrait';

  @override
  String get resLargeLandscape => 'Large Landscape';

  @override
  String get resLargeSquare => 'Large Square';

  @override
  String get resWallpaperPortrait => 'Wallpaper Portrait';

  @override
  String get resWallpaperLandscape => 'Wallpaper Landscape';

  @override
  String get toolsHub => 'Tools Hub';

  @override
  String get toolsTitle => 'Tools';

  @override
  String get toolsWildcards => 'Wildcards';

  @override
  String get toolsTagLibrary => 'Tag Library';

  @override
  String get toolsPresets => 'Presets';

  @override
  String get toolsStyles => 'Styles';

  @override
  String get toolsReferences => 'References';

  @override
  String get toolsCascadeEditor => 'Cascade Editor';

  @override
  String get toolsImg2imgEditor => 'IMG2IMG Editor';

  @override
  String get toolsSlideshow => 'Slideshow';

  @override
  String get toolsPacks => 'Packs';

  @override
  String get toolsTheme => 'Theme';

  @override
  String get toolsSettings => 'Settings';

  @override
  String get helpTitle => 'NAIWeaver';

  @override
  String get helpShortcuts => 'Shortcuts';

  @override
  String get helpFeatures => 'Features';

  @override
  String get helpShortcutWildcard => 'Random line from wildcards/name.txt';

  @override
  String get helpShortcutWildcardBrowse => 'Browse wildcard file to insert';

  @override
  String get helpShortcutHoldDismiss => 'Dismiss tag suggestion';

  @override
  String get helpShortcutFavorites => 'Show all favorite tags';

  @override
  String get helpShortcutFavCategories => 'Favorites by category';

  @override
  String get helpShortcutSourceAction => 'Character performing action';

  @override
  String get helpShortcutTargetAction => 'Character receiving action';

  @override
  String get helpShortcutMutualAction => 'Shared action between characters';

  @override
  String get helpShortcutEnter => 'Generate (or select tag suggestion)';

  @override
  String get helpShortcutDragDrop => 'Import generation settings';

  @override
  String get helpFeatureGallery => 'Gallery';

  @override
  String get helpFeatureGalleryDesc =>
      'Browse, favorite, compare, and album-sort outputs';

  @override
  String get helpFeatureWildcards => 'Wildcards';

  @override
  String get helpFeatureWildcardsDesc =>
      '__pattern__ random substitution from text files';

  @override
  String get helpFeatureStyles => 'Styles';

  @override
  String get helpFeatureStylesDesc =>
      'Auto-inject prefix/suffix/negative into prompts';

  @override
  String get helpFeaturePresets => 'Presets';

  @override
  String get helpFeaturePresetsDesc =>
      'Save & restore full generation configurations';

  @override
  String get helpFeatureDirectorRef => 'Director Reference';

  @override
  String get helpFeatureDirectorRefDesc =>
      'Guide character/style appearance with ref images';

  @override
  String get helpFeatureVibeTransfer => 'Vibe Transfer';

  @override
  String get helpFeatureVibeTransferDesc =>
      'Influence composition & mood with ref images';

  @override
  String get helpFeatureCascade => 'Cascade';

  @override
  String get helpFeatureCascadeDesc => 'Multi-beat sequential scene generation';

  @override
  String get helpFeatureImg2img => 'IMG2IMG';

  @override
  String get helpFeatureImg2imgDesc =>
      'Edit/refine images with inpainting & variation';

  @override
  String get helpFeatureThemes => 'Themes';

  @override
  String get helpFeatureThemesDesc => 'Customize all colors, fonts, and scale';

  @override
  String get helpFeaturePacks => 'Packs';

  @override
  String get helpFeaturePacksDesc =>
      'Export/import presets, styles, wildcards as .vpack';

  @override
  String get wildcardManager => 'WILDCARD MANAGER';

  @override
  String get wildcardManageDesc => 'MANAGE AND EDIT YOUR WILDCARD FILES';

  @override
  String get wildcardFiles => 'FILES';

  @override
  String get wildcardNew => 'NEW WILDCARD';

  @override
  String get wildcardSelectOrCreate => 'SELECT OR CREATE A WILDCARD FILE';

  @override
  String get wildcardValidateTags => 'VALIDATE TAGS';

  @override
  String wildcardRecognized(int valid, int total) {
    return '$valid/$total RECOGNIZED';
  }

  @override
  String get wildcardClear => 'CLEAR';

  @override
  String get wildcardStartTyping => 'START TYPING TAGS...';

  @override
  String wildcardUnrecognized(int count) {
    return '$count UNRECOGNIZED';
  }

  @override
  String get wildcardCreateTitle => 'CREATE WILDCARD';

  @override
  String get wildcardFileName => 'FILE NAME';

  @override
  String get tagLibTitle => 'TAG LIBRARY';

  @override
  String get tagLibPreviewSettings => 'PREVIEW SETTINGS';

  @override
  String get tagLibAddTag => 'ADD TAG';

  @override
  String get tagLibSearchTags => 'SEARCH TAGS...';

  @override
  String get tagLibAll => 'ALL';

  @override
  String get tagLibFavorites => 'FAVORITES';

  @override
  String get tagLibImages => 'IMAGES';

  @override
  String get tagLibSort => 'SORT:';

  @override
  String get tagLibSortCountDesc => 'COUNT ↓';

  @override
  String get tagLibSortCountAsc => 'COUNT ↑';

  @override
  String get tagLibSortAZ => 'A-Z';

  @override
  String get tagLibSortZA => 'Z-A';

  @override
  String get tagLibSortFavsFirst => 'FAVS FIRST';

  @override
  String tagLibTagCount(int count) {
    return '$count TAGS';
  }

  @override
  String get tagLibDeleteTag => 'DELETE TAG';

  @override
  String tagLibRemoveConfirm(String tag) {
    return 'REMOVE \'$tag\' FROM LIBRARY?';
  }

  @override
  String get tagLibTestTag => 'TEST TAG';

  @override
  String get tagLibAddNewTag => 'ADD NEW TAG';

  @override
  String get tagLibTagName => 'TAG NAME';

  @override
  String get tagLibCount => 'COUNT';

  @override
  String get tagLibAddTagBtn => 'ADD TAG';

  @override
  String get tagLibDeleteExample => 'DELETE EXAMPLE';

  @override
  String get tagLibDeleteExampleConfirm => 'DELETE THIS VISUAL EXAMPLE?';

  @override
  String tagLibTesting(String tag) {
    return 'TESTING: $tag';
  }

  @override
  String get tagLibGeneratingPreview => 'GENERATING PREVIEW...';

  @override
  String get tagLibGenerationFailed => 'GENERATION FAILED';

  @override
  String get tagLibExampleSaved => 'EXAMPLE SAVED';

  @override
  String get tagLibSaveAsExample => 'SAVE AS EXAMPLE';

  @override
  String get tagLibPreviewSettingsTitle => 'PREVIEW SETTINGS';

  @override
  String get tagLibPositivePromptBase => 'POSITIVE PROMPT (BASE)';

  @override
  String get tagLibNegativePrompt => 'NEGATIVE PROMPT';

  @override
  String get tagLibSampler => 'SAMPLER';

  @override
  String get tagLibSteps => 'STEPS';

  @override
  String get tagLibWidth => 'WIDTH';

  @override
  String get tagLibHeight => 'HEIGHT';

  @override
  String get tagLibScale => 'SCALE';

  @override
  String get tagLibSeed => 'SEED';

  @override
  String get tagLibRandom => 'RANDOM';

  @override
  String get presetManager => 'PRESET MANAGER';

  @override
  String get presetManageDesc => 'MANAGE AND EDIT YOUR GENERATION PRESETS';

  @override
  String get presetList => 'PRESETS';

  @override
  String get presetNew => 'NEW PRESET';

  @override
  String presetCharsInfo(int chars, int ints) {
    return '$chars CHARS, $ints INTS';
  }

  @override
  String presetCharsRefsInfo(int chars, int ints, int refs) {
    return '$chars CHARS, $ints INTS, $refs REFS';
  }

  @override
  String get presetSelectToEdit => 'SELECT A PRESET TO EDIT';

  @override
  String get presetIdentity => 'IDENTITY';

  @override
  String get presetName => 'NAME';

  @override
  String get presetPrompts => 'PROMPTS';

  @override
  String get presetPrompt => 'PROMPT';

  @override
  String get presetNegativePrompt => 'NEGATIVE PROMPT';

  @override
  String get presetGenSettings => 'GENERATION SETTINGS';

  @override
  String get presetWidth => 'WIDTH';

  @override
  String get presetHeight => 'HEIGHT';

  @override
  String get presetScale => 'SCALE';

  @override
  String get presetSteps => 'STEPS';

  @override
  String get presetSampler => 'SAMPLER';

  @override
  String get presetCharsAndInteractions => 'CHARACTERS & INTERACTIONS';

  @override
  String get presetNoChars => 'NO CHARACTERS SAVED IN THIS PRESET';

  @override
  String presetCharacterN(int n) {
    return 'CHARACTER $n';
  }

  @override
  String get presetInteractions => 'INTERACTIONS';

  @override
  String get presetReferences => 'REFERENCES';

  @override
  String get presetNoRefs => 'NO REFERENCES SAVED IN THIS PRESET';

  @override
  String get presetProcessing => 'PROCESSING...';

  @override
  String get presetAddReference => 'ADD REFERENCE';

  @override
  String get presetDeleteTitle => 'DELETE PRESET';

  @override
  String presetDeleteConfirm(String name) {
    return 'ARE YOU SURE YOU WANT TO DELETE \'\'$name\'\'?';
  }

  @override
  String get presetOverwriteTitle => 'OVERWRITE PRESET';

  @override
  String presetOverwriteConfirm(String name) {
    return 'A PRESET WITH THE NAME \'\'$name\'\' ALREADY EXISTS. OVERWRITE?';
  }

  @override
  String get styleEditor => 'STYLE EDITOR';

  @override
  String get styleManageDesc => 'MANAGE PROMPT SNIPPETS AND STYLE TAGS';

  @override
  String get styleList => 'STYLES';

  @override
  String get styleNew => 'NEW STYLE';

  @override
  String get styleSelectToEdit => 'SELECT A STYLE TO EDIT';

  @override
  String get styleIdentity => 'IDENTITY';

  @override
  String get styleName => 'NAME';

  @override
  String get styleDefaultOnLaunch => 'DEFAULT ON LAUNCH';

  @override
  String get styleTargetPrompt => 'TARGET PROMPT';

  @override
  String get stylePositive => 'POSITIVE';

  @override
  String get styleNegative => 'NEGATIVE';

  @override
  String get styleNegativeContent => 'NEGATIVE CONTENT';

  @override
  String get stylePositiveContent => 'POSITIVE CONTENT';

  @override
  String get styleContent => 'CONTENT';

  @override
  String get stylePlacement => 'PLACEMENT';

  @override
  String get styleBeginningPrefix => 'BEGINNING (PREFIX)';

  @override
  String get styleEndSuffix => 'END (SUFFIX)';

  @override
  String get styleDeleteTitle => 'DELETE STYLE';

  @override
  String styleDeleteConfirm(String name) {
    return 'ARE YOU SURE YOU WANT TO DELETE \'\'$name\'\'?';
  }

  @override
  String get styleOverwriteTitle => 'OVERWRITE STYLE';

  @override
  String styleOverwriteConfirm(String name) {
    return 'A STYLE WITH THE NAME \'\'$name\'\' ALREADY EXISTS. OVERWRITE?';
  }

  @override
  String get refPreciseReferences => 'PRECISE REFERENCES';

  @override
  String get refVibeTransfer => 'VIBE TRANSFER';

  @override
  String get refDialogCancel => 'CANCEL';

  @override
  String get refDialogSave => 'SAVE';

  @override
  String get refNameHint => 'NAME';

  @override
  String get refClearAll => 'CLEAR ALL';

  @override
  String get refSavedSection => 'SAVED';

  @override
  String get refSaveReference => 'SAVE REFERENCE';

  @override
  String refReferenceCount(int count) {
    return '$count REFERENCES';
  }

  @override
  String get refNoReferencesAdded => 'NO REFERENCES ADDED';

  @override
  String get refEmptyDescription =>
      'Upload reference images to maintain character\nappearance or artistic style across generations.';

  @override
  String get refAddReference => 'ADD REFERENCE';

  @override
  String get refEditorTitle => 'REFERENCE EDITOR';

  @override
  String get refTypeLabel => 'REFERENCE TYPE';

  @override
  String get refStrength => 'STRENGTH';

  @override
  String get refFidelity => 'FIDELITY';

  @override
  String get refStrengthShort => 'STR';

  @override
  String get refFidelityShort => 'FID';

  @override
  String get refTypeCharacter => 'CHARACTER';

  @override
  String get refTypeStyle => 'STYLE';

  @override
  String get refTypeCharAndStyle => 'CHAR & STYLE';

  @override
  String get refSaveVibe => 'SAVE VIBE';

  @override
  String get refVibeTransfers => 'VIBE TRANSFERS';

  @override
  String refVibeCount(int count) {
    return '$count VIBES';
  }

  @override
  String get refNoVibesAdded => 'NO VIBES ADDED';

  @override
  String get refVibeEmptyDescription =>
      'Upload reference images to transfer artistic\nstyle and mood to your generations.';

  @override
  String get refAddVibe => 'ADD VIBE';

  @override
  String get refVibeLabel => 'VIBE';

  @override
  String get refVibeEditorTitle => 'VIBE EDITOR';

  @override
  String get refInfoExtracted => 'INFO EXTRACTED';

  @override
  String get refInfoExtractedShort => 'INF';

  @override
  String get refApiKeyMissing => 'API key missing or invalid';

  @override
  String refVibeEncodeFailed(String error) {
    return 'Failed to encode vibe: $error';
  }

  @override
  String get packTitle => 'NAIWEAVER PACKS';

  @override
  String get packDesc =>
      'Export and import presets, styles, and wildcards as .vpack files.';

  @override
  String get packExportLabel => 'EXPORT PACK';

  @override
  String get packExportDesc => 'Bundle presets, styles, and wildcards';

  @override
  String get packImportLabel => 'IMPORT PACK';

  @override
  String get packImportDesc => 'Load a .vpack file';

  @override
  String get packGalleryExport => 'GALLERY EXPORT';

  @override
  String get packGalleryExportDesc =>
      'Export gallery images as a ZIP file, organized by album folders.';

  @override
  String get packExportGalleryZip => 'EXPORT GALLERY AS ZIP';

  @override
  String get packExportGalleryZipDesc => 'Preserve album hierarchy in folders';

  @override
  String get packImportDialogTitle => 'Import NAIWeaver Pack';

  @override
  String packFailedRead(String error) {
    return 'Failed to read pack: $error';
  }

  @override
  String get packExportDialogTitle => 'EXPORT PACK';

  @override
  String get packName => 'PACK NAME';

  @override
  String get packDescriptionOptional => 'DESCRIPTION (OPTIONAL)';

  @override
  String packPresetsSection(int selected, int total) {
    return 'PRESETS ($selected/$total)';
  }

  @override
  String packStylesSection(int selected, int total) {
    return 'STYLES ($selected/$total)';
  }

  @override
  String packWildcardsSection(int selected, int total) {
    return 'WILDCARDS ($selected/$total)';
  }

  @override
  String get packExportSuccess => 'Pack exported successfully';

  @override
  String packExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get packImportDialogTitle2 => 'IMPORT PACK';

  @override
  String packImportCount(int count) {
    return 'IMPORT ($count)';
  }

  @override
  String get packImportSuccess => 'Pack imported successfully';

  @override
  String packImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get packExportGalleryTitle => 'EXPORT GALLERY';

  @override
  String get packAlbums => 'ALBUMS';

  @override
  String packUnsortedCount(int count) {
    return 'UNSORTED ($count)';
  }

  @override
  String get packOptions => 'OPTIONS';

  @override
  String get packStripMetadata => 'STRIP METADATA';

  @override
  String get packFavoritesOnly => 'FAVORITES ONLY';

  @override
  String packExportCount(int count) {
    return 'EXPORT ($count)';
  }

  @override
  String get packSaveDialogTitle => 'Save NAIWeaver Pack';

  @override
  String get packExportGalleryZipDialog => 'Export Gallery ZIP';

  @override
  String packExportedToZip(int count) {
    return 'Exported $count images to ZIP';
  }

  @override
  String get themeSelectToEdit => 'SELECT A THEME TO EDIT';

  @override
  String get themeList => 'THEMES';

  @override
  String get themeNew => 'New Theme';

  @override
  String get themeSave => 'SAVE';

  @override
  String get themeReset => 'RESET';

  @override
  String get themePreview => 'PREVIEW';

  @override
  String get themeColors => 'COLORS';

  @override
  String get themeColorBackground => 'Background';

  @override
  String get themeColorSurfaceHigh => 'Surface High';

  @override
  String get themeColorSurfaceMid => 'Surface Mid';

  @override
  String get themeColorTextPrimary => 'Text Primary';

  @override
  String get themeColorTextSecondary => 'Text Secondary';

  @override
  String get themeColorTextTertiary => 'Text Tertiary';

  @override
  String get themeColorTextDisabled => 'Text Disabled';

  @override
  String get themeColorTextMinimal => 'Text Minimal';

  @override
  String get themeColorBorderStrong => 'Border Strong';

  @override
  String get themeColorBorderMedium => 'Border Medium';

  @override
  String get themeColorBorderSubtle => 'Border Subtle';

  @override
  String get themeColorAccent => 'Accent';

  @override
  String get themeColorAccentEdit => 'Accent Edit';

  @override
  String get themeColorAccentSuccess => 'Accent Success';

  @override
  String get themeColorAccentDanger => 'Accent Danger';

  @override
  String get themeColorLogo => 'Logo';

  @override
  String get themeColorCascade => 'Cascade';

  @override
  String get themeReferences => 'REFERENCES';

  @override
  String get themeColorVibeTransfer => 'Vibe Transfer';

  @override
  String get themeColorRefCharacter => 'Ref Character';

  @override
  String get themeColorRefStyle => 'Ref Style';

  @override
  String get themeColorRefCharStyle => 'Ref Char+Style';

  @override
  String get themeFont => 'FONT';

  @override
  String get themeTextScale => 'TEXT SCALE';

  @override
  String get themeSmall => 'SMALL';

  @override
  String get themeLarge => 'LARGE';

  @override
  String get themePromptInput => 'PROMPT INPUT';

  @override
  String get themeFontSize => 'FONT SIZE';

  @override
  String get themeHeightLabel => 'HEIGHT';

  @override
  String themeLines(int count) {
    return '$count lines';
  }

  @override
  String get themeBrightMode => 'BRIGHT MODE';

  @override
  String get themeBrightText => 'BRIGHT TEXT';

  @override
  String get themeBrightDesc =>
      'Use brighter text colors for improved readability';

  @override
  String get themePanelLayout => 'PANEL LAYOUT';

  @override
  String get themePanelLayoutDesc =>
      'Drag to reorder Advanced Settings sections';

  @override
  String get themeDeleteTitle => 'DELETE THEME';

  @override
  String themeDeleteConfirm(String name) {
    return 'ARE YOU SURE YOU WANT TO DELETE \'\'$name\'\'?';
  }

  @override
  String get themeNewTitle => 'NEW THEME';

  @override
  String get themeCustomTheme => 'Custom Theme';

  @override
  String get themeThemeName => 'THEME NAME';

  @override
  String themeCreateFailed(String error) {
    return 'Failed to create theme: $error';
  }

  @override
  String get themeSectionDimSeed => 'DIMENSIONS + SEED';

  @override
  String get themeSectionStepsScale => 'STEPS + SCALE';

  @override
  String get themeSectionSamplerPost => 'SAMPLER + POST-PROCESSING';

  @override
  String get themeSectionStyles => 'STYLES';

  @override
  String get themeSectionNegPrompt => 'NEGATIVE PROMPT';

  @override
  String get themeSectionPresets => 'PRESETS';

  @override
  String get themeSectionSaveAlbum => 'SAVE TO ALBUM';

  @override
  String get themePreviewHeader => 'HEADER TEXT';

  @override
  String get themePreviewSecondary => 'Secondary text content';

  @override
  String get themePreviewHint => 'Hint / tertiary text';

  @override
  String get themePreviewGenerate => 'GENERATE';

  @override
  String get themePreviewEdit => 'EDIT';

  @override
  String get cascadeEditorLabel => 'CASCADE EDITOR';

  @override
  String get cascadeSavedToLibrary => 'CASCADE SAVED TO LIBRARY';

  @override
  String get cascadeNoBeatSelected => 'NO BEAT SELECTED';

  @override
  String get cascadeEnvironmentPrompt => 'ENVIRONMENT PROMPT';

  @override
  String get cascadeEnvHint =>
      'e.g. outdoors, forest, night, cinematic lighting';

  @override
  String get cascadeCharacterSlots => 'CHARACTER SLOTS';

  @override
  String cascadeCharacterSlotN(int n) {
    return 'CHARACTER SLOT $n';
  }

  @override
  String get cascadePosition => 'POSITION';

  @override
  String get cascadeAiPosition => 'AI POSITION';

  @override
  String get cascadePositivePrompt => 'POSITIVE PROMPT';

  @override
  String get cascadeCharHint => 'Character tags, appearance, state...';

  @override
  String get cascadeNegativePrompt => 'NEGATIVE PROMPT';

  @override
  String get cascadeAvoidHint => 'Avoid tags...';

  @override
  String get cascadeLinkAction => 'Link Action';

  @override
  String get cascadeBeatSettings => 'BEAT SETTINGS';

  @override
  String get cascadeResolution => 'RESOLUTION';

  @override
  String get cascadeSampler => 'SAMPLER';

  @override
  String get cascadeSteps => 'STEPS';

  @override
  String get cascadeScale => 'SCALE';

  @override
  String get cascadeStyles => 'STYLES';

  @override
  String get cascadeNoStyles => 'NO STYLES AVAILABLE';

  @override
  String get cascadeLibrary => 'CASCADE LIBRARY';

  @override
  String cascadeSequencesSaved(int count) {
    return '$count SEQUENCES SAVED';
  }

  @override
  String get cascadeNew => 'NEW CASCADE';

  @override
  String get cascadeNoCascades => 'NO CASCADES FOUND';

  @override
  String cascadeBeatsAndSlots(int beats, int slots) {
    return '$beats BEATS • $slots CHARACTER SLOTS';
  }

  @override
  String get cascadeCreateNew => 'CREATE NEW CASCADE';

  @override
  String get cascadeName => 'CASCADE NAME';

  @override
  String get cascadeCharSlotsLabel => 'CHARACTER SLOTS';

  @override
  String get cascadeAutoPosition => 'AUTO POSITION (LET AI DECIDE)';

  @override
  String get cascadeDeleteTitle => 'DELETE CASCADE?';

  @override
  String cascadeDeleteConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get cascadeSelect => 'SELECT CASCADE';

  @override
  String get cascadeNoSaved => 'NO SAVED CASCADES FOUND';

  @override
  String cascadeCharactersAndBeats(int chars, int beats) {
    return '$chars CHARACTERS • $beats BEATS';
  }

  @override
  String cascadeCharTags(int n) {
    return 'CHAR $n TAGS';
  }

  @override
  String get cascadeGlobalStyle => 'GLOBAL STYLE / INJECTION';

  @override
  String cascadeRegenerateBeat(int n) {
    return 'REGENERATE BEAT $n';
  }

  @override
  String cascadeGenerateBeat(int n) {
    return 'GENERATE BEAT $n';
  }

  @override
  String get cascadeSkipToNext => 'Skip to next';

  @override
  String get img2imgResult => 'RESULT';

  @override
  String get img2imgSource => 'SOURCE';

  @override
  String get img2imgCanvas => 'CANVAS';

  @override
  String get img2imgUseAsSource => 'USE AS SOURCE';

  @override
  String get img2imgInpainting => 'INPAINTING';

  @override
  String get img2imgTitle => 'IMG2IMG';

  @override
  String get img2imgEditorLabel => 'EDITOR';

  @override
  String get img2imgBackToPicker => 'Back to picker';

  @override
  String get img2imgGenerating => 'GENERATING...';

  @override
  String get img2imgGenerate => 'GENERATE';

  @override
  String img2imgGenerationFailed(String error) {
    return 'Generation failed: $error';
  }

  @override
  String get img2imgSettings => 'IMG2IMG SETTINGS';

  @override
  String get img2imgPrompt => 'PROMPT';

  @override
  String get img2imgPromptHint => 'Describe what to generate...';

  @override
  String get img2imgNegative => 'NEGATIVE';

  @override
  String get img2imgNegativeHint => 'Undesired content...';

  @override
  String get img2imgStrength => 'STRENGTH';

  @override
  String get img2imgNoise => 'NOISE';

  @override
  String get img2imgMaskBlur => 'MASK BLUR';

  @override
  String get img2imgColorCorrect => 'COLOR CORRECT';

  @override
  String get img2imgSourceInfo => 'SOURCE';

  @override
  String img2imgMaskStrokes(int count) {
    return 'MASK: $count strokes';
  }

  @override
  String get img2imgNoMask => 'NO MASK (full img2img)';

  @override
  String get img2imgUploadFromDevice => 'UPLOAD FROM DEVICE';

  @override
  String get img2imgUploadFromDeviceDesc =>
      'Pick an image from your photo library or files';

  @override
  String get slideshowTitle => 'SLIDESHOW';

  @override
  String get slideshowPlayAll => 'PLAY ALL';

  @override
  String get slideshowConfigs => 'CONFIGS';

  @override
  String get slideshowNewConfig => 'NEW CONFIG';

  @override
  String get slideshowNoConfigs =>
      'NO SLIDESHOW CONFIGS YET.\nTAP + TO CREATE ONE.';

  @override
  String get slideshowSelectOrCreate => 'SELECT OR CREATE A SLIDESHOW CONFIG';

  @override
  String get slideshowNameLabel => 'NAME';

  @override
  String get slideshowSourceLabel => 'SOURCE';

  @override
  String get slideshowTransition => 'TRANSITION';

  @override
  String get slideshowTransitionDuration => 'TRANSITION DURATION';

  @override
  String get slideshowTiming => 'TIMING';

  @override
  String get slideshowSlideDuration => 'SLIDE DURATION';

  @override
  String get slideshowKenBurns => 'KEN BURNS EFFECT';

  @override
  String get slideshowEnabled => 'ENABLED';

  @override
  String get slideshowIntensity => 'INTENSITY';

  @override
  String get slideshowManualZoom => 'MANUAL ZOOM';

  @override
  String get slideshowPlayback => 'PLAYBACK';

  @override
  String get slideshowShuffle => 'SHUFFLE';

  @override
  String get slideshowLoop => 'LOOP';

  @override
  String get slideshowDefault => 'DEFAULT';

  @override
  String get slideshowUseAsDefault => 'USE AS DEFAULT SLIDESHOW';

  @override
  String get slideshowPlay => 'PLAY SLIDESHOW';

  @override
  String get slideshowTransFade => 'FADE';

  @override
  String get slideshowTransSlideL => 'SLIDE L';

  @override
  String get slideshowTransSlideR => 'SLIDE R';

  @override
  String get slideshowTransSlideUp => 'SLIDE UP';

  @override
  String get slideshowTransZoom => 'ZOOM';

  @override
  String get slideshowTransXZoom => 'X-ZOOM';

  @override
  String get slideshowSourceAllImages => 'ALL IMAGES';

  @override
  String get slideshowSourceAlbum => 'ALBUM';

  @override
  String get slideshowSourceFavorites => 'FAVORITES';

  @override
  String slideshowSourceCustom(int count) {
    return '$count CUSTOM';
  }

  @override
  String get slideshowDeleteConfig => 'DELETE CONFIG';

  @override
  String slideshowDeleteConfirm(String name) {
    return 'DELETE \'\'$name\'\'?';
  }

  @override
  String get slideshowImageSource => 'IMAGE SOURCE';

  @override
  String get slideshowAllImages => 'ALL IMAGES';

  @override
  String slideshowImageCount(int count) {
    return '$count images';
  }

  @override
  String get slideshowFavoritesLabel => 'FAVORITES';

  @override
  String get slideshowAlbumLabel => 'ALBUM';

  @override
  String get slideshowCustomSelection => 'CUSTOM SELECTION';

  @override
  String slideshowSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get slideshowNoAlbums => 'NO ALBUMS CREATED';

  @override
  String get slideshowSelectAlbum => 'SELECT ALBUM';

  @override
  String slideshowCustomCount(int selected, int total) {
    return '$selected / $total SELECTED';
  }

  @override
  String get slideshowDeselectAll => 'DESELECT ALL';

  @override
  String get slideshowSelectAll => 'SELECT ALL';

  @override
  String get slideshowNoImages => 'NO IMAGES TO SHOW';

  @override
  String get slideshowGoBack => 'GO BACK';

  @override
  String demoImagesSelected(int count) {
    return '$count IMAGES SELECTED';
  }

  @override
  String get demoAll => 'ALL';

  @override
  String get demoClear => 'CLEAR';

  @override
  String get demoNoImages => 'NO IMAGES IN GALLERY';

  @override
  String get cascadeBeatTimeline => 'BEAT TIMELINE';

  @override
  String cascadeBeatsCount(int count) {
    return '$count BEATS';
  }

  @override
  String cascadeBeatN(int n) {
    return 'BEAT $n';
  }

  @override
  String get cascadeCloneBeat => 'Clone Beat';

  @override
  String get cascadeRemoveBeat => 'Remove Beat';
}
