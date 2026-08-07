/// Barrel file — re-exports the split services for backward compatibility.
/// New code should import the specific service directly.
library;

export 'post_service.dart';
export 'notification_service.dart';
export 'poll_service.dart';

import 'post_service.dart';

/// @deprecated Use [PostService] directly. Kept as a type alias so
/// existing code referencing CommunityPostService still compiles.
typedef CommunityPostService = PostService;
