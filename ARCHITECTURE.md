# NAIWeaver Architecture

## Directory Structure

```text
lib/
├── main.dart                              # Entry point, MultiProvider setup, root layout
├── core/
│   ├── ml/
│   │   ├── ml_inference_service.dart      # ONNX Runtime inference engine
│   │   ├── ml_model_registry.dart         # Model catalog (8 models across 3 categories)
│   │   ├── ml_model_entry.dart            # Model entry data class
│   │   ├── ml_notifier.dart               # ML state management (ChangeNotifier)
│   │   ├── ml_device_capabilities.dart    # GPU/RAM detection and model recommendations
│   │   ├── ml_upscale_service.dart        # Tiled upscaling pipeline
│   │   ├── ml_segmentation_service.dart   # SAM 2.1-Tiny interactive segmentation
│   │   ├── ml_batch_service.dart          # Batch BG removal and upscaling
│   │   ├── ml_sprite_sheet_service.dart   # Sprite sheet generation from processed images
│   │   ├── ml_download_manager.dart       # Model download with SHA-256 verification
│   │   ├── ml_download_service.dart       # Download progress tracking
│   │   ├── ml_storage_service.dart        # Model file storage management
│   │   └── widgets/
│   │       ├── bg_removal_overlay.dart    # BG removal result overlay
│   │       ├── ml_processing_overlay.dart # ML processing progress overlay
│   │       └── upscale_comparison_view.dart # Before/after comparison for upscale results
│   ├── theme/
│   │   ├── app_theme_config.dart          # Theme config model (17 colors, font, scale, bright mode, JSON serialization)
│   │   ├── vision_tokens.dart             # Semantic design tokens derived from config
│   │   ├── theme_notifier.dart            # Theme state management (ChangeNotifier) with persistence
│   │   ├── theme_extensions.dart          # BuildContext extension: `context.t` for token access
│   │   └── built_in_themes.dart           # 8 built-in theme presets
│   ├── l10n/
│   │   ├── locale_notifier.dart           # Locale state management (ChangeNotifier) with persistence
│   │   └── l10n_extensions.dart           # BuildContext extension: `context.l` for localized strings
│   ├── services/
│   │   ├── novel_ai_service.dart          # NovelAI API client (Dio, ZIP decompression)
│   │   ├── preferences_service.dart       # SharedPreferences wrapper (core preferences)
│   │   ├── preferences/
│   │   │   ├── gallery_preferences.dart   # Gallery-specific preferences
│   │   │   ├── security_preferences.dart  # Security/PIN preferences
│   │   │   └── ml_preferences.dart        # ML model and processing preferences
│   │   ├── path_service.dart              # Platform-aware directory resolution
│   │   ├── pack_service.dart              # ZIP-based .vpack export/import for presets, styles, wildcards, director refs
│   │   ├── wildcard_service.dart          # Wildcard file I/O and indexing
│   │   ├── wildcard_processor.dart        # __wildcard__ pattern replacement (recursive, 5 levels)
│   │   ├── presets.dart                   # GenerationPreset model + JSON persistence
│   │   ├── styles.dart                    # PromptStyle model + JSON persistence
│   │   ├── tag_service.dart               # Danbooru tag auto-complete from Tags/ JSON
│   │   ├── reference_library_service.dart # Reference library operations
│   │   └── download_manager.dart          # Generic download manager shared across features
│   ├── utils/
│   │   ├── image_utils.dart               # PNG metadata inject/extract (runs in Isolate)
│   │   ├── nai_coordinate_utils.dart      # Character positioning math
│   │   ├── responsive.dart                # Shared utilities: isMobile(), isDesktopPlatform(), responsiveFont(), touchTarget()
│   │   ├── tag_suggestion_helper.dart     # Tag auto-complete logic shared across features
│   │   ├── app_snackbar.dart              # Reusable snackbar helper
│   │   └── timestamp_utils.dart           # EXIF date extraction and timestamp utilities
│   └── widgets/
│       ├── tag_suggestion_overlay.dart    # Reusable tag suggestion dropdown
│       ├── color_picker_dialog.dart       # Hex color picker with palette grid
│       ├── custom_resolution_dialog.dart  # Custom resolution input with 64-snap validation and save-for-reuse
│       ├── quick_action_overlay.dart      # Floating action buttons on image viewer
│       ├── comparison_slider.dart         # Reusable before/after comparison with zoom/pan
│       ├── confirm_dialog.dart            # Reusable confirmation dialog
│       ├── progress_dialog.dart           # Reusable progress dialog with cancel support
│       ├── vision_slider.dart             # Themed slider widget
│       ├── section_title.dart             # Reusable section title widget
│       ├── color_swatch_row.dart          # Color swatch row for theme editing
│       └── help_dialog.dart               # Help/info dialog
├── l10n/
│   ├── app_en.arb                         # English translation strings
│   ├── app_ja.arb                         # Japanese translation strings
│   ├── app_localizations.dart             # Generated localization base class
│   ├── app_localizations_en.dart          # Generated English localizations
│   └── app_localizations_ja.dart          # Generated Japanese localizations
└── features/
    ├── generation/                        # Main generation feature
    │   ├── models/
    │   │   ├── nai_character.dart          # NaiCharacter, NaiInteraction (multi-participant), NaiCoordinate models
    │   │   └── character_preset.dart       # CharacterPreset model for save/load character configurations
    │   ├── providers/
    │   │   └── generation_notifier.dart    # Central business logic (~1400 lines)
    │   ├── services/
    │   │   ├── session_snapshot_service.dart   # Generation session state snapshots
    │   │   ├── character_manager.dart         # Character lifecycle management
    │   │   ├── preset_service.dart            # Preset apply/save logic extracted from notifier
    │   │   └── metadata_import_service.dart   # PNG metadata import and field restoration
    │   └── widgets/
    │       ├── settings_panel.dart         # Collapsible advanced settings panel with custom resolutions
    │       ├── image_viewer.dart           # Interactive image display with zoom
    │       ├── character_shelf.dart        # Horizontal character chip shelf (compact mode)
    │       ├── inline_character_editor.dart # Expanded inline character editor with presets, tag suggestions, position grid
    │       ├── character_editor_sheet.dart # Character editing bottom sheet
    │       ├── action_interaction_sheet.dart # Multi-participant interaction editor
    │       └── vibe_transfer_shelf.dart    # Horizontal vibe transfer chip shelf
    ├── gallery/                           # Image vault / gallery
    │   ├── models/
    │   │   └── gallery_album.dart          # GalleryAlbum model (virtual folders in SharedPreferences)
    │   ├── providers/
    │   │   └── gallery_notifier.dart       # Gallery state, file management, sort modes
    │   ├── services/
    │   │   ├── album_service.dart          # Album CRUD operations
    │   │   └── gallery_import_service.dart # File import with EXIF date preservation and OriginalDate chunk injection
    │   └── ui/
    │       ├── gallery_screen.dart         # Full gallery view with search
    │       ├── comparison_view.dart        # Side-by-side image comparison with synced zoom
    │       └── image_detail_view.dart      # Full-screen detail view with swipe, zoom, metadata, and action bar
    ├── director_ref/                      # Director Reference (Precise Reference)
    │   ├── models/
    │   │   └── director_reference.dart     # DirectorReference model, DirectorRefPayload DTO
    │   ├── providers/
    │   │   └── director_ref_notifier.dart  # Reference state, image processing, payload assembly
    │   ├── services/
    │   │   └── reference_image_processor.dart  # Resize/pad to target dimensions (Isolate)
    │   └── widgets/
    │       ├── director_ref_shelf.dart     # Main-screen horizontal reference shelf
    │       ├── director_ref_chip.dart      # Type-colored reference thumbnail chip
    │       ├── director_ref_editor_sheet.dart  # Modal editor (type, strength, fidelity)
    │       └── director_ref_manager.dart   # Tools Hub full management interface
    ├── vibe_transfer/                     # Vibe Transfer (Reference Image)
    │   ├── models/
    │   │   └── vibe_transfer.dart          # VibeTransfer model, VibeTransferPayload DTO
    │   ├── providers/
    │   │   └── vibe_transfer_notifier.dart # Vibe state, strength/info controls, payload assembly
    │   └── widgets/
    │       ├── vibe_transfer_chip.dart     # Green-accented vibe thumbnail chip
    │       ├── vibe_transfer_editor_sheet.dart  # Modal editor (strength, info extracted)
    │       └── vibe_transfer_manager.dart  # Tools Hub management interface
    └── tools/                             # Tools Hub
        ├── tools_hub_screen.dart           # Sidebar navigation + content routing (14 tools)
        ├── providers/
        │   ├── preset_notifier.dart        # Preset editing state
        │   ├── style_notifier.dart         # Style editing state
        │   ├── wildcard_notifier.dart      # Wildcard file management state
        │   └── tag_library_notifier.dart   # Tag library browsing state
        ├── widgets/
        │   ├── preset_manager.dart         # Full preset editor with all sections
        │   ├── style_editor.dart           # Prompt style creation/editing
        │   ├── wildcard_manager.dart       # Wildcard file browser/editor
        │   ├── tag_library_manager.dart    # Tag browser with preview generation
        │   ├── theme_builder.dart          # Theme customization UI (colors, font, scale, preview)
        │   ├── pack_manager.dart           # Pack export/import management UI
        │   └── app_settings.dart           # API key, auto-save, shelf visibility, quick actions, upscale backend, tooltips, locale
        ├── cascade/                       # Cascade sequential generation
        │   ├── models/
        │   │   ├── prompt_cascade.dart     # PromptCascade, CascadeBeat models
        │   │   └── cascade_character.dart  # Character slot definitions
        │   ├── providers/
        │   │   └── cascade_notifier.dart   # Cascade state machine with unsaved-changes detection
        │   ├── services/
        │   │   └── cascade_stitching_service.dart  # Beat prompt assembly
        │   └── widgets/
        │       ├── cascade_editor.dart     # Timeline editor UI with unsaved-changes guard and Cast button
        │       ├── cascade_playback_view.dart  # Main-screen playback overlay with responsive controls
        │       └── ...                     # Director (custom resolutions), beat editor, library, etc.
        ├── canvas/                        # Multi-layer canvas editor
        │   ├── models/
        │   │   ├── canvas_action.dart      # Undo/redo action models
        │   │   ├── canvas_layer.dart       # Layer model (visibility, opacity)
        │   │   ├── canvas_session.dart     # Canvas session state
        │   │   └── paint_stroke.dart       # Paint stroke data model (fontFamily, letterSpacing)
        │   ├── providers/
        │   │   └── canvas_notifier.dart    # Canvas state management (layers, tools, colors, pending text state)
        │   ├── services/
        │   │   ├── canvas_flatten_service.dart      # Flatten visible layers to PNG
        │   │   ├── canvas_gallery_service.dart      # Canvas-gallery integration
        │   │   └── canvas_persistence_service.dart  # Canvas session persistence
        │   └── widgets/
        │       ├── canvas_color_picker.dart  # Canvas-specific color picker
        │       ├── canvas_editor.dart       # Main canvas editor UI (resizeToAvoidBottomInset: false)
        │       ├── canvas_paint_surface.dart # Drawing surface with gesture handling, inline text editor, tap support
        │       ├── canvas_toolbar.dart      # Tool selection toolbar
        │       └── layer_panel.dart         # Layer management panel
        ├── director_tools/                # Director Tools (server-side augmentation)
        │   ├── models/                    # Director tool types and request models
        │   ├── providers/                 # DirectorToolsNotifier state management
        │   └── widgets/                   # Tool picker, emotion selector, colorize controls
        ├── enhance/                       # Enhance (quick img2img refinement)
        │   ├── models/                    # Enhance config model
        │   ├── providers/                 # EnhanceNotifier state management
        │   └── widgets/                   # Enhance controls UI
        ├── img2img/                       # Img2Img editor
        │   ├── providers/
        │   │   └── img2img_notifier.dart   # Source/mask state management
        │   ├── services/
        │   │   └── img2img_request_builder.dart  # Request payload construction
        │   └── widgets/
        │       └── img2img_editor.dart     # Canvas with brush painting
        ├── ml/                            # ML model manager UI
        │   └── widgets/
        │       ├── ml_models_manager.dart  # Model download/management interface
        │       ├── ml_model_picker.dart    # Model selection picker
        │       └── segmentation_overlay.dart # SAM point-based segmentation UI
        └── slideshow/                     # Slideshow player
            ├── models/
            │   └── slideshow_config.dart   # SlideshowConfig model (timing, Ken Burns, source)
            ├── providers/
            │   └── slideshow_notifier.dart # Slideshow config state management
            ├── services/
            │   └── slideshow_animation_service.dart  # Transition and Ken Burns animation
            └── widgets/
                ├── slideshow_launcher.dart # Slideshow configuration and launch UI
                └── slideshow_player.dart   # Full-screen slideshow playback
```

## Provider Dependency Tree

All state flows through `ChangeNotifier` subclasses provided via `MultiProvider` in `main.dart`:

```text
ThemeNotifier                (standalone — provides VisionTokens, ThemeData)
LocaleNotifier               (standalone — provides Locale, persists to SharedPreferences)
GalleryNotifier              (standalone)
DirectorRefNotifier          (standalone)
VibeTransferNotifier         (standalone)
DirectorToolsNotifier        (standalone)
EnhanceNotifier              (standalone)
MLNotifier                   (standalone)
SlideshowNotifier            (standalone — manages slideshow configs)
CascadeNotifier              (standalone)
CanvasNotifier               (standalone — manages canvas layers, tools, drawing state)
Img2ImgNotifier              (standalone)
GenerationNotifier           (depends on: GalleryNotifier, DirectorRefNotifier, VibeTransferNotifier, DirectorToolsNotifier, EnhanceNotifier)
  └── via ChangeNotifierProxyProvider5
WildcardNotifier             (depends on: GenerationNotifier — for tagService, wildcardService)
TagLibraryNotifier           (depends on: GenerationNotifier — for tagService)
```

**Standalone notifiers** use `ChangeNotifierProvider(create: ...)`.
**Dependent notifiers** use `ChangeNotifierProxyProvider` / `ChangeNotifierProxyProvider5` to inject dependencies.

## Key Design Patterns

### Feature Architecture
Each feature follows the pattern: `features/{name}/models/`, `providers/`, `services/`, `widgets/`. Models are pure data classes with `copyWith()` and JSON serialization. Providers are `ChangeNotifier` subclasses that own the mutable state. Widgets consume state via `context.watch<T>()` / `context.read<T>()`.

### Immutable State Updates
All notifiers create new list/object instances on mutation (never mutate in place), then call `notifyListeners()`.

### PNG Metadata Round-Trip
Generation settings are embedded in PNG text chunks as JSON. Drag-and-drop import reads these chunks to reconstruct settings, enabling generate-save-reimport workflows.

### Reference Image Processing
Both Director Reference and Vibe Transfer share `ReferenceImageProcessor` which resizes/pads images to NAI-compatible target dimensions (1024x1536, 1536x1024, or 1472x1472) via `compute()` isolate.

### Theme System
All UI styling flows through `VisionTokens`, a semantic token layer derived from `AppThemeConfig`. Widgets access tokens via `context.t` (a `BuildContext` extension). `ThemeNotifier` manages theme state with persistence to SharedPreferences, supports 8 built-in themes and unlimited user-created themes, and provides live preview during editing. The `ThemeBuilder` widget in Tools Hub exposes all theme properties (17 colors including `bgRemoval` and `upscale`, font family, font scale, bright mode) with a color picker dialog and real-time preview card.

### Localization System
All UI strings flow through Flutter's `AppLocalizations` generated from `.arb` files. Widgets access strings via `context.l` (a `BuildContext` extension). `LocaleNotifier` manages the active locale and persists the selection to SharedPreferences. New languages are added by creating an `.arb` file and regenerating.

### Tools Hub Pattern
The Tools Hub sidebar defines tool items in a `_getTools()` method returning a list of `ToolItem` objects. The `_buildToolContent()` method uses a switch statement to route to the appropriate widget. New tools are added by inserting a `ToolItem` and a corresponding case. Currently 14 tools.

### ML Inference Pipeline
Model registry defines available models → download manager fetches with SHA-256 verification → device capability detection selects optimal execution provider (DirectML, CUDA, TensorRT, CoreML, NNAPI, or CPU) → ONNX Runtime loads model → tiled processing for large images → result saved to gallery. The pipeline supports background removal (binary mask + alpha matte), upscaling (2x with tile overlap), and interactive segmentation (SAM encoder + decoder).

### Quick Action Overlay
Context-aware floating action buttons rendered on the image viewer. Each button checks preconditions (e.g., BG Removal only appears when a model is downloaded) and is individually toggleable via Settings. Actions dispatch to the appropriate notifier (ML, Director Tools, Enhance, etc.).

## Data Lifecycle

### Text-to-Image Generation
1. User enters prompt, adjusts settings in UI widgets
2. `GenerationNotifier` updates `GenerationState`
3. On generate: prompt → `WildcardProcessor` for `__pattern__` expansion
4. Active styles inject prefix/suffix/negative content
5. `DirectorRefNotifier.buildPayload()` assembles 5 parallel arrays
6. `VibeTransferNotifier.buildPayload()` assembles 3 parallel arrays
7. `NovelAIService` builds V4.5 JSON payload, sends via Dio, decompresses ZIP response
8. `ImageUtils.injectMetadata()` encodes settings into PNG Comment/Description chunks (in Isolate)
9. Image saved to `output/` folder, `GalleryNotifier` picks it up

### Img2Img / Inpainting
1. Source image loaded into `Img2ImgNotifier` (from file, last generation, or canvas editor)
2. If using canvas: `CanvasNotifier` manages multi-layer drawing state; `CanvasFlattenService` merges visible layers to PNG
3. PNG metadata auto-imported to populate prompt fields (tEXt + iTXt chunk extraction)
4. User paints mask on canvas with brush tools
5. `Img2ImgRequestBuilder` constructs request with base64 source, mask, strength, noise
6. `GenerationNotifier.generateImg2Img()` sends with `action: 'img2img'`
7. Client-side mask compositing blends original and generated images per-pixel
8. Original source image saved as `Src_*.png` alongside generated `Gen_*.png` with matching timestamps

### ML Processing
1. User selects a model from the ML Models manager or triggers processing from quick actions / gallery detail view
2. `MLNotifier` checks device capabilities (GPU, RAM) and selects optimal execution provider
3. Model downloaded via `MLDownloadManager` with SHA-256 integrity verification (if not already cached)
4. `MLInferenceService` loads ONNX model and runs inference (tiled for upscaling, encoder+decoder for segmentation)
5. Result saved to gallery with appropriate filename prefix (e.g., `BG_`, `Up_`)

### Director Tools
1. Source image selected from image viewer, quick action overlay, or gallery detail view
2. `DirectorToolsNotifier` sends base64 image + tool type to NovelAI `augment-image` API
3. For Colorize: includes `defry` and optional `prompt` parameters; for Emotion: includes selected mood
4. API returns processed image; result saved to gallery

### Enhance
1. Source image selected from image viewer, quick action overlay, or gallery detail view
2. `EnhanceNotifier` sends image via `img2img` API with enhance-specific strength, noise, and scale settings
3. Result saved to gallery

### Gallery Import
1. User picks files via file picker or imports from external source
2. `GalleryImportService` extracts EXIF creation date from image metadata
3. Image converted to PNG if needed
4. `OriginalDate` PNG text chunk injected for refresh-resilient date recovery
5. File saved to output directory; `GalleryNotifier` picks it up with correct sort ordering

### Cascade Generation
1. User defines beats in Cascade Editor with characters, environment tags, styles
2. `CascadeStitchingService` assembles per-beat prompts from character appearances + environment
3. `GenerationNotifier.generateCascadeBeat()` generates each beat sequentially
4. Results displayed in `CascadePlaybackView` overlay

### Preset Save/Load
1. `savePreset()` captures: prompt, negative, settings, characters, interactions, director references, vibe transfers
2. Serialized to `presets.json` via `PresetStorage`
3. `applyPreset()` restores all fields including reference notifier state

### Pack Export/Import
1. `PackService.exportPack()` bundles selected presets, styles, wildcards, and director ref images into a ZIP archive (`.vpack`)
2. Director reference images extracted to `references/` directory in the ZIP, referenced via `@ref:filename` pointers in preset JSON
3. `PackService.importPack()` opens a `.vpack`, extracts contents, and restores items with reference image re-embedding
4. `GenerationNotifier.reloadPresetsAndStyles()` refreshes state after import

## Data Files

| File/Directory | Purpose |
|---|---|
| `Tags/high-frequency-tags-list.json` | Danbooru tag library for auto-complete |
| `wildcards/*.txt` | User-defined wildcard substitution files |
| `presets.json` | Saved generation presets |
| `prompt_styles.json` | Saved prompt style templates |
| `output/` | Generated image output directory |
| `ml_models/` | Downloaded ML model files (ONNX) |
| `lib/l10n/app_*.arb` | Localization string files (en, ja) |
