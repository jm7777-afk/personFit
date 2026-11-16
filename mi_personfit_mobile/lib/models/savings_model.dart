class SavingsGoalModel {
  final int id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final String? targetDate;
  final String priority;
  final String? notes;
  final double progressPercentage;
  final double remainingAmount;

  SavingsGoalModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    this.targetDate,
    required this.priority,
    this.notes,
    required this.progressPercentage,
    required this.remainingAmount,
  });

  factory SavingsGoalModel.fromJson(Map<String, dynamic> json) {
    return SavingsGoalModel(
      id: json['id'] as int,
      title: json['title'] as String,
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0.0,
      targetDate: json['target_date'] as String?,
      priority: json['priority'] as String? ?? 'media',
      notes: json['notes'] as String?,
      progressPercentage: (json['progress_percentage'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remaining_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
