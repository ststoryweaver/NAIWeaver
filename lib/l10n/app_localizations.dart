import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get commonCreate;

  /// No description provided for @commonRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get commonRename;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonSet.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get commonSet;

  /// No description provided for @commonNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get commonNone;

  /// No description provided for @commonExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get commonExport;

  /// No description provided for @commonOverwrite.
  ///
  /// In en, this message translates to:
  /// **'OVERWRITE'**
  String get commonOverwrite;

  /// No description provided for @commonSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'SAVE CHANGES'**
  String get commonSaveChanges;

  /// No description provided for @mainGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get mainGallery;

  /// No description provided for @mainTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get mainTools;

  /// No description provided for @mainSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get mainSave;

  /// No description provided for @mainEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get mainEdit;

  /// No description provided for @mainEnterPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter Prompt'**
  String get mainEnterPrompt;

  /// No description provided for @mainHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get mainHelp;

  /// No description provided for @mainAuthError.
  ///
  /// In en, this message translates to:
  /// **'Authentication error: please check API settings'**
  String get mainAuthError;

  /// No description provided for @mainSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get mainSettings;

  /// No description provided for @mainImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to import settings: {error}'**
  String mainImportFailed(String error);

  /// No description provided for @mainSavePreset.
  ///
  /// In en, this message translates to:
  /// **'Save Preset'**
  String get mainSavePreset;

  /// No description provided for @mainPresetName.
  ///
  /// In en, this message translates to:
  /// **'Preset Name'**
  String get mainPresetName;

  /// No description provided for @mainAdvancedSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get mainAdvancedSettings;

  /// No description provided for @settingsApiSettings.
  ///
  /// In en, this message translates to:
  /// **'API Settings'**
  String get settingsApiSettings;

  /// No description provided for @settingsGeneralSettings.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get settingsGeneralSettings;

  /// No description provided for @settingsUiSettings.
  ///
  /// In en, this message translates to:
  /// **'UI Settings'**
  String get settingsUiSettings;

  /// No description provided for @settingsExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get settingsExport;

  /// No description provided for @settingsSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSecurity;

  /// No description provided for @settingsDemoMode.
  ///
  /// In en, this message translates to:
  /// **'Demo Mode'**
  String get settingsDemoMode;

  /// No description provided for @settingsLinks.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get settingsLinks;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsApiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'NovelAI API Key'**
  String get settingsApiKeyLabel;

  /// No description provided for @settingsApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'pst-xxxx...'**
  String get settingsApiKeyHint;

  /// No description provided for @settingsAutoSave.
  ///
  /// In en, this message translates to:
  /// **'Auto-Save Images'**
  String get settingsAutoSave;

  /// No description provided for @settingsAutoSaveDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically save all generated images to the output folder'**
  String get settingsAutoSaveDesc;

  /// No description provided for @settingsSmartStyleImport.
  ///
  /// In en, this message translates to:
  /// **'Smart Style Import'**
  String get settingsSmartStyleImport;

  /// No description provided for @settingsSmartStyleImportDesc.
  ///
  /// In en, this message translates to:
  /// **'Strip style tags from imported prompts and restore style selections instead'**
  String get settingsSmartStyleImportDesc;

  /// No description provided for @settingsRememberSession.
  ///
  /// In en, this message translates to:
  /// **'Remember Session'**
  String get settingsRememberSession;

  /// No description provided for @settingsRememberSessionDesc.
  ///
  /// In en, this message translates to:
  /// **'Auto-save your prompt, settings, and references for crash recovery'**
  String get settingsRememberSessionDesc;

  /// No description provided for @settingsImg2ImgImportPrompt.
  ///
  /// In en, this message translates to:
  /// **'Img2Img Import Prompt'**
  String get settingsImg2ImgImportPrompt;

  /// No description provided for @settingsImg2ImgImportPromptDesc.
  ///
  /// In en, this message translates to:
  /// **'Auto-fill img2img prompt when selecting a source image with metadata'**
  String get settingsImg2ImgImportPromptDesc;

  /// No description provided for @settingsSaveToAlbum.
  ///
  /// In en, this message translates to:
  /// **'Save to Album'**
  String get settingsSaveToAlbum;

  /// No description provided for @settingsSaveToAlbumDesc.
  ///
  /// In en, this message translates to:
  /// **'Auto-add new generations to this album'**
  String get settingsSaveToAlbumDesc;

  /// No description provided for @settingsEditButton.
  ///
  /// In en, this message translates to:
  /// **'Edit Button'**
  String get settingsEditButton;

  /// No description provided for @settingsEditButtonDesc.
  ///
  /// In en, this message translates to:
  /// **'Show the edit/inpainting button on the image viewer'**
  String get settingsEditButtonDesc;

  /// No description provided for @settingsDirectorRefShelf.
  ///
  /// In en, this message translates to:
  /// **'Director Reference Shelf'**
  String get settingsDirectorRefShelf;

  /// No description provided for @settingsDirectorRefShelfDesc.
  ///
  /// In en, this message translates to:
  /// **'Show the reference image shelf on the main screen'**
  String get settingsDirectorRefShelfDesc;

  /// No description provided for @settingsVibeTransferShelf.
  ///
  /// In en, this message translates to:
  /// **'Vibe Transfer Shelf'**
  String get settingsVibeTransferShelf;

  /// No description provided for @settingsVibeTransferShelfDesc.
  ///
  /// In en, this message translates to:
  /// **'Show the vibe transfer shelf on the main screen'**
  String get settingsVibeTransferShelfDesc;

  /// No description provided for @settingsCharEditorMode.
  ///
  /// In en, this message translates to:
  /// **'Character Editor Mode'**
  String get settingsCharEditorMode;

  /// No description provided for @settingsCharEditorModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Use the expanded character editor in the settings panel instead of the compact shelf'**
  String get settingsCharEditorModeDesc;

  /// No description provided for @settingsThemeBuilder.
  ///
  /// In en, this message translates to:
  /// **'Theme Builder'**
  String get settingsThemeBuilder;

  /// No description provided for @settingsStripMetadata.
  ///
  /// In en, this message translates to:
  /// **'Strip Metadata on Export'**
  String get settingsStripMetadata;

  /// No description provided for @settingsStripMetadataDesc.
  ///
  /// In en, this message translates to:
  /// **'Remove generation data (prompt, settings) from exported images'**
  String get settingsStripMetadataDesc;

  /// No description provided for @settingsPinLock.
  ///
  /// In en, this message translates to:
  /// **'PIN Lock'**
  String get settingsPinLock;

  /// No description provided for @settingsPinLockDesc.
  ///
  /// In en, this message translates to:
  /// **'Require a PIN (4-8 digits) to open the app'**
  String get settingsPinLockDesc;

  /// No description provided for @settingsLockOnResume.
  ///
  /// In en, this message translates to:
  /// **'Lock on Resume'**
  String get settingsLockOnResume;

  /// No description provided for @settingsLockOnResumeDesc.
  ///
  /// In en, this message translates to:
  /// **'Re-lock app when returning from background'**
  String get settingsLockOnResumeDesc;

  /// No description provided for @settingsBiometricUnlock.
  ///
  /// In en, this message translates to:
  /// **'Biometric Unlock'**
  String get settingsBiometricUnlock;

  /// No description provided for @settingsBiometricUnlockDesc.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or face unlock'**
  String get settingsBiometricUnlockDesc;

  /// No description provided for @settingsBiometricsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometrics not available on this device'**
  String get settingsBiometricsUnavailable;

  /// No description provided for @settingsSetPin.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get settingsSetPin;

  /// No description provided for @settingsPinDigitsHint.
  ///
  /// In en, this message translates to:
  /// **'4-8 digits'**
  String get settingsPinDigitsHint;

  /// No description provided for @settingsPinMustBeDigits.
  ///
  /// In en, this message translates to:
  /// **'PIN must be 4-8 digits'**
  String get settingsPinMustBeDigits;

  /// No description provided for @settingsPinsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match'**
  String get settingsPinsDoNotMatch;

  /// No description provided for @settingsEnterCurrentPin.
  ///
  /// In en, this message translates to:
  /// **'Enter Current PIN'**
  String get settingsEnterCurrentPin;

  /// No description provided for @settingsEnterPinHint.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get settingsEnterPinHint;

  /// No description provided for @settingsIncorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get settingsIncorrectPin;

  /// No description provided for @settingsDemoModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Only show demo-safe images in the gallery'**
  String get settingsDemoModeDesc;

  /// No description provided for @settingsSelectDemoImages.
  ///
  /// In en, this message translates to:
  /// **'Select Demo Images'**
  String get settingsSelectDemoImages;

  /// No description provided for @settingsTagSuggestionsHidden.
  ///
  /// In en, this message translates to:
  /// **'Tag suggestions are hidden while demo mode is active'**
  String get settingsTagSuggestionsHidden;

  /// No description provided for @settingsPositivePrefix.
  ///
  /// In en, this message translates to:
  /// **'Positive Prefix'**
  String get settingsPositivePrefix;

  /// No description provided for @settingsNegativePrefix.
  ///
  /// In en, this message translates to:
  /// **'Negative Prefix'**
  String get settingsNegativePrefix;

  /// No description provided for @settingsEditPositivePrefix.
  ///
  /// In en, this message translates to:
  /// **'Edit Positive Prefix'**
  String get settingsEditPositivePrefix;

  /// No description provided for @settingsEditNegativePrefix.
  ///
  /// In en, this message translates to:
  /// **'Edit Negative Prefix'**
  String get settingsEditNegativePrefix;

  /// No description provided for @settingsDemoPrefixes.
  ///
  /// In en, this message translates to:
  /// **'Demo Prefixes'**
  String get settingsDemoPrefixes;

  /// No description provided for @settingsNotSet.
  ///
  /// In en, this message translates to:
  /// **'(not set)'**
  String get settingsNotSet;

  /// No description provided for @settingsGithubRepository.
  ///
  /// In en, this message translates to:
  /// **'GitHub Repository'**
  String get settingsGithubRepository;

  /// No description provided for @settingsGithubPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'GitHub link placeholder'**
  String get settingsGithubPlaceholder;

  /// No description provided for @galleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get galleryTitle;

  /// No description provided for @galleryDemoTitle.
  ///
  /// In en, this message translates to:
  /// **'Gallery (Demo)'**
  String get galleryDemoTitle;

  /// No description provided for @gallerySearchTags.
  ///
  /// In en, this message translates to:
  /// **'Search Tags...'**
  String get gallerySearchTags;

  /// No description provided for @gallerySelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Selected'**
  String gallerySelectedCount(int count);

  /// No description provided for @galleryDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get galleryDeselectAll;

  /// No description provided for @gallerySelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get gallerySelectAll;

  /// No description provided for @galleryFavoritesFilter.
  ///
  /// In en, this message translates to:
  /// **'Favorites filter'**
  String get galleryFavoritesFilter;

  /// No description provided for @gallerySort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get gallerySort;

  /// No description provided for @gallerySelectMode.
  ///
  /// In en, this message translates to:
  /// **'Select mode'**
  String get gallerySelectMode;

  /// No description provided for @galleryColumnsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} columns'**
  String galleryColumnsCount(int count);

  /// No description provided for @gallerySortDateNewest.
  ///
  /// In en, this message translates to:
  /// **'Date (Newest)'**
  String get gallerySortDateNewest;

  /// No description provided for @gallerySortDateOldest.
  ///
  /// In en, this message translates to:
  /// **'Date (Oldest)'**
  String get gallerySortDateOldest;

  /// No description provided for @gallerySortNameAZ.
  ///
  /// In en, this message translates to:
  /// **'Name (A-Z)'**
  String get gallerySortNameAZ;

  /// No description provided for @gallerySortNameZA.
  ///
  /// In en, this message translates to:
  /// **'Name (Z-A)'**
  String get gallerySortNameZA;

  /// No description provided for @gallerySortSizeLargest.
  ///
  /// In en, this message translates to:
  /// **'Size (Largest)'**
  String get gallerySortSizeLargest;

  /// No description provided for @gallerySortSizeSmallest.
  ///
  /// In en, this message translates to:
  /// **'Size (Smallest)'**
  String get gallerySortSizeSmallest;

  /// No description provided for @galleryNoDemoImages.
  ///
  /// In en, this message translates to:
  /// **'No demo images selected'**
  String get galleryNoDemoImages;

  /// No description provided for @galleryNoFavorites.
  ///
  /// In en, this message translates to:
  /// **'No Favorites'**
  String get galleryNoFavorites;

  /// No description provided for @galleryNoImagesInAlbum.
  ///
  /// In en, this message translates to:
  /// **'No Images in Album'**
  String get galleryNoImagesInAlbum;

  /// No description provided for @galleryNoImagesFound.
  ///
  /// In en, this message translates to:
  /// **'No Images Found'**
  String get galleryNoImagesFound;

  /// No description provided for @galleryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get galleryAll;

  /// No description provided for @galleryCopiedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Copied'**
  String galleryCopiedCount(int count);

  /// No description provided for @galleryImagesCopiedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Images Copied'**
  String galleryImagesCopiedCount(int count);

  /// No description provided for @galleryPasteInto.
  ///
  /// In en, this message translates to:
  /// **'Paste Into {name}'**
  String galleryPasteInto(String name);

  /// No description provided for @galleryPastedIntoAlbum.
  ///
  /// In en, this message translates to:
  /// **'{count} images pasted into {name}'**
  String galleryPastedIntoAlbum(int count, String name);

  /// No description provided for @galleryClearClipboard.
  ///
  /// In en, this message translates to:
  /// **'Clear Clipboard'**
  String get galleryClearClipboard;

  /// No description provided for @galleryNewAlbum.
  ///
  /// In en, this message translates to:
  /// **'New Album'**
  String get galleryNewAlbum;

  /// No description provided for @galleryAlbumName.
  ///
  /// In en, this message translates to:
  /// **'Album Name'**
  String get galleryAlbumName;

  /// No description provided for @galleryRenameAlbum.
  ///
  /// In en, this message translates to:
  /// **'Rename Album'**
  String get galleryRenameAlbum;

  /// No description provided for @galleryAddToAlbum.
  ///
  /// In en, this message translates to:
  /// **'Add to Album'**
  String get galleryAddToAlbum;

  /// No description provided for @galleryDeleteCount.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} images?'**
  String galleryDeleteCount(int count);

  /// No description provided for @galleryCannotUndo.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get galleryCannotUndo;

  /// No description provided for @galleryCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get galleryCompare;

  /// No description provided for @galleryCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get galleryCopy;

  /// No description provided for @galleryPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get galleryPaste;

  /// No description provided for @galleryAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get galleryAlbum;

  /// No description provided for @galleryFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get galleryFavorite;

  /// No description provided for @gallerySavedToDeviceCount.
  ///
  /// In en, this message translates to:
  /// **'Saved {saved}/{total} to device gallery'**
  String gallerySavedToDeviceCount(int saved, int total);

  /// No description provided for @galleryExportDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Export {count} Images'**
  String galleryExportDialogTitle(int count);

  /// No description provided for @galleryExportedToFolder.
  ///
  /// In en, this message translates to:
  /// **'Exported {count} images to {folder}'**
  String galleryExportedToFolder(int count, String folder);

  /// No description provided for @galleryExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String galleryExportFailed(String error);

  /// No description provided for @galleryImagesCopied.
  ///
  /// In en, this message translates to:
  /// **'{count} images copied'**
  String galleryImagesCopied(int count);

  /// No description provided for @galleryImagesPasted.
  ///
  /// In en, this message translates to:
  /// **'{count} images pasted'**
  String galleryImagesPasted(int count);

  /// No description provided for @galleryDeleteImage.
  ///
  /// In en, this message translates to:
  /// **'Delete Image?'**
  String get galleryDeleteImage;

  /// No description provided for @gallerySavedToDevice.
  ///
  /// In en, this message translates to:
  /// **'Saved to device gallery'**
  String get gallerySavedToDevice;

  /// No description provided for @galleryExportImageDialog.
  ///
  /// In en, this message translates to:
  /// **'Export Image'**
  String get galleryExportImageDialog;

  /// No description provided for @gallerySavedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to {name}'**
  String gallerySavedTo(String name);

  /// No description provided for @galleryToggleFavorite.
  ///
  /// In en, this message translates to:
  /// **'Toggle favorite'**
  String get galleryToggleFavorite;

  /// No description provided for @galleryExportImage.
  ///
  /// In en, this message translates to:
  /// **'Export image'**
  String get galleryExportImage;

  /// No description provided for @galleryDeleteImageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete image'**
  String get galleryDeleteImageTooltip;

  /// No description provided for @galleryNoPrompt.
  ///
  /// In en, this message translates to:
  /// **'No Prompt'**
  String get galleryNoPrompt;

  /// No description provided for @galleryNoMetadata.
  ///
  /// In en, this message translates to:
  /// **'No Metadata'**
  String get galleryNoMetadata;

  /// No description provided for @galleryPrompt.
  ///
  /// In en, this message translates to:
  /// **'Prompt'**
  String get galleryPrompt;

  /// No description provided for @galleryImg2img.
  ///
  /// In en, this message translates to:
  /// **'IMG2IMG'**
  String get galleryImg2img;

  /// No description provided for @galleryCharRef.
  ///
  /// In en, this message translates to:
  /// **'Char Ref'**
  String get galleryCharRef;

  /// No description provided for @galleryVibe.
  ///
  /// In en, this message translates to:
  /// **'Vibe'**
  String get galleryVibe;

  /// No description provided for @gallerySlideshow.
  ///
  /// In en, this message translates to:
  /// **'Slideshow'**
  String get gallerySlideshow;

  /// No description provided for @galleryAddedAsCharRef.
  ///
  /// In en, this message translates to:
  /// **'Added as character reference'**
  String get galleryAddedAsCharRef;

  /// No description provided for @galleryAddedAsVibe.
  ///
  /// In en, this message translates to:
  /// **'Added as vibe transfer'**
  String get galleryAddedAsVibe;

  /// No description provided for @galleryVibeTransferFailed.
  ///
  /// In en, this message translates to:
  /// **'Vibe transfer failed: {error}'**
  String galleryVibeTransferFailed(String error);

  /// No description provided for @galleryScale.
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get galleryScale;

  /// No description provided for @gallerySteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get gallerySteps;

  /// No description provided for @gallerySampler.
  ///
  /// In en, this message translates to:
  /// **'Sampler'**
  String get gallerySampler;

  /// No description provided for @gallerySeed.
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get gallerySeed;

  /// No description provided for @galleryResolution.
  ///
  /// In en, this message translates to:
  /// **'Res'**
  String get galleryResolution;

  /// No description provided for @galleryEnhance.
  ///
  /// In en, this message translates to:
  /// **'Enhance'**
  String get galleryEnhance;

  /// No description provided for @galleryDirectorTools.
  ///
  /// In en, this message translates to:
  /// **'Director'**
  String get galleryDirectorTools;

  /// No description provided for @galleryImport.
  ///
  /// In en, this message translates to:
  /// **'Import Images'**
  String get galleryImport;

  /// No description provided for @galleryImporting.
  ///
  /// In en, this message translates to:
  /// **'Importing...'**
  String get galleryImporting;

  /// No description provided for @galleryImportProgress.
  ///
  /// In en, this message translates to:
  /// **'Importing {current}/{total}...'**
  String galleryImportProgress(int current, int total);

  /// No description provided for @galleryImportPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing...'**
  String get galleryImportPreparing;

  /// No description provided for @galleryImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} images ({metadata} with NovelAI metadata)'**
  String galleryImportSuccess(int count, int metadata);

  /// No description provided for @galleryImportConverted.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} images ({converted} converted to PNG)'**
  String galleryImportConverted(int count, int converted);

  /// No description provided for @galleryImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String galleryImportFailed(String error);

  /// No description provided for @panelAdvancedSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get panelAdvancedSettings;

  /// No description provided for @panelDimensions.
  ///
  /// In en, this message translates to:
  /// **'Dimensions'**
  String get panelDimensions;

  /// No description provided for @panelSeed.
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get panelSeed;

  /// No description provided for @panelCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get panelCustom;

  /// No description provided for @panelSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get panelSteps;

  /// No description provided for @panelScale.
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get panelScale;

  /// No description provided for @panelSampler.
  ///
  /// In en, this message translates to:
  /// **'Sampler'**
  String get panelSampler;

  /// No description provided for @panelPostProcessing.
  ///
  /// In en, this message translates to:
  /// **'Post-Processing'**
  String get panelPostProcessing;

  /// No description provided for @panelStyles.
  ///
  /// In en, this message translates to:
  /// **'Styles'**
  String get panelStyles;

  /// No description provided for @panelManageStyles.
  ///
  /// In en, this message translates to:
  /// **'Manage Styles'**
  String get panelManageStyles;

  /// No description provided for @panelEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get panelEnabled;

  /// No description provided for @panelNoStylesDefined.
  ///
  /// In en, this message translates to:
  /// **'No Styles Defined'**
  String get panelNoStylesDefined;

  /// No description provided for @panelNegativePrompt.
  ///
  /// In en, this message translates to:
  /// **'Negative Prompt'**
  String get panelNegativePrompt;

  /// No description provided for @panelPresets.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get panelPresets;

  /// No description provided for @panelNoPresetsSaved.
  ///
  /// In en, this message translates to:
  /// **'No Presets Saved'**
  String get panelNoPresetsSaved;

  /// No description provided for @panelDeletePreset.
  ///
  /// In en, this message translates to:
  /// **'Delete Preset'**
  String get panelDeletePreset;

  /// No description provided for @panelDeletePresetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String panelDeletePresetConfirm(String name);

  /// No description provided for @panelSaveToAlbum.
  ///
  /// In en, this message translates to:
  /// **'Save to Album'**
  String get panelSaveToAlbum;

  /// No description provided for @panelNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get panelNew;

  /// No description provided for @panelNewAlbum.
  ///
  /// In en, this message translates to:
  /// **'New Album'**
  String get panelNewAlbum;

  /// No description provided for @panelAlbumName.
  ///
  /// In en, this message translates to:
  /// **'Album Name'**
  String get panelAlbumName;

  /// No description provided for @resNormalPortrait.
  ///
  /// In en, this message translates to:
  /// **'Normal Portrait'**
  String get resNormalPortrait;

  /// No description provided for @resNormalLandscape.
  ///
  /// In en, this message translates to:
  /// **'Normal Landscape'**
  String get resNormalLandscape;

  /// No description provided for @resNormalSquare.
  ///
  /// In en, this message translates to:
  /// **'Normal Square'**
  String get resNormalSquare;

  /// No description provided for @resLargePortrait.
  ///
  /// In en, this message translates to:
  /// **'Large Portrait'**
  String get resLargePortrait;

  /// No description provided for @resLargeLandscape.
  ///
  /// In en, this message translates to:
  /// **'Large Landscape'**
  String get resLargeLandscape;

  /// No description provided for @resLargeSquare.
  ///
  /// In en, this message translates to:
  /// **'Large Square'**
  String get resLargeSquare;

  /// No description provided for @resWallpaperPortrait.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper Portrait'**
  String get resWallpaperPortrait;

  /// No description provided for @resWallpaperLandscape.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper Landscape'**
  String get resWallpaperLandscape;

  /// No description provided for @toolsHub.
  ///
  /// In en, this message translates to:
  /// **'Tools Hub'**
  String get toolsHub;

  /// No description provided for @toolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get toolsTitle;

  /// No description provided for @toolsWildcards.
  ///
  /// In en, this message translates to:
  /// **'Wildcards'**
  String get toolsWildcards;

  /// No description provided for @toolsTagLibrary.
  ///
  /// In en, this message translates to:
  /// **'Tag Library'**
  String get toolsTagLibrary;

  /// No description provided for @toolsPresets.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get toolsPresets;

  /// No description provided for @toolsStyles.
  ///
  /// In en, this message translates to:
  /// **'Styles'**
  String get toolsStyles;

  /// No description provided for @toolsReferences.
  ///
  /// In en, this message translates to:
  /// **'References'**
  String get toolsReferences;

  /// No description provided for @toolsCascadeEditor.
  ///
  /// In en, this message translates to:
  /// **'Cascade Editor'**
  String get toolsCascadeEditor;

  /// No description provided for @toolsImg2imgEditor.
  ///
  /// In en, this message translates to:
  /// **'IMG2IMG Editor'**
  String get toolsImg2imgEditor;

  /// No description provided for @toolsSlideshow.
  ///
  /// In en, this message translates to:
  /// **'Slideshow'**
  String get toolsSlideshow;

  /// No description provided for @toolsPacks.
  ///
  /// In en, this message translates to:
  /// **'Packs'**
  String get toolsPacks;

  /// No description provided for @toolsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get toolsTheme;

  /// No description provided for @toolsSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get toolsSettings;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'NAIWeaver'**
  String get helpTitle;

  /// No description provided for @helpShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get helpShortcuts;

  /// No description provided for @helpFeatures.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get helpFeatures;

  /// No description provided for @helpShortcutWildcard.
  ///
  /// In en, this message translates to:
  /// **'Random line from wildcards/name.txt'**
  String get helpShortcutWildcard;

  /// No description provided for @helpShortcutWildcardBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse wildcard file to insert'**
  String get helpShortcutWildcardBrowse;

  /// No description provided for @helpShortcutHoldDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss tag suggestion'**
  String get helpShortcutHoldDismiss;

  /// No description provided for @helpShortcutFavorites.
  ///
  /// In en, this message translates to:
  /// **'Show all favorite tags'**
  String get helpShortcutFavorites;

  /// No description provided for @helpShortcutFavCategories.
  ///
  /// In en, this message translates to:
  /// **'Favorites by category'**
  String get helpShortcutFavCategories;

  /// No description provided for @helpShortcutArtistPrefix.
  ///
  /// In en, this message translates to:
  /// **'Filter tag suggestions to artists'**
  String get helpShortcutArtistPrefix;

  /// No description provided for @helpShortcutSourceAction.
  ///
  /// In en, this message translates to:
  /// **'Character performing action'**
  String get helpShortcutSourceAction;

  /// No description provided for @helpShortcutTargetAction.
  ///
  /// In en, this message translates to:
  /// **'Character receiving action'**
  String get helpShortcutTargetAction;

  /// No description provided for @helpShortcutMutualAction.
  ///
  /// In en, this message translates to:
  /// **'Shared action between characters'**
  String get helpShortcutMutualAction;

  /// No description provided for @helpShortcutEnter.
  ///
  /// In en, this message translates to:
  /// **'Generate (or select tag suggestion)'**
  String get helpShortcutEnter;

  /// No description provided for @helpShortcutDragDrop.
  ///
  /// In en, this message translates to:
  /// **'Import generation settings'**
  String get helpShortcutDragDrop;

  /// No description provided for @helpFeatureGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get helpFeatureGallery;

  /// No description provided for @helpFeatureGalleryDesc.
  ///
  /// In en, this message translates to:
  /// **'Browse, favorite, compare, and album-sort outputs'**
  String get helpFeatureGalleryDesc;

  /// No description provided for @helpFeatureWildcards.
  ///
  /// In en, this message translates to:
  /// **'Wildcards'**
  String get helpFeatureWildcards;

  /// No description provided for @helpFeatureWildcardsDesc.
  ///
  /// In en, this message translates to:
  /// **'__pattern__ random substitution from text files'**
  String get helpFeatureWildcardsDesc;

  /// No description provided for @helpFeatureStyles.
  ///
  /// In en, this message translates to:
  /// **'Styles'**
  String get helpFeatureStyles;

  /// No description provided for @helpFeatureStylesDesc.
  ///
  /// In en, this message translates to:
  /// **'Auto-inject prefix/suffix/negative into prompts'**
  String get helpFeatureStylesDesc;

  /// No description provided for @helpFeaturePresets.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get helpFeaturePresets;

  /// No description provided for @helpFeaturePresetsDesc.
  ///
  /// In en, this message translates to:
  /// **'Save & restore full generation configurations'**
  String get helpFeaturePresetsDesc;

  /// No description provided for @helpFeatureDirectorRef.
  ///
  /// In en, this message translates to:
  /// **'Director Reference'**
  String get helpFeatureDirectorRef;

  /// No description provided for @helpFeatureDirectorRefDesc.
  ///
  /// In en, this message translates to:
  /// **'Guide character/style appearance with ref images'**
  String get helpFeatureDirectorRefDesc;

  /// No description provided for @helpFeatureVibeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Vibe Transfer'**
  String get helpFeatureVibeTransfer;

  /// No description provided for @helpFeatureVibeTransferDesc.
  ///
  /// In en, this message translates to:
  /// **'Influence composition & mood with ref images'**
  String get helpFeatureVibeTransferDesc;

  /// No description provided for @helpFeatureCascade.
  ///
  /// In en, this message translates to:
  /// **'Cascade'**
  String get helpFeatureCascade;

  /// No description provided for @helpFeatureCascadeDesc.
  ///
  /// In en, this message translates to:
  /// **'Multi-beat sequential scene generation'**
  String get helpFeatureCascadeDesc;

  /// No description provided for @helpFeatureImg2img.
  ///
  /// In en, this message translates to:
  /// **'IMG2IMG'**
  String get helpFeatureImg2img;

  /// No description provided for @helpFeatureImg2imgDesc.
  ///
  /// In en, this message translates to:
  /// **'Edit/refine images with inpainting & variation'**
  String get helpFeatureImg2imgDesc;

  /// No description provided for @helpFeatureThemes.
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get helpFeatureThemes;

  /// No description provided for @helpFeatureThemesDesc.
  ///
  /// In en, this message translates to:
  /// **'Customize all colors, fonts, and scale'**
  String get helpFeatureThemesDesc;

  /// No description provided for @helpFeaturePacks.
  ///
  /// In en, this message translates to:
  /// **'Packs'**
  String get helpFeaturePacks;

  /// No description provided for @helpFeaturePacksDesc.
  ///
  /// In en, this message translates to:
  /// **'Export/import presets, styles, wildcards as .vpack'**
  String get helpFeaturePacksDesc;

  /// No description provided for @wildcardManager.
  ///
  /// In en, this message translates to:
  /// **'WILDCARD MANAGER'**
  String get wildcardManager;

  /// No description provided for @wildcardManageDesc.
  ///
  /// In en, this message translates to:
  /// **'MANAGE AND EDIT YOUR WILDCARD FILES'**
  String get wildcardManageDesc;

  /// No description provided for @wildcardFiles.
  ///
  /// In en, this message translates to:
  /// **'FILES'**
  String get wildcardFiles;

  /// No description provided for @wildcardNew.
  ///
  /// In en, this message translates to:
  /// **'NEW WILDCARD'**
  String get wildcardNew;

  /// No description provided for @wildcardSelectOrCreate.
  ///
  /// In en, this message translates to:
  /// **'SELECT OR CREATE A WILDCARD FILE'**
  String get wildcardSelectOrCreate;

  /// No description provided for @wildcardValidateTags.
  ///
  /// In en, this message translates to:
  /// **'VALIDATE TAGS'**
  String get wildcardValidateTags;

  /// No description provided for @wildcardRecognized.
  ///
  /// In en, this message translates to:
  /// **'{valid}/{total} RECOGNIZED'**
  String wildcardRecognized(int valid, int total);

  /// No description provided for @wildcardClear.
  ///
  /// In en, this message translates to:
  /// **'CLEAR'**
  String get wildcardClear;

  /// No description provided for @wildcardStartTyping.
  ///
  /// In en, this message translates to:
  /// **'START TYPING TAGS...'**
  String get wildcardStartTyping;

  /// No description provided for @wildcardUnrecognized.
  ///
  /// In en, this message translates to:
  /// **'{count} UNRECOGNIZED'**
  String wildcardUnrecognized(int count);

  /// No description provided for @wildcardCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'CREATE WILDCARD'**
  String get wildcardCreateTitle;

  /// No description provided for @wildcardFileName.
  ///
  /// In en, this message translates to:
  /// **'FILE NAME'**
  String get wildcardFileName;

  /// No description provided for @wildcardHelp.
  ///
  /// In en, this message translates to:
  /// **'WILDCARD HELP'**
  String get wildcardHelp;

  /// No description provided for @wildcardHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'WILDCARD HELP'**
  String get wildcardHelpTitle;

  /// No description provided for @wildcardHelpRandom.
  ///
  /// In en, this message translates to:
  /// **'__name__ picks a random line from that wildcard file'**
  String get wildcardHelpRandom;

  /// No description provided for @wildcardHelpDotSyntax.
  ///
  /// In en, this message translates to:
  /// **'Use dots for multi-word names'**
  String get wildcardHelpDotSyntax;

  /// No description provided for @wildcardHelpBrowse.
  ///
  /// In en, this message translates to:
  /// **'Type __ to browse and insert a wildcard from autocomplete'**
  String get wildcardHelpBrowse;

  /// No description provided for @wildcardHelpNesting.
  ///
  /// In en, this message translates to:
  /// **'Nesting'**
  String get wildcardHelpNesting;

  /// No description provided for @wildcardHelpNestingDesc.
  ///
  /// In en, this message translates to:
  /// **'Wildcards can reference other wildcards (up to 5 levels deep)'**
  String get wildcardHelpNestingDesc;

  /// No description provided for @wildcardHelpTip.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder files — the order is used in autocomplete'**
  String get wildcardHelpTip;

  /// No description provided for @wildcardMode.
  ///
  /// In en, this message translates to:
  /// **'MODE'**
  String get wildcardMode;

  /// No description provided for @wildcardModeRandom.
  ///
  /// In en, this message translates to:
  /// **'RANDOM'**
  String get wildcardModeRandom;

  /// No description provided for @wildcardModeRandomDesc.
  ///
  /// In en, this message translates to:
  /// **'Picks a random line each time the wildcard is used'**
  String get wildcardModeRandomDesc;

  /// No description provided for @wildcardModeSequential.
  ///
  /// In en, this message translates to:
  /// **'SEQUENTIAL'**
  String get wildcardModeSequential;

  /// No description provided for @wildcardModeSequentialDesc.
  ///
  /// In en, this message translates to:
  /// **'Cycles through lines in order, looping back to the start'**
  String get wildcardModeSequentialDesc;

  /// No description provided for @wildcardModeShuffle.
  ///
  /// In en, this message translates to:
  /// **'SHUFFLE'**
  String get wildcardModeShuffle;

  /// No description provided for @wildcardModeShuffleDesc.
  ///
  /// In en, this message translates to:
  /// **'Shuffles all lines randomly, then cycles through without repeats'**
  String get wildcardModeShuffleDesc;

  /// No description provided for @wildcardModeWeighted.
  ///
  /// In en, this message translates to:
  /// **'WEIGHTED'**
  String get wildcardModeWeighted;

  /// No description provided for @wildcardModeWeightedDesc.
  ///
  /// In en, this message translates to:
  /// **'Uses weight syntax (e.g. 10::option) to bias selection probability'**
  String get wildcardModeWeightedDesc;

  /// No description provided for @wildcardHelpFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorited wildcards appear with a gold outline in tag completion'**
  String get wildcardHelpFavorites;

  /// No description provided for @tagLibTitle.
  ///
  /// In en, this message translates to:
  /// **'TAG LIBRARY'**
  String get tagLibTitle;

  /// No description provided for @tagLibPreviewSettings.
  ///
  /// In en, this message translates to:
  /// **'PREVIEW SETTINGS'**
  String get tagLibPreviewSettings;

  /// No description provided for @tagLibAddTag.
  ///
  /// In en, this message translates to:
  /// **'ADD TAG'**
  String get tagLibAddTag;

  /// No description provided for @tagLibSearchTags.
  ///
  /// In en, this message translates to:
  /// **'SEARCH TAGS...'**
  String get tagLibSearchTags;

  /// No description provided for @tagLibAll.
  ///
  /// In en, this message translates to:
  /// **'ALL'**
  String get tagLibAll;

  /// No description provided for @tagLibFavorites.
  ///
  /// In en, this message translates to:
  /// **'FAVORITES'**
  String get tagLibFavorites;

  /// No description provided for @tagLibImages.
  ///
  /// In en, this message translates to:
  /// **'IMAGES'**
  String get tagLibImages;

  /// No description provided for @tagLibSort.
  ///
  /// In en, this message translates to:
  /// **'SORT:'**
  String get tagLibSort;

  /// No description provided for @tagLibSortCountDesc.
  ///
  /// In en, this message translates to:
  /// **'COUNT ↓'**
  String get tagLibSortCountDesc;

  /// No description provided for @tagLibSortCountAsc.
  ///
  /// In en, this message translates to:
  /// **'COUNT ↑'**
  String get tagLibSortCountAsc;

  /// No description provided for @tagLibSortAZ.
  ///
  /// In en, this message translates to:
  /// **'A-Z'**
  String get tagLibSortAZ;

  /// No description provided for @tagLibSortZA.
  ///
  /// In en, this message translates to:
  /// **'Z-A'**
  String get tagLibSortZA;

  /// No description provided for @tagLibSortFavsFirst.
  ///
  /// In en, this message translates to:
  /// **'FAVS FIRST'**
  String get tagLibSortFavsFirst;

  /// No description provided for @tagLibTagCount.
  ///
  /// In en, this message translates to:
  /// **'{count} TAGS'**
  String tagLibTagCount(int count);

  /// No description provided for @tagLibDeleteTag.
  ///
  /// In en, this message translates to:
  /// **'DELETE TAG'**
  String get tagLibDeleteTag;

  /// No description provided for @tagLibRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'REMOVE \'{tag}\' FROM LIBRARY?'**
  String tagLibRemoveConfirm(String tag);

  /// No description provided for @tagLibTestTag.
  ///
  /// In en, this message translates to:
  /// **'TEST TAG'**
  String get tagLibTestTag;

  /// No description provided for @tagLibAddNewTag.
  ///
  /// In en, this message translates to:
  /// **'ADD NEW TAG'**
  String get tagLibAddNewTag;

  /// No description provided for @tagLibTagName.
  ///
  /// In en, this message translates to:
  /// **'TAG NAME'**
  String get tagLibTagName;

  /// No description provided for @tagLibCount.
  ///
  /// In en, this message translates to:
  /// **'COUNT'**
  String get tagLibCount;

  /// No description provided for @tagLibAddTagBtn.
  ///
  /// In en, this message translates to:
  /// **'ADD TAG'**
  String get tagLibAddTagBtn;

  /// No description provided for @tagLibDeleteExample.
  ///
  /// In en, this message translates to:
  /// **'DELETE EXAMPLE'**
  String get tagLibDeleteExample;

  /// No description provided for @tagLibDeleteExampleConfirm.
  ///
  /// In en, this message translates to:
  /// **'DELETE THIS VISUAL EXAMPLE?'**
  String get tagLibDeleteExampleConfirm;

  /// No description provided for @tagLibTesting.
  ///
  /// In en, this message translates to:
  /// **'TESTING: {tag}'**
  String tagLibTesting(String tag);

  /// No description provided for @tagLibGeneratingPreview.
  ///
  /// In en, this message translates to:
  /// **'GENERATING PREVIEW...'**
  String get tagLibGeneratingPreview;

  /// No description provided for @tagLibGenerationFailed.
  ///
  /// In en, this message translates to:
  /// **'GENERATION FAILED'**
  String get tagLibGenerationFailed;

  /// No description provided for @tagLibExampleSaved.
  ///
  /// In en, this message translates to:
  /// **'EXAMPLE SAVED'**
  String get tagLibExampleSaved;

  /// No description provided for @tagLibSaveAsExample.
  ///
  /// In en, this message translates to:
  /// **'SAVE AS EXAMPLE'**
  String get tagLibSaveAsExample;

  /// No description provided for @tagLibPreviewSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'PREVIEW SETTINGS'**
  String get tagLibPreviewSettingsTitle;

  /// No description provided for @tagLibPositivePromptBase.
  ///
  /// In en, this message translates to:
  /// **'POSITIVE PROMPT (BASE)'**
  String get tagLibPositivePromptBase;

  /// No description provided for @tagLibNegativePrompt.
  ///
  /// In en, this message translates to:
  /// **'NEGATIVE PROMPT'**
  String get tagLibNegativePrompt;

  /// No description provided for @tagLibSampler.
  ///
  /// In en, this message translates to:
  /// **'SAMPLER'**
  String get tagLibSampler;

  /// No description provided for @tagLibSteps.
  ///
  /// In en, this message translates to:
  /// **'STEPS'**
  String get tagLibSteps;

  /// No description provided for @tagLibWidth.
  ///
  /// In en, this message translates to:
  /// **'WIDTH'**
  String get tagLibWidth;

  /// No description provided for @tagLibHeight.
  ///
  /// In en, this message translates to:
  /// **'HEIGHT'**
  String get tagLibHeight;

  /// No description provided for @tagLibScale.
  ///
  /// In en, this message translates to:
  /// **'SCALE'**
  String get tagLibScale;

  /// No description provided for @tagLibSeed.
  ///
  /// In en, this message translates to:
  /// **'SEED'**
  String get tagLibSeed;

  /// No description provided for @tagLibRandom.
  ///
  /// In en, this message translates to:
  /// **'RANDOM'**
  String get tagLibRandom;

  /// No description provided for @presetManager.
  ///
  /// In en, this message translates to:
  /// **'PRESET MANAGER'**
  String get presetManager;

  /// No description provided for @presetManageDesc.
  ///
  /// In en, this message translates to:
  /// **'MANAGE AND EDIT YOUR GENERATION PRESETS'**
  String get presetManageDesc;

  /// No description provided for @presetList.
  ///
  /// In en, this message translates to:
  /// **'PRESETS'**
  String get presetList;

  /// No description provided for @presetNew.
  ///
  /// In en, this message translates to:
  /// **'NEW PRESET'**
  String get presetNew;

  /// No description provided for @presetCharsInfo.
  ///
  /// In en, this message translates to:
  /// **'{chars} CHARS, {ints} INTS'**
  String presetCharsInfo(int chars, int ints);

  /// No description provided for @presetCharsRefsInfo.
  ///
  /// In en, this message translates to:
  /// **'{chars} CHARS, {ints} INTS, {refs} REFS'**
  String presetCharsRefsInfo(int chars, int ints, int refs);

  /// No description provided for @presetSelectToEdit.
  ///
  /// In en, this message translates to:
  /// **'SELECT A PRESET TO EDIT'**
  String get presetSelectToEdit;

  /// No description provided for @presetIdentity.
  ///
  /// In en, this message translates to:
  /// **'IDENTITY'**
  String get presetIdentity;

  /// No description provided for @presetName.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get presetName;

  /// No description provided for @presetPrompts.
  ///
  /// In en, this message translates to:
  /// **'PROMPTS'**
  String get presetPrompts;

  /// No description provided for @presetPrompt.
  ///
  /// In en, this message translates to:
  /// **'PROMPT'**
  String get presetPrompt;

  /// No description provided for @presetNegativePrompt.
  ///
  /// In en, this message translates to:
  /// **'NEGATIVE PROMPT'**
  String get presetNegativePrompt;

  /// No description provided for @presetGenSettings.
  ///
  /// In en, this message translates to:
  /// **'GENERATION SETTINGS'**
  String get presetGenSettings;

  /// No description provided for @presetWidth.
  ///
  /// In en, this message translates to:
  /// **'WIDTH'**
  String get presetWidth;

  /// No description provided for @presetHeight.
  ///
  /// In en, this message translates to:
  /// **'HEIGHT'**
  String get presetHeight;

  /// No description provided for @presetScale.
  ///
  /// In en, this message translates to:
  /// **'SCALE'**
  String get presetScale;

  /// No description provided for @presetSteps.
  ///
  /// In en, this message translates to:
  /// **'STEPS'**
  String get presetSteps;

  /// No description provided for @presetSampler.
  ///
  /// In en, this message translates to:
  /// **'SAMPLER'**
  String get presetSampler;

  /// No description provided for @presetCharsAndInteractions.
  ///
  /// In en, this message translates to:
  /// **'CHARACTERS & INTERACTIONS'**
  String get presetCharsAndInteractions;

  /// No description provided for @presetNoChars.
  ///
  /// In en, this message translates to:
  /// **'NO CHARACTERS SAVED IN THIS PRESET'**
  String get presetNoChars;

  /// No description provided for @presetCharacterN.
  ///
  /// In en, this message translates to:
  /// **'CHARACTER {n}'**
  String presetCharacterN(int n);

  /// No description provided for @presetInteractions.
  ///
  /// In en, this message translates to:
  /// **'INTERACTIONS'**
  String get presetInteractions;

  /// No description provided for @presetReferences.
  ///
  /// In en, this message translates to:
  /// **'REFERENCES'**
  String get presetReferences;

  /// No description provided for @presetNoRefs.
  ///
  /// In en, this message translates to:
  /// **'NO REFERENCES SAVED IN THIS PRESET'**
  String get presetNoRefs;

  /// No description provided for @presetProcessing.
  ///
  /// In en, this message translates to:
  /// **'PROCESSING...'**
  String get presetProcessing;

  /// No description provided for @presetAddReference.
  ///
  /// In en, this message translates to:
  /// **'ADD REFERENCE'**
  String get presetAddReference;

  /// No description provided for @presetDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'DELETE PRESET'**
  String get presetDeleteTitle;

  /// No description provided for @presetDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'ARE YOU SURE YOU WANT TO DELETE \'\'{name}\'\'?'**
  String presetDeleteConfirm(String name);

  /// No description provided for @presetOverwriteTitle.
  ///
  /// In en, this message translates to:
  /// **'OVERWRITE PRESET'**
  String get presetOverwriteTitle;

  /// No description provided for @presetOverwriteConfirm.
  ///
  /// In en, this message translates to:
  /// **'A PRESET WITH THE NAME \'\'{name}\'\' ALREADY EXISTS. OVERWRITE?'**
  String presetOverwriteConfirm(String name);

  /// No description provided for @styleEditor.
  ///
  /// In en, this message translates to:
  /// **'STYLE EDITOR'**
  String get styleEditor;

  /// No description provided for @styleManageDesc.
  ///
  /// In en, this message translates to:
  /// **'MANAGE PROMPT SNIPPETS AND STYLE TAGS'**
  String get styleManageDesc;

  /// No description provided for @styleList.
  ///
  /// In en, this message translates to:
  /// **'STYLES'**
  String get styleList;

  /// No description provided for @styleNew.
  ///
  /// In en, this message translates to:
  /// **'NEW STYLE'**
  String get styleNew;

  /// No description provided for @styleSelectToEdit.
  ///
  /// In en, this message translates to:
  /// **'SELECT A STYLE TO EDIT'**
  String get styleSelectToEdit;

  /// No description provided for @styleIdentity.
  ///
  /// In en, this message translates to:
  /// **'IDENTITY'**
  String get styleIdentity;

  /// No description provided for @styleName.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get styleName;

  /// No description provided for @styleDefaultOnLaunch.
  ///
  /// In en, this message translates to:
  /// **'DEFAULT ON LAUNCH'**
  String get styleDefaultOnLaunch;

  /// No description provided for @styleTargetPrompt.
  ///
  /// In en, this message translates to:
  /// **'TARGET PROMPT'**
  String get styleTargetPrompt;

  /// No description provided for @stylePositive.
  ///
  /// In en, this message translates to:
  /// **'POSITIVE'**
  String get stylePositive;

  /// No description provided for @styleNegative.
  ///
  /// In en, this message translates to:
  /// **'NEGATIVE'**
  String get styleNegative;

  /// No description provided for @styleNegativeContent.
  ///
  /// In en, this message translates to:
  /// **'NEGATIVE CONTENT'**
  String get styleNegativeContent;

  /// No description provided for @stylePositiveContent.
  ///
  /// In en, this message translates to:
  /// **'POSITIVE CONTENT'**
  String get stylePositiveContent;

  /// No description provided for @styleContent.
  ///
  /// In en, this message translates to:
  /// **'CONTENT'**
  String get styleContent;

  /// No description provided for @stylePlacement.
  ///
  /// In en, this message translates to:
  /// **'PLACEMENT'**
  String get stylePlacement;

  /// No description provided for @styleBeginningPrefix.
  ///
  /// In en, this message translates to:
  /// **'BEGINNING (PREFIX)'**
  String get styleBeginningPrefix;

  /// No description provided for @styleEndSuffix.
  ///
  /// In en, this message translates to:
  /// **'END (SUFFIX)'**
  String get styleEndSuffix;

  /// No description provided for @styleDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'DELETE STYLE'**
  String get styleDeleteTitle;

  /// No description provided for @styleDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'ARE YOU SURE YOU WANT TO DELETE \'\'{name}\'\'?'**
  String styleDeleteConfirm(String name);

  /// No description provided for @styleOverwriteTitle.
  ///
  /// In en, this message translates to:
  /// **'OVERWRITE STYLE'**
  String get styleOverwriteTitle;

  /// No description provided for @styleOverwriteConfirm.
  ///
  /// In en, this message translates to:
  /// **'A STYLE WITH THE NAME \'\'{name}\'\' ALREADY EXISTS. OVERWRITE?'**
  String styleOverwriteConfirm(String name);

  /// No description provided for @refPreciseReferences.
  ///
  /// In en, this message translates to:
  /// **'PRECISE REFERENCES'**
  String get refPreciseReferences;

  /// No description provided for @refVibeTransfer.
  ///
  /// In en, this message translates to:
  /// **'VIBE TRANSFER'**
  String get refVibeTransfer;

  /// No description provided for @refDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get refDialogCancel;

  /// No description provided for @refDialogSave.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get refDialogSave;

  /// No description provided for @refNameHint.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get refNameHint;

  /// No description provided for @refClearAll.
  ///
  /// In en, this message translates to:
  /// **'CLEAR ALL'**
  String get refClearAll;

  /// No description provided for @refSavedSection.
  ///
  /// In en, this message translates to:
  /// **'SAVED'**
  String get refSavedSection;

  /// No description provided for @refSaveReference.
  ///
  /// In en, this message translates to:
  /// **'SAVE REFERENCE'**
  String get refSaveReference;

  /// No description provided for @refReferenceCount.
  ///
  /// In en, this message translates to:
  /// **'{count} REFERENCES'**
  String refReferenceCount(int count);

  /// No description provided for @refNoReferencesAdded.
  ///
  /// In en, this message translates to:
  /// **'NO REFERENCES ADDED'**
  String get refNoReferencesAdded;

  /// No description provided for @refEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload reference images to maintain character\nappearance or artistic style across generations.'**
  String get refEmptyDescription;

  /// No description provided for @refAddReference.
  ///
  /// In en, this message translates to:
  /// **'ADD REFERENCE'**
  String get refAddReference;

  /// No description provided for @refEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'REFERENCE EDITOR'**
  String get refEditorTitle;

  /// No description provided for @refTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'REFERENCE TYPE'**
  String get refTypeLabel;

  /// No description provided for @refStrength.
  ///
  /// In en, this message translates to:
  /// **'STRENGTH'**
  String get refStrength;

  /// No description provided for @refFidelity.
  ///
  /// In en, this message translates to:
  /// **'FIDELITY'**
  String get refFidelity;

  /// No description provided for @refStrengthShort.
  ///
  /// In en, this message translates to:
  /// **'STR'**
  String get refStrengthShort;

  /// No description provided for @refFidelityShort.
  ///
  /// In en, this message translates to:
  /// **'FID'**
  String get refFidelityShort;

  /// No description provided for @refTypeCharacter.
  ///
  /// In en, this message translates to:
  /// **'CHARACTER'**
  String get refTypeCharacter;

  /// No description provided for @refTypeStyle.
  ///
  /// In en, this message translates to:
  /// **'STYLE'**
  String get refTypeStyle;

  /// No description provided for @refTypeCharAndStyle.
  ///
  /// In en, this message translates to:
  /// **'CHAR & STYLE'**
  String get refTypeCharAndStyle;

  /// No description provided for @refSaveVibe.
  ///
  /// In en, this message translates to:
  /// **'SAVE VIBE'**
  String get refSaveVibe;

  /// No description provided for @refVibeTransfers.
  ///
  /// In en, this message translates to:
  /// **'VIBE TRANSFERS'**
  String get refVibeTransfers;

  /// No description provided for @refVibeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} VIBES'**
  String refVibeCount(int count);

  /// No description provided for @refNoVibesAdded.
  ///
  /// In en, this message translates to:
  /// **'NO VIBES ADDED'**
  String get refNoVibesAdded;

  /// No description provided for @refVibeEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload reference images to transfer artistic\nstyle and mood to your generations.'**
  String get refVibeEmptyDescription;

  /// No description provided for @refAddVibe.
  ///
  /// In en, this message translates to:
  /// **'ADD VIBE'**
  String get refAddVibe;

  /// No description provided for @refVibeLabel.
  ///
  /// In en, this message translates to:
  /// **'VIBE'**
  String get refVibeLabel;

  /// No description provided for @refVibeEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'VIBE EDITOR'**
  String get refVibeEditorTitle;

  /// No description provided for @refInfoExtracted.
  ///
  /// In en, this message translates to:
  /// **'INFO EXTRACTED'**
  String get refInfoExtracted;

  /// No description provided for @refInfoExtractedShort.
  ///
  /// In en, this message translates to:
  /// **'INF'**
  String get refInfoExtractedShort;

  /// No description provided for @refApiKeyMissing.
  ///
  /// In en, this message translates to:
  /// **'API key missing or invalid'**
  String get refApiKeyMissing;

  /// No description provided for @refVibeEncodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to encode vibe: {error}'**
  String refVibeEncodeFailed(String error);

  /// No description provided for @packTitle.
  ///
  /// In en, this message translates to:
  /// **'NAIWEAVER PACKS'**
  String get packTitle;

  /// No description provided for @packDesc.
  ///
  /// In en, this message translates to:
  /// **'Export and import presets, styles, and wildcards as .vpack files.'**
  String get packDesc;

  /// No description provided for @packExportLabel.
  ///
  /// In en, this message translates to:
  /// **'EXPORT PACK'**
  String get packExportLabel;

  /// No description provided for @packExportDesc.
  ///
  /// In en, this message translates to:
  /// **'Bundle presets, styles, and wildcards'**
  String get packExportDesc;

  /// No description provided for @packImportLabel.
  ///
  /// In en, this message translates to:
  /// **'IMPORT PACK'**
  String get packImportLabel;

  /// No description provided for @packImportDesc.
  ///
  /// In en, this message translates to:
  /// **'Load a .vpack file'**
  String get packImportDesc;

  /// No description provided for @packGalleryExport.
  ///
  /// In en, this message translates to:
  /// **'GALLERY EXPORT'**
  String get packGalleryExport;

  /// No description provided for @packGalleryExportDesc.
  ///
  /// In en, this message translates to:
  /// **'Export gallery images as a ZIP file, organized by album folders.'**
  String get packGalleryExportDesc;

  /// No description provided for @packExportGalleryZip.
  ///
  /// In en, this message translates to:
  /// **'EXPORT GALLERY AS ZIP'**
  String get packExportGalleryZip;

  /// No description provided for @packExportGalleryZipDesc.
  ///
  /// In en, this message translates to:
  /// **'Preserve album hierarchy in folders'**
  String get packExportGalleryZipDesc;

  /// No description provided for @packImportDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Import NAIWeaver Pack'**
  String get packImportDialogTitle;

  /// No description provided for @packFailedRead.
  ///
  /// In en, this message translates to:
  /// **'Failed to read pack: {error}'**
  String packFailedRead(String error);

  /// No description provided for @packExportDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'EXPORT PACK'**
  String get packExportDialogTitle;

  /// No description provided for @packName.
  ///
  /// In en, this message translates to:
  /// **'PACK NAME'**
  String get packName;

  /// No description provided for @packDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION (OPTIONAL)'**
  String get packDescriptionOptional;

  /// No description provided for @packPresetsSection.
  ///
  /// In en, this message translates to:
  /// **'PRESETS ({selected}/{total})'**
  String packPresetsSection(int selected, int total);

  /// No description provided for @packStylesSection.
  ///
  /// In en, this message translates to:
  /// **'STYLES ({selected}/{total})'**
  String packStylesSection(int selected, int total);

  /// No description provided for @packWildcardsSection.
  ///
  /// In en, this message translates to:
  /// **'WILDCARDS ({selected}/{total})'**
  String packWildcardsSection(int selected, int total);

  /// No description provided for @packExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Pack exported successfully'**
  String get packExportSuccess;

  /// No description provided for @packExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String packExportFailed(String error);

  /// No description provided for @packImportDialogTitle2.
  ///
  /// In en, this message translates to:
  /// **'IMPORT PACK'**
  String get packImportDialogTitle2;

  /// No description provided for @packImportCount.
  ///
  /// In en, this message translates to:
  /// **'IMPORT ({count})'**
  String packImportCount(int count);

  /// No description provided for @packImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Pack imported successfully'**
  String get packImportSuccess;

  /// No description provided for @packImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String packImportFailed(String error);

  /// No description provided for @packExportGalleryTitle.
  ///
  /// In en, this message translates to:
  /// **'EXPORT GALLERY'**
  String get packExportGalleryTitle;

  /// No description provided for @packAlbums.
  ///
  /// In en, this message translates to:
  /// **'ALBUMS'**
  String get packAlbums;

  /// No description provided for @packUnsortedCount.
  ///
  /// In en, this message translates to:
  /// **'UNSORTED ({count})'**
  String packUnsortedCount(int count);

  /// No description provided for @packOptions.
  ///
  /// In en, this message translates to:
  /// **'OPTIONS'**
  String get packOptions;

  /// No description provided for @packStripMetadata.
  ///
  /// In en, this message translates to:
  /// **'STRIP METADATA'**
  String get packStripMetadata;

  /// No description provided for @packFavoritesOnly.
  ///
  /// In en, this message translates to:
  /// **'FAVORITES ONLY'**
  String get packFavoritesOnly;

  /// No description provided for @packExportCount.
  ///
  /// In en, this message translates to:
  /// **'EXPORT ({count})'**
  String packExportCount(int count);

  /// No description provided for @packSaveDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Save NAIWeaver Pack'**
  String get packSaveDialogTitle;

  /// No description provided for @packExportGalleryZipDialog.
  ///
  /// In en, this message translates to:
  /// **'Export Gallery ZIP'**
  String get packExportGalleryZipDialog;

  /// No description provided for @packExportedToZip.
  ///
  /// In en, this message translates to:
  /// **'Exported {count} images to ZIP'**
  String packExportedToZip(int count);

  /// No description provided for @themeSelectToEdit.
  ///
  /// In en, this message translates to:
  /// **'SELECT A THEME TO EDIT'**
  String get themeSelectToEdit;

  /// No description provided for @themeList.
  ///
  /// In en, this message translates to:
  /// **'THEMES'**
  String get themeList;

  /// No description provided for @themeNew.
  ///
  /// In en, this message translates to:
  /// **'New Theme'**
  String get themeNew;

  /// No description provided for @themeSave.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get themeSave;

  /// No description provided for @themeReset.
  ///
  /// In en, this message translates to:
  /// **'RESET'**
  String get themeReset;

  /// No description provided for @themePreview.
  ///
  /// In en, this message translates to:
  /// **'PREVIEW'**
  String get themePreview;

  /// No description provided for @themeColors.
  ///
  /// In en, this message translates to:
  /// **'COLORS'**
  String get themeColors;

  /// No description provided for @themeColorBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get themeColorBackground;

  /// No description provided for @themeColorSurfaceHigh.
  ///
  /// In en, this message translates to:
  /// **'Surface High'**
  String get themeColorSurfaceHigh;

  /// No description provided for @themeColorSurfaceMid.
  ///
  /// In en, this message translates to:
  /// **'Surface Mid'**
  String get themeColorSurfaceMid;

  /// No description provided for @themeColorTextPrimary.
  ///
  /// In en, this message translates to:
  /// **'Text Primary'**
  String get themeColorTextPrimary;

  /// No description provided for @themeColorTextSecondary.
  ///
  /// In en, this message translates to:
  /// **'Text Secondary'**
  String get themeColorTextSecondary;

  /// No description provided for @themeColorTextTertiary.
  ///
  /// In en, this message translates to:
  /// **'Text Tertiary'**
  String get themeColorTextTertiary;

  /// No description provided for @themeColorTextDisabled.
  ///
  /// In en, this message translates to:
  /// **'Text Disabled'**
  String get themeColorTextDisabled;

  /// No description provided for @themeColorTextMinimal.
  ///
  /// In en, this message translates to:
  /// **'Text Minimal'**
  String get themeColorTextMinimal;

  /// No description provided for @themeColorBorderStrong.
  ///
  /// In en, this message translates to:
  /// **'Border Strong'**
  String get themeColorBorderStrong;

  /// No description provided for @themeColorBorderMedium.
  ///
  /// In en, this message translates to:
  /// **'Border Medium'**
  String get themeColorBorderMedium;

  /// No description provided for @themeColorBorderSubtle.
  ///
  /// In en, this message translates to:
  /// **'Border Subtle'**
  String get themeColorBorderSubtle;

  /// No description provided for @themeColorAccent.
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get themeColorAccent;

  /// No description provided for @themeColorAccentEdit.
  ///
  /// In en, this message translates to:
  /// **'Accent Edit'**
  String get themeColorAccentEdit;

  /// No description provided for @themeColorAccentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Accent Success'**
  String get themeColorAccentSuccess;

  /// No description provided for @themeColorAccentDanger.
  ///
  /// In en, this message translates to:
  /// **'Accent Danger'**
  String get themeColorAccentDanger;

  /// No description provided for @themeColorLogo.
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get themeColorLogo;

  /// No description provided for @themeColorCascade.
  ///
  /// In en, this message translates to:
  /// **'Cascade'**
  String get themeColorCascade;

  /// No description provided for @themeReferences.
  ///
  /// In en, this message translates to:
  /// **'REFERENCES'**
  String get themeReferences;

  /// No description provided for @themeColorVibeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Vibe Transfer'**
  String get themeColorVibeTransfer;

  /// No description provided for @themeColorRefCharacter.
  ///
  /// In en, this message translates to:
  /// **'Ref Character'**
  String get themeColorRefCharacter;

  /// No description provided for @themeColorRefStyle.
  ///
  /// In en, this message translates to:
  /// **'Ref Style'**
  String get themeColorRefStyle;

  /// No description provided for @themeColorRefCharStyle.
  ///
  /// In en, this message translates to:
  /// **'Ref Char+Style'**
  String get themeColorRefCharStyle;

  /// No description provided for @themeColorFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get themeColorFavorite;

  /// No description provided for @themeColorCharacter.
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get themeColorCharacter;

  /// No description provided for @themeColorPositive.
  ///
  /// In en, this message translates to:
  /// **'Positive'**
  String get themeColorPositive;

  /// No description provided for @themeColorNegative.
  ///
  /// In en, this message translates to:
  /// **'Negative'**
  String get themeColorNegative;

  /// No description provided for @themeFont.
  ///
  /// In en, this message translates to:
  /// **'FONT'**
  String get themeFont;

  /// No description provided for @themeTextScale.
  ///
  /// In en, this message translates to:
  /// **'TEXT SCALE'**
  String get themeTextScale;

  /// No description provided for @themeSmall.
  ///
  /// In en, this message translates to:
  /// **'SMALL'**
  String get themeSmall;

  /// No description provided for @themeLarge.
  ///
  /// In en, this message translates to:
  /// **'LARGE'**
  String get themeLarge;

  /// No description provided for @themePromptInput.
  ///
  /// In en, this message translates to:
  /// **'PROMPT INPUT'**
  String get themePromptInput;

  /// No description provided for @themeFontSize.
  ///
  /// In en, this message translates to:
  /// **'FONT SIZE'**
  String get themeFontSize;

  /// No description provided for @themeHeightLabel.
  ///
  /// In en, this message translates to:
  /// **'HEIGHT'**
  String get themeHeightLabel;

  /// No description provided for @themeLines.
  ///
  /// In en, this message translates to:
  /// **'{count} lines'**
  String themeLines(int count);

  /// No description provided for @themeBrightMode.
  ///
  /// In en, this message translates to:
  /// **'BRIGHT MODE'**
  String get themeBrightMode;

  /// No description provided for @themeBrightText.
  ///
  /// In en, this message translates to:
  /// **'BRIGHT TEXT'**
  String get themeBrightText;

  /// No description provided for @themeBrightDesc.
  ///
  /// In en, this message translates to:
  /// **'Use brighter text colors for improved readability'**
  String get themeBrightDesc;

  /// No description provided for @themePanelLayout.
  ///
  /// In en, this message translates to:
  /// **'PANEL LAYOUT'**
  String get themePanelLayout;

  /// No description provided for @themePanelLayoutDesc.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder Advanced Settings sections'**
  String get themePanelLayoutDesc;

  /// No description provided for @themeDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'DELETE THEME'**
  String get themeDeleteTitle;

  /// No description provided for @themeDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'ARE YOU SURE YOU WANT TO DELETE \'\'{name}\'\'?'**
  String themeDeleteConfirm(String name);

  /// No description provided for @themeNewTitle.
  ///
  /// In en, this message translates to:
  /// **'NEW THEME'**
  String get themeNewTitle;

  /// No description provided for @themeCustomTheme.
  ///
  /// In en, this message translates to:
  /// **'Custom Theme'**
  String get themeCustomTheme;

  /// No description provided for @themeThemeName.
  ///
  /// In en, this message translates to:
  /// **'THEME NAME'**
  String get themeThemeName;

  /// No description provided for @themeCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create theme: {error}'**
  String themeCreateFailed(String error);

  /// No description provided for @themeSectionDimSeed.
  ///
  /// In en, this message translates to:
  /// **'DIMENSIONS + SEED'**
  String get themeSectionDimSeed;

  /// No description provided for @themeSectionStepsScale.
  ///
  /// In en, this message translates to:
  /// **'STEPS + SCALE'**
  String get themeSectionStepsScale;

  /// No description provided for @themeSectionSamplerPost.
  ///
  /// In en, this message translates to:
  /// **'SAMPLER + POST-PROCESSING'**
  String get themeSectionSamplerPost;

  /// No description provided for @themeSectionStyles.
  ///
  /// In en, this message translates to:
  /// **'STYLES'**
  String get themeSectionStyles;

  /// No description provided for @themeSectionNegPrompt.
  ///
  /// In en, this message translates to:
  /// **'NEGATIVE PROMPT'**
  String get themeSectionNegPrompt;

  /// No description provided for @themeSectionPresets.
  ///
  /// In en, this message translates to:
  /// **'PRESETS'**
  String get themeSectionPresets;

  /// No description provided for @themeSectionSaveAlbum.
  ///
  /// In en, this message translates to:
  /// **'SAVE TO ALBUM'**
  String get themeSectionSaveAlbum;

  /// No description provided for @themePreviewHeader.
  ///
  /// In en, this message translates to:
  /// **'HEADER TEXT'**
  String get themePreviewHeader;

  /// No description provided for @themePreviewSecondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary text content'**
  String get themePreviewSecondary;

  /// No description provided for @themePreviewHint.
  ///
  /// In en, this message translates to:
  /// **'Hint / tertiary text'**
  String get themePreviewHint;

  /// No description provided for @themePreviewGenerate.
  ///
  /// In en, this message translates to:
  /// **'GENERATE'**
  String get themePreviewGenerate;

  /// No description provided for @themePreviewEdit.
  ///
  /// In en, this message translates to:
  /// **'EDIT'**
  String get themePreviewEdit;

  /// No description provided for @cascadeEditorLabel.
  ///
  /// In en, this message translates to:
  /// **'CASCADE EDITOR'**
  String get cascadeEditorLabel;

  /// No description provided for @cascadeSavedToLibrary.
  ///
  /// In en, this message translates to:
  /// **'CASCADE SAVED TO LIBRARY'**
  String get cascadeSavedToLibrary;

  /// No description provided for @cascadeNoBeatSelected.
  ///
  /// In en, this message translates to:
  /// **'NO BEAT SELECTED'**
  String get cascadeNoBeatSelected;

  /// No description provided for @cascadeEnvironmentPrompt.
  ///
  /// In en, this message translates to:
  /// **'ENVIRONMENT PROMPT'**
  String get cascadeEnvironmentPrompt;

  /// No description provided for @cascadeEnvHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. outdoors, forest, night, cinematic lighting'**
  String get cascadeEnvHint;

  /// No description provided for @cascadeCharacterSlots.
  ///
  /// In en, this message translates to:
  /// **'CHARACTER SLOTS'**
  String get cascadeCharacterSlots;

  /// No description provided for @cascadeCharacterSlotN.
  ///
  /// In en, this message translates to:
  /// **'CHARACTER SLOT {n}'**
  String cascadeCharacterSlotN(int n);

  /// No description provided for @cascadePosition.
  ///
  /// In en, this message translates to:
  /// **'POSITION'**
  String get cascadePosition;

  /// No description provided for @cascadeAiPosition.
  ///
  /// In en, this message translates to:
  /// **'AI POSITION'**
  String get cascadeAiPosition;

  /// No description provided for @cascadePositivePrompt.
  ///
  /// In en, this message translates to:
  /// **'POSITIVE PROMPT'**
  String get cascadePositivePrompt;

  /// No description provided for @cascadeCharHint.
  ///
  /// In en, this message translates to:
  /// **'Character tags, appearance, state...'**
  String get cascadeCharHint;

  /// No description provided for @cascadeNegativePrompt.
  ///
  /// In en, this message translates to:
  /// **'NEGATIVE PROMPT'**
  String get cascadeNegativePrompt;

  /// No description provided for @cascadeAvoidHint.
  ///
  /// In en, this message translates to:
  /// **'Avoid tags...'**
  String get cascadeAvoidHint;

  /// No description provided for @cascadeLinkAction.
  ///
  /// In en, this message translates to:
  /// **'Link Action'**
  String get cascadeLinkAction;

  /// No description provided for @cascadeBeatSettings.
  ///
  /// In en, this message translates to:
  /// **'BEAT SETTINGS'**
  String get cascadeBeatSettings;

  /// No description provided for @cascadeResolution.
  ///
  /// In en, this message translates to:
  /// **'RESOLUTION'**
  String get cascadeResolution;

  /// No description provided for @cascadeSampler.
  ///
  /// In en, this message translates to:
  /// **'SAMPLER'**
  String get cascadeSampler;

  /// No description provided for @cascadeSteps.
  ///
  /// In en, this message translates to:
  /// **'STEPS'**
  String get cascadeSteps;

  /// No description provided for @cascadeScale.
  ///
  /// In en, this message translates to:
  /// **'SCALE'**
  String get cascadeScale;

  /// No description provided for @cascadeStyles.
  ///
  /// In en, this message translates to:
  /// **'STYLES'**
  String get cascadeStyles;

  /// No description provided for @cascadeNoStyles.
  ///
  /// In en, this message translates to:
  /// **'NO STYLES AVAILABLE'**
  String get cascadeNoStyles;

  /// No description provided for @cascadeLibrary.
  ///
  /// In en, this message translates to:
  /// **'CASCADE LIBRARY'**
  String get cascadeLibrary;

  /// No description provided for @cascadeSequencesSaved.
  ///
  /// In en, this message translates to:
  /// **'{count} SEQUENCES SAVED'**
  String cascadeSequencesSaved(int count);

  /// No description provided for @cascadeNew.
  ///
  /// In en, this message translates to:
  /// **'NEW CASCADE'**
  String get cascadeNew;

  /// No description provided for @cascadeNoCascades.
  ///
  /// In en, this message translates to:
  /// **'NO CASCADES FOUND'**
  String get cascadeNoCascades;

  /// No description provided for @cascadeBeatsAndSlots.
  ///
  /// In en, this message translates to:
  /// **'{beats} BEATS • {slots} CHARACTER SLOTS'**
  String cascadeBeatsAndSlots(int beats, int slots);

  /// No description provided for @cascadeCreateNew.
  ///
  /// In en, this message translates to:
  /// **'CREATE NEW CASCADE'**
  String get cascadeCreateNew;

  /// No description provided for @cascadeName.
  ///
  /// In en, this message translates to:
  /// **'CASCADE NAME'**
  String get cascadeName;

  /// No description provided for @cascadeCharSlotsLabel.
  ///
  /// In en, this message translates to:
  /// **'CHARACTER SLOTS'**
  String get cascadeCharSlotsLabel;

  /// No description provided for @cascadeAutoPosition.
  ///
  /// In en, this message translates to:
  /// **'AUTO POSITION (LET AI DECIDE)'**
  String get cascadeAutoPosition;

  /// No description provided for @cascadeDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'DELETE CASCADE?'**
  String get cascadeDeleteTitle;

  /// No description provided for @cascadeDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String cascadeDeleteConfirm(String name);

  /// No description provided for @cascadeSelect.
  ///
  /// In en, this message translates to:
  /// **'SELECT CASCADE'**
  String get cascadeSelect;

  /// No description provided for @cascadeNoSaved.
  ///
  /// In en, this message translates to:
  /// **'NO SAVED CASCADES FOUND'**
  String get cascadeNoSaved;

  /// No description provided for @cascadeCharactersAndBeats.
  ///
  /// In en, this message translates to:
  /// **'{chars} CHARACTERS • {beats} BEATS'**
  String cascadeCharactersAndBeats(int chars, int beats);

  /// No description provided for @cascadeCharTags.
  ///
  /// In en, this message translates to:
  /// **'CHAR {n} TAGS'**
  String cascadeCharTags(int n);

  /// No description provided for @cascadeGlobalStyle.
  ///
  /// In en, this message translates to:
  /// **'GLOBAL STYLE / INJECTION'**
  String get cascadeGlobalStyle;

  /// No description provided for @cascadeRegenerateBeat.
  ///
  /// In en, this message translates to:
  /// **'REGENERATE BEAT {n}'**
  String cascadeRegenerateBeat(int n);

  /// No description provided for @cascadeGenerateBeat.
  ///
  /// In en, this message translates to:
  /// **'GENERATE BEAT {n}'**
  String cascadeGenerateBeat(int n);

  /// No description provided for @cascadeSkipToNext.
  ///
  /// In en, this message translates to:
  /// **'Skip to next'**
  String get cascadeSkipToNext;

  /// No description provided for @cascadeStartCasting.
  ///
  /// In en, this message translates to:
  /// **'Cast'**
  String get cascadeStartCasting;

  /// No description provided for @cascadeBackToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get cascadeBackToLibrary;

  /// No description provided for @cascadeUnsavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get cascadeUnsavedTitle;

  /// No description provided for @cascadeUnsavedMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes to this cascade. Discard them?'**
  String get cascadeUnsavedMessage;

  /// No description provided for @cascadeDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get cascadeDiscard;

  /// No description provided for @cascadeExitCascade.
  ///
  /// In en, this message translates to:
  /// **'Exit Cascade'**
  String get cascadeExitCascade;

  /// No description provided for @img2imgResult.
  ///
  /// In en, this message translates to:
  /// **'RESULT'**
  String get img2imgResult;

  /// No description provided for @img2imgSource.
  ///
  /// In en, this message translates to:
  /// **'SOURCE'**
  String get img2imgSource;

  /// No description provided for @img2imgCanvas.
  ///
  /// In en, this message translates to:
  /// **'CANVAS'**
  String get img2imgCanvas;

  /// No description provided for @img2imgUseAsSource.
  ///
  /// In en, this message translates to:
  /// **'USE AS SOURCE'**
  String get img2imgUseAsSource;

  /// No description provided for @img2imgInpainting.
  ///
  /// In en, this message translates to:
  /// **'INPAINTING'**
  String get img2imgInpainting;

  /// No description provided for @img2imgTitle.
  ///
  /// In en, this message translates to:
  /// **'IMG2IMG'**
  String get img2imgTitle;

  /// No description provided for @img2imgEditorLabel.
  ///
  /// In en, this message translates to:
  /// **'EDITOR'**
  String get img2imgEditorLabel;

  /// No description provided for @img2imgBackToPicker.
  ///
  /// In en, this message translates to:
  /// **'Back to picker'**
  String get img2imgBackToPicker;

  /// No description provided for @img2imgGenerating.
  ///
  /// In en, this message translates to:
  /// **'GENERATING...'**
  String get img2imgGenerating;

  /// No description provided for @img2imgGenerate.
  ///
  /// In en, this message translates to:
  /// **'GENERATE'**
  String get img2imgGenerate;

  /// No description provided for @img2imgGenerationFailed.
  ///
  /// In en, this message translates to:
  /// **'Generation failed: {error}'**
  String img2imgGenerationFailed(String error);

  /// No description provided for @img2imgSettings.
  ///
  /// In en, this message translates to:
  /// **'IMG2IMG SETTINGS'**
  String get img2imgSettings;

  /// No description provided for @img2imgPrompt.
  ///
  /// In en, this message translates to:
  /// **'PROMPT'**
  String get img2imgPrompt;

  /// No description provided for @img2imgPromptHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what to generate...'**
  String get img2imgPromptHint;

  /// No description provided for @img2imgNegative.
  ///
  /// In en, this message translates to:
  /// **'NEGATIVE'**
  String get img2imgNegative;

  /// No description provided for @img2imgNegativeHint.
  ///
  /// In en, this message translates to:
  /// **'Undesired content...'**
  String get img2imgNegativeHint;

  /// No description provided for @img2imgStrength.
  ///
  /// In en, this message translates to:
  /// **'STRENGTH'**
  String get img2imgStrength;

  /// No description provided for @img2imgNoise.
  ///
  /// In en, this message translates to:
  /// **'NOISE'**
  String get img2imgNoise;

  /// No description provided for @img2imgMaskBlur.
  ///
  /// In en, this message translates to:
  /// **'MASK BLUR'**
  String get img2imgMaskBlur;

  /// No description provided for @img2imgColorCorrect.
  ///
  /// In en, this message translates to:
  /// **'COLOR CORRECT'**
  String get img2imgColorCorrect;

  /// No description provided for @img2imgSourceInfo.
  ///
  /// In en, this message translates to:
  /// **'SOURCE'**
  String get img2imgSourceInfo;

  /// No description provided for @img2imgMaskStrokes.
  ///
  /// In en, this message translates to:
  /// **'MASK: {count} strokes'**
  String img2imgMaskStrokes(int count);

  /// No description provided for @img2imgNoMask.
  ///
  /// In en, this message translates to:
  /// **'NO MASK (full img2img)'**
  String get img2imgNoMask;

  /// No description provided for @img2imgImportPrompt.
  ///
  /// In en, this message translates to:
  /// **'Import Prompt'**
  String get img2imgImportPrompt;

  /// No description provided for @img2imgImportPromptDesc.
  ///
  /// In en, this message translates to:
  /// **'Auto-fill prompt from source image metadata'**
  String get img2imgImportPromptDesc;

  /// No description provided for @img2imgUploadFromDevice.
  ///
  /// In en, this message translates to:
  /// **'UPLOAD FROM DEVICE'**
  String get img2imgUploadFromDevice;

  /// No description provided for @img2imgUploadFromDeviceDesc.
  ///
  /// In en, this message translates to:
  /// **'Pick an image from your photo library or files'**
  String get img2imgUploadFromDeviceDesc;

  /// No description provided for @img2imgBlankCanvas.
  ///
  /// In en, this message translates to:
  /// **'BLANK CANVAS'**
  String get img2imgBlankCanvas;

  /// No description provided for @img2imgBlankCanvasDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a blank image to draw on'**
  String get img2imgBlankCanvasDesc;

  /// No description provided for @img2imgBlankCanvasSize.
  ///
  /// In en, this message translates to:
  /// **'CANVAS SIZE'**
  String get img2imgBlankCanvasSize;

  /// No description provided for @slideshowTitle.
  ///
  /// In en, this message translates to:
  /// **'SLIDESHOW'**
  String get slideshowTitle;

  /// No description provided for @slideshowPlayAll.
  ///
  /// In en, this message translates to:
  /// **'PLAY ALL'**
  String get slideshowPlayAll;

  /// No description provided for @slideshowConfigs.
  ///
  /// In en, this message translates to:
  /// **'CONFIGS'**
  String get slideshowConfigs;

  /// No description provided for @slideshowNewConfig.
  ///
  /// In en, this message translates to:
  /// **'NEW CONFIG'**
  String get slideshowNewConfig;

  /// No description provided for @slideshowNoConfigs.
  ///
  /// In en, this message translates to:
  /// **'NO SLIDESHOW CONFIGS YET.\nTAP + TO CREATE ONE.'**
  String get slideshowNoConfigs;

  /// No description provided for @slideshowSelectOrCreate.
  ///
  /// In en, this message translates to:
  /// **'SELECT OR CREATE A SLIDESHOW CONFIG'**
  String get slideshowSelectOrCreate;

  /// No description provided for @slideshowNameLabel.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get slideshowNameLabel;

  /// No description provided for @slideshowSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'SOURCE'**
  String get slideshowSourceLabel;

  /// No description provided for @slideshowTransition.
  ///
  /// In en, this message translates to:
  /// **'TRANSITION'**
  String get slideshowTransition;

  /// No description provided for @slideshowTransitionDuration.
  ///
  /// In en, this message translates to:
  /// **'TRANSITION DURATION'**
  String get slideshowTransitionDuration;

  /// No description provided for @slideshowTiming.
  ///
  /// In en, this message translates to:
  /// **'TIMING'**
  String get slideshowTiming;

  /// No description provided for @slideshowSlideDuration.
  ///
  /// In en, this message translates to:
  /// **'SLIDE DURATION'**
  String get slideshowSlideDuration;

  /// No description provided for @slideshowKenBurns.
  ///
  /// In en, this message translates to:
  /// **'KEN BURNS EFFECT'**
  String get slideshowKenBurns;

  /// No description provided for @slideshowEnabled.
  ///
  /// In en, this message translates to:
  /// **'ENABLED'**
  String get slideshowEnabled;

  /// No description provided for @slideshowIntensity.
  ///
  /// In en, this message translates to:
  /// **'INTENSITY'**
  String get slideshowIntensity;

  /// No description provided for @slideshowManualZoom.
  ///
  /// In en, this message translates to:
  /// **'MANUAL ZOOM'**
  String get slideshowManualZoom;

  /// No description provided for @slideshowPlayback.
  ///
  /// In en, this message translates to:
  /// **'PLAYBACK'**
  String get slideshowPlayback;

  /// No description provided for @slideshowShuffle.
  ///
  /// In en, this message translates to:
  /// **'SHUFFLE'**
  String get slideshowShuffle;

  /// No description provided for @slideshowLoop.
  ///
  /// In en, this message translates to:
  /// **'LOOP'**
  String get slideshowLoop;

  /// No description provided for @slideshowDefault.
  ///
  /// In en, this message translates to:
  /// **'DEFAULT'**
  String get slideshowDefault;

  /// No description provided for @slideshowUseAsDefault.
  ///
  /// In en, this message translates to:
  /// **'USE AS DEFAULT SLIDESHOW'**
  String get slideshowUseAsDefault;

  /// No description provided for @slideshowPlay.
  ///
  /// In en, this message translates to:
  /// **'PLAY SLIDESHOW'**
  String get slideshowPlay;

  /// No description provided for @slideshowTransFade.
  ///
  /// In en, this message translates to:
  /// **'FADE'**
  String get slideshowTransFade;

  /// No description provided for @slideshowTransSlideL.
  ///
  /// In en, this message translates to:
  /// **'SLIDE L'**
  String get slideshowTransSlideL;

  /// No description provided for @slideshowTransSlideR.
  ///
  /// In en, this message translates to:
  /// **'SLIDE R'**
  String get slideshowTransSlideR;

  /// No description provided for @slideshowTransSlideUp.
  ///
  /// In en, this message translates to:
  /// **'SLIDE UP'**
  String get slideshowTransSlideUp;

  /// No description provided for @slideshowTransZoom.
  ///
  /// In en, this message translates to:
  /// **'ZOOM'**
  String get slideshowTransZoom;

  /// No description provided for @slideshowTransXZoom.
  ///
  /// In en, this message translates to:
  /// **'X-ZOOM'**
  String get slideshowTransXZoom;

  /// No description provided for @slideshowSourceAllImages.
  ///
  /// In en, this message translates to:
  /// **'ALL IMAGES'**
  String get slideshowSourceAllImages;

  /// No description provided for @slideshowSourceAlbum.
  ///
  /// In en, this message translates to:
  /// **'ALBUM'**
  String get slideshowSourceAlbum;

  /// No description provided for @slideshowSourceFavorites.
  ///
  /// In en, this message translates to:
  /// **'FAVORITES'**
  String get slideshowSourceFavorites;

  /// No description provided for @slideshowSourceCustom.
  ///
  /// In en, this message translates to:
  /// **'{count} CUSTOM'**
  String slideshowSourceCustom(int count);

  /// No description provided for @slideshowDeleteConfig.
  ///
  /// In en, this message translates to:
  /// **'DELETE CONFIG'**
  String get slideshowDeleteConfig;

  /// No description provided for @slideshowDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'DELETE \'\'{name}\'\'?'**
  String slideshowDeleteConfirm(String name);

  /// No description provided for @slideshowImageSource.
  ///
  /// In en, this message translates to:
  /// **'IMAGE SOURCE'**
  String get slideshowImageSource;

  /// No description provided for @slideshowAllImages.
  ///
  /// In en, this message translates to:
  /// **'ALL IMAGES'**
  String get slideshowAllImages;

  /// No description provided for @slideshowImageCount.
  ///
  /// In en, this message translates to:
  /// **'{count} images'**
  String slideshowImageCount(int count);

  /// No description provided for @slideshowFavoritesLabel.
  ///
  /// In en, this message translates to:
  /// **'FAVORITES'**
  String get slideshowFavoritesLabel;

  /// No description provided for @slideshowAlbumLabel.
  ///
  /// In en, this message translates to:
  /// **'ALBUM'**
  String get slideshowAlbumLabel;

  /// No description provided for @slideshowCustomSelection.
  ///
  /// In en, this message translates to:
  /// **'CUSTOM SELECTION'**
  String get slideshowCustomSelection;

  /// No description provided for @slideshowSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String slideshowSelectedCount(int count);

  /// No description provided for @slideshowNoAlbums.
  ///
  /// In en, this message translates to:
  /// **'NO ALBUMS CREATED'**
  String get slideshowNoAlbums;

  /// No description provided for @slideshowSelectAlbum.
  ///
  /// In en, this message translates to:
  /// **'SELECT ALBUM'**
  String get slideshowSelectAlbum;

  /// No description provided for @slideshowCustomCount.
  ///
  /// In en, this message translates to:
  /// **'{selected} / {total} SELECTED'**
  String slideshowCustomCount(int selected, int total);

  /// No description provided for @slideshowDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'DESELECT ALL'**
  String get slideshowDeselectAll;

  /// No description provided for @slideshowSelectAll.
  ///
  /// In en, this message translates to:
  /// **'SELECT ALL'**
  String get slideshowSelectAll;

  /// No description provided for @slideshowNoImages.
  ///
  /// In en, this message translates to:
  /// **'NO IMAGES TO SHOW'**
  String get slideshowNoImages;

  /// No description provided for @slideshowGoBack.
  ///
  /// In en, this message translates to:
  /// **'GO BACK'**
  String get slideshowGoBack;

  /// No description provided for @demoImagesSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} IMAGES SELECTED'**
  String demoImagesSelected(int count);

  /// No description provided for @demoAll.
  ///
  /// In en, this message translates to:
  /// **'ALL'**
  String get demoAll;

  /// No description provided for @demoClear.
  ///
  /// In en, this message translates to:
  /// **'CLEAR'**
  String get demoClear;

  /// No description provided for @demoNoImages.
  ///
  /// In en, this message translates to:
  /// **'NO IMAGES IN GALLERY'**
  String get demoNoImages;

  /// No description provided for @cascadeBeatTimeline.
  ///
  /// In en, this message translates to:
  /// **'BEAT TIMELINE'**
  String get cascadeBeatTimeline;

  /// No description provided for @cascadeBeatsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} BEATS'**
  String cascadeBeatsCount(int count);

  /// No description provided for @cascadeBeatN.
  ///
  /// In en, this message translates to:
  /// **'BEAT {n}'**
  String cascadeBeatN(int n);

  /// No description provided for @cascadeCloneBeat.
  ///
  /// In en, this message translates to:
  /// **'Clone Beat'**
  String get cascadeCloneBeat;

  /// No description provided for @cascadeRemoveBeat.
  ///
  /// In en, this message translates to:
  /// **'Remove Beat'**
  String get cascadeRemoveBeat;

  /// No description provided for @settingsCheckForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get settingsCheckForUpdates;

  /// No description provided for @settingsUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get settingsUpdateAvailable;

  /// No description provided for @settingsUpdateAvailableDesc.
  ///
  /// In en, this message translates to:
  /// **'A new version ({version}) is available.'**
  String settingsUpdateAvailableDesc(String version);

  /// No description provided for @settingsUpdateDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get settingsUpdateDownload;

  /// No description provided for @settingsUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You\'re up to date!'**
  String get settingsUpToDate;

  /// No description provided for @settingsUpdateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Update check failed'**
  String get settingsUpdateCheckFailed;

  /// No description provided for @mainAnlas.
  ///
  /// In en, this message translates to:
  /// **'Anlas'**
  String get mainAnlas;

  /// No description provided for @settingsAnlasTracker.
  ///
  /// In en, this message translates to:
  /// **'Anlas Tracker'**
  String get settingsAnlasTracker;

  /// No description provided for @settingsAnlasTrackerDesc.
  ///
  /// In en, this message translates to:
  /// **'Show your Anlas balance in the top bar'**
  String get settingsAnlasTrackerDesc;

  /// No description provided for @canvasEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'CANVAS EDITOR'**
  String get canvasEditorTitle;

  /// No description provided for @canvasEditInCanvas.
  ///
  /// In en, this message translates to:
  /// **'CANVAS'**
  String get canvasEditInCanvas;

  /// No description provided for @canvasPaint.
  ///
  /// In en, this message translates to:
  /// **'PAINT'**
  String get canvasPaint;

  /// No description provided for @canvasErase.
  ///
  /// In en, this message translates to:
  /// **'ERASE'**
  String get canvasErase;

  /// No description provided for @canvasSize.
  ///
  /// In en, this message translates to:
  /// **'SIZE'**
  String get canvasSize;

  /// No description provided for @canvasOpacity.
  ///
  /// In en, this message translates to:
  /// **'OPACITY'**
  String get canvasOpacity;

  /// No description provided for @canvasUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get canvasUndo;

  /// No description provided for @canvasRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get canvasRedo;

  /// No description provided for @canvasClear.
  ///
  /// In en, this message translates to:
  /// **'Clear all strokes'**
  String get canvasClear;

  /// No description provided for @canvasFlatten.
  ///
  /// In en, this message translates to:
  /// **'FLATTEN'**
  String get canvasFlatten;

  /// No description provided for @canvasFlattenSend.
  ///
  /// In en, this message translates to:
  /// **'FLATTEN & SEND'**
  String get canvasFlattenSend;

  /// No description provided for @canvasBack.
  ///
  /// In en, this message translates to:
  /// **'Back to img2img'**
  String get canvasBack;

  /// No description provided for @canvasDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'DISCARD CHANGES?'**
  String get canvasDiscardTitle;

  /// No description provided for @canvasDiscardMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved paint strokes. Discard them?'**
  String get canvasDiscardMessage;

  /// No description provided for @canvasDiscard.
  ///
  /// In en, this message translates to:
  /// **'DISCARD'**
  String get canvasDiscard;

  /// No description provided for @canvasFlattenFailed.
  ///
  /// In en, this message translates to:
  /// **'Flatten failed: {error}'**
  String canvasFlattenFailed(String error);

  /// No description provided for @canvasFlattening.
  ///
  /// In en, this message translates to:
  /// **'FLATTENING...'**
  String get canvasFlattening;

  /// No description provided for @canvasRestoreSession.
  ///
  /// In en, this message translates to:
  /// **'A previous canvas session was found. Restore it?'**
  String get canvasRestoreSession;

  /// No description provided for @canvasRestore.
  ///
  /// In en, this message translates to:
  /// **'RESTORE'**
  String get canvasRestore;

  /// No description provided for @canvasAutoSave.
  ///
  /// In en, this message translates to:
  /// **'Canvas Auto-Save'**
  String get canvasAutoSave;

  /// No description provided for @canvasAutoSaveDesc.
  ///
  /// In en, this message translates to:
  /// **'Auto-save canvas editing sessions for crash recovery'**
  String get canvasAutoSaveDesc;

  /// No description provided for @canvasColor.
  ///
  /// In en, this message translates to:
  /// **'COLOR'**
  String get canvasColor;

  /// No description provided for @canvasLayers.
  ///
  /// In en, this message translates to:
  /// **'LAYERS'**
  String get canvasLayers;

  /// No description provided for @canvasLayerAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Layer'**
  String get canvasLayerAdd;

  /// No description provided for @canvasLayerDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Layer'**
  String get canvasLayerDelete;

  /// No description provided for @canvasLayerDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Layer'**
  String get canvasLayerDuplicate;

  /// No description provided for @canvasLayerRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get canvasLayerRename;

  /// No description provided for @canvasLayerVisible.
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get canvasLayerVisible;

  /// No description provided for @canvasLayerHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get canvasLayerHidden;

  /// No description provided for @canvasLayerOpacity.
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get canvasLayerOpacity;

  /// No description provided for @canvasLayerBlendMode.
  ///
  /// In en, this message translates to:
  /// **'Blend'**
  String get canvasLayerBlendMode;

  /// No description provided for @canvasLayerDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this layer? Strokes will be lost.'**
  String get canvasLayerDeleteConfirm;

  /// No description provided for @canvasLayerDefault.
  ///
  /// In en, this message translates to:
  /// **'Layer {number}'**
  String canvasLayerDefault(int number);

  /// No description provided for @canvasLayerClear.
  ///
  /// In en, this message translates to:
  /// **'Clear Layer'**
  String get canvasLayerClear;

  /// No description provided for @canvasLayerClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear all strokes on this layer?'**
  String get canvasLayerClearConfirm;

  /// No description provided for @canvasLine.
  ///
  /// In en, this message translates to:
  /// **'LINE'**
  String get canvasLine;

  /// No description provided for @canvasRectangle.
  ///
  /// In en, this message translates to:
  /// **'RECT'**
  String get canvasRectangle;

  /// No description provided for @canvasCircle.
  ///
  /// In en, this message translates to:
  /// **'CIRCLE'**
  String get canvasCircle;

  /// No description provided for @canvasEyedropper.
  ///
  /// In en, this message translates to:
  /// **'PICK'**
  String get canvasEyedropper;

  /// No description provided for @canvasTransform.
  ///
  /// In en, this message translates to:
  /// **'MOVE'**
  String get canvasTransform;

  /// No description provided for @canvasImportImage.
  ///
  /// In en, this message translates to:
  /// **'Import Image'**
  String get canvasImportImage;

  /// No description provided for @canvasSmooth.
  ///
  /// In en, this message translates to:
  /// **'SMOOTH'**
  String get canvasSmooth;

  /// No description provided for @canvasFill.
  ///
  /// In en, this message translates to:
  /// **'FILL'**
  String get canvasFill;

  /// No description provided for @canvasText.
  ///
  /// In en, this message translates to:
  /// **'TEXT'**
  String get canvasText;

  /// No description provided for @canvasTextHint.
  ///
  /// In en, this message translates to:
  /// **'Enter text...'**
  String get canvasTextHint;

  /// No description provided for @canvasTextSize.
  ///
  /// In en, this message translates to:
  /// **'SIZE'**
  String get canvasTextSize;

  /// No description provided for @canvasTextPlace.
  ///
  /// In en, this message translates to:
  /// **'PLACE'**
  String get canvasTextPlace;

  /// No description provided for @canvasTextFont.
  ///
  /// In en, this message translates to:
  /// **'FONT'**
  String get canvasTextFont;

  /// No description provided for @canvasTextSpacing.
  ///
  /// In en, this message translates to:
  /// **'SPACING'**
  String get canvasTextSpacing;

  /// No description provided for @canvasTextDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get canvasTextDefault;

  /// No description provided for @canvasBlendNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get canvasBlendNormal;

  /// No description provided for @canvasBlendMultiply.
  ///
  /// In en, this message translates to:
  /// **'Multiply'**
  String get canvasBlendMultiply;

  /// No description provided for @canvasBlendScreen.
  ///
  /// In en, this message translates to:
  /// **'Screen'**
  String get canvasBlendScreen;

  /// No description provided for @canvasBlendOverlay.
  ///
  /// In en, this message translates to:
  /// **'Overlay'**
  String get canvasBlendOverlay;

  /// No description provided for @settingsOutputFolder.
  ///
  /// In en, this message translates to:
  /// **'Output Folder'**
  String get settingsOutputFolder;

  /// No description provided for @settingsOutputFolderDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose where generated images are saved'**
  String get settingsOutputFolderDesc;

  /// No description provided for @settingsOutputFolderDefault.
  ///
  /// In en, this message translates to:
  /// **'Default (App Storage)'**
  String get settingsOutputFolderDefault;

  /// No description provided for @settingsOutputFolderBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get settingsOutputFolderBrowse;

  /// No description provided for @settingsOutputFolderClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settingsOutputFolderClear;

  /// No description provided for @resCustomEntry.
  ///
  /// In en, this message translates to:
  /// **'Custom...'**
  String get resCustomEntry;

  /// No description provided for @resCustomDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Resolution'**
  String get resCustomDialogTitle;

  /// No description provided for @resCustomWidth.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get resCustomWidth;

  /// No description provided for @resCustomHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get resCustomHeight;

  /// No description provided for @resCustomName.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get resCustomName;

  /// No description provided for @resCustomUseOnce.
  ///
  /// In en, this message translates to:
  /// **'Use Once'**
  String get resCustomUseOnce;

  /// No description provided for @resCustomSaveAndUse.
  ///
  /// In en, this message translates to:
  /// **'Save & Use'**
  String get resCustomSaveAndUse;

  /// No description provided for @resCustomMustBeMultiple.
  ///
  /// In en, this message translates to:
  /// **'Must be a multiple of 64'**
  String get resCustomMustBeMultiple;

  /// No description provided for @resCustomOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'Must be between 64 and 2048'**
  String get resCustomOutOfRange;

  /// No description provided for @themeSectionCharacters.
  ///
  /// In en, this message translates to:
  /// **'CHARACTERS'**
  String get themeSectionCharacters;

  /// No description provided for @charEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get charEditorTitle;

  /// No description provided for @charEditorExpanded.
  ///
  /// In en, this message translates to:
  /// **'EXPANDED'**
  String get charEditorExpanded;

  /// No description provided for @charEditorCompact.
  ///
  /// In en, this message translates to:
  /// **'COMPACT'**
  String get charEditorCompact;

  /// No description provided for @charEditorAutoPosition.
  ///
  /// In en, this message translates to:
  /// **'AUTO'**
  String get charEditorAutoPosition;

  /// No description provided for @charEditorUsingCompactShelf.
  ///
  /// In en, this message translates to:
  /// **'Using compact shelf below prompt'**
  String get charEditorUsingCompactShelf;

  /// No description provided for @charEditorCharacterName.
  ///
  /// In en, this message translates to:
  /// **'CHARACTER NAME'**
  String get charEditorCharacterName;

  /// No description provided for @charEditorPromptHint.
  ///
  /// In en, this message translates to:
  /// **'Character tags, appearance...'**
  String get charEditorPromptHint;

  /// No description provided for @charEditorUcHint.
  ///
  /// In en, this message translates to:
  /// **'Undesired tags...'**
  String get charEditorUcHint;

  /// No description provided for @charEditorShowUc.
  ///
  /// In en, this message translates to:
  /// **'UC'**
  String get charEditorShowUc;

  /// No description provided for @charEditorShowPosition.
  ///
  /// In en, this message translates to:
  /// **'POS'**
  String get charEditorShowPosition;

  /// No description provided for @charEditorShowPresets.
  ///
  /// In en, this message translates to:
  /// **'PRESET'**
  String get charEditorShowPresets;

  /// No description provided for @charEditorAiDecidesPosition.
  ///
  /// In en, this message translates to:
  /// **'AI decides position'**
  String get charEditorAiDecidesPosition;

  /// No description provided for @charEditorAddCharacter.
  ///
  /// In en, this message translates to:
  /// **'ADD CHARACTER'**
  String get charEditorAddCharacter;

  /// No description provided for @charEditorDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String charEditorDeleteConfirm(String name);

  /// No description provided for @charEditorDeleteCharacter.
  ///
  /// In en, this message translates to:
  /// **'DELETE CHARACTER'**
  String get charEditorDeleteCharacter;

  /// No description provided for @charEditorInteractions.
  ///
  /// In en, this message translates to:
  /// **'INTERACTIONS'**
  String get charEditorInteractions;

  /// No description provided for @charEditorAddInteraction.
  ///
  /// In en, this message translates to:
  /// **'ADD INTERACTION'**
  String get charEditorAddInteraction;

  /// No description provided for @charEditorInteractionDisplay.
  ///
  /// In en, this message translates to:
  /// **'{source} → {target}: {action}'**
  String charEditorInteractionDisplay(
    String source,
    String target,
    String action,
  );

  /// No description provided for @charEditorMutualDisplay.
  ///
  /// In en, this message translates to:
  /// **'{source} ↔ {target}: {action}'**
  String charEditorMutualDisplay(String source, String target, String action);

  /// No description provided for @charEditorSavePreset.
  ///
  /// In en, this message translates to:
  /// **'SAVE PRESET'**
  String get charEditorSavePreset;

  /// No description provided for @charEditorLoadPreset.
  ///
  /// In en, this message translates to:
  /// **'LOAD PRESET'**
  String get charEditorLoadPreset;

  /// No description provided for @charEditorPresetName.
  ///
  /// In en, this message translates to:
  /// **'Preset Name'**
  String get charEditorPresetName;

  /// No description provided for @charEditorNoPresets.
  ///
  /// In en, this message translates to:
  /// **'No character presets saved'**
  String get charEditorNoPresets;

  /// No description provided for @charEditorSelectSource.
  ///
  /// In en, this message translates to:
  /// **'Source Character'**
  String get charEditorSelectSource;

  /// No description provided for @charEditorSelectTarget.
  ///
  /// In en, this message translates to:
  /// **'Target Character'**
  String get charEditorSelectTarget;

  /// No description provided for @charEditorCharacterN.
  ///
  /// In en, this message translates to:
  /// **'Character {n}'**
  String charEditorCharacterN(int n);

  /// No description provided for @charEditorContinue.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get charEditorContinue;

  /// No description provided for @charEditorParticipants.
  ///
  /// In en, this message translates to:
  /// **'PARTICIPANTS'**
  String get charEditorParticipants;

  /// No description provided for @charEditorSourceTarget.
  ///
  /// In en, this message translates to:
  /// **'SOURCE → TARGET'**
  String get charEditorSourceTarget;

  /// No description provided for @charEditorMutual.
  ///
  /// In en, this message translates to:
  /// **'MUTUAL'**
  String get charEditorMutual;

  /// No description provided for @jukeboxTitle.
  ///
  /// In en, this message translates to:
  /// **'JUKEBOX'**
  String get jukeboxTitle;

  /// No description provided for @jukeboxShuffleAll.
  ///
  /// In en, this message translates to:
  /// **'SHUFFLE ALL'**
  String get jukeboxShuffleAll;

  /// No description provided for @jukeboxPlayAll.
  ///
  /// In en, this message translates to:
  /// **'PLAY ALL'**
  String get jukeboxPlayAll;

  /// No description provided for @jukeboxNoSongPlaying.
  ///
  /// In en, this message translates to:
  /// **'NO SONG PLAYING'**
  String get jukeboxNoSongPlaying;

  /// No description provided for @jukeboxNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'NOW PLAYING'**
  String get jukeboxNowPlaying;

  /// No description provided for @jukeboxSoundFont.
  ///
  /// In en, this message translates to:
  /// **'SOUNDFONT'**
  String get jukeboxSoundFont;

  /// No description provided for @jukeboxSettings.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get jukeboxSettings;

  /// No description provided for @jukeboxQueue.
  ///
  /// In en, this message translates to:
  /// **'QUEUE'**
  String get jukeboxQueue;

  /// No description provided for @jukeboxQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'QUEUE IS EMPTY'**
  String get jukeboxQueueEmpty;

  /// No description provided for @jukeboxRepeat.
  ///
  /// In en, this message translates to:
  /// **'REPEAT'**
  String get jukeboxRepeat;

  /// No description provided for @jukeboxShuffle.
  ///
  /// In en, this message translates to:
  /// **'SHUFFLE'**
  String get jukeboxShuffle;

  /// No description provided for @jukeboxOn.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get jukeboxOn;

  /// No description provided for @jukeboxOff.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get jukeboxOff;

  /// No description provided for @jukeboxAddToQueue.
  ///
  /// In en, this message translates to:
  /// **'Add to queue'**
  String get jukeboxAddToQueue;

  /// No description provided for @jukeboxMusicUnavailable.
  ///
  /// In en, this message translates to:
  /// **'MUSIC PLAYBACK UNAVAILABLE'**
  String get jukeboxMusicUnavailable;

  /// No description provided for @jukeboxDllMissing.
  ///
  /// In en, this message translates to:
  /// **'FluidSynth DLL not found'**
  String get jukeboxDllMissing;

  /// No description provided for @jukeboxCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'ALL'**
  String get jukeboxCategoryAll;

  /// No description provided for @jukeboxCategoryClassical.
  ///
  /// In en, this message translates to:
  /// **'CLASSICAL'**
  String get jukeboxCategoryClassical;

  /// No description provided for @jukeboxCategoryAnime.
  ///
  /// In en, this message translates to:
  /// **'ANIME'**
  String get jukeboxCategoryAnime;

  /// No description provided for @jukeboxCategoryGame.
  ///
  /// In en, this message translates to:
  /// **'GAME'**
  String get jukeboxCategoryGame;

  /// No description provided for @jukeboxCategoryJazz.
  ///
  /// In en, this message translates to:
  /// **'JAZZ'**
  String get jukeboxCategoryJazz;

  /// No description provided for @jukeboxCategoryAmbient.
  ///
  /// In en, this message translates to:
  /// **'AMBIENT'**
  String get jukeboxCategoryAmbient;

  /// No description provided for @jukeboxCategoryHoliday.
  ///
  /// In en, this message translates to:
  /// **'HOLIDAY'**
  String get jukeboxCategoryHoliday;

  /// No description provided for @jukeboxCategoryMeme.
  ///
  /// In en, this message translates to:
  /// **'MEME'**
  String get jukeboxCategoryMeme;

  /// No description provided for @jukeboxCategoryRock.
  ///
  /// In en, this message translates to:
  /// **'ROCK'**
  String get jukeboxCategoryRock;

  /// No description provided for @jukeboxEnableMusic.
  ///
  /// In en, this message translates to:
  /// **'ENABLE MUSIC'**
  String get jukeboxEnableMusic;

  /// No description provided for @jukeboxMusicVolume.
  ///
  /// In en, this message translates to:
  /// **'MUSIC VOLUME'**
  String get jukeboxMusicVolume;

  /// No description provided for @jukeboxKaraokeLyrics.
  ///
  /// In en, this message translates to:
  /// **'KARAOKE LYRICS'**
  String get jukeboxKaraokeLyrics;

  /// No description provided for @mlModels.
  ///
  /// In en, this message translates to:
  /// **'ML MODELS'**
  String get mlModels;

  /// No description provided for @mlBgRemoval.
  ///
  /// In en, this message translates to:
  /// **'BACKGROUND REMOVAL'**
  String get mlBgRemoval;

  /// No description provided for @mlUpscaling.
  ///
  /// In en, this message translates to:
  /// **'UPSCALING'**
  String get mlUpscaling;

  /// No description provided for @mlSegmentation.
  ///
  /// In en, this message translates to:
  /// **'SEGMENTATION'**
  String get mlSegmentation;

  /// No description provided for @mlDownload.
  ///
  /// In en, this message translates to:
  /// **'DOWNLOAD'**
  String get mlDownload;

  /// No description provided for @mlDownloaded.
  ///
  /// In en, this message translates to:
  /// **'DOWNLOADED'**
  String get mlDownloaded;

  /// No description provided for @mlRetry.
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get mlRetry;

  /// No description provided for @mlCancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get mlCancel;

  /// No description provided for @mlDelete.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get mlDelete;

  /// No description provided for @mlRemoveBg.
  ///
  /// In en, this message translates to:
  /// **'REMOVE BG'**
  String get mlRemoveBg;

  /// No description provided for @mlUpscale.
  ///
  /// In en, this message translates to:
  /// **'UPSCALE'**
  String get mlUpscale;

  /// No description provided for @mlSegment.
  ///
  /// In en, this message translates to:
  /// **'SEGMENT'**
  String get mlSegment;

  /// No description provided for @mlCanvas.
  ///
  /// In en, this message translates to:
  /// **'CANVAS'**
  String get mlCanvas;

  /// No description provided for @mlSave.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get mlSave;

  /// No description provided for @mlDiscard.
  ///
  /// In en, this message translates to:
  /// **'DISCARD'**
  String get mlDiscard;

  /// No description provided for @mlAddPoint.
  ///
  /// In en, this message translates to:
  /// **'ADD'**
  String get mlAddPoint;

  /// No description provided for @mlRemovePoint.
  ///
  /// In en, this message translates to:
  /// **'REMOVE'**
  String get mlRemovePoint;

  /// No description provided for @mlTierFast.
  ///
  /// In en, this message translates to:
  /// **'FAST'**
  String get mlTierFast;

  /// No description provided for @mlTierBalanced.
  ///
  /// In en, this message translates to:
  /// **'BALANCED'**
  String get mlTierBalanced;

  /// No description provided for @mlTierBalancedShort.
  ///
  /// In en, this message translates to:
  /// **'BAL'**
  String get mlTierBalancedShort;

  /// No description provided for @mlTierQuality.
  ///
  /// In en, this message translates to:
  /// **'QUALITY'**
  String get mlTierQuality;

  /// No description provided for @mlRemovingBg.
  ///
  /// In en, this message translates to:
  /// **'REMOVING BACKGROUNDS'**
  String get mlRemovingBg;

  /// No description provided for @mlUpscalingImages.
  ///
  /// In en, this message translates to:
  /// **'UPSCALING IMAGES'**
  String get mlUpscalingImages;

  /// No description provided for @mlBgRemovalFailed.
  ///
  /// In en, this message translates to:
  /// **'BG REMOVAL FAILED'**
  String get mlBgRemovalFailed;

  /// No description provided for @mlUpscaleFailed.
  ///
  /// In en, this message translates to:
  /// **'UPSCALE FAILED'**
  String get mlUpscaleFailed;

  /// No description provided for @mlRecommended.
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDED'**
  String get mlRecommended;

  /// No description provided for @mlMayBeSlow.
  ///
  /// In en, this message translates to:
  /// **'MAY BE SLOW'**
  String get mlMayBeSlow;

  /// No description provided for @mlNotRecommended.
  ///
  /// In en, this message translates to:
  /// **'NOT RECOMMENDED'**
  String get mlNotRecommended;

  /// No description provided for @mlNotAvailableOnPlatform.
  ///
  /// In en, this message translates to:
  /// **'NOT AVAILABLE ON THIS PLATFORM'**
  String get mlNotAvailableOnPlatform;

  /// No description provided for @mlLowRamWarning.
  ///
  /// In en, this message translates to:
  /// **'LOW RAM — MAY CRASH'**
  String get mlLowRamWarning;

  /// No description provided for @mlBgRemovedAndSaved.
  ///
  /// In en, this message translates to:
  /// **'BG REMOVED & SAVED'**
  String get mlBgRemovedAndSaved;

  /// No description provided for @mlBgRemovedCount.
  ///
  /// In en, this message translates to:
  /// **'BG REMOVED: {completed}/{total} IMAGES'**
  String mlBgRemovedCount(int completed, int total);

  /// No description provided for @mlUpscaledCount.
  ///
  /// In en, this message translates to:
  /// **'UPSCALED: {completed}/{total} IMAGES'**
  String mlUpscaledCount(int completed, int total);

  /// No description provided for @mlBgRemovedSavedAs.
  ///
  /// In en, this message translates to:
  /// **'BG REMOVED: SAVED AS {name}'**
  String mlBgRemovedSavedAs(String name);

  /// No description provided for @toolsDirectorTools.
  ///
  /// In en, this message translates to:
  /// **'Director Tools'**
  String get toolsDirectorTools;

  /// No description provided for @toolsEnhance.
  ///
  /// In en, this message translates to:
  /// **'Enhance'**
  String get toolsEnhance;

  /// No description provided for @directorToolsTitle.
  ///
  /// In en, this message translates to:
  /// **'DIRECTOR TOOLS'**
  String get directorToolsTitle;

  /// No description provided for @directorToolsDesc.
  ///
  /// In en, this message translates to:
  /// **'Server-side image manipulation: remove backgrounds, extract line art, colorize, and more'**
  String get directorToolsDesc;

  /// No description provided for @directorToolsUseCurrent.
  ///
  /// In en, this message translates to:
  /// **'USE CURRENT GENERATION'**
  String get directorToolsUseCurrent;

  /// No description provided for @directorToolsUseCurrentDesc.
  ///
  /// In en, this message translates to:
  /// **'Use the last generated image as source'**
  String get directorToolsUseCurrentDesc;

  /// No description provided for @directorToolsSelectTool.
  ///
  /// In en, this message translates to:
  /// **'SELECT TOOL'**
  String get directorToolsSelectTool;

  /// No description provided for @directorToolsProcess.
  ///
  /// In en, this message translates to:
  /// **'PROCESS'**
  String get directorToolsProcess;

  /// No description provided for @directorToolsProcessing.
  ///
  /// In en, this message translates to:
  /// **'PROCESSING...'**
  String get directorToolsProcessing;

  /// No description provided for @directorToolsDefry.
  ///
  /// In en, this message translates to:
  /// **'DEFRY (TOOL STRENGTH)'**
  String get directorToolsDefry;

  /// No description provided for @directorToolsMood.
  ///
  /// In en, this message translates to:
  /// **'MOOD'**
  String get directorToolsMood;

  /// No description provided for @directorToolsPrompt.
  ///
  /// In en, this message translates to:
  /// **'PROMPT'**
  String get directorToolsPrompt;

  /// No description provided for @directorToolsPromptHint.
  ///
  /// In en, this message translates to:
  /// **'Optional prompt for colorize/emotion...'**
  String get directorToolsPromptHint;

  /// No description provided for @directorToolsSaved.
  ///
  /// In en, this message translates to:
  /// **'RESULT SAVED TO GALLERY'**
  String get directorToolsSaved;

  /// No description provided for @enhanceTitle.
  ///
  /// In en, this message translates to:
  /// **'ENHANCE'**
  String get enhanceTitle;

  /// No description provided for @enhanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Re-process an image with img2img enhancement'**
  String get enhanceDesc;

  /// No description provided for @enhanceUseCurrent.
  ///
  /// In en, this message translates to:
  /// **'USE CURRENT GENERATION'**
  String get enhanceUseCurrent;

  /// No description provided for @enhanceUseCurrentDesc.
  ///
  /// In en, this message translates to:
  /// **'Use the last generated image as source'**
  String get enhanceUseCurrentDesc;

  /// No description provided for @enhanceProcess.
  ///
  /// In en, this message translates to:
  /// **'ENHANCE'**
  String get enhanceProcess;

  /// No description provided for @enhanceProcessing.
  ///
  /// In en, this message translates to:
  /// **'ENHANCING...'**
  String get enhanceProcessing;

  /// No description provided for @enhancePrompt.
  ///
  /// In en, this message translates to:
  /// **'PROMPT'**
  String get enhancePrompt;

  /// No description provided for @enhanceNegative.
  ///
  /// In en, this message translates to:
  /// **'NEGATIVE'**
  String get enhanceNegative;

  /// No description provided for @enhanceStrength.
  ///
  /// In en, this message translates to:
  /// **'STRENGTH'**
  String get enhanceStrength;

  /// No description provided for @enhanceNoise.
  ///
  /// In en, this message translates to:
  /// **'NOISE'**
  String get enhanceNoise;

  /// No description provided for @enhanceSaved.
  ///
  /// In en, this message translates to:
  /// **'ENHANCED IMAGE SAVED TO GALLERY'**
  String get enhanceSaved;

  /// No description provided for @settingsShowTooltips.
  ///
  /// In en, this message translates to:
  /// **'Show Tooltips'**
  String get settingsShowTooltips;

  /// No description provided for @settingsShowTooltipsDesc.
  ///
  /// In en, this message translates to:
  /// **'Display helpful tooltips when hovering or long-pressing buttons'**
  String get settingsShowTooltipsDesc;

  /// No description provided for @commonMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get commonMenu;

  /// No description provided for @presetDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get presetDuplicate;

  /// No description provided for @presetLoad.
  ///
  /// In en, this message translates to:
  /// **'Load Preset'**
  String get presetLoad;

  /// No description provided for @settingsStylesToggle.
  ///
  /// In en, this message translates to:
  /// **'Toggle Styles'**
  String get settingsStylesToggle;

  /// No description provided for @canvasLayerToggleVisibility.
  ///
  /// In en, this message translates to:
  /// **'Toggle Visibility'**
  String get canvasLayerToggleVisibility;

  /// No description provided for @mainRefreshAnlas.
  ///
  /// In en, this message translates to:
  /// **'Refresh Anlas'**
  String get mainRefreshAnlas;

  /// No description provided for @enhanceSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get enhanceSettingsTooltip;

  /// No description provided for @directorToolsSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get directorToolsSettingsTooltip;

  /// No description provided for @sidebarCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get sidebarCollapse;

  /// No description provided for @sidebarExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get sidebarExpand;

  /// No description provided for @naiUpscale.
  ///
  /// In en, this message translates to:
  /// **'NAI UPSCALE'**
  String get naiUpscale;

  /// No description provided for @naiUpscaling.
  ///
  /// In en, this message translates to:
  /// **'UPSCALING VIA API...'**
  String get naiUpscaling;

  /// No description provided for @naiUpscaleFailed.
  ///
  /// In en, this message translates to:
  /// **'API upscale failed'**
  String get naiUpscaleFailed;

  /// No description provided for @naiUpscaledCount.
  ///
  /// In en, this message translates to:
  /// **'API UPSCALED: {completed}/{total} IMAGES'**
  String naiUpscaledCount(int completed, int total);

  /// No description provided for @naiApiKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'API key required'**
  String get naiApiKeyRequired;

  /// No description provided for @comparisonBefore.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get comparisonBefore;

  /// No description provided for @comparisonAfter.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get comparisonAfter;

  /// No description provided for @comparisonSideBySide.
  ///
  /// In en, this message translates to:
  /// **'Side by side'**
  String get comparisonSideBySide;

  /// No description provided for @comparisonSliderMode.
  ///
  /// In en, this message translates to:
  /// **'Slider mode'**
  String get comparisonSliderMode;

  /// No description provided for @settingsBgRemovalButton.
  ///
  /// In en, this message translates to:
  /// **'BG Removal Button'**
  String get settingsBgRemovalButton;

  /// No description provided for @settingsBgRemovalButtonDesc.
  ///
  /// In en, this message translates to:
  /// **'Show the background removal button on the image viewer'**
  String get settingsBgRemovalButtonDesc;

  /// No description provided for @settingsUpscaleButton.
  ///
  /// In en, this message translates to:
  /// **'Upscale Button'**
  String get settingsUpscaleButton;

  /// No description provided for @settingsUpscaleButtonDesc.
  ///
  /// In en, this message translates to:
  /// **'Show the upscale button on the image viewer'**
  String get settingsUpscaleButtonDesc;

  /// No description provided for @settingsEnhanceButton.
  ///
  /// In en, this message translates to:
  /// **'Enhance Button'**
  String get settingsEnhanceButton;

  /// No description provided for @settingsEnhanceButtonDesc.
  ///
  /// In en, this message translates to:
  /// **'Show the enhance button on the image viewer'**
  String get settingsEnhanceButtonDesc;

  /// No description provided for @settingsDirectorToolsButton.
  ///
  /// In en, this message translates to:
  /// **'Director Tools Button'**
  String get settingsDirectorToolsButton;

  /// No description provided for @settingsDirectorToolsButtonDesc.
  ///
  /// In en, this message translates to:
  /// **'Show the director tools button on the image viewer'**
  String get settingsDirectorToolsButtonDesc;

  /// No description provided for @settingsUpscaleBackend.
  ///
  /// In en, this message translates to:
  /// **'Upscale Backend'**
  String get settingsUpscaleBackend;

  /// No description provided for @settingsUpscaleBackendDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose between local ML model or NovelAI API for upscaling'**
  String get settingsUpscaleBackendDesc;

  /// No description provided for @settingsUpscaleBackendMl.
  ///
  /// In en, this message translates to:
  /// **'ML (Local)'**
  String get settingsUpscaleBackendMl;

  /// No description provided for @settingsUpscaleBackendNovelai.
  ///
  /// In en, this message translates to:
  /// **'NovelAI (API)'**
  String get settingsUpscaleBackendNovelai;

  /// No description provided for @quickActionEnhance.
  ///
  /// In en, this message translates to:
  /// **'Enhance'**
  String get quickActionEnhance;

  /// No description provided for @quickActionDirectorTools.
  ///
  /// In en, this message translates to:
  /// **'Director Tools'**
  String get quickActionDirectorTools;

  /// No description provided for @themeColorBgRemoval.
  ///
  /// In en, this message translates to:
  /// **'BG Removal'**
  String get themeColorBgRemoval;

  /// No description provided for @themeColorUpscale.
  ///
  /// In en, this message translates to:
  /// **'Upscale'**
  String get themeColorUpscale;

  /// No description provided for @jukeboxSynthUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Synthesizer unavailable'**
  String get jukeboxSynthUnavailable;

  /// No description provided for @jukeboxImport.
  ///
  /// In en, this message translates to:
  /// **'IMPORT'**
  String get jukeboxImport;

  /// No description provided for @jukeboxKeyboard.
  ///
  /// In en, this message translates to:
  /// **'KEYBOARD'**
  String get jukeboxKeyboard;

  /// No description provided for @jukeboxGame.
  ///
  /// In en, this message translates to:
  /// **'GAME'**
  String get jukeboxGame;

  /// No description provided for @jukeboxEnd.
  ///
  /// In en, this message translates to:
  /// **'END'**
  String get jukeboxEnd;

  /// No description provided for @jukeboxTempo.
  ///
  /// In en, this message translates to:
  /// **'TEMPO'**
  String get jukeboxTempo;

  /// No description provided for @jukeboxKeyboardHint.
  ///
  /// In en, this message translates to:
  /// **'KEYS: A-L  SHARPS: W,E,T,Y,U,O,P  OCTAVE: Z/X'**
  String get jukeboxKeyboardHint;

  /// No description provided for @jukeboxGameResults.
  ///
  /// In en, this message translates to:
  /// **'RESULTS'**
  String get jukeboxGameResults;

  /// No description provided for @jukeboxGameScore.
  ///
  /// In en, this message translates to:
  /// **'SCORE'**
  String get jukeboxGameScore;

  /// No description provided for @jukeboxGameMaxCombo.
  ///
  /// In en, this message translates to:
  /// **'MAX COMBO'**
  String get jukeboxGameMaxCombo;

  /// No description provided for @jukeboxGameAccuracy.
  ///
  /// In en, this message translates to:
  /// **'ACCURACY'**
  String get jukeboxGameAccuracy;

  /// No description provided for @jukeboxGamePerfect.
  ///
  /// In en, this message translates to:
  /// **'PERFECT'**
  String get jukeboxGamePerfect;

  /// No description provided for @jukeboxGameGreat.
  ///
  /// In en, this message translates to:
  /// **'GREAT'**
  String get jukeboxGameGreat;

  /// No description provided for @jukeboxGameGood.
  ///
  /// In en, this message translates to:
  /// **'GOOD'**
  String get jukeboxGameGood;

  /// No description provided for @jukeboxGameMiss.
  ///
  /// In en, this message translates to:
  /// **'MISS'**
  String get jukeboxGameMiss;

  /// No description provided for @jukeboxHighScores.
  ///
  /// In en, this message translates to:
  /// **'HIGH SCORES'**
  String get jukeboxHighScores;

  /// No description provided for @jukeboxQueueCount.
  ///
  /// In en, this message translates to:
  /// **'QUEUE ({count})'**
  String jukeboxQueueCount(int count);

  /// No description provided for @jukeboxStyle.
  ///
  /// In en, this message translates to:
  /// **'STYLE'**
  String get jukeboxStyle;

  /// No description provided for @jukeboxGameModeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Game Mode'**
  String get jukeboxGameModeTooltip;

  /// No description provided for @jukeboxEndGameTooltip.
  ///
  /// In en, this message translates to:
  /// **'End Game'**
  String get jukeboxEndGameTooltip;

  /// No description provided for @jukeboxImportTooltip.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get jukeboxImportTooltip;

  /// No description provided for @jukeboxShuffleAllTooltip.
  ///
  /// In en, this message translates to:
  /// **'Shuffle All'**
  String get jukeboxShuffleAllTooltip;

  /// No description provided for @jukeboxPlayAllTooltip.
  ///
  /// In en, this message translates to:
  /// **'Play All'**
  String get jukeboxPlayAllTooltip;

  /// No description provided for @jukeboxKeyboardTooltip.
  ///
  /// In en, this message translates to:
  /// **'Keyboard'**
  String get jukeboxKeyboardTooltip;

  /// No description provided for @jukeboxGameMode.
  ///
  /// In en, this message translates to:
  /// **'GAME MODE'**
  String get jukeboxGameMode;

  /// No description provided for @jukeboxNoSongs.
  ///
  /// In en, this message translates to:
  /// **'NO SONGS'**
  String get jukeboxNoSongs;

  /// No description provided for @jukeboxRecommendedBadge.
  ///
  /// In en, this message translates to:
  /// **'REC'**
  String get jukeboxRecommendedBadge;

  /// No description provided for @jukeboxAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'ANALYZING...'**
  String get jukeboxAnalyzing;

  /// No description provided for @jukeboxNoScoresYet.
  ///
  /// In en, this message translates to:
  /// **'No scores yet'**
  String get jukeboxNoScoresYet;

  /// No description provided for @jukeboxSelectInstrument.
  ///
  /// In en, this message translates to:
  /// **'SELECT INSTRUMENT'**
  String get jukeboxSelectInstrument;

  /// No description provided for @jukeboxWatch.
  ///
  /// In en, this message translates to:
  /// **'WATCH'**
  String get jukeboxWatch;

  /// No description provided for @jukeboxPlayGame.
  ///
  /// In en, this message translates to:
  /// **'PLAY GAME'**
  String get jukeboxPlayGame;

  /// No description provided for @jukeboxChannelLabel.
  ///
  /// In en, this message translates to:
  /// **'CH {channel}'**
  String jukeboxChannelLabel(int channel);

  /// No description provided for @jukeboxCombo.
  ///
  /// In en, this message translates to:
  /// **'{count} COMBO'**
  String jukeboxCombo(int count);

  /// No description provided for @jukeboxPressOnTheLine.
  ///
  /// In en, this message translates to:
  /// **'PRESS ON THE LINE'**
  String get jukeboxPressOnTheLine;

  /// No description provided for @jukeboxGradePerfect.
  ///
  /// In en, this message translates to:
  /// **'PERFECT'**
  String get jukeboxGradePerfect;

  /// No description provided for @jukeboxGradeGreat.
  ///
  /// In en, this message translates to:
  /// **'GREAT'**
  String get jukeboxGradeGreat;

  /// No description provided for @jukeboxGradeGood.
  ///
  /// In en, this message translates to:
  /// **'GOOD'**
  String get jukeboxGradeGood;

  /// No description provided for @jukeboxGradeMiss.
  ///
  /// In en, this message translates to:
  /// **'MISS'**
  String get jukeboxGradeMiss;

  /// No description provided for @jukeboxDifficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'EASY'**
  String get jukeboxDifficultyEasy;

  /// No description provided for @jukeboxDifficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'MEDIUM'**
  String get jukeboxDifficultyMedium;

  /// No description provided for @jukeboxDifficultyHard.
  ///
  /// In en, this message translates to:
  /// **'HARD'**
  String get jukeboxDifficultyHard;

  /// No description provided for @jukeboxDifficultyExtreme.
  ///
  /// In en, this message translates to:
  /// **'EXTREME'**
  String get jukeboxDifficultyExtreme;

  /// No description provided for @jukeboxInstrumentAcousticGrandPiano.
  ///
  /// In en, this message translates to:
  /// **'Acoustic Grand Piano'**
  String get jukeboxInstrumentAcousticGrandPiano;

  /// No description provided for @jukeboxInstrumentElectricPiano.
  ///
  /// In en, this message translates to:
  /// **'Electric Piano'**
  String get jukeboxInstrumentElectricPiano;

  /// No description provided for @jukeboxInstrumentHarpsichord.
  ///
  /// In en, this message translates to:
  /// **'Harpsichord'**
  String get jukeboxInstrumentHarpsichord;

  /// No description provided for @jukeboxInstrumentVibraphone.
  ///
  /// In en, this message translates to:
  /// **'Vibraphone'**
  String get jukeboxInstrumentVibraphone;

  /// No description provided for @jukeboxInstrumentXylophone.
  ///
  /// In en, this message translates to:
  /// **'Xylophone'**
  String get jukeboxInstrumentXylophone;

  /// No description provided for @jukeboxInstrumentChurchOrgan.
  ///
  /// In en, this message translates to:
  /// **'Church Organ'**
  String get jukeboxInstrumentChurchOrgan;

  /// No description provided for @jukeboxInstrumentNylonGuitar.
  ///
  /// In en, this message translates to:
  /// **'Nylon Guitar'**
  String get jukeboxInstrumentNylonGuitar;

  /// No description provided for @jukeboxInstrumentSteelGuitar.
  ///
  /// In en, this message translates to:
  /// **'Steel Guitar'**
  String get jukeboxInstrumentSteelGuitar;

  /// No description provided for @jukeboxInstrumentCleanElectricGuitar.
  ///
  /// In en, this message translates to:
  /// **'Clean Electric Guitar'**
  String get jukeboxInstrumentCleanElectricGuitar;

  /// No description provided for @jukeboxInstrumentDistortionGuitar.
  ///
  /// In en, this message translates to:
  /// **'Distortion Guitar'**
  String get jukeboxInstrumentDistortionGuitar;

  /// No description provided for @jukeboxInstrumentAcousticBass.
  ///
  /// In en, this message translates to:
  /// **'Acoustic Bass'**
  String get jukeboxInstrumentAcousticBass;

  /// No description provided for @jukeboxInstrumentElectricBassFinger.
  ///
  /// In en, this message translates to:
  /// **'Electric Bass (Finger)'**
  String get jukeboxInstrumentElectricBassFinger;

  /// No description provided for @jukeboxInstrumentViolin.
  ///
  /// In en, this message translates to:
  /// **'Violin'**
  String get jukeboxInstrumentViolin;

  /// No description provided for @jukeboxInstrumentCello.
  ///
  /// In en, this message translates to:
  /// **'Cello'**
  String get jukeboxInstrumentCello;

  /// No description provided for @jukeboxInstrumentOrchestralHarp.
  ///
  /// In en, this message translates to:
  /// **'Orchestral Harp'**
  String get jukeboxInstrumentOrchestralHarp;

  /// No description provided for @jukeboxInstrumentStringEnsemble.
  ///
  /// In en, this message translates to:
  /// **'String Ensemble'**
  String get jukeboxInstrumentStringEnsemble;

  /// No description provided for @jukeboxInstrumentTrumpet.
  ///
  /// In en, this message translates to:
  /// **'Trumpet'**
  String get jukeboxInstrumentTrumpet;

  /// No description provided for @jukeboxInstrumentFrenchHorn.
  ///
  /// In en, this message translates to:
  /// **'French Horn'**
  String get jukeboxInstrumentFrenchHorn;

  /// No description provided for @jukeboxInstrumentAltoSax.
  ///
  /// In en, this message translates to:
  /// **'Alto Sax'**
  String get jukeboxInstrumentAltoSax;

  /// No description provided for @jukeboxInstrumentFlute.
  ///
  /// In en, this message translates to:
  /// **'Flute'**
  String get jukeboxInstrumentFlute;

  /// No description provided for @jukeboxInstrumentSquareLeadSynth.
  ///
  /// In en, this message translates to:
  /// **'Square Lead (Synth)'**
  String get jukeboxInstrumentSquareLeadSynth;

  /// No description provided for @jukeboxInstrumentLeadVoice.
  ///
  /// In en, this message translates to:
  /// **'Lead 6 (Voice)'**
  String get jukeboxInstrumentLeadVoice;

  /// No description provided for @jukeboxKaraokeBadge.
  ///
  /// In en, this message translates to:
  /// **'KAR'**
  String get jukeboxKaraokeBadge;

  /// No description provided for @jukeboxDeleteCustomSongTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete custom song'**
  String get jukeboxDeleteCustomSongTooltip;

  /// No description provided for @jukeboxDeleteSong.
  ///
  /// In en, this message translates to:
  /// **'DELETE SONG'**
  String get jukeboxDeleteSong;

  /// No description provided for @jukeboxDeleteSongConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {title}? This will remove the file from disk.'**
  String jukeboxDeleteSongConfirm(String title);

  /// No description provided for @jukeboxStyleHighlight.
  ///
  /// In en, this message translates to:
  /// **'HIGHLIGHT'**
  String get jukeboxStyleHighlight;

  /// No description provided for @jukeboxStyleUpcoming.
  ///
  /// In en, this message translates to:
  /// **'UPCOMING'**
  String get jukeboxStyleUpcoming;

  /// No description provided for @jukeboxStyleNextLine.
  ///
  /// In en, this message translates to:
  /// **'NEXT LINE'**
  String get jukeboxStyleNextLine;

  /// No description provided for @jukeboxStyleGlow.
  ///
  /// In en, this message translates to:
  /// **'GLOW'**
  String get jukeboxStyleGlow;

  /// No description provided for @jukeboxVisualizer.
  ///
  /// In en, this message translates to:
  /// **'VISUALIZER'**
  String get jukeboxVisualizer;

  /// No description provided for @jukeboxVizIntensity.
  ///
  /// In en, this message translates to:
  /// **'INTENSITY'**
  String get jukeboxVizIntensity;

  /// No description provided for @jukeboxVizSpeed.
  ///
  /// In en, this message translates to:
  /// **'SPEED'**
  String get jukeboxVizSpeed;

  /// No description provided for @jukeboxVizDensity.
  ///
  /// In en, this message translates to:
  /// **'DENSITY'**
  String get jukeboxVizDensity;

  /// No description provided for @jukeboxFontSize.
  ///
  /// In en, this message translates to:
  /// **'SIZE'**
  String get jukeboxFontSize;

  /// No description provided for @jukeboxResetToDefaults.
  ///
  /// In en, this message translates to:
  /// **'RESET TO DEFAULTS'**
  String get jukeboxResetToDefaults;

  /// No description provided for @jukeboxRepeatMode.
  ///
  /// In en, this message translates to:
  /// **'REPEAT: {mode}'**
  String jukeboxRepeatMode(String mode);

  /// No description provided for @jukeboxShuffleStatus.
  ///
  /// In en, this message translates to:
  /// **'SHUFFLE: {status}'**
  String jukeboxShuffleStatus(String status);

  /// No description provided for @galleryBadgeNaiUpscale.
  ///
  /// In en, this message translates to:
  /// **'NAI UPSCALE'**
  String get galleryBadgeNaiUpscale;

  /// No description provided for @galleryBadgeDirectorTool.
  ///
  /// In en, this message translates to:
  /// **'DIRECTOR: {tool}'**
  String galleryBadgeDirectorTool(String tool);

  /// No description provided for @galleryBadgeEnhanced.
  ///
  /// In en, this message translates to:
  /// **'ENHANCED'**
  String get galleryBadgeEnhanced;

  /// No description provided for @galleryBadgeBgRemoved.
  ///
  /// In en, this message translates to:
  /// **'BG REMOVED'**
  String get galleryBadgeBgRemoved;

  /// No description provided for @galleryBadgeUpscaled.
  ///
  /// In en, this message translates to:
  /// **'UPSCALED'**
  String get galleryBadgeUpscaled;

  /// No description provided for @galleryBgRemovalFailed.
  ///
  /// In en, this message translates to:
  /// **'BG REMOVAL FAILED'**
  String get galleryBgRemovalFailed;

  /// No description provided for @naiUpscaleTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Image too large for NAI upscale ({width}x{height} exceeds 2048px limit per side)'**
  String naiUpscaleTooLarge(int width, int height);

  /// No description provided for @naiRemovingBackground.
  ///
  /// In en, this message translates to:
  /// **'REMOVING BACKGROUND...'**
  String get naiRemovingBackground;

  /// No description provided for @naiBgRemovalFailed.
  ///
  /// In en, this message translates to:
  /// **'NAI BG REMOVAL FAILED'**
  String get naiBgRemovalFailed;

  /// No description provided for @directorToolsFromGallery.
  ///
  /// In en, this message translates to:
  /// **'FROM GALLERY'**
  String get directorToolsFromGallery;

  /// No description provided for @settingsBgRemovalBackend.
  ///
  /// In en, this message translates to:
  /// **'BG Removal Backend'**
  String get settingsBgRemovalBackend;

  /// No description provided for @settingsBgRemovalBackendDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose between local ML model or NovelAI API for background removal'**
  String get settingsBgRemovalBackendDesc;

  /// No description provided for @importDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'IMPORT METADATA'**
  String get importDialogTitle;

  /// No description provided for @importCategoryPrompt.
  ///
  /// In en, this message translates to:
  /// **'Prompt'**
  String get importCategoryPrompt;

  /// No description provided for @importCategoryNegative.
  ///
  /// In en, this message translates to:
  /// **'Negative Prompt'**
  String get importCategoryNegative;

  /// No description provided for @importCategoryCharacters.
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get importCategoryCharacters;

  /// No description provided for @importCategorySeed.
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get importCategorySeed;

  /// No description provided for @importCategoryStyles.
  ///
  /// In en, this message translates to:
  /// **'Styles'**
  String get importCategoryStyles;

  /// No description provided for @importCategorySettings.
  ///
  /// In en, this message translates to:
  /// **'Settings (Resolution, Sampler, Scale)'**
  String get importCategorySettings;

  /// No description provided for @importActionImport.
  ///
  /// In en, this message translates to:
  /// **'IMPORT'**
  String get importActionImport;

  /// No description provided for @importNothingAvailable.
  ///
  /// In en, this message translates to:
  /// **'No importable metadata found'**
  String get importNothingAvailable;

  /// No description provided for @settingsCredits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get settingsCredits;

  /// No description provided for @settingsSpecialThanks.
  ///
  /// In en, this message translates to:
  /// **'Special Thanks'**
  String get settingsSpecialThanks;

  /// No description provided for @settingsAnonTesters.
  ///
  /// In en, this message translates to:
  /// **'...and all anonymous bug testers'**
  String get settingsAnonTesters;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
