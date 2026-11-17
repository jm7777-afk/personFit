import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payroll_model.dart';
import '../services/api_service.dart';

class PayrollCalendarDialog extends StatefulWidget {
  final PayrollSummary payroll;
  final bool showInBs;

  const PayrollCalendarDialog({
    super.key,
    required this.payroll,
    required this.showInBs,
  });

  @override
  State<PayrollCalendarDialog> createState() => _PayrollCalendarDialogState();
}

class _PayrollCalendarDialogState extends State<PayrollCalendarDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PayrollCalendarItem> _calendarItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCalendar();
  }

  Future<void> _loadCalendar() async {
    try {
      final items = await ApiService().getPayrollCalendar(count: 8);
      if (mounted) {
        setState(() {
          _calendarItems = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,##0.00', 'es_VE');
    final symbol = widget.showInBs ? 'Bs.' : '\$';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 580),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.calendar_month, color: Color(0xFF4F46E5), size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Organización de Cobros',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // TabBar
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF4F46E5),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF4F46E5),
              indicatorWeight: 3,
              tabs: [
                Tab(text: 'Deducciones (${widget.payroll.deductions.length})'),
                const Tab(text: 'Próximas Fechas'),
              ],
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Deducciones
                  widget.payroll.deductions.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.celebration_outlined, color: Color(0xFF10B981), size: 48),
                                SizedBox(height: 12),
                                Text(
                                  '¡Sin deducciones pendientes!',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'No tienes préstamos ni compromisos descontándose de tu próxima nómina. Cobrarás tu sueldo completo.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: widget.payroll.deductions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final d = widget.payroll.deductions[index];
                            final amount = widget.showInBs ? d.amountBs : d.amountUsd;
                            final isLoan = d.type == 'prestamo_tomado';

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isLoan ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isLoan ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isLoan ? const Color(0xFFEF4444).withOpacity(0.15) : const Color(0xFF64748B).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isLoan ? Icons.handshake : Icons.receipt_long,
                                      color: isLoan ? const Color(0xFFDC2626) : const Color(0xFF475569),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          d.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                        ),
                                        Text(
                                          isLoan ? 'Acreedor: ${d.creditor}' : 'Fecha límite: ${d.dueDate}',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '- $symbol ${currencyFmt.format(amount)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isLoan ? const Color(0xFFDC2626) : const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                  // Tab 2: Próximas Fechas
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _calendarItems.isEmpty
                          ? const Center(child: Text('No hay fechas disponibles'))
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _calendarItems.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final item = _calendarItems[index];
                                final isNext = index == 0;

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isNext ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isNext ? const Color(0xFF818CF8) : const Color(0xFFE2E8F0),
                                      width: isNext ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isNext ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '#${item.payoutNumber}',
                                          style: TextStyle(
                                            color: isNext ? Colors.white : const Color(0xFF475569),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Fecha: ${item.date}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: isNext ? const Color(0xFF4F46E5) : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            Text(
                                              item.frequencyLabel,
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isNext)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'Próximo Cobro',
                                            style: TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
