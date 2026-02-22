class AiRequest {
  final String content;
  final String? targetLanguage;
  final String? noteId;

  AiRequest({required this.content, this.targetLanguage, this.noteId});

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      if (targetLanguage != null) 'targetLanguage': targetLanguage,
      if (noteId != null) 'noteId': noteId,
    };
  }

  factory AiRequest.fromJson(Map<String, dynamic> json) {
    return AiRequest(
      content: json['content'] as String,
      targetLanguage: json['targetLanguage'] as String?,
      noteId: json['noteId'] as String?,
    );
  }
}
