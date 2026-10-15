/// Returns a route from an FCM payload, with a normalized leading slash.
String routeFromMessage(
  Map<String, dynamic> data, {
  String fallbackRoute = '/',
}) {
  final route = data['route'];
  if (route is! String || route.trim().isEmpty) return fallbackRoute;
  return route.startsWith('/') ? route : '/$route';
}

/// Formats a date and time for compact display without a localization package.
String formatDateTime(DateTime dateTime) {
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$day/$month/${dateTime.year} $hour:$minute';
}
