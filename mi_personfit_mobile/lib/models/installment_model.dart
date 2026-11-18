class InstallmentPaymentModel {
  final int id;
  final int planId;
  final int installmentNumber;
  final double amount;
  final String dueDate;
  final bool isPaid;
  final String? paidAt;

  InstallmentPaymentModel({
    required this.id,
    required this.planId,
    required this.installmentNumber,
    required this.amount,
    required this.dueDate,
    required this.isPaid,
    this.paidAt,
  });

  factory InstallmentPaymentModel.fromJson(Map<String, dynamic> json) {
    return InstallmentPaymentModel(
      id: json['id'] as int,
      planId: json['plan_id'] as int,
      installmentNumber: json['installment_number'] as int? ?? 1,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: json['due_date'] as String? ?? '',
      isPaid: json['is_paid'] == 1 || json['is_paid'] == true,
      paidAt: json['paid_at'] as String?,
    );
  }
}

class InstallmentPlanModel {
  final int id;
  final String provider;
  final String merchantName;
  final String title;
  final double totalAmount;
  final double initialPaid;
  final double remainingAmount;
  final int installmentsCount;
  final int intervalDays;
  final String purchaseDate;
  final String status;
  final bool deductFromSalary;
  final int paidInstallments;
  final InstallmentPaymentModel? nextPayment;
  final List<InstallmentPaymentModel> payments;

  InstallmentPlanModel({
    required this.id,
    required this.provider,
    required this.merchantName,
    required this.title,
    required this.totalAmount,
    required this.initialPaid,
    required this.remainingAmount,
    required this.installmentsCount,
    required this.intervalDays,
    required this.purchaseDate,
    required this.status,
    required this.deductFromSalary,
    required this.paidInstallments,
    this.nextPayment,
    required this.payments,
  });

  factory InstallmentPlanModel.fromJson(Map<String, dynamic> json) {
    return InstallmentPlanModel(
      id: json['id'] as int,
      provider: json['provider'] as String? ?? 'Cashea',
      merchantName: json['merchant_name'] as String? ?? 'Comercio',
      title: json['title'] as String? ?? 'Compra en cuotas',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      initialPaid: (json['initial_paid'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remaining_amount'] as num?)?.toDouble() ?? 0.0,
      installmentsCount: json['installments_count'] as int? ?? 3,
      intervalDays: json['interval_days'] as int? ?? 14,
      purchaseDate: json['purchase_date'] as String? ?? '',
      status: json['status'] as String? ?? 'activa',
      deductFromSalary: json['deduct_from_salary'] == 1 || json['deduct_from_salary'] == true,
      paidInstallments: json['paid_installments'] as int? ?? 0,
      nextPayment: json['next_payment'] != null
          ? InstallmentPaymentModel.fromJson(json['next_payment'] as Map<String, dynamic>)
          : null,
      payments: (json['payments'] as List<dynamic>? ?? [])
          .map((e) => InstallmentPaymentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class InstallmentsSummaryModel {
  final List<InstallmentPlanModel> plans;
  final double upcoming14DaysUsd;
  final double totalPendingUsd;
  final int activePlansCount;

  InstallmentsSummaryModel({
    required this.plans,
    required this.upcoming14DaysUsd,
    required this.totalPendingUsd,
    required this.activePlansCount,
  });

  factory InstallmentsSummaryModel.fromJson(Map<String, dynamic> json) {
    return InstallmentsSummaryModel(
      plans: (json['plans'] as List<dynamic>? ?? [])
          .map((e) => InstallmentPlanModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      upcoming14DaysUsd: (json['upcoming_14_days_usd'] as num?)?.toDouble() ?? 0.0,
      totalPendingUsd: (json['total_pending_usd'] as num?)?.toDouble() ?? 0.0,
      activePlansCount: json['active_plans_count'] as int? ?? 0,
    );
  }
}
