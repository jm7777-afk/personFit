import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/expense_model.dart';
import '../widgets/custom_dialogs.dart';
import '../widgets/currency_calculator_dialog.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<ExpenseModel> expenses = [];
  List<CategoryModel> categories = [];
  bool isLoading = true;
  String selectedFilter = 'todos'; // 'todos', 'servicios', 'compras', 'pendientes'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final cats = await ApiService().getCategories();
      int? isPaidParam;
      String? typeParam;

      if (selectedFilter == 'pendientes') {
        isPaidParam = 0;
      } else if (selectedFilter == 'servicios') {
        typeParam = 'servicio';
      } else if (selectedFilter == 'compras') {
        typeParam = 'compra';
      }

      final exp = await ApiService().getExpenses(isPaid: isPaidParam, type: typeParam);

      if (mounted) {
        setState(() {
          categories = cats;
          expenses = exp;
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
    final totalSpent = expenses.where((e) => e.isPaid).fold<double>(0.0, (acc, e) => acc + e.amount);
    final pendingTotal = expenses.where((e) => !e.isPaid).fold<double>(0.0, (acc, e) => acc + e.amount);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Compras & Servicios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined, color: Color(0xFF10B981)),
            tooltip: 'Calculadora de Divisas',
            onPressed: () => CurrencyCalculatorDialog.show(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          CustomDialogs.showAddExpenseDialog(
            context: context,
            categories: categories,
            onConfirm: (data) async {
              await ApiService().createExpense(data);
              _loadData();
            },
          );
        },
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Gasto'),
      ),
      body: Column(
        children: [
          // Banner de totales del mes
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Pagado', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      Text(currency.format(totalSpent), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Facturas por Pagar', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      Text(currency.format(pendingTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFEF4444))),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Chips de filtro
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('Todos', 'todos'),
                _buildFilterChip('Servicios Fijos', 'servicios'),
                _buildFilterChip('Compras Diarias', 'compras'),
                _buildFilterChip('Facturas Pendientes', 'pendientes'),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Lista de gastos
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: const Color(0xFF10B981),
                    child: expenses.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 56, color: Color(0xFF94A3B8)),
                                SizedBox(height: 12),
                                Text('No hay gastos registrados en esta sección', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: expenses.length,
                            itemBuilder: (context, index) {
                              final item = expenses[index];
                              final isService = item.isService;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: !item.isPaid ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isService
                                            ? const Color(0xFFF59E0B).withOpacity(0.12)
                                            : const Color(0xFF6366F1).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isService ? Icons.bolt : Icons.shopping_cart_outlined,
                                        color: isService ? const Color(0xFFF59E0B) : const Color(0xFF6366F1),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${item.categoryName ?? 'Gasto'} • ${item.date}',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                          ),
                                          if (!item.isPaid && item.dueDate != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                '⏰ Vence el ${item.dueDate}',
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          currency.format(item.amount),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                        ),
                                        const SizedBox(height: 4),
                                        if (!item.isPaid)
                                          GestureDetector(
                                            onTap: () async {
                                              await ApiService().markExpenseAsPaid(item.id);
                                              _loadData();
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF10B981),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text('Pagar', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                          )
                                        else
                                          const Text('Pagado', style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF475569),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF0F172A),
        showCheckmark: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
        ),
        onSelected: (val) {
          setState(() => selectedFilter = value);
          _loadData();
        },
      ),
    );
  }
}
