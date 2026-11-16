class CategoryModel {
  final int id;
  final String name;
  final String type; // 'servicio', 'compra', 'obligatorio', 'deseo'
  final String? icon;
  final double monthlyBudget;

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    required this.monthlyBudget,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      icon: json['icon'] as String?,
      monthlyBudget: (json['monthly_budget'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ExpenseModel {
  final int id;
  final String title;
  final double amount;
  final int categoryId;
  final String? categoryName;
  final String? categoryType;
  final String? categoryIcon;
  final String date;
  final String? dueDate;
  final bool isPaid;
  final String paymentMethod;
  final String? notes;
  final int? daysRemaining;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    this.categoryName,
    this.categoryType,
    this.categoryIcon,
    required this.date,
    this.dueDate,
    required this.isPaid,
    required this.paymentMethod,
    this.notes,
    this.daysRemaining,
  });

  bool get isService => categoryType == 'servicio' || dueDate != null;

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as int,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      categoryId: json['category_id'] as int,
      categoryName: json['category_name'] as String?,
      categoryType: json['category_type'] as String?,
      categoryIcon: json['category_icon'] as String?,
      date: json['date'] as String,
      dueDate: json['due_date'] as String?,
      isPaid: (json['is_paid'] as int? ?? 1) == 1,
      paymentMethod: json['payment_method'] as String? ?? 'efectivo',
      notes: json['notes'] as String?,
      daysRemaining: json['days_remaining'] as int?,
    );
  }
}
