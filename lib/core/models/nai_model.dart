/// NovelAI image-model registry + per-model capability table.
///
/// Pure Dart (no Flutter imports) so it can be unit-tested and reused by the
/// request builder, the UI gating and persistence. Everything in here mirrors
/// NovelAI's own frontend capability table as read on 2026-08-21 (see
/// `docs/NOVELAI_V5_RESEARCH_AND_PLAN.md` §2.2) — it is **data**, so when
/// NovelAI turns a feature on for V5 ("Vibe Transfer rolling out following the
/// release") it is a one-line change here and nothing else moves.
library;

/// Per-model feature switches. `true` means the request field / UI control is
/// allowed for that model; the request builder strips anything the model does
/// not support so a stale preset can never produce a 400/500.
class NaiCaps {
  /// Vibe Transfer (`reference_image_multiple*`).
  final bool vibeTransfer;

  /// `/ai/encode-vibe` accepts this model id.
  final bool encodedVibes;

  /// Director / Precise / Character Reference (`director_reference_*`).
  final bool characterReference;

  /// Variety+ (`skip_cfg_above_sigma`).
  final bool varietyPlus;

  /// Noise-schedule picker. When false the frontend force-sends `karras`.
  final bool noiseSchedule;

  /// `cfg_rescale` is honoured.
  final bool cfgRescale;

  /// SMEA / SMEA DYN (`sm`, `sm_dyn`). False on every V4+ model — sending
  /// `sm:true` returns HTTP 500 on V4.5 *and* V5.
  final bool smea;

  /// Decrisper (`dynamic_thresholding`).
  final bool decrisper;

  /// Native RGBA output (`straight_alpha`, `tag_hint_transparent_background`).
  final bool transparency;

  /// Character centers may be arbitrary `{x,y}` instead of the 5×5 grid.
  final bool freeformPosition;

  /// Positioning UI is allowed with a single character.
  final bool canPositionOneCharacter;

  /// Quoted text in the prompt is auto-promoted to a `Text:` block.
  final bool autoText;

  /// Enhance "Max" (`upscaled_enhance: true`).
  final bool maxEnhance;

  /// Opus "usage limit" battery applies (free renders are metered).
  final bool opusUsageLimit;

  /// Inpainting is available (via [NaiModel.inpaintingId]).
  final bool inpainting;

  /// Maximum number of character prompts per generation.
  final int maxCharacters;

  const NaiCaps({
    required this.vibeTransfer,
    required this.encodedVibes,
    required this.characterReference,
    required this.varietyPlus,
    required this.noiseSchedule,
    required this.cfgRescale,
    required this.smea,
    required this.decrisper,
    required this.transparency,
    required this.freeformPosition,
    required this.canPositionOneCharacter,
    required this.autoText,
    required this.maxEnhance,
    required this.opusUsageLimit,
    required this.inpainting,
    required this.maxCharacters,
  });

  /// NovelAI Diffusion V4.5 (Full / Curated).
  static const v45 = NaiCaps(
    vibeTransfer: true,
    encodedVibes: true,
    characterReference: true,
    varietyPlus: true,
    noiseSchedule: true,
    cfgRescale: true,
    smea: false,
    decrisper: false,
    transparency: false,
    freeformPosition: false,
    canPositionOneCharacter: false,
    autoText: false,
    maxEnhance: false,
    opusUsageLimit: false,
    inpainting: true,
    maxCharacters: 6,
  );

  /// NovelAI Diffusion V5 (Full / Curated) — launch-day table.
  static const v5 = NaiCaps(
    vibeTransfer: false,
    encodedVibes: false,
    characterReference: false,
    varietyPlus: false,
    noiseSchedule: false,
    cfgRescale: true,
    smea: false,
    decrisper: false,
    transparency: true,
    freeformPosition: true,
    canPositionOneCharacter: true,
    autoText: true,
    maxEnhance: true,
    opusUsageLimit: true,
    inpainting: true,
    maxCharacters: 32,
  );
}

/// NovelAI's own default generation parameters per model.
class NaiModelDefaults {
  final int steps;
  final double scale;
  final String sampler;
  final String noiseSchedule;
  final double cfgRescale;
  final int width;
  final int height;

  /// `params_version` the request builder sends. V4.5 keeps the value this
  /// app has always sent (3) so existing renders stay byte-identical; V5 uses
  /// 4, which is what NovelAI's frontend sends for V5.
  final int paramsVersion;

  const NaiModelDefaults({
    required this.steps,
    required this.scale,
    required this.sampler,
    required this.noiseSchedule,
    required this.cfgRescale,
    required this.width,
    required this.height,
    required this.paramsVersion,
  });

  static const v45 = NaiModelDefaults(
    steps: 23,
    scale: 5.0,
    sampler: 'k_euler_ancestral',
    noiseSchedule: 'karras',
    cfgRescale: 0,
    width: 832,
    height: 1216,
    paramsVersion: 3,
  );

  static const v5 = NaiModelDefaults(
    steps: 23,
    scale: 7.0,
    sampler: 'k_euler_ancestral',
    noiseSchedule: 'karras',
    cfgRescale: 0,
    width: 832,
    height: 1216,
    paramsVersion: 4,
  );
}

/// A quality-tag preset (appended to the positive prompt).
class NaiQualityPreset {
  final String id;
  final String label;
  final String suffix;
  const NaiQualityPreset(this.id, this.label, this.suffix);
}

/// An undesired-content preset (prepended to the negative prompt).
class NaiUcPreset {
  final String id;
  final String label;
  final String text;
  const NaiUcPreset(this.id, this.label, this.text);
}

/// The image models this app can drive.
enum NaiModel {
  v5Full(
    id: 'nai-diffusion-5-full',
    inpaintingId: 'nai-diffusion-5-full-inpainting',
    label: 'V5 Full',
    shortLabel: 'V5',
    isV5: true,
    isCurated: false,
  ),
  v5Curated(
    id: 'nai-diffusion-5-curated',
    // NovelAI's own UI still routes V5 Curated inpainting to the V4.5 Curated
    // inpainting model ("until it is ready"). Flip to
    // 'nai-diffusion-5-curated-inpainting' once it goes live.
    inpaintingId: 'nai-diffusion-4-5-curated-inpainting',
    label: 'V5 Curated',
    shortLabel: 'V5C',
    isV5: true,
    isCurated: true,
  ),
  v45Full(
    id: 'nai-diffusion-4-5-full',
    inpaintingId: 'nai-diffusion-4-5-full-inpainting',
    label: 'V4.5 Full',
    shortLabel: 'V4.5',
    isV5: false,
    isCurated: false,
  ),
  v45Curated(
    id: 'nai-diffusion-4-5-curated',
    inpaintingId: 'nai-diffusion-4-5-curated-inpainting',
    label: 'V4.5 Curated',
    shortLabel: 'V4.5C',
    isV5: false,
    isCurated: true,
  );

  const NaiModel({
    required this.id,
    required this.inpaintingId,
    required this.label,
    required this.shortLabel,
    required this.isV5,
    required this.isCurated,
  });

  /// Wire id for `generate` / `img2img`.
  final String id;

  /// Wire id for `infill`.
  final String inpaintingId;

  /// Human label ("V5 Full").
  final String label;

  /// Compact label for chips ("V5C").
  final String shortLabel;

  final bool isV5;
  final bool isCurated;

  /// The model used by [Defaults] and by the app when nothing is stored.
  /// Deliberately V4.5 Full — existing users are **not** auto-migrated to V5
  /// (it is metered on Opus); they opt in via the picker.
  static const NaiModel fallback = NaiModel.v45Full;

  NaiCaps get caps => isV5 ? NaiCaps.v5 : NaiCaps.v45;
  NaiModelDefaults get defaults => isV5 ? NaiModelDefaults.v5 : NaiModelDefaults.v45;

  /// V4.5 and older render free on Opus; V5 draws from the usage battery.
  bool get opusUnlimited => !isV5;

  int get maxCharacters => caps.maxCharacters;

  /// The model whose capability table shapes the request body for [action].
  ///
  /// Normally `this` — but V5 Curated routes inpainting to the V4.5 Curated
  /// wire model (see [inpaintingId]), and the body must be shaped for the
  /// model actually hit: a V5-shaped block (params_version, no sm/sm_dyn,
  /// prefer_brownian, straight_alpha) sent to a V4.5 endpoint risks the same
  /// HTTP 500 strictness that `sm: true` already triggers on V4+. Collapses
  /// back to `this` automatically once the V5 Curated inpainting id ships.
  NaiModel bodyModelFor(String action) {
    if (action != 'infill') return this;
    if (isV5 && inpaintingId == NaiModel.v45Curated.inpaintingId) {
      return NaiModel.v45Curated;
    }
    return this;
  }

  /// Model id to use for `/ai/encode-vibe`. V5 does not accept vibes at all,
  /// so encode against the matching V4.5 id — the vibe library stays usable
  /// when the user switches back.
  String get vibeEncodeId => switch (this) {
        NaiModel.v5Full => NaiModel.v45Full.id,
        NaiModel.v5Curated => NaiModel.v45Curated.id,
        _ => id,
      };

  /// Samplers NovelAI's UI offers for the V4/V5 group, recommended first.
  List<String> get samplers => const [
        'k_euler_ancestral',
        'k_euler',
        'k_dpmpp_2s_ancestral',
        'k_dpmpp_2m_sde',
        'k_dpmpp_2m',
        'k_dpmpp_sde',
      ];

  /// Noise schedules the UI may offer. V5: none (karras is forced).
  List<String> get noiseSchedules => isV5
      ? const []
      : const ['karras', 'exponential', 'polyexponential'];

  List<NaiQualityPreset> get qualityPresets => isV5
      ? const [
          NaiQualityPreset('standard', 'Standard',
              'very aesthetic, masterpiece, no text'),
          NaiQualityPreset('light', 'Light',
              'very aesthetic, amazing quality, no text'),
        ]
      : isCurated
          ? const [
              NaiQualityPreset('standard', 'Standard',
                  'very aesthetic, masterpiece, no text, -0.8::feet::, rating:general'),
            ]
          : const [
              NaiQualityPreset('standard', 'Standard',
                  'very aesthetic, masterpiece, no text'),
            ];

  List<NaiUcPreset> get ucPresets => const [
        NaiUcPreset('heavy', 'Heavy', ucHeavy),
        NaiUcPreset('light', 'Light', ucLight),
        NaiUcPreset('humanFocus', 'Human Focus', ucHumanFocus),
        NaiUcPreset('furryFocus', 'Furry Focus', ucFurryFocus),
      ];

  static const String ucHeavy =
      'lowres, artistic error, film grain, scan artifacts, worst quality, bad quality, jpeg artifacts, very displeasing, chromatic aberration, dithering, halftone, screentone, multiple views, logo, too many watermarks, negative space, blank page';
  static const String ucLight =
      'lowres, bad hands, bad anatomy, artistic error, sepia, white haze, worst quality, very displeasing, jpeg artifacts, 0::ai-generated::';
  static const String ucHumanFocus =
      '$ucHeavy, @_@, mismatched pupils, glowing eyes, bad anatomy';
  static const String ucFurryFocus =
      '{worst quality}, distracting watermark, unfinished, bad quality, {widescreen}, upscale, {sequence}, {{grandfathered content}}, blurred foreground, chromatic aberration, sketch, everyone, [sketch background], simple, [flat colors], ych (character), outline, multiple scenes, [[horror (theme)]], comic';

  /// One-line capability hint shown under the model picker.
  String get capsHint => isV5
      ? 'V5: no Vibe Transfer / Character Reference yet · free positioning · '
          '32 characters · alpha · counts against the Opus usage limit'
      : 'V4.5: Vibe Transfer + Character Reference · 5×5 grid · 6 characters · '
          'free on Opus';

  /// Tolerant parser for a stored/imported model id.
  ///
  /// Exact ids win; otherwise the string is sniffed for a version marker
  /// (`-5-` / `-4-5-`) and `curated`. Returns null when nothing matches so
  /// callers can keep the current model instead of silently switching.
  static NaiModel? tryParse(String? raw) {
    if (raw == null) return null;
    final s = raw.trim().toLowerCase();
    if (s.isEmpty) return null;
    for (final m in NaiModel.values) {
      if (m.id == s || m.name.toLowerCase() == s) return m;
    }
    final curated = s.contains('curated');
    // Check the V4.5 marker first: "4-5-" also contains "-5-".
    if (s.contains('4-5') || s.contains('4.5')) {
      return curated ? NaiModel.v45Curated : NaiModel.v45Full;
    }
    if (s.contains('diffusion-5') ||
        s.contains('-5-') ||
        RegExp(r'\bv5\b').hasMatch(s)) {
      return curated ? NaiModel.v5Curated : NaiModel.v5Full;
    }
    return null;
  }

  /// [tryParse] with a fallback (V4.5 Full) for unknown input.
  static NaiModel fromId(String? raw) => tryParse(raw) ?? fallback;

  /// Migrates the pre-V5 `use_curated` boolean.
  static NaiModel fromLegacyCurated(bool useCurated) =>
      useCurated ? NaiModel.v45Curated : NaiModel.v45Full;
}

/// The Opus "usage limit" battery for V5 (absent below Opus).
class NaiUsage {
  /// 0–100.
  final double percent;

  /// The account has dipped below zero; every V5 image now costs Anlas.
  final bool isNegative;

  /// Seconds until the next +1 %.
  final int secondsPerPercent;

  const NaiUsage({
    required this.percent,
    required this.isNegative,
    required this.secondsPerPercent,
  });

  /// NovelAI's own helper: ≈17.3 images per percent.
  static const double imagesPerPercent = 17.3;

  /// Remaining percent, clamped to 0 when negative.
  double get remainingPercent => isNegative ? 0 : percent.clamp(0, 100).toDouble();

  /// Approximate free V5 images left (`Math.round(17.3 * percent)`).
  int get imagesLeft => (imagesPerPercent * remainingPercent).round();

  /// Recharge rate in %/day, rounded to 0.1 (`86400 / timeUntilNextPercent`).
  double get percentPerDay {
    if (secondsPerPercent <= 0) return 0;
    return ((86400 / secondsPerPercent) * 10).round() / 10;
  }

  /// Approximate images recharged per day.
  int get imagesPerDay => (imagesPerPercent * percentPerDay).round();

  /// NovelAI's "low" threshold: negative or under 5 %.
  bool get isLow => isNegative || percent < 5;

  /// Empty = every V5 image costs Anlas.
  bool get isEmpty => isNegative || percent <= 0;

  static NaiUsage? fromJson(Object? json) {
    if (json is! Map) return null;
    final pct = json['percent'];
    if (pct is! num) return null;
    final secs = json['timeUntilNextPercent'];
    return NaiUsage(
      percent: pct.toDouble(),
      isNegative: json['isNegative'] == true,
      secondsPerPercent: secs is num ? secs.toInt() : 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'percent': percent,
        'isNegative': isNegative,
        'timeUntilNextPercent': secondsPerPercent,
      };
}

/// Parsed `GET /user/subscription`.
class NaiSubscription {
  /// Subscription tier: 0 Paper, 1 Tablet, 2 Scroll, 3 Opus.
  final int tier;
  final bool active;

  /// Anlas = fixed + purchased training steps.
  final int anlas;

  /// Null below Opus or when the server omits it.
  final NaiUsage? usage;

  const NaiSubscription({
    required this.tier,
    required this.active,
    required this.anlas,
    this.usage,
  });

  bool get isOpus => tier >= 3;

  static NaiSubscription? fromJson(Object? json) {
    if (json is! Map) return null;
    int anlas = 0;
    final steps = json['trainingStepsLeft'];
    if (steps is int) {
      anlas = steps;
    } else if (steps is Map) {
      final fixed = steps['fixedTrainingStepsLeft'];
      final purchased = steps['purchasedTrainingSteps'];
      anlas = (fixed is num ? fixed.toInt() : 0) +
          (purchased is num ? purchased.toInt() : 0);
    }
    final tier = json['tier'];
    return NaiSubscription(
      tier: tier is num ? tier.toInt() : 0,
      active: json['active'] == true,
      anlas: anlas,
      usage: NaiUsage.fromJson(json['usage']),
    );
  }
}

/// What a single generation is expected to cost, before sending it.
enum NaiCostKind {
  /// Unlimited on the user's plan (V4.5 on Opus, normal size, ≤28 steps, no base image).
  free,

  /// Draws from the V5 Opus allowance.
  allowance,

  /// Will be charged in Anlas.
  anlas,

  /// No subscription info yet.
  unknown,
}

/// Pre-flight cost classification mirroring NovelAI's "free on Opus" rule:
/// one image, no base image, ≤ 1024×1024 px, ≤ 28 steps — plus the V5
/// battery. The exact Anlas price is not modelled (unverified); this only
/// answers "free / allowance / costs Anlas".
NaiCostKind estimateCostKind({
  required NaiModel model,
  required int width,
  required int height,
  required int steps,
  required bool hasBaseImage,
  required NaiSubscription? subscription,
}) {
  if (subscription == null) return NaiCostKind.unknown;
  final withinFreeRule =
      !hasBaseImage && width * height <= 1024 * 1024 && steps <= 28;
  if (!subscription.isOpus || !withinFreeRule) return NaiCostKind.anlas;
  if (model.opusUnlimited) return NaiCostKind.free;
  final usage = subscription.usage;
  if (usage == null) return NaiCostKind.allowance;
  return usage.isEmpty ? NaiCostKind.anlas : NaiCostKind.allowance;
}

/// Hard pixel cap NovelAI enforces for the V4/V5 group.
const int naiMaxPixels = 3145728;

/// Enhance "Max" is offered below 0.8 × the pixel cap.
bool naiMaxEnhanceAvailable(NaiModel model, int width, int height) =>
    model.caps.maxEnhance && width * height < naiMaxPixels * 0.8;
