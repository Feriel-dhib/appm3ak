import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/notification_model.dart';

class NotificationsRepository {
  NotificationsRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<NotificationsPage> getMine({int page = 1, int limit = 20}) async {
    final response = await _api.dio.get(
      Endpoints.notifications,
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = response.data as Map<String, dynamic>;
    final list = (data['data'] as List<dynamic>? ?? [])
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return NotificationsPage(
      data: list,
      total: (data['total'] as num?)?.toInt() ?? 0,
      page: (data['page'] as num?)?.toInt() ?? page,
      limit: (data['limit'] as num?)?.toInt() ?? limit,
      totalPages: (data['totalPages'] as num?)?.toInt() ?? 1,
      unreadCount: (data['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> markRead(String id) async {
    await _api.dio.post(Endpoints.notificationRead(id));
  }

  Future<void> markAllRead() async {
    await _api.dio.post(Endpoints.notificationsReadAll);
  }
}

class NotificationsPage {
  const NotificationsPage({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.unreadCount,
  });
  final List<NotificationModel> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final int unreadCount;
}
