import 'debt_model.dart';
import 'expense_model.dart';
import 'savings_model.dart';

class CashflowModel {
  final double totalIncome;
  final double totalExpenses;
  final double netBalance;
  final double savingsRate;

  CashflowModel({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netBalance,
    required this.savingsRate,
  });

  factory CashflowModel.fromJson(Map<String, dynamic> json) {
    return CashflowModel(
      totalIncome: (json['total_income'] as num).toDouble(),
      totalExpenses: (json['total_expenses'] as num).toDouble(),
      netBalance: (json['net_balance'] as num).toDouble(),
      savingsRate: (json['savings_rate'] as num).toDouble(),
    );
  }
}

class FinancialHealthModel {
  final int score;
  final String status;
  final List<String> recommendations;

  FinancialHealthModel({
    required this.score,
    required this.status,
    required this.recommendations,
  });

  factory FinancialHealthModel.fromJson(Map<String, dynamic> json) {
    return FinancialHealthModel(
      score: json['score'] as int,
      status: json['status'] as String,
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class BudgetCategoryTarget {
  final String category;
  final double targetAmount;
  final double actualSpent;
  final double percentageOfIncome;
  final String status;

  BudgetCategoryTarget({
    required this.category,
    required this.targetAmount,
    required this.actualSpent,
    required this.percentageOfIncome,
    required this.status,
  });

  factory BudgetCategoryTarget.fromJson(Map<String, dynamic> json) {
    return BudgetCategoryTarget(
      category: json['category'] as String,
      targetAmount: (json['target_amount'] as num).toDouble(),
      actualSpent: (json['actual_spent'] as num?)?.toDouble() ?? (json['actual_available'] as num?)?.toDouble() ?? 0.0,
      percentageOfIncome: (json['percentage_of_income'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String,
    );
  }
}

class DashboardModel {
  final String month;
  final CashflowModel cashflow;
  final FinancialHealthModel financialHealth;
  final Map<String, BudgetCategoryTarget> budget503020;
  final double totalOutstandingDebt;
  final int urgentDebtsCount;
  final List<DebtModel> upcomingDebts;
  final int urgentBillsCount;
  final List<ExpenseModel> upcomingBills;
  final double totalAccumulatedSavings;
  final int activeGoalsCount;
  final List<SavingsGoalModel> goals;

  DashboardModel({
    required this.month,
    required this.cashflow,
    required this.financialHealth,
    required this.budget503020,
    required this.totalOutstandingDebt,
    required this.urgentDebtsCount,
    required this.upcomingDebts,
    required this.urgentBillsCount,
    required this.upcomingBills,
    required this.totalAccumulatedSavings,
    required this.activeGoalsCount,
    required this.goals,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final bMap = <String, BudgetCategoryTarget>{};
    if (json['budget_rule_50_30_20'] != null) {
      final b = json['budget_rule_50_30_20'] as Map<String, dynamic>;
      if (b['needs'] != null) bMap['needs'] = BudgetCategoryTarget.fromJson(b['needs']);
      if (b['wants'] != null) bMap['wants'] = BudgetCategoryTarget.fromJson(b['wants']);
      if (b['savings_and_debts'] != null) bMap['savings'] = BudgetCategoryTarget.fromJson(b['savings_and_debts']);
    }

    final dOverview = json['debts_overview'] as Map<String, dynamic>? ?? {};
    final bRadar = json['upcoming_bills_radar'] as Map<String, dynamic>? ?? {};
    final sOverview = json['savings_overview'] as Map<String, dynamic>? ?? {};

    return DashboardModel(
      month: json['month'] as String? ?? '',
      cashflow: CashflowModel.fromJson(json['cashflow'] as Map<String, dynamic>),
      financialHealth: FinancialHealthModel.fromJson(json['financial_health'] as Map<String, dynamic>),
      budget503020: bMap,
      totalOutstandingDebt: (dOverview['total_outstanding_debt'] as num?)?.toDouble() ?? 0.0,
      urgentDebtsCount: dOverview['urgent_debts_count'] as int? ?? 0,
      upcomingDebts: (dOverview['upcoming_debts'] as List<dynamic>?)
              ?.map((e) => DebtModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      urgentBillsCount: bRadar['urgent_bills_count'] as int? ?? 0,
      upcomingBills: (bRadar['upcoming_bills'] as List<dynamic>?)
              ?.map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalAccumulatedSavings: (sOverview['total_accumulated_savings'] as num?)?.toDouble() ?? 0.0,
      activeGoalsCount: sOverview['active_goals_count'] as int? ?? 0,
      goals: (sOverview['goals'] as List<dynamic>?)
              ?.map((e) => SavingsGoalModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
