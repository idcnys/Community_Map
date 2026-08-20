import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../services/app_update_service.dart';

enum _UpdateState {
  checking,
  upToDate,
  updateAvailable,
  downloading,
  downloaded,
  installing,
  error,
}

class AppUpdatePage extends StatefulWidget {
  const AppUpdatePage({super.key});

  @override
  State<AppUpdatePage> createState() => _AppUpdatePageState();
}

class _AppUpdatePageState extends State<AppUpdatePage>
    with SingleTickerProviderStateMixin {
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

  AnimationController? _iconAnimCtrl;
  Animation<double>? _iconScale;

  @override
  void initState() {
    super.initState();
    _iconAnimCtrl ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _iconScale ??= CurvedAnimation(
      parent: _iconAnimCtrl!,
      curve: Curves.elasticOut,
    );
    _init();
  }

  @override
  void dispose() {
    _iconAnimCtrl?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final pkg = await PackageInfo.fromPlatform();
      _currentVersion = pkg.version;
    } catch (_) {}

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
    _iconAnimCtrl?.forward();
  }

  Future<void> _checkForUpdate() async {
    _iconAnimCtrl?.reset();
    setState(() {
      _state = _UpdateState.checking;
      _errorMessage = null;
      _downloadedFile = null;
      _bytesDownloaded = 0;
      _totalBytes = 0;
    });

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
    _iconAnimCtrl?.forward();
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

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('App Update')),
      body: SafeArea(
        child: Column(
          children: [
            // Header section
            _buildHeader(theme),

            // Version selector
            if (_allReleases.isNotEmpty) _buildVersionSelector(theme),

            // Main content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildStateContent(theme),
              ),
            ),

            // Bottom action bar
            _buildActionBar(theme),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────

  Widget _buildHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          // Animated icon
          ScaleTransition(
            scale: _iconScale ?? const AlwaysStoppedAnimation(1.0),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _headerIcon,
                size: 24,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _headerTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Installed: v$_currentVersion',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Version badge
          if (_updateInfo != null &&
              _state != _UpdateState.checking)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _state == _UpdateState.upToDate
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'v${_updateInfo!.version}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _state == _UpdateState.upToDate
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData get _headerIcon {
    switch (_state) {
      case _UpdateState.checking:
        return LucideIcons.radar;
      case _UpdateState.upToDate:
        return LucideIcons.circleCheckBig;
      case _UpdateState.updateAvailable:
        return LucideIcons.arrowUpCircle;
      case _UpdateState.downloading:
        return LucideIcons.download;
      case _UpdateState.downloaded:
        return LucideIcons.fileDown;
      case _UpdateState.installing:
        return LucideIcons.packageOpen;
      case _UpdateState.error:
        return LucideIcons.circleAlert;
    }
  }

  String get _headerTitle {
    switch (_state) {
      case _UpdateState.checking:
        return 'Checking…';
      case _UpdateState.upToDate:
        return 'Up to Date';
      case _UpdateState.updateAvailable:
        return 'Update Available';
      case _UpdateState.downloading:
        return 'Downloading…';
      case _UpdateState.downloaded:
        return 'Ready to Install';
      case _UpdateState.installing:
        return 'Installing…';
      case _UpdateState.error:
        return 'Error';
    }
  }

  // ── Version Selector ───────────────────────────────────────────────

  Widget _buildVersionSelector(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Icon(LucideIcons.gitBranch,
              size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                border: Border.all(
                    color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _updateInfo?.tagName,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12),
                  icon: Icon(LucideIcons.chevronDown,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant),
                  style: theme.textTheme.bodySmall,
                  items: _allReleases.map((r) {
                    final isCurrent = r.version == _currentVersion;
                    return DropdownMenuItem<String>(
                      value: r.tagName,
                      child: Row(
                        children: [
                          if (isCurrent)
                            Padding(
                              padding:
                                  const EdgeInsets.only(right: 6),
                              child: Icon(LucideIcons.check,
                                  size: 12,
                                  color: theme.colorScheme.primary),
                            ),
                          Expanded(
                            child: Text(
                              r.tagName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isCurrent
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isCurrent
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                            ),
                          ),
                          Text(
                            r.formattedSize,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                  );
                }).toList(),
                onChanged: (tag) {
                  if (tag == null) return;
                  final info = _allReleases
                      .firstWhere((r) => r.tagName == tag);
                  _selectVersion(info);
                },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── State Content ──────────────────────────────────────────────────

  Widget _buildStateContent(ThemeData theme) {
    switch (_state) {
      case _UpdateState.checking:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Checking for updates…'),
            ],
          ),
        );

      case _UpdateState.upToDate:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.shieldCheck,
                  size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 20),
              Text(
                'You\'re all set!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
        return _buildReleaseNotesCard(theme);

      case _UpdateState.downloading:
        return _buildDownloadProgress(theme);

      case _UpdateState.downloaded:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.fileDown,
                    size: 36, color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(height: 24),
              Text(
                'Download Complete',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_updateInfo?.formattedSize ?? ""} • v${_updateInfo?.version ?? ""}',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.info,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'The app will close during installation',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
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
              SizedBox(height: 20),
              Text('Opening system installer…'),
            ],
          ),
        );

      case _UpdateState.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.circleAlert,
                    size: 36, color: theme.colorScheme.onErrorContainer),
              ),
              const SizedBox(height: 24),
              Text(
                'Something went wrong',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  _errorMessage ?? 'Unknown error',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  // ── Release Notes Card ─────────────────────────────────────────────

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Widget _buildReleaseNotesCard(ThemeData theme) {
    final info = _updateInfo!;
    final notes = info.releaseNotes?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Date + author chips
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (info.publishedAt != null)
              _InfoChip(
                icon: LucideIcons.calendar,
                label: _formatDate(info.publishedAt!),
                theme: theme,
              ),
            if (info.author != null)
              _InfoChip(
                icon: LucideIcons.user,
                label: info.author!,
                theme: theme,
              ),
          ],
        ),
        // Release notes card
        if (notes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    child: Row(
                      children: [
                        Icon(LucideIcons.fileText,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text(
                          'Release Notes',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        notes,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else
          const Spacer(),
      ],
    );
  }

  // ── Download Progress ──────────────────────────────────────────────

  Widget _buildDownloadProgress(ThemeData theme) {
    final pct = (_downloadProgress * 100).toStringAsFixed(0);
    final dlMb = (_bytesDownloaded / (1024 * 1024)).toStringAsFixed(1);
    final totalMb = (_totalBytes / (1024 * 1024)).toStringAsFixed(1);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular progress
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: _downloadProgress,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                Text(
                  '$pct%',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Downloading APK',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          // Linear progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _downloadProgress,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$dlMb MB / $totalMb MB',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  // ── Action Bar ─────────────────────────────────────────────────────

  Widget _buildActionBar(ThemeData theme) {
    Widget? button;

    switch (_state) {
      case _UpdateState.updateAvailable:
        button = FilledButton.icon(
          onPressed: _startDownload,
          icon: const Icon(LucideIcons.download),
          label: Text('Download ${_updateInfo?.formattedSize ?? "APK"}'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
        );

      case _UpdateState.downloaded:
        button = FilledButton.icon(
          onPressed: _installApk,
          icon: const Icon(LucideIcons.packageOpen),
          label: const Text('Install Now'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
        );

      case _UpdateState.error:
        button = OutlinedButton.icon(
          onPressed: _checkForUpdate,
          icon: const Icon(LucideIcons.refreshCw),
          label: const Text('Try Again'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
        );

      case _UpdateState.upToDate:
        button = OutlinedButton.icon(
          onPressed: _checkForUpdate,
          icon: const Icon(LucideIcons.refreshCw),
          label: const Text('Check Again'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
        );

      case _UpdateState.checking:
      case _UpdateState.downloading:
      case _UpdateState.installing:
        button = null;
    }

    if (button == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: button,
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

