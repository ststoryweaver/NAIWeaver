import 'package:dio/dio.dart';

class UpdateCheckResult {
  final bool updateAvailable;
  final String? latestVersion;
  final String? releaseUrl;
  final String? error;

  const UpdateCheckResult({
    required this.updateAvailable,
    this.latestVersion,
    this.releaseUrl,
    this.error,
  });
}

class UpdateService {
  static const _repoApiUrl =
      'https://api.github.com/repos/ststoryweaver/NAIWeaver/releases/latest';

  static Future<UpdateCheckResult> checkForUpdate(String currentVersion) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        _repoApiUrl,
        options: Options(
          headers: {'Accept': 'application/vnd.github.v3+json'},
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      final data = response.data as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? '';
      final htmlUrl = data['html_url'] as String? ?? '';

      final latestVersion = tagName.startsWith('v') ? tagName.substring(1) : tagName;

      if (_isNewerVersion(currentVersion, latestVersion)) {
        return UpdateCheckResult(
          updateAvailable: true,
          latestVersion: latestVersion,
          releaseUrl: htmlUrl,
        );
      }

      return const UpdateCheckResult(updateAvailable: false);
    } on DioException catch (e) {
      return UpdateCheckResult(
        updateAvailable: false,
        error: e.message ?? 'Network error',
      );
    } catch (e) {
      return UpdateCheckResult(
        updateAvailable: false,
        error: e.toString(),
      );
    }
  }

  static bool _isNewerVersion(String current, String latest) {
    final currentParts = _parseVersion(current);
    final latestParts = _parseVersion(latest);

    for (var i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  static List<int> _parseVersion(String version) {
    final parts = version.split('.');
    return List.generate(3, (i) {
      if (i < parts.length) {
        return int.tryParse(parts[i]) ?? 0;
      }
      return 0;
    });
  }
}
