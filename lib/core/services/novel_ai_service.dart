import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import '../../features/generation/models/nai_character.dart';
import '../models/nai_model.dart';
import 'nai_request_builder.dart';

export 'nai_request_builder.dart' show sanitizePromptForNai;

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

/// Service to interact with NovelAI Image Generation API (V4.5 / V5).
///
/// Model selection and per-model request sanitising live in [NaiModel] and
/// [buildNaiGenerateBody]; this class only does transport.
class NovelAIService {
  final Dio _dio = Dio();
  final String _apiKey;

  /// NovelAI hosts. Every request is built through [_imageUrl] / [_apiUrl]
  /// and authenticated through [_headers] so there is a single place to
  /// change if a proxy or self-hosted endpoint is ever supported.
  static const String imageHost = 'https://image.novelai.net';
  static const String apiHost = 'https://api.novelai.net';

  String _imageUrl(String path) => '$imageHost$path';
  String _apiUrl(String path) => '$apiHost$path';

  Map<String, String> _headers({bool json = true}) => {
        'Authorization': 'Bearer $_apiKey',
        if (json) 'Content-Type': 'application/json',
      };

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
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(minutes: 5);
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestHeader: false,
        requestBody: false, // Don't log base64 image data
        responseHeader: true,
        responseBody: false, // Don't log bytes
      ));
    }
  }

  /// POST with automatic retry on connection/timeout errors.
  Future<Response<dynamic>> _postWithRetry(
    String url, {
    required dynamic data,
    Options? options,
  }) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        return await _dio.post(url, data: data, options: options);
      } on DioException catch (e) {
        final retryable = e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout;
        if (!retryable || attempt >= 2) rethrow;
        debugPrint('NovelAIService: Retry ${attempt + 1} for $url');
        await Future.delayed(Duration(seconds: (attempt + 1) * 2));
      }
    }
    throw StateError('Unreachable');
  }

  /// GET with automatic retry on connection/timeout errors.
  Future<Response<dynamic>> _getWithRetry(
    String url, {
    Options? options,
  }) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        return await _dio.get(url, options: options);
      } on DioException catch (e) {
        final retryable = e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout;
        if (!retryable || attempt >= 2) rethrow;
        debugPrint('NovelAIService: Retry ${attempt + 1} for $url');
        await Future.delayed(Duration(seconds: (attempt + 1) * 2));
      }
    }
    throw StateError('Unreachable');
  }

  /// Encodes an image into a vibe vector via the NAI encode-vibe endpoint.
  ///
  /// Returns the raw binary vibe vector which must be base64-encoded before
  /// passing to `reference_image_multiple` in the generate call.
  Future<Uint8List> encodeVibeImage({
    required String imageBase64,
    double informationExtracted = 1.0,
    NaiModel model = NaiModel.fallback,
  }) async {
    final url = _imageUrl('/ai/encode-vibe');
    // V5 does not encode vibes; [NaiModel.vibeEncodeId] maps it to the
    // matching V4.5 id so the vibe library keeps working.
    final body = {
      "image": imageBase64,
      "model": model.vibeEncodeId,
      "information_extracted": informationExtracted,
    };

    try {
      final response = await _postWithRetry(
        url,
        data: body,
        options: Options(
          responseType: ResponseType.bytes,
          headers: _headers(),
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

  /// Fetches the user's subscription (tier, Anlas, V5 usage battery).
  ///
  /// NovelAI moved `/user/subscription` to the image host
  /// (`api.novelai.net` started answering 400 "update to the image URL" on
  /// 2026-08-21); the image host is tried first and the legacy host is kept
  /// as a fallback. The `usage` block (Opus V5 allowance) is only present on
  /// the image host and only for Opus. Returns null on failure.
  Future<NaiSubscription?> getSubscription() async {
    if (_apiKey.isEmpty) return null;
    for (final url in [
      _imageUrl('/user/subscription'),
      _apiUrl('/user/subscription'),
    ]) {
      try {
        final response = await _getWithRetry(
          url,
          options: Options(headers: _headers(json: false)),
        );
        if (response.statusCode == 200) {
          final parsed = NaiSubscription.fromJson(response.data);
          if (parsed != null) return parsed;
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) return null;
        debugPrint('NovelAIService: subscription fetch error ($url): ${e.message}');
      } catch (e) {
        debugPrint('NovelAIService: subscription fetch error ($url): $e');
      }
    }
    return null;
  }

  /// Fetches the user's Anlas balance. Returns null on failure.
  Future<int?> getAnlasBalance() async => (await getSubscription())?.anlas;

  /// Generates an image with [model] (default V4.5 Full).
  ///
  /// For img2img: set [action] to `"img2img"`, provide [sourceImageBase64],
  /// and optionally [maskBase64] for inpainting. The request body is produced
  /// by [buildNaiGenerateBody], which strips anything [model] does not support.
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
    NaiModel model = NaiModel.fallback,
    bool transparentBackground = false,
  }) async {
    final url = _imageUrl('/ai/generate-image');

    final body = buildNaiGenerateBody(
      model: model,
      prompt: prompt,
      width: width,
      height: height,
      seed: seed,
      steps: steps,
      scale: scale,
      sampler: sampler,
      negativePrompt: negativePrompt,
      smea: smea,
      smeaDyn: smeaDyn,
      decrisper: decrisper,
      promptPrefix: promptPrefix,
      promptSuffix: promptSuffix,
      characters: characters,
      interactions: interactions,
      action: action,
      sourceImageBase64: sourceImageBase64,
      maskBase64: maskBase64,
      img2imgStrength: img2imgStrength,
      img2imgNoise: img2imgNoise,
      maskBlur: maskBlur,
      directorRefImages: directorRefImages,
      directorRefDescriptions: directorRefDescriptions,
      directorRefStrengths: directorRefStrengths,
      directorRefSecondaryStrengths: directorRefSecondaryStrengths,
      directorRefInfoExtracted: directorRefInfoExtracted,
      vibeTransferImages: vibeTransferImages,
      vibeTransferStrengths: vibeTransferStrengths,
      vibeTransferInfoExtracted: vibeTransferInfoExtracted,
      useCoords: useCoords,
      transparentBackground: transparentBackground,
    );
    final inputPrompt = body['input'] as String;
    final parameters = body['parameters'] as Map<String, dynamic>;
    final effectiveNegativePrompt = parameters['uc'] as String;

    try {
      final response = await _postWithRetry(
        url,
        data: body,
        options: Options(
          responseType: ResponseType.bytes,
          headers: _headers(),
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
          "model": body['model'],
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
    final url = _imageUrl('/ai/augment-image');
    final body = <String, dynamic>{
      'image': imageBase64,
      'width': width,
      'height': height,
      'req_type': reqType,
      if (defry != null) 'defry': defry,
      if (prompt != null) 'prompt': prompt,
    };

    try {
      final response = await _postWithRetry(
        url,
        data: body,
        options: Options(
          responseType: ResponseType.bytes,
          headers: _headers(),
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

    final url = _apiUrl('/ai/upscale');
    final body = {
      'image': imageBase64,
      'width': width,
      'height': height,
      'scale': scale,
    };

    try {
      final response = await _postWithRetry(
        url,
        data: body,
        options: Options(
          responseType: ResponseType.bytes,
          headers: _headers(),
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
      final Uint8List bytes = file.content;
      // A failed generation (e.g. unsupported Vibe + Precise Reference
      // combos) can come back as an empty or truncated entry. Saving those
      // bytes puts a corrupt image in the gallery, so fail the generation
      // here instead (issue #24).
      if (!_looksLikeImage(bytes)) {
        throw Exception(
            'API returned invalid image data (${bytes.length} bytes).');
      }
      return bytes;
    }
  }
  throw Exception('No image file found in ZIP response.');
}

/// PNG signature or RIFF/WebP header — the formats NAI returns.
bool _looksLikeImage(Uint8List b) {
  if (b.length < 12) return false;
  const png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  var isPng = true;
  for (var i = 0; i < png.length; i++) {
    if (b[i] != png[i]) {
      isPng = false;
      break;
    }
  }
  if (isPng) return true;
  return b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 &&
      b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50;
}
