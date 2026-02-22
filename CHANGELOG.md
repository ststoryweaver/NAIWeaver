# Changelog

## v0.5.0 — The Tools Update

### On-Device ML Processing
- On-device ML inference via ONNX Runtime with downloadable model system
- Background removal: 3 models (ISNet Anime, RMBG-2.0 Q4F16, RMBG-2.0 FP16) with binary mask and alpha matte output
- Image upscaling: 3 models (SPAN 2x DC, Compact 2x, RealPLKSR 2x DC) with tiled processing for large images
- Interactive segmentation: SAM 2.1-Tiny with point-based selection (encoder + decoder pair)
- ML model download manager with SHA-256 integrity verification and progress tracking
- Device capability detection (GPU acceleration via DirectML/CUDA/TensorRT/CoreML/NNAPI, RAM-aware recommendations)
- Batch processing for BG removal and upscaling across multiple gallery images
- Sprite sheet generation from processed images
- Before/after comparison slider with zoom and pan for upscale results

### Director Tools
- 6 NovelAI augment-image tools: Remove BG, Line Art, Sketch, Colorize, Emotion, Declutter
- Colorize supports defry control and prompt input
- Emotion supports 24 mood presets (happy, sad, angry, smug, aroused, etc.)
- Accessible from Tools Hub, image viewer quick actions, and gallery detail view

### Enhance Tool
- Quick img2img refinement with strength, noise, and scale controls
- Accessible from Tools Hub, image viewer quick actions, and gallery detail view

### NovelAI API Upscaling
- Server-side 4x upscaling via NovelAI API as alternative to local ML
- Configurable backend toggle (ML Local vs NovelAI API) in Settings

### Quick Action Overlay
- Floating action buttons on generated image: Save, Edit, Remove BG, Upscale, Enhance, Director Tools
- Each button individually toggleable in Settings
- Context-aware: BG Removal and Upscale only appear when a model is downloaded

### Gallery Rework
- Full-screen image detail view with PageView swipe navigation and keyboard support
- Per-page zoom with double-tap zoom animation (2.5x) and pinch-to-zoom
- Auto-hiding controls with tap/hover to reveal
- Bottom action bar: Prompt import, Img2Img, Enhance, Director Tools, Remove BG, Upscale, NAI Upscale, Char Ref, Vibe, Slideshow
- Metadata display with prompt text, resolution, scale, steps, sampler, and seed chips
- Post-processing badge detection from filename prefixes
- Gallery import now preserves original creation dates from EXIF metadata (fixes Android date clustering)
- OriginalDate PNG chunk injection for refresh-resilient date recovery

### Architecture
- Gallery refactored into separate services (album service, import service)
- Generation logic extracted into services (session snapshot, character manager, preset service, metadata import)
- Preferences split into domain-specific modules (gallery, security, ML)
- Core service files consolidated from root into `lib/core/services/`
- `GenerationNotifier` upgraded to `ChangeNotifierProxyProvider5` (adds DirectorTools, Enhance dependencies)
- New providers: `DirectorToolsNotifier`, `EnhanceNotifier`, `MLNotifier`
- Reusable widget library expanded (comparison slider, confirm dialog, progress dialog, vision slider, section title, color swatch row)
- Generic download manager shared across ML and other download features

### Other
- Tooltip visibility toggle in Settings
- New theme color tokens: `bgRemoval`, `upscale`
- Full EN and JA localization for all new features (~70 new keys)
- Tools Hub expanded from 11 to 14 tools

### Bug Fixes
- Fixed upscale producing black rectangles
- Fixed metadata preservation during upscale operations
- Fixed BG removal crashes

### New Files
- `lib/core/ml/` — Full ML inference pipeline (14 files)
- `lib/features/tools/ml/` — ML model manager UI
- `lib/features/tools/director_tools/` — Director Tools feature (4 files)
- `lib/features/tools/enhance/` — Enhance feature (3 files)
- `lib/core/widgets/quick_action_overlay.dart`
- `lib/core/widgets/comparison_slider.dart`
- `lib/features/gallery/ui/image_detail_view.dart`
- `lib/features/gallery/services/gallery_import_service.dart`

---

## v0.4.0 — The Character Update

### Character System
- Expanded inline character editor as alternative to the compact shelf, with per-character tag suggestions, UC editing, position grid, and character presets
- Character preset system: save and load reusable character configurations (prompt, UC, name) via SharedPreferences
- Character editor mode toggle in Settings (expanded vs compact)
- Multi-participant interactions: source and target now support multiple characters per interaction (backward-compatible JSON deserialization)
- Redesigned action interaction sheet with multi-participant selection flow
- Characters section added to theme builder panel ordering

### Canvas Editor
- Inline text editor with live canvas preview and blinking cursor, replacing the old modal dialog
- Google Fonts picker for text tool (any Google Fonts family)
- Letter spacing control for text tool
- Persistent text-tool settings (font size, font family, letter spacing) across strokes
- `onTapUp` gesture handler so tap-based tools (text, fill, eyedropper) work on Android touch devices
- `resizeToAvoidBottomInset: false` on canvas Scaffold to prevent keyboard from resizing canvas
- Google Fonts and letter spacing support in flatten pre-render pipeline
- Expanded toolbar with text font/spacing controls

### Custom Resolutions
- Custom resolution dialog with width/height input, 64-snap validation, and optional save-for-reuse
- Integrated custom resolution entry into blank canvas dialog and Cascade director beat settings
- Saved custom resolutions persisted via SharedPreferences

### Cascade
- Unsaved-changes detection with save/discard confirmation dialog when leaving the editor
- "Cast" button: save cascade to library and return to main screen in one action
- Labeled "Back to Library" and "Exit Cascade" buttons with responsive sizing
- Fixed text overflow on cascade name headers

### Other
- Gallery canvas badge uses palette icon with accent color instead of layers icon
- Tools Hub mobile body wrapped in SafeArea
- Simplified img2img editor header (removed redundant title and dimensions)
- Full EN and JA localization for all new strings

### New Files
- `lib/core/widgets/custom_resolution_dialog.dart` — Custom resolution input dialog
- `lib/features/generation/models/character_preset.dart` — CharacterPreset model
- `lib/features/generation/widgets/inline_character_editor.dart` — Expanded inline character editor widget

---

## v0.3.0 — Canvas Editor, Anlas Tracker & Furry Mode

### Canvas Editor
- Multi-layer canvas editor with paint, erase, shapes (rect, circle, line), fill, text, and eyedropper tools
- Layer management: add, delete, reorder, visibility toggle, opacity control, blend modes
- Flatten-to-PNG for seamless img2img pipeline integration
- Blank canvas option in img2img source picker
- **Canvas state persistence** — flatten & send saves sidecar files (`.canvas.json` + `.canvas.src`) alongside gallery PNGs; re-opening the image in canvas restores all layers, strokes, and undo history
- Gallery layers badge overlay on images with saved canvas state
- Automatic sidecar cleanup when deleting gallery images
- Redesigned two-row canvas toolbar layout for desktop

### Generation
- Anlas balance tracker in app bar with auto-refresh after generation
- Furry mode toggle (fur dataset prefix) for txt2img and Cascade generation
- Custom output folder setting for desktop platforms

### Img2Img
- Prompt auto-import from PNG metadata (tEXt + iTXt chunks) when loading source image
- V4 character restoration from imported generation parameters
- Save original source image (`Src_*.png`) alongside img2img generation result (`Gen_*.png`) with matching timestamps

### Prompt Engineering
- Artist: category prefix for tag autocomplete filtering
- Support dot syntax in wildcard filenames

### Fixes
- PNG metadata extraction for iTXt chunks with zlib compression
- Gallery image detail view layout
- Canvas text dialog theme context fix

---

## v0.2.0 — Wildcard Modes, Update Checker & Platform Expansion

### Generation
- Replaced ddim sampler with k_euler

### Prompt Engineering
- Cascade tag autocompletion in Director View and Playback View
- Style reordering and expandable style chips layout

### Wildcard Manager
- Per-file randomization modes: random, sequential, shuffle, weighted
- Drag-to-reorder with persistent custom ordering
- Help dialog

### Infrastructure
- Release signing for APK (`key.properties` with debug fallback)
- In-app update checker via GitHub releases API
- Linux AppImage build and CI job
- Japanese web build with separate `/ja/` deployment

### Fixes
- Blank white screen on web (kIsWeb guards)
- Overlapping brush stroke opacity in inpainting mask
- Android gallery import stripping PNG metadata
- Linux AppImage missing libsecret-1-dev dependency

---

## v0.1.0 — Initial Open-Source Release

First public release of NAIWeaver, a cross-platform frontend for NovelAI's image generation API. Previously developed as an internal tool (nai_terminal_v2), this release marks the transition to an open-source project with a clean repository history.

### Generation
- Full NovelAI Diffusion V4.5 text-to-image, img2img, and inpainting support
- Multi-character generation with pixel-coordinate positioning and interaction tags
- Director Reference (Precise Reference) with character/style/char&style types, strength, and fidelity controls
- Vibe Transfer (Reference Image) with strength and information extraction controls
- Cascade system for sequential multi-beat scene generation with prompt stitching
- Img2Img editor with brush-based mask painting and iterative workflow
- PNG metadata round-trip — generation settings embedded in images and re-importable via drag-and-drop

### Prompt Engineering
- Wildcard system (`__pattern__` substitution) with recursive expansion and favorites
- Danbooru tag library with auto-suggest, visual examples, and preview generation
- Preset system with full serialization (characters, interactions, director references, vibe transfers)
- Prompt style system with prefix/suffix/negative templates and style defaults

### Gallery
- Image vault with search, favorites, multi-select, bulk export, and bulk delete
- Virtual albums (folder-like organization without moving files)
- Sort by date, name, or file size (ascending/descending)
- Side-by-side image comparison with synced zoom
- Image info overlay on hover

### Tools Hub (11 Tools)
- Wildcard Manager, Tag Library, Preset Manager, Style Editor, Reference Manager
- Cascade Editor, Img2Img Editor, Slideshow, Packs, Theme Builder, Settings

### Slideshow
- Configurable slideshow player with transition timing and Ken Burns effect
- Source selection from full gallery or specific albums
- Saved slideshow configurations with default selection

### NAIWeaver Packs
- Export/import presets, styles, wildcards, and director references as `.vpack` ZIP archives
- Director reference images bundled and restored automatically

### Localization
- English and Japanese language support
- Extensible via `.arb` files

### Theme System
- Token-based theming with 8 built-in themes and custom user theme creation
- 15 configurable colors, font selection, text scale, bright mode toggle
- Live preview and color picker with curated palette

### Security & Privacy
- PIN lock with SHA-256 hashing and lock-on-resume
- Biometric unlock support
- Demo mode with gallery filtering, tag suppression, and configurable prompt prefixes

### Platform Support
- Windows desktop (primary), Android, and Web
- Responsive layouts with mobile-optimized navigation, bottom sheets, and touch-friendly controls

### Infrastructure
- Branding: nai_terminal_v2 renamed to NAIWeaver
- Clean repository initialization for open-source release
- CI/CD workflow for Windows, Android, and Web builds via GitHub Actions
- MIT license
