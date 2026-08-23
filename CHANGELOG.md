# Changelog

## v0.9.3

### New
- **NovelAI Diffusion V5 support** — a new **MODEL** section at the top of the settings panel picks **V5 Full · V5 Curated · V4.5 Full · V4.5 Curated** (it replaces the old CURATED toggle; your previous choice is migrated and nobody is moved to V5 automatically). Per-model capabilities are data (`lib/core/models/nai_model.dart`), mirroring NovelAI's own frontend table as of launch day, so the request sent to NovelAI is always valid for the chosen model:
  - V5 bodies force `noise_schedule: karras`, send `params_version: 4`, drop SMEA/SMEA DYN and the Vibe Transfer / Character Reference arrays (not available on V5 at launch — the data is kept and used again when you switch back), and send raw character coordinates.
  - V4.5 bodies are unchanged, except that stale `SMEA`/`SMEA DYN` preset flags are no longer sent (NovelAI returns HTTP 500 for them on every V4+ model).
  - Inpainting routes to `nai-diffusion-5-full-inpainting`; V5 Curated uses the V4.5 Curated inpainting model (and gets a V4.5-shaped request body to match), exactly as NovelAI's UI does until V5 Curated inpainting ships.
  - Enhance now renders with the selected model (it was always V4.5 Full before, even with CURATED on).
- **V5 free character positioning** — with a V5 model the character position picker becomes a free-drag canvas (aspect-matched to the current resolution, 3-decimal precision, faint 5×5 guides) instead of the 5×5 grid; up to **32** characters per generation. V4.5 keeps the grid and the 6-character cap.
- **V5 native transparency** — a **TRANSPARENT BG** toggle (V5 only) appends `transparent background` to the prompt and requests straight alpha; the result is a real RGBA PNG, shown over a checkerboard in the viewer and saved as-is (metadata is injected without re-encoding).
- **V5 auto-Text** — on V5, a quoted string in the prompt (`"..."` or `「...」`) is promoted to a `Text:` block the way NovelAI's frontend does; a manual `Text:` block disables it.
- **Opus V5 usage battery** — the Anlas chip shows the V5 allowance (`%` and `~images left`, orange when low) whenever a V5 model is selected; the MODEL section shows a pre-flight label (**FREE ON OPUS** / **V5 ALLOWANCE** / **COSTS ANLAS**) for the next render. Subscription data now comes from `image.novelai.net/user/subscription` (the legacy host is a fallback).
- **"DEFAULTS" button** in the MODEL section resets steps / scale / sampler to NovelAI's defaults for the active model (V5: 23 steps, scale 7.0 · V4.5: 23 steps, scale 5.0). Switching models never rewrites your tuned values.
- **V5 prompt helpers** — `k_dpmpp_2m_sde` added to the sampler list; the new V5 tags (`depthness`, `attractive male`, `low|medium|high|ultra complexity`, `has alpha`, `meta:novel era`, `visual novel …`) autocomplete; the bundled styles now carry NovelAI's full quality / UC preset set for both model families, each marked with its model — `Quality V4.5 (NAI Default)`, `Light V4.5 - NAI`, `Heavy V4.5 - NAI`, `Quality V5 (NAI Standard)`, `Quality V5 (NAI Light)`, `Light V5 - NAI`, `Heavy V5 - NAI`, `Human Focus V5 - NAI`, `Furry Focus V5 - NAI` (new installs, or Style Editor → reset to defaults).
- **Model is remembered everywhere** — session snapshot, generation presets (older presets simply don't pin a model), backups (`nai_model`), and PNG metadata (`model` is written and imported). Only an explicit `model` entry counts on import: the model is never guessed from NovelAI's `Source` text, which doesn't name the Curated variant — so importing settings from an old image can't switch your model.
- **Noise schedule, guidance rescale and Variety+** — three settings NovelAI's web UI exposes that the app did not, so certain images simply could not be reproduced here. Each is gated per model (V5 forces karras and has no Variety+ at launch, so it hides the controls instead of offering no-ops); V4.5 bodies now send `cfg_rescale` / `skip_cfg_above_sigma` exactly as NovelAI's own frontend does. All three are saved in presets, read back from PNG metadata on import, and sent everywhere the app renders — txt2img, img2img/inpaint, cascade beats, tag previews and Enhance (#35).
- **Vibe Transfer and Character Reference are now mutually exclusive**, matching NovelAI's own UI. The API has no contract for receiving both and could return an empty/truncated image for the combination — the source of the corrupt files that froze the gallery in #24. The exclusion is enforced in the request builder (Character Reference wins), and the Vibe controls grey out with an explanation while a reference is active instead of silently having their data dropped.
- **Web: importing images works** — on web the file picker returns no path, so every "pick an image" action silently did nothing. Character Reference / Vibe Transfer imports (shelf, sidebar rail, both managers), img2img / Enhance / Director Tools "upload from device", mask load and the Canvas image-layer import now read the picked bytes from memory (#8). Adapted from [@RedContritio](https://github.com/RedContritio)'s fork.

### Fixes
- **Preset editor SMEA / SMEA DYN / Decrisper toggles removed** — no V4+ model supports them; presets that still carry the flags show a note instead.
- **Editing a preset in the Preset Manager no longer drops its Vibe Transfers.**
- **PNG metadata was never actually written or stripped.** `package:image`'s PNG encoder ignores its own `textData` field, so since the first release `injectMetadata` never wrote our Comment JSON (smart style import and model pinning couldn't work from our own images), "Strip metadata on export" and the pack-export strip option shipped the full prompt anyway, and WebP/JPEG metadata was dropped on import. All three now work on the actual bytes. NovelAI's own `Source` and `Comment` chunks are kept untouched — the app's record (clean base prompt, model, styles) rides in its own `NAIWeaver` chunk instead of overwriting NovelAI's — and the base64 image/mask/reference payloads are left out the way NovelAI does.
- **Numerical weights highlight anywhere in the prompt**, not just at the very start (`girl, 2::tag::`), and positive/negative weights use NovelAI's warm/cool colours (#38).
- **Negative-prompt tag suggestions can be clicked on desktop** — the list cleared itself on focus loss before the click landed, which is why it reproduced on Windows but not Android (#37).
- **Transparency checkerboard** — only drawn behind images with *visibly* transparent pixels. The old check said "yes" for every RGBA PNG (i.e. almost everything NovelAI returns), and even a strict pixel scan trips on the invisible alpha-254 noise NovelAI's renders carry. It's also clipped to the image instead of the whole preview box — no more checkerboard slivers at the edges of opaque renders.
- **Web: no more `Unsupported operation: _Namespace` console errors** from the Wildcard Manager, img2img auto-save or Tag Library examples — filesystem-only paths are gated off on web (#8).
- **Anlas chip** shows the V5 usage percentage only, and on mobile it sits clear of the help button (with TOOLS no longer hugging the screen edge); the MODEL section follows the theme's section order.
- **Duplicating a preset** no longer drops its model pin and Vibe Transfers.

### Under the hood
- `NovelAIService` builds every NovelAI URL and auth header through one helper (`_imageUrl` / `_apiUrl` / `_headers`), so a proxy or self-hosted endpoint is a one-place change. A standalone Anlas cost estimator (`nai_cost_estimator.dart`, mirroring the official frontend's formula) ships as a library function, not yet surfaced in the UI. Both ported from [@RedContritio](https://github.com/RedContritio)'s fork (MIT).

## v0.9.2

### New
- **Move your image library to the SD card (Android)** — Settings → Output Folder now shows a **USE SD CARD** button whenever a removable card is mounted. It points saves at the app's own folder on the card (`Android/data/dev.naiweaver.app/files/output` — writable with zero extra permissions on every Android version, no "all files access" prompt), and offers to move your existing library there: free space is checked first, then each file is copied → size-verified → only then deleted from internal storage, with live n/total progress and cancel. An interrupted move (cancel, crash, reboot) offers to resume on the next tap, skipping files already safely on the card and re-copying partials. Canvas sidecar files travel with their images, and albums are unaffected. If the card is ejected, the app falls back to internal storage for that session and returns to the card when it's back; no card → the button simply doesn't appear. ⚠️ Android deletes `Android/data` on uninstall — **including the copies on the SD card** — so export anything precious elsewhere before uninstalling. Requested by [@UraganAI](https://github.com/UraganAI) (#21).
- **Draggable gallery scrollbar** — the gallery grid has an always-visible, grabbable scrollbar thumb (accent-tinted, thicker on touch screens), so reaching a precise point in a multi-thousand-image album is one drag instead of laps of fling-scrolling. Requested by [@UraganAI](https://github.com/UraganAI) (#19).
- **Custom filenames & save paths with wildcards** — two pattern fields in Settings under the output folder, with a live preview: `<prompt>`, `<seed>`, `<album>` / `<album:fallback>`, zero-padded `<year> <month> <day> <hours> <minutes> <seconds>` (plus `<date>` / `<time>` shorthands), `<digits:0000>` per-folder counters, and literal text. Save-path patterns file images into auto-created subfolders (e.g. `2026/07/19`), the counter resets per subfolder, and the gallery scans subfolders recursively so patterned saves survive restarts. Empty fields keep the current NAI-style names and flat folder. Requested by [@andreiagmu](https://github.com/andreiagmu) (#27).
- **Resizable character prompt boxes** — a slim grab bar under the character prompt field resizes it line-by-line (2–15 lines, default unchanged at 3). The size is persistent and shared by the inline character cards and the character editor sheet, so you set it once. Requested by [@UraganAI](https://github.com/UraganAI) (#15).
- **Canvas: selections that actually select** — rectangle and lasso selections now clip brush, shape, and fill strokes to the selected region (transform-aware), DELETE clears inside the selection, and the overlay draws the true region instead of an approximation (#23).
- **Canvas: flood-fill Fill tool** — Fill pours into the contiguous color region under the cursor instead of flooding the entire layer (#23).
- **Canvas: Move tool moves, eyedropper sees** — the Move tool actually moves the active layer, and the eyedropper samples the composited canvas rather than just the source image. Brush size is now specified in pixels with a 1px floor (#16, #23).
- **Tag autocomplete in the negative prompt box** — same suggestions, favorites, and wildcard support as the main prompt (#23).

### Fixes
- **Corrupted images can no longer freeze the Gallery (Android).** Two halves. Failed generations — e.g. the unsupported Vibe Transfer + Precise Reference combo, which NovelAI's own UI doesn't allow — could return a ZIP whose image entry is empty or truncated; those bytes were saved verbatim and became corrupt gallery files. The API layer now rejects non-image bytes so the failure surfaces as a generation error instead of a broken file. And the gallery itself now tolerates whatever it finds on disk: unreadable images degrade to a broken-image placeholder tile (grid and detail view), 0-byte files are skipped at scan, entries whose files were deleted with a file manager are pruned every time the gallery opens, and grid thumbnails decode at a capped size so big galleries scroll lighter. Report and patient diagnosis thanks to [@andreiagmu](https://github.com/andreiagmu) (#24).
- **Album strip: swipe scrolls, long-press moves.** On touch, the whole album chip was an immediate drag handle, so horizontal swipes kept picking albums up. New model, exactly as proposed: long-press a chip (with haptic) to enter move mode and drag; a plain swipe scrolls the strip; tapping the already-selected album opens rename/delete. Proposed by [@UraganAI](https://github.com/UraganAI) (#20).
- **Mouse wheel on Android scrolls ~one text line per notch** instead of jumping 3–4 lines in prompt boxes and lists. Android converts a notch into the system scroll factor (~64+ px); wheel deltas are now rescaled globally on Android — desktop, trackpads, and touch are untouched. Reported by [@UraganAI](https://github.com/UraganAI) (#14).
- **Generated filenames match NovelAI's own format** (`1girl, black hair s-12345678.png`), so files sort alongside webview downloads. Contributed by [@ArranPell](https://github.com/ArranPell) (#28, PR #30).
- **Canvas & img2img input and zoom** — all canvas tool input routes through InteractiveViewer interactions, fixing pinch-zoom on mobile; mouse-wheel zoom is clamped to sane bounds and anchored at the cursor (#17, #18, #23).
- **Emphasis highlighting covers the full `N::tag::` unit** including the closing `::` and negative/fractional weights, and a rare highlighter hang on strength prefixes inside brackets is fixed (#23).
- **Android: the GitHub and update links in Settings actually open** (#23).
- **Readability** — the export album/folder fields no longer render near-invisible text, swatch selection rings use luminance-contrast borders, and canvas slider `%` labels are legible (#25).

### Docs
- CONTRIBUTING now says to branch from `master`, and `.dart` files are normalized to LF so `dart format` doesn't rewrite the tree on Windows checkouts. Contributed by [@ArranPell](https://github.com/ArranPell) (PR #29).

## v0.9.1

### New
- **In-app auto-updater (Android & Windows)** — the Settings "Check for Updates" button used to just open the GitHub release page and leave you to download and install by hand. It now downloads the correct release asset and applies it. On Android it fetches the matching `.apk` into app-external storage and launches the system package-installer (you tap Install); on Windows it fetches the `.zip` and runs a detached helper that waits for the app to close, swaps the install dir in place (with an elevation fallback for Program Files installs), and relaunches. The right build is picked by platform and app locale from the release assets (`NAIWeaver[-ja|-zh].{apk,zip}`), falling back to the English build and then to opening the release page if nothing matches. A throttled once-a-day background check on launch surfaces a non-intrusive prompt; the download dialog shows progress and can be cancelled. Downloads are pinned to the official GitHub release source — the API URL is hardcoded, asset URLs are accepted only from GitHub hosts over HTTPS, and the downloaded binary is checked against the release's published SHA-256 (when available) before anything is installed. Installation-flow idea thanks to [@andreiagmu](https://github.com/andreiagmu).
- **Cascade SCENE / ACTION base prompt** — each beat gets a dedicated booru-tag field for *what's happening* (subject count, action, composition/camera), distinct from ENVIRONMENT, which describes *where*. Both feed the NovelAI base prompt with Scene/Action front-loaded ahead of Environment to match NAI's base-prompt weighting. Backward-compatible with older cascades (the field defaults blank).
- **Cascade global scene tags** — a GLOBAL SCENE box on the casting sheet holds scene/action tags shared by every beat (e.g. `2girls, school uniform` that never changes), inserted ahead of each beat's own scene and environment. An "apply scene to all beats" action copies one beat's scene onto the rest for the fixed-shot / changing-action workflow.
- **Cascade narration captions** — type a prose narration caption per beat, shown over the preview behind a legibility scrim so a cascade reads like a storyboard. Captions are cast-time state for the current run; they aren't saved with the cascade or baked into the in-app preview bytes.
- **Cascade caption burn-in & storyboard export** — an explicit export action bakes captions into the pixels: share a single captioned beat, or assemble every generated beat into a numbered comic-style storyboard strip (vertical or horizontal). Routes through the platform path — share sheet on mobile, save-file dialog on desktop, browser download on web. Long strips are capped on their long axis to stay within memory limits, with a "shrunk to fit" notice when that happens. Saved cascades and in-app previews stay clean — burn-in only affects the exported image.

### Fixes
- **Cascade previews and captions now stay glued to their beats.** The per-beat preview and caption maps are keyed by beat index, but cloning, removing, or reordering a beat changed the beats list without re-keying those maps — so a removed beat left every later beat showing the wrong image and caption, and clone/reorder mis-attached them. Each structural edit now applies the matching index shift, so a beat's preview and caption travel with it. (A beat holding an explicit empty preview also no longer counts as "generated" in the export menu.)
- **Cascade caption preview matches the export.** The in-app caption preview now uses the same aspect ratio as the burned-in PNG, so what you see during playback is what you get in the exported frame.
- **Pinch-to-zoom on the inpaint canvas** now works on mobile. The mask canvas drove zoom by flipping `scaleEnabled` only after a second finger landed, but Flutter's gesture arena resolves in the same frame the pointer arrives — so scale was still disabled when it needed to win, and pinch never engaged. Drawing and zoom now both run through InteractiveViewer's own interaction callbacks (single finger paints, two fingers pinch), removing the gesture-arena conflict entirely. (The general image-editor canvas has the same latent issue and a much larger tool set; its port is tracked separately.)
- **Style cycling no longer eats text selection.** The style-cycle shortcut moved from `Ctrl+Shift+Left/Right` (which collided with the OS word-by-word selection shortcut inside the prompt box) to **`Alt+Left/Right`**, and works whether or not the prompt field is focused. `Ctrl+Up/Down` still adjusts tag weight on the tag at the cursor.
- **img2img from the gallery no longer double-applies styles.** Sending a saved image to img2img pulled its fully-styled prompt from metadata, then re-applied the active style on top, duplicating the style tags. img2img now loads the clean base prompt (`original_prompt`) when present, so the style is applied exactly once. Applies to the gallery action and both of the img2img tool's own "from gallery / from device" pickers; older images without a stored base prompt fall back to the previous behavior.
- **No more lag editing large wildcards.** Adding a tag to a wildcard with hundreds of entries was rewriting the whole file to disk on every keystroke. Saves are now debounced (and flushed on file switch / close), so typing stays responsive regardless of list size.
- **Backslashes are stripped from prompts.** `\` has no meaning in NovelAI prompts; any backslashes (usually pasted in by accident) are now removed from the positive prompt, negative prompt, and per-character captions before the request is sent.
- **Save mask now works on mobile and web.** The img2img inpainting "Save mask" button only ran a desktop save-file dialog, which silently does nothing on Android and isn't supported on web — so on those platforms the button appeared dead. It now routes through the same path as every other export: browser download on web, share sheet on mobile, save-file dialog on desktop, with a confirmation toast on save.
- **New cascades can generate their first beat.** Creating a fresh cascade left its cast slots unseeded, so GENERATE BEAT silently did nothing (it couldn't build a request and never showed a loading state). New cascades now start with one appearance slot per character and a cleared cast state, and a failed beat build surfaces an error message instead of no-op'ing.

## v0.9.0

### Characters
- **Saved character library** — build reusable personas with split appearance buckets (base / face / hair / body, plus NSFW sub-buckets) and a per-character closet of outfits. Each character is stored locally as one JSON file with its closet kept separately, so wardrobes stay portable and editable. Clothing never lives on the character — it lives in the closet.
- **AI character generation** — a ✨ generator drafts a character and a starter wardrobe from a free-text vibe + era + location. Ships with a catalogue of historical era presets (Age of Ramesses through the modern day) for period-correct results, and a lean appearance-only prompt that emits canonical Danbooru tags instead of invented English phrases. The old soul-md continuation pipeline (which truncated on lower-tier token budgets) is gone; generation is now a single bounded call with a `<<END>>` stop string. The generate form is now a single free-text **vibe** box (blank lets the model pick) plus an optional **style** field backed by the Danbooru artist-tag autosuggest, which is written straight onto the character's image prompt as its artist tag. The starter-wardrobe slider defaults to 2 (range 0–3) to stay within lower-tier token budgets.
- **Wardrobe generator** — generates era- and vibe-appropriate outfits with garment-only tag scope and a curated color palette. Undergarment rules are now gender- and era-aware: a male historical character gets period base layers (loincloth, braies, linen undershirt) instead of feminine undergarment tags, and a modern character gets the right modern base layer — and the character page's "✨ Generate outfits" action now passes the character's gender through so those rules actually apply (previously it generated gender-blind). The per-run outfit count defaults to 2 (range 1–3). Bra dressing-state fix: the stale `aside` state is gone (`bra aside` isn't a real tag); `lifted` → `bra lift`, `pulled_down` → `bra pull`, legacy `aside` remaps to `bra pull`.
- **Outfit state** — each outfit tracks per-slot dressing state (intact, unbuttoned, open, lifted, pulled down, aside, around ankles, removed) with automatic concealment so layered pieces only surface when the outer garment moves. The state panel is mobile-first: garment cards with tap-to-open state pills.
- **Insert characters anywhere via autocomplete** — saved characters appear as `[Name]` and `[Name (Outfit)]` entries in the tag autocomplete, ranked above ordinary Danbooru tags. Picking one expands into the full body + outfit tag block. An inline **honor outfit state** toggle in the suggestion overlay switches between the flat tag string (default) and the state-rendered expansion (concealment + `nsfw` when dishevelled).
- **Per-character & per-outfit negative tags** — attach negatives to a character or a specific outfit. On insertion the combined, de-duplicated negatives route to the right field automatically: the global negative prompt, or a per-character UC field when the character is inserted inside a character editor.
- **Photoshoot mode** — pick a character + outfit, dress them in-place for the session (ephemeral by default, with an explicit "save state to outfit" button), choose a style plus curated pose and environment presets, preview the assembled prompt, and generate through the existing image pipeline — without disturbing the saved closet. Pose/environment libraries are SFW-only in this release. The screen now mirrors the main editor: a large image preview fills the top (tap to open the full-screen gallery viewer, with a recent-shots strip), and the controls live in a pull-up drawer with Dress / Scene / Prompt tabs and a persistent GENERATE/SEND action bar that never scrolls away. The outfit switcher moved into the app bar. GENERATE now snapshots and restores the main editor's prompt + negative so a photoshoot doesn't clobber what you had typed there, surfaces auth/generation errors instead of always claiming success, and routes the character's + outfit's negative tags into the negative prompt (SEND appends them, de-duplicated). The keyboard no longer double-counts the system nav-bar inset, so the drawer sits flush on top of it.

### Text Generation
- **NovelAI text models** — a new Text Gen tool with a continue-style multiline input, model picker, full parameter controls (temperature, max length, top-P/K, repetition + phrase-repetition penalties), client-side stop strings, live streaming output, and a local history.
- **Model-aware transport** — GLM/Xialong models route through `/oa/v1/completions` (and GLM-4.6 through the chat-style `/oa/v1/chat/completions`), while legacy Kayra/Clio/Erato models use `/ai/generate`. Uses the same `pst-` token as image generation.
- **Reasoning mode** — for GLM models, an "enable thinking" switch routes through the chat endpoint so the model's `<think>…</think>` block is surfaced in a collapsible Reasoning section alongside the answer.

### Export & Sharing
- **Export to an SD card (Android)** — choose a removable-SD-card folder as your export target via the system folder picker. The write grant survives reboots, and exports stream straight to the card through the Storage Access Framework, which plain `dart:io` file writes can't reach under Android scoped storage (#13). Gallery bulk export and image-detail save route to SAF vs `dart:io` based on whether the stored folder is a `content://` tree URI, and re-check the grant before each write. SAF writes now pass `overwrite: true` so re-exporting the same image replaces it instead of silently disambiguating to `name (1).png`, matching the plain-filesystem path. A custom export folder stored as a bare filesystem path (carried over from an older version or a desktop session) is now detected as unreachable under scoped storage: manual export surfaces a clear "re-pick it in Settings" message, and auto-export falls through to the device gallery instead of dropping the image to a swallowed `PathAccessException`.
- **Web image download** — generated images can now be saved on the web build via a standard `<a download>` browser download. Repeated saves of the same image in one session now get a `_(2)`, `_(3)`, … suffix (tracked in memory, since the web has no filesystem to probe for collisions), matching the unique-filename convention on native.

### Packs & Backup
- **Bigger `.vpack` backups** — packs now bundle your custom themes, gallery albums, and an app/jukebox settings blob in addition to presets, styles, wildcards, references, vibes, and character presets, with new manifest counts and a restart hint on import. The settings blob is allowlisted on both export and import — the API key, PIN hash, and folder paths are intentionally excluded, so a malicious pack can't inject arbitrary preferences.

### Generation UX
- **Enable/disable vibes & references** — a toggle pill on vibe-transfer and director-reference chips/editors lets you switch an item off without deleting it. The `enabled` flag round-trips through JSON (defaults true on legacy data) and disabled items are skipped at generation time.
- **Type exact slider values** — tap any slider's number to type a precise value, including beyond the soft range up to a hard cap, mirroring NovelAI.

### Cascade
- **Multi-interaction beat slots** — a cascade beat slot can now hold multiple interaction tags at once (e.g. `source#hugging`, `target#hugging`, `mutual#holding hands`) instead of a single one.

### Inpainting & Canvas
- **Discard partial stroke on pinch-zoom** — when a one-finger stroke is interrupted by a second finger starting a pinch-zoom, the partial stroke is discarded instead of being committed to the inpaint mask or canvas layer.

### Jukebox
- **Anime & game song categories** — new anime and game MIDI tracks, bundled in-repo alongside the existing songs.

### Gallery
- **Fix Android image import stripping PNG metadata** — `file_picker 8.x` defaults `compressionQuality` to 30, which on Android forces a `Bitmap.compress(JPEG, 30, ...)` re-encode for any `FileType.image` pick. PNGs were being silently transcoded to JPEG before reaching the app, destroying NovelAI `tEXt`/`iTXt` metadata chunks (Comment, Description, Software). Now passes `compressionQuality: 0` to short-circuit the native re-encode and stream original bytes through unchanged. Affected every Android user since `9f41d05` reverted the `FileType.custom` workaround on Mar 22; native PNGs (including NAIWeaver-exported ones) now round-trip with metadata intact. The "(N converted to PNG)" status message should now only appear for genuinely non-PNG inputs.

### Fixes
- **Touch drag-to-scroll on long prompts** — a mouse wheel on Android no longer skips multiple lines in multi-line prompt fields; drag-scroll is now gated to touch and stylus input (#14).
- **Desktop window** — guard against an invisible window restored from stale saved bounds.

### Security & Privacy
- **No prompt content in release logs** — the text-generation service's request-body debug logging is now gated behind debug builds, so user prompt content no longer lands in release-build logs. (The auth token was never in the request body.)
- **Saved-character data stays local** — runtime character data (personas, closets) written to the working directory during development is gitignored and never enters version control.

### Code Quality
- **Test coverage** — new suites across the Characters and Text Gen modules (outfit classifier / renderer / delta, wardrobe generator, negative-tag routing, character generation, SSE parsing, parameter mapping), plus pack-backup round-trip, exportable-settings allowlist, cascade beats, and a prompt-iteration lab harness. Full suite passing.
- **Analyzer clean** — zero errors, warnings, or infos.

### Localization
- New strings localized for EN, JA, ZH (Text Gen panel, pack sections, character UI).

### Notes
- New dependencies: `web`, and `saf_util` / `saf_stream` (pinned to the 2.x line) for Android SD-card export.

### Contributors
- [@andreiagmu](https://github.com/andreiagmu)

## v0.8.6

### Tag Library
- **Danbooru wiki descriptions** — tap any tag in the tag library to open a detail sheet with the wiki description, "other names" chips (Japanese / aliases), and tappable `[[wiki_link]]` spans that navigate the tag graph in-app. Unresolved links (tag groups, missing pages) open the source page on Danbooru in your browser. ~25,000 entries (~14 MB) preprocessed from the `isek-ai/danbooru-wiki-2024` dataset, converted from DText to simplified markdown at build time, and bundled for offline use. Wiki content © Danbooru contributors, CC-BY-SA-4.0.
- **Hover affordance on desktop** — tag rows now show a click cursor, accent-tinted background, left-edge accent border, and underlined tag name on hover, so the new tap-to-open behavior is discoverable.

### Theme Builder
- **Header / Title / Button scale sliders** — three new multipliers (75–200%) on top of the existing TEXT SCALE. HEADER scales markdown headings (used by the wiki sheet today, ready for any future markdown surface). TITLE scales panel titles, app bar titles, section headers, and dialog titles. BUTTON scales confirm-dialog action buttons. Multiplicative on top of the global text scale so users can tune body and chrome independently.

### Web Platform
- **Platform-agnostic key/value storage** — new `KvStore` abstraction with a file backend on native platforms and `SharedPreferences` on web. Presets, styles, wildcards, reference library, and session snapshots all route through it, so the web build now persists user data across reloads.
- **Filesystem-only features gated** — gallery import, canvas persistence, generation save-to-disk, wildcard file ops, and tag library save now early-return on web instead of crashing.

### Inpainting
- **Square brush is the new default** — first-time users no longer hit the round brush's known opacity-stacking artifacts. The toggle still exists for users who prefer round.
- **Mask undo (Ctrl+Z)** — global Ctrl+Z handler in img2img undoes the last mask stroke without losing focus context.
- **Pen-down stroke start** — touch and stylus strokes now begin on `onPointerDown` instead of after the pan-slop threshold, removing the small drawing delay that mouse users never saw.

### Director References
- **Tap to open saved-refs sheet** — tapping the REF button now opens the saved-refs sheet directly. Long-press still shows the old menu for power users.
- **Strength / fidelity persistence** — last-applied REF strength and fidelity are remembered across sessions instead of resetting to defaults.

### Cascade
- **Wildcard autocomplete** — typing `__` in cascade beat prompts now shows the wildcard suggestion overlay, matching the behavior of the main prompt editor.

### Settings Panel
- **Style chip tooltips** — richer hover tooltip for style chips, surfacing the full style content.
- **Touch drag-to-scroll on negative prompt** — long UC strings no longer require a scrollbar drag on touch devices.
- **Settings font-scale slider** — quick text-scale slider available directly in app settings, mirroring the theme builder control.

### Gallery
- **Fix overwrite collisions** — saving an image with a name that already exists now generates a unique suffix (`name (2).png`) and evicts the in-memory `FileImage` cache so the new file shows immediately. Previously the gallery would display the old cached image until restart.

### Code Quality
- **Test coverage** — four new test files added this cycle covering the new `KvStore` round-trip, presets/styles/wildcards/refs storage paths, unique-filename generation, and pack saved refs. 21 tests, all passing.
- **Analyzer clean** — zero errors, warnings, or infos.

### Localization
- New strings localized for EN, JA, ZH (theme scale labels).

### Notes
- App bundle grows by ~14 MB to accommodate the offline wiki database.
- Tag descriptions are licensed CC-BY-SA-4.0; see `Tags/LICENSE-WIKI.txt` and the build pipeline in `Tags/`.

## v0.8.4

### Gallery & Albums
- **Fix export saves to wrong folder** — gallery bulk export and single-image export now correctly pass the `album:` parameter to `Gal.putImageBytes()`, saving to Pictures/NAIWeaver instead of Pictures root
- **Import to active album** — importing images while viewing an album now adds them to that album, instead of the generation settings default
- **Album reorder** — drag albums in the gallery strip to reorder them. New albums no longer stuck at the end
- **Remove from album** — new "Remove" action in both gallery selection toolbar and image detail view when viewing an album
- **Preserve metadata on import** — imported images now retain their NovelAI Comment chunk and other PNG metadata (switched from `convertToPng` to `convertToPngPreservingMetadata`)

### Export & File Naming
- **NovelAI-style filenames** — generated images are now named with the prompt start + seed (e.g. `1girl_ancient_greek_macedonian_177319647.png`) instead of timestamps. Falls back to timestamp when no metadata available
- **Custom export folder** — new "Export Folder" picker in settings. Choose any folder (including SD card) for exports. Overrides the gallery album when set. Clear to return to default behavior

### Inpainting
- **Round/square brush toggle** — new brush shape button in mask toolbar. Round brush fills only grid cells within a circular radius; square brush fills the full bounding box
- **Tap-to-fill single cell** — tapping (not dragging) on the mask canvas now places a single brush mark, useful for precise masking
- **Disable scale on InteractiveViewer** — zoom is now exclusively handled via scroll wheel, preventing accidental pinch conflicts on desktop

### Prompt Editing
- **NAI tag weight format** — Ctrl+Up/Down now uses NovelAI's native `1.2::tag::` syntax instead of the legacy `{tag:1.2}` format. Both formats are recognized when parsing
- **Key repeat support** — Ctrl+Up/Down weight adjustment now responds to held keys (KeyRepeatEvent), not just initial press

### Localization
- All new strings localized for EN, JA, ZH (export folder, browse files)

## v0.8.3

### Canvas & Inpainting
- **Fix zoom cursor drift** — remove erroneous double-inversion of Matrix4 transform in `_toNormalized`; Flutter's hit testing already provides coordinates in child-space, so manual inversion was causing cursor/stroke offset proportional to zoom level
- **Fix back button crash** — `_handleBack` used `context.t` (watch) inside async event handler; replaced with `context.tRead` (read) to avoid provider assertion failure

### Prompt Editing
- **Tag weight adjustment** — Ctrl+Up/Down adjusts the weight of the tag under the cursor (e.g. `{tag:1.2}` ↔ `{tag:1.3}`). Works with bare tags, `{tag}` shorthand, and `{tag:weight}` syntax
- **Tag suggestion wrap** — suggestions now display in a wrapped grid layout (max 120px height) instead of a single horizontal scroll row

### Seed Control
- **Optional seed row** — new "Show Seed Control" toggle in app settings. When enabled, a seed input row appears above the prompt with random/fixed toggle and manual seed entry

### Sharing & Export
- **Mobile share sheet** — COPY button on mobile now opens the native share sheet (via `share_plus`) instead of attempting clipboard copy, which was unreliable on Android. Desktop retains clipboard behavior

### Settings Panel
- **Furry mode redesign** — post-processing toggles (SMEA/DYN/CRISP/FURRY) replaced with dedicated FURRY toggle button with icon, separate from sampler controls

### Image Import
- **Persistent category selection** — import metadata dialog remembers which categories you disabled/enabled across sessions (stored in preferences)

### Localization
- All new strings localized for EN, JA, ZH

## v0.8.2

### Style Import
- **Fix style order dependency** — style matching now uses multi-pass detection, so artist styles and quality tags are correctly identified regardless of their ordering in the style list

### Quick Actions
- **Add to Album button** — assign a generated image to an album directly from the generation screen without navigating to the gallery. Auto-saves the image if needed

## v0.8.1

### Network & Reliability
- **API retry with exponential backoff** — all API calls retry up to 3 times on connection/timeout errors with 2s/4s/6s delays. Prevents lost generations when switching apps on mobile
- **Increased connect timeout** — 30s → 60s for better mobile resumption after app switch

### Inpainting
- **Pinch-to-zoom on mobile** — two-finger pinch zooms the canvas, single finger paints. Pointer count tracking distinguishes paint from zoom gestures
- **Cursor position fix** — cursor preview now correctly tracks position when zoomed in (applies inverse zoom transform)

### Clipboard & Export
- **Copy to clipboard** — copy generated images to system clipboard on all platforms (Windows, Linux, macOS, Android, iOS) via `super_clipboard`. Toggleable button in quick action overlay settings
- **Desktop export support** — Export button now works on Windows/Linux/macOS with a save file dialog (was previously Android/iOS only)
- **Desktop auto-export** — auto-export writes to the configured album path or output directory on desktop

### Window Management (Desktop)
- **Save/restore window state** — window size, position, and maximized state persist across sessions via `window_manager`

### Style Import
- **Case-insensitive fuzzy matching** — style prefix/suffix detection now normalizes case, whitespace, and trailing commas. Fixes artist styles not being auto-detected on image import

### Android
- **Media picker shows gallery apps** — uses `FileType.image` so Android shows the gallery picker instead of the document browser. "Browse Files" fallback available in REF shelf for power users needing ZArchiver, FStop, etc.

### Canvas Editor
- **Canvas resize/expand** — new resize dialog with width/height inputs, quick-add buttons (+480px, +256px), and 3x3 anchor grid for positioning existing content. Fully undoable
- **Middle-click pan** — hold middle mouse button to pan the canvas, matching standard image editor behavior

### Cascade
- **Help dialog** — new cascade editor help dialog with beat/timeline documentation

### Jukebox
- **New bundled songs** — added new songs to the jukebox
- **Registry cleanup** — trimmed duplicate/redundant entries to reduce APK size

### Bug Fixes
- **Fix API retry infinite recursion** — `_postWithRetry` called `_dio.post()` correctly instead of itself
- **Fix cascade beat timeline** — beat indicator rendering improvements
- **Fix jukebox style section** — remove reference to non-exported `RepeatMode` symbol
- **Fix falling notes view** — rendering improvements

### Localization
- All new strings localized for EN, JA, ZH

## v0.8.0

### Canvas Editor
- Four new tools: Select (S), Lasso (A), Blur, and Clone Stamp
- Select tool with rectangular selection, corner handles, and rotation handle
- Lasso tool for freehand selection with bounding box handles
- Blur tool with configurable sigma (1.0–30.0)
- Clone stamp tool with Alt+tap source selection and offset tracking
- Zoom/pan system: Space to pan, scroll to zoom (0.25x–16x), Ctrl+Scroll to adjust brush size
- Full keyboard shortcuts for all tools (B/E/G/T/C/V/S/A/L/R/O, [/] for brush size, Ctrl+Z/Y undo/redo, Escape to cancel)
- Smart color palette: auto-extracts dominant colors from source image via k-means clustering in CIE Lab color space
- Quick palette shows up to 10 colors (source image colors first, then defaults); long-press any swatch to replace with current color
- Expanded color picker now has separate "Quick" (customizable) and "Palette" (default) sections with reset button
- Help dialog with keyboard shortcut reference

### Img2Img / Inpainting
- Mask overlay customization: 8-color palette, opacity slider (0.05–1.0), three display patterns (solid, stripe, crosshatch), toggleable border outline
- Expandable settings row in mask toolbar with color/pattern/opacity controls
- Zoom/pan system matching canvas editor (Space to pan, Ctrl+Scroll for brush, scroll to zoom)
- Cursor preview color matches selected mask color

### Layout
- Widescreen sidebar layout with three modes: auto (desktop 1200px+), always, never
- Configurable sidebar width (compact/normal) and prompt position (left/right)
- Settings panel renders inline in sidebar with compact spacing
- SidebarRefVibeRail for compact director/vibe reference display in sidebar mode
- Exit confirmation dialog on back button press (collapses settings first)

### Generation
- Reference inpainting: director references and vibe transfers now apply during img2img/infill generation
- Mobile device gallery export with manual export button in quick action overlay
- Auto-export to device gallery after generation with configurable album name (defaults to "NAIWeaver")
- Wakelock during generation on mobile to prevent network drops
- API connection timeout (30s) and receive timeout (5min)

### Reference System
- REF button split into popup menu: "Load Saved" (bottom sheet of saved references) and "Pick Image" (file picker)
- Loading a saved reference restores original type, strength, and fidelity settings
- Saved director references and vibe transfers included in .vpack export/import
- New `saved_refs/` and `saved_vibes/` directories in pack ZIP format
- Selective import with duplicate detection by name

### Keyboard Shortcuts
- Ctrl+Enter to trigger generation from prompt field
- Ctrl+Left/Right to cycle through styles with snackbar indicator

### Style Editor
- Reset to defaults with confirmation dialog
- Restore icon button in style list header

### Security
- API key backup fallback: base64-encoded backup in SharedPreferences when secure storage fails
- Biometric enrollment check before attempting authentication (prevents failures on devices without enrolled biometrics)

### Performance
- Layer raster caching for image-only layers (skip per-frame stroke re-rendering)
- shouldRepaint optimizations: canvas overlay and mask painters compare by reference instead of always repainting
- RepaintBoundary on source image and layer panel for compositing isolation
- Dominant color extraction runs in background isolate via `compute()` to avoid blocking UI

### Bug Fixes
- Fix gallery image detail view showing grey screen instead of image (Positioned→Align revert) — Closes #4
- Fix pack import on Android and Web (use withData: true and bytes instead of file path) — Closes #3
- Fix Android SAF metadata stripping across file pickers (centralized pickImageFiles() helper)
- Path service validates existing files before re-seeding (prevents overwriting valid data)
- Fix FocusNode memory leaks in canvas and mask keyboard listeners (moved to State fields with proper disposal)
- Fix potential crash from Matrix4 inversion on singular zoom transforms (graceful fallback to identity)

### Other
- Centralized file picker helper (pickImageFiles, pickCustomFiles) for cross-platform compatibility
- wakelock_plus dependency for screen/CPU wake during generation
- App settings UI for layout mode, sidebar width, prompt position, and export preferences

### Localization
- All new strings localized for EN, JA, ZH

## v0.7.1

### Bug Fixes
- Fix versionCode regression that prevented updating from v0.6.x (versionCode was reset from 7 to 1)
- Revert debug builds to use default debug signing key to prevent data wipe on update

## v0.7.0

### Style Import
- Fuzzy matching for external images: auto-detects style presets from composed prompts
- Import dialog shows "(auto-detected from prompt)" for fuzzy-matched styles
- Smart Style Import setting preserved as user opt-out for heuristic matching

### Enhance / Img2Img
- Active styles (prefix/suffix/negative) synced from main editor at generation time
- Characters and interactions synced from main editor at generation time
- `resolveStyles()` extracted as reusable static helper

### Img2Img
- Custom output resolution independent of source image dimensions
- Resolution dropdown with built-in presets, saved custom resolutions, and source reset option
- Resolution persists across source image changes
- Reset button to revert to source dimensions

### Generation
- Duplicate generation detection: warning snackbar when image is byte-identical to previous generation, with "Randomize" action button

### Android
- Add `hasFragileUserData` and `allowBackup` manifest attributes to protect user data on uninstall
- Debug builds now use release signing key (when available) to prevent data loss during development

### Bug Fixes
- Fix infinite loop crash when typing unmatched `}` or `]` in prompt field
- Fix Android generate button not raising above keyboard

### Localization
- All new strings localized for EN, JA, ZH

## v0.6.0

### Prompt Editor
- Syntax highlighting for NAI prompt syntax ({emphasis}, [de-emphasis], N::strength)
- Keyboard tag navigation (Tab/Shift+Tab cycle, Enter accept)
- Tag suggestions work inside strength prefixes (e.g. `2::1gi`)
- Persisted UI toggle states for character editor and style panel

### Gallery
- "Date Added" sort mode (import date vs file modification date)
- Move-to-album option in "Add to album" bottom sheet
- Import-to-editor snackbar shortcut after metadata import
- Better Android image import (FileType.any bypasses SAF transcoding)
- Smarter auto-album assignment (explicit > active > default)
- Image detail header layout fix
- Import metadata dialog shows style embedding hint

### img2img / Inpainting
- Mask save/load (export to PNG, load pre-painted masks)
- Prebaked mask support (loaded masks bypass stroke rendering)
- img2img presets (save/load/delete named settings)
- Auto-sync prompt/UC from main generation editor

### Enhance
- Auto-sync prompt/UC from main generation editor
- Default negative prompt extracted to constant

### ML Hub
- Mobile-only: force NovelAI backend for upscale/BG removal
- Mobile info banner and hidden local ML model cards
- NNAPI skip for upscale to avoid Android crashes

### Style Editor
- PopupMenuButton replaces inline action icons

### Jukebox
- Smooth karaoke syllable animation: gradual color sweep with glow instead of instant color flip
- Next-line countdown progress bar between current and upcoming lyric lines
- Next-line brightness fade (upcoming lyrics brighten in the last 30% of current line)
- Frame-rate accurate lyric rendering via per-line ticker (only active on current line)
- Persistent keyboard volume preference
- Player volume slider in game lobby
- Volume scaling applied to MIDI CC7 events in sequencer
- Increased minimum falling note block height for better visibility
- Fix RepeatMode analyzer warning
- Game button in mobile now-playing bar
- Remove buggy Watch mode

### Slideshow
- Fix context.read after dispose crash

### Tools Hub
- Auto-open tool drawer on mobile

### Localization
- Simplified Chinese (zh) translation — thanks to [@baisumang](https://github.com/baisumang) (PR #2)

### Other
- Snackbar action support with 6s duration

## v0.5.1

### Tag Alias System
- Type in Japanese, Korean, Chinese, or other languages and see alias-matched tag suggestions
- Suggestions display as `alias → english_tag` for clear context
- Aliases auto-inserted into prompt for readability
- Automatic resolution to English Danbooru tags at generation time (prompt, negative prompt, character prompts)
- Weight syntax preserved: `{女の子}` → `{1girl}`
- CJK-aware minimum query length (1 character) across all tag suggestion fields

### Selective Metadata Import
- New import dialog when importing metadata from gallery images
- Choose which categories to import: Prompt, Negative Prompt, Characters, Seed, Styles, Settings
- Unavailable categories auto-detected and greyed out
- Drag-and-drop import unchanged (imports all)

### ML Inference
- Graceful GPU provider fallback (CUDA → DirectML → CPU) when DLLs missing
- TensorRT provider removed (unstable, superseded by CUDA)

### Gallery
- NAI API background removal via image detail view
- Post-processing badge detection (NAI Upscale, Director Tools, Enhanced, BG Removed, Upscaled)

### Tag Database
- High-frequency tag list refreshed with updated counts
- Aliases merged from latest Danbooru export

### Bug Fixes
- Web build: kIsWeb guards in gallery export, image detail, pack manager
- Director Tools keyboard inset no longer pushes editor content
- Mobile layout overflow fixes

### Other
- Easter egg improvements
- Full EN and JA localization for all new features
- debugPrint cleanup (error-path only)
- Code quality: comparison-based shouldRepaint, extracted duplicated helpers

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
