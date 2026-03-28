class PriceData {
  final double price;
  final double change;
  final double changePct;
  final String updatedAt;

  const PriceData({
    required this.price,
    required this.change,
    required this.changePct,
    required this.updatedAt,
  });

  factory PriceData.fromJson(Map<String, dynamic> json) => PriceData(
        price: (json['price'] as num).toDouble(),
        change: (json['change'] as num).toDouble(),
        changePct: (json['change_pct'] as num).toDouble(),
        updatedAt: json['updated_at'] as String,
      );
}

class PricesSnapshot {
  final PriceData? au9999;
  final PriceData? xauusd;
  final double? usdcny;
  final bool isStale;

  const PricesSnapshot({
    this.au9999,
    this.xauusd,
    this.usdcny,
    this.isStale = false,
  });

  factory PricesSnapshot.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return PricesSnapshot(
      au9999: data['au9999'] != null ? PriceData.fromJson(data['au9999']) : null,
      xauusd: data['xauusd'] != null ? PriceData.fromJson(data['xauusd']) : null,
      usdcny: data['usdcny'] != null ? (data['usdcny']['price'] as num).toDouble() : null,
    );
  }
}
