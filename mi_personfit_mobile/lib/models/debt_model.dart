class DebtModel {
  final int id;
  final String title;
  final String creditor;
  final double totalAmount;
  final double currentBalance;
  final double monthlyPayment;
  final double interestRate;
  final int dueDay;
  final String nextDueDate;
  final String status;
  final String? paidAt;
  final String? notes;
  final int? daysRemaining;

  DebtModel({
    required this.id,
    required this.title,
    required this.creditor,
    required this.totalAmount,
    required this.currentBalance,
    required this.monthlyPayment,
    required this.interestRate,
    required this.dueDay,
    required this.nextDueDate,
    required this.status,
    this.paidAt,
    this.notes,
    this.daysRemaining,
  });

  bool get isPaid => status == 'pagada' || currentBalance <= 0;
  double get progressPercentage => totalAmount > 0 ? ((totalAmount - currentBalance) / totalAmount) * 100 : 100;

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      id: json['id'] as int,
      title: json['title'] as String,
      creditor: json['creditor'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      currentBalance: (json['current_balance'] as num).toDouble(),
      monthlyPayment: (json['monthly_payment'] as num).toDouble(),
      interestRate: (json['interest_rate'] as num?)?.toDouble() ?? 0.0,
      dueDay: json['due_day'] as int,
      nextDueDate: json['next_due_date'] as String,
      status: json['status'] as String? ?? 'activa',
      paidAt: json['paid_at'] as String?,
      notes: json['notes'] as String?,
      daysRemaining: json['days_remaining'] as int?,
    );
  }
}

class DebtPaymentModel {
  final int id;
  final int debtId;
  final double amount;
  final String paymentDate;
  final String? notes;

  DebtPaymentModel({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.paymentDate,
    this.notes,
  });

  factory DebtPaymentModel.fromJson(Map<String, dynamic> json) {
    return DebtPaymentModel(
      id: json['id'] as int,
      debtId: json['debt_id'] as int,
      amount: (json['amount'] as num).toDouble(),
      paymentDate: json['payment_date'] as String,
      notes: json['notes'] as String?,
    );
  }
}
