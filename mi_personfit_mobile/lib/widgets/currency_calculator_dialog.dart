import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/exchange_rate_model.dart';
import '../services/api_service.dart';

class CurrencyCalculatorDialog extends StatefulWidget {
  final ExchangeRatesSummaryModel? initialRates;

  const CurrencyCalculatorDialog({super.key, this.initialRates});

  static void show(BuildContext context, {ExchangeRatesSummaryModel? rates}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => CurrencyCalculatorDialog(initialRates: rates),
    );
  }

  @override
  State<CurrencyCalculatorDialog> createState() => _CurrencyCalculatorDialogState();
}

class _CurrencyCalculatorDialogState extends State<CurrencyCalculatorDialog> {
  final TextEditingController _amountController = TextEditingController(text: '10');
  String _selectedFrom = 'USD'; // 'USD', 'VES', 'EUR'
  String _selectedRateType = 'oficial'; // 'oficial' (BCV), 'paralelo'
  ExchangeRatesSummaryModel? _rates;

  @override
  void initState() {
    super.initState();
    _rates = widget.initialRates;
    if (_rates == null) {
      _loadRates();
    }
  }

  Future<void> _loadRates() async {
    try {
      final r = await ApiService().getExchangeRates();
      if (mounted) setState(() => _rates = r);
    } catch (_) {
      // Ignorar fallback
    }
  }

  void _applyQuickMultiplier(double factor) {
    final current = double.tryParse(_amountController.text) ?? 0;
    if (current > 0) {
      setState(() {
        _amountController.text = (current * factor).toStringAsFixed(2);
      });
    }
  }

  void _applyQuickDivide(int divisor) {
    final current = double.tryParse(_amountController.text) ?? 0;
    if (current > 0 && divisor > 0) {
      setState(() {
        _amountController.text = (current / divisor).toStringAsFixed(2);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '', decimalDigits: 2);
    final amount = double.tryParse(_amountController.text) ?? 0;

    final usdBcv = _rates?.usdBcv ?? 914.02;
    final usdParalelo = _rates?.usdParalelo ?? 1045.50;
    final eurBcv = _rates?.eurBcv ?? 1010.56;

    // Cálculos instantáneos
    double inBsBcv = 0;
    double inBsParalelo = 0;
    double inUsdBcv = 0;
    double inUsdParalelo = 0;
    double inEur = 0;

    if (_selectedFrom == 'USD') {
      inBsBcv = amount * usdBcv;
      inBsParalelo = amount * usdParalelo;
      inEur = eurBcv > 0 ? (inBsBcv / eurBcv) : 0;
    } else if (_selectedFrom == 'VES') {
      inUsdBcv = usdBcv > 0 ? (amount / usdBcv) : 0;
      inUsdParalelo = usdParalelo > 0 ? (amount / usdParalelo) : 0;
      inEur = eurBcv > 0 ? (amount / eurBcv) : 0;
    } else if (_selectedFrom == 'EUR') {
      inBsBcv = amount * eurBcv;
      inBsParalelo = amount * (eurBcv * (usdParalelo / usdBcv));
      inUsdBcv = usdBcv > 0 ? (inBsBcv / usdBcv) : 0;
    }

    final double primaryResult = _selectedFrom == 'VES'
        ? (_selectedRateType == 'oficial' ? inUsdBcv : inUsdParalelo)
        : (_selectedRateType == 'oficial' ? inBsBcv : inBsParalelo);

    final String primarySymbol = _selectedFrom == 'VES' ? '\$' : 'Bs.';

    return Padding(
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
          // Encabezado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.calculate_outlined, color: Color(0xFF10B981), size: 26),
                  SizedBox(width: 8),
                  Text(
                    'Calculadora Venezuela',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Text(
            'Tasas en tiempo real: Bolívares, Dólares y Euros',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 18),

          // Selector de moneda de origen (USD / VES / EUR)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildCurrencyTab('USD (\$)', 'USD'),
                _buildCurrencyTab('Bolívares (Bs)', 'VES'),
                _buildCurrencyTab('Euro (€)', 'EUR'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Campo de monto
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Monto a Calcular en $_selectedFrom',
              prefixIcon: Icon(
                _selectedFrom == 'USD'
                    ? Icons.attach_money
                    : _selectedFrom == 'EUR'
                        ? Icons.euro
                        : Icons.account_balance,
                color: const Color(0xFF10B981),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Selector de Tasa: BCV Oficial vs Paralelo
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: Text('Oficial BCV (${usdBcv.toStringAsFixed(2)} Bs)'),
                  selected: _selectedRateType == 'oficial',
                  onSelected: (val) => setState(() => _selectedRateType = 'oficial'),
                  selectedColor: const Color(0xFF10B981).withOpacity(0.15),
                  labelStyle: TextStyle(
                    fontWeight: _selectedRateType == 'oficial' ? FontWeight.bold : FontWeight.normal,
                    color: _selectedRateType == 'oficial' ? const Color(0xFF10B981) : const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: Text('Paralelo (${usdParalelo.toStringAsFixed(2)} Bs)'),
                  selected: _selectedRateType == 'paralelo',
                  onSelected: (val) => setState(() => _selectedRateType = 'paralelo'),
                  selectedColor: const Color(0xFFEF4444).withOpacity(0.15),
                  labelStyle: TextStyle(
                    fontWeight: _selectedRateType == 'paralelo' ? FontWeight.bold : FontWeight.normal,
                    color: _selectedRateType == 'paralelo' ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Resultado Principal
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CONVERSIÓN A TASA ${_selectedRateType.toUpperCase()}',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    if (_rates != null && _rates!.gapPercentage > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Brecha: +${_rates!.gapPercentage}%',
                          style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$primarySymbol ${currency.format(primaryResult)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(color: Color(0xFF334155)),
                const SizedBox(height: 4),

                // Comparativa Simultánea
                if (_selectedFrom != 'VES')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'A tasa Paralelo: Bs. ${currency.format(inBsParalelo)}',
                        style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                      ),
                      Text(
                        'En Euros: € ${currency.format(inEur)}',
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'A tasa Paralelo: \$ ${currency.format(inUsdParalelo)}',
                        style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                      ),
                      Text(
                        'En Euros: € ${currency.format(inEur)}',
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Botones de acceso rápido para compras venezolanas
          const Text('Atajos Financieros', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickButton('+ 16% IVA', () => _applyQuickMultiplier(1.16)),
                _buildQuickButton('- 16% Base', () => _applyQuickMultiplier(1 / 1.16)),
                _buildQuickButton('÷ 2 Personas', () => _applyQuickDivide(2)),
                _buildQuickButton('÷ 3 Personas', () => _applyQuickDivide(3)),
                _buildQuickButton('÷ 4 Personas', () => _applyQuickDivide(4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyTab(String label, String value) {
    final isSelected = _selectedFrom == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFrom = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickButton(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
        backgroundColor: const Color(0xFFF1F5F9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onPressed: onTap,
      ),
    );
  }
}
