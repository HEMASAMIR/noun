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

  /// إشعار تقدم حي — يتحدث مع كل منتج يُفحص
  /// [checkedSoFar] = عدد المنتجات اللي اتفحصت فعلاً
  /// [total]        = إجمالي عدد المنتجات
  /// [currentName]  = اسم المنتج اللي بيتفحص الحين
  Future<void> showProgressNotification({
    required int id,
    required int checkedSoFar,
    required int total,
    required String currentName,
  }) async {
    if (total <= 0) return;

    // النسبة على أساس المنتجات اللي خلصت
    final int percent = ((checkedSoFar / total) * 100).round();
    final int remaining = total - checkedSoFar;
    final int currentNum = checkedSoFar + 1; // المنتج الحالي (1-indexed)

    // عنوان: رقم المنتج الحالي / الكل — نسبة%
    final String title = '🔄 فحص ($currentNum/$total) — $percent٪';

    // اسم المنتج بس — واحدهم في كل مرة
    final String shortName = currentName.length > 28
        ? '${currentName.substring(0, 28)}...'
        : currentName;
    final String body = '📦 $shortName\n'
        'باقي $remaining منتج';

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
      progress: checkedSoFar,   // ← شريط التقدم يتحرك مع كل منتج
      indeterminate: false,     // ← دايماً محدد ومش ثابت
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(id, title, body, details);
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

    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'wasfy_products_channel',
      'Wasfy - تنبيهات الأسعار',
      channelDescription: 'قناة تنبيهات الوصول للسعر المستهدف للمنتجات',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      styleInformation: BigTextStyleInformation(body),
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: const DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
