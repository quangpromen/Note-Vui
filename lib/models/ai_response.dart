class AiResponse {
  final String? result;
  final bool isSuccess;
  final String? errorMessage;
  final int inputTokens;
  final int outputTokens;
  final int remainingQuota;

  AiResponse({
    this.result,
    required this.isSuccess,
    this.errorMessage,
    required this.inputTokens,
    required this.outputTokens,
    required this.remainingQuota,
  });

  factory AiResponse.fromJson(Map<String, dynamic> json) {
    return AiResponse(
      result: json['result'] as String?,
      isSuccess: json['isSuccess'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
      inputTokens: json['inputTokens'] as int? ?? 0,
      outputTokens: json['outputTokens'] as int? ?? 0,
      remainingQuota: json['remainingQuota'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result': result,
      'isSuccess': isSuccess,
      'errorMessage': errorMessage,
      'inputTokens': inputTokens,
      'outputTokens': outputTokens,
      'remainingQuota': remainingQuota,
    };
  }
}
