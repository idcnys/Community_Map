import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Result of checking for an available update.
class UpdateInfo {
  final String tagName;
  final String version; // e.g. "2.2.0"
  final String? releaseNotes;
  final String downloadUrl;
  final int fileSizeBytes;
  final DateTime? publishedAt;
  final String? author;

  const UpdateInfo({
    required this.tagName,
    required this.version,
    this.releaseNotes,
    required this.downloadUrl,
    required this.fileSizeBytes,
    this.publishedAt,
    this.author,
  });

  String get formattedSize {
    if (fileSizeBytes <= 0) return 'Unknown size';
    final mb = fileSizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

/// Service that checks GitHub Releases for app updates and downloads APKs.
class AppUpdateService {
  static const _repoOwner = 'idcnys';
  static const _repoName = 'Community_Map';
  static const _apiBase = 'https://api.github.com';

  /// Returns the latest [UpdateInfo] if a newer version is available,
  /// or `null` if the current version is up-to-date.
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g. "2.1.4"

      final response = await http.get(
        Uri.parse('$_apiBase/repos/$_repoOwner/$_repoName/releases/latest'),
        headers: {'Accept': 'application/vnd.github+json'},
      );

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = json['tag_name'] as String? ?? '';
      final latestVersion = _extractVersion(tagName);

      if (!_isNewerVersion(currentVersion, latestVersion)) return null;

      final assets = json['assets'] as List<dynamic>? ?? [];
      final apkAsset = _pickBestApk(assets);

      if (apkAsset == null) return null;

      final downloadUrl = apkAsset['browser_download_url'] as String? ?? '';
      final fileSize = apkAsset['size'] as int? ?? 0;

      if (downloadUrl.isEmpty) return null;

      final publishedAt = json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String)
          : null;
      final author = (json['author'] as Map<String, dynamic>?)?['login'] as String?;

      return UpdateInfo(
        tagName: tagName,
        version: latestVersion,
        releaseNotes: json['body'] as String?,
        downloadUrl: downloadUrl,
        fileSizeBytes: fileSize,
        publishedAt: publishedAt,
        author: author,
      );
    } catch (_) {
      return null;
    }
  }

  /// Downloads the APK from [updateInfo] to a temp file.
  /// Calls [onProgress] with (bytesDownloaded, totalBytes).
  /// Returns the downloaded [File].
  Future<File> downloadApk(
    UpdateInfo updateInfo, {
    void Function(int bytesDownloaded, int totalBytes)? onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/cmap-update-${updateInfo.version}.apk';
    final file = File(filePath);

    // Remove stale partial download
    if (await file.exists()) await file.delete();

    final request = http.Request('GET', Uri.parse(updateInfo.downloadUrl));
    final streamedResponse = await http.Client().send(request);

    final totalBytes = streamedResponse.contentLength ?? updateInfo.fileSizeBytes;
    var downloadedBytes = 0;

    final sink = file.openWrite();
    await for (final chunk in streamedResponse.stream) {
      sink.add(chunk);
      downloadedBytes += chunk.length;
      onProgress?.call(downloadedBytes, totalBytes);
    }
    await sink.flush();
    await sink.close();

    return file;
  }

  /// Fetches all GitHub releases (up to [limit]) for version switching/testing.
  Future<List<UpdateInfo>> getAllReleases({int limit = 30}) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_apiBase/repos/$_repoOwner/$_repoName/releases?per_page=$limit',
        ),
        headers: {'Accept': 'application/vnd.github+json'},
      );

      if (response.statusCode != 200) return [];

      final list = jsonDecode(response.body) as List<dynamic>;
      final results = <UpdateInfo>[];

      for (final item in list) {
        final json = item as Map<String, dynamic>;
        final tagName = json['tag_name'] as String? ?? '';
        final version = _extractVersion(tagName);
        final assets = json['assets'] as List<dynamic>? ?? [];
        final apkAsset = _pickBestApk(assets);

        if (apkAsset == null) continue;

        final downloadUrl =
            apkAsset['browser_download_url'] as String? ?? '';
        final fileSize = apkAsset['size'] as int? ?? 0;
        if (downloadUrl.isEmpty) continue;

        final publishedAt = json['published_at'] != null
            ? DateTime.tryParse(json['published_at'] as String)
            : null;
        final author = (json['author'] as Map<String, dynamic>?)?['login'] as String?;

        results.add(UpdateInfo(
          tagName: tagName,
          version: version,
          releaseNotes: json['body'] as String?,
          downloadUrl: downloadUrl,
          fileSizeBytes: fileSize,
          publishedAt: publishedAt,
          author: author,
        ));
      }

      return results;
    } catch (_) {
      return [];
    }
  }

  /// Deletes any leftover update APK files from the temp directory.
  Future<void> cleanupTempFiles() async {
    try {
      final dir = await getTemporaryDirectory();
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.contains('cmap-update-')) {
          await entity.delete();
        }
      }
    } catch (_) {}
  }

  // ── Helpers ────────────────────────────────────────────────────────

  /// Picks the best APK asset from a release's assets list.
  /// Priority: arm64-v8a → armeabi-v7a → x86_64 → release (fat) → any .apk
  Map<String, dynamic>? _pickBestApk(List<dynamic> assets) {
    const archPriority = [
      'arm64-v8a',
      'armeabi-v7a',
      'x86_64',
    ];

    final apkAssets = assets
        .whereType<Map<String, dynamic>>()
        .where((a) => (a['name'] as String?)?.endsWith('.apk') == true)
        .toList();

    if (apkAssets.isEmpty) return null;

    // Try each architecture in priority order
    for (final arch in archPriority) {
      final match = apkAssets.firstWhere(
        (a) => (a['name'] as String?)?.contains(arch) == true,
        orElse: () => <String, dynamic>{},
      );
      if (match.isNotEmpty) return match;
    }

    // Fallback: universal/release APK
    final release = apkAssets.firstWhere(
      (a) => (a['name'] as String?)?.contains('release') == true,
      orElse: () => <String, dynamic>{},
    );
    if (release.isNotEmpty) return release;

    // Last resort: any APK
    return apkAssets.first;
  }

  /// Extracts a clean semver string from a tag like "v2.2.0+" → "2.2.0"
  String _extractVersion(String tag) {
    var v = tag.trim();
    if (v.startsWith('v') || v.startsWith('V')) v = v.substring(1);
    // Strip trailing build metadata like "+"
    final plusIdx = v.indexOf('+');
    if (plusIdx != -1) v = v.substring(0, plusIdx);
    return v;
  }

  /// Simple semver comparison: returns true if [latest] > [current].
  bool _isNewerVersion(String current, String latest) {
    final c = _parseSemver(current);
    final l = _parseSemver(latest);
    for (var i = 0; i < 3; i++) {
      if (l[i] > c[i]) return true;
      if (l[i] < c[i]) return false;
    }
    return false;
  }

  List<int> _parseSemver(String version) {
    final parts = version.split('.');
    return [
      int.tryParse(parts.elementAtOrNull(0) ?? '0') ?? 0,
      int.tryParse(parts.elementAtOrNull(1) ?? '0') ?? 0,
      int.tryParse(parts.elementAtOrNull(2) ?? '0') ?? 0,
    ];
  }
}
