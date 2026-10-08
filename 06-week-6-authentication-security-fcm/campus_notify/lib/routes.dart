/// Centralised route constants shared by GoRouter and FCM deep-link parsing.
///
/// Every navigation target in the app is defined here so that route strings
/// are never duplicated across the codebase.
abstract final class Routes {
  /// Home / dashboard.
  static const home = '/';

  /// Login screen.
  static const login = '/login';

  /// Announcement detail — append the id: `'$announcementBase/42'`.
  static const announcementBase = '/announcement';

  /// GoRouter path with the `:id` parameter placeholder.
  static const announcementById = '/announcement/:id';

  /// Helper to build a concrete announcement route.
  static String announcement(String id) => '$announcementBase/$id';
}
