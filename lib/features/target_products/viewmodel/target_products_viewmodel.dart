import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import '../model/product_model.dart';
import '../../notifications/viewmodel/notifications_viewmodel.dart';
import '../services/price_scraper_service.dart';
import '../services/google_shopping_service.dart';
import '../../../core/services/notification_service.dart';

enum ProductSortOption {
  newest,
  oldest,
  priceHighToLow,
  priceLowToHigh,
  nameAZ,
  nameZA,
  lastChecked,
  notAvailable,
}

class TargetProductsViewModel extends ChangeNotifier {
  final NotificationsViewModel? notificationsViewModel;
  String _searchQuery = '';
  final List<ProductModel> _products = [];
  static const String _storageKey = 'target_products_cache';

  Timer? _periodicTimer;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  // تقدم الفحص الدوري
  int _refreshCheckedCount = 0;
  int _refreshTotalCount = 0;
  String _refreshCurrentName = '';

  int get refreshCheckedCount => _refreshCheckedCount;
  int get refreshTotalCount => _refreshTotalCount;
  String get refreshCurrentName => _refreshCurrentName;

  // آخر منتج اتحدث (عشان الأنيميشن)
  List<String> _lastUpdatedIds = [];
  List<String> get lastUpdatedIds => _lastUpdatedIds;
  Timer? _lastUpdatedClearTimer;

  // المنتجات الجاري تحديثها حاليا
  List<String> _currentlyRefreshingIds = [];
  List<String> get currentlyRefreshingIds => _currentlyRefreshingIds;

  ProductSortOption _currentSortOption = ProductSortOption.newest;
  DeliveryType? _currentDeliveryFilter;

  ProductSortOption get currentSortOption => _currentSortOption;
  DeliveryType? get currentDeliveryFilter => _currentDeliveryFilter;

  List<ProductModel> get _filteredProducts {
    List<ProductModel> filtered = _products;

    // 1. Search Query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (p) =>
                p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                p.storeName.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    // 2. Delivery Filter
    if (_currentDeliveryFilter != null) {
      filtered = filtered
          .where((p) => p.deliveryType == _currentDeliveryFilter)
          .toList();
    }

    // 3. Sorting
    filtered = _sortProducts(filtered, _currentSortOption);

    return filtered;
  }

  List<ProductModel> _sortProducts(
    List<ProductModel> list,
    ProductSortOption option,
  ) {
    final result = List<ProductModel>.from(list);
    switch (option) {
      case ProductSortOption.newest:
        result.sort((a, b) => b.timeAdded.compareTo(a.timeAdded));
        break;
      case ProductSortOption.oldest:
        result.sort((a, b) => a.timeAdded.compareTo(b.timeAdded));
        break;
      case ProductSortOption.priceHighToLow:
        result.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
        break;
      case ProductSortOption.priceLowToHigh:
        result.sort((a, b) => a.currentPrice.compareTo(b.currentPrice));
        break;
      case ProductSortOption.nameAZ:
        result.sort((a, b) => a.title.compareTo(b.title));
        break;
      case ProductSortOption.nameZA:
        result.sort((a, b) => b.title.compareTo(a.title));
        break;
      case ProductSortOption.lastChecked:
        result.sort((a, b) {
          if (a.lastChecked == null) return 1;
          if (b.lastChecked == null) return -1;
          return b.lastChecked!.compareTo(a.lastChecked!);
        });
        break;
      case ProductSortOption.notAvailable:
        result.sort((a, b) {
          if (a.error != null && b.error == null) return -1;
          if (a.error == null && b.error != null) return 1;
          return 0;
        });
        break;
    }
    return result;
  }

  void updateSortOption(ProductSortOption option) {
    _currentSortOption = option;
    notifyListeners();
  }

  void updateDeliveryFilter(DeliveryType? type) {
    _currentDeliveryFilter = type;
    notifyListeners();
  }

  List<ProductModel> get allProducts => _filteredProducts;
  List<ProductModel> get processingProducts =>
      _filteredProducts.where((p) => !p.hasReachedTarget).toList();
  List<ProductModel> get reachedTargetProducts =>
      _filteredProducts.where((p) => p.hasReachedTarget).toList();

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearchQuery() {
    _searchQuery = '';
    notifyListeners();
  }

  TargetProductsViewModel({this.notificationsViewModel});

  /// يبدأ تايمر foreground بالوقت المحدد من الإعدادات
  void startPeriodicTimer(Duration interval) {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(interval, (_) {
      debugPrint(
        '[ForegroundTimer] Triggering refresh after ${interval.inMinutes} min',
      );
      refreshAllProducts();
    });
    debugPrint(
      '[ForegroundTimer] Started with interval: ${interval.inSeconds}s',
    );
  }

  void stopPeriodicTimer() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    _lastUpdatedClearTimer?.cancel();
    super.dispose();
  }

  Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? productsJson = prefs.getString(_storageKey);
      if (productsJson != null) {
        final List<dynamic> decoded = jsonDecode(productsJson);
        _products.clear();
        _products.addAll(decoded.map((item) => ProductModel.fromJson(item)));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(
        _products.map((p) => p.toJson()).toList(),
      );
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Error saving products: $e');
    }
  }

  Future<void> fetchAndAddProduct(String url, double targetPrice) async {
    final String id = DateTime.now().millisecondsSinceEpoch.toString();

    // 1. Add Placeholder Product Immediately
    final placeholder = ProductModel(
      id: id,
      title: 'جاري التحليل الذكي...',
      storeName: 'قيد المراجعة',
      currentPrice: 0.0,
      targetPrice: targetPrice,
      deliveryType: DeliveryType.normal,
      imageUrl: '',
      timeAdded: DateTime.now(),
      originalUrl: url,
      isAnalyzing: true,
    );

    _products.insert(0, placeholder);
    notifyListeners();
    await _saveToStorage();

    // إشعار بدء التحليل
    notificationsViewModel?.addNotification(
      title: '⏳ جاري تحليل منتج جديد',
      body:
          'نحن نجمع بيانات المنتج وأفضل الأسعار المتاحة... سنخطرك عند اكتمال التحليل.',
    );

    // 2. Perform fetching in background (Google Shopping first)
    _scrapeAndPopulateProduct(id, url, targetPrice);
  }

  // Future<void> _scrapeAndPopulateProduct(String id, String url, double targetPrice) async {
  //   try {
  //     final googleShopping = GoogleShoppingService();
  //     final scraper = PriceScraperService();

  //     // Check if input is a URL
  //     final uri = Uri.tryParse(url.trim());
  //     final isUrl = uri != null && uri.hasScheme && uri.scheme.startsWith('http');

  //     // ------- STEP 1: Get exact title + image from the original product page -------
  //     String exactTitle = '';
  //     String exactImage = '';
  //     String exactStore = '';
  //     double scraperPrice = 0.0;

  //     if (isUrl) {
  //       debugPrint('[Hybrid] Step 1: Scraping original URL for title+image...');
  //       final scraperResult = await scraper.scrapeProductInfo(url);
  //       exactTitle = scraperResult['title']?.toString() ?? '';
  //       exactImage = scraperResult['image']?.toString() ?? '';
  //       exactStore = scraperResult['store']?.toString() ?? '';
  //       scraperPrice = (scraperResult['price'] as num?)?.toDouble() ?? 0.0;
  //       debugPrint('[Hybrid] Step 1 result — title: "$exactTitle", scraperPrice: $scraperPrice');
  //     } else {
  //       // Plain text input (اسم المنتج مباشرة)
  //       exactTitle = url.trim();
  //     }

  //     // ------- STEP 2: Search Google Shopping with the EXACT product title -------
  //     final searchQuery = exactTitle.isNotEmpty ? exactTitle : url;
  //     debugPrint('[Hybrid] Step 2: Searching Google Shopping for: "$searchQuery"');
  //     final gsResult = await googleShopping.searchLowestPrice(searchQuery);
  //     final double gsPrice = (gsResult['price'] as num?)?.toDouble() ?? 0.0;
  //     debugPrint('[Hybrid] Step 2 result — lowest price: $gsPrice from ${gsResult['store']}');

  //     // ------- COMBINE: title+image from Step 1, sellers+price from Step 2 -------
  //     final String finalTitle = exactTitle.isNotEmpty
  //         ? exactTitle
  //         : (gsResult['title']?.toString() ?? '');
  //     final String finalImage = exactImage.isNotEmpty
  //         ? exactImage
  //         : (gsResult['image']?.toString() ?? '');
  //     final String finalStore = gsResult['store']?.toString().isNotEmpty == true
  //         ? gsResult['store'].toString()
  //         : (exactStore.isNotEmpty ? exactStore : 'Google Shopping');

  //     // Build sellers list from Google Shopping
  //     final List<ProductSeller> sellers = [];
  //     if (gsResult['sellers'] != null && gsResult['sellers'] is List) {
  //       for (var s in gsResult['sellers']) {
  //         if (s is Map && s['name'] != null && s['price'] != null) {
  //           sellers.add(ProductSeller(
  //             name: s['name'].toString(),
  //             price: (s['price'] as num).toDouble(),
  //           ));
  //         }
  //       }
  //     }

  //     // Determine final lowest price
  //     double lowestPrice = gsPrice > 0 ? gsPrice : scraperPrice;

  //     // If Google Shopping found nothing at all, fall back entirely to scraper price
  //     if (lowestPrice <= 0 && scraperPrice > 0) {
  //       lowestPrice = scraperPrice;
  //       if (exactStore.isNotEmpty) {
  //         sellers.add(ProductSeller(name: exactStore, price: scraperPrice));
  //       }
  //     }

  //     sellers.sort((a, b) => a.price.compareTo(b.price));
  //     if (sellers.isNotEmpty) lowestPrice = sellers.first.price;

  //     final index = _products.indexWhere((p) => p.id == id);
  //     if (index == -1) return;

  //     // Handle complete failure (no price from either source)
  //     if (lowestPrice <= 0) {
  //       _products[index] = _products[index].copyWith(
  //         isAnalyzing: false,
  //         error: 'تعذر جلب البيانات. يرجى التحقق من الرابط أو الاسم.',
  //         title: finalTitle.isNotEmpty ? finalTitle : 'منتج غير مدعوم',
  //       );
  //       notifyListeners();
  //       await _saveToStorage();
  //       return;
  //     }

  //     final double finalTargetPrice = targetPrice > 0
  //         ? targetPrice
  //         : (lowestPrice * 0.9);

  //     // Ensure the primary price appears in sellers list
  //     if (!sellers.any((s) => (s.price - lowestPrice).abs() < 0.01) && lowestPrice > 0) {
  //       sellers.insert(0, ProductSeller(name: finalStore, price: lowestPrice));
  //     }

  //     _products[index] = _products[index].copyWith(
  //       title: finalTitle.isNotEmpty ? finalTitle : 'منتج',
  //       storeName: finalStore,
  //       currentPrice: lowestPrice,
  //       targetPrice: finalTargetPrice,
  //       deliveryType: DeliveryType.express,
  //       imageUrl: finalImage.isNotEmpty ? finalImage : 'https://picsum.photos/200',
  //       isAnalyzing: false,
  //       sellers: sellers,
  //       priceHistory: [lowestPrice],
  //       error: null,
  //     );

  //     notifyListeners();
  //     await _saveToStorage();

  //     if (_products[index].hasReachedTarget) {
  //       _triggerNotification(_products[index]);
  //     }
  //   } catch (e) {
  //     final index = _products.indexWhere((p) => p.id == id);
  //     if (index != -1) {
  //       final errorStr = e.toString().toLowerCase();
  //       String displayError = 'حدث خطأ: ${e.toString()}';
  //       if (errorStr.contains('socketexception') || errorStr.contains('host lookup') || errorStr.contains('timeout')) {
  //         displayError = 'يرجى التحقق من اتصالك بالإنترنت!';
  //       }

  //       _products[index] = _products[index].copyWith(
  //         isAnalyzing: false,
  //         error: displayError,
  //       );
  //       notifyListeners();
  //     }
  //   }
  // }
  Future<void> _scrapeAndPopulateProduct(
    String id,
    String url,
    double targetPrice,
  ) async {
    try {
      final scraper = PriceScraperService();

      debugPrint('[Hybrid] Scraping: $url');
      final scraperResult = await scraper.scrapeProductInfo(url);
      debugPrint('[Hybrid] Result: $scraperResult');

      final String exactTitle = scraperResult['title']?.toString() ?? '';
      final String exactImage = scraperResult['image']?.toString() ?? '';
      final String exactStore = scraperResult['store']?.toString() ?? 'نون';
      final double lowestPrice =
          (scraperResult['price'] as num?)?.toDouble() ?? 0.0;

      // جيب البائعين
      final List<ProductSeller> sellers = [];
      if (scraperResult['sellers'] != null &&
          scraperResult['sellers'] is List) {
        for (var s in scraperResult['sellers']) {
          if (s is Map && s['name'] != null && s['price'] != null) {
            sellers.add(
              ProductSeller(
                name: s['name'].toString(),
                price: (s['price'] as num).toDouble(),
              ),
            );
          }
        }
      }

      final index = _products.indexWhere((p) => p.id == id);
      if (index == -1) return;

      // لو مجاش سعر
      if (lowestPrice <= 0) {
        _products[index] = _products[index].copyWith(
          isAnalyzing: false,
          error: exactTitle.isNotEmpty ? exactTitle : 'تعذر جلب البيانات',
          title: 'تعذر جلب البيانات',
        );
        notifyListeners();
        await _saveToStorage();
        notificationsViewModel?.addNotification(
          title: '⚠️ تعذر تحليل المنتج',
          body:
              'لم نتمكن من جلب بيانات هذا المنتج. تحقق من صحة الرابط وحاول مرة أخرى.',
        );
        return;
      }

      final double finalTargetPrice = targetPrice > 0
          ? targetPrice
          : (lowestPrice * 0.9);

      _products[index] = _products[index].copyWith(
        title: exactTitle.isNotEmpty ? exactTitle : 'منتج',
        storeName: exactStore,
        currentPrice: lowestPrice,
        targetPrice: finalTargetPrice,
        deliveryType: DeliveryType.express,
        imageUrl: exactImage.isNotEmpty
            ? exactImage
            : 'https://picsum.photos/200',
        isAnalyzing: false,
        sellers: sellers,
        priceHistory: [lowestPrice],
        error: null,
      );

      notifyListeners();
      await _saveToStorage();

      if (_products[index].hasReachedTarget) {
        _triggerNotification(_products[index]);
      } else {
        // إشعار نجاح الإضافة
        notificationsViewModel?.addNotification(
          title: '✅ تمت إضافة المنتج',
          body:
              'تمت إضافة "${_products[index].title}" بنجاح. السعر الحالي: ${lowestPrice.toStringAsFixed(2)} ريال. سنخطرك عند الوصول للسعر المستهدف ⁠(${finalTargetPrice.toStringAsFixed(2)} ريال).',
        );
      }
    } catch (e) {
      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        _products[index] = _products[index].copyWith(
          isAnalyzing: false,
          error: 'حدث خطأ: ${e.toString()}',
        );
        notifyListeners();
      }
    }
  }

  void removeProduct(String id) async {
    _products.removeWhere((p) => p.id == id);
    await _saveToStorage();
    notifyListeners();
  }

  void simulatePriceDrop(String id) async {
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      final oldProduct = _products[index];
      final newProduct = ProductModel(
        id: oldProduct.id,
        title: oldProduct.title,
        storeName: oldProduct.storeName,
        currentPrice: oldProduct.targetPrice,
        targetPrice: oldProduct.targetPrice,
        deliveryType: oldProduct.deliveryType,
        imageUrl: oldProduct.imageUrl,
        timeAdded: oldProduct.timeAdded,
        watchers: oldProduct.watchers,
        originalUrl: oldProduct.originalUrl,
        sellers: oldProduct.sellers,
      );
      _products[index] = newProduct;
      await _saveToStorage();
      notifyListeners();

      _triggerNotification(newProduct);
    }
  }

  void _triggerNotification(ProductModel product) {
    if (notificationsViewModel != null) {
      notificationsViewModel!.addNotification(
        title: '🎯 هدف محقق: ${product.storeName}',
        body:
            'أبشر! نزل سعر "${product.title}" لـ ${product.currentPrice.toStringAsFixed(2)} ريال وهو أقل من هدفك (${product.targetPrice.toStringAsFixed(2)} ريال).',
      );
    }
    
    NotificationService().showNotification(
      id: product.id.hashCode,
      title: '🎯 هدف محقق!',
      body:
          'أبشر! نزل سعر "${product.title}" لـ ${product.currentPrice.toStringAsFixed(2)} ريال وهو أقل من هدفك.',
    );
  }

  Future<void> refreshAllProducts() async {
    if (_products.isEmpty || _isRefreshing) return;

    _isRefreshing = true;
    _refreshCheckedCount = 0;
    _refreshTotalCount = _products.length;
    _refreshCurrentName = '';
    notifyListeners();

    debugPrint(
      'Starting SEQUENTIAL refresh for ${_products.length} products...',
    );
    int updatedCount = 0;
    int reachedTargetCount = 0;
    const int _progressNotifId = 997;

    // 🔔 إشعار بدء الفحص
    await NotificationService().showProgressNotification(
      id: _progressNotifId,
      current: 0,
      total: _products.length,
      currentProductName: '',
    );

    try {
      // ✅ نسخة من الـ IDs عشان الـ loop لا تتأثر بإعادة الترتيب
      final ids = _products.map((p) => p.id).toList();
      int loopCount = 0;

      final prefs = await SharedPreferences.getInstance();
      final int batchSize = prefs.getInt('concurrent_products') ?? 2;

      for (int i = 0; i < ids.length; i += batchSize) {
        final batchIds = ids.sublist(i, (i + batchSize > ids.length) ? ids.length : i + batchSize);
        
        List<String> currentNames = [];
        List<Future<ProductModel?>> futures = [];
        List<ProductModel> oldBatchProducts = [];

        for (final id in batchIds) {
          final currentIndex = _products.indexWhere((p) => p.id == id);
          if (currentIndex == -1) continue;

          final old = _products[currentIndex];
          oldBatchProducts.add(old);
          
          String shortName = old.title.length > 20
              ? '${old.title.substring(0, 20)}...'
              : old.title;
          currentNames.add(shortName);

          futures.add(_refreshSingleProduct(old));
        }

        if (futures.isEmpty) continue;

        _refreshCurrentName = currentNames.join(' و ');

        // 🔔 تحديث إشعار التقدم في الخلفية
        await NotificationService().showProgressNotification(
          id: _progressNotifId,
          current: loopCount,
          total: _products.length,
          currentProductName: _refreshCurrentName,
        );

        _currentlyRefreshingIds = batchIds.toList();
        notifyListeners();

        final results = await Future.wait(futures);

        _currentlyRefreshingIds.clear();
        loopCount += futures.length;
        _refreshCheckedCount = loopCount;
        
        _lastUpdatedClearTimer?.cancel();
        _lastUpdatedIds.clear();

        for (int j = 0; j < results.length; j++) {
          final updated = results[j];
          if (updated != null) {
            final old = oldBatchProducts[j];
            // ✅ أزّل من مكانه الحالي وحطه في الأول
            final idx = _products.indexWhere((p) => p.id == updated.id);
            if (idx != -1) {
              _products.removeAt(idx);
              _products.insert(0, updated);
            }

            if (updated.currentPrice > 0) updatedCount++;

            // 🟢 فلاش للمنتج اللي اتحدث
            _lastUpdatedIds.add(updated.id);

            if (updated.hasReachedTarget && !old.hasReachedTarget) {
              reachedTargetCount++;
              _triggerNotification(updated);
            }
          }
        }
        
        if (_lastUpdatedIds.isNotEmpty) {
          _lastUpdatedClearTimer = Timer(
            const Duration(milliseconds: 2500),
            () {
              _lastUpdatedIds.clear();
              notifyListeners();
            },
          );
        }
        notifyListeners();
      }

      await _saveToStorage();

      // إلغاء إشعار التقدم وإظهار النتيجة النهائية
      await NotificationService().dismissNotification(_progressNotifId);

      String summaryTitle = '✅ اكتمل الفحص الدوري';
      String summaryBody = 'تم فحص ${_products.length} منتجات.';
      if (reachedTargetCount > 0) {
        summaryBody += '\n🎯 $reachedTargetCount منتج وصل للسعر المستهدف!';
      }

      await NotificationService().showNotification(
        id: 998,
        title: summaryTitle,
        body: summaryBody,
      );

      notificationsViewModel?.addNotification(
        title: summaryTitle,
        body: summaryBody,
      );
    } finally {
      _currentlyRefreshingIds.clear();
      _isRefreshing = false;
      _refreshCheckedCount = 0;
      _refreshTotalCount = 0;
      _refreshCurrentName = '';
      notifyListeners();
    }
  }

  /// يحدّث منتج واحد ويرجع النسخة الجديدة أو null لو فشل
  Future<ProductModel?> _refreshSingleProduct(ProductModel old) async {
    if (old.isAnalyzing) return null;

    try {
      final uri = Uri.tryParse(old.originalUrl.trim());
      final isUrl =
          uri != null && uri.hasScheme && uri.scheme.startsWith('http');
      if (!isUrl) return old.copyWith(lastChecked: DateTime.now());

      final scraper = PriceScraperService();
      final result = await scraper.scrapeProductInfo(old.originalUrl);
      final double lowestPrice = (result['price'] as num?)?.toDouble() ?? 0.0;
      final String refreshedImage = result['image']?.toString() ?? '';

      if (lowestPrice <= 0) return old.copyWith(lastChecked: DateTime.now());

      List<ProductSeller> refreshedSellers = [];
      if (result['sellers'] is List) {
        for (var s in result['sellers']) {
          if (s is Map && s['name'] != null && s['price'] != null) {
            refreshedSellers.add(
              ProductSeller(
                name: s['name'].toString(),
                price: (s['price'] as num).toDouble(),
              ),
            );
          }
        }
      }
      if (refreshedSellers.isEmpty) {
        refreshedSellers.add(
          ProductSeller(
            name: result['store']?.toString() ?? old.storeName,
            price: lowestPrice,
          ),
        );
      }
      refreshedSellers.sort((a, b) => a.price.compareTo(b.price));
      final double finalPrice = refreshedSellers.first.price;

      final newHistory = List<double>.from(old.priceHistory);
      if (newHistory.isEmpty || newHistory.last != finalPrice) {
        newHistory.add(finalPrice);
        if (newHistory.length > 30) newHistory.removeAt(0);
      }

      return old.copyWith(
        currentPrice: finalPrice,
        storeName: result['store']?.toString().isNotEmpty == true
            ? result['store'].toString()
            : old.storeName,
        imageUrl: refreshedImage.isNotEmpty ? refreshedImage : old.imageUrl,
        sellers: refreshedSellers,
        priceHistory: newHistory,
        lastChecked: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error refreshing product ${old.id}: $e');
      return old.copyWith(lastChecked: DateTime.now());
    }
  }

  String exportToJson() {
    final data = jsonEncode(_products.map((p) => p.toJson()).toList());
    NotificationService().showNotification(
      id: 103,
      title: '📁 تصدير الملف',
      body: 'تم تجهيز ملف البيانات بنجاح للمشاركة.',
    );
    return data;
  }

  Future<bool> importFromJson(String json) async {
    try {
      final List<dynamic> decoded = jsonDecode(json);
      final imported = decoded
          .map((item) => ProductModel.fromJson(item))
          .toList();
      _products.addAll(imported);
      await _saveToStorage();
      notifyListeners();

      NotificationService().showNotification(
        id: 104,
        title: '📥 استيراد الملف',
        body: 'تم استيراد ${imported.length} منتج جديد بنجاح.',
      );

      return true;
    } catch (e) {
      debugPrint('Import error: $e');
      return false;
    }
  }
}
