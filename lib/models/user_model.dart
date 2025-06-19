class UserModel {
  final String username;
  final int dailyGiftsSent;
  final int totalGiftsSent;
  final int totalGiftsReceived;
  final DateTime lastGiftDate;
  final List<String> sentGiftIds;
  final List<String> receivedGiftIds;

  UserModel({
    required this.username,
    this.dailyGiftsSent = 0,
    this.totalGiftsSent = 0,
    this.totalGiftsReceived = 0,
    DateTime? lastGiftDate,
    List<String>? sentGiftIds,
    List<String>? receivedGiftIds,
  })  : lastGiftDate = lastGiftDate ?? DateTime.now(),
        sentGiftIds = sentGiftIds ?? [],
        receivedGiftIds = receivedGiftIds ?? [];

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'dailyGiftsSent': dailyGiftsSent,
      'totalGiftsSent': totalGiftsSent,
      'totalGiftsReceived': totalGiftsReceived,
      'lastGiftDate': lastGiftDate.millisecondsSinceEpoch,
      'sentGiftIds': sentGiftIds,
      'receivedGiftIds': receivedGiftIds,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'],
      dailyGiftsSent: json['dailyGiftsSent'] ?? 0,
      totalGiftsSent: json['totalGiftsSent'] ?? 0,
      totalGiftsReceived: json['totalGiftsReceived'] ?? 0,
      lastGiftDate: DateTime.fromMillisecondsSinceEpoch(json['lastGiftDate']),
      sentGiftIds: List<String>.from(json['sentGiftIds'] ?? []),
      receivedGiftIds: List<String>.from(json['receivedGiftIds'] ?? []),
    );
  }

  UserModel copyWith({
    String? username,
    int? dailyGiftsSent,
    int? totalGiftsSent,
    int? totalGiftsReceived,
    DateTime? lastGiftDate,
    List<String>? sentGiftIds,
    List<String>? receivedGiftIds,
  }) {
    return UserModel(
      username: username ?? this.username,
      dailyGiftsSent: dailyGiftsSent ?? this.dailyGiftsSent,
      totalGiftsSent: totalGiftsSent ?? this.totalGiftsSent,
      totalGiftsReceived: totalGiftsReceived ?? this.totalGiftsReceived,
      lastGiftDate: lastGiftDate ?? this.lastGiftDate,
      sentGiftIds: sentGiftIds ?? List.from(this.sentGiftIds),
      receivedGiftIds: receivedGiftIds ?? List.from(this.receivedGiftIds),
    );
  }

  bool canSendFreeGift() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastGiftDay = DateTime(lastGiftDate.year, lastGiftDate.month, lastGiftDate.day);
    
    if (today.isAfter(lastGiftDay)) {
      return true; // New day, can send free gift
    }
    
    return dailyGiftsSent == 0; // Same day, check if already sent
  }

  @override
  String toString() {
    return 'UserModel(username: $username, dailyGiftsSent: $dailyGiftsSent, totalSent: $totalGiftsSent, totalReceived: $totalGiftsReceived)';
  }
}