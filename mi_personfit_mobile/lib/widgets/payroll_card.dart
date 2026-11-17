import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payroll_model.dart';

class PayrollCard extends StatelessWidget {
  final PayrollSummary payroll;
  final bool showInBs;
  final VoidCallback onRefresh;
  final VoidCallback onOpenCalendar;
  final VoidCallback onAddLoan;

  const PayrollCard({
    super.key,
    required this.payroll,
    required this.showInBs,
    required this.onRefresh,
    required this.onOpenCalendar,
    required this.onAddLoan,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,##0.00', 'es_VE');

    final expectedSalary = showInBs ? payroll.expectedSalaryBs : payroll.expectedSalaryUsd;
    final deductions = showInBs ? payroll.totalDeductionsBs : payroll.totalDeductionsUsd;
    final netSalary = showInBs ? payroll.netRemainingBs : payroll.netRemainingUsd;
    final symbol = showInBs ? 'Bs.' : '\$';

    if (!payroll.hasIncomeConfigured) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        color: const Color(0xFFF1F5F9),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.calendar_month, color: Color(0xFF6366F1)),
                  SizedBox(width: 8),
                  Text(
                    'Control de Nómina y Próximo Cobro',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Registra tu salario seleccionando Quincenal, Semanal o Diario para activar el contador de días para cobrar y el cálculo de sueldo libre restante.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    final isUrgentCountdown = payroll.daysRemaining <= 3;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E1B4B),
            const Color(0xFF312E81),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4338CA).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila superior con insignia de periodicidad y botón calendario
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF818CF8).withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.alarm, color: Color(0xFFA5B4FC), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      payroll.frequencyLabel.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFA5B4FC),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: onOpenCalendar,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.calendar_month, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Calendario',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Contador Grande de Días
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${payroll.daysRemaining}',
                style: TextStyle(
                  color: isUrgentCountdown ? const Color(0xFF34D399) : Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payroll.daysRemaining == 1 ? 'DÍA RESTANTE' : 'DÍAS RESTANTES',
                    style: const TextStyle(
                      color: Color(0xFFC7D2FE),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'Próximo cobro: ${payroll.nextPayoutDate}',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Card Interna de Sueldo Proyectado Sin Cobrar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sueldo Bruto Previsto:',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                    Text(
                      '$symbol ${currencyFmt.format(expectedSalary)}',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Deducciones / Préstamos:',
                          style: TextStyle(color: Color(0xFFF87171), fontSize: 13),
                        ),
                        if (payroll.deductions.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              '(${payroll.deductions.length})',
                              style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      '- $symbol ${currencyFmt.format(deductions)}',
                      style: const TextStyle(color: Color(0xFFF87171), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(color: Colors.white12, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SUELDO RESTANTE SIN COBRAR',
                          style: TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '${payroll.percentFree}% de tu nómina queda libre',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                      ),
                      child: Text(
                        '$symbol ${currencyFmt.format(netSalary)}',
                        style: const TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Botones de acción rápida: Pedir Prestado y Ver Deducciones
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAddLoan,
                  icon: const Icon(Icons.handshake_outlined, size: 16),
                  label: const Text('Pedí Prestado (+)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenCalendar,
                  icon: const Icon(Icons.list_alt, size: 16),
                  label: const Text('Ver Deducciones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
