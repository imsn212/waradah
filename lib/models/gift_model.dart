enum GiftType { emoji, image, custom }

class Gift {
  final String id;
  final GiftType type;
  final String content; // Emoji text or base64 image data
  final String sender;
  final String recipient;
  final DateTime timestamp;
  final double price;
  final bool isFree;

  Gift({
    required this.id,
    required this.type,
    required this.content,
    required this.sender,
    required this.recipient,
    required this.timestamp,
    this.price = 0.0,
    this.isFree = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'content': content,
      'sender': sender,
      'recipient': recipient,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'price': price,
      'isFree': isFree,
    };
  }

  factory Gift.fromJson(Map<String, dynamic> json) {
    return Gift(
      id: json['id'],
      type: GiftType.values[json['type']],
      content: json['content'],
      sender: json['sender'],
      recipient: json['recipient'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      price: json['price']?.toDouble() ?? 0.0,
      isFree: json['isFree'] ?? true,
    );
  }

  Gift copyWith({
    String? id,
    GiftType? type,
    String? content,
    String? sender,
    String? recipient,
    DateTime? timestamp,
    double? price,
    bool? isFree,
  }) {
    return Gift(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      sender: sender ?? this.sender,
      recipient: recipient ?? this.recipient,
      timestamp: timestamp ?? this.timestamp,
      price: price ?? this.price,
      isFree: isFree ?? this.isFree,
    );
  }

  @override
  String toString() {
    return 'Gift(id: $id, type: $type, sender: $sender, recipient: $recipient, price: $price)';
  }
}