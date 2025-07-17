class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? type; // 'entry', 'report', 'search', 'general'
  final Map<String, dynamic>? metadata; // Thêm metadata cho các loại tin nhắn khác nhau

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.type,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'metadata': metadata,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] ?? '',
      isUser: json['isUser'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
      type: json['type'],
      metadata: json['metadata'],
    );
  }

  // Copy with method
  ChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    String? type,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(text: $text, isUser: $isUser, timestamp: $timestamp, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.text == text &&
        other.isUser == isUser &&
        other.timestamp == timestamp &&
        other.type == type;
  }

  @override
  int get hashCode {
    return text.hashCode ^
        isUser.hashCode ^
        timestamp.hashCode ^
        (type?.hashCode ?? 0);
  }
} 