import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/notification_service.dart';
import '../../features/target_products/services/price_scraper_service.dart';
import '../../features/target_products/model/product_model.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      final prefs = await SharedPreferences.getInstance();
      // Use same key as TargetProductsViewModel ('target_products_cache')
      final String? productsJsonStr = prefs.getString('target_products_cache');
      
      if (productsJsonStr == null || productsJsonStr.isEmpty) return true;

      List<ProductModel> products = (jsonDecode(productsJsonStr) as List)
          .map((item) => ProductModel.fromJson(item))
          .toList();

      final scraper = PriceScraperService();
      final notifications = NotificationService();
      await notifications.init();
      
      bool updatedSomething = false;
      int reachedCount = 0;
      const int progressNotifId = 997;
      int loopIdx = 0;

      // 🔔 إشعار بدء فحص الخلفية
      await notifications.showProgressNotification(
        id: progressNotifId,
        current: 0,
        total: products.length,
        currentProductName: '',
      );

      for (var product in products) {
        if (product.isAnalyzing) continue;

        final shortName = product.title.length > 30
            ? '${product.title.substring(0, 30)}...'
            : product.title;

        await notifications.showProgressNotification(
          id: progressNotifId,
          current: loopIdx,
          total: products.length,
          currentProductName: shortName,
        );
        loopIdx++;

        try {
          // ✅ HTTP فقط — WebView مبيشتغلش في Workmanager background isolate
          final result = await scraper.scrapeWithHttpOnly(product.originalUrl);
          if (result != null && result['price'] != null) {
            List<ProductSeller> sellers = [];
            if (result['sellers'] != null && result['sellers'] is List) {
              sellers = (result['sellers'] as List)
                  .where((s) => s != null && s is Map)
                  .map((s) => ProductSeller.fromJson(Map<String, dynamic>.from(s)))
                  .toList();
            }
            
            // Sort sellers to find absolute lowest
            final double mainPrice = (result['price'] as num).toDouble();
            final bool primaryExists = sellers.any((s) => (s.price - mainPrice).abs() < 0.01);
            if (!primaryExists && mainPrice > 0) {
              sellers.add(ProductSeller(name: product.storeName, price: mainPrice));
            }
            
            sellers.sort((a, b) => a.price.compareTo(b.price));
            final double lowestPrice = sellers.isNotEmpty ? sellers.first.price : mainPrice;

            if (lowestPrice <= product.targetPrice && (product.currentPrice > product.targetPrice || product.currentPrice == 0)) {
              reachedCount++;
              final title = '🎉 مبروك! وصل سعرك المفضل للهدف';
              final body = 'المنتج \"${_shortenTitle(product.title)}\" متاح الآن بسعر ${lowestPrice.toStringAsFixed(2)} ريال في موقع ${product.storeName}. اطلبه الآن!';

              
              await notifications.showNotification(
                id: product.id.hashCode,
                title: title,
                body: body,
              );
              await _saveNotificationToHistory(title, body);
            }

            final updatedProduct = product.copyWith(
              currentPrice: lowestPrice,
              sellers: sellers,
              lastChecked: DateTime.now(),
              isAnalyzing: false,
              error: null,
            );
            
            int index = products.indexWhere((p) => p.id == product.id);
            if (index != -1) {
              products[index] = updatedProduct;
              updatedSomething = true;
            }
          }
        } catch (e) {
          debugPrint('Error checking product ${product.id}: $e');
        }
      }

      // إلغاء إشعار التقدم
      await notifications.dismissNotification(progressNotifId);

      if (updatedSomething) {
        // إشعار نهائي
        final String summaryTitle = '✅ اكتمل الفحص الدوري';
        final StringBuffer sb = StringBuffer();
        sb.write('تم فحص ${products.length} منتجات.');
        if (reachedCount > 0) sb.write('\n🎯 $reachedCount منتج وصل للسعر المستهدف!');
        final String summaryBody = sb.toString();

        await notifications.showNotification(
          id: 999,
          title: summaryTitle,
          body: summaryBody,
        );
        await _saveNotificationToHistory(summaryTitle, summaryBody);
      }

      return true;
    } catch (e) {
      return false;
    }
  });
}

Future<void> _saveNotificationToHistory(String title, String body) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    const String storageKey = 'notifications_history';
    final String? data = prefs.getString(storageKey);
    List<dynamic> notifications = [];
    if (data != null) {
      notifications = jsonDecode(data);
    }
    
    final newNotification = {
      'title': title,
      'body': body,
      'time': DateTime.now().toIso8601String(),
      'isRead': false,
    };
    
    notifications.insert(0, newNotification);
    
    // Limit history to last 50 notifications to save space
    if (notifications.length > 50) {
      notifications = notifications.sublist(0, 50);
    }
    
    await prefs.setString(storageKey, jsonEncode(notifications));
  } catch (e) {
    debugPrint('Error saving notification history: $e');
  }
}

String _shortenTitle(String title) {
  if (title.length <= 30) return title;
  return '${title.substring(0, 27)}...';
}
