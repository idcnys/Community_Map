import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../services/app_update_service.dart';

enum _UpdateState { checking, upToDate, updateAvailable, downloading, downloaded, installing, error }

class AppUpdatePage extends StatefulWidget {
  const AppUpdatePage({super.key});

  @override
  State<AppUpdatePage> createState() => _AppUpdatePageState();
}

class _AppUpdatePageState extends State<AppUpdatePage> {
  final _service = AppUpdateService();

  _UpdateState _state = _UpdateState.checking;
  UpdateInfo? _updateInfo;
  String? _errorMessage;
  String _currentVersion = '';

  // All releases for version switching
  List<UpdateInfo> _allReleases = [];

  // Download progress
  int _bytesDownloaded = 0;
  int _totalBytes = 0;
  File? _downloadedFile;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final pkg = await PackageInfo.fromPlatform();
      _currentVersion = pkg.version;
    } catch (_) {}

    // Load latest update check + all releases in parallel
    final results = await Future.wait([
      _service.checkForUpdate(),
      _service.getAllReleases(),
    ]);

    if (!mounted) return;

    final updateInfo = results[0] as UpdateInfo?;
    final releases = results[1] as List<UpdateInfo>;

    setState(() {
      _allReleases = releases;
      if (updateInfo == null) {
        _state = _UpdateState.upToDate;
      } else {
        _updateInfo = updateInfo;
        _state = _UpdateState.updateAvailable;
      }
    });
  }

  Future<void> _checkForUpdate() async {
    setState(() {
      _state = _UpdateState.checking;
      _errorMessage = null;
      _downloadedFile = null;
      _bytesDownloaded = 0;
      _totalBytes = 0;
    });

    // Re-fetch latest + all releases
    final results = await Future.wait([
      _service.checkForUpdate(),
      _service.getAllReleases(),
    ]);

    if (!mounted) return;

    final updateInfo = results[0] as UpdateInfo?;
    final releases = results[1] as List<UpdateInfo>;

    setState(() {
      _allReleases = releases;
      if (updateInfo == null) {
        _state = _UpdateState.upToDate;
      } else {
        _updateInfo = updateInfo;
        _state = _UpdateState.updateAvailable;
      }
    });
  }

  Future<void> _startDownload() async {
    if (_updateInfo == null) return;

    setState(() => _state = _UpdateState.downloading);

    try {
      final file = await _service.downloadApk(
        _updateInfo!,
        onProgress: (downloaded, total) {
          if (!mounted) return;
          setState(() {
            _bytesDownloaded = downloaded;
            _totalBytes = total;
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _downloadedFile = file;
        _state = _UpdateState.downloaded;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _UpdateState.error;
        _errorMessage = 'Download failed: $e';
      });
    }
  }

  Future<void> _installApk() async {
    if (_downloadedFile == null) return;

    setState(() => _state = _UpdateState.installing);

    try {
      final result = await OpenFilex.open(
        _downloadedFile!.path,
        type: 'application/vnd.android.package-archive',
      );

      if (!mounted) return;

      if (result.type == ResultType.done) {
        // System installer opened; clean up temp file after a delay
        // to allow the install to proceed.
        Future.delayed(const Duration(seconds: 5), () {
          _service.cleanupTempFiles();
        });
      } else {
        setState(() {
          _state = _UpdateState.error;
          _errorMessage = 'Could not open installer: ${result.message}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _UpdateState.error;
        _errorMessage = 'Install error: $e';
      });
    }
  }

  void _selectVersion(UpdateInfo info) {
    setState(() {
      _updateInfo = info;
      _state = _UpdateState.updateAvailable;
      _downloadedFile = null;
      _bytesDownloaded = 0;
      _totalBytes = 0;
      _errorMessage = null;
    });
  }

  double get _downloadProgress =>
      _totalBytes > 0 ? _bytesDownloaded / _totalBytes : 0.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Update'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current version badge
            Center(
              child: Chip(
                avatar: const Icon(LucideIcons.info, size: 16),
                label: Text('Current version: $_currentVersion'),
              ),
            ),
            const SizedBox(height: 16),

            // Version selector dropdown
            if (_allReleases.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: _updateInfo?.tagName,
                decoration: const InputDecoration(
                  labelText: 'Select Version',
                  prefixIcon: Icon(LucideIcons.gitBranch),
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                isExpanded: true,
                items: _allReleases.map((r) {
                  final isCurrent = r.version == _currentVersion;
                  return DropdownMenuItem<String>(
                    value: r.tagName,
                    child: Row(
                      children: [
                        Text(r.tagName),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Chip(
                            label: const Text('installed',
                                style: TextStyle(fontSize: 10)),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (tag) {
                  if (tag == null) return;
                  final info = _allReleases.firstWhere(
                    (r) => r.tagName == tag,
                  );
                  _selectVersion(info);
                },
              ),

            const SizedBox(height: 16),

            // State-dependent content
            Expanded(child: _buildStateContent(theme)),

            // Action button
            if (_state == _UpdateState.updateAvailable)
              FilledButton.icon(
                onPressed: _startDownload,
                icon: const Icon(LucideIcons.download),
                label: Text('Download ${_updateInfo?.formattedSize ?? "APK"}'),
              )
            else if (_state == _UpdateState.downloaded)
              FilledButton.icon(
                onPressed: _installApk,
                icon: const Icon(LucideIcons.packageOpen),
                label: const Text('Install Update'),
              )
            else if (_state == _UpdateState.error)
              OutlinedButton.icon(
                onPressed: _checkForUpdate,
                icon: const Icon(LucideIcons.refreshCw),
                label: const Text('Retry'),
              )
            else if (_state == _UpdateState.upToDate)
              OutlinedButton.icon(
                onPressed: _checkForUpdate,
                icon: const Icon(LucideIcons.refreshCw),
                label: const Text('Check Again'),
              ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildStateContent(ThemeData theme) {
    switch (_state) {
      case _UpdateState.checking:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking for updates…'),
            ],
          ),
        );

      case _UpdateState.upToDate:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.circleCheckBig,
                  size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'You\'re up to date!',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Version $_currentVersion is the latest release.',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        );

      case _UpdateState.updateAvailable:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.arrowUpCircle,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Update Available',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_updateInfo!.version} (${_updateInfo!.tagName})',
                            style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_updateInfo!.releaseNotes != null &&
                    _updateInfo!.releaseNotes!.trim().isNotEmpty) ...[
                  const Divider(height: 24),
                  Text(
                    'Release Notes',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _updateInfo!.releaseNotes!.trim(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );

      case _UpdateState.downloading:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(value: _downloadProgress),
              const SizedBox(height: 20),
              Text(
                'Downloading… ${(_downloadProgress * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${(_bytesDownloaded / (1024 * 1024)).toStringAsFixed(1)} / '
                '${(_totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        );

      case _UpdateState.downloaded:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.fileDown,
                  size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Download Complete',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _updateInfo?.formattedSize ?? '',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap below to install. The app will close during installation.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        );

      case _UpdateState.installing:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Opening installer…'),
            ],
          ),
        );

      case _UpdateState.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.circleAlert,
                  size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _errorMessage ?? 'Unknown error',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        );
    }
  }
}
