import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Uploads images to Cloudinary using an unsigned upload preset.
/// Cloud: s2r8pydh | Preset: cmap-flutter
class CloudinaryService {
  static const String _cloudName = 's2r8pydh';
  static const String _uploadPreset = 'cmap-flutter';
  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Uploads an image file and returns the secure URL.
  /// Returns null on failure (error message via onError callback).
  Future<String?> uploadImage(
    File imageFile, {
    String folder = '',
    void Function(String error)? onError,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl))
        ..fields['upload_preset'] = _uploadPreset;

      if (folder.isNotEmpty) {
        request.fields['folder'] = folder;
      }

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final json = jsonDecode(response.body);

      if (streamedResponse.statusCode == 200) {
        return json['secure_url'] as String;
      } else {
        final msg = json['error']?['message'] ?? 'Upload failed';
        onError?.call(msg);
        return null;
      }
    } catch (e) {
      onError?.call('Network error: $e');
      return null;
    }
  }
}
