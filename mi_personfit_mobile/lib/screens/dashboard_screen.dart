import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/dashboard_model.dart';
import '../models/exchange_rate_model.dart';
import '../models/payroll_model.dart';
import '../widgets/metric_card.dart';
import '../widgets/health_score_gauge.dart';
import '../widgets/custom_dialogs.dart';
import '../widgets/exchange_rate_ticker.dart';
import '../widgets/payroll_card.dart';
import '../widgets/payroll_calendar_dialog.dart';
import '../widgets/standard_calculator_dialog.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onNavigateToDebts;
  final VoidCallback onNavigateToExpenses;
  final VoidCallback? onNavigateToGroceries;

  const DashboardScreen({
    super.key,
    required this.onNavigateToDebts,
    required this.onNavigateToExpenses,
    this.onNavigateToGroceries,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardModel? dashboard;
  ExchangeRatesSummaryModel? exchangeRates;
  PayrollSummary? payroll;
  bool showInBs = false;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    showInBs = ApiService().showInBs;
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final data = await ApiService().getDashboard();
      ExchangeRatesSummaryModel? rates;
      try {
        rates = await ApiService().getExchangeRates();
      } catch (_) {}

      PayrollSummary? payrollSummary;
      try {
        payrollSummary = await ApiService().getPayrollSummary();
      } catch (_) {}

      if (mounted) {
        setState(() {
          dashboard = data;
          exchangeRates = rates;
          payroll = payrollSummary;
          showInBs = ApiService().showInBs;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,##0.00', 'es_VE');
    final symbol = showInBs ? 'Bs.' : '\$';
    final user = ApiService().currentUser;
    final bcvRate = ApiService().activeBcvRate;

    double convert(double usd) => showInBs ? usd * bcvRate : usd;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user != null ? 'Hola, ${user.name.split(' ').first} 👋' : 'Kryon 💰',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const Text(
              'Administrador Financiero Activo',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          // Conmutador Moneda Global ($ USD | Bs. VES)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: InkWell(
              onTap: () {
                setState(() => showInBs = !showInBs);
                ApiService().setCurrencyPreference(showInBs);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: showInBs ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(
                      showInBs ? 'Bs. VES' : '\$ USD',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.sync_alt, color: Colors.white, size: 12),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Calculadora Estándar con Tasa
          IconButton(
            icon: const Icon(Icons.calculate_outlined, color: Color(0xFF6366F1)),
            tooltip: 'Calculadora Estándar con Tasa',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const StandardCalculatorDialog(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off, size: 64, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 16),
                        Text(
                          error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadDashboard,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : dashboard == null
                  ? const SizedBox()
                  : RefreshIndicator(
                      onRefresh: _loadDashboard,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tarjeta de Balance General del Mes
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(22),
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
                                        'BALANCE NETO DISPONIBLE',
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
                                    '$symbol ${currencyFmt.format(convert(dashboard!.cashflow.netBalance))}',
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
                                                  '$symbol ${currencyFmt.format(convert(dashboard!.cashflow.totalIncome))}',
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
                                                  '$symbol ${currencyFmt.format(convert(dashboard!.cashflow.totalExpenses))}',
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
                            const SizedBox(height: 18),

                            // Ticker de Tasas de Cambio en Venezuela (BCV & Paralelo)
                            ExchangeRateTicker(rates: exchangeRates),
                            const SizedBox(height: 18),

                            // CONTROL DE NÓMINA, CONTADOR DE DÍAS Y SUELDO RESTANTE SIN COBRAR
                            if (payroll != null) ...[
                              PayrollCard(
                                payroll: payroll!,
                                showInBs: showInBs,
                                onRefresh: _loadDashboard,
                                onOpenCalendar: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => PayrollCalendarDialog(
                                      payroll: payroll!,
                                      showInBs: showInBs,
                                    ),
                                  );
                                },
                                onAddLoan: () {
                                  CustomDialogs.showBorrowMoneyDialog(
                                    context: context,
                                    onConfirm: ({
                                      required creditor,
                                      required amount,
                                      required currency,
                                      required dueDate,
                                      required deductFromSalary,
                                      notes,
                                    }) async {
                                      await ApiService().createBorrowedMoney(
                                        creditor: creditor,
                                        amount: amount,
                                        currency: currency,
                                        dueDate: dueDate,
                                        deductFromSalary: deductFromSalary,
                                        notes: notes,
                                      );
                                      _loadDashboard();
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 18),
                            ],

                            // Radar de Alertas / Vencimientos Urgentes
                            if (dashboard!.urgentDebtsCount > 0 || dashboard!.urgentBillsCount > 0)
                              Container(
                                margin: const EdgeInsets.only(bottom: 18),
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
                                            '${dashboard!.urgentDebtsCount} cuota(s) de deuda y ${dashboard!.urgentBillsCount} factura(s) por pagar.',
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
                            const SizedBox(height: 18),

                            // Resumen de Deudas y Ahorros
                            Row(
                              children: [
                                Expanded(
                                  child: MetricCard(
                                    title: 'Deuda Total',
                                    value: '$symbol ${currencyFmt.format(convert(dashboard!.totalOutstandingDebt))}',
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
                                    value: '$symbol ${currencyFmt.format(convert(dashboard!.totalAccumulatedSavings))}',
                                    subtitle: '${dashboard!.activeGoalsCount} metas',
                                    icon: Icons.savings,
                                    iconColor: const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // BOTONES DE ACCIÓN RÁPIDA (Fila 1: Gasto / Ingreso)
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
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
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
                                    label: const Text('Salario / Ingreso'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // BOTONES DE ACCIÓN RÁPIDA (Fila 2: Pedí Prestado / Lista Súper)
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      CustomDialogs.showBorrowMoneyDialog(
                                        context: context,
                                        onConfirm: ({
                                          required creditor,
                                          required amount,
                                          required currency,
                                          required dueDate,
                                          required deductFromSalary,
                                          notes,
                                        }) async {
                                          await ApiService().createBorrowedMoney(
                                            creditor: creditor,
                                            amount: amount,
                                            currency: currency,
                                            dueDate: dueDate,
                                            deductFromSalary: deductFromSalary,
                                            notes: notes,
                                          );
                                          _loadDashboard();
                                        },
                                      );
                                    },
                                    icon: const Icon(Icons.handshake_outlined, size: 18, color: Color(0xFFEF4444)),
                                    label: const Text('Pedí Prestado (+)', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFFEF4444)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: widget.onNavigateToGroceries,
                                    icon: const Icon(Icons.shopping_cart_outlined, size: 18, color: Color(0xFF6366F1)),
                                    label: const Text('Lista Supermercado', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFF6366F1)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
    );
  }
}
