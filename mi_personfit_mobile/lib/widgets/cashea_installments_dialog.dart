import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/installment_model.dart';
import '../services/api_service.dart';

class CasheaInstallmentsDialog extends StatefulWidget {
  final VoidCallback? onChanged;

  const CasheaInstallmentsDialog({super.key, this.onChanged});

  static Future<void> show(BuildContext context, {VoidCallback? onChanged}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.88,
        child: CasheaInstallmentsDialog(onChanged: onChanged),
      ),
    );
  }

  @override
  State<CasheaInstallmentsDialog> createState() => _CasheaInstallmentsDialogState();
}

class _CasheaInstallmentsDialogState extends State<CasheaInstallmentsDialog> {
  final ApiService _api = ApiService();
  InstallmentsSummaryModel? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getInstallmentPlans();
      if (mounted) {
        setState(() {
          _summary = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showCreatePlanDialog() {
    final merchantCtrl = TextEditingController();
    final totalCtrl = TextEditingController();
    String provider = 'Cashea';
    double initialPercent = 40;
    int installmentsCount = 3;
    int intervalDays = 14;
    bool deductSalary = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final total = double.tryParse(totalCtrl.text.replaceAll(',', '.')) ?? 0.0;
          final initial = total * (initialPercent / 100);
          final remaining = (total - initial).clamp(0, double.infinity);
          final cuota = installmentsCount > 0 ? remaining / installmentsCount : 0;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Nueva Compra en Cuotas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: provider,
                    decoration: InputDecoration(
                      labelText: 'Plataforma / Crédito',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Cashea', child: Text('Cashea (Cuotas cada 14 días)')),
                      DropdownMenuItem(value: 'Krece', child: Text('Krece')),
                      DropdownMenuItem(value: 'Chollo', child: Text('Chollo')),
                      DropdownMenuItem(value: 'Crédito Directo', child: Text('Crédito Comercial / Tienda')),
                    ],
                    onChanged: (v) => setState(() => provider = v ?? 'Cashea'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: merchantCtrl,
                    decoration: InputDecoration(
                      labelText: 'Comercio / Supermercado',
                      hintText: 'Ej: Bio Mercado Mañongo, Traki, EPA',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: totalCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Monto Total de Compra (\$ USD)',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Inicial pagada: ${initialPercent.toInt()}% (\$${initial.toStringAsFixed(2)})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 6,
                    children: [20.0, 40.0, 50.0, 60.0].map((pct) {
                      return ChoiceChip(
                        label: Text('${pct.toInt()}%'),
                        selected: initialPercent == pct,
                        onSelected: (_) => setState(() => initialPercent = pct),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: installmentsCount,
                          decoration: InputDecoration(
                            labelText: 'Cuotas',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 3, child: Text('3 cuotas')),
                            DropdownMenuItem(value: 6, child: Text('6 cuotas')),
                            DropdownMenuItem(value: 9, child: Text('9 cuotas')),
                          ],
                          onChanged: (v) => setState(() => installmentsCount = v ?? 3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: intervalDays,
                          decoration: InputDecoration(
                            labelText: 'Frecuencia',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 14, child: Text('Cada 14 días')),
                            DropdownMenuItem(value: 15, child: Text('Quincenal')),
                            DropdownMenuItem(value: 30, child: Text('Mensual')),
                          ],
                          onChanged: (v) => setState(() => intervalDays = v ?? 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (total > 0)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Text(
                        'Te quedarán $installmentsCount cuotas de \$${cuota.toStringAsFixed(2)} cada $intervalDays días.',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                      ),
                    ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Descontar de mi Sueldo Neto', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Se resta automáticamente antes de cobrar tu quincena', style: TextStyle(fontSize: 11)),
                    value: deductSalary,
                    onChanged: (v) => setState(() => deductSalary = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  final amt = double.tryParse(totalCtrl.text.replaceAll(',', '.')) ?? 0;
                  if (amt <= 0 || merchantCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  try {
                    await _api.createInstallmentPlan({
                      'provider': provider,
                      'merchant_name': merchantCtrl.text.trim(),
                      'title': '$provider en ${merchantCtrl.text.trim()}',
                      'total_amount': amt,
                      'initial_percent': initialPercent,
                      'installments_count': installmentsCount,
                      'interval_days': intervalDays,
                      'deduct_from_salary': deductSalary,
                    });
                    await _load();
                    widget.onChanged?.call();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white),
                child: const Text('Registrar Cuotas'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00', 'es_VE');

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Control de Cuotas (Cashea / Krece)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      'Calendario cada 14 días integrado a tu nómina',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showCreatePlanDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nueva'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_summary != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('PRÓXIMOS 15 DÍAS', style: TextStyle(color: Color(0xFFFBBF24), fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        '\$${fmt.format(_summary!.upcoming14DaysUsd)}',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 34, color: Colors.white24),
                  Column(
                    children: [
                      const Text('TOTAL PENDIENTE', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        '\$${fmt.format(_summary!.totalPendingUsd)}',
                        style: const TextStyle(color: Color(0xFF34D399), fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_summary == null || _summary!.plans.isEmpty)
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_month_outlined, size: 52, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 10),
                            const Text('No tienes cuotas activas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 6),
                            const Text(
                              'Registra tus compras de Cashea o Krece para saber exactamente cuánto se descuenta de tu próxima quincena.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _summary!.plans.length,
                        itemBuilder: (context, idx) {
                          final plan = _summary!.plans[idx];
                          final isDone = plan.status == 'pagada';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: isDone ? const Color(0xFF10B981) : const Color(0xFFE2E8F0)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFEF3C7),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    plan.provider,
                                                    style: const TextStyle(color: Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    plan.merchantName,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Total \$${plan.totalAmount.toStringAsFixed(2)} • Inicial \$${plan.initialPaid.toStringAsFixed(2)} • Resta \$${plan.remainingAmount.toStringAsFixed(2)}',
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                        onPressed: () async {
                                          await _api.deleteInstallmentPlan(plan.id);
                                          await _load();
                                          widget.onChanged?.call();
                                        },
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  ...plan.payments.map((pay) {
                                    return InkWell(
                                      onTap: () async {
                                        await _api.toggleInstallmentPayment(pay.id);
                                        await _load();
                                        widget.onChanged?.call();
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          children: [
                                            Icon(
                                              pay.isPaid ? Icons.check_circle : Icons.radio_button_unchecked,
                                              color: pay.isPaid ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Cuota #${pay.installmentNumber} • Vence: ${pay.dueDate}',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  decoration: pay.isPaid ? TextDecoration.lineThrough : null,
                                                  color: pay.isPaid ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '\$${pay.amount.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: pay.isPaid ? const Color(0xFF10B981) : const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
