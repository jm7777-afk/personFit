import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/dashboard_model.dart';

class BudgetRuleCard extends StatelessWidget {
  final Map<String, BudgetCategoryTarget> budget;

  const BudgetRuleCard({super.key, required this.budget});

  Widget _buildRow({
    required String title,
    required String rulePercent,
    required double actual,
    required double target,
    required double percentOfIncome,
    required Color color,
    required bool isExceeded,
  }) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final progress = target > 0 ? (actual / target).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              Row(
                children: [
                  Text(
                    currency.format(actual),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isExceeded ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    ' / ${currency.format(target)} ($rulePercent)',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(
                isExceeded ? const Color(0xFFEF4444) : color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final needs = budget['needs'];
    final wants = budget['wants'];
    final savings = budget['savings'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Regla 50 / 30 / 20',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Anti-Desperdicio',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (needs != null)
            _buildRow(
              title: 'Necesidades Básicas & Servicios',
              rulePercent: '50%',
              actual: needs.actualSpent,
              target: needs.targetAmount,
              percentOfIncome: needs.percentageOfIncome,
              color: const Color(0xFF3B82F6),
              isExceeded: needs.status == 'excedido',
            ),
          if (wants != null)
            _buildRow(
              title: 'Compras Personales & Estilo de Vida',
              rulePercent: '30%',
              actual: wants.actualSpent,
              target: wants.targetAmount,
              percentOfIncome: wants.percentageOfIncome,
              color: const Color(0xFFF59E0B),
              isExceeded: wants.status == 'excedido',
            ),
          if (savings != null)
            _buildRow(
              title: 'Ahorro & Fondo de Emergencia',
              rulePercent: '20%',
              actual: savings.actualSpent,
              target: savings.targetAmount,
              percentOfIncome: savings.percentageOfIncome,
              color: const Color(0xFF10B981),
              isExceeded: false,
            ),
        ],
      ),
    );
  }
}
