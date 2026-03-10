class SubscriptionRequestEntity {
  final int id;
  final String planType;
  final String planName;
  final String status;
  final String? note;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? processedAt;

  SubscriptionRequestEntity({
    required this.id,
    required this.planType,
    required this.planName,
    required this.status,
    this.note,
    this.adminNote,
    required this.createdAt,
    this.processedAt,
  });

  factory SubscriptionRequestEntity.fromJson(Map<String, dynamic> json) {
    return SubscriptionRequestEntity(
      id: json['id'] as int,
      planType: json['planType'] as String,
      planName: json['planName'] as String,
      status: json['status'] as String,
      note: json['note'] as String?,
      adminNote: json['adminNote'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'] as String).toLocal()
          : null,
    );
  }
}
