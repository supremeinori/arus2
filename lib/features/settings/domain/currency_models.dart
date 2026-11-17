class CurrencyRateModel {
  final String base;
  final dynamic asOf;
  final Map<String, double> rates;

  const CurrencyRateModel({
    this.base = 'IDR',
    this.asOf,
    this.rates = const {'IDR': 1.0, 'USD': 0.000062, 'EUR': 0.000058},
  });

  factory CurrencyRateModel.fromJson(Map<String, dynamic> json) {
    return CurrencyRateModel(
      base: json['base'] as String? ?? 'IDR',
      asOf: json['as_of'] ?? DateTime.now(),
      rates: (json['rates'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          const {'IDR': 1.0},
    );
  }
}
