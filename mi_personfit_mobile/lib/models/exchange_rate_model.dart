class ExchangeRateModel {
  final String id;
  final String currency;
  final String provider;
  final String name;
  final double rate;
  final double previousRate;
  final double changePercent;
  final String lastUpdated;

  ExchangeRateModel({
    required this.id,
    required this.currency,
    required this.provider,
    required this.name,
    required this.rate,
    required this.previousRate,
    required this.changePercent,
    required this.lastUpdated,
  });

  bool get isIncrease => changePercent > 0;
  bool get isDecrease => changePercent < 0;

  factory ExchangeRateModel.fromJson(Map<String, dynamic> json) {
    return ExchangeRateModel(
      id: json['id'] as String,
      currency: json['currency'] as String,
      provider: json['provider'] as String,
      name: json['name'] as String,
      rate: (json['rate'] as num).toDouble(),
      previousRate: (json['previous_rate'] as num).toDouble(),
      changePercent: (json['change_percent'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: json['last_updated'] as String? ?? '',
    );
  }
}

class ExchangeRatesSummaryModel {
  final double usdBcv;
  final double usdBcvChange;
  final double usdParalelo;
  final double usdParaleloChange;
  final double eurBcv;
  final double eurBcvChange;
  final double eurParalelo;
  final double eurParaleloChange;
  final double gapPercentage;
  final List<ExchangeRateModel> rates;

  ExchangeRatesSummaryModel({
    required this.usdBcv,
    required this.usdBcvChange,
    required this.usdParalelo,
    required this.usdParaleloChange,
    required this.eurBcv,
    required this.eurBcvChange,
    required this.eurParalelo,
    required this.eurParaleloChange,
    required this.gapPercentage,
    required this.rates,
  });

  factory ExchangeRatesSummaryModel.fromJson(Map<String, dynamic> json) {
    final s = json['summary'] as Map<String, dynamic>? ?? {};
    final rList = (json['rates'] as List<dynamic>?)
            ?.map((e) => ExchangeRateModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return ExchangeRatesSummaryModel(
      usdBcv: (s['usd_bcv'] as num?)?.toDouble() ?? 0.0,
      usdBcvChange: (s['usd_bcv_change'] as num?)?.toDouble() ?? 0.0,
      usdParalelo: (s['usd_paralelo'] as num?)?.toDouble() ?? 0.0,
      usdParaleloChange: (s['usd_paralelo_change'] as num?)?.toDouble() ?? 0.0,
      eurBcv: (s['eur_bcv'] as num?)?.toDouble() ?? 0.0,
      eurBcvChange: (s['eur_bcv_change'] as num?)?.toDouble() ?? 0.0,
      eurParalelo: (s['eur_paralelo'] as num?)?.toDouble() ?? 0.0,
      eurParaleloChange: (s['eur_paralelo_change'] as num?)?.toDouble() ?? 0.0,
      gapPercentage: (s['exchange_gap_percentage'] as num?)?.toDouble() ?? 0.0,
      rates: rList,
    );
  }
}

class ConversionResultModel {
  final double amount;
  final String from;
  final String to;
  final String rateType;
  final double rateUsed;
  final double result;
  final String formula;
  final double? alternateResult;
  final double? difference;

  ConversionResultModel({
    required this.amount,
    required this.from,
    required this.to,
    required this.rateType,
    required this.rateUsed,
    required this.result,
    required this.formula,
    this.alternateResult,
    this.difference,
  });

  factory ConversionResultModel.fromJson(Map<String, dynamic> json) {
    final comp = json['comparison'] as Map<String, dynamic>?;
    return ConversionResultModel(
      amount: (json['amount'] as num).toDouble(),
      from: json['from'] as String,
      to: json['to'] as String,
      rateType: json['rate_type'] as String,
      rateUsed: (json['rate_used'] as num).toDouble(),
      result: (json['result'] as num).toDouble(),
      formula: json['formula'] as String? ?? '',
      alternateResult: (comp?['alternate_result'] as num?)?.toDouble(),
      difference: (comp?['difference'] as num?)?.toDouble(),
    );
  }
}
