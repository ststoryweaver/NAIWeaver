<p align="center">
  <img src="logo.png" alt="NAIWeaver" width="128" />
</p>

# NAIWeaver

An unofficial cross-platform frontend for NovelAI's image generation API (Diffusion V5 and V4.5). Built with Flutter for Windows, Linux, Android, and Web.

Check out the github page to test it out, https://ststoryweaver.github.io/NAIWeaver/

## Features

### Image Generation
- NovelAI V5 + V4.5 API integration (txt2img, img2img, inpainting, precise reference, vibe transfer, multiple characters) with a per-model capability layer — V5 adds free character positioning (32 characters), native transparency, auto-Text and the Opus usage battery; Vibe Transfer / Character Reference stay on V4.5 until NovelAI enables them for V5
- Multi-character generation with pixel-level positioning and multi-participant interactions
- Expanded inline character editor with tag suggestions, UC editing, position grid, and character presets (save/load)
- Multi-layer canvas editor for img2img source creation (paint, erase, shapes, text with Google Fonts, layers, selection tools, blur, clone stamp, zoom/pan)
- Custom resolution dialog with 64-snap validation and save-for-reuse
- Anlas balance tracker in app bar with auto-refresh after generation
- Furry mode toggle for fur dataset prefix in txt2img and Cascade
- In-app update checker via GitHub releases API
- PNG metadata round-trip — settings embedded in images, re-importable via drag-and-drop
- Seed control with randomization toggle for reproducible generations
- Duplicate generation detection with warning snackbar and quick randomize action
- Widescreen sidebar layout mode for ultrawide and multi-monitor setups
- Keyboard shortcuts: Ctrl+Enter to generate, Alt+Left/Right to cycle styles, Ctrl+Up/Down to adjust tag weight, canvas tool shortcuts

### Director Reference
Upload reference images to guide character appearance or artistic style. Supports three reference types (Character, Style, Character & Style) with per-reference strength and fidelity sliders. The REF button provides quick access to saved references via a popup menu for instant loading.

### Vibe Transfer
Apply the aesthetic "vibe" of reference images to generations. Each vibe has independent strength and information extraction controls, allowing fine-tuned style influence without precise character matching.

### Cascade System
Sequential scene generation. Define setting, placement, actions, emotion, and state for each scene. Once your story is made, use the Cast button to return to the main editor, add your characters, and watch them play out the scenes. Includes unsaved-changes detection with save/discard confirmation.

### Characters
Build reusable personas with split appearance buckets (base / face / hair / body, plus NSFW sub-buckets) and a per-character closet of outfits — each character is one local JSON file, with its closet stored separately so wardrobes stay portable. A ✨ generator drafts a character and a starter wardrobe from a free-text vibe + era + location (a catalogue of historical era presets, period-correct undergarment rules that are gender- and era-aware) and an optional artist style tag. Outfits track per-slot dressing state (intact → removed) with automatic concealment of layered pieces. Saved characters appear in the tag autocomplete as `[Name]` and `[Name (Outfit)]`, expanding into the full body + outfit tag block, with per-character and per-outfit negative tags routed automatically. **Photoshoot mode** dresses a character in-place for a session — pull-up Dress / Scene / Prompt drawer, curated pose and environment presets, large image preview, and one-tap generate — without disturbing the saved closet. Requires Text Generation (a NovelAI text model) for the AI generators.

### Text Generation
A NovelAI text-model tool with a continue-style multiline input, model picker, full parameter controls (temperature, max length, top-P/K, repetition and phrase-repetition penalties), client-side stop strings, live streaming output, and a local history. Model-aware transport routes GLM/Xialong models through the OpenAI-style completions endpoint (GLM-4.6 through the chat endpoint) and legacy Kayra/Clio/Erato through `/ai/generate`, all on the same `pst-` token as image generation. For GLM models, an "enable thinking" switch surfaces the model's reasoning block in a collapsible section. Also powers the Characters and Wardrobe AI generators.

### On-Device ML Processing
- Background removal, image upscaling, and interactive segmentation via ONNX Runtime
- 8 downloadable ML models with SHA-256 integrity verification and device-aware recommendations
- Batch processing for gallery-wide BG removal and upscaling
- Before/after comparison slider with zoom and pan

### Director Tools
- 6 NovelAI augment-image tools: Remove BG, Line Art, Sketch, Colorize, Emotion, Declutter
- Emotion supports 24 mood presets; Colorize supports defry and prompt input

### Enhance
- Quick img2img refinement with strength, noise, and scale controls

### Quick Action Overlay
- Floating action buttons on generated images (Save, Edit, Remove BG, Upscale, Enhance, Director Tools, Export to Device)
- Each button individually toggleable; context-aware based on downloaded models

### Gallery
- Full-screen image detail view with swipe navigation, zoom, and metadata display (grey screen bug fixed)
- Bottom action bar with integrated ML, Director Tools, Enhance, and reference actions
- Gallery import preserves original creation dates from EXIF metadata
- Favorites, search, multi-select with drag-to-select
- Virtual albums (folder-like organization without moving files)
- Sort by date, name, or file size
- Image info overlay on hover
- Demo mode with PIN lock and biometric unlock for privacy
- Android data protection: "Keep app data?" prompt on uninstall, auto-backup to Google Drive

### Tools Hub (16 Tools)

| Tool | Description |
|---|---|
| **Wildcard Manager** | Browse, create, edit, and delete wildcard files (`__pattern__` substitution) with favorites |
| **Tag Library** | Danbooru tag auto-complete with visual examples and inline preview generation |
| **Preset Manager** | Full preset editor with characters, interactions, and reference management |
| **Style Editor** | Prompt style templates with prefix, suffix, and negative content |
| **Reference Manager** | Director Reference management with type, strength, and fidelity controls |
| **Characters** | Saved-persona library with appearance buckets, per-character closets, outfit dressing-state, AI character/wardrobe generation, and photoshoot mode |
| **Cascade Editor** | Multi-beat sequential scene generation with character slots and prompt stitching |
| **Img2Img Editor** | Source image loading, canvas editor, custom resolutions, brush-based mask painting with customizable mask color, opacity, and patterns, and inpainting |
| **Director Tools** | 6 server-side image augmentation tools (Remove BG, Line Art, Sketch, Colorize, Emotion, Declutter) |
| **Enhance** | Quick img2img refinement with strength, noise, and scale controls |
| **Slideshow** | Configurable image slideshow with transitions and Ken Burns effect from gallery or album sources |
| **ML Models** | Download and manage on-device ML models for BG removal, upscaling, and segmentation |
| **Text Gen** | NovelAI text-model generation with streaming output, parameter controls, reasoning mode, and local history |
| **Packs** | Export/import presets, styles, wildcards, director refs, saved references, vibe transfers, characters, themes, gallery albums, and settings as `.vpack` files |
| **Theme Builder** | 8 built-in themes + full custom theme editor with 17 configurable colors |
| **Settings** | API key, auto-save, shelf visibility, quick action buttons, upscale backend, tooltips, locale, layout mode (widescreen sidebar), device/SD-card export, and sidebar options |

### Localization
English, Japanese, and Simplified Chinese out of the box. Extensible via `.arb` files — see [Contributing](#localization-1) for adding new languages.

### Theme System
Token-based theming with 8 built-in themes (OLED Dark, Soft Dark, Midnight, Pastel Purple, Rose Quartz, Emerald, Amber Terminal, Cyberpunk) and unlimited custom themes. 17 configurable color tokens including `bgRemoval` and `upscale`. All colors and fonts flow through semantic design tokens.

## Requirements

- A NovelAI API key (subscription required)
- Flutter SDK ^3.10.7 (stable channel)

### GPU Acceleration (Optional)

On-device ML features (background removal, upscaling, segmentation) work on CPU out of the box. For faster inference on NVIDIA GPUs, install:

1. **CUDA Toolkit 12.x** — [download](https://developer.nvidia.com/cuda-downloads)
2. **cuDNN 9.x** — [download](https://developer.nvidia.com/cudnn-downloads) (free NVIDIA account required)
   - Copy cuDNN DLLs into your CUDA Toolkit `bin` directory, or add cuDNN's `bin` to your system PATH

Ensure `C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.x\bin` is on your system PATH, then restart the app.

If CUDA is not installed, the app automatically falls back to **DirectML** (Windows) or **CPU**.

## Quick Start

```bash
# Clone
git clone https://github.com/YOUR_USERNAME/naiweaver.git  # Replace with your repo URL
cd naiweaver

# Install dependencies
flutter pub get

# Run
flutter run -d windows    # Windows
flutter run -d linux       # Linux
flutter run -d chrome      # Web
flutter run                # Android (with device connected)
```

## Build

```bash
flutter build windows     # Windows release
flutter build linux        # Linux release
flutter build apk         # Android APK
flutter build web         # Web build
```

## Configuration

1. Launch the app
2. Go to **TOOLS > SETTINGS**
3. Enter your NovelAI API key
4. Start generating

## Project Structure

```
lib/
  main.dart                    # Entry point, provider setup
  core/
    ml/                        # On-device ML inference pipeline (ONNX Runtime)
    theme/                     # Token-based theme system
    l10n/                      # Locale state management
    services/                  # NovelAI API, preferences, paths, pack service, presets, styles, tags, wildcards
    utils/                     # Image utils, responsive helpers, snackbar, timestamps
    widgets/                   # Shared widgets (comparison slider, quick actions, dialogs, etc.)
  l10n/                        # ARB translation files (en, ja, zh)
  features/
    generation/                # Main generation UI, character editor, services
    characters/                # Saved-character library, AI char/wardrobe gen, outfits, photoshoot
    text_gen/                  # NovelAI text-model generation (streaming, reasoning, history)
    gallery/                   # Image gallery with albums, detail view, services
    director_ref/              # Director Reference system
    vibe_transfer/             # Vibe Transfer system
    tools/                     # Tools Hub (16 tools)
      canvas/                  # Multi-layer canvas editor with text/font tools
      cascade/                 # Multi-beat sequential generation
      director_tools/          # Director Tools (6 augmentation tools)
      enhance/                 # Enhance (quick img2img refinement)
      img2img/                 # Img2Img with inpainting
      ml/                      # ML model manager UI
      slideshow/               # Configurable slideshow player
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for a detailed breakdown.

## NAIWeaver Packs

Share your presets, styles, wildcards, and director references with others using `.vpack` files:

- **Export**: TOOLS > PACKS > Export Pack — select items, name your pack, save as `.vpack`
- **Import**: TOOLS > PACKS > Import Pack — open a `.vpack`, preview contents, import selected items
- Packs are ZIP archives containing JSON presets/styles and wildcard text files
- Director Reference images are extracted and re-embedded automatically

## Roadmap

See [ROADMAP.md](ROADMAP.md) for development principles, completed milestones, and planned features.

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, code style guidelines, and PR process.

Feature requests and bug reports are encouraged — please open a [GitHub Issue](../../issues).

## Related Projects
These projects were great resources and inspiration:
- [novelai-python](https://github.com/LlmKira/novelai-python) by [@LlmKira](https://github.com/LlmKira) — NovelAI API Python SDK
- [NAI_UI_2](https://github.com/EctoplasmicNeko/NAI_UI_2) by [@EctoplasmicNeko](https://github.com/EctoplasmicNeko) — NovelAI desktop app with additional features
- [ComfyUI_NAIDGenerator](https://github.com/bedovyy/ComfyUI_NAIDGenerator) by [@bedovyy](https://github.com/bedovyy) — NovelAI Diffusion generator for ComfyUI
- Special thanks to Glockamoli and his TamperMonkey script for the comparison tool

## Contributors

- [@baisumang](https://github.com/baisumang) — Simplified Chinese translation
- [@andreiagmu](https://github.com/andreiagmu)

## License

[MIT](LICENSE)
