import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  final _client = Supabase.instance.client;
  static const _bucket = 'voice-notes';

  /// Upload audio and return its public URL.
  /// Returns (url, null) on success, (null, errorMessage) on failure.
  Future<(String?, String?)> uploadAudioFile(File file) async {
    try {
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final path = 'reports/$fileName';

      await _client.storage.from(_bucket).upload(
        path,
        file,
        fileOptions: const FileOptions(
          contentType: 'audio/m4a',
          upsert: false,
        ),
      );

      final publicUrl = _client.storage.from(_bucket).getPublicUrl(path);
      return (publicUrl, null);
    } on StorageException catch (e) {
      return (null, 'Storage ${e.statusCode}: ${e.message}');
    } catch (e) {
      return (null, e.toString());
    }
  }
}
