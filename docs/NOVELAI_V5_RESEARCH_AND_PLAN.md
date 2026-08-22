# NovelAI Diffusion V5 — research + integration plan for NAIWeaver

**Date:** 2026-08-21 (V5 shipped the same day)
**Status:** S1–S6 + S8 **implemented** (v0.9.3, 2026-08-21) — see "Implementation status" at the end. This doc remains the spec / source-of-truth for the capability table.
**Sibling:** `D:\bri\docs\image\NOVELAI_V5_RESEARCH_AND_PLAN_2026_08_21.md` (the Python app's
V5 pass, incl. a live Opus smoke run) and `D:\bri\app\image_gen\nai_models.py` (its model registry).

Every claim carries a basis tag:

- `[bundle]` read from NovelAI's own web frontend (`novelai.net/_next/static/chunks/*`,
  fetched 2026-08-21 — `_app-b3011089065336af.js`, `1052-*`, `1741-*`, `7416-*`, `52-*`).
  This is the authoritative source for what NovelAI's UI gates/sends per model.
- `[official]` journal post / docs.novelai.net / subscription page.
- `[bri-smoke]` confirmed against the live API from `D:\bri` with an Opus token on 2026-08-21.
- `[3p]` third-party client updated post-launch (ComfyUI_NAIDGenerator PR #50, caru-ini/novelai-sdk 0.12.0, NAIS3).
- `[UNVERIFIED]` plausible, not confirmed.

---

## 0. TL;DR

- **Four new model ids** `[bundle][bri-smoke]`: `nai-diffusion-5-full`, `nai-diffusion-5-curated`,
  `nai-diffusion-5-full-inpainting`, `nai-diffusion-5-curated-inpainting` (the last one exists in
  the enum but the UI still routes V5 Curated inpaint to `nai-diffusion-4-5-curated-inpainting` `[bundle][official]`).
- **The request body is the V4.5 body.** `v4_prompt` / `v4_negative_prompt` keep their names; `params_version`
  3 still works (`[bri-smoke]`; the frontend now sends 4). Swapping `model` is enough to get a V5 render.
- **What V5 turns OFF** (NovelAI's own capability table, `[bundle]`): Vibe Transfer (`vibetransfer:false`,
  `encodedVibes:false`), Character/Precise Reference (`characterReferences:false`), Variety+
  (`cfgDelay:false`), noise-schedule picker (`noiseSchedule:false` — frontend force-sends `karras`),
  SMEA/SMEA DYN (`smea:false`), Decrisper (`dynamicThresholding:false`), controlnet.
- **What V5 turns ON** `[bundle]`: `transparency` (native RGBA via `straight_alpha` +
  `tag_hint_transparent_background`), `freeformCharacterPosition` (raw x/y, not the 5×5 grid),
  `maxCharacters: 32` (was 6), `canPositionOneCharacter`, `autoText` (quoted text → `Text:` block),
  `maxEnhance` ("Max" enhance via `upscaled_enhance: true`), `opusUsageLimit`.
  CFG Rescale stays available (`cfgRescale:true`).
- **Defaults moved** `[bundle]`: steps **23**, scale **7**, `k_euler_ancestral`, `karras`, `cfg_rescale 0`,
  832×1216. V4.5 defaults in the same table are 23 / 5. Sampler list for V5: Recommended = Euler Ancestral
  only; Other = Euler, DPM++ 2S Ancestral, DPM++ 2M SDE, DPM++ 2M, DPM++ SDE. DDIM is silently remapped
  to Euler Ancestral on V4/V5.
- **Opus is NOT unlimited on V5** `[official][bundle]`: a per-account "usage limit" bar (recharges ~11–14 %/day,
  full from empty ≈ 1 week, ~17.3 images per percent ⇒ ~1,730 renders per full bar). When empty, every V5
  image costs Anlas. V4.5 and older stay unlimited. Readable from
  `GET https://image.novelai.net/user/subscription` → `usage {percent, isNegative, timeUntilNextPercent}`.
- **Not at launch** `[official]`: Vibe Transfer, Precise Reference, V5 Curated inpainting, Potions. NovelAI says
  they are "rolling out following the release" — so the capability layer must be data, not hardcoded.
- **Our app today**: no model enum, no capability layer, model is a single `useCurated` bool in three string
  literals (`lib/core/services/novel_ai_service.dart:115, 326-328`). Everything below is greenfield.

---

## 1. What NovelAI shipped `[official]`

Journal: https://journal.novelai.net/image-generation-novelai-diffusion-v5-is-here-c2df7c6b8d2d/

- V5 Curated + V5 Full, live 2026-08-21. Own architecture, >2× V4.5 size, 268,000 B200 GPU-hours,
  **32-channel VAE** (V4.5: 16). Fine detail (eyes, jewelry, text, accessories) and backgrounds much better.
- Natural-language prompting is the headline; tags fully supported; **longer prompts** (token budget reported
  as 1471 Full / 703 Curated `[3p, UNVERIFIED]`). Official languages EN + JA; zh/de/es/pt "tested, may vary".
- **Characters**: "much higher number of character prompts than V4.5", 22 on screen in testing; **free canvas
  positioning** ("no more tiny grids"), less bleed, better interactions even without positioning.
- **Text rendering** EN/JA/ZH, longer text; the frontend now auto-prepares the `Text:` block when you quote text
  (`"..."` or `「」`); a manual `Text:` block still works and disables the auto path. NL styling of text works.
- **Alpha transparency**: prompt `transparent background` / `has alpha` / `alpha transparency`; tip
  `2.1::transparent background::`. Output is a real RGBA PNG `[bri-smoke]`.
- **Comics/manga**: full multi-panel pages in one generation (describe layout in NL and/or position characters).
- **Enhance "Max✨"**: higher resolution + sharper in one pass; new upscaler also standalone.
- **New tags**: `depthness`, `attractive male`, `low|medium|high|ultra complexity` ("high complexity" for normal
  nice images), `has alpha`, `meta:novel era`, `meta:golden era`, `visual novel art|bg|cg|chibi|sprite`.
- **Inpainting**: V5 Full ships; V5 Curated uses V4.5 Curated inpainting "until it is ready".
- **Not at launch**: Precise Reference, Curated Inpainting, Vibe Transfer (+ Potions per the JP post).
- Subscription note: 31 days after release, unused Subscription Anlas reset to zero when a subscription ends.
- UI overhaul (irrelevant to API): scroll/zoom output viewer, persistent character prompts, naming, positioning
  with grid lines in the output viewer, multi-pin, resizable history, mobile draggable sheet.

---

## 2. API facts (what to actually code against)

### 2.1 Model ids `[bundle][bri-smoke]`

| id | family | notes |
|---|---|---|
| `nai-diffusion-5-full` | v5 | confirmed live: PNG `Source: NovelAI Diffusion V5 0ADF9AB7` |
| `nai-diffusion-5-curated` | v5 | frontend's **default for new users** (`let o="nai-diffusion-5-curated"`) |
| `nai-diffusion-5-full-inpainting` | v5 | exists (400 "doesn't support action generate" on a plain generate) |
| `nai-diffusion-5-curated-inpainting` | v5 | in the enum; UI still maps V5 Curated → `nai-diffusion-4-5-curated-inpainting` |
| `nai-diffusion-4-5-full` / `-curated` / `*-inpainting` | v4 | unchanged |

Frontend migration: V4.5 Full users auto-moved to V5 Full; V4.5 Curated → V5 Curated `[bri doc, bundle]`.

### 2.2 NovelAI's per-model capability table `[bundle]` — the thing to mirror

Verbatim from `_app-*.js` (`function h(e)`), V4.5 vs V5 columns only (custom/local models omitted):

| capability key | V4.5 (full/curated/inpaint) | **V5** (full/curated/inpaint) | meaning for us |
|---|---|---|---|
| `vibetransfer` | true | **false** | hide/grey Vibe Transfer panel + shelf + rail |
| `encodedVibes` | true | **false** | no `/ai/encode-vibe` on V5 (encode with a V4.5 id or disable) |
| `characterReferences` | true | **false** | hide/grey Director Ref (Precise/Character Reference) |
| `charRefInpainting` | true | **false** | — |
| `cfgDelay` (Variety+) | true | **false** | we don't send `skip_cfg_above_sigma` today; never add it for V5 |
| `cfgDelaySigma` | 58 | 58 | — |
| `noiseSchedule` | true | **false** | no picker; frontend force-sends `noise_schedule: "karras"` on V5 |
| `cfgRescale` | true | true | OK to add a CFG-rescale slider for both |
| `smea` / `smeaDyn` | false | false | V4+ never SMEA. **Sending `sm:true` returns HTTP 500 on V4.5 AND V5** `[bri-smoke]` — existing bug surface in our presets |
| `autoSmea` | false | false | — |
| `dynamicThresholding` (Decrisper) | false | **false** | frontend forces `dynamic_thresholding:false` for V4+ |
| `characterPrompts` | true | true | — |
| `maxCharacters` | 6 | **32** | raise our cap per model |
| `canPositionOneCharacter` | false | **true** | position UI allowed with a single character |
| `freeformCharacterPosition` | false | **true** | send raw `{x,y}` (3 dp) instead of snapping to 0.1/0.3/0.5/0.7/0.9 |
| `v4Prompts` | true | true | same `v4_prompt` body |
| `text` | true | true | — |
| `autoText` | false | **true** | quoted text → `Text:` block (frontend convenience; we can replicate) |
| `transparency` | false | **true** | `straight_alpha`, `tag_hint_transparent_background`, RGBA output |
| `maxEnhance` | false | **true** | Enhance "Max" = `upscaled_enhance:true` at source dims |
| `e2eUpscale` | false | false | — |
| `opusUsageLimit` | false | **true** | Opus battery applies |
| `hasFurryMode` | true | true | `fur dataset, ` prefix still the mechanism (same as ours) |
| `img2imgInpainting` | true | true | — |
| `streamedResponses` | true | true | `/ai/generate-image-stream` available |
| `inpainting` | true | true | — |
| `scaleMax` | 10 | 10 | UI max for guidance |
| `numericEmphasis` | true | true | `1.2::tag::` syntax |
| `negativePromptGuidance` | true | true | — |
| `controlnet` | false | false | — |

Noise schedules offered per model (`function g`): **V5 → `[]`** (none), V4/V4.5 → all but `native`.
Sampler groups for the v4/v5 UI group (`1052-*.js`): Recommended `[k_euler_ancestral]`; Other
`[k_euler, k_dpmpp_2s_ancestral, k_dpmpp_2m_sde, k_dpmpp_2m, k_dpmpp_sde]`.

### 2.3 What the frontend does to `parameters` before POST on V5 `[bundle]` (`class tL` sanitizer)

In order:
- `uc` → renamed to `negative_prompt` (our `uc` key also works `[bri-smoke]`).
- `upscale` deleted unless `e2eUpscale` (V5: deleted).
- `uncond_scale === 0` → `1e-5`.
- `!caps.noiseSchedule` → `delete noise_schedule`; then **`v5 → noise_schedule = "karras"`** (re-added).
- `!caps.cfgRescale` → delete `cfg_rescale` (V5 keeps it).
- `!caps.transparency` → delete `straight_alpha`; `tag_hint_transparent_background` kept only if true AND transparency.
- `tag_hint_qt` / `tag_hint_uc_preset` must be numbers or are deleted (pure UI hints).
- `k_euler_ancestral` + non-native schedule → `deliberate_euler_ancestral_bug:false`, `prefer_brownian:true`.
- `!caps.cfgDelay` → delete `skip_cfg_above_sigma` (V5).
- v4/v5 + `ddim` → sampler becomes `k_euler_ancestral`.
- `!caps.smea` → delete `sm`, `sm_dyn` (V4+). `!caps.dynamicThresholding` → `dynamic_thresholding=false`.
- `image_format` = user setting (`png` | `webp`).
- Before that, in the generate path: `straight_alpha = settings.imageStraightAlpha` (default true) when
  `caps.transparency`; img2img source image is flattened onto **transparent** (not white) when transparency is on.

### 2.4 Default params per model `[bundle]` (`function A` in module 41179)

| | V4.5 | **V5** |
|---|---|---|
| params_version | 4 | 4 (3 still accepted `[bri-smoke]`) |
| width × height | 832×1216 | 832×1216 |
| steps | 23 | **23** |
| scale | 5 | **7** |
| sampler | k_euler_ancestral | k_euler_ancestral |
| noise_schedule | karras | karras |
| cfg_rescale | 0 | 0 |
| sm / sm_dyn / dynamic_thresholding | false | false |
| skip_cfg_above_sigma | null | null |
| use_coords / legacy_uc | false | false |
| inpaintImg2ImgStrength | 1 | 1 |
| tag_hint_transparent_background | — | false |

(Our app's `generateImage` defaults are steps 28 / scale 6.0 / `karras` hardcoded — see §4.)

### 2.5 Quality-tag presets per model `[bundle]` (`function f` in 41179)

| model | id | suffix |
|---|---|---|
| **V5 Full / Curated** | `standard` | `very aesthetic, masterpiece, no text` |
| **V5 Full / Curated** | `light` | `very aesthetic, amazing quality, no text` |
| V4.5 Full | `standard` | `very aesthetic, masterpiece, no text` |
| V4.5 Curated | `standard` | `very aesthetic, masterpiece, no text, -0.8::feet::, rating:general` |

With "Transparent BG" on, the frontend prepends `transparent background, ` to the suffix (or uses it alone for `none`).
Note: **no `location` tag** in the V5 suffix (docs listed it for V4.5 Full; the bundle does not).

### 2.6 UC presets for V5 `[bundle]` (module 28811)

| id | string |
|---|---|
| `heavy` | `lowres, artistic error, film grain, scan artifacts, worst quality, bad quality, jpeg artifacts, very displeasing, chromatic aberration, dithering, halftone, screentone, multiple views, logo, too many watermarks, negative space, blank page` (= V4.5 Full heavy) |
| `light` | `lowres, bad hands, bad anatomy, artistic error, sepia, white haze, worst quality, very displeasing, jpeg artifacts, 0::ai-generated::` (**new**) |
| `humanFocus` | heavy + `, @_@, mismatched pupils, glowing eyes, bad anatomy` |
| `furryFocus` | `{worst quality}, distracting watermark, unfinished, bad quality, {widescreen}, upscale, {sequence}, {{grandfathered content}}, blurred foreground, chromatic aberration, sketch, everyone, [sketch background], simple, [flat colors], ych (character), outline, multiple scenes, [[horror (theme)]], comic` |
| `none` | — |

UC preset is a prefix prepended to the user's negative; on V4+ it is applied to the **first `|`-segment** (base) only.
The frontend also prepends `nsfw, ` to the UC when the preset is on, the model isn't a curated id, and the prompt
doesn't already contain "nsfw" (`function o` in 28811) — worth replicating as an option.

### 2.7 Resolution / pixel rules `[bundle]` (module 57863, 81828)

- Presets for the v4/v5 group are **unchanged from V4.5**: Normal 832×1216 / 1216×832 / 1024×1024; Large
  1024×1536 / 1536×1024 / 1472×1472; (+ Wallpaper 1088×1920 / 1920×1088, Small 512×768 / 768×512 / 640×640, Custom).
- Hard cap: **3,145,728 px** (`xM`). Dimension step: **64**. Max steps 50.
- n_samples cap by pixel count: ≤3,145,728 → 4; ≤409,600 → 6; ≤360,448 → 8.
- Enhance scales: `[2, 1.5, 1]` filtered by ≤3,145,728 px and multiple-of-64; 832×1216 → `[1.5, 1]`.
  **"Max"** offered when `caps.maxEnhance && w*h < 2,516,582.4` (0.8 × cap); request keeps source dims and sets
  `upscaled_enhance: true`; result dims are the source scaled to 3,145,728 px.
- Enhance (img2img) **drops the Opus free discount**: the frontend's "free on Opus" check requires no base image.

### 2.8 New / newly relevant request fields `[bundle][bri doc: official swagger]`

| field | type | use |
|---|---|---|
| `straight_alpha` | bool | straight vs premultiplied alpha (frontend default true) — V5 only |
| `tag_hint_transparent_background` | bool | "pure pass-through hint", sent true when Transparent BG toggle is on |
| `tag_hint_qt`, `tag_hint_uc_preset` | int | UI hints (quality-preset id / UC-preset id), optional |
| `upscaled_enhance` | bool | Enhance "Max" |
| `image_format` | `png` \| `webp` | output format |
| `stream` | `msgpack` \| `sse` | for `/ai/generate-image-stream` (per-step intermediates) |
| `negative_prompt` | string | frontend's name for `uc` (both accepted) |
| `use_coords` (in `v4_prompt`) | bool | already sent; **on V5 send raw floats** in `centers` |

Response: zip with `image_0.png`; **RGBA PNG (colour type 6)** when alpha requested `[bri-smoke]`.
PNG `tEXt` Comment carries the full params incl. `model_name: "NovelAI Diffusion V5"` — our metadata importer
should start reading `model`.

### 2.9 Usage limit (Opus battery) + cost `[official][bundle][bri-smoke]`

- `GET https://image.novelai.net/user/subscription` (bearer) → `{tier, active, trainingStepsLeft{fixedTrainingStepsLeft, purchasedTrainingSteps}, usage?}`;
  `usage = {percent: 0-100, isNegative: bool, timeUntilNextPercent: seconds}`; **absent below Opus (tier 3)**.
  `[bri-smoke]`: `api.novelai.net/user/subscription` returned 400 "update to the image URL" — our
  `getAnlasBalance()` uses `api.novelai.net`; **verify** and move to `image.novelai.net`.
- Frontend helpers (`52-*.js`): images ≈ `Math.round(17.3 * percent)`; recharge `%/day = 86400 / timeUntilNextPercent`
  (rounded to 0.1); "low" = `isNegative || percent < 5`; remaining clamps to 0 when `isNegative`.
  Measured 2026-08-21: `timeUntilNextPercent 7888` ⇒ 10.95 %/day ≈ 190 images/day `[bri-smoke]`.
- UI strings `[bundle]`: "Your Opus subscription includes free NovelAI Diffusion V5 generations at normal resolutions
  and up to 28 steps. This allowance is limited and refills automatically over time. When it runs out, you can still
  generate images by spending Anlas." / "[0]% remaining (~[1] images)" / "Currently refills at [0]% per day (~[1] images)."
  / setting "Always Show Usage Limit Bar".
- Free-on-Opus rule (docs): one image at a time, no base image, ≥ "Normal" size (≤ 1024×1024 px), steps ≤ 28.
  V4.5-and-lower: free. **V5: draws from the battery; when `isNegative`/0 every image costs Anlas**, and the
  batch "first image free" discount is dropped while `usage.isNegative` `[bundle]`.
- Observed Anlas when paying for V5 (day-one community measurements, `[3p]`): ~11 small / ~26 normal / ~39 large
  per image (note.com, tank_ai); bri doc estimates ~17 @ 832×1216/23 steps, ~20 @ 28 via the novelai-sdk formula.
  Tablet/Scroll get 1,000 Anlas/month ⇒ ~40–60 V5 images/month; Opus 10,000.

### 2.10 Things the bundle confirms are NOT V5-specific but bite us
- `sm:true` / `sm_dyn:true` → **HTTP 500 on V4.5 too** `[bri-smoke]`. Our presets can set these
  (`lib/core/services/presets.dart:17-18`, `generation_notifier.dart:82-83`). Strip for any V4+ model.
- `params_version` in the frontend is now 4 for every model; we send 3. Works, but move to 4 when touching the builder.

---

## 3. Source confidence

| claim | basis |
|---|---|
| model ids, inpaint ids, capability table, defaults, presets, sanitizer, pixel rules, sampler lists | `[bundle]` — read directly from NovelAI's JS; V5 Full id + inpaint id + alpha + coords + usage endpoint additionally `[bri-smoke]` |
| features missing at launch | `[official]` journal + JP post |
| battery semantics | `[official]` docs/subscription + bundle strings; rates `[bri-smoke]`/`[3p]` |
| token limits 1471/703, maxCharacters 32 in practice, Anlas per V5 image | `[3p]` / `[UNVERIFIED]` |
| V5 Curated inpaint id being live | `[UNVERIFIED]` (enum exists, UI doesn't use it) |

Docs.novelai.net had **no** V5 pages as of today (models/quality/UC/multi-character/text pages unchanged).

---

## 4. Where our app touches the model today (seam map)

From the repo survey (file:line):

- **Model literals** — `lib/core/services/novel_ai_service.dart:115` (vibe encode) and `:326-328` (generate /
  img2img / infill) — `useCurated ? "nai-diffusion-4-5-curated" : "nai-diffusion-4-5-full"` (+ `-inpainting`).
  Class doc `:29` says "(V4.5)".
- **Body builder** `novel_ai_service.dart:175-331` `generateImage(...)`: hardcoded `params_version: 3` (`:246`),
  `noise_schedule: "karras"` (`:254`), `sm`/`sm_dyn`/`dynamic_thresholding` always sent, `v4_prompt` +
  `characterPrompts` + `v4_negative_prompt` unconditional (`:259-288`), `use_coords: useCoords ?? isMultiCharacter`,
  director-ref arrays (`:304-312`), vibe arrays (`:313-321`). Not sent: `cfg_rescale`, `skip_cfg_above_sigma`,
  `straight_alpha`, `tag_hint_*`, `image_format`, `upscaled_enhance`. `img2imgColorCorrect` param is dead.
- **Call sites** passing `useCurated`: `generation_notifier.dart:1008/1462/1514/1569`; **`enhance_notifier.dart:127`
  does NOT** (always Full — existing gap).
- **Vibe encode** `novel_ai_service.dart:107-144`; **augment** `:388-439` (no model field); **upscale** `:445-501`.
- **Settings UI** `lib/features/generation/widgets/settings_panel.dart`: CURATED toggle `:563-598` is the whole
  model UI; FURRY toggle `:526-561` = `fur dataset, ` prefix (`generation_notifier.dart:928-930`); sampler list
  `:94-100` (5 samplers); resolution presets `:26-92`; steps/scale `:474-495`; section order `:303-312`
  (`dimensions_seed, steps_scale, sampler_post, characters, styles, negative_prompt, presets, save_to_album`).
  No noise-schedule, CFG-rescale, variety, decrisper, quality-toggle or UC-preset UI; SMEA/decrisper only in
  `lib/features/tools/widgets/preset_manager.dart:490-492`.
- **Panels to gate**: vibe (`lib/features/vibe_transfer/widgets/*`, `generation/widgets/vibe_transfer_shelf.dart`,
  `sidebar_ref_vibe_rail.dart`), director ref (`lib/features/director_ref/widgets/*`), characters
  (`inline_character_editor.dart`, `character_editor_sheet.dart`, `nai_grid_selector.dart` — the 5×5 grid),
  director tools (`lib/features/tools/director_tools/*`, model-agnostic), img2img/inpaint
  (`lib/features/tools/img2img/*`), enhance (`lib/features/tools/enhance/*`).
- **Persistence**: `PreferencesService` `_keyUseCurated='use_curated'` (`preferences_service.dart:38, 291-295`,
  exportable at `:578`); session snapshot `session_snapshot_service.dart:25-26, 72-73, 119-120`; presets
  `lib/core/services/presets.dart` (sampler/smea/smeaDyn/decrisper, **no model**); PNG import
  `metadata_import_service.dart:230-233` (**no model**).
- **Anlas**: `getAnlasBalance()` `novel_ai_service.dart:148-169` hits `api.novelai.net/user/subscription`, sums
  `trainingStepsLeft`; shown in `lib/main.dart:710-731`; no per-image cost estimate anywhere.
- **Capabilities abstraction**: none. Nearest pattern: `lib/features/tools/director_tools/models/augment_tool.dart:16-17`
  (`hasDefry`/`hasPrompt` getters on an enum).
- **Tests**: nothing covers model selection or the request body. `test/exportable_settings_test.dart` covers
  `furry_mode` only; `test/text_gen_params_test.dart` is the closest template.
- **Docs to update**: `API_DOCUMENTATION.md` ("V4.5", lines 17/107/168/206/275), `ARCHITECTURE.md:344`,
  `ROADMAP.md:142`, `FEATURES.md`, `README.md`.

---

## 5. Plan

Build order: **S1 → S2 → S3** ship together (model picker + gating + usage awareness is the minimum safe V5
release); S4–S6 are the V5-native wins; S7–S8 when convenient. Keep V4.5 behaviour byte-identical for existing users.

### S1. `NaiModel` enum + capability layer (the chokepoint)

New `lib/core/models/nai_model.dart` (pure, no Flutter imports):

```dart
enum NaiModel { v5Full, v5Curated, v45Full, v45Curated }

extension NaiModelX on NaiModel {
  String get id;                 // 'nai-diffusion-5-full' …
  String get inpaintingId;       // v5Curated → 'nai-diffusion-4-5-curated-inpainting' (launch mapping), flag to flip later
  String get label;              // 'V5 Full' …
  bool get isV5;
  bool get isCurated;
  bool get opusUnlimited;        // v4.5 true, v5 false
  NaiCaps get caps;              // mirrors §2.2
  NaiDefaults get defaults;      // steps 23, scale 7.0 (v5) / 23, 5.0 (v4.5) — see note below
  List<String> get samplers;     // v4/v5 group list from §2.2
  List<String> get noiseSchedules;   // v5: []
  List<QualityPreset> get qualityPresets;
  List<UcPreset> get ucPresets;
  int get maxCharacters;         // 6 / 32
  static NaiModel fromId(String id) // tolerant: regex on '-5-' / '-4-5-', unknown → v45Full
}
```

`NaiCaps` = `{vibeTransfer, characterReference, varietyPlus, noiseSchedule, cfgRescale, smea, decrisper,
transparency, freeformPosition, canPositionOneCharacter, autoText, maxEnhance, opusUsageLimit, inpainting}` — data,
so "Vibe Transfer lands on V5 next month" is a one-line change (or a remote-config override later).

Thread `NaiModel model` through `NovelAIService.generateImage` / `encodeVibeImage` (replace `useCurated`) and the
five call sites (fix the missing flag at `enhance_notifier.dart:127` while there). `generateImage` becomes the
sanitizer from §2.3: drop `sm/sm_dyn` for V4+ (fixes the 500), force `noise_schedule: karras` + drop it from UI
for V5, only emit `straight_alpha`/`tag_hint_transparent_background` when `caps.transparency`, `params_version: 4`.

**Defaults note:** the official V5 defaults are 23 / 7.0. Our current defaults are 28 / 6.0 for everything.
Apply per-model defaults only to *new* state and to a "Reset to model defaults" action — never silently rewrite a
user's tuned steps/scale on model switch.

### S2. Model picker + gating (replace the CURATED toggle)

- New `model` section in `settings_panel.dart` (add id to `sectionOrder` defaults): a segmented picker
  **V5 Full · V5 Curated · V4.5 Full · V4.5 Curated** (+ a one-line caps hint: "V5: no Vibe Transfer / Character
  Reference yet · counts against Opus usage limit"). Keep FURRY as-is (still a prefix on V5).
- Gating matrix (greyed with a tooltip, not hidden, so users learn why):

| control | V5 | V4.5 |
|---|---|---|
| Vibe Transfer panel / shelf / rail / "add vibe" | **disabled** ("Not available on V5 yet") | on |
| Director Ref (character reference) panel / shelf | **disabled** | on |
| Noise schedule (if we add it) | hidden | on (no `native`) |
| SMEA / SMEA DYN (preset manager) | hidden for all V4+ | hidden |
| Decrisper (preset manager) | hidden for all V4+ | hidden |
| Variety+ (if we add it) | hidden | on |
| CFG Rescale (new slider, optional) | on | on |
| Sampler list | §2.2 v4/v5 list, Euler Ancestral marked recommended | same |
| Character grid selector (`nai_grid_selector.dart`) | **free drag x/y** (3 dp) | 5×5 grid |
| Character count cap | 32 | 6 |
| Position with 1 character | allowed | not allowed |
| Transparent BG toggle | shown | hidden |
| Enhance "Max" option | shown when `w*h < 2,516,582` | hidden |
| Inpaint model | `…-5-full-inpainting` / `…-4-5-curated-inpainting` | as today |
| Anlas/usage chip | battery + "costs Anlas when empty" | "free on Opus" rule |

- Persisted as `nai_model` (string id) in `PreferencesService` (+ exportable allowlist), `SessionSnapshot`
  (migrate `use_curated:true` → `v45Curated`, false → `v45Full`; **do not auto-migrate to V5** — user opts in),
  `GenerationPreset.model` (nullable → "preset doesn't pin a model"), and PNG import reads `model` from the
  Comment JSON (`metadata_import_service.dart`) behind an `ImportCategory`.
- When the user switches to V5 with vibes/director refs enabled: keep the data, show a banner "N vibe(s) will be
  ignored on V5", and **do not send** the arrays (sending `reference_image_multiple` on V5 is `[UNVERIFIED]`).

### S3. Usage-limit + Anlas awareness

- `getAnlasBalance()` → `getSubscription()` against `https://image.novelai.net/user/subscription`; parse
  `usage` (nullable). New state: `anlas`, `usage{percent, isNegative, secondsPerPercent}`, derived `imagesLeft ≈ 17.3·%`,
  `pctPerDay = 86400/secondsPerPercent`.
- Top bar (`main.dart:710-731`): when model is V5 and tier==3 show a small battery bar + "~N imgs"; when
  `isNegative || percent<5` turn warning colour; tap → tooltip with refill rate. Non-Opus on V5: "V5 costs Anlas".
- Pre-flight estimate on the Generate button (new): reuse the free-on-Opus rule (1 image, no base image,
  ≤1024×1024, ≤28 steps) × model (`opusUnlimited` / battery) — exact Anlas formula is `[UNVERIFIED]` for us;
  ship "free" / "uses V5 allowance" / "costs Anlas" labels first, numbers later.
- Refetch after each generation (already done) so the bar ticks.
- Optional policy setting (mirrors bri): *When V5 allowance is empty:* `keep going (spend Anlas)` (default, matches
  NovelAI) / `warn before generating` / `fall back to V4.5 Full`.

### S4. Native transparency (V5 only)

- "Transparent BG" toggle in the model section (V5 only): appends `transparent background` to the quality suffix
  exactly like NovelAI (§2.5), sends `straight_alpha: true` + `tag_hint_transparent_background: true`.
- Gallery/save path must preserve RGBA (check `_looksLikeImage` + PNG writer + thumbnailer + share/export — our
  metadata-injecting PNG rewrite must not flatten). Show a checkerboard behind transparent images in the viewer.
- img2img/inpaint with transparency on: flatten source onto transparent, not white (`[bundle]` behaviour).
- Director-tool "Remove Background" becomes less necessary on V5; leave it.

### S5. Character positioning on V5

- `nai_grid_selector.dart`: on V5 render a free-drag canvas (aspect-matched to the current resolution) and store
  `{x,y}` rounded to 3 dp; on V4.5 keep snapping to the grid. Allow positioning with one character on V5.
- Cap character cards at `model.maxCharacters` (32 on V5) with a toast when trimmed.
- `use_coords` semantics unchanged (true when any position set; "AI's choice" = false).

### S6. Prompt features: auto-Text, new tags, presets

- `autoText` (V5): if the base prompt contains a quoted string (`"…"` or `「…」`) and no `Text:` block, append
  `\nText: <quoted>` at the very end (frontend convenience; replicate in the prompt pre-processor, off for V4.5).
- Tag DB: add `depthness`, `attractive male`, `low/medium/high/ultra complexity`, `has alpha`, `alpha transparency`,
  `transparent background`, `meta:novel era`, `meta:golden era`, `visual novel art|bg|cg|chibi|sprite` to autocomplete
  (flag as V5).
- Styles: add the V5 `light` quality preset (`very aesthetic, amazing quality, no text`) and the V5 UC presets
  (§2.6) as selectable defaults; keep user strings untouched.
- Default negative prompt constant (`generation_notifier.dart:294`) — offer V5 Heavy as a one-tap preset.

### S7. Later: Enhance "Max", streaming, webp

- Enhance panel: add "Max" when `caps.maxEnhance && w*h < 2,516,582` → `upscaled_enhance: true` at source dims
  (result ≈ 3.1 MP). Whether it draws battery or Anlas is `[UNVERIFIED]`.
- `/ai/generate-image-stream` (`stream: "sse"`) for a live preview — nice-to-have.
- `image_format: webp` — skip (metadata/alpha pipeline assumes PNG).

### S8. Tests + docs

- `test/nai_model_test.dart`: id round-trip, caps per model, inpaint id mapping, `fromId` tolerance.
- `test/novel_ai_request_builder_test.dart` (new — there is none today): V4.5 body unchanged byte-for-byte; V5 body
  drops `sm/sm_dyn`, forces `karras`, emits alpha fields only when asked, drops vibe/director arrays, raw coords.
- `test/exportable_settings_test.dart`: add `nai_model` round-trip; session-snapshot migration test.
- Update `API_DOCUMENTATION.md`, `ARCHITECTURE.md`, `README.md`, `FEATURES.md`, CHANGELOG (v0.9.3).

---

## 6. Open / verify before shipping

1. `api.novelai.net/user/subscription` vs `image.novelai.net` — bri saw a 400 on the former; confirm which our
   Anlas fetch should use (and that `usage` only comes from `image.`).
2. Does V5 **reject** or ignore `reference_image_multiple*` / `director_reference_*`? (we plan to not send them either way)
3. `nai-diffusion-5-curated-inpainting` — live yet? (UI still maps to V4.5 Curated inpaint.)
4. Exact Anlas per V5 image when paying (formula vs the day-one 11/26/39 observations).
5. Whether Enhance / upscale draw from the battery.
6. V5 Curated `rating:general` behaviour / whether a Curated quality suffix differs (bundle says same as Full).
7. Token budget (1471/703) for our token counter.

---

## 7. Sources

Official: journal post (EN) https://journal.novelai.net/image-generation-novelai-diffusion-v5-is-here-c2df7c6b8d2d/ ·
JP post https://blognew.novelai.net/novelai-diffusion-v5-release-jp-343211a45664/ ·
subscription docs https://docs.novelai.net/en/subscription/ · frontend bundle `novelai.net/image` → `/_next/static/chunks/*` (2026-08-21).
Third-party: ComfyUI_NAIDGenerator PR #50 (2026-08-21) · `D:\bri` research doc + live smoke (§10 there) ·
note.com day-one reports (itsuki_ailab, tank_ai, aiillust000).

---

## 8. Implementation status (v0.9.3, 2026-08-21)

| step | status | where |
|---|---|---|
| S1 `NaiModel` + caps + sanitising builder | **done** | `lib/core/models/nai_model.dart`, `lib/core/services/nai_request_builder.dart`, `NovelAIService.generateImage(model:)` / `encodeVibeImage(model:)`; `enhance_notifier` now passes the model |
| S2 picker + gating + persistence | **done** | `settings_panel.dart` MODEL section (first section; `theme_notifier` inserts it at the top for saved orders); `ModelGate` / `ModelGateBanner` on vibe/director shelves, rail, managers; `nai_model` pref (+ `use_curated` migration, exportable), `SessionSnapshot.model`, `GenerationPreset.model` (nullable), PNG `model` written + imported under the settings category |
| S3 usage + Anlas | **done** (labels, no Anlas numbers) | `getSubscription()` on `image.novelai.net` with legacy fallback; `NaiUsage` / `NaiSubscription` / `estimateCostKind`; Anlas chip battery; pre-flight FREE / V5 ALLOWANCE / COSTS ANLAS label. The "when empty" policy setting is **not** built (NovelAI default = keep going). |
| S4 transparency | **done** (viewer + request); img2img source flatten-onto-transparent **not** done | TRANSPARENT BG toggle, `straight_alpha` + tag hint, `pngHasAlpha` + `CheckerboardPainter` in the viewer. Save path already injects metadata without re-encoding, so RGBA survives. |
| S5 positioning | **done** | `NaiGridSelector(freeform:, aspectRatio:)` — free-drag on V5 (3 dp), grid on V4.5; cap 32/6 with an "only the first N are sent" note (no destructive trimming) |
| S6 prompt features | **done** | `applyAutoText` (V5 only), V5 tags merged into autocomplete (`TagService.naiV5Tags`), V5 quality/UC styles in `prompt_styles.json`; `k_dpmpp_2m_sde` sampler |
| S7 Enhance Max / streaming / webp | **deferred** | helper `naiMaxEnhanceAvailable` exists; no UI |
| S8 tests + docs | **done** | `test/nai_model_test.dart`, `test/nai_request_builder_test.dart`, `test/nai_v5_persistence_test.dart` (51 tests); README / FEATURES / ARCHITECTURE / API_DOCUMENTATION / CHANGELOG |

Decisions taken where the plan left room:
- `params_version`: 3 for V4.5 (byte-identical bodies), 4 for V5 (what the frontend sends).
- `deliberate_euler_ancestral_bug:false` + `prefer_brownian:true` are sent on V5 only (frontend parity for the new model; V4.5 untouched).
- `straight_alpha` is only sent when the Transparent BG toggle is on (conservative; the frontend sends it on every V5 request).
- Over-cap characters are not trimmed on a model switch — the builder sends the first N and the editor says so.
- Open items in §6 remain open (Anlas-per-image numbers, Enhance battery draw, V5 Curated inpaint id).
