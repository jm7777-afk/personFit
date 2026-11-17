import 'package:flutter/material.dart';
import '../models/debt_model.dart';
import '../models/expense_model.dart';
import '../models/savings_model.dart';

class CustomDialogs {
  static void showRecordPaymentDialog({
    required BuildContext context,
    required DebtModel debt,
    required Future<void> Function(double amount, String date, String? notes) onConfirm,
  }) {
    final amountController = TextEditingController(text: debt.monthlyPayment.toStringAsFixed(0));
    final notesController = TextEditingController();
    final today = DateTime.now().toIso8601String().split('T')[0];
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Abonar a "${debt.title}"',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Saldo pendiente actual: \$${debt.currentBalance.toStringAsFixed(0)}',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto del Abono (\$)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Nota (opcional)',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final amount = double.tryParse(amountController.text) ?? 0;
                          if (amount <= 0) return;
                          setState(() => isLoading = true);
                          try {
                            await onConfirm(amount, today, notesController.text);
                            if (context.mounted) Navigator.pop(context);
                          } finally {
                            if (context.mounted) setState(() => isLoading = false);
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Registrar Abono'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showAddExpenseDialog({
    required BuildContext context,
    required List<CategoryModel> categories,
    required Future<void> Function(Map<String, dynamic> data) onConfirm,
  }) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final today = DateTime.now().toIso8601String().split('T')[0];
    int selectedCategoryId = categories.isNotEmpty ? categories.first.id : 1;
    bool isPaid = true;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nuevo Gasto o Servicio',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Concepto (ej. Supermercado, Luz, Alquiler)',
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto (\$)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: categories.map((cat) {
                  return DropdownMenuItem<int>(
                    value: cat.id,
                    child: Text('${cat.name} (${cat.type})'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedCategoryId = val);
                },
              ),
              const SizedBox(height: 14),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('¿Ya está pagado?'),
                subtitle: Text(
                  isPaid ? 'Gasto liquidado hoy' : 'Servicio / Factura pendiente por pagar',
                  style: const TextStyle(fontSize: 12),
                ),
                value: isPaid,
                activeColor: const Color(0xFF10B981),
                onChanged: (val) => setState(() => isPaid = val),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          final amount = double.tryParse(amountController.text) ?? 0;
                          if (title.isEmpty || amount <= 0) return;
                          setState(() => isLoading = true);
                          try {
                            await onConfirm({
                              'title': title,
                              'amount': amount,
                              'category_id': selectedCategoryId,
                              'date': today,
                              'due_date': isPaid ? null : today,
                              'is_paid': isPaid ? 1 : 0,
                              'payment_method': 'efectivo',
                            });
                            if (context.mounted) Navigator.pop(context);
                          } finally {
                            if (context.mounted) setState(() => isLoading = false);
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Guardar Gasto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showAddIncomeDialog({
    required BuildContext context,
    required Future<void> Function(Map<String, dynamic> data) onConfirm,
  }) {
    final titleController = TextEditingController(text: 'Sueldo Empleo');
    final amountController = TextEditingController();
    final today = DateTime.now().toIso8601String().split('T')[0];
    String source = 'empleo_principal';
    String frequency = 'quincenal'; // quincenal, semanal, diario, mensual
    String currency = 'USD'; // USD o VES
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registrar Salario / Ingreso Recurrente',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción del empleo / ingreso',
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                ),
                const SizedBox(height: 14),

                // Selector de Moneda y Monto
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Monto a Cobrar ($currency)',
                          prefixIcon: Icon(currency == 'USD' ? Icons.attach_money : Icons.currency_exchange),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: currency,
                        decoration: const InputDecoration(labelText: 'Moneda'),
                        items: const [
                          DropdownMenuItem(value: 'USD', child: Text('\$ USD')),
                          DropdownMenuItem(value: 'VES', child: Text('Bs. VES')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => currency = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // SELECTOR DE PERIODICIDAD: Quincenal, Semanal, Diario, Mensual
                DropdownButtonFormField<String>(
                  value: frequency,
                  decoration: const InputDecoration(
                    labelText: 'Periodicidad de Cobro',
                    prefixIcon: Icon(Icons.alarm_on),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'quincenal', child: Text('Quincenal (Día 15 y Fin de Mes)')),
                    DropdownMenuItem(value: 'semanal', child: Text('Semanal (Cada semana)')),
                    DropdownMenuItem(value: 'diario', child: Text('Diario (Ingresos diarios)')),
                    DropdownMenuItem(value: 'mensual', child: Text('Mensual (Fin de mes)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => frequency = val);
                  },
                ),
                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  value: source,
                  decoration: const InputDecoration(
                    labelText: 'Fuente de Ingreso',
                    prefixIcon: Icon(Icons.source_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'empleo_principal', child: Text('Empleo Principal')),
                    DropdownMenuItem(value: 'freelance', child: Text('Freelance / Extra')),
                    DropdownMenuItem(value: 'negocio', child: Text('Negocio Propio')),
                    DropdownMenuItem(value: 'inversion', child: Text('Inversiones / Rendimiento')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => source = val);
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            final amount = double.tryParse(amountController.text) ?? 0;
                            if (amount <= 0) return;
                            setState(() => isLoading = true);
                            try {
                              await onConfirm({
                                'title': titleController.text,
                                'amount': amount,
                                'source': source,
                                'frequency': frequency,
                                'currency': currency,
                                'date': today,
                              });
                              if (context.mounted) Navigator.pop(context);
                            } finally {
                              if (context.mounted) setState(() => isLoading = false);
                            }
                          },
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Guardar Ingreso'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // DIÁLOGO PARA REGISTRAR PRÉSTAMO TOMADO ("PEDÍ PRESTADO / SUMAR A DEUDA")
  static void showBorrowMoneyDialog({
    required BuildContext context,
    required Future<void> Function({
      required String creditor,
      required double amount,
      required String currency,
      required String dueDate,
      required bool deductFromSalary,
      String? notes,
    }) onConfirm,
  }) {
    final creditorController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String currency = 'USD'; // USD o VES
    bool deductFromSalary = true;
    bool isLoading = false;
    final in15Days = DateTime.now().add(const Duration(days: 15)).toIso8601String().split('T')[0];
    final dueDateController = TextEditingController(text: in15Days);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.handshake, color: Color(0xFFEF4444)),
                        SizedBox(width: 8),
                        Text(
                          'Pedí Prestado (+ Deuda)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Registra el dinero que tomaste prestado. Se sumará a tus deudas y se descontará automáticamente de tu próximo sueldo.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 18),

                TextField(
                  controller: creditorController,
                  decoration: const InputDecoration(
                    labelText: '¿Quién te prestó dinero?',
                    hintText: 'Ej. Juan, Banco, Familiar, Tarjeta',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14),

                // Monto y Moneda
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Monto Prestado ($currency)',
                          prefixIcon: Icon(currency == 'USD' ? Icons.attach_money : Icons.currency_exchange),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: currency,
                        decoration: const InputDecoration(labelText: 'Moneda'),
                        items: const [
                          DropdownMenuItem(value: 'USD', child: Text('\$ USD')),
                          DropdownMenuItem(value: 'VES', child: Text('Bs. VES')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => currency = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: dueDateController,
                  decoration: const InputDecoration(
                    labelText: 'Fecha estimada de devolución (YYYY-MM-DD)',
                    prefixIcon: Icon(Icons.event_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('¿Descontar de mi próxima nómina?'),
                  subtitle: const Text(
                    'Resta este préstamo del sueldo que te va quedando sin cobrar',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: deductFromSalary,
                  activeColor: const Color(0xFFEF4444),
                  onChanged: (val) => setState(() => deductFromSalary = val),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Motivo / Nota (opcional)',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () async {
                            final creditor = creditorController.text.trim();
                            final amount = double.tryParse(amountController.text) ?? 0;
                            if (creditor.isEmpty || amount <= 0) return;

                            setState(() => isLoading = true);
                            try {
                              await onConfirm(
                                creditor: creditor,
                                amount: amount,
                                currency: currency,
                                dueDate: dueDateController.text.trim(),
                                deductFromSalary: deductFromSalary,
                                notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                              );
                              if (context.mounted) Navigator.pop(context);
                            } finally {
                              if (context.mounted) setState(() => isLoading = false);
                            }
                          },
                    icon: const Icon(Icons.add_alert),
                    label: const Text('Registrar Préstamo y Sumar a Deuda', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void showAddSavingsGoalDialog({
    required BuildContext context,
    required Future<void> Function(Map<String, dynamic> data) onConfirm,
  }) {
    final titleController = TextEditingController(text: 'Fondo de Emergencia');
    final targetController = TextEditingController();
    final initialController = TextEditingController(text: '0');
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Crear Meta de Ahorro',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Meta (ej. Fondo 3 meses)',
                  prefixIcon: Icon(Icons.savings_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: targetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Meta Objetivo (\$)',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: initialController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto Inicial con el que comienzas (\$)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final target = double.tryParse(targetController.text) ?? 0;
                          final initial = double.tryParse(initialController.text) ?? 0;
                          if (target <= 0) return;
                          setState(() => isLoading = true);
                          try {
                            await onConfirm({
                              'title': titleController.text,
                              'target_amount': target,
                              'current_amount': initial,
                              'priority': 'alta',
                            });
                            if (context.mounted) Navigator.pop(context);
                          } finally {
                            if (context.mounted) setState(() => isLoading = false);
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Crear Meta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showDepositSavingsDialog({
    required BuildContext context,
    required SavingsGoalModel goal,
    required Future<void> Function(double amount, String date, String? notes) onConfirm,
  }) {
    final amountController = TextEditingController();
    final today = DateTime.now().toIso8601String().split('T')[0];
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aportar a "${goal.title}"',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Acumulado: \$${goal.currentAmount.toStringAsFixed(0)} / \$${goal.targetAmount.toStringAsFixed(0)}',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto a Guardar (\$)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final amount = double.tryParse(amountController.text) ?? 0;
                          if (amount <= 0) return;
                          setState(() => isLoading = true);
                          try {
                            await onConfirm(amount, today, 'Aporte a meta');
                            if (context.mounted) Navigator.pop(context);
                          } finally {
                            if (context.mounted) setState(() => isLoading = false);
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Depositar en Ahorro'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
