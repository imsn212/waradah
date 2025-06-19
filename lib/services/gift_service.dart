import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gift_model.dart';
import '../models/user_model.dart';

class GiftService {
  static const String _giftsKey = 'gifts';
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'current_user';

  // Singleton pattern
  static final GiftService _instance = GiftService._internal();
  factory GiftService() => _instance;
  GiftService._internal();

  // Initialize with sample data
  Future<void> initializeApp() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if first time setup
    if (!prefs.containsKey(_currentUserKey)) {
      await _setupSampleData();
    }
  }

  Future<void> _setupSampleData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Create sample users
    final sampleUsers = [
      UserModel(username: 'alice_wonder'),
      UserModel(username: 'bob_builder'),
      UserModel(username: 'charlie_brown'),
      UserModel(username: 'diana_prince'),
      UserModel(username: 'eve_online'),
    ];

    // Set current user as first user
    await prefs.setString(_currentUserKey, 'alice_wonder');

    // Save sample users
    final usersJson = sampleUsers.map((user) => user.toJson()).toList();
    await prefs.setString(_usersKey, jsonEncode(usersJson));

    // Create sample gifts
    final sampleGifts = _createSampleGifts();
    final giftsJson = sampleGifts.map((gift) => gift.toJson()).toList();
    await prefs.setString(_giftsKey, jsonEncode(giftsJson));
  }

  List<Gift> _createSampleGifts() {
    final giftEmojis = ['🎁', '🌹', '💎', '🍰', '🎈', '🌟', '💝', '🎉'];
    final usernames = ['alice_wonder', 'bob_builder', 'charlie_brown', 'diana_prince', 'eve_online'];
    final gifts = <Gift>[];

    for (int i = 0; i < 15; i++) {
      final random = Random();
      gifts.add(Gift(
        id: 'gift_$i',
        type: GiftType.emoji,
        content: giftEmojis[random.nextInt(giftEmojis.length)],
        sender: usernames[random.nextInt(usernames.length)],
        recipient: usernames[random.nextInt(usernames.length)],
        timestamp: DateTime.now().subtract(Duration(days: random.nextInt(7))),
        isFree: random.nextBool(),
        price: !random.nextBool() ? random.nextDouble() * 10 : 0.0,
      ));
    }

    return gifts;
  }

  // Current user methods
  Future<String?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserKey);
  }

  Future<void> setCurrentUser(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, username);
  }

  // User management
  Future<List<UserModel>> getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    
    if (usersJson == null) return [];
    
    final List<dynamic> usersList = jsonDecode(usersJson);
    return usersList.map((json) => UserModel.fromJson(json)).toList();
  }

  Future<UserModel?> getUser(String username) async {
    final users = await getAllUsers();
    try {
      return users.firstWhere((user) => user.username == username);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveUser(UserModel user) async {
    final users = await getAllUsers();
    final index = users.indexWhere((u) => u.username == user.username);
    
    if (index >= 0) {
      users[index] = user;
    } else {
      users.add(user);
    }

    final prefs = await SharedPreferences.getInstance();
    final usersJson = users.map((user) => user.toJson()).toList();
    await prefs.setString(_usersKey, jsonEncode(usersJson));
  }

  // Gift management
  Future<List<Gift>> getAllGifts() async {
    final prefs = await SharedPreferences.getInstance();
    final giftsJson = prefs.getString(_giftsKey);
    
    if (giftsJson == null) return [];
    
    final List<dynamic> giftsList = jsonDecode(giftsJson);
    return giftsList.map((json) => Gift.fromJson(json)).toList();
  }

  Future<List<Gift>> getSentGifts(String username) async {
    final gifts = await getAllGifts();
    return gifts.where((gift) => gift.sender == username).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<List<Gift>> getReceivedGifts(String username) async {
    final gifts = await getAllGifts();
    return gifts.where((gift) => gift.recipient == username).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<bool> sendGift(Gift gift) async {
    try {
      // Get current gifts
      final gifts = await getAllGifts();
      gifts.add(gift);

      // Update sender stats
      final sender = await getUser(gift.sender);
      if (sender != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final lastGiftDay = DateTime(sender.lastGiftDate.year, sender.lastGiftDate.month, sender.lastGiftDate.day);

        int newDailyCount = sender.dailyGiftsSent;
        if (today.isAfter(lastGiftDay)) {
          newDailyCount = 1; // Reset for new day
        } else {
          newDailyCount += 1;
        }

        final updatedSender = sender.copyWith(
          dailyGiftsSent: newDailyCount,
          totalGiftsSent: sender.totalGiftsSent + 1,
          lastGiftDate: now,
          sentGiftIds: [...sender.sentGiftIds, gift.id],
        );
        await saveUser(updatedSender);
      }

      // Update recipient stats
      final recipient = await getUser(gift.recipient);
      if (recipient != null) {
        final updatedRecipient = recipient.copyWith(
          totalGiftsReceived: recipient.totalGiftsReceived + 1,
          receivedGiftIds: [...recipient.receivedGiftIds, gift.id],
        );
        await saveUser(updatedRecipient);
      }

      // Save gifts
      final prefs = await SharedPreferences.getInstance();
      final giftsJson = gifts.map((gift) => gift.toJson()).toList();
      await prefs.setString(_giftsKey, jsonEncode(giftsJson));

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending gift: $e');
      }
      return false;
    }
  }

  Future<bool> canSendFreeGift(String username) async {
    final user = await getUser(username);
    return user?.canSendFreeGift() ?? false;
  }

  Future<int> getDailyGiftsRemaining(String username) async {
    final user = await getUser(username);
    if (user == null) return 1;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastGiftDay = DateTime(user.lastGiftDate.year, user.lastGiftDate.month, user.lastGiftDate.day);
    
    if (today.isAfter(lastGiftDay)) {
      return 1; // New day, 1 free gift available
    }
    
    return user.dailyGiftsSent >= 1 ? 0 : 1;
  }

  // Utility methods
  String generateGiftId() {
    return 'gift_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  double calculatePriceWithCommission(double price) {
    return price * 1.1; // Add 10% commission
  }
}