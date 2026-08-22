import 'package:flutter_test/flutter_test.dart';
import 'package:naiweaver/core/services/nai_cost_estimator.dart';

// Ported from RedContritio's gateway fork (MIT).
void main() {
  group('estimateNaiImageCost', () {
    test('treats Opus normal serial images as zero Anlas', () {
      final estimate = estimateNaiImageCost(
        width: 832,
        height: 1216,
        steps: 28,
        smea: false,
        smeaDyn: false,
        isOpus: true,
        serialImages: 4,
      );

      expect(estimate.totalAnlas, 0);
      expect(estimate.baseAnlas, 0);
      expect(estimate.opusBaseDiscountApplied, isTrue);
      expect(estimate.serialImages, 4);
    });

    test('charges the base price below Opus', () {
      final estimate = estimateNaiImageCost(
        width: 832,
        height: 1216,
        steps: 28,
        smea: false,
        smeaDyn: false,
        isOpus: false,
      );

      expect(estimate.opusBaseDiscountApplied, isFalse);
      expect(estimate.baseAnlas, greaterThan(0));
      expect(estimate.totalAnlas, estimate.baseAnlas);
    });

    test('adds precise reference cost per serial image', () {
      final estimate = estimateNaiImageCost(
        width: 1024,
        height: 1024,
        steps: 28,
        smea: false,
        smeaDyn: false,
        isOpus: true,
        serialImages: 2,
        directorReferenceCount: 2,
      );

      expect(estimate.baseAnlas, 0);
      expect(estimate.directorReferenceAnlas, 20);
      expect(estimate.totalAnlas, 20);
    });

    test('adds Vibe generation cost only above four vibes', () {
      final estimate = estimateNaiImageCost(
        width: 1024,
        height: 1024,
        steps: 28,
        smea: false,
        smeaDyn: false,
        isOpus: true,
        serialImages: 3,
        vibeReferenceCount: 5,
      );

      expect(estimate.baseAnlas, 0);
      expect(estimate.vibeReferenceAnlas, 6);
      expect(estimate.totalAnlas, 6);
    });

    test('keeps the Opus base discount with SMEA like the official frontend',
        () {
      final estimate = estimateNaiImageCost(
        width: 1024,
        height: 1024,
        steps: 28,
        smea: true,
        smeaDyn: false,
        isOpus: true,
      );

      expect(estimate.baseAnlas, 0);
      expect(estimate.totalAnlas, 0);
      expect(estimate.opusBaseDiscountApplied, isTrue);
    });

    test('charges base Anlas above the Opus free size limit', () {
      final estimate = estimateNaiImageCost(
        width: 1216,
        height: 1216,
        steps: 28,
        smea: false,
        smeaDyn: false,
        isOpus: true,
      );

      expect(estimate.baseAnlas, greaterThan(0));
      expect(estimate.totalAnlas, estimate.baseAnlas);
      expect(estimate.opusBaseDiscountApplied, isFalse);
    });

    test('charges base Anlas above 28 steps or with a base image on Opus', () {
      final steps = estimateNaiImageCost(
        width: 1024,
        height: 1024,
        steps: 29,
        smea: false,
        smeaDyn: false,
        isOpus: true,
      );
      final img2img = estimateNaiImageCost(
        width: 1024,
        height: 1024,
        steps: 28,
        smea: false,
        smeaDyn: false,
        isOpus: true,
        hasImageInput: true,
      );

      expect(steps.opusBaseDiscountApplied, isFalse);
      expect(img2img.opusBaseDiscountApplied, isFalse);
      expect(steps.baseAnlas, greaterThan(0));
      expect(img2img.baseAnlas, greaterThan(0));
    });

    test('never prices an image below two Anlas', () {
      final estimate = estimateNaiImageCost(
        width: 64,
        height: 64,
        steps: 1,
        smea: false,
        smeaDyn: false,
        isOpus: false,
      );

      expect(estimate.perImageBaseAnlas, 2);
    });
  });
}
