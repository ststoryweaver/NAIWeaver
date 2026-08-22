// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get commonCancel => '取消';

  @override
  String get commonDelete => '删除';

  @override
  String get commonSave => '保存';

  @override
  String get commonClose => '关闭';

  @override
  String get commonCreate => '创建';

  @override
  String get commonRename => '重命名';

  @override
  String get commonConfirm => '确认';

  @override
  String get commonSet => '设置';

  @override
  String get commonNone => '无';

  @override
  String get commonExport => '导出';

  @override
  String get commonOverwrite => '覆盖';

  @override
  String get commonSaveChanges => '保存更改';

  @override
  String get mainGallery => '图库';

  @override
  String get mainTools => '工具';

  @override
  String get mainSave => '保存';

  @override
  String get mainExport => '导出';

  @override
  String get mainEdit => '编辑';

  @override
  String get mainEnterPrompt => '输入提示词';

  @override
  String get mainHelp => '帮助';

  @override
  String get mainAuthError => '认证错误：请检查 API 设置';

  @override
  String get mainSettings => '设置';

  @override
  String mainImportFailed(String error) {
    return '导入设置失败：$error';
  }

  @override
  String get mainSavePreset => '保存预设';

  @override
  String get mainPresetName => '预设名称';

  @override
  String get mainAdvancedSettings => '高级设置';

  @override
  String get mainExitConfirmation => '确定要退出吗？';

  @override
  String get settingsApiSettings => 'API 设置';

  @override
  String get settingsGeneralSettings => '通用设置';

  @override
  String get settingsUiSettings => '界面设置';

  @override
  String get settingsExport => '导出';

  @override
  String get settingsSecurity => '安全';

  @override
  String get settingsDemoMode => '演示模式';

  @override
  String get settingsLinks => '链接';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsApiKeyLabel => 'NovelAI API Key';

  @override
  String get settingsApiKeyHint => 'pst-xxxx...';

  @override
  String get settingsAutoSave => '自动保存图片';

  @override
  String get settingsAutoSaveDesc => '自动将所有生成的图片保存到输出文件夹';

  @override
  String get settingsSmartStyleImport => '智能风格导入';

  @override
  String get settingsSmartStyleImportDesc => '从导入的提示词中移除风格标签并恢复风格选择';

  @override
  String get settingsCharInsertTarget => '将保存的角色添加到编辑器';

  @override
  String get settingsCharInsertTargetDesc =>
      '在提示词框中选择保存的角色时，将添加角色卡片，而不是把标签插入主提示词';

  @override
  String get settingsRememberSession => '记住会话';

  @override
  String get settingsRememberSessionDesc => '自动保存提示词、设置和参考图，用于崩溃恢复';

  @override
  String get settingsImg2ImgImportPrompt => '图生图导入提示词';

  @override
  String get settingsImg2ImgImportPromptDesc => '选择带元数据的原图时自动填充图生图提示词';

  @override
  String get settingsSaveToAlbum => '保存到相册';

  @override
  String get settingsSaveToAlbumDesc => '自动将新生成的内容添加到此相册';

  @override
  String get settingsEditButton => '编辑按钮';

  @override
  String get settingsEditButtonDesc => '在图片查看器中显示编辑/重绘按钮';

  @override
  String get settingsDirectorRefShelf => '导演参考栏';

  @override
  String get settingsDirectorRefShelfDesc => '在主界面显示参考图栏';

  @override
  String get settingsVibeTransferShelf => '氛围迁移栏';

  @override
  String get settingsVibeTransferShelfDesc => '在主界面显示氛围迁移栏';

  @override
  String get settingsCharEditorMode => '角色编辑模式';

  @override
  String get settingsCharEditorModeDesc => '在设置面板使用展开式角色编辑器，而非紧凑栏';

  @override
  String get settingsThemeBuilder => '主题编辑器';

  @override
  String get settingsStripMetadata => '导出时移除元数据';

  @override
  String get settingsStripMetadataDesc => '从导出图片中移除生成信息（提示词、设置）';

  @override
  String get settingsPinLock => 'PIN 锁';

  @override
  String get settingsPinLockDesc => '打开应用需输入 4–8 位 PIN 码';

  @override
  String get settingsLockOnResume => '恢复时锁定';

  @override
  String get settingsLockOnResumeDesc => '从后台返回时重新锁定应用';

  @override
  String get settingsBiometricUnlock => '生物识别解锁';

  @override
  String get settingsBiometricUnlockDesc => '使用指纹或面容解锁';

  @override
  String get settingsBiometricsUnavailable => '此设备不支持生物识别';

  @override
  String get settingsSetPin => '设置 PIN';

  @override
  String get settingsPinDigitsHint => '4–8 位数字';

  @override
  String get settingsPinMustBeDigits => 'PIN 必须是 4–8 位数字';

  @override
  String get settingsPinsDoNotMatch => 'PIN 不一致';

  @override
  String get settingsEnterCurrentPin => '输入当前 PIN';

  @override
  String get settingsEnterPinHint => '输入 PIN';

  @override
  String get settingsIncorrectPin => 'PIN 错误';

  @override
  String get settingsDemoModeDesc => '图库中仅显示演示安全图片';

  @override
  String get settingsSelectDemoImages => '选择演示图片';

  @override
  String get settingsTagSuggestionsHidden => '演示模式开启时标签建议已隐藏';

  @override
  String get settingsPositivePrefix => '正向前缀';

  @override
  String get settingsNegativePrefix => '负向前缀';

  @override
  String get settingsEditPositivePrefix => '编辑正向前缀';

  @override
  String get settingsEditNegativePrefix => '编辑负向前缀';

  @override
  String get settingsDemoPrefixes => '演示前缀';

  @override
  String get settingsNotSet => '（未设置）';

  @override
  String get settingsGithubRepository => 'GitHub 仓库';

  @override
  String get settingsGithubPlaceholder => 'GitHub 链接占位符';

  @override
  String get galleryTitle => '图库';

  @override
  String get galleryDemoTitle => '图库（演示）';

  @override
  String get gallerySearchTags => '搜索标签…';

  @override
  String gallerySelectedCount(int count) {
    return '已选择 $count 项';
  }

  @override
  String get galleryDeselectAll => '取消全选';

  @override
  String get gallerySelectAll => '全选';

  @override
  String get galleryFavoritesFilter => '收藏筛选';

  @override
  String get gallerySort => '排序';

  @override
  String get gallerySelectMode => '选择模式';

  @override
  String galleryColumnsCount(int count) {
    return '$count 列';
  }

  @override
  String get gallerySortDateNewest => '日期（最新）';

  @override
  String get gallerySortDateOldest => '日期（最早）';

  @override
  String get gallerySortNameAZ => '名称（A-Z）';

  @override
  String get gallerySortNameZA => '名称（Z-A）';

  @override
  String get gallerySortSizeLargest => '大小（最大）';

  @override
  String get gallerySortSizeSmallest => '大小（最小）';

  @override
  String get galleryNoDemoImages => '未选择演示图片';

  @override
  String get galleryNoFavorites => '无收藏';

  @override
  String get galleryNoImagesInAlbum => '相册内无图片';

  @override
  String get galleryNoImagesFound => '未找到图片';

  @override
  String get galleryAll => '全部';

  @override
  String galleryCopiedCount(int count) {
    return '已复制 $count 项';
  }

  @override
  String galleryImagesCopiedCount(int count) {
    return '已复制 $count 张图片';
  }

  @override
  String galleryPasteInto(String name) {
    return '粘贴到 $name';
  }

  @override
  String galleryPastedIntoAlbum(int count, String name) {
    return '已将 $count 张图片粘贴到 $name';
  }

  @override
  String get galleryClearClipboard => '清空剪贴板';

  @override
  String get galleryNewAlbum => '新建相册';

  @override
  String get galleryAlbumName => '相册名称';

  @override
  String get galleryRenameAlbum => '重命名相册';

  @override
  String get galleryAddToAlbum => '添加到相册';

  @override
  String galleryDeleteCount(int count) {
    return '删除 $count 张图片？';
  }

  @override
  String get galleryCannotUndo => '此操作无法撤销。';

  @override
  String get galleryCompare => '对比';

  @override
  String get galleryCopy => '复制';

  @override
  String get galleryShare => '分享';

  @override
  String get galleryPaste => '粘贴';

  @override
  String get galleryAlbum => '相册';

  @override
  String get galleryFavorite => '收藏';

  @override
  String gallerySavedToDeviceCount(int saved, int total) {
    return '已保存 $saved/$total 到设备图库';
  }

  @override
  String galleryExportDialogTitle(int count) {
    return '导出 $count 张图片';
  }

  @override
  String galleryExportedToFolder(int count, String folder) {
    return '已导出 $count 张图片到 $folder';
  }

  @override
  String galleryExportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String galleryImagesCopied(int count) {
    return '$count 张图片已复制';
  }

  @override
  String galleryImagesPasted(int count) {
    return '$count 张图片已粘贴';
  }

  @override
  String get galleryDeleteImage => '删除图片？';

  @override
  String get gallerySavedToDevice => '已保存到设备图库';

  @override
  String get galleryExportImageDialog => '导出图片';

  @override
  String gallerySavedTo(String name) {
    return '已保存到 $name';
  }

  @override
  String get galleryToggleFavorite => '切换收藏';

  @override
  String get galleryExportImage => '导出图片';

  @override
  String get galleryDeleteImageTooltip => '删除图片';

  @override
  String get galleryNoPrompt => '无提示词';

  @override
  String get galleryNoMetadata => '无元数据';

  @override
  String get galleryPrompt => '提示词';

  @override
  String get galleryImg2img => '图生图';

  @override
  String get galleryCharRef => '角色参考';

  @override
  String get galleryVibe => '氛围';

  @override
  String get gallerySlideshow => '幻灯片';

  @override
  String get galleryAddedAsCharRef => '已添加为角色参考';

  @override
  String get galleryAddedAsVibe => '已添加为氛围迁移';

  @override
  String galleryVibeTransferFailed(String error) {
    return '氛围迁移失败：$error';
  }

  @override
  String get galleryScale => '缩放';

  @override
  String get gallerySteps => '步数';

  @override
  String get gallerySampler => '采样器';

  @override
  String get gallerySeed => '种子';

  @override
  String get galleryResolution => '分辨率';

  @override
  String get galleryEnhance => '增强';

  @override
  String get galleryDirectorTools => '导演工具';

  @override
  String get galleryImport => '导入图片';

  @override
  String get galleryImporting => '正在导入…';

  @override
  String galleryImportProgress(int current, int total) {
    return '正在导入 $current/$total…';
  }

  @override
  String get galleryImportPreparing => '正在准备…';

  @override
  String galleryImportSuccess(int count, int metadata) {
    return '已导入 $count 张图片（$metadata 张含 NovelAI 元数据）';
  }

  @override
  String galleryImportConverted(int count, int converted) {
    return '已导入 $count 张图片（$converted 张已转为 PNG）';
  }

  @override
  String galleryImportFailed(String error) {
    return '导入失败：$error';
  }

  @override
  String get panelAdvancedSettings => '高级设置';

  @override
  String get panelDimensions => '尺寸';

  @override
  String get panelSeed => '种子';

  @override
  String get panelCustom => '自定义';

  @override
  String get panelSteps => '步数';

  @override
  String get panelScale => '缩放';

  @override
  String get panelSampler => '采样器';

  @override
  String get panelPostProcessing => '后期处理';

  @override
  String get panelStyles => '风格';

  @override
  String get panelManageStyles => '管理风格';

  @override
  String get panelEnabled => '已启用';

  @override
  String get panelNoStylesDefined => '未定义任何风格';

  @override
  String get panelNegativePrompt => '负向提示词';

  @override
  String get panelPresets => '预设';

  @override
  String get panelNoPresetsSaved => '未保存任何预设';

  @override
  String get panelDeletePreset => '删除预设';

  @override
  String panelDeletePresetConfirm(String name) {
    return '删除「$name」？';
  }

  @override
  String get panelSaveToAlbum => '保存到相册';

  @override
  String get panelNew => '新建';

  @override
  String get panelNewAlbum => '新建相册';

  @override
  String get panelAlbumName => '相册名称';

  @override
  String get resNormalPortrait => '标准竖屏';

  @override
  String get resNormalLandscape => '标准横屏';

  @override
  String get resNormalSquare => '标准正方形';

  @override
  String get resLargePortrait => '大尺寸竖屏';

  @override
  String get resLargeLandscape => '大尺寸横屏';

  @override
  String get resLargeSquare => '大尺寸正方形';

  @override
  String get resWallpaperPortrait => '壁纸竖屏';

  @override
  String get resWallpaperLandscape => '壁纸横屏';

  @override
  String get toolsHub => '工具中心';

  @override
  String get toolsTitle => '工具';

  @override
  String get toolsWildcards => '随机提示词';

  @override
  String get toolsTagLibrary => '标签库';

  @override
  String get toolsPresets => '预设';

  @override
  String get toolsStyles => '风格';

  @override
  String get toolsReferences => '参考';

  @override
  String get toolsCascadeEditor => '分镜编辑器';

  @override
  String get toolsImg2imgEditor => '图生图编辑器';

  @override
  String get toolsSlideshow => '幻灯片';

  @override
  String get toolsPacks => '资源包';

  @override
  String get toolsTheme => '主题';

  @override
  String get toolsSettings => '设置';

  @override
  String get helpTitle => 'NAIWeaver';

  @override
  String get helpShortcuts => '快捷键';

  @override
  String get helpFeatures => '功能';

  @override
  String get helpShortcutWildcard => '从 wildcards/name.txt 随机抽取一行';

  @override
  String get helpShortcutWildcardBrowse => '浏览并插入随机提示词文件';

  @override
  String get helpShortcutHoldDismiss => '关闭标签建议';

  @override
  String get helpShortcutFavorites => '显示所有收藏标签';

  @override
  String get helpShortcutFavCategories => '按分类查看收藏';

  @override
  String get helpShortcutArtistPrefix => '筛选画师标签';

  @override
  String get helpShortcutSourceAction => '执行动作的角色';

  @override
  String get helpShortcutTargetAction => '接收动作的角色';

  @override
  String get helpShortcutMutualAction => '角色间互动动作';

  @override
  String get helpShortcutEnter => '生成（或选择标签建议）';

  @override
  String get helpShortcutDragDrop => '导入生成设置';

  @override
  String get helpFeatureGallery => '图库';

  @override
  String get helpFeatureGalleryDesc => '浏览、收藏、对比、相册分类';

  @override
  String get helpFeatureWildcards => '随机提示词';

  @override
  String get helpFeatureWildcardsDesc => '__pattern__ 从文本文件随机替换';

  @override
  String get helpFeatureStyles => '风格';

  @override
  String get helpFeatureStylesDesc => '自动在提示词中注入前缀/后缀/负向提示';

  @override
  String get helpFeaturePresets => '预设';

  @override
  String get helpFeaturePresetsDesc => '保存与恢复完整生成配置';

  @override
  String get helpFeatureDirectorRef => '导演参考';

  @override
  String get helpFeatureDirectorRefDesc => '用参考图控制角色/风格外观';

  @override
  String get helpFeatureVibeTransfer => '氛围迁移';

  @override
  String get helpFeatureVibeTransferDesc => '用参考图影响构图与氛围';

  @override
  String get helpFeatureCascade => '分镜';

  @override
  String get helpFeatureCascadeDesc => '多镜头连续场景生成';

  @override
  String get helpFeatureImg2img => '图生图';

  @override
  String get helpFeatureImg2imgDesc => '通过重绘与变体编辑/优化图片';

  @override
  String get helpFeatureThemes => '主题';

  @override
  String get helpFeatureThemesDesc => '自定义所有颜色、字体和缩放';

  @override
  String get helpFeaturePacks => '资源包';

  @override
  String get helpFeaturePacksDesc => '将预设、风格、随机提示词导出/导入为 .vpack';

  @override
  String get wildcardManager => '随机提示词管理器';

  @override
  String get wildcardManageDesc => '管理和编辑你的随机提示词文件';

  @override
  String get wildcardFiles => '文件';

  @override
  String get wildcardNew => '新建随机提示词';

  @override
  String get wildcardSelectOrCreate => '选择或创建随机提示词文件';

  @override
  String get wildcardValidateTags => '校验标签';

  @override
  String wildcardRecognized(int valid, int total) {
    return '$valid/$total 已识别';
  }

  @override
  String get wildcardClear => '清空';

  @override
  String get wildcardStartTyping => '开始输入标签…';

  @override
  String wildcardUnrecognized(int count) {
    return '$count 个未识别';
  }

  @override
  String get wildcardCreateTitle => '创建随机提示词';

  @override
  String get wildcardFileName => '文件名';

  @override
  String get wildcardHelp => '随机提示词帮助';

  @override
  String get wildcardHelpTitle => '随机提示词帮助';

  @override
  String get wildcardHelpRandom => '__name__ 从该随机提示词文件随机抽取一行';

  @override
  String get wildcardHelpDotSyntax => '多词名称使用点号';

  @override
  String get wildcardHelpBrowse => '输入 __ 浏览并从自动补全插入随机提示词';

  @override
  String get wildcardHelpNesting => '嵌套';

  @override
  String get wildcardHelpNestingDesc => '随机提示词可引用其他随机提示词（最深 5 层）';

  @override
  String get wildcardHelpTip => '拖动可重新排序文件 — 顺序会用于自动补全';

  @override
  String get wildcardMode => '模式';

  @override
  String get wildcardModeRandom => '随机';

  @override
  String get wildcardModeRandomDesc => '每次使用随机抽取一行';

  @override
  String get wildcardModeSequential => '顺序';

  @override
  String get wildcardModeSequentialDesc => '按顺序循环抽取';

  @override
  String get wildcardModeShuffle => '洗牌';

  @override
  String get wildcardModeShuffleDesc => '先随机打乱所有行，再无重复循环';

  @override
  String get wildcardModeWeighted => '加权';

  @override
  String get wildcardModeWeightedDesc => '使用权重语法（如 10::选项）控制抽取概率';

  @override
  String get wildcardHelpFavorites => '收藏的随机提示词会在标签补全中显示金色边框';

  @override
  String get wildcardDeleteTitle => '删除随机提示词';

  @override
  String wildcardDeleteConfirm(String name) {
    return '确定要删除 \'\'$name\'\' 吗？';
  }

  @override
  String get wildcardRenameTitle => '重命名随机提示词';

  @override
  String get wildcardRenameExists => '已存在同名的随机提示词';

  @override
  String get tagLibTitle => '标签库';

  @override
  String get tagLibPreviewSettings => '预览设置';

  @override
  String get tagLibAddTag => '添加标签';

  @override
  String get tagLibSearchTags => '搜索标签…';

  @override
  String get tagLibAll => '全部';

  @override
  String get tagLibFavorites => '收藏';

  @override
  String get tagLibImages => '图片';

  @override
  String get tagLibSort => '排序：';

  @override
  String get tagLibSortCountDesc => '数量 ↓';

  @override
  String get tagLibSortCountAsc => '数量 ↑';

  @override
  String get tagLibSortAZ => 'A-Z';

  @override
  String get tagLibSortZA => 'Z-A';

  @override
  String get tagLibSortFavsFirst => '收藏优先';

  @override
  String tagLibTagCount(int count) {
    return '$count 个标签';
  }

  @override
  String get tagLibDeleteTag => '删除标签';

  @override
  String tagLibRemoveConfirm(String tag) {
    return '从库中移除「$tag」？';
  }

  @override
  String get tagLibTestTag => '测试标签';

  @override
  String get tagLibAddNewTag => '添加新标签';

  @override
  String get tagLibTagName => '标签名';

  @override
  String get tagLibCount => '数量';

  @override
  String get tagLibAddTagBtn => '添加标签';

  @override
  String get tagLibDeleteExample => '删除示例';

  @override
  String get tagLibDeleteExampleConfirm => '删除此视觉示例？';

  @override
  String tagLibTesting(String tag) {
    return '正在测试：$tag';
  }

  @override
  String get tagLibGeneratingPreview => '正在生成预览…';

  @override
  String get tagLibGenerationFailed => '生成失败';

  @override
  String get tagLibExampleSaved => '示例已保存';

  @override
  String get tagLibSaveAsExample => '保存为示例';

  @override
  String get tagLibPreviewSettingsTitle => '预览设置';

  @override
  String get tagLibPositivePromptBase => '正向提示词（基础）';

  @override
  String get tagLibNegativePrompt => '负向提示词';

  @override
  String get tagLibSampler => '采样器';

  @override
  String get tagLibSteps => '步数';

  @override
  String get tagLibWidth => '宽度';

  @override
  String get tagLibHeight => '高度';

  @override
  String get tagLibScale => '缩放';

  @override
  String get tagLibSeed => '种子';

  @override
  String get tagLibRandom => '随机';

  @override
  String get presetManager => '预设管理器';

  @override
  String get presetManageDesc => '管理和编辑生成预设';

  @override
  String get presetList => '预设';

  @override
  String get presetNew => '新建预设';

  @override
  String presetCharsInfo(int chars, int ints) {
    return '$chars 角色，$ints 互动';
  }

  @override
  String presetCharsRefsInfo(int chars, int ints, int refs) {
    return '$chars 角色，$ints 互动，$refs 参考';
  }

  @override
  String get presetSelectToEdit => '选择要编辑的预设';

  @override
  String get presetIdentity => '标识';

  @override
  String get presetName => '名称';

  @override
  String get presetPrompts => '提示词';

  @override
  String get presetPrompt => '提示词';

  @override
  String get presetNegativePrompt => '负向提示词';

  @override
  String get presetGenSettings => '生成设置';

  @override
  String get presetWidth => '宽度';

  @override
  String get presetHeight => '高度';

  @override
  String get presetScale => '缩放';

  @override
  String get presetSteps => '步数';

  @override
  String get presetSampler => '采样器';

  @override
  String get presetCharsAndInteractions => '角色与互动';

  @override
  String get presetNoChars => '此预设未保存角色';

  @override
  String presetCharacterN(int n) {
    return '角色 $n';
  }

  @override
  String get presetInteractions => '互动';

  @override
  String get presetReferences => '参考';

  @override
  String get presetNoRefs => '此预设未保存参考';

  @override
  String get presetProcessing => '处理中…';

  @override
  String get presetAddReference => '添加参考';

  @override
  String get presetDeleteTitle => '删除预设';

  @override
  String presetDeleteConfirm(String name) {
    return '确定要删除「$name」吗？';
  }

  @override
  String get presetOverwriteTitle => '覆盖预设';

  @override
  String presetOverwriteConfirm(String name) {
    return '名为「$name」的预设已存在。是否覆盖？';
  }

  @override
  String get styleEditor => '风格编辑器';

  @override
  String get styleManageDesc => '管理提示词片段和风格标签';

  @override
  String get styleList => '风格';

  @override
  String get styleNew => '新建风格';

  @override
  String get styleResetDefaults => '重置风格为默认值';

  @override
  String get styleSelectToEdit => '选择要编辑的风格';

  @override
  String get styleIdentity => '标识';

  @override
  String get styleName => '名称';

  @override
  String get styleDefaultOnLaunch => '启动时默认启用';

  @override
  String get styleTargetPrompt => '目标提示词';

  @override
  String get stylePositive => '正向';

  @override
  String get styleNegative => '负向';

  @override
  String get styleNegativeContent => '负向内容';

  @override
  String get stylePositiveContent => '正向内容';

  @override
  String get styleContent => '内容';

  @override
  String get stylePlacement => '位置';

  @override
  String get styleBeginningPrefix => '开头（前缀）';

  @override
  String get styleEndSuffix => '结尾（后缀）';

  @override
  String get styleDeleteTitle => '删除风格';

  @override
  String styleDeleteConfirm(String name) {
    return '确定要删除「$name」吗？';
  }

  @override
  String get styleOverwriteTitle => '覆盖风格';

  @override
  String styleOverwriteConfirm(String name) {
    return '名为「$name」的风格已存在。是否覆盖？';
  }

  @override
  String get refPreciseReferences => '精准参考';

  @override
  String get refVibeTransfer => '氛围迁移';

  @override
  String get refDialogCancel => '取消';

  @override
  String get refDialogSave => '保存';

  @override
  String get refNameHint => '名称';

  @override
  String get refClearAll => '清空全部';

  @override
  String get refSavedSection => '已保存';

  @override
  String get refSaveReference => '保存参考';

  @override
  String refReferenceCount(int count) {
    return '$count 个参考';
  }

  @override
  String get refNoReferencesAdded => '未添加任何参考';

  @override
  String get refEmptyDescription => '上传参考图以在生成中保持角色外观或艺术风格。';

  @override
  String get refAddReference => '添加参考';

  @override
  String get refEditorTitle => '参考编辑器';

  @override
  String get refTypeLabel => '参考类型';

  @override
  String get refStrength => '强度';

  @override
  String get refFidelity => '保真度';

  @override
  String get refStrengthShort => '强';

  @override
  String get refFidelityShort => '保';

  @override
  String get refTypeCharacter => '角色';

  @override
  String get refTypeStyle => '风格';

  @override
  String get refTypeCharAndStyle => '角色+风格';

  @override
  String get refSaveVibe => '保存氛围';

  @override
  String get refVibeTransfers => '氛围迁移';

  @override
  String refVibeCount(int count) {
    return '$count 个氛围';
  }

  @override
  String get refNoVibesAdded => '未添加任何氛围';

  @override
  String get refVibeEmptyDescription => '上传参考图以将艺术风格和氛围迁移到生成内容。';

  @override
  String get refAddVibe => '添加氛围';

  @override
  String get refVibeLabel => '氛围';

  @override
  String get refVibeEditorTitle => '氛围编辑器';

  @override
  String get refInfoExtracted => '信息已提取';

  @override
  String get refInfoExtractedShort => '信';

  @override
  String get refApiKeyMissing => '缺少或无效的 API Key';

  @override
  String refVibeEncodeFailed(String error) {
    return '氛围编码失败：$error';
  }

  @override
  String get refLoadSaved => '加载已保存';

  @override
  String get refPickImage => '选择图片';

  @override
  String get refBrowseFiles => '浏览文件';

  @override
  String get refNoSavedRefs => '暂无已保存的参考';

  @override
  String get packTitle => 'NAIWeaver 资源包';

  @override
  String get packDesc => '将预设、风格、随机提示词导出/导入为 .vpack 文件。';

  @override
  String get packExportLabel => '导出包';

  @override
  String get packExportDesc => '打包预设、风格和随机提示词';

  @override
  String get packImportLabel => '导入包';

  @override
  String get packImportDesc => '加载 .vpack 文件';

  @override
  String get packGalleryExport => '图库导出';

  @override
  String get packGalleryExportDesc => '将图库图片按相册文件夹导出为 ZIP。';

  @override
  String get packExportGalleryZip => '导出图库为 ZIP';

  @override
  String get packExportGalleryZipDesc => '保留相册文件夹结构';

  @override
  String get packImportDialogTitle => '导入 NAIWeaver 包';

  @override
  String packFailedRead(String error) {
    return '读取包失败：$error';
  }

  @override
  String get packExportDialogTitle => '导出包';

  @override
  String get packName => '包名称';

  @override
  String get packDescriptionOptional => '描述（可选）';

  @override
  String packPresetsSection(int selected, int total) {
    return '预设（$selected/$total）';
  }

  @override
  String packStylesSection(int selected, int total) {
    return '风格（$selected/$total）';
  }

  @override
  String packWildcardsSection(int selected, int total) {
    return '随机提示词（$selected/$total）';
  }

  @override
  String packSavedRefsSection(int selected, int total) {
    return '已保存的参考 ($selected/$total)';
  }

  @override
  String packSavedVibesSection(int selected, int total) {
    return '已保存的氛围 ($selected/$total)';
  }

  @override
  String packCharacterPresetsSection(int selected, int total) {
    return '角色预设 ($selected/$total)';
  }

  @override
  String packThemesSection(int selected, int total) {
    return '主题 ($selected/$total)';
  }

  @override
  String packAlbumsSection(int selected, int total) {
    return '相册 ($selected/$total)';
  }

  @override
  String get packSettingsSection => '应用与点唱机设置';

  @override
  String get packSettingsItem => '应用与点唱机设置';

  @override
  String get packImportRestartHint => '已导入。请重启应用以完全应用设置和主题。';

  @override
  String get packExportSuccess => '包导出成功';

  @override
  String packExportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String get packImportDialogTitle2 => '导入包';

  @override
  String packImportCount(int count) {
    return '导入（$count）';
  }

  @override
  String get packImportSuccess => '包导入成功';

  @override
  String packImportFailed(String error) {
    return '导入失败：$error';
  }

  @override
  String get packExportGalleryTitle => '导出图库';

  @override
  String get packAlbums => '相册';

  @override
  String packUnsortedCount(int count) {
    return '未分类（$count）';
  }

  @override
  String get packOptions => '选项';

  @override
  String get packStripMetadata => '移除元数据';

  @override
  String get packFavoritesOnly => '仅收藏';

  @override
  String packExportCount(int count) {
    return '导出（$count）';
  }

  @override
  String get packSaveDialogTitle => '保存 NAIWeaver 包';

  @override
  String get packExportGalleryZipDialog => '导出图库 ZIP';

  @override
  String packExportedToZip(int count) {
    return '已导出 $count 张图片到 ZIP';
  }

  @override
  String get themeSelectToEdit => '选择要编辑的主题';

  @override
  String get themeList => '主题';

  @override
  String get themeNew => '新建主题';

  @override
  String get themeSave => '保存';

  @override
  String get themeReset => '重置';

  @override
  String get themePreview => '预览';

  @override
  String get themeColors => '颜色';

  @override
  String get themeColorBackground => '背景';

  @override
  String get themeColorSurfaceHigh => '上层界面';

  @override
  String get themeColorSurfaceMid => '中层界面';

  @override
  String get themeColorTextPrimary => '主要文字';

  @override
  String get themeColorTextSecondary => '次要文字';

  @override
  String get themeColorTextTertiary => '三级文字';

  @override
  String get themeColorTextDisabled => '禁用文字';

  @override
  String get themeColorTextMinimal => '极简文字';

  @override
  String get themeColorBorderStrong => '强边框';

  @override
  String get themeColorBorderMedium => '中等边框';

  @override
  String get themeColorBorderSubtle => '弱边框';

  @override
  String get themeColorAccent => '强调色';

  @override
  String get themeColorAccentEdit => '编辑强调色';

  @override
  String get themeColorAccentSuccess => '成功强调色';

  @override
  String get themeColorAccentDanger => '危险强调色';

  @override
  String get themeColorLogo => 'Logo';

  @override
  String get themeColorCascade => '分镜';

  @override
  String get themeReferences => '参考';

  @override
  String get themeColorVibeTransfer => '氛围迁移';

  @override
  String get themeColorRefCharacter => '角色参考';

  @override
  String get themeColorRefStyle => '风格参考';

  @override
  String get themeColorRefCharStyle => '角色+风格参考';

  @override
  String get themeColorFavorite => '收藏';

  @override
  String get themeColorCharacter => '角色';

  @override
  String get themeColorPositive => '正向';

  @override
  String get themeColorNegative => '负向';

  @override
  String get themeFont => '字体';

  @override
  String get themeTextScale => '文字大小';

  @override
  String get themeHeaderScale => '标题大小';

  @override
  String get themeTitleScale => '面板标题大小';

  @override
  String get themeButtonScale => '按钮大小';

  @override
  String get themeSmall => '小';

  @override
  String get themeLarge => '大';

  @override
  String get themePromptInput => '提示词输入框';

  @override
  String get themeFontSize => '字号';

  @override
  String get themeHeightLabel => '高度';

  @override
  String themeLines(int count) {
    return '$count 行';
  }

  @override
  String get themeBrightMode => '明亮模式';

  @override
  String get themeBrightText => '明亮文字';

  @override
  String get themeBrightDesc => '使用更亮的文字颜色以提升可读性';

  @override
  String get themePanelLayout => '面板布局';

  @override
  String get themePanelLayoutDesc => '拖动可重新排序高级设置区域';

  @override
  String get themeDeleteTitle => '删除主题';

  @override
  String themeDeleteConfirm(String name) {
    return '确定要删除「$name」吗？';
  }

  @override
  String get themeNewTitle => '新建主题';

  @override
  String get themeCustomTheme => '自定义主题';

  @override
  String get themeThemeName => '主题名称';

  @override
  String themeCreateFailed(String error) {
    return '创建主题失败：$error';
  }

  @override
  String get themeSectionModel => 'MODEL';

  @override
  String get themeSectionDimSeed => '尺寸 + 种子';

  @override
  String get themeSectionStepsScale => '步数 + 缩放';

  @override
  String get themeSectionSamplerPost => '采样器 + 后期';

  @override
  String get themeSectionStyles => '风格';

  @override
  String get themeSectionNegPrompt => '负向提示词';

  @override
  String get themeSectionPresets => '预设';

  @override
  String get themeSectionSaveAlbum => '保存到相册';

  @override
  String get themePreviewHeader => '标题文字';

  @override
  String get themePreviewSecondary => '次要文字内容';

  @override
  String get themePreviewHint => '提示 / 三级文字';

  @override
  String get themePreviewGenerate => '生成';

  @override
  String get themePreviewEdit => '编辑';

  @override
  String get cascadeEditorLabel => '分镜编辑器';

  @override
  String get cascadeSavedToLibrary => '分镜已保存到库';

  @override
  String get cascadeNoBeatSelected => '未选择镜头';

  @override
  String get cascadeScenePrompt => '场景 / 动作';

  @override
  String get cascadeSceneSubLabel => '发生什么 + 取景';

  @override
  String get cascadeSceneHint =>
      '正在发生什么：如 2girls, hugging, wide shot, from above';

  @override
  String get cascadeEnvironmentPrompt => '环境提示词';

  @override
  String get cascadeEnvSubLabel => '发生的地点';

  @override
  String get cascadeEnvHint => '地点：如 森林、夜晚、室内、电影光';

  @override
  String get cascadeApplyToAll => '应用到全部';

  @override
  String get cascadeSceneApplied => '场景已应用到所有节拍';

  @override
  String get cascadeCharacterSlots => '角色槽位';

  @override
  String cascadeCharacterSlotN(int n) {
    return '角色槽位 $n';
  }

  @override
  String get cascadePosition => '位置';

  @override
  String get cascadeAiPosition => 'AI 位置';

  @override
  String get cascadePositivePrompt => '正向提示词';

  @override
  String get cascadeCharHint => '角色标签、外观、状态…';

  @override
  String get cascadeNegativePrompt => '负向提示词';

  @override
  String get cascadeAvoidHint => '不想要的内容…';

  @override
  String get cascadeLinkAction => '关联动作';

  @override
  String get cascadeBeatSettings => '镜头设置';

  @override
  String get cascadeResolution => '分辨率';

  @override
  String get cascadeSampler => '采样器';

  @override
  String get cascadeSteps => '步数';

  @override
  String get cascadeScale => '缩放';

  @override
  String get cascadeStyles => '风格';

  @override
  String get cascadeNoStyles => '无可用风格';

  @override
  String get cascadeLibrary => '分镜库';

  @override
  String cascadeSequencesSaved(int count) {
    return '已保存 $count 个序列';
  }

  @override
  String get cascadeNew => '新建分镜';

  @override
  String get cascadeNoCascades => '未找到分镜';

  @override
  String cascadeBeatsAndSlots(int beats, int slots) {
    return '$beats 镜头 • $slots 角色槽';
  }

  @override
  String get cascadeCreateNew => '创建分镜';

  @override
  String get cascadeName => '分镜名称';

  @override
  String get cascadeCharSlotsLabel => '角色槽位';

  @override
  String get cascadeAutoPosition => '自动位置（由 AI 决定）';

  @override
  String get cascadeDeleteTitle => '删除分镜？';

  @override
  String cascadeDeleteConfirm(String name) {
    return '确定要删除「$name」吗？';
  }

  @override
  String get cascadeSelect => '选择分镜';

  @override
  String get cascadeNoSaved => '未找到保存的分镜';

  @override
  String cascadeCharactersAndBeats(int chars, int beats) {
    return '$chars 角色 • $beats 镜头';
  }

  @override
  String cascadeCharTags(int n) {
    return '角色 $n 标签';
  }

  @override
  String get cascadeGlobalScene => '全局场景（应用于每个镜头的标签）';

  @override
  String get cascadeGlobalStyle => '全局风格 / 注入';

  @override
  String get cascadeCaptionHint => '为该镜头添加旁白...（显示在预览上）';

  @override
  String get cascadeCaptionToggle => '显示 / 隐藏字幕';

  @override
  String get cascadeExportTooltip => '导出（带字幕）';

  @override
  String get cascadeExportBeat => '导出该镜头（字幕已烧录）';

  @override
  String get cascadeExportStripVertical => '故事板 — 纵向';

  @override
  String get cascadeExportStripHorizontal => '故事板 — 横向';

  @override
  String get cascadeExportSaved => '已导出';

  @override
  String get cascadeExportFailed => '导出失败';

  @override
  String get cascadeStripDownscaled => '故事板已缩小以适应内存限制';

  @override
  String cascadeRegenerateBeat(int n) {
    return '重新生成镜头 $n';
  }

  @override
  String cascadeGenerateBeat(int n) {
    return '生成镜头 $n';
  }

  @override
  String get cascadeSkipToNext => '跳到下一个';

  @override
  String get cascadeBeatRenderError => '无法构建此镜头。请检查是否已设置角色外观。';

  @override
  String get cascadeStartCasting => '分配角色';

  @override
  String get cascadeBackToLibrary => '库';

  @override
  String get cascadeUnsavedTitle => '有未保存更改';

  @override
  String get cascadeUnsavedMessage => '此分镜有未保存更改，是否放弃？';

  @override
  String get cascadeDiscard => '放弃';

  @override
  String get cascadeExitCascade => '退出分镜';

  @override
  String get img2imgResult => '结果';

  @override
  String get img2imgSource => '原图';

  @override
  String get img2imgCanvas => '画布';

  @override
  String get img2imgUseAsSource => '设为原图';

  @override
  String get img2imgInpainting => '局部重绘';

  @override
  String get img2imgTitle => '图生图';

  @override
  String get img2imgEditorLabel => '编辑器';

  @override
  String get img2imgBackToPicker => '返回选择器';

  @override
  String get img2imgGenerating => '生成中…';

  @override
  String get img2imgGenerate => '生成';

  @override
  String img2imgGenerationFailed(String error) {
    return '生成失败：$error';
  }

  @override
  String get img2imgSettings => '图生图设置';

  @override
  String get img2imgPrompt => '提示词';

  @override
  String get img2imgPromptHint => '描述要生成的内容…';

  @override
  String get img2imgNegative => '负向';

  @override
  String get img2imgNegativeHint => '不想要的内容…';

  @override
  String get img2imgStrength => '强度';

  @override
  String get img2imgNoise => '噪声';

  @override
  String get img2imgMaskBlur => '蒙版模糊';

  @override
  String get img2imgColorCorrect => '色彩校正';

  @override
  String get img2imgSourceInfo => '原图信息';

  @override
  String img2imgMaskStrokes(int count) {
    return '蒙版：$count 笔';
  }

  @override
  String get img2imgNoMask => '无蒙版（全图生图）';

  @override
  String get img2imgImportPrompt => '导入提示词';

  @override
  String get img2imgImportPromptDesc => '从原图元数据自动填充提示词';

  @override
  String get img2imgUploadFromDevice => '从设备上传';

  @override
  String get img2imgUploadFromDeviceDesc => '从相册或文件选择图片';

  @override
  String get img2imgBlankCanvas => '空白画布';

  @override
  String get img2imgBlankCanvasDesc => '创建空白画布进行绘制';

  @override
  String get img2imgBlankCanvasSize => '画布尺寸';

  @override
  String get slideshowTitle => '幻灯片';

  @override
  String get slideshowPlayAll => '播放全部';

  @override
  String get slideshowConfigs => '配置';

  @override
  String get slideshowNewConfig => '新建配置';

  @override
  String get slideshowNoConfigs => '暂无幻灯片配置。\n点击 + 创建。';

  @override
  String get slideshowSelectOrCreate => '选择或创建幻灯片配置';

  @override
  String get slideshowNameLabel => '名称';

  @override
  String get slideshowSourceLabel => '来源';

  @override
  String get slideshowTransition => '转场';

  @override
  String get slideshowTransitionDuration => '转场时长';

  @override
  String get slideshowTiming => '时序';

  @override
  String get slideshowSlideDuration => '单张时长';

  @override
  String get slideshowKenBurns => '动态缩放效果';

  @override
  String get slideshowEnabled => '已启用';

  @override
  String get slideshowIntensity => '强度';

  @override
  String get slideshowManualZoom => '手动缩放';

  @override
  String get slideshowPlayback => '播放';

  @override
  String get slideshowShuffle => '随机';

  @override
  String get slideshowLoop => '循环';

  @override
  String get slideshowDefault => '默认';

  @override
  String get slideshowUseAsDefault => '设为默认幻灯片';

  @override
  String get slideshowPlay => '播放幻灯片';

  @override
  String get slideshowTransFade => '淡入淡出';

  @override
  String get slideshowTransSlideL => '左滑';

  @override
  String get slideshowTransSlideR => '右滑';

  @override
  String get slideshowTransSlideUp => '上滑';

  @override
  String get slideshowTransZoom => '缩放';

  @override
  String get slideshowTransXZoom => '横向缩放';

  @override
  String get slideshowSourceAllImages => '所有图片';

  @override
  String get slideshowSourceAlbum => '相册';

  @override
  String get slideshowSourceFavorites => '收藏';

  @override
  String slideshowSourceCustom(int count) {
    return '$count 自定义';
  }

  @override
  String get slideshowDeleteConfig => '删除配置';

  @override
  String slideshowDeleteConfirm(String name) {
    return '删除「$name」？';
  }

  @override
  String get slideshowImageSource => '图片来源';

  @override
  String get slideshowAllImages => '所有图片';

  @override
  String slideshowImageCount(int count) {
    return '$count 张图片';
  }

  @override
  String get slideshowFavoritesLabel => '收藏';

  @override
  String get slideshowAlbumLabel => '相册';

  @override
  String get slideshowCustomSelection => '自定义选择';

  @override
  String slideshowSelectedCount(int count) {
    return '已选择 $count 项';
  }

  @override
  String get slideshowNoAlbums => '未创建相册';

  @override
  String get slideshowSelectAlbum => '选择相册';

  @override
  String slideshowCustomCount(int selected, int total) {
    return '$selected/$total 已选择';
  }

  @override
  String get slideshowDeselectAll => '取消全选';

  @override
  String get slideshowSelectAll => '全选';

  @override
  String get slideshowNoImages => '无图片可显示';

  @override
  String get slideshowGoBack => '返回';

  @override
  String demoImagesSelected(int count) {
    return '已选择 $count 张图片';
  }

  @override
  String get demoAll => '全部';

  @override
  String get demoClear => '清空';

  @override
  String get demoNoImages => '图库无图片';

  @override
  String get cascadeBeatTimeline => '镜头时间线';

  @override
  String cascadeBeatsCount(int count) {
    return '$count 个镜头';
  }

  @override
  String cascadeBeatN(int n) {
    return '镜头 $n';
  }

  @override
  String get cascadeCloneBeat => '复制镜头';

  @override
  String get cascadeRemoveBeat => '移除镜头';

  @override
  String get settingsCheckForUpdates => '检查更新';

  @override
  String get settingsUpdateAvailable => '有更新可用';

  @override
  String settingsUpdateAvailableDesc(String version) {
    return '新版本 $version 已可用。';
  }

  @override
  String get settingsUpdateDownload => '下载';

  @override
  String get settingsUpToDate => '已是最新版本！';

  @override
  String get settingsUpdateCheckFailed => '检查更新失败';

  @override
  String get settingsUpdateDownloading => '正在下载更新…';

  @override
  String settingsUpdateProgress(String received, String total) {
    return '$received / $total';
  }

  @override
  String get settingsUpdateInstalling => '正在启动安装程序…';

  @override
  String get settingsUpdateRestartPrompt => 'NAIWeaver 将关闭以应用更新，然后自动重新打开。';

  @override
  String get settingsUpdateDownloadFailed => '下载失败';

  @override
  String get settingsUpdateInstallFailed => '无法启动安装程序';

  @override
  String get settingsUpdateSkipVersion => '跳过此版本';

  @override
  String get settingsUpdateOpenInBrowser => '在浏览器中打开';

  @override
  String get settingsUpdateApply => '更新并重启';

  @override
  String get mainAnlas => 'Anlas';

  @override
  String get settingsAnlasTracker => 'Anlas 追踪';

  @override
  String get settingsAnlasTrackerDesc => '在顶部栏显示 Anlas 余额';

  @override
  String get canvasEditorTitle => '画布编辑器';

  @override
  String get canvasEditInCanvas => '画布';

  @override
  String get canvasPaint => '画笔';

  @override
  String get canvasErase => '擦除';

  @override
  String get canvasSize => '大小';

  @override
  String get canvasOpacity => '不透明度';

  @override
  String get canvasUndo => '撤销';

  @override
  String get canvasRedo => '重做';

  @override
  String get canvasClear => '清空所有笔触';

  @override
  String get canvasFlatten => '合并图层';

  @override
  String get canvasFlattenSend => '合并并发送';

  @override
  String get canvasBack => '返回图生图';

  @override
  String get canvasDiscardTitle => '放弃更改？';

  @override
  String get canvasDiscardMessage => '你有未保存的画笔笔触，是否放弃？';

  @override
  String get canvasDiscard => '放弃';

  @override
  String canvasFlattenFailed(String error) {
    return '合并失败：$error';
  }

  @override
  String get canvasFlattening => '合并中…';

  @override
  String get canvasRestoreSession => '检测到上一次画布会话，是否恢复？';

  @override
  String get canvasRestore => '恢复';

  @override
  String get canvasAutoSave => '画布自动保存';

  @override
  String get canvasAutoSaveDesc => '自动保存画布编辑会话用于崩溃恢复';

  @override
  String get canvasColor => '颜色';

  @override
  String get canvasLayers => '图层';

  @override
  String get canvasLayerAdd => '添加图层';

  @override
  String get canvasLayerDelete => '删除图层';

  @override
  String get canvasLayerDuplicate => '复制图层';

  @override
  String get canvasLayerRename => '重命名';

  @override
  String get canvasLayerVisible => '可见';

  @override
  String get canvasLayerHidden => '隐藏';

  @override
  String get canvasLayerOpacity => '不透明度';

  @override
  String get canvasLayerBlendMode => '混合模式';

  @override
  String get canvasLayerDeleteConfirm => '删除此图层？笔触将会丢失。';

  @override
  String canvasLayerDefault(int number) {
    return '图层 $number';
  }

  @override
  String get canvasLayerClear => '清空图层';

  @override
  String get canvasLayerClearConfirm => '清空此图层所有笔触？';

  @override
  String get canvasLine => '直线';

  @override
  String get canvasRectangle => '矩形';

  @override
  String get canvasCircle => '圆形';

  @override
  String get canvasEyedropper => '取色';

  @override
  String get canvasTransform => '移动';

  @override
  String get canvasImportImage => '导入图片';

  @override
  String get canvasHelp => '画布帮助';

  @override
  String get canvasSmooth => '平滑';

  @override
  String get canvasFill => '填充';

  @override
  String get canvasText => '文字';

  @override
  String get canvasTextHint => '输入文字…';

  @override
  String get canvasTextSize => '大小';

  @override
  String get canvasTextPlace => '放置';

  @override
  String get canvasTextFont => '字体';

  @override
  String get canvasTextSpacing => '间距';

  @override
  String get canvasTextDefault => '默认';

  @override
  String get canvasBlendNormal => '正常';

  @override
  String get canvasBlendMultiply => '正片叠底';

  @override
  String get canvasBlendScreen => '滤色';

  @override
  String get canvasBlendOverlay => '叠加';

  @override
  String get settingsOutputFolder => '输出文件夹';

  @override
  String get settingsOutputFolderDesc => '选择生成图片的保存位置';

  @override
  String get settingsFilenamePattern => '文件名模式';

  @override
  String get settingsFilenamePatternDesc =>
      '保存图像的自定义名称。可用标记: <prompt>, <seed>, <album:fallback>, <year>, <month>, <day>, <hours>, <minutes>, <seconds>, <date>, <time>, <digits:0000>。留空使用 NAI 风格默认值。';

  @override
  String get settingsSavePathPattern => '保存子文件夹模式';

  @override
  String get settingsSavePathPatternDesc =>
      '在输出文件夹下自动创建子文件夹，例如 <year>/<month>/<day>。使用相同标记。留空则不创建。';

  @override
  String get settingsPatternPreview => '预览';

  @override
  String get settingsOutputFolderDefault => '默认（应用存储）';

  @override
  String get settingsOutputFolderBrowse => '浏览';

  @override
  String get settingsOutputFolderClear => '清空';

  @override
  String get settingsUseSdCard => '使用SD卡';

  @override
  String get settingsSdDialogTitle => '将输出移至SD卡';

  @override
  String get settingsSdUninstallWarning =>
      'SD卡上的图片保存在应用专属文件夹 (Android/data) 中。卸载应用时,Android会同时删除本机和SD卡上的该文件夹。请先将重要图片导出到其他位置。';

  @override
  String settingsSdExistingInfo(int count, String size) {
    return '可将$count个现有文件($size)移动到SD卡。';
  }

  @override
  String get settingsSdMoveButton => '移动现有文件';

  @override
  String get settingsSdFreshButton => '直接使用(不移动)';

  @override
  String get settingsSdAlready => '输出文件夹已在SD卡上';

  @override
  String settingsSdNotEnoughSpace(String needed, String available) {
    return 'SD卡空间不足:需要 $needed,可用 $available';
  }

  @override
  String get settingsSdMoving => '正在移动到SD卡… 请保持应用打开。';

  @override
  String settingsSdMoveDone(int count) {
    return '已将$count个文件移动到SD卡';
  }

  @override
  String settingsSdMoveFailed(int count) {
    return '$count个文件无法移动 — 点按\"使用SD卡\"重试';
  }

  @override
  String settingsSdMovePaused(int count) {
    return '移动已暂停 — 剩余$count个文件。点按\"使用SD卡\"继续。';
  }

  @override
  String get settingsSdResumeTitle => '继续移动到SD卡';

  @override
  String settingsSdResumeBody(int count) {
    return '上次移动还剩$count个文件。现在继续吗?';
  }

  @override
  String get settingsSdResume => '继续';

  @override
  String get resCustomEntry => '自定义…';

  @override
  String get resCustomDialogTitle => '自定义分辨率';

  @override
  String get resCustomWidth => '宽度';

  @override
  String get resCustomHeight => '高度';

  @override
  String get resCustomName => '名称（可选）';

  @override
  String get resCustomUseOnce => '仅使用一次';

  @override
  String get resCustomSaveAndUse => '保存并使用';

  @override
  String get resCustomMustBeMultiple => '必须是 64 的倍数';

  @override
  String get resCustomOutOfRange => '必须在 64–2048 之间';

  @override
  String get themeSectionCharacters => '角色';

  @override
  String get charEditorTitle => '角色';

  @override
  String get charEditorExpanded => '展开';

  @override
  String get charEditorCompact => '紧凑';

  @override
  String get charEditorAutoPosition => '自动';

  @override
  String get charEditorUsingCompactShelf => '在提示词下方使用紧凑栏';

  @override
  String get charEditorCharacterName => '角色名称';

  @override
  String get charEditorPromptHint => '角色标签、外观…';

  @override
  String get charEditorUcHint => '不想要的标签…';

  @override
  String get charEditorShowUc => '负向';

  @override
  String get charEditorShowPosition => '位置';

  @override
  String get charEditorShowPresets => '预设';

  @override
  String get charEditorAiDecidesPosition => 'AI 决定位置';

  @override
  String get charEditorAddCharacter => '添加角色';

  @override
  String get charEditorCharacterLimitReached => '已达角色上限（6）';

  @override
  String charEditorDeleteConfirm(String name) {
    return '删除「$name」？';
  }

  @override
  String get charEditorDeleteCharacter => '删除角色';

  @override
  String get charEditorInteractions => '互动';

  @override
  String get charEditorAddInteraction => '添加互动';

  @override
  String charEditorInteractionDisplay(
    String source,
    String target,
    String action,
  ) {
    return '$source → $target：$action';
  }

  @override
  String charEditorMutualDisplay(String source, String target, String action) {
    return '$source ↔ $target：$action';
  }

  @override
  String get charEditorSavePreset => '保存预设';

  @override
  String get charEditorLoadPreset => '加载预设';

  @override
  String get charEditorPresetName => '预设名称';

  @override
  String get charEditorNoPresets => '未保存角色预设';

  @override
  String get charEditorSelectSource => '来源角色';

  @override
  String get charEditorSelectTarget => '目标角色';

  @override
  String charEditorCharacterN(int n) {
    return '角色 $n';
  }

  @override
  String get charEditorContinue => '继续';

  @override
  String get charEditorParticipants => '参与者';

  @override
  String get charEditorSourceTarget => '来源 → 目标';

  @override
  String get charEditorMutual => '双向';

  @override
  String get jukeboxTitle => '点唱机';

  @override
  String get jukeboxShuffleAll => '随机全部';

  @override
  String get jukeboxPlayAll => '播放全部';

  @override
  String get jukeboxNoSongPlaying => '未播放歌曲';

  @override
  String get jukeboxNowPlaying => '正在播放';

  @override
  String get jukeboxSoundFont => '音色库';

  @override
  String get jukeboxSettings => '设置';

  @override
  String get jukeboxQueue => '队列';

  @override
  String get jukeboxQueueEmpty => '队列为空';

  @override
  String get jukeboxRepeat => '重复';

  @override
  String get jukeboxShuffle => '随机';

  @override
  String get jukeboxOn => '开启';

  @override
  String get jukeboxOff => '关闭';

  @override
  String get jukeboxAddToQueue => '加入队列';

  @override
  String get jukeboxMusicUnavailable => '音乐播放不可用';

  @override
  String get jukeboxDllMissing => '未找到 FluidSynth DLL';

  @override
  String get jukeboxCategoryAll => '全部';

  @override
  String get jukeboxCategoryClassical => '古典';

  @override
  String get jukeboxCategoryAnime => '动漫';

  @override
  String get jukeboxCategoryGame => '游戏';

  @override
  String get jukeboxCategoryJazz => '爵士';

  @override
  String get jukeboxCategoryAmbient => '氛围';

  @override
  String get jukeboxCategoryHoliday => '节日';

  @override
  String get jukeboxCategoryMeme => '趣味';

  @override
  String get jukeboxCategoryRock => '摇滚';

  @override
  String get jukeboxEnableMusic => '启用音乐';

  @override
  String get jukeboxMusicVolume => '音乐音量';

  @override
  String get jukeboxKaraokeLyrics => '卡拉OK歌词';

  @override
  String get mlModels => '机器学习模型';

  @override
  String get mlBgRemoval => '背景移除';

  @override
  String get mlUpscaling => '超分';

  @override
  String get mlSegmentation => '图像分割';

  @override
  String get mlDownload => '下载';

  @override
  String get mlDownloaded => '已下载';

  @override
  String get mlRetry => '重试';

  @override
  String get mlCancel => '取消';

  @override
  String get mlDelete => '删除';

  @override
  String get mlRemoveBg => '移除背景';

  @override
  String get mlUpscale => '超分';

  @override
  String get mlSegment => '分割';

  @override
  String get mlCanvas => '画布';

  @override
  String get mlSave => '保存';

  @override
  String get mlDiscard => '丢弃';

  @override
  String get mlAddPoint => '添加';

  @override
  String get mlRemovePoint => '移除';

  @override
  String get mlTierFast => '快速';

  @override
  String get mlTierBalanced => '平衡';

  @override
  String get mlTierBalancedShort => '平衡';

  @override
  String get mlTierQuality => '质量';

  @override
  String get mlRemovingBg => '正在移除背景';

  @override
  String get mlUpscalingImages => '正在放大图像';

  @override
  String get mlBgRemovalFailed => '背景移除失败';

  @override
  String get mlUpscaleFailed => '图像放大失败';

  @override
  String get mlRecommended => '推荐';

  @override
  String get mlMayBeSlow => '可能较慢';

  @override
  String get mlNotRecommended => '不推荐';

  @override
  String get mlNotAvailableOnPlatform => '此平台不可用';

  @override
  String get mlLowRamWarning => '内存不足 — 可能崩溃';

  @override
  String get mlBgRemovedAndSaved => '背景已移除并保存';

  @override
  String mlBgRemovedCount(int completed, int total) {
    return '背景已移除：$completed/$total 张图像';
  }

  @override
  String mlUpscaledCount(int completed, int total) {
    return '已放大：$completed/$total 张图像';
  }

  @override
  String mlBgRemovedSavedAs(String name) {
    return '背景已移除：保存为 $name';
  }

  @override
  String get toolsDirectorTools => '导演工具';

  @override
  String get toolsEnhance => '增强';

  @override
  String get directorToolsTitle => '导演工具';

  @override
  String get directorToolsDesc => '服务器端图像处理：移除背景、提取线稿、上色等';

  @override
  String get directorToolsUseCurrent => '使用当前生成结果';

  @override
  String get directorToolsUseCurrentDesc => '以最后生成的图像作为源图';

  @override
  String get directorToolsSelectTool => '选择工具';

  @override
  String get directorToolsProcess => '处理';

  @override
  String get directorToolsProcessing => '处理中...';

  @override
  String get directorToolsDefry => '效果强度';

  @override
  String get directorToolsMood => '氛围';

  @override
  String get directorToolsPrompt => '提示词';

  @override
  String get directorToolsPromptHint => '可选：用于上色/情绪风格的提示词...';

  @override
  String get directorToolsSaved => '结果已保存到图库';

  @override
  String get enhanceTitle => '图像增强';

  @override
  String get enhanceDesc => '通过图生图重新处理并增强图像';

  @override
  String get enhanceUseCurrent => '使用当前生成结果';

  @override
  String get enhanceUseCurrentDesc => '以最后生成的图像作为源图';

  @override
  String get enhanceProcess => '增强';

  @override
  String get enhanceProcessing => '增强中...';

  @override
  String get enhancePrompt => '提示词';

  @override
  String get enhanceNegative => '负面提示词';

  @override
  String get enhanceStrength => '强度';

  @override
  String get enhanceNoise => '噪声';

  @override
  String get enhanceSaved => '增强图像已保存到图库';

  @override
  String get settingsSeedControl => '显示种子控制';

  @override
  String get settingsSeedControlDesc => '在生成界面显示种子值和随机切换';

  @override
  String get settingsShowTooltips => '显示提示';

  @override
  String get settingsShowTooltipsDesc => '悬停或长按按钮时显示帮助提示';

  @override
  String get commonMenu => '菜单';

  @override
  String get presetDuplicate => '复制';

  @override
  String get presetLoad => '加载预设';

  @override
  String get settingsStylesToggle => '切换样式';

  @override
  String get canvasLayerToggleVisibility => '切换可见性';

  @override
  String get mainRefreshAnlas => '刷新资源';

  @override
  String get enhanceSettingsTooltip => '设置';

  @override
  String get directorToolsSettingsTooltip => '设置';

  @override
  String get sidebarCollapse => '收起';

  @override
  String get sidebarExpand => '展开';

  @override
  String get naiUpscale => 'NAI 放大';

  @override
  String get naiUpscaling => '正在通过 API 放大...';

  @override
  String get naiUpscaleFailed => 'API 放大失败';

  @override
  String naiUpscaledCount(int completed, int total) {
    return 'API 已放大：$completed/$total 张图像';
  }

  @override
  String get naiApiKeyRequired => '需要 API 密钥';

  @override
  String get comparisonBefore => '处理前';

  @override
  String get comparisonAfter => '处理后';

  @override
  String get comparisonSideBySide => '并排对比';

  @override
  String get comparisonSliderMode => '滑动对比模式';

  @override
  String get settingsBgRemovalButton => '背景移除按钮';

  @override
  String get settingsBgRemovalButtonDesc => '在图像查看器中显示背景移除按钮';

  @override
  String get settingsUpscaleButton => '放大按钮';

  @override
  String get settingsUpscaleButtonDesc => '在图像查看器中显示放大按钮';

  @override
  String get settingsEnhanceButton => '增强按钮';

  @override
  String get settingsEnhanceButtonDesc => '在图像查看器中显示增强按钮';

  @override
  String get settingsDirectorToolsButton => '导演工具按钮';

  @override
  String get settingsDirectorToolsButtonDesc => '在图像查看器中显示导演工具按钮';

  @override
  String get settingsExportButton => '导出到设备按钮';

  @override
  String get settingsExportButtonDesc => '显示导出按钮以直接保存图片到相册';

  @override
  String get settingsAutoExport => '自动导出到设备';

  @override
  String get settingsAutoExportDesc => '自动将生成的图片保存到设备相册';

  @override
  String get settingsExportAlbum => '导出相册名称';

  @override
  String get settingsExportAlbumDesc => '导出的图片保存到的设备文件夹/相册';

  @override
  String get settingsExportFolder => '导出文件夹';

  @override
  String get settingsExportFolderDesc => '选择自定义导出文件夹（SD卡等）。设置后将覆盖相册名称。';

  @override
  String get settingsExportFolderDefault => '默认（设备相册）';

  @override
  String get settingsUpscaleBackend => '放大后端';

  @override
  String get settingsUpscaleBackendDesc => '选择本地机器学习模型或 NovelAI API 进行放大';

  @override
  String get settingsUpscaleBackendMl => '机器学习（本地）';

  @override
  String get settingsUpscaleBackendNovelai => 'NovelAI（API）';

  @override
  String get quickActionEnhance => '增强';

  @override
  String get quickActionDirectorTools => '导演工具';

  @override
  String get themeColorBgRemoval => '背景移除';

  @override
  String get themeColorUpscale => '图像放大';

  @override
  String get jukeboxSynthUnavailable => '合成器不可用';

  @override
  String get jukeboxImport => '导入';

  @override
  String get jukeboxKeyboard => '键盘';

  @override
  String get jukeboxGame => '游戏';

  @override
  String get jukeboxEnd => '结束';

  @override
  String get jukeboxTempo => '速度';

  @override
  String get jukeboxKeyboardHint => '按键：A‑L  升调：W,E,T,Y,U,O,P  八度：Z/X';

  @override
  String get jukeboxGameResults => '结果';

  @override
  String get jukeboxGameScore => '得分';

  @override
  String get jukeboxGameMaxCombo => '最高连击';

  @override
  String get jukeboxGameAccuracy => '准确率';

  @override
  String get jukeboxGamePerfect => '完美';

  @override
  String get jukeboxGameGreat => '优秀';

  @override
  String get jukeboxGameGood => '良好';

  @override
  String get jukeboxGameMiss => '失误';

  @override
  String get jukeboxHighScores => '最高分';

  @override
  String jukeboxQueueCount(int count) {
    return '队列（$count）';
  }

  @override
  String get jukeboxStyle => '风格';

  @override
  String get jukeboxGameModeTooltip => '游戏模式';

  @override
  String get jukeboxEndGameTooltip => '结束游戏';

  @override
  String get jukeboxImportTooltip => '导入';

  @override
  String get jukeboxShuffleAllTooltip => '随机播放全部';

  @override
  String get jukeboxPlayAllTooltip => '播放全部';

  @override
  String get jukeboxKeyboardTooltip => '键盘';

  @override
  String get jukeboxGameMode => '游戏模式';

  @override
  String get jukeboxNoSongs => '暂无歌曲';

  @override
  String get jukeboxRecommendedBadge => '推荐';

  @override
  String get jukeboxAnalyzing => '分析中...';

  @override
  String get jukeboxNoScoresYet => '暂无成绩';

  @override
  String get jukeboxSelectInstrument => '选择乐器';

  @override
  String get jukeboxWatch => '观看';

  @override
  String get jukeboxPlayGame => '开始游戏';

  @override
  String jukeboxChannelLabel(int channel) {
    return '通道 $channel';
  }

  @override
  String jukeboxCombo(int count) {
    return '$count 连击';
  }

  @override
  String get jukeboxPressOnTheLine => '在线条处按下';

  @override
  String get jukeboxGradePerfect => '完美';

  @override
  String get jukeboxGradeGreat => '优秀';

  @override
  String get jukeboxGradeGood => '良好';

  @override
  String get jukeboxGradeMiss => '失误';

  @override
  String get jukeboxDifficultyEasy => '简单';

  @override
  String get jukeboxDifficultyMedium => '中等';

  @override
  String get jukeboxDifficultyHard => '困难';

  @override
  String get jukeboxDifficultyExtreme => '极限';

  @override
  String get jukeboxInstrumentAcousticGrandPiano => '三角钢琴';

  @override
  String get jukeboxInstrumentElectricPiano => '电钢琴';

  @override
  String get jukeboxInstrumentHarpsichord => '大键琴';

  @override
  String get jukeboxInstrumentVibraphone => '颤音琴';

  @override
  String get jukeboxInstrumentXylophone => '木琴';

  @override
  String get jukeboxInstrumentChurchOrgan => '教堂管风琴';

  @override
  String get jukeboxInstrumentNylonGuitar => '尼龙弦吉他';

  @override
  String get jukeboxInstrumentSteelGuitar => '钢弦吉他';

  @override
  String get jukeboxInstrumentCleanElectricGuitar => '清音电吉他';

  @override
  String get jukeboxInstrumentDistortionGuitar => '失真电吉他';

  @override
  String get jukeboxInstrumentAcousticBass => '原声贝斯';

  @override
  String get jukeboxInstrumentElectricBassFinger => '指弹电贝斯';

  @override
  String get jukeboxInstrumentViolin => '小提琴';

  @override
  String get jukeboxInstrumentCello => '大提琴';

  @override
  String get jukeboxInstrumentOrchestralHarp => '管弦乐竖琴';

  @override
  String get jukeboxInstrumentStringEnsemble => '弦乐合奏';

  @override
  String get jukeboxInstrumentTrumpet => '小号';

  @override
  String get jukeboxInstrumentFrenchHorn => '圆号';

  @override
  String get jukeboxInstrumentAltoSax => '中音萨克斯';

  @override
  String get jukeboxInstrumentFlute => '长笛';

  @override
  String get jukeboxInstrumentSquareLeadSynth => '方波合成主音';

  @override
  String get jukeboxInstrumentLeadVoice => '人声主音';

  @override
  String get jukeboxKaraokeBadge => '卡拉OK';

  @override
  String get jukeboxDeleteCustomSongTooltip => '删除自定义歌曲';

  @override
  String get jukeboxDeleteSong => '删除歌曲';

  @override
  String jukeboxDeleteSongConfirm(String title) {
    return '删除 $title？此操作将从磁盘移除文件。';
  }

  @override
  String get jukeboxStyleHighlight => '高亮';

  @override
  String get jukeboxStyleUpcoming => '即将播放';

  @override
  String get jukeboxStyleNextLine => '下一行';

  @override
  String get jukeboxStyleGlow => '发光';

  @override
  String get jukeboxVisualizer => '频谱可视化';

  @override
  String get jukeboxVizIntensity => '强度';

  @override
  String get jukeboxVizSpeed => '速度';

  @override
  String get jukeboxVizDensity => '密度';

  @override
  String get jukeboxFontSize => '字号';

  @override
  String get jukeboxResetToDefaults => '恢复默认';

  @override
  String jukeboxRepeatMode(String mode) {
    return '循环：$mode';
  }

  @override
  String jukeboxShuffleStatus(String status) {
    return '随机：$status';
  }

  @override
  String get galleryBadgeNaiUpscale => 'NAI 放大';

  @override
  String galleryBadgeDirectorTool(String tool) {
    return '导演：$tool';
  }

  @override
  String get galleryBadgeEnhanced => '已增强';

  @override
  String get galleryBadgeBgRemoved => '已去背景';

  @override
  String get galleryBadgeUpscaled => '已放大';

  @override
  String get galleryBgRemovalFailed => '背景移除失败';

  @override
  String naiUpscaleTooLarge(int width, int height) {
    return '图像过大，无法使用 NAI 放大（${width}x$height 超出单边 2048px 限制）';
  }

  @override
  String get naiRemovingBackground => '正在移除背景...';

  @override
  String get naiBgRemovalFailed => 'NAI 背景移除失败';

  @override
  String get directorToolsFromGallery => '来自图库';

  @override
  String get settingsBgRemovalBackend => '背景移除后端';

  @override
  String get settingsBgRemovalBackendDesc => '选择本地机器学习模型或 NovelAI API 进行背景移除';

  @override
  String get importDialogTitle => '导入元数据';

  @override
  String get importCategoryPrompt => '提示词';

  @override
  String get importCategoryNegative => '负面提示词';

  @override
  String get importCategoryCharacters => '角色';

  @override
  String get importCategorySeed => '种子';

  @override
  String get importCategoryStyles => '样式';

  @override
  String get importCategorySettings => '设置（分辨率、采样器、缩放）';

  @override
  String get importActionImport => '导入';

  @override
  String get importNothingAvailable => '未找到可导入的元数据';

  @override
  String get importStylesAutoDetected => '从提示词自动检测';

  @override
  String get img2imgOutputRes => '输出分辨率';

  @override
  String get img2imgResetRes => '重置为原图';

  @override
  String get img2imgChangeRes => '更改';

  @override
  String get duplicateImageWarning => '生成的图像与上次完全相同——请尝试更换种子或检查氛围迁移/参考图';

  @override
  String get duplicateImageRandomize => '随机化';

  @override
  String get settingsCredits => '制作人员';

  @override
  String get settingsSpecialThanks => '特别感谢';

  @override
  String get settingsAnonTesters => '……以及所有匿名测试人员';

  @override
  String get settingsLayoutMode => '布局模式';

  @override
  String get settingsLayoutModeDesc => '控制宽屏上设置面板的显示方式';

  @override
  String get settingsLayoutAuto => '自动';

  @override
  String get settingsLayoutSidebar => '侧边栏';

  @override
  String get settingsLayoutClassic => '经典';

  @override
  String get settingsPromptPosition => '提示词位置';

  @override
  String get settingsPromptPositionDesc => '侧边栏模式下提示词输入的位置';

  @override
  String get settingsPromptLeft => '左侧';

  @override
  String get settingsPromptRight => '右侧';

  @override
  String get settingsSidebarWidth => '侧栏宽度';

  @override
  String get settingsSidebarWidthDesc => '选择紧凑模式以获得更窄的侧栏面板';

  @override
  String get settingsSidebarCompact => '紧凑';

  @override
  String get settingsSidebarNormal => '标准';

  @override
  String get toolsTextGen => '文本生成';

  @override
  String get textGenTitle => '文本生成';

  @override
  String get textGenInput => '输入';

  @override
  String get textGenInputHint => '要续写的文本……';

  @override
  String get textGenInputNote => 'NovelAI 文本模型会续写你的文本，而不是按聊天回合工作。';

  @override
  String get textGenModel => '模型';

  @override
  String get textGenModelCustom => '自定义……';

  @override
  String get textGenParameters => '参数';

  @override
  String get textGenPreset => '预设';

  @override
  String get textGenTemperature => 'Temperature';

  @override
  String get textGenMaxLength => '最大长度';

  @override
  String get textGenTopP => 'Top P';

  @override
  String get textGenTopK => 'Top K';

  @override
  String get textGenRepetitionPenalty => '重复惩罚';

  @override
  String get textGenPhraseRepPen => '短语重复惩罚';

  @override
  String get textGenGenerateUntilSentence => '生成到句末';

  @override
  String get textGenStopStrings => '停止字符串';

  @override
  String get textGenStopStringsNote => '每行一个。在第一个匹配处截断输出（客户端）。';

  @override
  String get textGenStopStringsHint => '例如对话的结束行';

  @override
  String get textGenGenerate => '生成';

  @override
  String get textGenCancel => '取消';

  @override
  String get textGenContinue => '继续';

  @override
  String get textGenCopy => '复制';

  @override
  String get textGenClear => '清除';

  @override
  String get textGenCopied => '已复制到剪贴板';

  @override
  String get textGenOutput => '输出';

  @override
  String get textGenOutputEmpty => '生成的文本将显示在这里。';

  @override
  String get textGenHistory => '历史';

  @override
  String get textGenEnableThinking => '启用思考';

  @override
  String get textGenEnableThinkingNote => 'GLM 会在回答前生成一段推理。会强制使用非流式响应。';

  @override
  String get textGenReasoning => '推理';
}
