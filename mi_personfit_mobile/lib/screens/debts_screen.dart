import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/debt_model.dart';
import '../widgets/debt_card.dart';
import '../widgets/custom_dialogs.dart';
import '../widgets/standard_calculator_dialog.dart';
import '../widgets/cashea_installments_dialog.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<DebtModel> activeDebts = [];
  List<DebtModel> paidDebts = [];
  Map<String, dynamic>? strategies;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final active = await ApiService().getDebts(status: 'activa');
      final paid = await ApiService().getPaidDebtsHistory();
      final strat = await ApiService().getDebtStrategies();

      if (mounted) {
        setState(() {
          activeDebts = active;
          paidDebts = paid;
          strategies = strat;
        });
      }
    } catch (e) {
      // Ignorar error o mantener cache
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showAddDebtDialog() {
    final titleController = TextEditingController();
    final creditorController = TextEditingController();
    final totalController = TextEditingController();
    final paymentController = TextEditingController();
    final interestController = TextEditingController(text: '0');
    final paymentDetailsController = TextEditingController();
    String paymentMethodType = 'Pago Móvil';
    final today = DateTime.now().toIso8601String().split('T')[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registrar Nueva Deuda / Pasivo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Nombre (ej. Tarjeta Oro, Préstamo Auto)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: creditorController,
                  decoration: const InputDecoration(labelText: 'Acreedor o Banco'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: totalController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Monto Total (\$)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: paymentController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Cuota Mensual (\$)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: interestController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Tasa de Interés Anual (%)'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Método de Pago del Acreedor (Para Copiar y Pegar)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: paymentMethodType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Pago',
                    prefixIcon: Icon(Icons.payment),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Pago Móvil', child: Text('Pago Móvil (Bs)')),
                    DropdownMenuItem(value: 'Zelle', child: Text('Zelle')),
                    DropdownMenuItem(value: 'Binance Pay', child: Text('Binance Pay / USDT')),
                    DropdownMenuItem(value: 'Transferencia', child: Text('Transferencia Bancaria')),
                    DropdownMenuItem(value: 'Zinli / Wally', child: Text('Zinli / Wally')),
                    DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo \$')),
                  ],
                  onChanged: (v) => setModalState(() => paymentMethodType = v ?? 'Pago Móvil'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: paymentDetailsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Datos para copiar y pegar (Banco, Teléfono, Cédula o Correo)',
                    hintText: 'Ej: Banesco (0134) | 0414-1234567 | V-20.123.456',
                    prefixIcon: Icon(Icons.copy_all),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final total = double.tryParse(totalController.text) ?? 0;
                      final payment = double.tryParse(paymentController.text) ?? 0;
                      final interest = double.tryParse(interestController.text) ?? 0;

                      if (titleController.text.isEmpty || total <= 0) return;

                      await ApiService().createDebt({
                        'title': titleController.text,
                        'creditor': creditorController.text.isNotEmpty ? creditorController.text : 'Particular',
                        'total_amount': total,
                        'current_balance': total,
                        'monthly_payment': payment > 0 ? payment : total * 0.1,
                        'interest_rate': interest,
                        'due_day': DateTime.now().day,
                        'next_due_date': today,
                        'payment_method_type': paymentMethodType,
                        'payment_details': paymentDetailsController.text.trim().isEmpty
                            ? null
                            : paymentDetailsController.text.trim(),
                      });

                      if (mounted) Navigator.pop(ctx);
                      _loadData();
                    },
                    child: const Text('Registrar Deuda'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Deudas & Cuotas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Color(0xFFF59E0B)),
            tooltip: 'Cuotas Cashea / Krece',
            onPressed: () => CasheaInstallmentsDialog.show(context, onChanged: _loadData),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: ElevatedButton.icon(
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
                    _loadData();
                  },
                );
              },
              icon: const Icon(Icons.handshake_outlined, size: 16),
              label: const Text('Pedí Prestado', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calculate_outlined, color: Color(0xFF6366F1)),
            tooltip: 'Calculadora',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const StandardCalculatorDialog(),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF10B981),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF10B981),
          tabs: [
            Tab(text: 'Activas (${activeDebts.length})'),
            Tab(text: 'Pagadas (${paidDebts.length})'),
            const Tab(text: 'Estrategias'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDebtDialog,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Deuda'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : TabBarView(
              controller: _tabController,
              children: [
                // 1. Activas
                RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFF10B981),
                  child: activeDebts.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.sentiment_very_satisfied, size: 56, color: Color(0xFF10B981)),
                              SizedBox(height: 12),
                              Text('¡Sin deudas activas pendientes!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              SizedBox(height: 6),
                              Text('Tus finanzas están completamente al día.', style: TextStyle(color: Color(0xFF64748B))),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: activeDebts.length,
                          itemBuilder: (context, index) {
                            final debt = activeDebts[index];
                            return DebtCard(
                              debt: debt,
                              onPay: () {
                                CustomDialogs.showRecordPaymentDialog(
                                  context: context,
                                  debt: debt,
                                  onConfirm: (amount, date, notes) async {
                                    await ApiService().recordDebtPayment(debt.id, amount, date, notes: notes);
                                    _loadData();
                                  },
                                );
                              },
                            );
                          },
                        ),
                ),

                // 2. Historial de Pagadas
                RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFF10B981),
                  child: paidDebts.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_outlined, size: 56, color: Color(0xFF94A3B8)),
                              SizedBox(height: 12),
                              Text('No hay deudas liquidadas aún', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              SizedBox(height: 6),
                              Text('Abona a tus deudas activas para celebrarlas aquí.', style: TextStyle(color: Color(0xFF64748B))),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: paidDebts.length,
                          itemBuilder: (context, index) {
                            final debt = paidDebts[index];
                            return DebtCard(
                              debt: debt,
                              onPay: () {},
                            );
                          },
                        ),
                ),

                // 3. Estrategias de Liquidación (Avalancha vs Bola de Nieve)
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Color(0xFF2563EB), size: 26),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Estas recomendaciones aplican matemáticas financieras para que elimines tus deudas sin desperdiciar dinero en intereses.',
                                style: TextStyle(color: Color(0xFF1E40AF), fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Avalancha
                      const Text(
                        '1. Método Avalancha (Recomendado matemáticamente)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Paga el mínimo en todas y ataca primero la de MAYOR tasa de interés para ahorrar el máximo dinero.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 12),
                      if (strategies != null && strategies!['strategies']?['avalanche']?['priority_order'] != null)
                        ...((strategies!['strategies']['avalanche']['priority_order'] as List).map(
                          (item) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.flash_on, color: Color(0xFFEF4444), size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        Text('${item['creditor']} • Tasa: ${item['interest_rate']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                      ],
                                    ),
                                  ],
                                ),
                                Text(
                                  currency.format(item['current_balance']),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                          ),
                        )),

                      const SizedBox(height: 24),
                      // Bola de Nieve
                      const Text(
                        '2. Método Bola de Nieve (Impulso psicológico)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Paga primero la de MENOR saldo. Liquidarás una deuda rápido y ganarás motivación instantánea.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 12),
                      if (strategies != null && strategies!['strategies']?['snowball']?['priority_order'] != null)
                        ...((strategies!['strategies']['snowball']['priority_order'] as List).map(
                          (item) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.ac_unit, color: Color(0xFF10B981), size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        Text(item['creditor'], style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                      ],
                                    ),
                                  ],
                                ),
                                Text(
                                  currency.format(item['current_balance']),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                          ),
                        )),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
