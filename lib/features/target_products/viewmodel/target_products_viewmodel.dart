import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

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
      filtered = filtered.where((p) => p.deliveryType == _currentDeliveryFilter).toList();
    }

    // 3. Sorting
    filtered = _sortProducts(filtered, _currentSortOption);

    return filtered;
  }

  List<ProductModel> _sortProducts(List<ProductModel> list, ProductSortOption option) {
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

    // 2. Perform fetching in background (Google Shopping first)
    _scrapeAndPopulateProduct(id, url, targetPrice);
  }

  Future<void> _scrapeAndPopulateProduct(String id, String url, double targetPrice) async {
    try {
      final googleShopping = GoogleShoppingService();
      final scraper = PriceScraperService();

      // Check if input is a URL
      final uri = Uri.tryParse(url.trim());
      final isUrl = uri != null && uri.hasScheme && uri.scheme.startsWith('http');

      // ------- STEP 1: Get exact title + image from the original product page -------
      String exactTitle = '';
      String exactImage = '';
      String exactStore = '';
      double scraperPrice = 0.0;

      if (isUrl) {
        debugPrint('[Hybrid] Step 1: Scraping original URL for title+image...');
        final scraperResult = await scraper.scrapeProductInfo(url);
        exactTitle = scraperResult['title']?.toString() ?? '';
        exactImage = scraperResult['image']?.toString() ?? '';
        exactStore = scraperResult['store']?.toString() ?? '';
        scraperPrice = (scraperResult['price'] as num?)?.toDouble() ?? 0.0;
        debugPrint('[Hybrid] Step 1 result — title: "$exactTitle", scraperPrice: $scraperPrice');
      } else {
        // Plain text input (اسم المنتج مباشرة)
        exactTitle = url.trim();
      }

      // ------- STEP 2: Search Google Shopping with the EXACT product title -------
      final searchQuery = exactTitle.isNotEmpty ? exactTitle : url;
      debugPrint('[Hybrid] Step 2: Searching Google Shopping for: "$searchQuery"');
      final gsResult = await googleShopping.searchLowestPrice(searchQuery);
      final double gsPrice = (gsResult['price'] as num?)?.toDouble() ?? 0.0;
      debugPrint('[Hybrid] Step 2 result — lowest price: $gsPrice from ${gsResult['store']}');

      // ------- COMBINE: title+image from Step 1, sellers+price from Step 2 -------
      final String finalTitle = exactTitle.isNotEmpty
          ? exactTitle
          : (gsResult['title']?.toString() ?? '');
      final String finalImage = exactImage.isNotEmpty
          ? exactImage
          : (gsResult['image']?.toString() ?? '');
      final String finalStore = gsResult['store']?.toString().isNotEmpty == true
          ? gsResult['store'].toString()
          : (exactStore.isNotEmpty ? exactStore : 'Google Shopping');

      // Build sellers list from Google Shopping
      final List<ProductSeller> sellers = [];
      if (gsResult['sellers'] != null && gsResult['sellers'] is List) {
        for (var s in gsResult['sellers']) {
          if (s is Map && s['name'] != null && s['price'] != null) {
            sellers.add(ProductSeller(
              name: s['name'].toString(),
              price: (s['price'] as num).toDouble(),
            ));
          }
        }
      }

      // Determine final lowest price
      double lowestPrice = gsPrice > 0 ? gsPrice : scraperPrice;

      // If Google Shopping found nothing at all, fall back entirely to scraper price
      if (lowestPrice <= 0 && scraperPrice > 0) {
        lowestPrice = scraperPrice;
        if (exactStore.isNotEmpty) {
          sellers.add(ProductSeller(name: exactStore, price: scraperPrice));
        }
      }

      sellers.sort((a, b) => a.price.compareTo(b.price));
      if (sellers.isNotEmpty) lowestPrice = sellers.first.price;

      final index = _products.indexWhere((p) => p.id == id);
      if (index == -1) return;

      // Handle complete failure (no price from either source)
      if (lowestPrice <= 0) {
        _products[index] = _products[index].copyWith(
          isAnalyzing: false,
          error: 'تعذر جلب البيانات. يرجى التحقق من الرابط أو الاسم.',
          title: finalTitle.isNotEmpty ? finalTitle : 'منتج غير مدعوم',
        );
        notifyListeners();
        await _saveToStorage();
        return;
      }

      final double finalTargetPrice = targetPrice > 0
          ? targetPrice
          : (lowestPrice * 0.9);

      // Ensure the primary price appears in sellers list
      if (!sellers.any((s) => (s.price - lowestPrice).abs() < 0.01) && lowestPrice > 0) {
        sellers.insert(0, ProductSeller(name: finalStore, price: lowestPrice));
      }

      _products[index] = _products[index].copyWith(
        title: finalTitle.isNotEmpty ? finalTitle : 'منتج',
        storeName: finalStore,
        currentPrice: lowestPrice,
        targetPrice: finalTargetPrice,
        deliveryType: DeliveryType.express,
        imageUrl: finalImage.isNotEmpty ? finalImage : 'https://picsum.photos/200',
        isAnalyzing: false,
        sellers: sellers,
        priceHistory: [lowestPrice],
        error: null,
      );

      notifyListeners();
      await _saveToStorage();

      if (_products[index].hasReachedTarget) {
        _triggerNotification(_products[index]);
      }
    } catch (e) {
      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        final errorStr = e.toString().toLowerCase();
        String displayError = 'حدث خطأ: ${e.toString()}';
        if (errorStr.contains('socketexception') || errorStr.contains('host lookup') || errorStr.contains('timeout')) {
          displayError = 'يرجى التحقق من اتصالك بالإنترنت!';
        }

        _products[index] = _products[index].copyWith(
          isAnalyzing: false,
          error: displayError,
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
        body: 'أبشر! نزل سعر "${product.title}" لـ ${product.currentPrice.toStringAsFixed(2)} ريال وهو أقل من هدفك (${product.targetPrice.toStringAsFixed(2)} ريال).',
      );
    }
  }

  Future<void> refreshAllProducts() async {
    if (_products.isEmpty || _isRefreshing) return;
    
    _isRefreshing = true;
    notifyListeners();
    
    final googleShopping = GoogleShoppingService();
    final scraper = PriceScraperService();
    debugPrint('Starting batch refresh for ${_products.length} products...');

    for (int i = 0; i < _products.length; i++) {
      final old = _products[i];
      try {
        // HYBRID: Step 1 — scrape original URL for exact title, Step 2 — Google Shopping
        final uri = Uri.tryParse(old.originalUrl.trim());
        final isUrl = uri != null && uri.hasScheme && uri.scheme.startsWith('http');

        String searchQuery = old.title; // default: use existing title
        String refreshedImage = old.imageUrl;

        // Step 1: re-scrape for an up-to-date title (only for known URL products)
        if (isUrl && old.title.isNotEmpty && old.title != 'منتج' && old.title != 'جاري التحليل الذكي...') {
          // We already have the title from initial fetch — reuse it for Google Shopping
          searchQuery = old.title;
        }

        // Step 2: Google Shopping with exact title
        final gsResult = await googleShopping.searchLowestPrice(searchQuery);
        final double gsPrice = (gsResult['price'] as num?)?.toDouble() ?? 0.0;

        double lowestPrice = gsPrice;

        // Fallback: re-scrape the URL if Google Shopping returned nothing
        if (lowestPrice <= 0 && isUrl) {
          final scraperResult = await scraper.scrapeProductInfo(old.originalUrl);
          lowestPrice = (scraperResult['price'] as num?)?.toDouble() ?? 0.0;
          if (scraperResult['image']?.toString().isNotEmpty == true) {
            refreshedImage = scraperResult['image'].toString();
          }
        }

        if (lowestPrice > 0) {
          List<ProductSeller> refreshedSellers = [];
          if (gsResult['sellers'] != null && gsResult['sellers'] is List) {
            for (var s in gsResult['sellers']) {
              if (s is Map && s['name'] != null && s['price'] != null) {
                refreshedSellers.add(ProductSeller(
                  name: s['name'].toString(),
                  price: (s['price'] as num).toDouble(),
                ));
              }
            }
          }
          if (refreshedSellers.isEmpty) {
            refreshedSellers.add(ProductSeller(
              name: gsResult['store']?.toString() ?? old.storeName,
              price: lowestPrice,
            ));
          }

          refreshedSellers.sort((a, b) => a.price.compareTo(b.price));
          lowestPrice = refreshedSellers.first.price;

          final newHistory = List<double>.from(old.priceHistory);
          if (newHistory.isEmpty || newHistory.last != lowestPrice) {
            newHistory.add(lowestPrice);
            if (newHistory.length > 30) newHistory.removeAt(0);
          }

          _products[i] = old.copyWith(
            currentPrice: lowestPrice,
            storeName: gsResult['store']?.toString().isNotEmpty == true
                ? gsResult['store'].toString()
                : old.storeName,
            imageUrl: refreshedImage.isNotEmpty ? refreshedImage : old.imageUrl,
            sellers: refreshedSellers,
            priceHistory: newHistory,
            lastChecked: DateTime.now(),
          );

          if (_products[i].hasReachedTarget && !old.hasReachedTarget) {
            _triggerNotification(_products[i]);
          }
        }
      } catch (e) {
        debugPrint('Error refreshing product ${old.id}: $e');
      }
    }
    
    _isRefreshing = false;
    await _saveToStorage();
    notifyListeners();
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
