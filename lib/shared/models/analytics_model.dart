import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Analytics event model for tracking user behavior
class AnalyticsEventModel extends Equatable {
  final String id;
  final String userId;
  final String eventName;
  final String eventCategory;
  final Map<String, dynamic>? eventParameters;
  final String? screenName;
  final String? contentType;
  final String? contentId;
  final double? value;
  final String? currency;
  final String? sessionId;
  final String? deviceId;
  final String? platform;
  final String? appVersion;
  final DateTime createdAt;

  const AnalyticsEventModel({
    required this.id,
    required this.userId,
    required this.eventName,
    required this.eventCategory,
    this.eventParameters,
    this.screenName,
    this.contentType,
    this.contentId,
    this.value,
    this.currency,
    this.sessionId,
    this.deviceId,
    this.platform,
    this.appVersion,
    required this.createdAt,
  });

  factory AnalyticsEventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnalyticsEventModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      eventName: data['eventName'] ?? '',
      eventCategory: data['eventCategory'] ?? '',
      eventParameters: data['eventParameters'],
      screenName: data['screenName'],
      contentType: data['contentType'],
      contentId: data['contentId'],
      value: (data['value'] as num?)?.toDouble(),
      currency: data['currency'],
      sessionId: data['sessionId'],
      deviceId: data['deviceId'],
      platform: data['platform'],
      appVersion: data['appVersion'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'eventName': eventName,
      'eventCategory': eventCategory,
      'eventParameters': eventParameters,
      'screenName': screenName,
      'contentType': contentType,
      'contentId': contentId,
      'value': value,
      'currency': currency,
      'sessionId': sessionId,
      'deviceId': deviceId,
      'platform': platform,
      'appVersion': appVersion,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [id, userId, eventName, createdAt];
}

/// Fighter stock model for gamification/engagement tracking
class FighterStockModel extends Equatable {
  final String id;
  final String fighterId;
  final double currentPrice;
  final double previousPrice;
  final double highPrice;
  final double lowPrice;
  final double openPrice;
  final double volume;
  final double marketCap;
  final int holdersCount;
  final List<PricePoint> priceHistory;
  final DateTime lastUpdated;
  final DateTime createdAt;

  const FighterStockModel({
    required this.id,
    required this.fighterId,
    required this.currentPrice,
    this.previousPrice = 0,
    this.highPrice = 0,
    this.lowPrice = 0,
    this.openPrice = 0,
    this.volume = 0,
    this.marketCap = 0,
    this.holdersCount = 0,
    this.priceHistory = const [],
    required this.lastUpdated,
    required this.createdAt,
  });

  /// Price change from previous
  double get priceChange => currentPrice - previousPrice;

  /// Price change percentage
  double get priceChangePercent {
    if (previousPrice == 0) return 0;
    return (priceChange / previousPrice) * 100;
  }

  /// Is price up
  bool get isPriceUp => priceChange > 0;

  factory FighterStockModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FighterStockModel(
      id: doc.id,
      fighterId: data['fighterId'] ?? '',
      currentPrice: (data['currentPrice'] as num?)?.toDouble() ?? 0,
      previousPrice: (data['previousPrice'] as num?)?.toDouble() ?? 0,
      highPrice: (data['highPrice'] as num?)?.toDouble() ?? 0,
      lowPrice: (data['lowPrice'] as num?)?.toDouble() ?? 0,
      openPrice: (data['openPrice'] as num?)?.toDouble() ?? 0,
      volume: (data['volume'] as num?)?.toDouble() ?? 0,
      marketCap: (data['marketCap'] as num?)?.toDouble() ?? 0,
      holdersCount: data['holdersCount'] ?? 0,
      priceHistory:
          (data['priceHistory'] as List<dynamic>?)
              ?.map((p) => PricePoint.fromMap(p))
              .toList() ??
          [],
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fighterId': fighterId,
      'currentPrice': currentPrice,
      'previousPrice': previousPrice,
      'highPrice': highPrice,
      'lowPrice': lowPrice,
      'openPrice': openPrice,
      'volume': volume,
      'marketCap': marketCap,
      'holdersCount': holdersCount,
      'priceHistory': priceHistory.map((p) => p.toMap()).toList(),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [id, fighterId, currentPrice];
}

/// Price point for price history
class PricePoint extends Equatable {
  final double price;
  final DateTime timestamp;
  final double? volume;

  const PricePoint({required this.price, required this.timestamp, this.volume});

  factory PricePoint.fromMap(Map<String, dynamic> map) {
    return PricePoint(
      price: (map['price'] as num?)?.toDouble() ?? 0,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      volume: (map['volume'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'price': price,
      'timestamp': Timestamp.fromDate(timestamp),
      'volume': volume,
    };
  }

  @override
  List<Object?> get props => [price, timestamp];
}

/// User portfolio model for fighter stock holdings
class UserPortfolioModel extends Equatable {
  final String id;
  final String userId;
  final double balance;
  final double totalValue;
  final double totalInvested;
  final List<StockHolding> holdings;
  final List<Transaction> transactions;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserPortfolioModel({
    required this.id,
    required this.userId,
    this.balance = 0,
    this.totalValue = 0,
    this.totalInvested = 0,
    this.holdings = const [],
    this.transactions = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Portfolio profit/loss
  double get profitLoss => totalValue - totalInvested;

  /// Portfolio profit/loss percentage
  double get profitLossPercent {
    if (totalInvested == 0) return 0;
    return (profitLoss / totalInvested) * 100;
  }

  factory UserPortfolioModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserPortfolioModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      balance: (data['balance'] as num?)?.toDouble() ?? 0,
      totalValue: (data['totalValue'] as num?)?.toDouble() ?? 0,
      totalInvested: (data['totalInvested'] as num?)?.toDouble() ?? 0,
      holdings:
          (data['holdings'] as List<dynamic>?)
              ?.map((h) => StockHolding.fromMap(h))
              .toList() ??
          [],
      transactions:
          (data['transactions'] as List<dynamic>?)
              ?.map((t) => Transaction.fromMap(t))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'balance': balance,
      'totalValue': totalValue,
      'totalInvested': totalInvested,
      'holdings': holdings.map((h) => h.toMap()).toList(),
      'transactions': transactions.map((t) => t.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  List<Object?> get props => [id, userId, balance, totalValue];
}

/// Stock holding in portfolio
class StockHolding extends Equatable {
  final String fighterId;
  final double quantity;
  final double averageBuyPrice;
  final double currentValue;

  const StockHolding({
    required this.fighterId,
    required this.quantity,
    required this.averageBuyPrice,
    this.currentValue = 0,
  });

  /// Holding profit/loss
  double get profitLoss => currentValue - (quantity * averageBuyPrice);

  factory StockHolding.fromMap(Map<String, dynamic> map) {
    return StockHolding(
      fighterId: map['fighterId'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      averageBuyPrice: (map['averageBuyPrice'] as num?)?.toDouble() ?? 0,
      currentValue: (map['currentValue'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fighterId': fighterId,
      'quantity': quantity,
      'averageBuyPrice': averageBuyPrice,
      'currentValue': currentValue,
    };
  }

  @override
  List<Object?> get props => [fighterId, quantity, averageBuyPrice];
}

/// Transaction record
class Transaction extends Equatable {
  final String type; // buy, sell
  final String fighterId;
  final double quantity;
  final double price;
  final double total;
  final DateTime timestamp;

  const Transaction({
    required this.type,
    required this.fighterId,
    required this.quantity,
    required this.price,
    required this.total,
    required this.timestamp,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      type: map['type'] ?? '',
      fighterId: map['fighterId'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'fighterId': fighterId,
      'quantity': quantity,
      'price': price,
      'total': total,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  @override
  List<Object?> get props => [type, fighterId, quantity, timestamp];
}
