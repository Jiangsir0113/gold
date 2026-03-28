class Transaction {
  final int id;
  final DateTime date;
  final String type; // 'buy' | 'sell'
  final double grams;
  final double pricePerG;
  final double fee;
  final String? note;

  const Transaction({
    required this.id,
    required this.date,
    required this.type,
    required this.grams,
    required this.pricePerG,
    required this.fee,
    this.note,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as int,
        date: DateTime.parse(json['date'] as String),
        type: json['type'] as String,
        grams: (json['grams'] as num).toDouble(),
        pricePerG: (json['price_per_g'] as num).toDouble(),
        fee: (json['fee'] as num).toDouble(),
        note: json['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'type': type,
        'grams': grams,
        'price_per_g': pricePerG,
        'fee': fee,
        'note': note,
      };
}
