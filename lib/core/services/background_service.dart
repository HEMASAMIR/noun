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
      final String? productsJsonStr = prefs.getString('target_products_cache');
      if (productsJsonStr == null || productsJsonStr.isEmpty) return true;

      List<ProductModel> products = (jsonDecode(productsJsonStr) as List)
          .map((item) => ProductModel.fromJson(item))
          .toList();

      // ✅ ذكاء في الفحص: ترتيب المنتجات ليتم فحص الأقدم (التي لم تفحص مؤخراً) أولاً
      // هذا يضمن أنه لو توقف الفحص في النصف بسبب انتهاء الوقت، سيبدأ المرة القادمة بالمنتجات التي لم تُفحص
      products.sort((a, b) {
        if (a.lastChecked == null && b.lastChecked != null) return -1;
        if (a.lastChecked != null && b.lastChecked == null) return 1;
        if (a.lastChecked == null && b.lastChecked == null) return 0;
        return a.lastChecked!.compareTo(b.lastChecked!);
      });

      // اقرأ إعداد التوازي من الـ settings
      final int concurrency = prefs.getInt('concurrent_products') ?? 1;

      final scraper = PriceScraperService();
      final notifications = NotificationService();
      await notifications.init();

      bool updatedSomething = false;
      int reachedCount = 0;
      const int progressNotifId = 997;
      List<String> droppedProductsStrings = [];

      // فحص الكل بـ concurrent chunks — بدون أي delay بين الـ chunks
      for (int start = 0; start < products.length; start += concurrency) {
        final chunkEnd = (start + concurrency).clamp(0, products.length);
        final chunk = products.sublist(start, chunkEnd)
            .where((p) => !p.isAnalyzing)
            .toList();
        if (chunk.isEmpty) continue;

        final firstName = chunk.first.title.length > 30
            ? '${chunk.first.title.substring(0, 30)}...'
            : chunk.first.title;

        // 🔔 إشعار تقدم قبل بدء الـ chunk
        await notifications.showProgressNotification(
          id: progressNotifId,
          checkedSoFar: start,
          total: products.length,
          currentName: firstName,
        );

        // ✅ فحص كل المنتجات في الـ chunk بالتوازي
        final futures = chunk.map((product) async {
          try {
            final result = await scraper.scrapeWithHttpOnly(product.originalUrl);
            if (result == null || result['price'] == null) return;

            List<ProductSeller> sellers = [];
            if (result['sellers'] != null && result['sellers'] is List) {
              sellers = (result['sellers'] as List)
                  .where((s) => s != null && s is Map)
                  .map((s) => ProductSeller.fromJson(Map<String, dynamic>.from(s)))
                  .toList();
            }

            final double mainPrice = (result['price'] as num).toDouble();
            if (!sellers.any((s) => (s.price - mainPrice).abs() < 0.01) && mainPrice > 0) {
              sellers.add(ProductSeller(name: product.storeName, price: mainPrice));
            }
            sellers.sort((a, b) => a.price.compareTo(b.price));
            final double lowestPrice = sellers.isNotEmpty ? sellers.first.price : mainPrice;
            final double oldPrice = product.currentPrice;

            if (lowestPrice <= product.targetPrice &&
                (oldPrice > product.targetPrice || oldPrice <= 0)) {
              reachedCount++;
              double dropPercent = 0;
              if (oldPrice > 0) {
                 dropPercent = ((oldPrice - lowestPrice) / oldPrice) * 100;
              } else if (product.priceHistory.isNotEmpty && product.priceHistory.first > lowestPrice) {
                 dropPercent = ((product.priceHistory.first - lowestPrice) / product.priceHistory.first) * 100;
              }
              String percentText = dropPercent > 0 ? ' (-${dropPercent.toStringAsFixed(0)}%)' : '';
              droppedProductsStrings.add('🎯 ${_shortenTitle(product.title)}$percentText بـ ${lowestPrice.toStringAsFixed(0)}');
            } else if (oldPrice > 0 && lowestPrice < oldPrice) {
              double dropPercent = ((oldPrice - lowestPrice) / oldPrice) * 100;
              if (dropPercent >= 1) {
                 droppedProductsStrings.add('🔽 ${_shortenTitle(product.title)} (-${dropPercent.toStringAsFixed(0)}%) بـ ${lowestPrice.toStringAsFixed(0)}');
              }
            }

            final idx = products.indexWhere((p) => p.id == product.id);
            if (idx != -1) {
              products[idx] = product.copyWith(
                currentPrice: lowestPrice,
                sellers: sellers,
                lastChecked: DateTime.now(),
                isAnalyzing: false,
                error: null,
              );
              updatedSomething = true;
            }
          } catch (e) {
            debugPrint('Background: error checking ${product.id}: $e');
          }
        });

        await Future.wait(futures);
        // ✅ لا يوجد delay — ينتقل للـ chunk التالي فوراً

        // حفظ المنتجات في الذاكرة أولاً بأول لكي لا نفقد البيانات لو توقفت العملية أو انتهى الوقت
        if (updatedSomething) {
          await prefs.setString(
            'target_products_cache',
            jsonEncode(products.map((p) => p.toJson()).toList()),
          );
        }

        // إشعار تقدم بعد اكتمال الـ chunk
        await notifications.showProgressNotification(
          id: progressNotifId,
          checkedSoFar: chunkEnd,
          total: products.length,
          currentName: firstName,
        );
      }


      // إلغاء إشعار التقدم
      await notifications.dismissNotification(progressNotifId);

      if (updatedSomething) {
        final String summaryTitle = reachedCount > 0 ? '🎉 $reachedCount منتج وصل للمطلوب!' : 'تحديث أسعار المنتجات';
        final StringBuffer sb = StringBuffer();
        
        if (droppedProductsStrings.isNotEmpty) {
          sb.write(droppedProductsStrings.join('\n'));
        } else {
          sb.write('تم فحص ${products.length} منتجات ولم يتم رصد تخفيضات جديدة.');
        }
        
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
