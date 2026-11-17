class PayrollSummary {
  final bool hasIncomeConfigured;
  final String incomeTitle;
  final String frequency;
  final String frequencyLabel;
  final int daysRemaining;
  final String nextPayoutDate;
  final double expectedSalaryUsd;
  final double expectedSalaryBs;
  final double totalDeductionsUsd;
  final double totalDeductionsBs;
  final double netRemainingUsd;
  final double netRemainingBs;
  final double percentFree;
  final List<PayrollDeduction> deductions;

  PayrollSummary({
    required this.hasIncomeConfigured,
    required this.incomeTitle,
    required this.frequency,
    required this.frequencyLabel,
    required this.daysRemaining,
    required this.nextPayoutDate,
    required this.expectedSalaryUsd,
    required this.expectedSalaryBs,
    required this.totalDeductionsUsd,
    required this.totalDeductionsBs,
    required this.netRemainingUsd,
    required this.netRemainingBs,
    required this.percentFree,
    required this.deductions,
  });

  factory PayrollSummary.fromJson(Map<String, dynamic> json) {
    return PayrollSummary(
      hasIncomeConfigured: json['has_income_configured'] ?? false,
      incomeTitle: json['income_title'] ?? 'Nómina',
      frequency: json['frequency'] ?? 'quincenal',
      frequencyLabel: json['frequency_label'] ?? 'Quincenal',
      daysRemaining: (json['days_remaining'] as num?)?.toInt() ?? 0,
      nextPayoutDate: json['next_payout_date'] ?? '',
      expectedSalaryUsd: (json['expected_salary_usd'] as num?)?.toDouble() ?? 0.0,
      expectedSalaryBs: (json['expected_salary_bs'] as num?)?.toDouble() ?? 0.0,
      totalDeductionsUsd: (json['total_deductions_usd'] as num?)?.toDouble() ?? 0.0,
      totalDeductionsBs: (json['total_deductions_bs'] as num?)?.toDouble() ?? 0.0,
      netRemainingUsd: (json['net_remaining_usd'] as num?)?.toDouble() ?? 0.0,
      netRemainingBs: (json['net_remaining_bs'] as num?)?.toDouble() ?? 0.0,
      percentFree: (json['percent_free'] as num?)?.toDouble() ?? 100.0,
      deductions: (json['deductions_breakdown'] as List? ?? [])
          .map((d) => PayrollDeduction.fromJson(d))
          .toList(),
    );
  }
}

class PayrollDeduction {
  final String type;
  final String title;
  final String creditor;
  final double amountUsd;
  final double amountBs;
  final String dueDate;

  PayrollDeduction({
    required this.type,
    required this.title,
    required this.creditor,
    required this.amountUsd,
    required this.amountBs,
    required this.dueDate,
  });

  factory PayrollDeduction.fromJson(Map<String, dynamic> json) {
    return PayrollDeduction(
      type: json['type'] ?? 'deuda',
      title: json['title'] ?? '',
      creditor: json['creditor'] ?? '',
      amountUsd: (json['amount_usd'] as num?)?.toDouble() ?? 0.0,
      amountBs: (json['amount_bs'] as num?)?.toDouble() ?? 0.0,
      dueDate: json['due_date'] ?? '',
    );
  }
}

class PayrollCalendarItem {
  final int payoutNumber;
  final String date;
  final String frequency;
  final String frequencyLabel;
  final double expectedAmount;
  final String currency;

  PayrollCalendarItem({
    required this.payoutNumber,
    required this.date,
    required this.frequency,
    required this.frequencyLabel,
    required this.expectedAmount,
    required this.currency,
  });

  factory PayrollCalendarItem.fromJson(Map<String, dynamic> json) {
    return PayrollCalendarItem(
      payoutNumber: json['payout_number'] ?? 1,
      date: json['date'] ?? '',
      frequency: json['frequency'] ?? 'mensual',
      frequencyLabel: json['frequency_label'] ?? 'Mensual',
      expectedAmount: (json['expected_amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'USD',
    );
  }
}
