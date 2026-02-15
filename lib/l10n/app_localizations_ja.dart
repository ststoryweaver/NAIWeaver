// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonDelete => '削除';

  @override
  String get commonSave => '保存';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonCreate => '作成';

  @override
  String get commonRename => '名前変更';

  @override
  String get commonConfirm => '確認';

  @override
  String get commonSet => '設定';

  @override
  String get commonNone => 'なし';

  @override
  String get commonExport => 'エクスポート';

  @override
  String get commonOverwrite => '上書き';

  @override
  String get commonSaveChanges => '変更を保存';

  @override
  String get mainGallery => 'ギャラリー';

  @override
  String get mainTools => 'ツール';

  @override
  String get mainSave => '保存';

  @override
  String get mainEdit => '編集';

  @override
  String get mainEnterPrompt => 'プロンプトを入力';

  @override
  String get mainHelp => 'ヘルプ';

  @override
  String get mainAuthError => '認証エラー：API設定を確認してください';

  @override
  String get mainSettings => '設定';

  @override
  String mainImportFailed(String error) {
    return '設定のインポートに失敗しました: $error';
  }

  @override
  String get mainSavePreset => 'プリセットを保存';

  @override
  String get mainPresetName => 'プリセット名';

  @override
  String get mainAdvancedSettings => '詳細設定';

  @override
  String get settingsApiSettings => 'API設定';

  @override
  String get settingsGeneralSettings => '一般設定';

  @override
  String get settingsUiSettings => 'UI設定';

  @override
  String get settingsExport => 'エクスポート';

  @override
  String get settingsSecurity => 'セキュリティ';

  @override
  String get settingsDemoMode => 'デモモード';

  @override
  String get settingsLinks => 'リンク';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsApiKeyLabel => 'NovelAI APIキー';

  @override
  String get settingsApiKeyHint => 'pst-xxxx...';

  @override
  String get settingsAutoSave => '画像の自動保存';

  @override
  String get settingsAutoSaveDesc => '生成した画像をすべて自動的に出力フォルダに保存します';

  @override
  String get settingsSmartStyleImport => 'スマートスタイルインポート';

  @override
  String get settingsSmartStyleImportDesc =>
      'インポートしたプロンプトからスタイルタグを除去し、スタイル選択を復元します';

  @override
  String get settingsRememberSession => 'セッション記憶';

  @override
  String get settingsRememberSessionDesc => 'クラッシュ復旧のためにプロンプト、設定、参照を自動保存します';

  @override
  String get settingsSaveToAlbum => 'アルバムに保存';

  @override
  String get settingsSaveToAlbumDesc => '新しい生成画像を自動的にこのアルバムに追加します';

  @override
  String get settingsEditButton => '編集ボタン';

  @override
  String get settingsEditButtonDesc => '画像ビューアに編集/インペインティングボタンを表示します';

  @override
  String get settingsDirectorRefShelf => 'ディレクターリファレンスシェルフ';

  @override
  String get settingsDirectorRefShelfDesc => 'メイン画面にリファレンス画像シェルフを表示します';

  @override
  String get settingsVibeTransferShelf => 'バイブトランスファーシェルフ';

  @override
  String get settingsVibeTransferShelfDesc => 'メイン画面にバイブトランスファーシェルフを表示します';

  @override
  String get settingsThemeBuilder => 'テーマビルダー';

  @override
  String get settingsStripMetadata => 'エクスポート時にメタデータを除去';

  @override
  String get settingsStripMetadataDesc => 'エクスポートする画像から生成データ（プロンプト、設定）を除去します';

  @override
  String get settingsPinLock => 'PINロック';

  @override
  String get settingsPinLockDesc => 'アプリを開くのにPIN（4〜8桁）を要求します';

  @override
  String get settingsLockOnResume => '復帰時にロック';

  @override
  String get settingsLockOnResumeDesc => 'バックグラウンドから復帰時にアプリを再ロックします';

  @override
  String get settingsBiometricUnlock => '生体認証ロック解除';

  @override
  String get settingsBiometricUnlockDesc => '指紋または顔認証でロック解除します';

  @override
  String get settingsBiometricsUnavailable => 'このデバイスでは生体認証を利用できません';

  @override
  String get settingsSetPin => 'PINを設定';

  @override
  String get settingsPinDigitsHint => '4〜8桁';

  @override
  String get settingsPinMustBeDigits => 'PINは4〜8桁の数字で入力してください';

  @override
  String get settingsPinsDoNotMatch => 'PINが一致しません';

  @override
  String get settingsEnterCurrentPin => '現在のPINを入力';

  @override
  String get settingsEnterPinHint => 'PINを入力';

  @override
  String get settingsIncorrectPin => 'PINが正しくありません';

  @override
  String get settingsDemoModeDesc => 'ギャラリーにデモ用の安全な画像のみ表示します';

  @override
  String get settingsSelectDemoImages => 'デモ画像を選択';

  @override
  String get settingsTagSuggestionsHidden => 'デモモード中はタグ候補が非表示になります';

  @override
  String get settingsPositivePrefix => 'ポジティブプレフィックス';

  @override
  String get settingsNegativePrefix => 'ネガティブプレフィックス';

  @override
  String get settingsEditPositivePrefix => 'ポジティブプレフィックスを編集';

  @override
  String get settingsEditNegativePrefix => 'ネガティブプレフィックスを編集';

  @override
  String get settingsDemoPrefixes => 'デモプレフィックス';

  @override
  String get settingsNotSet => '（未設定）';

  @override
  String get settingsGithubRepository => 'GitHubリポジトリ';

  @override
  String get settingsGithubPlaceholder => 'GitHubリンクプレースホルダ';

  @override
  String get galleryTitle => 'ギャラリー';

  @override
  String get galleryDemoTitle => 'ギャラリー（デモ）';

  @override
  String get gallerySearchTags => 'タグを検索...';

  @override
  String gallerySelectedCount(int count) {
    return '$count件選択中';
  }

  @override
  String get galleryDeselectAll => 'すべて選択解除';

  @override
  String get gallerySelectAll => 'すべて選択';

  @override
  String get galleryFavoritesFilter => 'お気に入りフィルター';

  @override
  String get gallerySort => '並び替え';

  @override
  String get gallerySelectMode => '選択モード';

  @override
  String galleryColumnsCount(int count) {
    return '$count列';
  }

  @override
  String get gallerySortDateNewest => '日付（新しい順）';

  @override
  String get gallerySortDateOldest => '日付（古い順）';

  @override
  String get gallerySortNameAZ => '名前（A→Z）';

  @override
  String get gallerySortNameZA => '名前（Z→A）';

  @override
  String get gallerySortSizeLargest => 'サイズ（大きい順）';

  @override
  String get gallerySortSizeSmallest => 'サイズ（小さい順）';

  @override
  String get galleryNoDemoImages => 'デモ画像が選択されていません';

  @override
  String get galleryNoFavorites => 'お気に入りなし';

  @override
  String get galleryNoImagesInAlbum => 'アルバムに画像がありません';

  @override
  String get galleryNoImagesFound => '画像が見つかりません';

  @override
  String get galleryAll => 'すべて';

  @override
  String galleryCopiedCount(int count) {
    return '$count件コピー済み';
  }

  @override
  String galleryImagesCopiedCount(int count) {
    return '$count枚の画像をコピー済み';
  }

  @override
  String galleryPasteInto(String name) {
    return '$nameに貼り付け';
  }

  @override
  String galleryPastedIntoAlbum(int count, String name) {
    return '$count枚の画像を$nameに貼り付けました';
  }

  @override
  String get galleryClearClipboard => 'クリップボードをクリア';

  @override
  String get galleryNewAlbum => '新規アルバム';

  @override
  String get galleryAlbumName => 'アルバム名';

  @override
  String get galleryRenameAlbum => 'アルバム名を変更';

  @override
  String get galleryAddToAlbum => 'アルバムに追加';

  @override
  String galleryDeleteCount(int count) {
    return '$count枚の画像を削除しますか？';
  }

  @override
  String get galleryCannotUndo => 'この操作は取り消せません。';

  @override
  String get galleryCompare => '比較';

  @override
  String get galleryCopy => 'コピー';

  @override
  String get galleryPaste => '貼り付け';

  @override
  String get galleryAlbum => 'アルバム';

  @override
  String get galleryFavorite => 'お気に入り';

  @override
  String gallerySavedToDeviceCount(int saved, int total) {
    return '$saved/$total枚をデバイスギャラリーに保存しました';
  }

  @override
  String galleryExportDialogTitle(int count) {
    return '$count枚の画像をエクスポート';
  }

  @override
  String galleryExportedToFolder(int count, String folder) {
    return '$count枚の画像を$folderにエクスポートしました';
  }

  @override
  String galleryExportFailed(String error) {
    return 'エクスポートに失敗しました: $error';
  }

  @override
  String galleryImagesCopied(int count) {
    return '$count枚の画像をコピーしました';
  }

  @override
  String galleryImagesPasted(int count) {
    return '$count枚の画像を貼り付けました';
  }

  @override
  String get galleryDeleteImage => '画像を削除しますか？';

  @override
  String get gallerySavedToDevice => 'デバイスギャラリーに保存しました';

  @override
  String get galleryExportImageDialog => '画像をエクスポート';

  @override
  String gallerySavedTo(String name) {
    return '$nameに保存しました';
  }

  @override
  String get galleryToggleFavorite => 'お気に入りを切り替え';

  @override
  String get galleryExportImage => '画像をエクスポート';

  @override
  String get galleryDeleteImageTooltip => '画像を削除';

  @override
  String get galleryNoPrompt => 'プロンプトなし';

  @override
  String get galleryNoMetadata => 'メタデータなし';

  @override
  String get galleryPrompt => 'プロンプト';

  @override
  String get galleryImg2img => 'IMG2IMG';

  @override
  String get galleryCharRef => 'キャラ参照';

  @override
  String get galleryVibe => 'バイブ';

  @override
  String get gallerySlideshow => 'スライドショー';

  @override
  String get galleryAddedAsCharRef => 'キャラクター参照として追加しました';

  @override
  String get galleryAddedAsVibe => 'バイブトランスファーとして追加しました';

  @override
  String galleryVibeTransferFailed(String error) {
    return 'バイブトランスファーに失敗しました: $error';
  }

  @override
  String get galleryScale => 'スケール';

  @override
  String get gallerySteps => 'ステップ';

  @override
  String get gallerySampler => 'サンプラー';

  @override
  String get gallerySeed => 'シード';

  @override
  String get panelAdvancedSettings => '詳細設定';

  @override
  String get panelDimensions => '解像度';

  @override
  String get panelSeed => 'シード';

  @override
  String get panelCustom => 'カスタム';

  @override
  String get panelSteps => 'ステップ';

  @override
  String get panelScale => 'スケール';

  @override
  String get panelSampler => 'サンプラー';

  @override
  String get panelPostProcessing => '後処理';

  @override
  String get panelStyles => 'スタイル';

  @override
  String get panelManageStyles => 'スタイル管理';

  @override
  String get panelEnabled => '有効';

  @override
  String get panelNoStylesDefined => 'スタイル未定義';

  @override
  String get panelNegativePrompt => 'ネガティブプロンプト';

  @override
  String get panelPresets => 'プリセット';

  @override
  String get panelNoPresetsSaved => '保存済みプリセットなし';

  @override
  String get panelDeletePreset => 'プリセットを削除';

  @override
  String panelDeletePresetConfirm(String name) {
    return '「$name」を削除しますか？';
  }

  @override
  String get panelSaveToAlbum => 'アルバムに保存';

  @override
  String get panelNew => '新規';

  @override
  String get panelNewAlbum => '新規アルバム';

  @override
  String get panelAlbumName => 'アルバム名';

  @override
  String get resNormalPortrait => '通常 縦長';

  @override
  String get resNormalLandscape => '通常 横長';

  @override
  String get resNormalSquare => '通常 正方形';

  @override
  String get resLargePortrait => '大 縦長';

  @override
  String get resLargeLandscape => '大 横長';

  @override
  String get resLargeSquare => '大 正方形';

  @override
  String get resWallpaperPortrait => '壁紙 縦長';

  @override
  String get resWallpaperLandscape => '壁紙 横長';

  @override
  String get toolsHub => 'ツールハブ';

  @override
  String get toolsTitle => 'ツール';

  @override
  String get toolsWildcards => 'ワイルドカード';

  @override
  String get toolsTagLibrary => 'タグライブラリ';

  @override
  String get toolsPresets => 'プリセット';

  @override
  String get toolsStyles => 'スタイル';

  @override
  String get toolsReferences => 'リファレンス';

  @override
  String get toolsCascadeEditor => 'カスケードエディタ';

  @override
  String get toolsImg2imgEditor => 'IMG2IMGエディタ';

  @override
  String get toolsSlideshow => 'スライドショー';

  @override
  String get toolsPacks => 'パック';

  @override
  String get toolsTheme => 'テーマ';

  @override
  String get toolsSettings => '設定';

  @override
  String get helpTitle => 'NAIWeaver';

  @override
  String get helpShortcuts => 'ショートカット';

  @override
  String get helpFeatures => '機能';

  @override
  String get helpShortcutWildcard => 'wildcards/name.txtからランダムに1行選択';

  @override
  String get helpShortcutFavorites => 'すべてのお気に入りタグを表示';

  @override
  String get helpShortcutFavCategories => 'カテゴリ別お気に入り';

  @override
  String get helpShortcutSourceAction => 'アクションを実行するキャラクター';

  @override
  String get helpShortcutTargetAction => 'アクションを受けるキャラクター';

  @override
  String get helpShortcutMutualAction => 'キャラクター間の共有アクション';

  @override
  String get helpShortcutEnter => '生成（またはタグ候補を選択）';

  @override
  String get helpShortcutDragDrop => '生成設定をインポート';

  @override
  String get helpFeatureGallery => 'ギャラリー';

  @override
  String get helpFeatureGalleryDesc => '出力の閲覧、お気に入り、比較、アルバム整理';

  @override
  String get helpFeatureWildcards => 'ワイルドカード';

  @override
  String get helpFeatureWildcardsDesc => '__パターン__ テキストファイルからランダム置換';

  @override
  String get helpFeatureStyles => 'スタイル';

  @override
  String get helpFeatureStylesDesc => 'プロンプトにプレフィックス/サフィックス/ネガティブを自動挿入';

  @override
  String get helpFeaturePresets => 'プリセット';

  @override
  String get helpFeaturePresetsDesc => '生成設定の保存と復元';

  @override
  String get helpFeatureDirectorRef => 'ディレクターリファレンス';

  @override
  String get helpFeatureDirectorRefDesc => '参照画像でキャラクター/スタイルの外見をガイド';

  @override
  String get helpFeatureVibeTransfer => 'バイブトランスファー';

  @override
  String get helpFeatureVibeTransferDesc => '参照画像で構図とムードに影響を与える';

  @override
  String get helpFeatureCascade => 'カスケード';

  @override
  String get helpFeatureCascadeDesc => 'マルチビート連続シーン生成';

  @override
  String get helpFeatureImg2img => 'IMG2IMG';

  @override
  String get helpFeatureImg2imgDesc => 'インペインティングとバリエーションで画像を編集/改良';

  @override
  String get helpFeatureThemes => 'テーマ';

  @override
  String get helpFeatureThemesDesc => 'すべての色、フォント、スケールをカスタマイズ';

  @override
  String get helpFeaturePacks => 'パック';

  @override
  String get helpFeaturePacksDesc => 'プリセット、スタイル、ワイルドカードを.vpackでエクスポート/インポート';

  @override
  String get wildcardManager => 'ワイルドカードマネージャー';

  @override
  String get wildcardManageDesc => 'ワイルドカードファイルの管理と編集';

  @override
  String get wildcardFiles => 'ファイル';

  @override
  String get wildcardNew => '新規ワイルドカード';

  @override
  String get wildcardSelectOrCreate => 'ワイルドカードファイルを選択または作成';

  @override
  String get wildcardValidateTags => 'タグを検証';

  @override
  String wildcardRecognized(int valid, int total) {
    return '$valid/$total件認識';
  }

  @override
  String get wildcardClear => 'クリア';

  @override
  String get wildcardStartTyping => 'タグを入力...';

  @override
  String wildcardUnrecognized(int count) {
    return '$count件未認識';
  }

  @override
  String get wildcardCreateTitle => 'ワイルドカードを作成';

  @override
  String get wildcardFileName => 'ファイル名';

  @override
  String get tagLibTitle => 'タグライブラリ';

  @override
  String get tagLibPreviewSettings => 'プレビュー設定';

  @override
  String get tagLibAddTag => 'タグを追加';

  @override
  String get tagLibSearchTags => 'タグを検索...';

  @override
  String get tagLibAll => 'すべて';

  @override
  String get tagLibFavorites => 'お気に入り';

  @override
  String get tagLibImages => '画像付き';

  @override
  String get tagLibSort => '並び順:';

  @override
  String get tagLibSortCountDesc => '件数 ↓';

  @override
  String get tagLibSortCountAsc => '件数 ↑';

  @override
  String get tagLibSortAZ => 'A-Z';

  @override
  String get tagLibSortZA => 'Z-A';

  @override
  String get tagLibSortFavsFirst => 'お気に入り優先';

  @override
  String tagLibTagCount(int count) {
    return '$count件のタグ';
  }

  @override
  String get tagLibDeleteTag => 'タグを削除';

  @override
  String tagLibRemoveConfirm(String tag) {
    return '「$tag」をライブラリから削除しますか？';
  }

  @override
  String get tagLibTestTag => 'タグをテスト';

  @override
  String get tagLibAddNewTag => '新規タグを追加';

  @override
  String get tagLibTagName => 'タグ名';

  @override
  String get tagLibCount => '件数';

  @override
  String get tagLibAddTagBtn => 'タグを追加';

  @override
  String get tagLibDeleteExample => 'サンプルを削除';

  @override
  String get tagLibDeleteExampleConfirm => 'このビジュアルサンプルを削除しますか？';

  @override
  String tagLibTesting(String tag) {
    return 'テスト中: $tag';
  }

  @override
  String get tagLibGeneratingPreview => 'プレビューを生成中...';

  @override
  String get tagLibGenerationFailed => '生成に失敗しました';

  @override
  String get tagLibExampleSaved => 'サンプルを保存しました';

  @override
  String get tagLibSaveAsExample => 'サンプルとして保存';

  @override
  String get tagLibPreviewSettingsTitle => 'プレビュー設定';

  @override
  String get tagLibPositivePromptBase => 'ポジティブプロンプト（ベース）';

  @override
  String get tagLibNegativePrompt => 'ネガティブプロンプト';

  @override
  String get tagLibSampler => 'サンプラー';

  @override
  String get tagLibSteps => 'ステップ';

  @override
  String get tagLibWidth => '幅';

  @override
  String get tagLibHeight => '高さ';

  @override
  String get tagLibScale => 'スケール';

  @override
  String get tagLibSeed => 'シード';

  @override
  String get tagLibRandom => 'ランダム';

  @override
  String get presetManager => 'プリセットマネージャー';

  @override
  String get presetManageDesc => '生成プリセットの管理と編集';

  @override
  String get presetList => 'プリセット';

  @override
  String get presetNew => '新規プリセット';

  @override
  String presetCharsInfo(int chars, int ints) {
    return '$charsキャラ, $intsインタラクション';
  }

  @override
  String presetCharsRefsInfo(int chars, int ints, int refs) {
    return '$charsキャラ, $intsインタラクション, $refsリファレンス';
  }

  @override
  String get presetSelectToEdit => '編集するプリセットを選択';

  @override
  String get presetIdentity => '基本情報';

  @override
  String get presetName => '名前';

  @override
  String get presetPrompts => 'プロンプト';

  @override
  String get presetPrompt => 'プロンプト';

  @override
  String get presetNegativePrompt => 'ネガティブプロンプト';

  @override
  String get presetGenSettings => '生成設定';

  @override
  String get presetWidth => '幅';

  @override
  String get presetHeight => '高さ';

  @override
  String get presetScale => 'スケール';

  @override
  String get presetSteps => 'ステップ';

  @override
  String get presetSampler => 'サンプラー';

  @override
  String get presetCharsAndInteractions => 'キャラクター＆インタラクション';

  @override
  String get presetNoChars => 'このプリセットにキャラクターは保存されていません';

  @override
  String presetCharacterN(int n) {
    return 'キャラクター $n';
  }

  @override
  String get presetInteractions => 'インタラクション';

  @override
  String get presetReferences => 'リファレンス';

  @override
  String get presetNoRefs => 'このプリセットにリファレンスは保存されていません';

  @override
  String get presetProcessing => '処理中...';

  @override
  String get presetAddReference => 'リファレンスを追加';

  @override
  String get presetDeleteTitle => 'プリセットを削除';

  @override
  String presetDeleteConfirm(String name) {
    return '「$name」を削除してもよろしいですか？';
  }

  @override
  String get presetOverwriteTitle => 'プリセットを上書き';

  @override
  String presetOverwriteConfirm(String name) {
    return '「$name」という名前のプリセットが既に存在します。上書きしますか？';
  }

  @override
  String get styleEditor => 'スタイルエディタ';

  @override
  String get styleManageDesc => 'プロンプトスニペットとスタイルタグの管理';

  @override
  String get styleList => 'スタイル';

  @override
  String get styleNew => '新規スタイル';

  @override
  String get styleSelectToEdit => '編集するスタイルを選択';

  @override
  String get styleIdentity => '基本情報';

  @override
  String get styleName => '名前';

  @override
  String get styleDefaultOnLaunch => '起動時にデフォルト';

  @override
  String get styleTargetPrompt => '対象プロンプト';

  @override
  String get stylePositive => 'ポジティブ';

  @override
  String get styleNegative => 'ネガティブ';

  @override
  String get styleNegativeContent => 'ネガティブコンテンツ';

  @override
  String get stylePositiveContent => 'ポジティブコンテンツ';

  @override
  String get styleContent => 'コンテンツ';

  @override
  String get stylePlacement => '配置';

  @override
  String get styleBeginningPrefix => '先頭（プレフィックス）';

  @override
  String get styleEndSuffix => '末尾（サフィックス）';

  @override
  String get styleDeleteTitle => 'スタイルを削除';

  @override
  String styleDeleteConfirm(String name) {
    return '「$name」を削除してもよろしいですか？';
  }

  @override
  String get styleOverwriteTitle => 'スタイルを上書き';

  @override
  String styleOverwriteConfirm(String name) {
    return '「$name」という名前のスタイルが既に存在します。上書きしますか？';
  }

  @override
  String get refPreciseReferences => 'プリサイスリファレンス';

  @override
  String get refVibeTransfer => 'バイブトランスファー';

  @override
  String get refDialogCancel => 'キャンセル';

  @override
  String get refDialogSave => '保存';

  @override
  String get refNameHint => '名前';

  @override
  String get refClearAll => 'すべてクリア';

  @override
  String get refSavedSection => '保存済み';

  @override
  String get refSaveReference => 'リファレンスを保存';

  @override
  String refReferenceCount(int count) {
    return '$count件のリファレンス';
  }

  @override
  String get refNoReferencesAdded => 'リファレンスなし';

  @override
  String get refEmptyDescription =>
      'リファレンス画像をアップロードして、キャラクターの\n外見やアートスタイルを維持しましょう。';

  @override
  String get refAddReference => 'リファレンスを追加';

  @override
  String get refEditorTitle => 'リファレンスエディタ';

  @override
  String get refTypeLabel => 'リファレンスタイプ';

  @override
  String get refStrength => '強度';

  @override
  String get refFidelity => '忠実度';

  @override
  String get refStrengthShort => 'STR';

  @override
  String get refFidelityShort => 'FID';

  @override
  String get refTypeCharacter => 'キャラクター';

  @override
  String get refTypeStyle => 'スタイル';

  @override
  String get refTypeCharAndStyle => 'キャラ&スタイル';

  @override
  String get refSaveVibe => 'バイブを保存';

  @override
  String get refVibeTransfers => 'バイブトランスファー';

  @override
  String refVibeCount(int count) {
    return '$count件のバイブ';
  }

  @override
  String get refNoVibesAdded => 'バイブなし';

  @override
  String get refVibeEmptyDescription =>
      'リファレンス画像をアップロードして、アートスタイルと\n雰囲気を生成に反映させましょう。';

  @override
  String get refAddVibe => 'バイブを追加';

  @override
  String get refVibeLabel => 'バイブ';

  @override
  String get refVibeEditorTitle => 'バイブエディタ';

  @override
  String get refInfoExtracted => '情報抽出量';

  @override
  String get refInfoExtractedShort => 'INF';

  @override
  String get refApiKeyMissing => 'APIキーが未設定または無効です';

  @override
  String refVibeEncodeFailed(String error) {
    return 'バイブのエンコードに失敗: $error';
  }

  @override
  String get packTitle => 'NAIWEAVERパック';

  @override
  String get packDesc => 'プリセット、スタイル、ワイルドカードを.vpackファイルとしてエクスポート/インポートします。';

  @override
  String get packExportLabel => 'パックをエクスポート';

  @override
  String get packExportDesc => 'プリセット、スタイル、ワイルドカードをバンドル';

  @override
  String get packImportLabel => 'パックをインポート';

  @override
  String get packImportDesc => '.vpackファイルを読み込み';

  @override
  String get packGalleryExport => 'ギャラリーエクスポート';

  @override
  String get packGalleryExportDesc => 'ギャラリー画像をアルバムフォルダ別にZIPファイルとしてエクスポートします。';

  @override
  String get packExportGalleryZip => 'ギャラリーをZIPでエクスポート';

  @override
  String get packExportGalleryZipDesc => 'フォルダ内のアルバム階層を保持';

  @override
  String get packImportDialogTitle => 'NAIWeaverパックをインポート';

  @override
  String packFailedRead(String error) {
    return 'パックの読み込みに失敗しました: $error';
  }

  @override
  String get packExportDialogTitle => 'パックをエクスポート';

  @override
  String get packName => 'パック名';

  @override
  String get packDescriptionOptional => '説明（任意）';

  @override
  String packPresetsSection(int selected, int total) {
    return 'プリセット ($selected/$total)';
  }

  @override
  String packStylesSection(int selected, int total) {
    return 'スタイル ($selected/$total)';
  }

  @override
  String packWildcardsSection(int selected, int total) {
    return 'ワイルドカード ($selected/$total)';
  }

  @override
  String get packExportSuccess => 'パックをエクスポートしました';

  @override
  String packExportFailed(String error) {
    return 'エクスポートに失敗しました: $error';
  }

  @override
  String get packImportDialogTitle2 => 'パックをインポート';

  @override
  String packImportCount(int count) {
    return 'インポート ($count)';
  }

  @override
  String get packImportSuccess => 'パックをインポートしました';

  @override
  String packImportFailed(String error) {
    return 'インポートに失敗しました: $error';
  }

  @override
  String get packExportGalleryTitle => 'ギャラリーをエクスポート';

  @override
  String get packAlbums => 'アルバム';

  @override
  String packUnsortedCount(int count) {
    return '未分類 ($count)';
  }

  @override
  String get packOptions => 'オプション';

  @override
  String get packStripMetadata => 'メタデータを除去';

  @override
  String get packFavoritesOnly => 'お気に入りのみ';

  @override
  String packExportCount(int count) {
    return 'エクスポート ($count)';
  }

  @override
  String get packSaveDialogTitle => 'NAIWeaverパックを保存';

  @override
  String get packExportGalleryZipDialog => 'ギャラリーZIPをエクスポート';

  @override
  String packExportedToZip(int count) {
    return '$count枚の画像をZIPにエクスポートしました';
  }

  @override
  String get themeSelectToEdit => '編集するテーマを選択';

  @override
  String get themeList => 'テーマ';

  @override
  String get themeNew => '新規テーマ';

  @override
  String get themeSave => '保存';

  @override
  String get themeReset => 'リセット';

  @override
  String get themePreview => 'プレビュー';

  @override
  String get themeColors => 'カラー';

  @override
  String get themeColorBackground => '背景';

  @override
  String get themeColorSurfaceHigh => 'サーフェス（高）';

  @override
  String get themeColorSurfaceMid => 'サーフェス（中）';

  @override
  String get themeColorTextPrimary => 'テキスト（プライマリ）';

  @override
  String get themeColorTextSecondary => 'テキスト（セカンダリ）';

  @override
  String get themeColorTextTertiary => 'テキスト（ターシャリ）';

  @override
  String get themeColorTextDisabled => 'テキスト（無効）';

  @override
  String get themeColorTextMinimal => 'テキスト（最小）';

  @override
  String get themeColorBorderStrong => 'ボーダー（強）';

  @override
  String get themeColorBorderMedium => 'ボーダー（中）';

  @override
  String get themeColorBorderSubtle => 'ボーダー（微）';

  @override
  String get themeColorAccent => 'アクセント';

  @override
  String get themeColorAccentEdit => 'アクセント（編集）';

  @override
  String get themeColorAccentSuccess => 'アクセント（成功）';

  @override
  String get themeColorAccentDanger => 'アクセント（危険）';

  @override
  String get themeColorLogo => 'ロゴ';

  @override
  String get themeColorCascade => 'カスケード';

  @override
  String get themeReferences => 'リファレンス';

  @override
  String get themeColorVibeTransfer => 'バイブトランスファー';

  @override
  String get themeColorRefCharacter => 'リファレンス（キャラクター）';

  @override
  String get themeColorRefStyle => 'リファレンス（スタイル）';

  @override
  String get themeColorRefCharStyle => 'リファレンス（キャラ+スタイル）';

  @override
  String get themeFont => 'フォント';

  @override
  String get themeTextScale => 'テキストスケール';

  @override
  String get themeSmall => '小';

  @override
  String get themeLarge => '大';

  @override
  String get themePromptInput => 'プロンプト入力';

  @override
  String get themeFontSize => 'フォントサイズ';

  @override
  String get themeHeightLabel => '高さ';

  @override
  String themeLines(int count) {
    return '$count行';
  }

  @override
  String get themeBrightMode => 'ブライトモード';

  @override
  String get themeBrightText => '明るいテキスト';

  @override
  String get themeBrightDesc => 'テキストの色を明るくして可読性を向上';

  @override
  String get themePanelLayout => 'パネルレイアウト';

  @override
  String get themePanelLayoutDesc => 'ドラッグして詳細設定セクションを並び替え';

  @override
  String get themeDeleteTitle => 'テーマを削除';

  @override
  String themeDeleteConfirm(String name) {
    return '本当に \'\'$name\'\' を削除しますか？';
  }

  @override
  String get themeNewTitle => '新規テーマ';

  @override
  String get themeCustomTheme => 'カスタムテーマ';

  @override
  String get themeThemeName => 'テーマ名';

  @override
  String themeCreateFailed(String error) {
    return 'テーマの作成に失敗しました: $error';
  }

  @override
  String get themeSectionDimSeed => '解像度＋シード';

  @override
  String get themeSectionStepsScale => 'ステップ＋スケール';

  @override
  String get themeSectionSamplerPost => 'サンプラー＋後処理';

  @override
  String get themeSectionStyles => 'スタイル';

  @override
  String get themeSectionNegPrompt => 'ネガティブプロンプト';

  @override
  String get themeSectionPresets => 'プリセット';

  @override
  String get themeSectionSaveAlbum => 'アルバムに保存';

  @override
  String get themePreviewHeader => 'ヘッダーテキスト';

  @override
  String get themePreviewSecondary => 'セカンダリテキスト';

  @override
  String get themePreviewHint => 'ヒント / ターシャリテキスト';

  @override
  String get themePreviewGenerate => '生成';

  @override
  String get themePreviewEdit => '編集';

  @override
  String get cascadeEditorLabel => 'カスケードエディタ';

  @override
  String get cascadeSavedToLibrary => 'カスケードをライブラリに保存しました';

  @override
  String get cascadeNoBeatSelected => 'ビートが選択されていません';

  @override
  String get cascadeEnvironmentPrompt => '環境プロンプト';

  @override
  String get cascadeEnvHint => '例: 屋外、森、夜、シネマティックライティング';

  @override
  String get cascadeCharacterSlots => 'キャラクタースロット';

  @override
  String cascadeCharacterSlotN(int n) {
    return 'キャラクタースロット $n';
  }

  @override
  String get cascadePosition => 'ポジション';

  @override
  String get cascadeAiPosition => 'AIポジション';

  @override
  String get cascadePositivePrompt => 'ポジティブプロンプト';

  @override
  String get cascadeCharHint => 'キャラクタータグ、外見、状態...';

  @override
  String get cascadeNegativePrompt => 'ネガティブプロンプト';

  @override
  String get cascadeAvoidHint => '除外タグ...';

  @override
  String get cascadeLinkAction => 'アクションをリンク';

  @override
  String get cascadeBeatSettings => 'ビート設定';

  @override
  String get cascadeResolution => '解像度';

  @override
  String get cascadeSampler => 'サンプラー';

  @override
  String get cascadeSteps => 'ステップ';

  @override
  String get cascadeScale => 'スケール';

  @override
  String get cascadeStyles => 'スタイル';

  @override
  String get cascadeNoStyles => '利用可能なスタイルがありません';

  @override
  String get cascadeLibrary => 'カスケードライブラリ';

  @override
  String cascadeSequencesSaved(int count) {
    return '$countシーケンス保存済み';
  }

  @override
  String get cascadeNew => '新規カスケード';

  @override
  String get cascadeNoCascades => 'カスケードが見つかりません';

  @override
  String cascadeBeatsAndSlots(int beats, int slots) {
    return '$beatsビート・$slotsキャラクタースロット';
  }

  @override
  String get cascadeCreateNew => '新規カスケードを作成';

  @override
  String get cascadeName => 'カスケード名';

  @override
  String get cascadeCharSlotsLabel => 'キャラクタースロット';

  @override
  String get cascadeAutoPosition => '自動配置（AIに任せる）';

  @override
  String get cascadeDeleteTitle => 'カスケードを削除しますか？';

  @override
  String cascadeDeleteConfirm(String name) {
    return '「$name」を削除してもよろしいですか？';
  }

  @override
  String get cascadeSelect => 'カスケードを選択';

  @override
  String get cascadeNoSaved => '保存済みカスケードが見つかりません';

  @override
  String cascadeCharactersAndBeats(int chars, int beats) {
    return '$charsキャラクター・$beatsビート';
  }

  @override
  String cascadeCharTags(int n) {
    return 'キャラ$nタグ';
  }

  @override
  String get cascadeGlobalStyle => 'グローバルスタイル / インジェクション';

  @override
  String cascadeRegenerateBeat(int n) {
    return 'ビート$nを再生成';
  }

  @override
  String cascadeGenerateBeat(int n) {
    return 'ビート$nを生成';
  }

  @override
  String get cascadeSkipToNext => '次へスキップ';

  @override
  String get img2imgResult => '結果';

  @override
  String get img2imgSource => 'ソース';

  @override
  String get img2imgCanvas => 'キャンバス';

  @override
  String get img2imgUseAsSource => 'ソースとして使用';

  @override
  String get img2imgInpainting => 'インペインティング';

  @override
  String get img2imgTitle => 'IMG2IMG';

  @override
  String get img2imgEditorLabel => 'エディタ';

  @override
  String get img2imgBackToPicker => 'ピッカーに戻る';

  @override
  String get img2imgGenerating => '生成中...';

  @override
  String get img2imgGenerate => '生成';

  @override
  String img2imgGenerationFailed(String error) {
    return '生成に失敗しました: $error';
  }

  @override
  String get img2imgSettings => 'IMG2IMG設定';

  @override
  String get img2imgPrompt => 'プロンプト';

  @override
  String get img2imgPromptHint => '生成する内容を入力...';

  @override
  String get img2imgNegative => 'ネガティブ';

  @override
  String get img2imgNegativeHint => '不要な内容...';

  @override
  String get img2imgStrength => '強度';

  @override
  String get img2imgNoise => 'ノイズ';

  @override
  String get img2imgMaskBlur => 'マスクブラー';

  @override
  String get img2imgColorCorrect => '色補正';

  @override
  String get img2imgSourceInfo => 'ソース';

  @override
  String img2imgMaskStrokes(int count) {
    return 'マスク: $countストローク';
  }

  @override
  String get img2imgNoMask => 'マスクなし（全体IMG2IMG）';

  @override
  String get img2imgUploadFromDevice => 'デバイスからアップロード';

  @override
  String get img2imgUploadFromDeviceDesc => 'フォトライブラリまたはファイルから画像を選択';

  @override
  String get slideshowTitle => 'スライドショー';

  @override
  String get slideshowPlayAll => 'すべて再生';

  @override
  String get slideshowConfigs => '設定一覧';

  @override
  String get slideshowNewConfig => '新規設定';

  @override
  String get slideshowNoConfigs => 'スライドショー設定がありません。\n+をタップして作成してください。';

  @override
  String get slideshowSelectOrCreate => 'スライドショー設定を選択または作成';

  @override
  String get slideshowNameLabel => '名前';

  @override
  String get slideshowSourceLabel => 'ソース';

  @override
  String get slideshowTransition => 'トランジション';

  @override
  String get slideshowTransitionDuration => 'トランジション時間';

  @override
  String get slideshowTiming => 'タイミング';

  @override
  String get slideshowSlideDuration => 'スライド表示時間';

  @override
  String get slideshowKenBurns => 'ケンバーンズエフェクト';

  @override
  String get slideshowEnabled => '有効';

  @override
  String get slideshowIntensity => '強度';

  @override
  String get slideshowManualZoom => '手動ズーム';

  @override
  String get slideshowPlayback => '再生';

  @override
  String get slideshowShuffle => 'シャッフル';

  @override
  String get slideshowLoop => 'ループ';

  @override
  String get slideshowDefault => 'デフォルト';

  @override
  String get slideshowUseAsDefault => 'デフォルトスライドショーとして使用';

  @override
  String get slideshowPlay => 'スライドショーを再生';

  @override
  String get slideshowTransFade => 'フェード';

  @override
  String get slideshowTransSlideL => 'スライド左';

  @override
  String get slideshowTransSlideR => 'スライド右';

  @override
  String get slideshowTransSlideUp => 'スライド上';

  @override
  String get slideshowTransZoom => 'ズーム';

  @override
  String get slideshowTransXZoom => 'Xズーム';

  @override
  String get slideshowSourceAllImages => 'すべての画像';

  @override
  String get slideshowSourceAlbum => 'アルバム';

  @override
  String get slideshowSourceFavorites => 'お気に入り';

  @override
  String slideshowSourceCustom(int count) {
    return '$countカスタム';
  }

  @override
  String get slideshowDeleteConfig => '設定を削除';

  @override
  String slideshowDeleteConfirm(String name) {
    return '「$name」を削除しますか？';
  }

  @override
  String get slideshowImageSource => '画像ソース';

  @override
  String get slideshowAllImages => 'すべての画像';

  @override
  String slideshowImageCount(int count) {
    return '$count枚';
  }

  @override
  String get slideshowFavoritesLabel => 'お気に入り';

  @override
  String get slideshowAlbumLabel => 'アルバム';

  @override
  String get slideshowCustomSelection => 'カスタム選択';

  @override
  String slideshowSelectedCount(int count) {
    return '$count枚選択済み';
  }

  @override
  String get slideshowNoAlbums => 'アルバムが作成されていません';

  @override
  String get slideshowSelectAlbum => 'アルバムを選択';

  @override
  String slideshowCustomCount(int selected, int total) {
    return '$selected / $total枚選択済み';
  }

  @override
  String get slideshowDeselectAll => 'すべて選択解除';

  @override
  String get slideshowSelectAll => 'すべて選択';

  @override
  String get slideshowNoImages => '表示する画像がありません';

  @override
  String get slideshowGoBack => '戻る';

  @override
  String demoImagesSelected(int count) {
    return '$count枚選択済み';
  }

  @override
  String get demoAll => 'すべて';

  @override
  String get demoClear => 'クリア';

  @override
  String get demoNoImages => 'ギャラリーに画像がありません';

  @override
  String get cascadeBeatTimeline => 'ビートタイムライン';

  @override
  String cascadeBeatsCount(int count) {
    return '$countビート';
  }

  @override
  String cascadeBeatN(int n) {
    return 'ビート $n';
  }

  @override
  String get cascadeCloneBeat => 'ビートを複製';

  @override
  String get cascadeRemoveBeat => 'ビートを削除';
}
