# State Management Strategy

## Riverpod (shared / async / cross-widget state)
- Auth & guest session (`guest_provider.dart`)
- Feed pagination + real-time new posts (`feed_providers.dart`)
- Group data: joined, created, search, pending (`group_providers.dart`)
- Notifications & comments (`feed_providers.dart`)
- Nearby places & enrichment (`nearby_providers.dart`)
- Report data (`report_providers.dart`)
- Service instances (`service_providers.dart`)

## setState (local / transient / widget-scoped state)
- Loading flags for buttons (`_submitting`, `_uploading`, `_sending`)
- Form field values (`_reportType`, `_descCtrl`, `_selectedGroupId`)
- UI toggles (`_obscurePassword`, `_showComments`)
- Widget-internal state (audio player position, voice recorder timer)
- File picker results (`_selectedImage`, `_audioFile`)

## Rule of thumb
- Data fetched from Firestore/Supabase that multiple widgets need → **Riverpod provider**
- Data fetched once for a single form/screen → **Riverpod FutureProvider** (preferred) or local fetch
- Transient UI state that no other widget cares about → **setState**
- Never duplicate a provider — check existing providers before creating new ones
