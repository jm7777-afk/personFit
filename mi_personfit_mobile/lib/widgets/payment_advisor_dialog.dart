import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/exchange_rate_model.dart';
import '../services/api_service.dart';

class PaymentAdvisorDialog extends StatefulWidget {
  final ExchangeRatesSummaryModel? rates;

  const PaymentAdvisorDialog({super.key, this.rates});

  static Future<void> show(BuildContext context, {ExchangeRatesSummaryModel? rates}) {
    return showDialog(
      context: context,
      builder: (_) => PaymentAdvisorDialog(rates: rates),
    );
  }

  @override
  State<PaymentAdvisorDialog> createState() => _PaymentAdvisorDialogState();
}

class _PaymentAdvisorDialogState extends State<PaymentAdvisorDialog> {
  final _amountController = TextEditingController(text: '50');
  bool _applyIgtf = true;
  bool _pricedInEuroBcv = false;
  bool _useUsdtRate = true;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = ApiService();
    final bcvUsd = (widget.rates?.usdBcv ?? 0) > 0 ? widget.rates!.usdBcv : api.activeBcvRate;
    final bcvEur = (widget.rates?.eurBcv ?? 0) > 0 ? widget.rates!.eurBcv : api.activeEurBcvRate;
    final paralelo = (widget.rates?.usdParalelo ?? 0) > 0 ? widget.rates!.usdParalelo : api.activeParaleloRate;
    final usdt = (widget.rates?.usdtBinance ?? 0) > 0 ? widget.rates!.usdtBinance : api.activeUsdtRate;

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    final storeRate = _pricedInEuroBcv ? bcvEur : bcvUsd;
    final sellRate = _useUsdtRate ? usdt : paralelo;

    // Opción 1: Pagar en Bolívares (Pago Móvil / Punto) vendiendo divisas/USDT
    final totalBsToPay = amount * storeRate;
    final realCostUsdIfPayingBs = sellRate > 0 ? totalBsToPay / sellRate : amount;

    // Opción 2: Pagar en Efectivo USD (+ 3% IGTF si aplica)
    final igtfAmount = _applyIgtf ? amount * 0.03 : 0.0;
    final totalUsdCash = amount + igtfAmount;

    // Comparación
    final bsIsBetter = realCostUsdIfPayingBs < totalUsdCash;
    final savingsUsd = (totalUsdCash - realCostUsdIfPayingBs).abs();
    final savingsBs = savingsUsd * sellRate;
    final gapPct = bcvUsd > 0 ? ((sellRate - bcvUsd) / bcvUsd) * 100 : 0.0;

    final fmt = NumberFormat('#,##0.00', 'es_VE');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.balance, color: Color(0xFF38BDF8), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Cómo me conviene pagar hoy?',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'Brecha Cambiaria + IGTF 3% Venezuela',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Monto del comercio
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: _pricedInEuroBcv ? 'Precio marcado en € (Euro BCV)' : 'Precio marcado en \$ (Dólar BCV)',
                prefixIcon: Icon(_pricedInEuroBcv ? Icons.euro : Icons.attach_money, color: const Color(0xFF10B981)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),

            // Chips rápidos de configuración
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                FilterChip(
                  label: const Text('Comercio cobra a € BCV'),
                  selected: _pricedInEuroBcv,
                  selectedColor: const Color(0xFF2563EB).withOpacity(0.18),
                  onSelected: (v) => setState(() => _pricedInEuroBcv = v),
                ),
                FilterChip(
                  label: const Text('IGTF 3% en efectivo \$'),
                  selected: _applyIgtf,
                  selectedColor: const Color(0xFFEF4444).withOpacity(0.15),
                  onSelected: (v) => setState(() => _applyIgtf = v),
                ),
                FilterChip(
                  label: Text(_useUsdtRate ? 'Cambio a USDT (${sellRate.toStringAsFixed(1)})' : 'Cambio a Paralelo (${sellRate.toStringAsFixed(1)})'),
                  selected: _useUsdtRate,
                  selectedColor: const Color(0xFFF59E0B).withOpacity(0.18),
                  onSelected: (v) => setState(() => _useUsdtRate = v),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tarjeta de Veredicto
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: bsIsBetter
                      ? [const Color(0xFF065F46), const Color(0xFF059669)]
                      : [const Color(0xFF1E3A8A), const Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, color: Color(0xFFFDE047), size: 20),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          bsIsBetter
                              ? '¡TE CONVIENE PAGAR EN BOLÍVARES!'
                              : '¡TE CONVIENE PAGAR EN DIVISAS (\$)!',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ahorras \$${savingsUsd.toStringAsFixed(2)} (Bs. ${fmt.format(savingsBs)})',
                    style: const TextStyle(color: Color(0xFFFDE047), fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Brecha cambiaria actual: +${gapPct.toStringAsFixed(1)}% vs BCV',
                    style: const TextStyle(color: Color(0xFFD1FAE5), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Desglose comparativo lado a lado
            Row(
              children: [
                Expanded(
                  child: _buildOptionCard(
                    title: 'Pago Móvil / Punto',
                    subtitle: 'Bs. ${fmt.format(totalBsToPay)}',
                    realCost: '\$${realCostUsdIfPayingBs.toStringAsFixed(2)} reales',
                    detail: 'Cambiando a ${sellRate.toStringAsFixed(2)} Bs',
                    isWinner: bsIsBetter,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildOptionCard(
                    title: 'Efectivo USD',
                    subtitle: _applyIgtf ? '+\$${igtfAmount.toStringAsFixed(2)} IGTF (3%)' : 'Sin IGTF',
                    realCost: '\$${totalUsdCash.toStringAsFixed(2)} exactos',
                    detail: 'Pagando directo en \$',
                    isWinner: !bsIsBetter,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Tasas usadas: BCV \$ ${bcvUsd.toStringAsFixed(2)} • Euro BCV ${bcvEur.toStringAsFixed(2)} • USDT ${usdt.toStringAsFixed(2)} Bs.',
                style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required String realCost,
    required String detail,
    required bool isWinner,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWinner ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWinner ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
          width: isWinner ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                ),
              ),
              if (isWinner) const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Text(
            realCost,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isWinner ? const Color(0xFF059669) : const Color(0xFF0F172A),
            ),
          ),
          Text(detail, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}
