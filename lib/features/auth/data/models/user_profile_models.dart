/// Models cho API lấy thông tin hồ sơ cá nhân.
///
/// **Endpoint**: `GET /api/user/profile`
/// **Authorization**: Bearer Token (bắt buộc)
///
/// Response chứa toàn bộ thông tin user: cơ bản, gói VIP,
/// thống kê ghi chú, và thống kê sử dụng AI.

// ═══════════════════════════════════════════════════════════════════════════
// AI ACTION USAGE — Thống kê từng loại hành động AI trong ngày
// ═══════════════════════════════════════════════════════════════════════════

/// Chi tiết lượt dùng AI theo từng loại hành động (Summarize, Translate, ...).
///
/// ```json
/// { "actionType": "Summarize", "count": 3 }
/// ```
class AiActionUsage {
  final String actionType;
  final int count;

  const AiActionUsage({required this.actionType, required this.count});

  /// Parse từ JSON — an toàn với null.
  factory AiActionUsage.fromJson(Map<String, dynamic> json) {
    return AiActionUsage(
      actionType: json['actionType']?.toString() ?? 'Unknown',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AI USAGE STATS — Thống kê sử dụng AI tổng hợp
// ═══════════════════════════════════════════════════════════════════════════

/// Thống kê tổng hợp về việc sử dụng tính năng AI.
///
/// ```json
/// {
///   "usedToday": 5,
///   "usedThisMonth": 42,
///   "usedThisYear": 180,
///   "totalUsed": 320,
///   "todayByAction": [ { "actionType": "Summarize", "count": 3 } ]
/// }
/// ```
class AiUsageStats {
  final int usedToday;
  final int usedThisMonth;
  final int usedThisYear;
  final int totalUsed;
  final List<AiActionUsage> todayByAction;

  const AiUsageStats({
    required this.usedToday,
    required this.usedThisMonth,
    required this.usedThisYear,
    required this.totalUsed,
    required this.todayByAction,
  });

  /// Parse từ JSON — an toàn với null và list rỗng.
  factory AiUsageStats.fromJson(Map<String, dynamic> json) {
    return AiUsageStats(
      usedToday: (json['usedToday'] as num?)?.toInt() ?? 0,
      usedThisMonth: (json['usedThisMonth'] as num?)?.toInt() ?? 0,
      usedThisYear: (json['usedThisYear'] as num?)?.toInt() ?? 0,
      totalUsed: (json['totalUsed'] as num?)?.toInt() ?? 0,
      todayByAction:
          (json['todayByAction'] as List<dynamic>?)
              ?.map((e) => AiActionUsage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// USER SUBSCRIPTION INFO — Thông tin gói đăng ký (VIP)
// ═══════════════════════════════════════════════════════════════════════════

/// Thông tin gói đăng ký / VIP của user.
///
/// ```json
/// {
///   "planName": "Pro",
///   "planType": "Monthly",
///   "isVip": true,
///   "status": "Active",
///   "startDate": "2026-01-01T00:00:00Z",
///   "endDate": "2026-02-01T00:00:00Z",
///   "daysRemaining": 27,
///   "isAutoRenew": true
/// }
/// ```
class UserSubscriptionInfo {
  final String planName;
  final String planType;
  final bool isVip;
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int daysRemaining;
  final bool isAutoRenew;

  const UserSubscriptionInfo({
    required this.planName,
    required this.planType,
    required this.isVip,
    this.status,
    this.startDate,
    this.endDate,
    required this.daysRemaining,
    required this.isAutoRenew,
  });

  /// Parse từ JSON — handle null safety cho startDate, endDate, status.
  factory UserSubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return UserSubscriptionInfo(
      planName: json['planName']?.toString() ?? 'Free',
      planType: json['planType']?.toString() ?? 'Free',
      isVip: json['isVip'] == true,
      status: json['status']?.toString(),
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
      daysRemaining: (json['daysRemaining'] as num?)?.toInt() ?? 0,
      isAutoRenew: json['isAutoRenew'] == true,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// USER PROFILE RESPONSE — Response tổng hợp từ API
// ═══════════════════════════════════════════════════════════════════════════

/// Response model cho API `GET /api/user/profile`.
///
/// Bao gồm:
/// - Thông tin cơ bản: userId, email, fullName, avatarUrl
/// - Gói đăng ký: [subscription]
/// - Thống kê ghi chú: [totalNotesBackedUp], [activeNotes]
/// - Thống kê AI: [aiUsage]
class UserProfileResponse {
  final String userId;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final UserSubscriptionInfo subscription;
  final int totalNotesBackedUp;
  final int activeNotes;
  final AiUsageStats aiUsage;

  const UserProfileResponse({
    required this.userId,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    required this.subscription,
    required this.totalNotesBackedUp,
    required this.activeNotes,
    required this.aiUsage,
  });

  /// Parse từ JSON phức tạp — xử lý toàn bộ nested objects.
  ///
  /// Các trường nullable (avatarUrl) được handle an toàn.
  /// Các nested object (subscription, aiUsage) được parse bằng fromJson riêng.
  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      userId: json['userId']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      subscription: json['subscription'] != null
          ? UserSubscriptionInfo.fromJson(
              json['subscription'] as Map<String, dynamic>,
            )
          : const UserSubscriptionInfo(
              planName: 'Free',
              planType: 'Free',
              isVip: false,
              daysRemaining: 0,
              isAutoRenew: false,
            ),
      totalNotesBackedUp: (json['totalNotesBackedUp'] as num?)?.toInt() ?? 0,
      activeNotes: (json['activeNotes'] as num?)?.toInt() ?? 0,
      aiUsage: json['aiUsage'] != null
          ? AiUsageStats.fromJson(json['aiUsage'] as Map<String, dynamic>)
          : const AiUsageStats(
              usedToday: 0,
              usedThisMonth: 0,
              usedThisYear: 0,
              totalUsed: 0,
              todayByAction: [],
            ),
    );
  }
}
