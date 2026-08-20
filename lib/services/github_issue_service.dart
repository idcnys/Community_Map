import 'dart:convert';
import 'package:http/http.dart' as http;
import '../secrets.dart';

/// Labels that can be applied to GitHub issues.
enum IssueLabel {
  bug('bug', 'Bug Report'),
  feature('enhancement', 'Feature Request'),
  question('question', 'Question'),
  crash('crash', 'Crash');

  final String githubLabel;
  final String displayName;
  const IssueLabel(this.githubLabel, this.displayName);
}

/// Result of creating a GitHub issue.
class IssueResult {
  final bool success;
  final int? issueNumber;
  final String? htmlUrl;
  final String? error;

  const IssueResult.ok({required this.issueNumber, required this.htmlUrl})
      : success = true,
        error = null;

  const IssueResult.failed(this.error)
      : success = false,
        issueNumber = null,
        htmlUrl = null;
}

/// Service to create GitHub issues via the REST API.
class GitHubIssueService {
  static const _owner = 'idcnys';
  static const _repo = 'Community_Map';
  static const _token = githubPat;

  /// Creates a new issue. Returns [IssueResult].
  Future<IssueResult> createIssue({
    required String title,
    required String body,
    IssueLabel label = IssueLabel.bug,
    String? deviceInfo,
    String? appVersion,
  }) async {
    try {
      // Build markdown body
      final sb = StringBuffer(body);
      if (deviceInfo != null || appVersion != null) {
        sb.writeln();
        sb.writeln();
        sb.writeln('---');
        sb.writeln('**Submitted from app**');
        if (appVersion != null) sb.writeln('- App version: `$appVersion`');
        if (deviceInfo != null) sb.writeln('- Device: $deviceInfo');
      }

      final response = await http.post(
        Uri.parse('https://api.github.com/repos/$_owner/$_repo/issues'),
        headers: {
          'Accept': 'application/vnd.github+json',
          'Authorization': 'Bearer $_token',
          'X-GitHub-Api-Version': '2022-11-28',
        },
        body: jsonEncode({
          'title': title,
          'body': sb.toString(),
          'labels': [label.githubLabel],
        }),
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return IssueResult.ok(
          issueNumber: json['number'] as int?,
          htmlUrl: json['html_url'] as String?,
        );
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return IssueResult.failed(
          json['message'] as String? ?? 'HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      return IssueResult.failed(e.toString());
    }
  }
}
