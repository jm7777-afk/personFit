class NotificationModel {
  final String id;
  final String type; // 'debt_overdue', 'debt_due_today', 'debt_due_soon', 'bill_due', 'celebration'
  final String priority; // 'urgent', 'high', 'medium', 'positive'
  final String title;
  final String message;
  final int? debtId;
  final int? expenseId;
  final String? dueDate;
  final double? amountDue;
  final String? action;

  NotificationModel({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    this.debtId,
    this.expenseId,
    this.dueDate,
    this.amountDue,
    this.action,
  });

  bool get isUrgent => priority == 'urgent' || priority == 'high';

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      type: json['type'] as String,
      priority: json['priority'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      debtId: json['debt_id'] as int?,
      expenseId: json['expense_id'] as int?,
      dueDate: json['due_date'] as String?,
      amountDue: (json['amount_due'] as num?)?.toDouble(),
      action: json['action'] as String?,
    );
  }
}
