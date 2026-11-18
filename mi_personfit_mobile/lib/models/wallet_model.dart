class WalletModel {
  final int id;
  final String name;
  final String walletType;
  final String currency;
  final double balance;
  final String? accountDetails;
  final String colorHex;
  final double equivalentUsd;
  final double equivalentBs;

  WalletModel({
    required this.id,
    required this.name,
    required this.walletType,
    required this.currency,
    required this.balance,
    this.accountDetails,
    required this.colorHex,
    required this.equivalentUsd,
    required this.equivalentBs,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Billetera',
      walletType: json['wallet_type'] as String? ?? 'otro',
      currency: json['currency'] as String? ?? 'USD',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      accountDetails: json['account_details'] as String?,
      colorHex: json['color'] as String? ?? '#6366F1',
      equivalentUsd: (json['equivalent_usd'] as num?)?.toDouble() ?? 0.0,
      equivalentBs: (json['equivalent_bs'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class WalletsSummaryModel {
  final List<WalletModel> wallets;
  final double totalUsd;
  final double totalBs;
  final double bcvRate;

  WalletsSummaryModel({
    required this.wallets,
    required this.totalUsd,
    required this.totalBs,
    required this.bcvRate,
  });

  factory WalletsSummaryModel.fromJson(Map<String, dynamic> json) {
    return WalletsSummaryModel(
      wallets: (json['wallets'] as List<dynamic>? ?? [])
          .map((e) => WalletModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalUsd: (json['total_usd'] as num?)?.toDouble() ?? 0.0,
      totalBs: (json['total_bs'] as num?)?.toDouble() ?? 0.0,
      bcvRate: (json['bcv_rate'] as num?)?.toDouble() ?? 914.02,
    );
  }
}
