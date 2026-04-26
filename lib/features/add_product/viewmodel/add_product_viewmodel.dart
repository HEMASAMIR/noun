import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../target_products/viewmodel/target_products_viewmodel.dart';

class AddProductData {
  final TextEditingController linkController;
  final TextEditingController priceController;

  AddProductData()
      : linkController = TextEditingController(text: 'https://www.noon.com/saudi-ar/galaxy-a17-dual-sim-gray-6gb-128gb-5g-middle-east-version/N70202453V/p/'),
        priceController = TextEditingController();

  void dispose() {
    linkController.dispose();
    priceController.dispose();
  }
}

class AddProductViewModel extends ChangeNotifier {
  final List<AddProductData> _products = [AddProductData()];
  bool _isLoading = false;
  bool _disposed = false;
  String? _errorMessage;

  List<AddProductData> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void addProduct() {
    _products.add(AddProductData());
    if (!_disposed) notifyListeners();
  }

  Future<void> checkClipboard(int index) async {
    try {
      final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null) {
        final text = data.text!.trim();
        if (text.isNotEmpty && _products[index].linkController.text.isEmpty) {
          // إذا كان نص عادي أو URL، نحطه في الحقل
          _products[index].linkController.text = text;
          if (!_disposed) notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Clipboard error: $e');
    }
  }

  void removeProduct(int index) {
    if (_products.length > 1) {
      _products[index].dispose();
      _products.removeAt(index);
      if (!_disposed) notifyListeners();
    }
  }

  void setSuggestedPrice(int index, double currentPrice, double discountPercentage) {
    if (currentPrice <= 0) return;
    final suggested = currentPrice * (1 - discountPercentage);
    _products[index].priceController.text = suggested.toStringAsFixed(0);
    if (!_disposed) notifyListeners();
  }

  Future<void> submitProducts(TargetProductsViewModel targetViewModel) async {
    _isLoading = true;
    _errorMessage = null;
    if (!_disposed) notifyListeners();

    try {
      // Simulate network delay for UI feedback
      await Future.delayed(const Duration(milliseconds: 500));

      for (var p in _products) {
        final link = p.linkController.text.trim();
        String priceText = p.priceController.text.trim();
        
        if (link.isEmpty) {
          throw Exception('يرجى إدخال اسم المنتج أو رابطه');
        }
        
        // Convert Arabic numerals to English numerals
        const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
        const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
        for (int i = 0; i < arabic.length; i++) {
          priceText = priceText.replaceAll(arabic[i], english[i]);
        }
        
        final price = double.tryParse(priceText) ?? 0.0;
        
        // Add product using the target view model
        await targetViewModel.fetchAndAddProduct(link, price);
      }
      
      // Clear search query to ensure new products are visible
      targetViewModel.clearSearchQuery();
      
      // Clear forms after successful submission
      _products.clear();
      _products.add(AddProductData());
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socketexception') || errorStr.contains('host lookup') || errorStr.contains('timeout')) {
        _errorMessage = 'لا يوجد اتصال بالإنترنت. يرجى التحقق والمحاولة مرة أخرى.';
      } else {
        _errorMessage = e.toString().contains('Exception:') 
            ? e.toString().split('Exception:')[1].trim()
            : 'حدث خطأ غير متوقع: ${e.toString()}';
      }
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (var p in _products) {
      p.dispose();
    }
    super.dispose();
  }
}
