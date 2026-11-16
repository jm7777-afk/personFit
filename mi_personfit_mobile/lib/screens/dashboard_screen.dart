import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/dashboard_model.dart';
import '../widgets/metric_card.dart';
import '../widgets/health_score_gauge.dart';
import '../widgets/budget_progress_bar.dart';
import '../widgets/custom_dialogs.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onNavigateToDebts;
  final VoidCallback onNavigateToExpenses;

  const DashboardScreen({
    super.key,
    required this.onNavigateToDebts,
    required this.onNavigateToExpenses,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardModel? dashboard;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final data = await ApiService().getDashboard();
      if (mounted) setState(() => dashboard = data);
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final user = ApiService().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user != null ? 'Hola, ${user.name.split(' ').first} 👋' : 'Mi PersonFit 💰',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const Text(
              'Administrador Financiero Activo',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off, size: 48, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        Text(
                          'No se pudo conectar a la API:\n$error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadDashboard,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  color: const Color(0xFF10B981),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tarjeta Principal de Balance Neto
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'BALANCE NETO DEL MES',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${dashboard!.cashflow.savingsRate}% Ahorro',
                                      style: const TextStyle(
                                        color: Color(0xFF10B981),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currency.format(dashboard!.cashflow.netBalance),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.arrow_downward, color: Color(0xFF10B981), size: 16),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Ingresos', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                                            Text(
                                              currency.format(dashboard!.cashflow.totalIncome),
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEF4444).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.arrow_upward, color: Color(0xFFEF4444), size: 16),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Gastos', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                                            Text(
                                              currency.format(dashboard!.cashflow.totalExpenses),
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Radar de Alertas / Vencimientos Urgentes
                        if (dashboard!.urgentDebtsCount > 0 || dashboard!.urgentBillsCount > 0)
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.notification_important, color: Color(0xFFD97706), size: 28),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Radar de Vencimientos (Próximos 15 días)',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E), fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${dashboard!.urgentDebtsCount} cuota(s) de deuda y ${dashboard!.urgentBillsCount} factura(s) de servicio por pagar.',
                                        style: const TextStyle(color: Color(0xFFB45309), fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: widget.onNavigateToDebts,
                                  child: const Text('Revisar', style: TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),

                        // Medidor de Salud Financiera
                        HealthScoreGauge(
                          score: dashboard!.financialHealth.score,
                          status: dashboard!.financialHealth.status,
                          recommendations: dashboard!.financialHealth.recommendations,
                        ),
                        const SizedBox(height: 20),

                        // Tarjeta Regla 50/30/20
                        BudgetRuleCard(budget: dashboard!.budget503020),
                        const SizedBox(height: 20),

                        // Métricas Rápidas: Deuda Activa vs Ahorros
                        Row(
                          children: [
                            Expanded(
                              child: MetricCard(
                                title: 'Deuda Total',
                                value: currency.format(dashboard!.totalOutstandingDebt),
                                subtitle: '${dashboard!.upcomingDebts.length} activas',
                                icon: Icons.credit_card,
                                iconColor: const Color(0xFFEF4444),
                                onTap: widget.onNavigateToDebts,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: MetricCard(
                                title: 'Total Ahorros',
                                value: currency.format(dashboard!.totalAccumulatedSavings),
                                subtitle: '${dashboard!.activeGoalsCount} metas',
                                icon: Icons.savings,
                                iconColor: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Botones Rápidos
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final cats = await ApiService().getCategories();
                                  if (context.mounted) {
                                    CustomDialogs.showAddExpenseDialog(
                                      context: context,
                                      categories: cats,
                                      onConfirm: (data) async {
                                        await ApiService().createExpense(data);
                                        _loadDashboard();
                                      },
                                    );
                                  }
                                },
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Gasto'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  CustomDialogs.showAddIncomeDialog(
                                    context: context,
                                    onConfirm: (data) async {
                                      await ApiService().createIncome(data);
                                      _loadDashboard();
                                    },
                                  );
                                },
                                icon: const Icon(Icons.attach_money, size: 18),
                                label: const Text('Ingreso'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }
}
