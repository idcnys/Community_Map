import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized access to environment variables loaded from `.env`.
/// Call [AppConfig.load] once in `main()` before using any getter.
class AppConfig {
  AppConfig._();

  static bool _loaded = false;

  /// Load the `.env` file from assets. Must be called before any access.
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
    _loaded = true;
  }

  static void _ensureLoaded() {
    assert(_loaded, 'AppConfig.load() must be called before accessing config.');
  }

  // ── Supabase ──────────────────────────────────────────────────────
  static String get supabaseUrl {
    _ensureLoaded();
    return dotenv.env['SUPABASE_URL']!;
  }

  static String get supabasePublishableKey {
    _ensureLoaded();
    return dotenv.env['SUPABASE_PUBLISHABLE_KEY']!;
  }

  // ── Cloudinary ────────────────────────────────────────────────────
  static String get cloudinaryCloudName {
    _ensureLoaded();
    return dotenv.env['CLOUDINARY_CLOUD_NAME']!;
  }

  static String get cloudinaryUploadPreset {
    _ensureLoaded();
    return dotenv.env['CLOUDINARY_UPLOAD_PRESET']!;
  }
}
