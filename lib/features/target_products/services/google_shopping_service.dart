import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// يجيب أقل سعر من Google Shopping مجاناً باستخدام HeadlessInAppWebView.
/// لا يحتاج API Key أو اشتراك.
class GoogleShoppingService {
  /// [query] إما اسم منتج أو URL (سنستخرج منه اسم المنتج)
  Future<Map<String, dynamic>> searchLowestPrice(String query) async {
    final searchQuery = _buildSearchQuery(query);
    debugPrint('[GoogleShopping] Searching for: $searchQuery');

    final completer = Completer<Map<String, dynamic>>();
    HeadlessInAppWebView? headlessWebView;

    final url =
        'https://www.google.com/search?tbm=shop&q=${Uri.encodeQueryComponent(searchQuery)}&hl=ar&gl=eg';

    headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(url)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        userAgent:
            'Mozilla/5.0 (Linux; Android 12; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        cacheEnabled: true,
        disableDefaultErrorPage: true,
        preferredContentMode: UserPreferredContentMode.MOBILE,
      ),
      onLoadStop: (controller, uri) async {
        if (completer.isCompleted) return;

        // ننتظر شوية عشان الـ JS يشتغل كويس
        await Future.delayed(const Duration(milliseconds: 2500));

        if (completer.isCompleted) return;

        try {
          final String? resultsJson =
              await controller.evaluateJavascript(source: _extractionScript);

          if (resultsJson == null || resultsJson == 'null') {
            debugPrint('[GoogleShopping] JS returned null');
            if (!completer.isCompleted) completer.complete(_emptyResult());
            return;
          }

          // flutter_inappwebview يرجع string مع quotes زيادة أحياناً
          String cleaned = resultsJson;
          if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
            cleaned = jsonDecode(cleaned) as String;
          }

          final Map<String, dynamic> data = jsonDecode(cleaned);
          final List<dynamic> rawSellers = data['sellers'] ?? [];

          final List<Map<String, dynamic>> sellers = rawSellers
              .where((s) =>
                  s is Map &&
                  s['price'] != null &&
                  (s['price'] as num) > 0)
              .map((s) => {
                    'name': s['name']?.toString() ?? 'بائع',
                    'price': (s['price'] as num).toDouble(),
                  })
              .toList()
              .cast<Map<String, dynamic>>();

          sellers.sort((a, b) =>
              (a['price'] as double).compareTo(b['price'] as double));

          if (sellers.isEmpty) {
            debugPrint('[GoogleShopping] No sellers found in JS result');
            if (!completer.isCompleted) completer.complete(_emptyResult());
            return;
          }

          final double lowestPrice = sellers.first['price'] as double;
          final String storeName = sellers.first['name'] as String;
          final String title =
              data['title']?.toString().isNotEmpty == true
                  ? data['title'].toString()
                  : searchQuery;
          final String image = data['image']?.toString() ?? '';

          debugPrint(
              '[GoogleShopping] Found ${sellers.length} sellers. Lowest: $lowestPrice from $storeName');

          if (!completer.isCompleted) {
            completer.complete({
              'price': lowestPrice,
              'title': title,
              'image': image,
              'store': storeName,
              'sellers': sellers,
            });
          }
        } catch (e) {
          debugPrint('[GoogleShopping] JS parse error: $e');
          if (!completer.isCompleted) completer.complete(_emptyResult());
        } finally {
          headlessWebView?.dispose();
        }
      },
      onReceivedError: (controller, request, error) {
        debugPrint('[GoogleShopping] WebView error: ${error.description}');
        if (!completer.isCompleted) {
          completer.complete({
            'price': 0.0,
            'title': 'لا يوجد اتصال بالإنترنت',
            'image': '',
            'store': 'غير معروف',
            'sellers': [],
          });
        }
        headlessWebView?.dispose();
      },
    );

    await headlessWebView.run();

    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        debugPrint('[GoogleShopping] Timeout!');
        headlessWebView?.dispose();
        return _emptyResult();
      },
    );
  }

  /// يبني search query من الـ input (URL أو نص عادي)
  String _buildSearchQuery(String input) {
    final trimmed = input.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme && uri.scheme.startsWith('http')) {
      // استخرج اسم المنتج من الـ URL
      return _extractNameFromUrl(uri);
    }
    return trimmed;
  }

  String _extractNameFromUrl(Uri uri) {
    // جرب تجيب اسم من الـ path segments
    final pathParts = uri.pathSegments
        .where((s) =>
            s.isNotEmpty &&
            !s.startsWith('N') && // noon product IDs
            !RegExp(r'^[a-f0-9\-]{8,}$').hasMatch(s) && // UUIDs
            !RegExp(r'^\d+$').hasMatch(s)) // pure numbers
        .toList();

    if (pathParts.isNotEmpty) {
      // استخدم آخر جزء بعد تنظيف الـ dashes/underscores
      final name = pathParts.last
          .replaceAll('-', ' ')
          .replaceAll('_', ' ')
          .replaceAll('%20', ' ')
          .trim();
      if (name.length > 3) return name;
    }

    // fallback: استخدم الـ domain بدون www/com
    return uri.host.replaceAll('www.', '').split('.').first;
  }

  Map<String, dynamic> _emptyResult() => {
        'price': 0.0,
        'title': '',
        'image': '',
        'store': 'غير معروف',
        'sellers': [],
      };

  /// سكريبت JavaScript يسحب نتائج Google Shopping من الصفحة
  static const String _extractionScript = r'''
(function() {
  try {
    var sellers = [];
    var title = '';
    var image = '';

    // --- استخراج المنتجات من Google Shopping ---
    // Google Shopping يستخدم عدة selectors حسب الـ layout

    // 1. حاول تجيب الـ structured data (JSON-LD) 
    var jsonLdEls = document.querySelectorAll('script[type="application/ld+json"]');
    for (var i = 0; i < jsonLdEls.length; i++) {
      try {
        var obj = JSON.parse(jsonLdEls[i].textContent);
        var items = [];
        if (obj['@type'] === 'ItemList') items = obj.itemListElement || [];
        else if (Array.isArray(obj)) items = obj;
        items.forEach(function(item) {
          var product = item.item || item;
          if (product && product.offers) {
            var offers = Array.isArray(product.offers) ? product.offers : [product.offers];
            offers.forEach(function(offer) {
              var p = parseFloat(String(offer.price || 0).replace(/[^0-9.]/g,''));
              var seller = offer.seller ? (offer.seller.name || offer.seller) : 'بائع';
              if (p > 0) sellers.push({name: String(seller), price: p});
            });
            if (!title && product.name) title = product.name;
            if (!image && product.image) image = Array.isArray(product.image) ? product.image[0] : product.image;
          }
        });
      } catch(e) {}
    }

    // 2. جرب الـ DOM مباشرة من Google Shopping results
    if (sellers.length === 0) {
      // Google Shopping product cards
      var cards = document.querySelectorAll(
        '.sh-dgr__content, .sh-pr__product-results-grid .sh-dgr__grade-peers, ' +
        '[jscontroller][data-sh-gr], .u30d4, .KZmu8e, .sh-dlr__list-result'
      );

      cards.forEach(function(card) {
        // title
        var titleEl = card.querySelector('h3, .Xjkr3b, .pymv4e, [class*="title"]');
        if (!title && titleEl) title = titleEl.innerText.trim();

        // image
        var imgEl = card.querySelector('img');
        if (!image && imgEl && imgEl.src && imgEl.src.startsWith('http')) image = imgEl.src;

        // price
        var priceEl = card.querySelector('.a8Pemb, .YxtAqb, .PZPZlf, [aria-label*="EGP"], [aria-label*="جنيه"], .T14wmb, .b5mFgb');
        var priceStr = '';
        if (priceEl) {
          priceStr = priceEl.innerText || priceEl.getAttribute('aria-label') || '';
        }

        // seller name
        var sellerEl = card.querySelector('.E5ocAb, .aULzUe, .zPEcBd, [class*="seller"], .u30d4 a, .sh-sp__seller-link');
        var sellerName = sellerEl ? sellerEl.innerText.trim() : '';

        var p = parseFloat(priceStr.replace(/[^0-9.]/g, ''));
        if (p > 0) {
          sellers.push({name: sellerName || 'بائع Google Shopping', price: p});
        }
      });
    }

    // 3. fallback: أي عنصر في الصفحة يحتوي EGP أو ج.م
    if (sellers.length === 0) {
      var allText = document.body.innerText;
      var regex = /([0-9,،]+(?:\.[0-9]+)?)\s*(?:EGP|ج\.م|جنيه)/ig;
      var matches;
      var foundPrices = [];
      while ((matches = regex.exec(allText)) !== null) {
        var p = parseFloat(matches[1].replace(/[,،]/g, ''));
        if (p > 10 && p < 10000000) foundPrices.push(p);
      }
      // حاول SAR أيضاً لو EGP مش موجود
      if (foundPrices.length === 0) {
        var regex2 = /([0-9,،]+(?:\.[0-9]+)?)\s*(?:SAR|ريال|ر\.س)/ig;
        while ((matches = regex2.exec(allText)) !== null) {
          var p2 = parseFloat(matches[1].replace(/[,،]/g, ''));
          if (p2 > 10 && p2 < 10000000) foundPrices.push(p2);
        }
      }
      if (foundPrices.length > 0) {
        foundPrices.sort(function(a,b){return a-b;});
        var median = foundPrices[Math.floor(foundPrices.length / 2)];
        foundPrices.filter(function(p3){return p3 >= median * 0.2;}).forEach(function(p4, idx) {
          sellers.push({name: 'بائع ' + (idx + 1), price: p4});
        });
      }
    }

    // جيب أول صورة لو لسا مفيش
    if (!image) {
      var firstImg = document.querySelector('.sh-dgr__content img, .sh-pr__product-results-grid img, #rso img');
      if (firstImg && firstImg.src && firstImg.src.startsWith('http')) image = firstImg.src;
    }

    // جيب عنوان لو لسا مفيش
    if (!title) {
      var h3 = document.querySelector('h3.Xjkr3b, h3.pymv4e, h3');
      if (h3) title = h3.innerText.trim();
    }

    sellers.sort(function(a,b){return a.price - b.price;});
    // رجع أول 5 بائعين بس
    sellers = sellers.slice(0, 5);

    return JSON.stringify({title: title, image: image, sellers: sellers});
  } catch(e) {
    return JSON.stringify({title: '', image: '', sellers: [], error: e.toString()});
  }
})()
''';
}
