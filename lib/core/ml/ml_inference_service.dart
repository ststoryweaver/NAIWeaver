import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'ml_device_capabilities.dart';
import 'ml_model_entry.dart';
import 'ml_model_registry.dart';
import 'ml_storage_service.dart';

class MLInferenceResult {
  final Float32List data;
  final List<int> shape;

  const MLInferenceResult({required this.data, required this.shape});
}

class MLInferenceService {
  final String mlModelsDir;
  final OnnxRuntime _ort = OnnxRuntime();

  // Keyed by model ID (supports multiple concurrent sessions)
  final Map<String, _CachedSession> _sessions = {};
  final List<String> _sessionOrder = []; // LRU tracking

  static const int maxConcurrentSessions = 3;

  MLDeviceCapabilities? _capabilities;

  MLInferenceService({required this.mlModelsDir});

  MLDeviceCapabilities? get capabilities => _capabilities;

  Future<MLDeviceCapabilities> detectCapabilities() async {
    List<String> providers;
    try {
      final available = await _ort.getAvailableProviders();
      providers = available.map((p) => p.name).toList();
    } catch (_) {
      providers = ['CPU'];
    }

    final hasGpu = providers.any((p) =>
        p.contains('TensorRT') ||
        p.contains('Tensor_RT') ||
        p.contains('CUDA') ||
        p.contains('DirectML') ||
        p.contains('CoreML') ||
        p.contains('NNAPI'));

    String activeProvider = 'CPU';
    if (providers.any((p) => p.contains('TensorRT') || p.contains('Tensor_RT'))) {
      activeProvider = 'TensorRT';
    } else if (providers.any((p) => p.contains('CUDA'))) {
      activeProvider = 'CUDA';
    } else if (providers.any((p) => p.contains('DirectML'))) {
      activeProvider = 'DirectML';
    } else if (providers.any((p) => p.contains('CoreML'))) {
      activeProvider = 'CoreML';
    } else if (providers.any((p) => p.contains('NNAPI'))) {
      activeProvider = 'NNAPI';
    }

    String platform = '';
    if (!kIsWeb) {
      if (Platform.isWindows) {
        platform = 'windows';
      } else if (Platform.isLinux) {
        platform = 'linux';
      } else if (Platform.isMacOS) {
        platform = 'macos';
      } else if (Platform.isAndroid) {
        platform = 'android';
      } else if (Platform.isIOS) {
        platform = 'ios';
      }
    }

    final totalRamMB = await _detectRamMB();

    _capabilities = MLDeviceCapabilities(
      availableProviders: providers,
      activeProvider: activeProvider,
      hasGpuAcceleration: hasGpu,
      totalRamMB: totalRamMB,
      platform: platform,
    );

    debugPrint('ML: Device capabilities: ${_capabilities!.deviceInfoLabel}, providers: $providers');
    return _capabilities!;
  }

  Future<bool> loadModel(String modelId, {bool skipNnapi = false}) async {
    final entry = MLModelRegistry.findById(modelId);
    if (entry == null) return false;

    final config = MLModelRegistry.configFor(modelId);
    if (config == null) return false;

    // Already loaded check
    final existing = _sessions[modelId];
    if (existing != null) return true;

    // Evict LRU if at capacity
    while (_sessions.length >= maxConcurrentSessions) {
      final lruId = _sessionOrder.removeAt(0);
      final lru = _sessions.remove(lruId);
      if (lru != null) await _closeSession(lru);
    }

    final modelPath = MLStorageService.modelPath(mlModelsDir, entry);

    try {
      List<OrtProvider> providers;
      try {
        final available = await _ort.getAvailableProviders();
        providers = _selectProviders(available, skipNnapi: skipNnapi);
      } catch (_) {
        providers = [OrtProvider.CPU];
      }

      final options = OrtSessionOptions(
        intraOpNumThreads: 4,
        providers: providers,
      );

      final session = await _ort.createSession(modelPath, options: options);

      _sessions[modelId] = _CachedSession(
        modelId: modelId,
        session: session,
        config: config,
      );
      _sessionOrder.add(modelId);

      debugPrint('ML: Loaded model $modelId with providers: $providers');
      debugPrint('ML: Inputs: ${session.inputNames}, Outputs: ${session.outputNames}');
      return true;
    } catch (e) {
      debugPrint('ML: Failed to load model $modelId: $e');
      return false;
    }
  }

  Future<MLInferenceResult?> runInference({
    required String modelId,
    required Float32List inputData,
    required List<int> inputShape,
  }) async {
    // Ensure loaded
    if (!_sessions.containsKey(modelId)) {
      final loaded = await loadModel(modelId);
      if (!loaded) return null;
    }

    final session = _sessions[modelId]!;
    final config = session.config;

    // Update LRU
    _sessionOrder.remove(modelId);
    _sessionOrder.add(modelId);

    OrtValue? inputTensor;
    Map<String, OrtValue>? outputs;

    try {
      inputTensor = await OrtValue.fromList(inputData, inputShape);

      final inputName = session.session.inputNames.isNotEmpty
          ? session.session.inputNames.first
          : config.inputName;

      outputs = await session.session.run({inputName: inputTensor});

      final outputName = session.session.outputNames.isNotEmpty
          ? session.session.outputNames.first
          : config.outputName;

      final outputTensor = outputs[outputName];
      if (outputTensor == null) return null;

      final flatData = await outputTensor.asFlattenedList();
      final outputShape = outputTensor.shape;

      final float32Data = Float32List(flatData.length);
      for (int i = 0; i < flatData.length; i++) {
        float32Data[i] = (flatData[i] as num).toDouble();
      }

      return MLInferenceResult(data: float32Data, shape: outputShape);
    } catch (e) {
      debugPrint('ML: Inference error for $modelId: $e');
      return null;
    } finally {
      try {
        await inputTensor?.dispose();
      } catch (e) {
        debugPrint('MLInferenceService.runInference: dispose inputTensor: $e');
      }
      if (outputs != null) {
        for (final v in outputs.values) {
          try {
            await v.dispose();
          } catch (e) {
            debugPrint('MLInferenceService.runInference: dispose output: $e');
          }
        }
      }
    }
  }

  /// Run inference with multiple named inputs (e.g. SAM decoder).
  Future<Map<String, MLInferenceResult>?> runMultiInputInference({
    required String modelId,
    required Map<String, ({Float32List data, List<int> shape})> inputs,
  }) async {
    if (!_sessions.containsKey(modelId)) {
      final loaded = await loadModel(modelId);
      if (!loaded) return null;
    }

    final session = _sessions[modelId]!;

    _sessionOrder.remove(modelId);
    _sessionOrder.add(modelId);

    final inputTensors = <String, OrtValue>{};
    Map<String, OrtValue>? outputs;

    try {
      for (final entry in inputs.entries) {
        inputTensors[entry.key] =
            await OrtValue.fromList(entry.value.data, entry.value.shape);
      }

      outputs = await session.session.run(inputTensors);

      final results = <String, MLInferenceResult>{};
      for (final entry in outputs.entries) {
        final flatData = await entry.value.asFlattenedList();
        final shape = entry.value.shape;
        final float32Data = Float32List(flatData.length);
        for (int i = 0; i < flatData.length; i++) {
          float32Data[i] = (flatData[i] as num).toDouble();
        }
        results[entry.key] = MLInferenceResult(data: float32Data, shape: shape);
      }

      return results;
    } catch (e) {
      debugPrint('ML: Multi-input inference error for $modelId: $e');
      return null;
    } finally {
      for (final v in inputTensors.values) {
        try {
          await v.dispose();
        } catch (e) {
          debugPrint('MLInferenceService.runMultiInputInference: dispose inputTensor: $e');
        }
      }
      if (outputs != null) {
        for (final v in outputs.values) {
          try {
            await v.dispose();
          } catch (e) {
            debugPrint('MLInferenceService.runMultiInputInference: dispose output: $e');
          }
        }
      }
    }
  }

  Future<void> unloadModel(String modelId) async {
    final cached = _sessions.remove(modelId);
    _sessionOrder.remove(modelId);
    if (cached != null) {
      await _closeSession(cached);
    }
  }

  Future<void> unloadAll() async {
    for (final cached in _sessions.values) {
      await _closeSession(cached);
    }
    _sessions.clear();
    _sessionOrder.clear();
  }

  Future<int?> _detectRamMB() async {
    try {
      if (kIsWeb) return null;
      if (Platform.isLinux || Platform.isAndroid) {
        final file = File('/proc/meminfo');
        if (await file.exists()) {
          final contents = await file.readAsString();
          final match = RegExp(r'MemTotal:\s+(\d+)\s+kB').firstMatch(contents);
          if (match != null) {
            final kb = int.parse(match.group(1)!);
            return (kb / 1024).round();
          }
        }
      } else if (Platform.isWindows) {
        // Try wmic first (fast, but deprecated on Win 11)
        var result = await Process.run(
          'wmic',
          ['ComputerSystem', 'get', 'TotalPhysicalMemory', '/value'],
        );
        var match = RegExp(r'TotalPhysicalMemory=(\d+)').firstMatch(result.stdout.toString());
        // Fallback to PowerShell if wmic unavailable
        if (match == null) {
          result = await Process.run('powershell', ['-NoProfile', '-Command',
            '(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory']);
          final ps = result.stdout.toString().trim();
          final bytes = int.tryParse(ps);
          if (bytes != null) return (bytes / (1024 * 1024)).round();
        } else {
          final bytes = int.parse(match.group(1)!);
          return (bytes / (1024 * 1024)).round();
        }
      } else if (Platform.isMacOS || Platform.isIOS) {
        final result = await Process.run('sysctl', ['-n', 'hw.memsize']);
        final output = result.stdout.toString().trim();
        final bytes = int.tryParse(output);
        if (bytes != null) {
          return (bytes / (1024 * 1024)).round();
        }
      }
    } catch (e) {
      debugPrint('ML: Failed to detect RAM: $e');
    }
    return null;
  }

  Future<void> _closeSession(_CachedSession cached) async {
    try {
      await cached.session.close();
      debugPrint('ML: Unloaded model ${cached.modelId}');
    } catch (e) {
      debugPrint('ML: Error closing session ${cached.modelId}: $e');
    }
  }

  List<OrtProvider> _selectProviders(List<OrtProvider> available, {bool skipNnapi = false}) {
    final preferred = <OrtProvider>[];

    if (available.contains(OrtProvider.TENSOR_RT)) {
      preferred.add(OrtProvider.TENSOR_RT);
    }
    if (available.contains(OrtProvider.CUDA)) {
      preferred.add(OrtProvider.CUDA);
    }
    if (available.contains(OrtProvider.DIRECT_ML)) {
      preferred.add(OrtProvider.DIRECT_ML);
    }
    if (available.contains(OrtProvider.CORE_ML)) {
      preferred.add(OrtProvider.CORE_ML);
    }
    if (!skipNnapi && available.contains(OrtProvider.NNAPI)) {
      preferred.add(OrtProvider.NNAPI);
    }

    preferred.add(OrtProvider.CPU);
    return preferred;
  }
}

class _CachedSession {
  final String modelId;
  final OrtSession session;
  final MLModelConfig config;

  const _CachedSession({
    required this.modelId,
    required this.session,
    required this.config,
  });
}
