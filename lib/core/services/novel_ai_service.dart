import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import '../../features/generation/models/nai_character.dart';

/// Result of an image generation
class GenerationResult {
  final Uint8List imageBytes;
  final Map<String, dynamic> metadata;

  GenerationResult({required this.imageBytes, required this.metadata});
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = 'Unauthorized']);
}

/// Service to interact with NovelAI Image Generation API (V4.5)
class NovelAIService {
  final Dio _dio = Dio();
  final String _apiKey;

  /// Maximum output dimension (px) the NAI upscale endpoint accepts.
  static const int maxUpscaleOutputPixels = 4096;

  /// Returns the largest viable scale factor (4, 2) for the given input
  /// dimensions, or `null` if even 2x would exceed the output limit.
  static int? bestUpscaleScale(int width, int height) {
    for (final s in [4, 2]) {
      if (width * s <= maxUpscaleOutputPixels &&
          height * s <= maxUpscaleOutputPixels) {
        return s;
      }
    }
    return null;
  }

  NovelAIService(this._apiKey) {
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestHeader: false,
        requestBody: false, // Don't log base64 image data
        responseHeader: true,
        responseBody: false, // Don't log bytes
      ));
    }
  }

  /// Encodes an image into a vibe vector via the NAI encode-vibe endpoint.
  ///
  /// Returns the raw binary vibe vector which must be base64-encoded before
  /// passing to `reference_image_multiple` in the generate call.
  Future<Uint8List> encodeVibeImage({
    required String imageBase64,
    double informationExtracted = 1.0,
  }) async {
    const url = 'https://image.novelai.net/ai/encode-vibe';
    final body = {
      "image": imageBase64,
      "model": "nai-diffusion-4-5-full",
      "information_extracted": informationExtracted,
    };

    try {
      final response = await _dio.post(
        url,
        data: body,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return Uint8List.fromList(response.data as List<int>);
      } else {
        throw Exception('[Encode-Vibe Error ${response.statusCode}]');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw UnauthorizedException();
      }
      debugPrint('NovelAIService: Encode-vibe error: ${e.message}');
      rethrow;
    }
  }

  /// Fetches the user's Anlas balance from the NovelAI user data API.
  /// Returns null on failure (no API key, network error).
  Future<int?> getAnlasBalance() async {
    if (_apiKey.isEmpty) return null;
    try {
      final response = await _dio.get(
        'https://api.novelai.net/user/subscription',
        options: Options(headers: {'Authorization': 'Bearer $_apiKey'}),
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final steps = data['trainingStepsLeft'];
        if (steps is int) return steps;
        if (steps is Map<String, dynamic>) {
          final fixed = steps['fixedTrainingStepsLeft'] as int? ?? 0;
          final purchased = steps['purchasedTrainingSteps'] as int? ?? 0;
          return fixed + purchased;
        }
      }
    } catch (e) {
      debugPrint('NovelAIService: Anlas fetch error: $e');
    }
    return null;
  }

  /// Generates an image using the NAI Diffusion V4.5 model.
  ///
  /// For img2img: set [action] to `"img2img"`, provide [sourceImageBase64],
  /// and optionally [maskBase64] for inpainting.
  Future<GenerationResult> generateImage({
    required String prompt,
    required int width,
    required int height,
    required int seed,
    int steps = 28,
    double scale = 6.0,
    String sampler = "k_euler_ancestral",
    String? negativePrompt,
    bool smea = false,
    bool smeaDyn = false,
    bool decrisper = false,
    String? promptPrefix,
    String? promptSuffix,
    List<NaiCharacter> characters = const [],
    List<NaiInteraction> interactions = const [],
    String action = 'generate',
    String? sourceImageBase64,
    String? maskBase64,
    double? img2imgStrength,
    double? img2imgNoise,
    bool? img2imgColorCorrect,
    int? maskBlur,
    List<String>? directorRefImages,
    List<Map<String, dynamic>>? directorRefDescriptions,
    List<double>? directorRefStrengths,
    List<double>? directorRefSecondaryStrengths,
    List<double>? directorRefInfoExtracted,
    List<String>? vibeTransferImages,
    List<double>? vibeTransferStrengths,
    List<double>? vibeTransferInfoExtracted,
    bool? useCoords,
  }) async {
    const url = 'https://image.novelai.net/ai/generate-image';

    final inputPrompt = "${promptPrefix ?? ''}$prompt${promptSuffix ?? ''}";
    
    final effectiveNegativePrompt = negativePrompt ?? "";

    final bool isMultiCharacter = characters.isNotEmpty;

    // Build character captions with interaction tags
    final List<Map<String, dynamic>> charCaptions = [];
    for (int i = 0; i < characters.length; i++) {
      final character = characters[i];
      String caption = character.prompt;

      // Find interactions involving this character
      for (final interaction in interactions) {
        if (interaction.type == InteractionType.mutual) {
          if (interaction.sourceCharacterIndices.contains(i)) {
            caption = "mutual#${interaction.actionName}, $caption";
          }
        } else {
          if (interaction.sourceCharacterIndices.contains(i)) {
            caption = "source#${interaction.actionName}, $caption";
          } else if (interaction.targetCharacterIndices.contains(i)) {
            caption = "target#${interaction.actionName}, $caption";
          }
        }
      }

      charCaptions.add({
        'char_caption': caption,
        'centers': [character.center.toJson()],
      });
    }

    final parameters = {
      "params_version": 3,
      "width": width,
      "height": height,
      "scale": scale,
      "sampler": sampler,
      "steps": steps,
      "seed": seed,
      "n_samples": 1,
      "noise_schedule": "karras",
      "sm": smea,
      "sm_dyn": smeaDyn,
      "dynamic_thresholding": decrisper,
      "uc": effectiveNegativePrompt,
      if (isMultiCharacter)
        "characterPrompts": charCaptions.map((cc) {
          return {
            'prompt': cc['char_caption'],
            'center': (cc['centers'] as List).isNotEmpty
                ? (cc['centers'] as List).first
                : {'x': 0.5, 'y': 0.5},
          };
        }).toList(),
      "v4_prompt": {
        "caption": {
          "base_caption": inputPrompt,
          "char_captions": charCaptions,
        },
        "use_coords": useCoords ?? isMultiCharacter,
        "use_order": true
      },
      "v4_negative_prompt": {
        "caption": {
          "base_caption": effectiveNegativePrompt,
          "char_captions":
              characters.map((c) => c.toV4NegativePrompt()).toList(),
        }
      },
      // img2img / inpainting parameters
      if (action != 'generate' && sourceImageBase64 != null)
        "image": sourceImageBase64,
      if (action != 'generate' && maskBase64 != null)
        "mask": maskBase64,
      if (action != 'generate' && img2imgStrength != null)
        "strength": img2imgStrength,
      if (action == 'img2img' && img2imgNoise != null)
        "noise": img2imgNoise,
      if (action == 'img2img')
        "extra_noise_seed": seed,
      if (action != 'generate')
        "add_original_image": true,
      if (action == 'infill' && maskBlur != null)
        "mask_blur": maskBlur,
      // Director reference (Precise Reference) parameters
      if (directorRefImages != null && directorRefImages.isNotEmpty)
        "director_reference_images": directorRefImages,
      if (directorRefDescriptions != null && directorRefDescriptions.isNotEmpty)
        "director_reference_descriptions": directorRefDescriptions,
      if (directorRefStrengths != null && directorRefStrengths.isNotEmpty)
        "director_reference_strength_values": directorRefStrengths,
      if (directorRefSecondaryStrengths != null && directorRefSecondaryStrengths.isNotEmpty)
        "director_reference_secondary_strength_values": directorRefSecondaryStrengths,
      if (directorRefInfoExtracted != null && directorRefInfoExtracted.isNotEmpty)
        "director_reference_information_extracted": directorRefInfoExtracted,
      // Vibe Transfer (Reference Image) parameters
      if (vibeTransferImages != null && vibeTransferImages.isNotEmpty)
        "reference_image_multiple": vibeTransferImages,
      if (vibeTransferStrengths != null && vibeTransferStrengths.isNotEmpty)
        "reference_strength_multiple": vibeTransferStrengths,
      if (vibeTransferInfoExtracted != null && vibeTransferInfoExtracted.isNotEmpty)
        "reference_information_extracted_multiple": vibeTransferInfoExtracted,
    };

    final body = {
      "input": inputPrompt,
      "model": action == 'infill' ? "nai-diffusion-4-5-full-inpainting" : "nai-diffusion-4-5-full",
      "action": action,
      "parameters": parameters,
    };

    try {
      final response = await _dio.post(
        url,
        data: body,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final imageBytes = await compute(_decodeZip, response.data as List<int>);
        
        // Prepare metadata in official NAI style
        // We include both 'uc' and 'undesired_content' to be absolutely sure
        final metadata = {
          "prompt": inputPrompt,
          "original_prompt": prompt,
          "uc": effectiveNegativePrompt,
          "undesired_content": effectiveNegativePrompt,
          ...parameters,
        };

        return GenerationResult(
          imageBytes: imageBytes,
          metadata: metadata,
        );
      } else {
        throw Exception('[API Error ${response.statusCode}]');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw UnauthorizedException();
      }
      debugPrint('NovelAIService: DioError: ${e.message}');
      // Log the response body for API errors (400, 422, etc.)
      final responseData = e.response?.data;
      if (responseData != null) {
        if (responseData is List<int>) {
          debugPrint('NovelAIService: Response body: ${utf8.decode(responseData, allowMalformed: true)}');
        } else {
          debugPrint('NovelAIService: Response body: $responseData');
        }
      }
      rethrow;
    } catch (e) {
      debugPrint('NovelAIService: Error generating image: $e');
      rethrow;
    }
  }

  /// Augments an image using Director Tools (bg-removal, lineart, sketch, etc.)
  Future<Uint8List> augmentImage({
    required String imageBase64,
    required int width,
    required int height,
    required String reqType,
    int? defry,
    String? prompt,
  }) async {
    const url = 'https://image.novelai.net/ai/augment-image';
    final body = <String, dynamic>{
      'image': imageBase64,
      'width': width,
      'height': height,
      'req_type': reqType,
      if (defry != null) 'defry': defry,
      if (prompt != null) 'prompt': prompt,
    };

    try {
      final response = await _dio.post(
        url,
        data: body,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return await compute(_decodeZip, response.data as List<int>);
      } else {
        throw Exception('[Augment Error ${response.statusCode}]');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw UnauthorizedException();
      }
      debugPrint('NovelAIService: Augment error: ${e.message}');
      final responseData = e.response?.data;
      if (responseData != null) {
        if (responseData is List<int>) {
          debugPrint('NovelAIService: Response body: ${utf8.decode(responseData, allowMalformed: true)}');
        } else {
          debugPrint('NovelAIService: Response body: $responseData');
        }
      }
      rethrow;
    }
  }

  /// Upscales an image using the NovelAI upscale endpoint.
  ///
  /// If [scale] would produce an output exceeding [maxUpscaleOutputPixels],
  /// an [ArgumentError] is thrown. Use [bestUpscaleScale] to pick a safe value.
  Future<Uint8List> upscaleImage({
    required String imageBase64,
    required int width,
    required int height,
    int scale = 2,
  }) async {
    if (width * scale > maxUpscaleOutputPixels ||
        height * scale > maxUpscaleOutputPixels) {
      throw ArgumentError(
        'Output resolution ${width * scale}x${height * scale} exceeds '
        'NAI upscale limit of ${maxUpscaleOutputPixels}px. '
        'Try a smaller scale or image.',
      );
    }

    const url = 'https://api.novelai.net/ai/upscale';
    final body = {
      'image': imageBase64,
      'width': width,
      'height': height,
      'scale': scale,
    };

    try {
      final response = await _dio.post(
        url,
        data: body,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return await compute(_decodeZip, response.data as List<int>);
      } else {
        throw Exception('[Upscale Error ${response.statusCode}]');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw UnauthorizedException();
      }
      debugPrint('NovelAIService: Upscale error: ${e.message}');
      final responseData = e.response?.data;
      if (responseData != null) {
        if (responseData is List<int>) {
          debugPrint('NovelAIService: Response body: ${utf8.decode(responseData, allowMalformed: true)}');
        } else {
          debugPrint('NovelAIService: Response body: $responseData');
        }
      }
      rethrow;
    }
  }
}

/// Helper to decode the ZIP response from NAI
Uint8List _decodeZip(List<int> data) {
  final archive = ZipDecoder().decodeBytes(data);
  if (archive.isNotEmpty) {
    final file = archive.first;
    if (file.isFile) {
      return file.content;
    }
  }
  throw Exception('No image file found in ZIP response.');
}
