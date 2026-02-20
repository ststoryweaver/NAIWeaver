# NAIWeaver: Development Strategy

## Core Principles
- **Simplicity Over Speed**: Build one feature at a time and ensure it works perfectly before moving on.
- **Robust Documentation**: Every service and key logic block must be documented.
- **Token-Based Theming**: All colors/fonts flow through `VisionTokens` (`context.t`). 8 built-in themes + custom user themes with configurable colors, fonts, scale, and bright mode.
- **Path Reliability**: Use `PathService` for platform-aware directory resolution on all targets.
- **Feature Architecture**: Each feature lives in its own folder under `features/` with `models/`, `providers/`, `services/`, and `widgets/` sub-folders.
- **Provider Pattern**: All state flows through `ChangeNotifier` subclasses wired via `MultiProvider`.

## Completed

### Phase 1: Minimal Generator
- NovelAI V4.5 API client with full parameter support
- Single-page generation UI with prompt input and interactive image viewer
- Auto-save to disk with PNG metadata injection

### Phase 2: Gallery (Vault)
- Image vault that reads from the output folder
- Search, browse, and manage generated images
- Auto-save integration with gallery notifier
- Export button with platform-branched save (Downloads on mobile, save-as on desktop)

### Phase 3: Advanced Features
- Wildcard system with recursive expansion (5 levels) and favorites
- PNG metadata extraction and drag-and-drop import
- Danbooru tag library with auto-suggest, visual examples, and preview settings
- Preset system with full serialization (characters, interactions, references)
- Prompt style system with prefix/suffix/negative templates and style defaults
- Multi-character generation with coordinate positioning and interactions
- Cascade system with character appearance casting, cascade library, and playback
- Img2Img editor with client-side inpainting, brush-based masking, and iterative workflow
- Director Reference (Precise Reference) with 3 types and per-reference controls
- Vibe Transfer (Reference Image) with strength and information extraction controls

### Phase 4: Polish & Platform
- Tools Hub with 11 integrated tools (Wildcards, Tag Library, Presets, Styles, References, Cascade, Img2Img, Slideshow, Packs, Theme Builder, Settings)
- Token-based theme system with 8 built-in themes and custom user themes
- Gallery sort options (date, name, size — ascending/descending)
- Virtual albums for folder-like organization
- Side-by-side image comparison with synced zoom
- Image info overlay on hover
- Slideshow player with Ken Burns effect and saved configurations
- NAIWeaver Packs (`.vpack` export/import of presets, styles, wildcards, director refs)
- Localization (English + Japanese) with extensible `.arb` system
- Android/mobile support with responsive layouts, drawers, bottom sheets, and touch-friendly controls
- PIN lock with lock-on-resume and biometric unlock support
- Demo mode with gallery filtering, tag suppression, configurable prompt prefixes, and demo image picker
- Toggleable shelf visibility for reference shelves

### Phase 5: Canvas, Tracking & Platform Expansion (v0.2.0–v0.3.0)
- Multi-layer canvas editor with paint, erase, shapes, fill, text, eyedropper, layer management, and flatten-to-PNG for img2img pipeline
- Blank canvas option in img2img source picker
- Anlas balance tracker in app bar with auto-refresh after generation
- Furry mode toggle (fur dataset prefix) for txt2img and Cascade
- Custom output folder setting for desktop platforms
- Img2img prompt auto-import from PNG metadata (tEXt + iTXt chunks)
- Wildcard manager enhancements: per-file randomization modes (random, sequential, shuffle, weighted), drag-to-reorder
- Style reordering and expandable style chips layout
- Artist: category prefix for tag autocomplete filtering
- Cascade tag autocompletion in Director View and Playback View
- Replaced ddim sampler with k_euler
- Release signing for APK with debug fallback
- In-app update checker via GitHub releases API
- Linux AppImage build and CI job
- Japanese web build with separate `/ja/` deployment
- Save original source image alongside img2img generation result with matching timestamps

### Phase 6: Character System, Custom Resolutions & Canvas Text (post-v0.3.0)
- Expanded inline character editor with tag suggestions, UC editing, position grid, and character presets (save/load)
- Character editor mode toggle (expanded vs compact) in Settings
- Multi-participant interactions: source and target now support multiple characters per interaction
- Custom resolution dialog with 64-snap validation and save-for-reuse, integrated into blank canvas and Cascade
- Canvas inline text editor with live preview, Google Fonts picker, and letter spacing control
- Canvas `onTapUp` gesture handler for Android touch (tap-based tools: text, fill, eyedropper)
- Canvas keyboard-safe Scaffold (resizeToAvoidBottomInset: false)
- Cascade unsaved-changes guard with save/discard confirmation
- Cascade "Cast" button for quick save-and-return workflow
- Responsive cascade navigation buttons and overflow fixes
- Gallery canvas badge redesign (palette icon with accent color)
- Characters section in theme builder panel ordering
- Full EN and JA localization for all new features

## Architecture
- **Language/Framework**: Dart 3.10.7+ / Flutter (stable channel)
- **Primary Target**: Windows desktop (also supports Android, iOS, Linux, macOS, Web)
- **API**: NovelAI image generation (`https://image.novelai.net/ai/generate-image`), model `nai-diffusion-4-5-full`
- **State Management**: Provider + ChangeNotifier with `MultiProvider` in `main.dart`
- **Theme**: Token-based system via `VisionTokens` with 8 built-in themes + custom themes

## Planned Features

### Director Tools Integration
NovelAI's Director Tools API provides image transformation capabilities beyond generation. Planned tools:
- **Remove Background** — Isolate subjects from their backgrounds
- **Line Art** — Extract clean line art from images
- **Sketch** — Convert images to sketch-style renderings
- **Colorize** — Add color to grayscale or line art images
- **Emotion** — Modify character facial expressions
- **Declutter** — Clean up and simplify image compositions

These will be integrated as additional tools in the Tools Hub or as post-processing options accessible from the image viewer.

### Enhance (Upscale)
Image enhancement/upscale via NovelAI's API. Planned capabilities:
- **Upscale**: Increase image resolution while preserving detail
- Integration as a post-generation action in the image viewer and gallery detail view
- Configurable enhancement parameters (strength, scale factor)

### Cascade Editor Revamp
Major overhaul of the Cascade Editor to improve usability and creative control:
- Visual timeline with drag-and-drop beat reordering
- Per-beat image preview thumbnails
- Inline character appearance editing within beats
- Beat duplication and templating
- Improved multi-character slot management with visual indicators
- Side-by-side beat comparison view

### NAI v4 Vibe Bundle Support
Support for NovelAI's native vibe file formats:
- **`.naiv4vibe`** — Single pre-encoded vibe file
- **`.naiv4vibeBundle`** — Bundle of multiple pre-encoded vibes

This enables sharing vibes without re-encoding costs and interoperability with other NovelAI tools. Import/export will be available through the Vibe Transfer manager and the Packs system.

## Community Wishlist

Have an idea? Feature requests are welcome — please open a [GitHub Issue](../../issues) with the `enhancement` label. Some ideas from the community backlog:

- **Prompt history with undo/redo**: Navigate recent prompts with back/forward controls
- **Batch generation**: Queue N generations with seed increment or wildcard variance
- **Keyboard shortcuts**: Hotkeys for common actions (generate, randomize seed, toggle settings)
- **Prompt weight visualization**: Highlight tags with `{}` or `[]` weighting inline in the prompt field
- ~~**Resolution presets**: Named resolution presets per use-case~~ *(Done — custom resolution dialog with save-for-reuse in Phase 6)*
- **Cloud sync**: Sync presets, wildcards, and styles across devices
