import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepositoryImpl(),
);
