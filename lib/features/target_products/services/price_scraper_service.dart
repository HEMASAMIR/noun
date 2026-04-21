import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class PriceScraperService {
  Future<Map<String, dynamic>> scrapeProductInfo(String url) async {
    try {
      final uri = Uri.tryParse(url.trim());
      if (uri == null || !uri.hasScheme || !uri.scheme.startsWith('http')) {
        return {
          'price': 0.0,
          'title': 'رابط غير صالح',
          'image': '',
          'store': 'غير معروف',
          'sellers': [],
        };
      }
      final host = uri.host.toLowerCase();

      // Noon & Amazon needs JS
      if (host.contains('noon.com') || host.contains('amazon.sa')) {
        String storeName = host.contains('noon.com')
            ? 'نون'
            : 'أمازون السعودية';
        return await _scrapeWithWebView(url, storeName);
      }

      // Generic HTTP fallback
      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            },
          )
          .timeout(const Duration(seconds: 40));

      if (response.statusCode != 200) {
        throw Exception('Failed to load page: ${response.statusCode}');
      }

      final document = parse(response.body);
      double price = 0.0;
      String title = _extractTitle(document);
      String image = _extractImage(document);
      String store = host.replaceAll('www.', '');
      List<Map<String, dynamic>> sellers = [];

      if (host.contains('extra.com')) {
        price = _parseExtraPrice(document, sellers);
        store = 'إكسترا';
      } else {
        price = _parseGenericPrice(document, response.body, sellers);
      }

      if (price <= 0) {
        price = _parseGenericRegexPrice(response.body, sellers, store);
      }

      return {
        'price': price,
        'title': title.isNotEmpty ? title : 'منتج غير معروف',
        'image': image,
        'store': store,
        'sellers': sellers,
      };
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      String title = 'خطأ في جلب البيانات';
      if (errorStr.contains('socketexception') ||
          errorStr.contains('host lookup') ||
          errorStr.contains('timeout')) {
        title = 'لا يوجد اتصال بالإنترنت';
      }
      return {
        'price': 0.0,
        'title': title,
        'image': '',
        'store': 'غير معروف',
        'sellers': [],
      };
    }
  }

  Future<Map<String, dynamic>> _scrapeWithWebView(
    String url,
    String storeName,
  ) async {
    final completer = Completer<Map<String, dynamic>>();
    HeadlessInAppWebView? headlessWebView;

    headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(url)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        userAgent:
            'Mozilla/5.0 (Linux; Android 10; SM-G975F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
        cacheEnabled: true,
        useShouldOverrideUrlLoading: false,
        useOnLoadResource: false,
        disableDefaultErrorPage: true,
        preferredContentMode: UserPreferredContentMode.MOBILE,
      ),
      onLoadStop: (controller, uri) async {
        await Future.delayed(const Duration(milliseconds: 3000));

        try {
          final String script =
              '''
            (function() {
              let price = 0;
              let sellers = [];
              let title = document.title;
              let image = "";

              // Helper: try to get image from og:image
              let ogImg = document.querySelector('meta[property="og:image"]');
              if (ogImg) image = ogImg.getAttribute('content') || '';

              // Helper: get h1 for title
              let h1 = document.querySelector('h1');
              if (h1 && h1.innerText.trim()) title = h1.innerText.trim();

              // ===== STRATEGY 1: __NEXT_DATA__ (multiple known paths) =====
              try {
                let el = document.getElementById('__NEXT_DATA__');
                if (el) {
                  let data = JSON.parse(el.textContent);
                  // Try all known paths in Noon's NEXT_DATA
                  let product =
                    data?.props?.pageProps?.product ||
                    data?.props?.pageProps?.catalog?.product ||
                    data?.props?.pageProps?.data?.product ||
                    data?.props?.pageProps?.initialData?.product ||
                    null;

                  // Deep search helper
                  if (!product) {
                    let str = el.textContent;
                    let m = str.match(/"sale_price"\s*:\s*"?(\d+\.?\d*)"?/);
                    if (m) {
                      let p = parseFloat(m[1]);
                      if (p > 0) sellers.push({ name: "$storeName", price: p });
                    }
                    // Also try "price":"xxx"
                    if (sellers.length === 0) {
                      let m2 = str.match(/"now"\s*:\s*"?(\d+\.?\d*)"?/);
                      if (m2) {
                        let p2 = parseFloat(m2[1]);
                        if (p2 > 0) sellers.push({ name: "$storeName", price: p2 });
                      }
                    }
                  }

                  if (product) {
                    title = product.name || product.title || title;
                    // Image
                    if (product.image_keys && product.image_keys.length > 0) {
                      image = 'https://f.nooncdn.com/p/' + product.image_keys[0] + '.jpg';
                    } else if (product.image_url) {
                      image = product.image_url;
                    }
                    // Offers/variants
                    let variants = product.variants || [];
                    variants.forEach(v => {
                      let offers = v.offers || [];
                      offers.forEach(o => {
                        let p = parseFloat(o.sale_price) || parseFloat(o.price) || parseFloat(o.now) || 0;
                        if (p > 0) sellers.push({ name: o.seller_name || "$storeName", price: p });
                      });
                    });
                    // Direct price fields
                    if (sellers.length === 0) {
                      let p =
                        parseFloat(product.sale_price) ||
                        parseFloat(product.price?.now) ||
                        parseFloat(product.price) ||
                        parseFloat(product.now) ||
                        0;
                      if (p > 0) sellers.push({ name: "$storeName", price: p });
                    }
                  }
                }
              } catch(e1) {}

              // ===== STRATEGY 2: window.__APP_STATE__ or similar globals =====
              if (sellers.length === 0) {
                try {
                  let appKeys = ['__APP_STATE__','__INITIAL_STATE__','__REDUX_STATE__','__PRELOADED_STATE__'];
                  for (let k of appKeys) {
                    if (window[k]) {
                      let str = JSON.stringify(window[k]);
                      let m = str.match(/"sale_price"\s*:\s*"?(\d+\.?\d*)"?/);
                      if (!m) m = str.match(/"now"\s*:\s*"?(\d+\.?\d*)"?/);
                      if (m) {
                        let p = parseFloat(m[1]);
                        if (p > 0) { sellers.push({ name: "$storeName", price: p }); break; }
                      }
                    }
                  }
                } catch(e2) {}
              }

              // ===== STRATEGY 3: JSON-LD structured data =====
              if (sellers.length === 0) {
                try {
                  let jsonLds = document.querySelectorAll('script[type="application/ld+json"]');
                  jsonLds.forEach(s => {
                    try {
                      let d = JSON.parse(s.textContent);
                      let items = Array.isArray(d) ? d : [d];
                      items.forEach(item => {
                        let offers = item.offers || item.Offers;
                        if (offers) {
                          let offerList = Array.isArray(offers) ? offers : [offers];
                          offerList.forEach(o => {
                            let p = parseFloat(o.price) || parseFloat(o.lowPrice) || 0;
                            if (p > 0) sellers.push({ name: o.seller?.name || "$storeName", price: p });
                          });
                        }
                      });
                    } catch(_) {}
                  });
                } catch(e3) {}
              }

              // ===== STRATEGY 4: DOM selectors (Noon-specific + generic) =====
              if (sellers.length === 0) {
                let foundPrices = [];
                // Noon-specific modern selectors
                let noonSelectors = [
                  '[data-qa="product-price"]',
                  '[class*="price"][class*="now"]',
                  '[class*="priceNow"]',
                  '[class*="selling-price"]',
                  '[class*="sellingPrice"]',
                  '.price-now',
                  '.priceNow',
                  'span[class*="Price"]',
                  '[class*="ProductPrice"]',
                  '[data-testid="product-price"]',
                  '.a-price-whole',
                  '#priceblock_ourprice',
                ];
                for (let sel of noonSelectors) {
                  document.querySelectorAll(sel).forEach(el => {
                    let text = el.innerText.replace(/[^0-9.]/g, '');
                    let p = parseFloat(text);
                    if (p > 10 && p < 100000) foundPrices.push(p);
                  });
                }
                if (foundPrices.length > 0) {
                  foundPrices.sort((a,b) => a - b);
                  sellers.push({ name: "$storeName", price: foundPrices[0] });
                }
              }

              // ===== STRATEGY 5: Regex on page body text =====
              if (sellers.length === 0) {
                try {
                  let bodyText = document.body ? document.body.innerText : '';
                  let foundPrices = [];
                  // SAR patterns
                  let r1 = /(?:SAR|ريال|ر\.س)\s*([0-9,]+\.?[0-9]*)/gi;
                  let r2 = /([0-9,]+\.?[0-9]*)\s*(?:SAR|ريال|ر\.س)/gi;
                  [r1, r2].forEach(rx => {
                    let m;
                    while ((m = rx.exec(bodyText)) !== null) {
                      let p = parseFloat(m[1].replace(/,/g,''));
                      if (p > 10 && p < 100000) foundPrices.push(p);
                    }
                  });
                  if (foundPrices.length > 0) {
                    foundPrices.sort((a,b) => a - b);
                    let median = foundPrices[Math.floor(foundPrices.length/2)];
                    let valid = foundPrices.filter(p => p >= median * 0.3);
                    if (valid.length === 0) valid = foundPrices;
                    sellers.push({ name: "$storeName (تقريبي)", price: valid[0] });
                  }
                } catch(e5) {}
              }

              // Final: pick lowest price
              if (sellers.length > 0) {
                sellers.sort((a, b) => a.price - b.price);
                price = sellers[0].price;
              }

              return JSON.stringify({
                "price": price,
                "title": title,
                "image": image,
                "sellers": sellers
              });
            })()
          ''';

          final String resultsJson = await controller.evaluateJavascript(
            source: script,
          );
          final data = jsonDecode(resultsJson);

          if (!completer.isCompleted) {
            completer.complete({
              'price': (data['price'] as num?)?.toDouble() ?? 0.0,
              'title': data['title'] ?? 'منتج غير معروف',
              'image': data['image'] ?? '',
              'store': storeName,
              'sellers': data['sellers'] ?? [],
            });
          }
        } catch (e) {
          if (!completer.isCompleted)
            completer.complete({
              'price': 0.0,
              'title': 'خطأ في جلب البيانات',
              'image': '',
              'store': storeName,
              'sellers': [],
            });
        } finally {
          headlessWebView?.dispose();
        }
      },
      onReceivedError: (controller, request, error) {
        // ✅ تجاهل أخطاء الـ sub-resources (صور، فيديوهات، CDN، إلخ)
        // نتدخل بس لو الخطأ في الصفحة الرئيسية نفسها
        if (request.isForMainFrame != true) return;

        if (!completer.isCompleted) {
          completer.complete({
            'price': 0.0,
            'title': 'لا يوجد اتصال بالإنترنت',
            'image': '',
            'store': storeName,
            'sellers': [],
          });
        }
        headlessWebView?.dispose();
      },
    );

    await headlessWebView.run();

    return completer.future.timeout(
      const Duration(seconds: 40),
      onTimeout: () {
        headlessWebView?.dispose();
        return {
          'price': 0.0,
          'title': 'انتهت المهلة، لا يوجد اتصال',
          'image': '',
          'store': storeName,
          'sellers': [],
        };
      },
    );
  }
  // Future<Map<String, dynamic>> _scrapeWithWebView(
  //   String url,
  //   String storeName,
  // ) async {
  //   try {
  //     // استخرج الـ product ID من الرابط
  //     final uri = Uri.parse(url);
  //     final pathParts = uri.pathSegments;
  //     String productId = '';

  //     for (var part in pathParts) {
  //       if (part.startsWith('N') && part.length > 5) {
  //         productId = part;
  //         break;
  //       }
  //     }

  //     if (productId.isEmpty) {
  //       return _fallbackScrape(url, storeName);
  //     }

  //     // نون API مباشرة
  //     final apiUrl =
  //         'https://www.noon.com/api/v2/product/?sku=$productId&country=eg&lang=ar';

  //     final response = await http
  //         .get(
  //           Uri.parse(apiUrl),
  //           headers: {
  //             'User-Agent':
  //                 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
  //             'Accept': 'application/json',
  //             'Accept-Language': 'ar',
  //             'Referer': 'https://www.noon.com/',
  //           },
  //         )
  //         .timeout(const Duration(seconds: 20));

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       final product = data?['product'];

  //       if (product != null) {
  //         final price = (product['price']?['now'] ?? 0).toDouble();
  //         final title = product['name'] ?? 'منتج غير معروف';
  //         final image = product['image_keys']?[0] != null
  //             ? 'https://f.nooncdn.com/p/${product['image_keys'][0]}.jpg'
  //             : '';

  //         return {
  //           'price': price,
  //           'title': title,
  //           'image': image,
  //           'store': storeName,
  //           'sellers': price > 0
  //               ? [
  //                   {'name': storeName, 'price': price},
  //                 ]
  //               : [],
  //         };
  //       }
  //     }

  //     return _fallbackScrape(url, storeName);
  //   } catch (e) {
  //     return _fallbackScrape(url, storeName);
  //   }
  // }

  Future<Map<String, dynamic>> _fallbackScrape(
    String url,
    String storeName,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Linux; Android 10; SM-G975F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
              'Accept-Language': 'ar',
              'Accept': 'text/html',
            },
          )
          .timeout(const Duration(seconds: 20));

      final document = parse(response.body);

      // جرب تجيب السعر من الـ meta tags
      final metaPrice = document.querySelector(
        'meta[property="product:price:amount"]',
      );
      final title =
          document
              .querySelector('meta[property="og:title"]')
              ?.attributes['content'] ??
          '';
      final image =
          document
              .querySelector('meta[property="og:image"]')
              ?.attributes['content'] ??
          '';

      double price = 0.0;
      if (metaPrice != null) {
        price = double.tryParse(metaPrice.attributes['content'] ?? '') ?? 0.0;
      }

      return {
        'price': price,
        'title': price > 0
            ? title
            : 'تعذر جلب البيانات. الرابط قد يكون غير مدعوم حالياً',
        'image': image,
        'store': storeName,
        'sellers': price > 0
            ? [
                {'name': storeName, 'price': price},
              ]
            : [],
      };
    } catch (e) {
      return {
        'price': 0.0,
        'title': 'تعذر جلب البيانات. الرابط قد يكون غير مدعوم حالياً',
        'image': '',
        'store': storeName,
        'sellers': [],
      };
    }
  }

  String _extractTitle(Document document) {
    final ogTitle = document.querySelector('meta[property="og:title"]');
    if (ogTitle != null && ogTitle.attributes.containsKey('content'))
      return ogTitle.attributes['content']!;
    final titleTag = document.querySelector('title');
    if (titleTag != null) return titleTag.text.trim();
    return '';
  }

  String _extractImage(Document document) {
    final ogImage = document.querySelector('meta[property="og:image"]');
    if (ogImage != null && ogImage.attributes.containsKey('content'))
      return ogImage.attributes['content']!;
    return '';
  }

  double _processPricesToLowest(
    List<double> prices,
    List<Map<String, dynamic>> sellersList,
    String storePrefix,
  ) {
    if (prices.isEmpty) return 0.0;
    prices.removeWhere((p) => p <= 0);
    if (prices.isEmpty) return 0.0;
    prices.sort();

    // Filter outliers (e.g. shipping fees of 12 SAR when the median is 4000 SAR)
    double medianPrice = prices[(prices.length / 2).floor()];
    List<double> validPrices = prices
        .where((p) => p >= (medianPrice * 0.3))
        .toList();
    if (validPrices.isEmpty) validPrices = prices;

    final uniquePrices = validPrices.toSet().toList();
    for (int i = 0; i < uniquePrices.length; i++) {
      sellersList.add({
        'name': uniquePrices.length > 1
            ? '$storePrefix (عرض ${i + 1})'
            : storePrefix,
        'price': uniquePrices[i],
      });
    }
    return uniquePrices.first;
  }

  double _parseExtraPrice(
    Document document,
    List<Map<String, dynamic>> sellersList,
  ) {
    final priceElements = document.querySelectorAll('.price, .product-price');
    List<double> foundPrices = [];
    for (var el in priceElements) {
      final parsed = _extractNumber(el.text);
      if (parsed > 0) foundPrices.add(parsed);
    }
    return _processPricesToLowest(foundPrices, sellersList, 'إكسترا');
  }

  double _parseGenericPrice(
    Document document,
    String body,
    List<Map<String, dynamic>> sellersList,
  ) {
    final metaPrices = document.querySelectorAll(
      'meta[itemprop="price"], meta[property="product:price:amount"]',
    );
    List<double> foundPrices = [];
    for (var el in metaPrices) {
      if (el.attributes.containsKey('content')) {
        final parsed = double.tryParse(
          el.attributes['content']!.replaceAll(RegExp(r'[^0-9.]'), ''),
        );
        if (parsed != null && parsed > 0) foundPrices.add(parsed);
      }
    }
    return _processPricesToLowest(foundPrices, sellersList, 'موقع عام');
  }

  double _parseGenericRegexPrice(
    String body,
    List<Map<String, dynamic>> sellersList,
    String storePrefix,
  ) {
    final regex = RegExp(
      r'(?:SAR|ريال|ر\.س)\s*([0-9,]*\.?[0-9]+)|([0-9,]*\.?[0-9]+)\s*(?:SAR|ريال|ر\.س)',
      caseSensitive: false,
    );
    final matches = regex.allMatches(body);
    List<double> foundPrices = [];
    for (var match in matches) {
      String? numStr = match.group(1) ?? match.group(2);
      if (numStr != null) {
        final parsed = _extractNumber(numStr);
        if (parsed > 0) foundPrices.add(parsed);
      }
    }
    if (foundPrices.isEmpty) return 0.0;
    return _processPricesToLowest(foundPrices, sellersList, storePrefix);
  }

  /// نسخة HTTP فقط — للاستخدام من Workmanager بدون WebView
  Future<Map<String, dynamic>> scrapeWithHttpOnly(String url) async {
    try {
      final uri = Uri.tryParse(url.trim());
      if (uri == null || !uri.hasScheme || !uri.scheme.startsWith('http')) {
        return {'price': 0.0, 'title': 'رابط غير صالح', 'image': '', 'store': 'غير معروف', 'sellers': []};
      }
      final host = uri.host.toLowerCase();
      String storeName = host.contains('noon.com')
          ? 'نون'
          : host.contains('amazon.sa')
              ? 'أمازون السعودية'
              : host.replaceAll('www.', '');

      final response = await http
          .get(uri, headers: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 10; SM-G975F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
            'Accept-Language': 'ar,en;q=0.9',
            'Accept': 'text/html,application/xhtml+xml',
          })
          .timeout(const Duration(seconds: 25));

      final document = parse(response.body);

      // 1. meta product:price:amount
      final metaPrice = document.querySelector('meta[property="product:price:amount"]');
      double price = metaPrice != null ? (double.tryParse(metaPrice.attributes['content'] ?? '') ?? 0.0) : 0.0;

      // 2. JSON-LD
      if (price <= 0) {
        for (var script in document.querySelectorAll('script[type="application/ld+json"]')) {
          try {
            final d = jsonDecode(script.innerHtml);
            final items = d is List ? d : [d];
            for (var item in items) {
              final offers = item['offers'];
              if (offers != null) {
                final offerList = offers is List ? offers : [offers];
                for (var o in offerList) {
                  final p = double.tryParse(o['price']?.toString() ?? '') ?? 0.0;
                  if (p > 0) { price = p; break; }
                }
              }
              if (price > 0) break;
            }
          } catch (_) {}
          if (price > 0) break;
        }
      }

      // 3. regex fallback
      if (price <= 0) {
        price = _parseGenericRegexPrice(response.body, [], storeName);
      }

      final title = document.querySelector('meta[property="og:title"]')?.attributes['content'] ??
          document.querySelector('title')?.text.trim() ?? '';
      final image = document.querySelector('meta[property="og:image"]')?.attributes['content'] ?? '';

      return {
        'price': price,
        'title': title.isNotEmpty ? title : 'منتج',
        'image': image,
        'store': storeName,
        'sellers': price > 0 ? [{'name': storeName, 'price': price}] : [],
      };
    } catch (e) {
      return {'price': 0.0, 'title': 'خطأ في الجلب', 'image': '', 'store': 'غير معروف', 'sellers': []};
    }
  }

  double _extractNumber(String text) {
    final cleaned = text.replaceAll(',', '').replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }
}
