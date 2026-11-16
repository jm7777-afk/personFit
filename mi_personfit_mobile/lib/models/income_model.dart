class IncomeModel {
  final int id;
  final String title;
  final double amount;
  final String source;
  final String frequency;
  final String date;
  final String? notes;

  IncomeModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.source,
    required this.frequency,
    required this.date,
    this.notes,
  });

  factory IncomeModel.fromJson(Map<String, dynamic> json) {
    return IncomeModel(
      id: json['id'] as int,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      source: json['source'] as String,
      frequency: json['frequency'] as String,
      date: json['date'] as String,
      notes: json['notes'] as String?,
    );
  }
}
