import 'package:flutter/material.dart';
import '../models/exchange_rate_model.dart';
import 'currency_calculator_dialog.dart';
import 'payment_advisor_dialog.dart';

class ExchangeRateTicker extends StatelessWidget {
  final ExchangeRatesSummaryModel? rates;
  final VoidCallback? onRefresh;

  const ExchangeRateTicker({
    super.key,
    required this.rates,
    this.onRefresh,
  });

  Widget _buildRateBadge(String label, double rate, double change, bool isParalelo) {
    final isIncrease = change > 0;
    final changeColor = isIncrease ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final arrow = isIncrease ? '▲' : (change < 0 ? '▼' : '•');

    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: changeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$arrow ${change.abs().toStringAsFixed(2)}%',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: changeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Bs. ${rate.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (rates == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.currency_exchange, size: 16, color: Color(0xFF10B981)),
                SizedBox(width: 6),
                Text(
                  'Tasas de Cambio Venezuela',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => PaymentAdvisorDialog.show(context, rates: rates),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.balance, size: 13, color: Color(0xFF38BDF8)),
                        SizedBox(width: 4),
                        Text(
                          '¿Bs o \$ hoy?',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => CurrencyCalculatorDialog.show(context, rates: rates),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.calculate, size: 14, color: Color(0xFF10B981)),
                        SizedBox(width: 4),
                        Text(
                          'Calc',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildRateBadge('Dólar BCV', rates!.usdBcv, rates!.usdBcvChange, false),
              _buildRateBadge('Euro BCV', rates!.eurBcv, rates!.eurBcvChange, false),
              _buildRateBadge('USDT Binance', rates!.usdtBinance, rates!.usdtBinanceChange, true),
              _buildRateBadge('Dólar Paralelo', rates!.usdParalelo, rates!.usdParaleloChange, true),
              _buildRateBadge('Euro Paralelo', rates!.eurParalelo, rates!.eurParaleloChange, true),
            ],
          ),
        ),
      ],
    );
  }
}
