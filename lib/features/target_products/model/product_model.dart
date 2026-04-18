// enum DeliveryType { express, market, superMall, normal }

// class ProductSeller {
//   final String name;
//   final double price;

//   ProductSeller({required this.name, required this.price});

//   Map<String, dynamic> toJson() => {'name': name, 'price': price};

//   factory ProductSeller.fromJson(Map<String, dynamic> json) => ProductSeller(
//         name: json['name'],
//         price: json['price'].toDouble(),
//       );
// }

// class ProductModel {
//   final String id;
//   final String title;
//   final String storeName;
//   final double currentPrice;
//   final double targetPrice;
//   final DeliveryType deliveryType;
//   final String imageUrl;
//   final DateTime timeAdded;
//   final int watchers;
//   final String originalUrl;
//   final List<ProductSeller> sellers;
//   final List<double> priceHistory;
//   final DateTime? lastChecked;
//   final bool isAnalyzing;
//   final String? error;

//   ProductModel({
//     required this.id,
//     required this.title,
//     required this.storeName,
//     required this.currentPrice,
//     required this.targetPrice,
//     required this.deliveryType,
//     this.imageUrl = '',
//     required this.timeAdded,
//     this.watchers = 0,
//     required this.originalUrl,
//     this.sellers = const [],
//     this.priceHistory = const [],
//     this.lastChecked,
//     this.isAnalyzing = false,
//     this.error,
//   });

//   bool get hasReachedTarget => currentPrice <= targetPrice && currentPrice > 0;

//   String get url => originalUrl;

//   ProductModel copyWith({
//     String? id,
//     String? title,
//     String? storeName,
//     double? currentPrice,
//     double? targetPrice,
//     DeliveryType? deliveryType,
//     String? imageUrl,
//     DateTime? timeAdded,
//     int? watchers,
//     String? originalUrl,
//     List<ProductSeller>? sellers,
//     List<double>? priceHistory,
//     DateTime? lastChecked,
//     bool? isAnalyzing,
//     String? error,
//   }) {
//     return ProductModel(
//       id: id ?? this.id,
//       title: title ?? this.title,
//       storeName: storeName ?? this.storeName,
//       currentPrice: currentPrice ?? this.currentPrice,
//       targetPrice: targetPrice ?? this.targetPrice,
//       deliveryType: deliveryType ?? this.deliveryType,
//       imageUrl: imageUrl ?? this.imageUrl,
//       timeAdded: timeAdded ?? this.timeAdded,
//       watchers: watchers ?? this.watchers,
//       originalUrl: originalUrl ?? this.originalUrl,
//       sellers: sellers ?? this.sellers,
//       priceHistory: priceHistory ?? this.priceHistory,
//       lastChecked: lastChecked ?? this.lastChecked,
//       isAnalyzing: isAnalyzing ?? this.isAnalyzing,
//       error: error ?? this.error,
//     );
//   }

//   Map<String, dynamic> toJson() => {
//         'id': id,
//         'title': title,
//         'storeName': storeName,
//         'currentPrice': currentPrice,
//         'targetPrice': targetPrice,
//         'deliveryType': deliveryType.index,
//         'imageUrl': imageUrl,
//         'timeAdded': timeAdded.toIso8601String(),
//         'watchers': watchers,
//         'originalUrl': originalUrl,
//         'sellers': sellers.map((s) => s.toJson()).toList(),
//         'priceHistory': priceHistory,
//         'lastChecked': lastChecked?.toIso8601String(),
//         'isAnalyzing': isAnalyzing,
//         'error': error,
//       };

//   factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
//         id: json['id'],
//         title: json['title'],
//         storeName: json['storeName'],
//         currentPrice: json['currentPrice'].toDouble(),
//         targetPrice: json['targetPrice'].toDouble(),
//         deliveryType: DeliveryType.values[json['deliveryType']],
//         imageUrl: json['imageUrl'],
//         timeAdded: DateTime.parse(json['timeAdded']),
//         watchers: json['watchers'],
//         originalUrl: json['originalUrl'],
//         sellers: (json['sellers'] as List?)
//                 ?.map((s) => ProductSeller.fromJson(s))
//                 .toList() ??
//             [],
//         priceHistory: (json['priceHistory'] as List?)
//                 ?.map((p) => p.toDouble())
//                 .toList()
//                 .cast<double>() ??
//             [],
//         lastChecked: json['lastChecked'] != null ? DateTime.parse(json['lastChecked']) : null,
//         isAnalyzing: json['isAnalyzing'] ?? false,
//         error: json['error'],
//       );
// }

enum DeliveryType { express, market, superMall, normal }

class ProductSeller {
  final String name;
  final double price;

  ProductSeller({required this.name, required this.price});

  Map<String, dynamic> toJson() => {'name': name, 'price': price};

  factory ProductSeller.fromJson(Map<String, dynamic> json) =>
      ProductSeller(name: json['name'], price: json['price'].toDouble());
}

class ProductModel {
  final String id;
  final String title;
  final String storeName;
  final double currentPrice;
  final double targetPrice;
  final DeliveryType deliveryType;
  final String imageUrl;
  final DateTime timeAdded;
  final int watchers;
  final String originalUrl;
  final List<ProductSeller> sellers;
  final List<double> priceHistory;
  final DateTime? lastChecked;
  final bool isAnalyzing;
  final String? error;

  ProductModel({
    required this.id,
    required this.title,
    required this.storeName,
    required this.currentPrice,
    required this.targetPrice,
    required this.deliveryType,
    this.imageUrl = '',
    required this.timeAdded,
    this.watchers = 0,
    required this.originalUrl,
    this.sellers = const [],
    this.priceHistory = const [],
    this.lastChecked,
    this.isAnalyzing = false,
    this.error,
  });

  bool get hasReachedTarget => currentPrice <= targetPrice && currentPrice > 0;

  String get url => originalUrl;

  ProductModel copyWith({
    String? id,
    String? title,
    String? storeName,
    double? currentPrice,
    double? targetPrice,
    DeliveryType? deliveryType,
    String? imageUrl,
    DateTime? timeAdded,
    int? watchers,
    String? originalUrl,
    List<ProductSeller>? sellers,
    List<double>? priceHistory,
    DateTime? lastChecked,
    bool? isAnalyzing,
    String? error,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      storeName: storeName ?? this.storeName,
      currentPrice: currentPrice ?? this.currentPrice,
      targetPrice: targetPrice ?? this.targetPrice,
      deliveryType: deliveryType ?? this.deliveryType,
      imageUrl: imageUrl ?? this.imageUrl,
      timeAdded: timeAdded ?? this.timeAdded,
      watchers: watchers ?? this.watchers,
      originalUrl: originalUrl ?? this.originalUrl,
      sellers: sellers ?? this.sellers,
      priceHistory: priceHistory ?? this.priceHistory,
      lastChecked: lastChecked ?? this.lastChecked,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'storeName': storeName,
    'currentPrice': currentPrice,
    'targetPrice': targetPrice,
    'deliveryType': deliveryType.index,
    'imageUrl': imageUrl,
    'timeAdded': timeAdded.toIso8601String(),
    'watchers': watchers,
    'originalUrl': originalUrl,
    'sellers': sellers.map((s) => s.toJson()).toList(),
    'priceHistory': priceHistory,
    'lastChecked': lastChecked?.toIso8601String(),
    'isAnalyzing': isAnalyzing,
    'error': error,
  };

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id: json['id'],
    title: json['title'],
    storeName: json['storeName'],
    currentPrice: json['currentPrice'].toDouble(),
    targetPrice: json['targetPrice'].toDouble(),
    deliveryType: DeliveryType.values[json['deliveryType'] ?? 3],
    imageUrl: json['imageUrl'] ?? '',
    timeAdded: DateTime.parse(json['timeAdded']),
    watchers: json['watchers'] ?? 0,
    originalUrl: json['originalUrl'],
    sellers:
        (json['sellers'] as List?)
            ?.map((s) => ProductSeller.fromJson(s))
            .toList() ??
        [],
    priceHistory:
        (json['priceHistory'] as List?)
            ?.map((p) => p.toDouble())
            .toList()
            .cast<double>() ??
        [],
    lastChecked: json['lastChecked'] != null
        ? DateTime.parse(json['lastChecked'])
        : null,
    isAnalyzing: json['isAnalyzing'] ?? false,
    error: json['error'],
  );
}
