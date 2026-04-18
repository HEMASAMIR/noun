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

  // Load products from storage
  await targetProductsViewModel.loadFromStorage();
  // Load settings from storage
  await settingsViewModel.loadSettings();

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
