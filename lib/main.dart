import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/target_products/view/target_products_screen.dart';
import 'features/notifications/view/notifications_screen.dart';
import 'features/settings/view/settings_screen.dart';
import 'features/splash/view/splash_screen.dart';

import 'features/target_products/viewmodel/target_products_viewmodel.dart';
import 'features/notifications/viewmodel/notifications_viewmodel.dart';

import 'features/settings/viewmodel/settings_viewmodel.dart';
import 'core/services/notification_service.dart';
import 'package:workmanager/workmanager.dart';
import 'core/services/background_service.dart';
import 'core/widgets/network_status_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications service
  if (!kIsWeb) {
    await NotificationService().init();
  }

  // Initialize background tasks (Android/iOS only)
  if (!kIsWeb) {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

    await Workmanager().registerPeriodicTask(
      "wasfy_price_check",
      "periodicPriceCheck",
      frequency: const Duration(hours: 1),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  final notificationsViewModel = NotificationsViewModel();
  final targetProductsViewModel = TargetProductsViewModel(
    notificationsViewModel: notificationsViewModel,
  );
  final settingsViewModel = SettingsViewModel();
  // ✅ اربط الـ settings بالـ timer
  settingsViewModel.targetProductsViewModel = targetProductsViewModel;


  // Load products from storage
  await targetProductsViewModel.loadFromStorage();
  // Load settings from storage
  await settingsViewModel.loadSettings();

  // ✅ ابدأ الـ foreground timer بالوقت المحدد من الإعدادات
  if (!kIsWeb) {
    final Duration foregroundInterval = _buildIntervalDuration(
      settingsViewModel.checkIntervalValue,
      settingsViewModel.checkIntervalUnit,
    );
    targetProductsViewModel.startPeriodicTimer(foregroundInterval);
  }


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: notificationsViewModel),
        ChangeNotifierProvider.value(value: targetProductsViewModel),
        ChangeNotifierProvider.value(value: settingsViewModel),
      ],
      child: const MyApp(),
    ),
  );
}

Duration _buildIntervalDuration(double value, String unit) {
  final int v = value.toInt().clamp(1, 999);
  switch (unit) {
    case 'دقائق': return Duration(minutes: v);
    case 'أيام':  return Duration(days: v);
    default:      return Duration(hours: v); // ساعات
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsViewModel>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'Wasfy',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ar', 'AE')],
          locale: const Locale('ar', 'AE'),
          builder: (context, child) {
            return NetworkStatusWrapper(child: child ?? const SizedBox());
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const TargetProductsScreen(),
    const NotificationsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'وصل للهدف',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'الإشعارات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}


// https://www.noon.com/saudi-ar/galaxy-a17-dual-sim-gray-6gb-128gb-5g-middle-east-version/N70202453V/p/?o=f750ad5cc64c591a&shareId=85617582-f282-47ad-b5e9-573106319637 
// https://www.noon.com/saudi-ar/galaxy-a17-dual-sim-blue-4gb-128gb-5g-middle-east-version/N70202449V/p/?o=b8341860e905224e&shareId=f680a6ce-8572-458d-9190-2330f98fffa4 
// https://www.noon.com/saudi-ar/galaxy-a17-dual-sim-black-4gb-128gb-5g-middle-east-version/N70202450V/p/?o=f5a867026dfa6fcb&shareId=4699ce9a-5964-4e47-8a55-424bdd9dc7c3

// https://www.noon.com/saudi-ar/galaxy-a17-dual-sim-gray-4gb-128gb-5g-middle-east-version/N70202448V/p/?o=ca0aa2ee134b456c&shareId=0da43345-af8b-449e-b077-afd21b0e0299
/**
 * https://www.noon.com/saudi-ar/x9c-dual-sim-5g-sunrise-orange-8gb-ram-256gb-middle-east-version/N70167846V/p/?o=e65a2fe5bad125fb&shareId=fd85cece-656e-4176-8c63-dd2e63e65ac3
 * https://www.noon.com/saudi-ar/x9c-dual-sim-5g-titanium-black-8gb-ram-256gb-middle-east-version/N70167844V/p/?o=b0ed9e3e842a788f&shareId=a9167acc-a97f-4ab5-8043-bdb436cee95a
 * https://www.noon.com/saudi-ar/x9c-dual-sim-jade-cyan-12gb-ram-256gb-5g-middle-east-version/N70127356V/p/?o=da151580c4b2d47f&shareId=02febb7e-a129-43d1-8c99-b006fc7bca89
 * 
 * https://www.noon.com/saudi-ar/x9c-dual-sim-titanium-black-12gb-ram-256gb-5g-middle-east-version/N70127355V/p/?o=e58cb93a321fa56e&shareId=bfeff241-f6fa-49a1-9f4d-1e638d006bf6
 * 
 * https://www.noon.com/saudi-ar/x9c-dual-sim-sunrise-orange-12gb-ram-256gb-5g-middle-east-version/N70127357V/p/?o=fd4a2978ad7327df&shareId=f920d522-12fc-4928-9ff1-639ff8f25ff2
 * 
 * https://www.noon.com/saudi-ar/x9c-dual-sim-titanium-purple-12gb-ram-256gb-5g-middle-east-version/N70127388V/p/?o=bc0c11f99bd216de&shareId=24571365-6be7-4dda-a849-65ee7018c413
 */