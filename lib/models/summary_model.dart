class PositionSummary {
  final double totalGrams;
  final double avgCostPerG;
  final double currentPrice;
  final double marketValue;
  final double unrealizedPnl;
  final double unrealizedPnlPct;
  final double realizedPnl;
  final double totalPnl;

  const PositionSummary({
    required this.totalGrams,
    required this.avgCostPerG,
    required this.currentPrice,
    required this.marketValue,
    required this.unrealizedPnl,
    required this.unrealizedPnlPct,
    required this.realizedPnl,
    required this.totalPnl,
  });

  factory PositionSummary.fromJson(Map<String, dynamic> json) => PositionSummary(
        totalGrams: (json['total_grams'] as num).toDouble(),
        avgCostPerG: (json['avg_cost_per_g'] as num).toDouble(),
        currentPrice: (json['current_price'] as num).toDouble(),
        marketValue: (json['market_value'] as num).toDouble(),
        unrealizedPnl: (json['unrealized_pnl'] as num).toDouble(),
        unrealizedPnlPct: (json['unrealized_pnl_pct'] as num).toDouble(),
        realizedPnl: (json['realized_pnl'] as num).toDouble(),
        totalPnl: (json['total_pnl'] as num).toDouble(),
      );
}
