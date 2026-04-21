import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../target_products/viewmodel/target_products_viewmodel.dart';
import '../view/periodic_report_screen.dart';
import 'package:workmanager/workmanager.dart';
import '../../../core/services/background_service.dart';
import '../../../core/services/notification_service.dart';
class SettingsViewModel extends ChangeNotifier {
  static const String _keyForegroundService = 'foreground_service';
  static const String _keyConcurrentProducts = 'concurrent_products';
  static const String _keyCheckIntervalValue = 'check_interval_value';
  static const String _keyCheckIntervalUnit = 'check_interval_unit';
  static const String _keyDarkMode = 'dark_mode';

  bool _isForegroundServiceEnabled = true;
  int _selectedConcurrentProducts = 2;
  double _checkIntervalValue = 2.0;
  String _checkIntervalUnit = 'ساعات';
  bool _isDarkMode = false;
  bool _isLoaded = false;

  /// مرجع لـ TargetProductsViewModel لتحديث الـ foreground timer
  TargetProductsViewModel? targetProductsViewModel;

  bool get isForegroundServiceEnabled => _isForegroundServiceEnabled;
  int get selectedConcurrentProducts => _selectedConcurrentProducts;
  double get checkIntervalValue => _checkIntervalValue;
  String get checkIntervalUnit => _checkIntervalUnit;
  bool get isDarkMode => _isDarkMode;
  bool get isLoaded => _isLoaded;

  SettingsViewModel();

  String _appVersion = '1.0.0';
  String get appVersion => _appVersion;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isForegroundServiceEnabled = prefs.getBool(_keyForegroundService) ?? true;
    _selectedConcurrentProducts = prefs.getInt(_keyConcurrentProducts) ?? 2;
    _checkIntervalValue = prefs.getDouble(_keyCheckIntervalValue) ?? 2.0;
    _checkIntervalUnit = prefs.getString(_keyCheckIntervalUnit) ?? 'ساعات';
    _isDarkMode = prefs.getBool(_keyDarkMode) ?? false;
    _isLoaded = true;
    
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
    } catch (e) {
      _appVersion = '1.0.0';
    }
    
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
    _notifySettingChanged('الوضع الليلي', value ? 'مفعل' : 'معطل');
    notifyListeners();
  }

  Future<void> toggleForegroundService(bool value) async {
    _isForegroundServiceEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyForegroundService, value);
    await _updateWorkmanagerRegistration();
    if (!value) {
      targetProductsViewModel?.stopPeriodicTimer();
    } else {
      _restartForegroundTimer();
    }
    _notifySettingChanged('وضع الخدمة الدائمة', value ? 'مفعل' : 'معطل');
    notifyListeners();
  }

  Future<void> setConcurrentProducts(int count) async {
    _selectedConcurrentProducts = count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyConcurrentProducts, count);
    await _updateWorkmanagerRegistration();
    _notifySettingChanged('عدد المنتجات المتزامنة', '$count منتجات');
    notifyListeners();
  }

  Future<void> setCheckIntervalValue(double value) async {
    _checkIntervalValue = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyCheckIntervalValue, value);
    await _updateWorkmanagerRegistration();
    _restartForegroundTimer(); // ✅ حدّث الـ foreground timer فوراً
    _notifySettingChanged('فترة الفحص', '${value.toInt()} $_checkIntervalUnit');
    notifyListeners();
  }

  Future<void> setCheckIntervalUnit(String unit) async {
    _checkIntervalUnit = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCheckIntervalUnit, unit);
    await _updateWorkmanagerRegistration();
    _restartForegroundTimer(); // ✅ حدّث الـ foreground timer فوراً
    _notifySettingChanged('وحدة الفحص', unit);
    notifyListeners();
  }

  void _restartForegroundTimer() {
    if (!_isForegroundServiceEnabled) return;
    final int v = _checkIntervalValue.toInt().clamp(1, 999);
    final Duration interval;
    switch (_checkIntervalUnit) {
      case 'دقائق': interval = Duration(minutes: v); break;
      case 'أيام':  interval = Duration(days: v); break;
      default:      interval = Duration(hours: v);
    }
    targetProductsViewModel?.startPeriodicTimer(interval);
  }

  void _notifySettingChanged(String settingName, String newValue) {
    NotificationService().showNotification(
      id: 101, // Fixed ID for settings updates
      title: '⚙️ تم تحديث الإعدادات',
      body: 'تم تغيير "$settingName" إلى $newValue بنجاح.',
    );
  }

  // Action Methods
  Future<void> checkAllProductsNow(BuildContext context) async {
    final targetViewModel = Provider.of<TargetProductsViewModel>(context, listen: false);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await targetViewModel.refreshAllProducts();
      
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        NotificationService().showNotification(
          id: 102,
          title: '🔄 تحديث الأسعار',
          body: 'تم تحديث جميع أسعار المنتجات المتابعة بنجاح بنجاح.',
        );
      }
    } catch (e) {
       if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الفحص: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> openPeriodicReport(BuildContext context) async {
    // Navigate to actual screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PeriodicReportScreen()),
    );
  }
  Future<void> _updateWorkmanagerRegistration() async {
    if (!_isForegroundServiceEnabled) {
      await Workmanager().cancelAll();
      return;
    }

    Duration frequency;
    switch (_checkIntervalUnit) {
      case 'دقائق':
        frequency = Duration(minutes: _checkIntervalValue.toInt().clamp(15, 60)); 
        break;
      case 'ساعات':
        frequency = Duration(hours: _checkIntervalValue.toInt());
        break;
      case 'أيام':
        frequency = Duration(days: _checkIntervalValue.toInt());
        break;
      default:
        frequency = const Duration(hours: 2);
    }

    await Workmanager().registerPeriodicTask(
      "periodic-check-task",
      "periodicCheck",
      frequency: frequency,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}
