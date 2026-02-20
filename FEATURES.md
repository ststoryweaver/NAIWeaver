# NAIWeaver Feature Catalog

## Core Generation
- **Text-to-Image**: Full NovelAI Diffusion V4.5 generation with prompt/negative prompt, configurable dimensions, steps, scale, sampler selection
- **Img2Img / Inpainting**: Source image transformation with strength/noise controls, client-side mask compositing for selective inpainting, canvas editor integration
- **Img2Img Iterative Workflow**: "Use Result as Source" button to feed the current generation back as the img2img source for iterative refinement
- **Img2Img Prompt Auto-Import**: Automatically extract and apply prompt from PNG metadata (tEXt + iTXt chunks) when loading a source image
- **Custom Output Folder**: Configurable output directory for desktop platforms (Windows, Linux)
- **Multi-Character Generation**: Up to 6 characters with independent prompts, negative prompts, and pixel-coordinate positioning via `char_captions` and `use_coords`
- **Character Interactions**: Typed interaction tags (`source#action`, `target#action`, `mutual#action`) automatically injected into character captions, with multi-participant support (multiple source/target characters per interaction)
- **Expanded Character Editor**: Inline character editor in the settings panel with per-character tag suggestions, UC editing, position grid, and character presets — alternative to the compact shelf
- **Character Presets**: Save and load reusable character configurations (name, prompt, UC) for quick character switching
- **Character Editor Mode**: Toggle between expanded (settings panel) and compact (shelf below prompt) modes via Settings
- **Custom Resolution Dialog**: Enter arbitrary resolutions with automatic 64-snap validation; optionally save custom resolutions for reuse across sessions
- **Seed Control**: Manual seed input with randomization toggle for reproducible or varied generations

## Reference Systems
- **Director Reference (Precise Reference)**: Upload reference images to guide character appearance or artistic style. Supports 3 reference types (Character, Style, Character & Style) with per-reference strength and fidelity sliders. 5 parallel API arrays. Shelf visibility toggleable via Settings.
- **Vibe Transfer (Reference Image)**: Apply the aesthetic "vibe" of reference images to influence generation style. Each vibe has independent strength (0.0–1.0) and information extraction (0.0–1.0) controls. 3 parallel API arrays. Multiple vibes can be active simultaneously, allowing layered style influence without precise character matching.

## Prompt Engineering
- **Danbooru Tag Library**: 300+ post-count tag database with intelligent auto-suggest and auto-completion as you type
- **Tag Library Visual Examples**: Generate and save example images per tag with thumbnail previews for quick visual reference
- **Tag Library Preview Settings**: Customizable generation parameters for tag test generations
- **Wildcard System**: `__pattern__` syntax replaced with random lines from corresponding wildcard files, supports recursive expansion up to 5 levels and dot syntax in filenames
- **Wildcard Favorites**: Star system for marking frequently-used wildcards for quick access
- **Wildcard Randomization Modes**: Per-file randomization modes — random, sequential, shuffle, and weighted — for fine-grained control over wildcard expansion
- **Wildcard Drag-to-Reorder**: Persistent custom ordering for the wildcard file list via drag-to-reorder
- **Prompt Styles**: Reusable prefix/suffix/negative templates that wrap around your prompt. Multiple styles can be active simultaneously.
- **Style Defaults**: Mark styles as auto-selected on application launch
- **Style Reordering**: Drag-to-reorder active styles with expandable style chips layout
- **Artist Tag Category**: `artist:` prefix filtering in tag autocomplete for targeted artist searches

## Tools Hub (11 Tools)
- **Wildcard Manager**: Browse, create, edit, and delete wildcard files with live preview, favorites, per-file randomization modes, and drag-to-reorder
- **Tag Library Manager**: Search, browse, favorite, and preview tags with inline image generation and visual examples
- **Preset Manager**: Full preset editor with inline sliders, character/interaction editing, and reference management
- **Style Editor**: Create and edit prompt style templates with prefix, suffix, and negative content
- **Reference Manager**: Add, configure, and manage Director Reference images with type/strength/fidelity controls
- **Cascade Editor**: Multi-beat sequential scene generation with character slots, environment tags, prompt stitching, custom resolutions per beat, and Cast button for quick save-and-return
- **Img2Img Editor**: Source image loading, multi-layer canvas editor integration, blank canvas option with custom resolutions, brush-based mask painting, strength/noise controls, client-side inpainting
- **Slideshow**: Configurable image slideshow player with transition timing, Ken Burns (pan/zoom) effect, and source selection from gallery or specific albums
- **Packs**: Export and import NAIWeaver Packs (`.vpack` files) containing presets, styles, wildcards, and director reference images as portable ZIP archives
- **Theme Builder**: Full theme customization with 8 built-in themes, custom user themes, color picker, font selector, text scale slider, bright mode toggle, and live preview
- **Settings**: API key management, auto-save toggle, shelf visibility toggle (Director Reference, Vibe Transfer), character editor mode toggle, custom output folder (desktop), locale selection

## Cascade System
- **Multi-Beat Scenes**: Define sequential beats with character slots, environment tags, per-beat prompts, and custom resolutions per beat
- **Prompt Stitching Service**: Assembles final prompts from character appearances + environment + global styles
- **Character Appearance Casting**: Define a character's look once and reuse across multiple beats
- **Cascade Library**: Save and load cascade configurations via SharedPreferences
- **Cascade Playback View**: Inline beat-by-beat playback overlay for cascade mode
- **Unsaved Changes Guard**: Save/discard confirmation dialog when leaving the cascade editor with unsaved modifications
- **Cast Button**: Save the active cascade to library and return to the main screen in one action
- **Responsive Navigation**: Labeled "Back to Library" and "Exit Cascade" buttons with mobile/desktop sizing

## Canvas Editor
- **Multi-Layer Canvas**: Full canvas editor with layer management — add, delete, reorder layers, per-layer visibility toggle and opacity control
- **Drawing Tools**: Paint brush, eraser, shapes (rectangle, circle, line), fill bucket, and text tool
- **Inline Text Editor**: Text tool opens an inline editor with live canvas preview and blinking cursor (replaces modal dialog)
- **Google Fonts for Text**: Choose any Google Fonts family for the text tool via a searchable font picker
- **Letter Spacing Control**: Adjustable letter spacing for canvas text strokes
- **Persistent Text Settings**: Font size, font family, and letter spacing persist across text strokes within a session
- **Eyedropper**: Pick colors from the canvas for precise color matching
- **Android Touch Support**: Tap-based tools (text, fill, eyedropper) work correctly on touch devices via `onTapUp` gesture handling
- **Keyboard-Safe Canvas**: Canvas does not resize when the soft keyboard opens for text editing
- **Flatten-to-PNG**: Merge all visible layers into a single PNG for seamless img2img pipeline integration, with Google Fonts and letter spacing rendered correctly
- **Blank Canvas Option**: Start from a blank canvas in the img2img source picker with standard or custom resolutions
- **Img2Img Source Image Save**: Automatically save the source drawing (`Src_*.png`) alongside the generated result (`Gen_*.png`) with matching timestamps

## Anlas Balance Tracker
- **Real-Time Anlas Display**: Current Anlas balance shown in the app bar
- **Auto-Refresh**: Balance automatically updates after each generation

## Furry Mode
- **Fur Dataset Prefix Toggle**: Enable fur dataset prefix for txt2img and Cascade generation to target the furry model

## In-App Update Checker
- **GitHub Releases Integration**: Check for new NAIWeaver versions via the GitHub releases API with in-app notification

## Slideshow
- **Configurable Slideshow Player**: Full-screen image slideshow with customizable transition duration
- **Ken Burns Effect**: Animated pan and zoom during slide display for dynamic visual presentation
- **Source Selection**: Play slideshows from the full gallery or a specific album
- **Saved Configurations**: Create, name, and save multiple slideshow configurations with a default selection

## Gallery
- **Image Vault**: Browse all generated images with search and filtering
- **Auto-Save**: Automatically saves all generated images to the output folder (configurable)
- **Export Button**: Save images from the gallery detail view with platform-branched behavior (Downloads folder on mobile, save-as dialog on desktop) and filename collision handling
- **Favorites**: Star/pin images in the gallery with a favorites-only filter toggle, persisted via SharedPreferences
- **Multi-Select**: Long-press (mobile) or rectangle drag (desktop) to select multiple images, with select-all toggle
- **Bulk Export**: Export multiple selected images at once to device gallery (mobile) or chosen folder (desktop)
- **Bulk Delete**: Delete multiple selected images with confirmation dialog
- **Virtual Albums**: Folder-like organization without moving files, managed via SharedPreferences
- **Sort Options**: Sort by date, name, or file size in ascending or descending order (6 sort modes)
- **Side-by-Side Comparison**: Compare two images with synced zoom, swap, and metadata chips
- **Image Info Overlay**: Hover over gallery tiles on desktop to see prompt and filename

## NAIWeaver Packs
- **Pack Export**: Select presets, styles, and wildcards to bundle into a `.vpack` ZIP archive
- **Pack Import**: Open `.vpack` files, preview contents, and selectively import items
- **Director Reference Bundling**: Reference images extracted to `references/` in the ZIP and restored on import via `@ref:filename` pointers
- **Pack Manager UI**: Full management interface in the Tools Hub for creating, browsing, and importing packs

## Metadata System
- **PNG Metadata Injection**: Generation settings (prompt, seed, dimensions, sampler, etc.) embedded in PNG Comment and Description text chunks using isolate-based processing
- **PNG Metadata Extraction**: Read settings back from any PNG with embedded metadata
- **Drag-and-Drop Import**: Drag an image onto the main viewer to automatically extract and apply its generation settings

## Localization
- **Multi-Language Support**: English and Japanese included out of the box
- **Extensible via ARB Files**: Add new languages by creating a new `.arb` file in `lib/l10n/` and running the Flutter localization generator
- **Locale Persistence**: Selected language saved across sessions via SharedPreferences
- **Full UI Coverage**: All tool names, labels, buttons, and messages are localized

## Linux Support
- **AppImage Build**: Linux desktop support via AppImage distribution
- **CI/CD Integration**: Automated Linux AppImage builds via GitHub Actions

## Android / Mobile Support
- **Responsive Layouts**: Adaptive UI that switches between desktop (sidebar, row layouts) and mobile (drawers, column stacking) based on platform
- **Mobile Navigation**: Tools Hub uses `endDrawer` on mobile; list+editor tools use `_showingEditor` flag for list/editor navigation
- **Bottom Sheet Settings**: Img2Img settings presented via FAB and `showModalBottomSheet` on mobile
- **Touch-Friendly Controls**: Enlarged slider thumbs (8px vs 4px desktop), `touchTarget()` sizing utilities
- **Keyboard-Aware Layout**: Prompt field offset adjusts for `viewInsets.bottom` on mobile
- **Safe Area Handling**: Proper `SafeArea` wrapping with `bottom: false` for body content

## Theme System
- **Token-Based Theming**: All UI colors and fonts flow through `VisionTokens` semantic design tokens, accessed via `context.t` extension
- **8 Built-In Themes**: OLED Dark (default), Soft Dark, Midnight, Pastel Purple, Rose Quartz, Emerald, Amber Terminal, Cyberpunk
- **Custom User Themes**: Create, edit, and delete custom themes based on any existing theme, persisted via SharedPreferences
- **15 Configurable Colors**: Background, surface (high/mid), text (primary/secondary/tertiary/disabled/minimal), border (strong/medium/subtle), accent (main/edit/success/danger)
- **Font Selection**: 7 font options (JetBrains Mono, Fira Code, IBM Plex Mono, Space Mono, Roboto Mono, Inter, Space Grotesk) via Google Fonts
- **Text Scale**: Adjustable font scale slider (75%–150%) applied globally through `t.fontSize()`
- **Bright Mode Toggle**: Per-theme toggle for brighter or dimmer text rendering
- **Color Picker**: Hex color input with curated palette grid for quick color selection
- **Live Preview**: Theme changes preview in real-time before saving

## Security & Demo Mode
- **PIN Lock**: 4-digit PIN to lock the app on launch, with set/verify dialogs and SHA-256 + salt hashing
- **Lock on Resume**: Re-lock the app when returning from background (configurable)
- **Biometric Unlock**: Fingerprint or face unlock support via `local_auth` (configurable)
- **Demo Mode**: Toggle to filter the gallery to only show demo-safe images; persisted via SharedPreferences
- **Demo Image Picker**: Full-screen grid picker to mark images as demo-safe, with ALL/CLEAR bulk actions and toggleable grid columns (cycles 2–3 on mobile, 3–5 on desktop)
- **Tag Suggestion Suppression**: Tag auto-suggest is automatically hidden while demo mode is active
- **Demo Prompt Prefixes**: Configurable positive prefix (default: "safe") and negative prefix (default: "nsfw, explicit") automatically prepended during generation when demo mode is on

## UI / UX
- **Dark Theme (Default)**: High-contrast black (#000000) background with off-white (#FAFAFA) text, JetBrains Mono font
- **Collapsible Settings Panel**: Slide-up advanced settings panel with grabber handle
- **Interactive Image Viewer**: Pinch-to-zoom with `InteractiveViewer`, loading pulse animation, drag-drop overlay
- **Character Shelf**: Horizontal scrollable shelf for quick character management on the main screen (compact mode); alternative expanded inline editor available in the settings panel
- **Director Reference Shelf**: Horizontal shelf with type-colored chips for reference images (toggleable via Settings)
- **Vibe Transfer Shelf**: Horizontal shelf with green-accented chips for vibe references (toggleable via Settings)
- **Quick Edit Button**: One-tap access to send the current generation into the Img2Img editor

## Post-Processing
- **SMEA / SMEA DYN**: Toggleable SMEA post-processing
- **Decrisper**: Dynamic thresholding toggle for sharper outputs
