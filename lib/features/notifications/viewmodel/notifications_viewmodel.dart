import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationItem {
  final String title;
  final String body;
  final DateTime time;
  bool isRead;

  NotificationItem({
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'time': time.toIso8601String(),
    'isRead': isRead,
  };

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
    title: json['title'],
    body: json['body'],
    time: DateTime.parse(json['time']),
    isRead: json['isRead'] ?? false,
  );
}

class NotificationsViewModel extends ChangeNotifier {
  final List<NotificationItem> _notifications = [];
  static const String _storageKey = 'notifications_history';

  NotificationsViewModel() {
    loadFromStorage();
  }

  List<NotificationItem> get notifications => _notifications;

  bool get hasNotifications => _notifications.isNotEmpty;

  void addNotification({required String title, required String body}) {
    _notifications.insert(
      0,
      NotificationItem(
        title: title,
        body: body,
        time: DateTime.now(),
      ),
    );
    
    // Show real system notification
    NotificationService().showNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
    );
    
    notifyListeners();
    _saveToStorage();
  }

  Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_storageKey);
      if (data != null) {
        final List<dynamic> decoded = jsonDecode(data);
        _notifications.clear();
        _notifications.addAll(decoded.map((json) => NotificationItem.fromJson(json)));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(_notifications.map((n) => n.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }

  void markAsRead(int index) {
    _notifications[index].isRead = true;
    notifyListeners();
    _saveToStorage();
  }

  void removeNotification(int index) {
    if (index >= 0 && index < _notifications.length) {
      _notifications.removeAt(index);
      notifyListeners();
      _saveToStorage();
    }
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
    _saveToStorage();
  }
}
