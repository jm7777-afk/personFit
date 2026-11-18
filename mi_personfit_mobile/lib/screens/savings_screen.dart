import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/income_model.dart';
import '../models/savings_model.dart';
import '../widgets/custom_dialogs.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<SavingsGoalModel> goals = [];
  List<IncomeModel> incomes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final g = await ApiService().getSavingsGoals();
      final inc = await ApiService().getIncomes();
      if (mounted) {
        setState(() {
          goals = g;
          incomes = inc;
        });
      }
    } catch (e) {
      // Ignorar o mantener
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final totalSavings = goals.fold<double>(0.0, (acc, g) => acc + g.currentAmount);
    final totalIncome = incomes.fold<double>(0.0, (acc, i) => acc + i.amount);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Ingresos & Ahorros'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF10B981),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF10B981),
          tabs: [
            Tab(text: 'Metas de Ahorro (${goals.length})'),
            Tab(text: 'Ingresos (${incomes.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            CustomDialogs.showAddSavingsGoalDialog(
              context: context,
              onConfirm: (data) async {
                await ApiService().createSavingsGoal(data);
                _loadData();
              },
            );
          } else {
            CustomDialogs.showAddIncomeDialog(
              context: context,
              onConfirm: (data) async {
                await ApiService().createIncome(data);
                _loadData();
              },
            );
          }
        },
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Nueva Meta' : 'Nuevo Ingreso'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : TabBarView(
              controller: _tabController,
              children: [
                // 1. Metas de Ahorro
                RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFF10B981),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Resumen
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TOTAL ACUMULADO EN AHORROS',
                                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                currency.format(totalSavings),
                                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tu blindaje financiero contra emergencias y metas',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Tus Fondos y Objetivos',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 12),

                        if (goals.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text('No tienes metas de ahorro aún. ¡Crea una para comenzar a proteger tu dinero!'),
                            ),
                          )
                        else
                          ...goals.map((goal) {
                            final isComplete = goal.progressPercentage >= 100;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isComplete ? const Color(0xFF10B981) : const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          goal.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${goal.progressPercentage.toStringAsFixed(0)}%',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981), fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        currency.format(goal.currentAmount),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                                      ),
                                      Text(
                                        'Meta: ${currency.format(goal.targetAmount)}',
                                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: (goal.progressPercentage / 100).clamp(0.0, 1.0),
                                      minHeight: 8,
                                      backgroundColor: const Color(0xFFF1F5F9),
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        isComplete
                                            ? '🎉 ¡Meta alcanzada!'
                                            : 'Faltan ${currency.format(goal.remainingAmount)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isComplete ? const Color(0xFF10B981) : const Color(0xFF64748B),
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          CustomDialogs.showDepositSavingsDialog(
                                            context: context,
                                            goal: goal,
                                            onConfirm: (amount, date, notes) async {
                                              await ApiService().addSavingsTransaction(goal.id, amount, date, notes: notes);
                                              _loadData();
                                            },
                                          );
                                        },
                                        icon: const Icon(Icons.add, size: 14),
                                        label: const Text('Aportar', style: TextStyle(fontSize: 12)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0F172A),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),

                // 2. Ingresos de Empleo
                RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFF10B981),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TOTAL INGRESOS REGISTRADOS', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text(currency.format(totalIncome), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('Dinero disponible antes de presupuesto', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text('Historial de Ingresos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        const SizedBox(height: 12),

                        if (incomes.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text('No has registrado ingresos aún.'),
                            ),
                          )
                        else
                          ...incomes.map((inc) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.work_outline, color: Color(0xFF10B981), size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(inc.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        Text('${inc.source} • ${inc.date}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '+${currency.format(inc.amount)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF10B981)),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
