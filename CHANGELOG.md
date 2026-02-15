# Changelog

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
