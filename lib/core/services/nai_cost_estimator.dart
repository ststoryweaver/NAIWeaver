import 'dart:math' as math;

/// Anlas price of a single image generation, mirroring the formula the
/// official NovelAI web frontend uses to show the cost badge.
///
/// Ported from RedContritio's gateway fork (MIT). The base-price
/// coefficients, the SMEA multipliers and the per-reference surcharges are
/// the frontend's constants; the "free on Opus" rule (no base image,
/// ≤ 1024×1024 px, ≤ 28 steps) matches [estimateCostKind] in
/// `nai_model.dart`. This only answers "how many Anlas *if* charged" — the
/// V5 Opus usage battery (free renders that draw from an allowance) is
/// [estimateCostKind]'s job, so combine the two: battery/free → 0,
/// otherwise [estimateNaiImageCost].
///
/// The exact numbers are unverified against NovelAI's billing (there is no
/// public price table) and may drift as pricing changes.
const double _areaCoefficient = 2.951823174884865e-6;
const double _stepAreaCoefficient = 5.753298233447344e-7;
const int _opusFreeMaxPixels = 1024 * 1024;
const int _opusFreeMaxSteps = 28;

/// Anlas per Character Reference ("precise" director reference) per image.
const int _preciseReferenceAnlas = 5;

/// Anlas per Vibe Transfer reference beyond the fourth, per image.
const int _extraVibeAnlas = 2;
const int _freeVibeReferences = 4;

/// Breakdown of an estimated Anlas charge for one request (possibly a batch).
class NaiImageCostEstimate {
  final int totalAnlas;
  final int baseAnlas;
  final int directorReferenceAnlas;
  final int vibeReferenceAnlas;

  /// Base price of one image before the Opus discount is applied.
  final int perImageBaseAnlas;
  final int serialImages;

  /// True when the base price was waived by the "free on Opus" rule.
  final bool opusBaseDiscountApplied;

  const NaiImageCostEstimate({
    required this.totalAnlas,
    required this.baseAnlas,
    required this.directorReferenceAnlas,
    required this.vibeReferenceAnlas,
    required this.perImageBaseAnlas,
    required this.serialImages,
    required this.opusBaseDiscountApplied,
  });

  bool get isZeroCost => totalAnlas == 0;
  bool get hasReferenceCost => directorReferenceAnlas > 0;
  bool get hasVibeCost => vibeReferenceAnlas > 0;
}

/// NovelAI's "free on Opus" rule for the base image price: no base image,
/// ≤ 1024×1024 px and ≤ 28 steps. The SMEA multipliers do not break it.
bool isOpusFreeBaseImage({
  required int width,
  required int height,
  required int steps,
  required bool hasImageInput,
}) {
  return !hasImageInput &&
      width * height <= _opusFreeMaxPixels &&
      steps <= _opusFreeMaxSteps;
}

/// Estimates the Anlas a generate-image request will be charged.
///
/// [serialImages] is the batch size (`n_samples`); reference surcharges are
/// charged per image. [strengthFactor] is the img2img strength (base price
/// scales with it). [isOpus] enables the free-base-image rule.
NaiImageCostEstimate estimateNaiImageCost({
  required int width,
  required int height,
  required int steps,
  required bool smea,
  required bool smeaDyn,
  required bool isOpus,
  int serialImages = 1,
  bool hasImageInput = false,
  double strengthFactor = 1.0,
  int directorReferenceCount = 0,
  int vibeReferenceCount = 0,
}) {
  final imageCount = math.max(1, serialImages);
  final area = math.max(1, width) * math.max(1, height);
  final multiplier = smeaDyn ? 1.4 : (smea ? 1.2 : 1.0);
  final rawBase =
      (_areaCoefficient * area) + (_stepAreaCoefficient * area * steps);
  final weightedBase = rawBase.ceil() * multiplier;
  final perImageBase = math.max((weightedBase * strengthFactor).ceil(), 2);
  final opusBaseDiscountApplied = isOpus &&
      isOpusFreeBaseImage(
        width: width,
        height: height,
        steps: steps,
        hasImageInput: hasImageInput,
      );
  final baseAnlas = opusBaseDiscountApplied ? 0 : perImageBase * imageCount;
  final directorAnlas =
      math.max(0, directorReferenceCount) * _preciseReferenceAnlas * imageCount;
  final extraVibes = math.max(0, vibeReferenceCount - _freeVibeReferences);
  final vibeAnlas = extraVibes * _extraVibeAnlas * imageCount;

  return NaiImageCostEstimate(
    totalAnlas: baseAnlas + directorAnlas + vibeAnlas,
    baseAnlas: baseAnlas,
    directorReferenceAnlas: directorAnlas,
    vibeReferenceAnlas: vibeAnlas,
    perImageBaseAnlas: perImageBase,
    serialImages: imageCount,
    opusBaseDiscountApplied: opusBaseDiscountApplied,
  );
}
