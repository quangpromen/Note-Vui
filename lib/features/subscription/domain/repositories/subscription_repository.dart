import '../../data/models/subscription_request_entity.dart';

abstract class SubscriptionRepository {
  /// Gửi yêu cầu nâng cấp gói VIP (1: Tháng, 2: Năm).
  ///
  /// Throw [Exception] nếu lỗi mạng, hoặc [ArgumentError] nếu lỗi 400.
  Future<SubscriptionRequestEntity> createUpgradeRequest(
    int planType,
    String note,
  );

  /// Lấy danh sách lịch sử yêu cầu của user.
  Future<List<SubscriptionRequestEntity>> getMyRequests();

  /// Hủy yêu cầu đang Pending.
  Future<bool> cancelRequest(int id);
}
