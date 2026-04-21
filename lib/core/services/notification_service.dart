import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Request permission for Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap logic here if needed
      },
    );
  }

  /// إشعار تقدم حي (يتحدث مع كل منتج)
  Future<void> showProgressNotification({
    required int id,
    required int current,
    required int total,
    required String currentProductName,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'wasfy_progress_channel',
      'Wasfy - تقدم الفحص الدوري',
      channelDescription: 'إشعار مباشر بتقدم الفحص الدوري للمنتجات',
      importance: Importance.low,
      priority: Priority.low,
      showWhen: false,
      ongoing: true,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: total,
      progress: current,
      indeterminate: current == 0,
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    final String body = current == 0
        ? 'جاري بدء الفحص...'
        : 'جاري الفحص ($current/$total): $currentProductName';

    await _notificationsPlugin.show(id, '🔄 الفحص الدوري', body, details);
  }

  /// إلغاء إشعار
  Future<void> dismissNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'wasfy_products_channel',
      'Wasfy - تنبيهات الأسعار',
      channelDescription: 'قناة تنبيهات الوصول للسعر المستهدف للمنتجات',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
