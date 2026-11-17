import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class StandardCalculatorDialog extends StatefulWidget {
  final double? initialValue;
  final Function(double value, String currency)? onApplyResult;

  const StandardCalculatorDialog({super.key, this.initialValue, this.onApplyResult});

  @override
  State<StandardCalculatorDialog> createState() => _StandardCalculatorDialogState();
}

class _StandardCalculatorDialogState extends State<StandardCalculatorDialog> {
  String _expression = '';
  String _currentInput = '0';
  double? _firstOperand;
  String? _operator;
  bool _shouldResetInput = false;

  // Modos de moneda: true = calculando en $, false = calculando en Bs.
  bool _isUsdMode = true;

  // Tasas de cambio disponibles
  String _selectedRateName = 'Dólar BCV';
  double _activeRate = 914.02;

  final Map<String, double> _rates = {
    'Dólar BCV': 914.02,
    'Dólar Paralelo': 1045.50,
    'Euro BCV': 1010.56,
  };

  @override
  void initState() {
    super.initState();
    _activeRate = ApiService().activeBcvRate;
    _rates['Dólar BCV'] = _activeRate;
    if (widget.initialValue != null && widget.initialValue! > 0) {
      _currentInput = widget.initialValue!.toStringAsFixed(2);
    }
    _loadLiveRates();
  }

  Future<void> _loadLiveRates() async {
    try {
      final summary = await ApiService().getExchangeRates();
      if (mounted) {
        setState(() {
          _rates['Dólar BCV'] = summary.usdBcv;
          _rates['Dólar Paralelo'] = summary.usdParalelo;
          _rates['Euro BCV'] = summary.eurBcv;
          _activeRate = _rates[_selectedRateName] ?? summary.usdBcv;
        });
      }
    } catch (_) {}
  }

  void _onDigitPress(String digit) {
    setState(() {
      if (_shouldResetInput || _currentInput == '0') {
        _currentInput = digit;
        _shouldResetInput = false;
      } else {
        if (digit == '.' && _currentInput.contains('.')) return;
        _currentInput += digit;
      }
    });
  }

  void _onOperatorPress(String op) {
    setState(() {
      final val = double.tryParse(_currentInput) ?? 0.0;
      if (_firstOperand == null) {
        _firstOperand = val;
        _expression = '$_currentInput $op';
      } else if (_operator != null && !_shouldResetInput) {
        _calculateIntermediate();
        _expression = '$_currentInput $op';
      } else {
        _expression = '$_currentInput $op';
      }
      _operator = op;
      _shouldResetInput = true;
    });
  }

  void _calculateIntermediate() {
    if (_firstOperand == null || _operator == null) return;
    final second = double.tryParse(_currentInput) ?? 0.0;
    double res = 0.0;

    switch (_operator) {
      case '+':
        res = _firstOperand! + second;
        break;
      case '-':
        res = _firstOperand! - second;
        break;
      case '×':
        res = _firstOperand! * second;
        break;
      case '÷':
        res = second != 0 ? _firstOperand! / second : 0;
        break;
    }

    _firstOperand = res;
    _currentInput = _formatResult(res);
  }

  void _onEqualPress() {
    if (_firstOperand == null || _operator == null) return;
    setState(() {
      final second = double.tryParse(_currentInput) ?? 0.0;
      double res = 0.0;
      switch (_operator) {
        case '+':
          res = _firstOperand! + second;
          break;
        case '-':
          res = _firstOperand! - second;
          break;
        case '×':
          res = _firstOperand! * second;
          break;
        case '÷':
          res = second != 0 ? _firstOperand! / second : 0;
          break;
      }
      _expression = '$_expression $_currentInput =';
      _currentInput = _formatResult(res);
      _firstOperand = null;
      _operator = null;
      _shouldResetInput = true;
    });
  }

  void _onClear() {
    setState(() {
      _expression = '';
      _currentInput = '0';
      _firstOperand = null;
      _operator = null;
      _shouldResetInput = false;
    });
  }

  void _onBackspace() {
    setState(() {
      if (_currentInput.length > 1) {
        _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      } else {
        _currentInput = '0';
      }
    });
  }

  void _onToggleSign() {
    setState(() {
      final val = double.tryParse(_currentInput) ?? 0.0;
      _currentInput = _formatResult(-val);
    });
  }

  void _onPercent() {
    setState(() {
      final val = double.tryParse(_currentInput) ?? 0.0;
      _currentInput = _formatResult(val / 100);
    });
  }

  void _onAddIva() {
    setState(() {
      final val = double.tryParse(_currentInput) ?? 0.0;
      final withIva = val * 1.16;
      _expression = '$_currentInput + 16% IVA =';
      _currentInput = _formatResult(withIva);
      _shouldResetInput = true;
    });
  }

  String _formatResult(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(2);
  }

  double get _currentValue => double.tryParse(_currentInput) ?? 0.0;

  double get _convertedValue {
    if (_activeRate <= 0) return 0.0;
    if (_isUsdMode) {
      // De USD ($) a Bolívares (Bs.)
      return _currentValue * _activeRate;
    } else {
      // De Bolívares (Bs.) a USD ($)
      return _currentValue / _activeRate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0.00', 'es_VE');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Encabezado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.calculate, color: Color(0xFF6366F1), size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Calculadora Kryon',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              const SizedBox(height: 12),

              // Selector de Tasa y Modo Moneda
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Dropdown de tasas
                        DropdownButton<String>(
                          value: _selectedRateName,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1)),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 13),
                          items: _rates.keys.map((name) {
                            return DropdownMenuItem(
                              value: name,
                              child: Text('$name (${_rates[name]!.toStringAsFixed(2)} Bs)'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedRateName = val;
                                _activeRate = _rates[val]!;
                              });
                            }
                          },
                        ),

                        // Switch Moneda Base
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isUsdMode = !_isUsdMode;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isUsdMode ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _isUsdMode ? 'Modo: \$ USD' : 'Modo: Bs. VES',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.sync_alt, color: Colors.white, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Pantalla de la Calculadora
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _expression.isEmpty ? ' ' : _expression,
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_isUsdMode ? '\$' : 'Bs.'} $_currentInput',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const Divider(color: Color(0xFF334155), height: 16),
                    // Resultado convertido en la otra moneda
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isUsdMode ? 'Equivalente en Bolívares:' : 'Equivalente en Dólares:',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                        Text(
                          _isUsdMode
                              ? 'Bs. ${currencyFormat.format(_convertedValue)}'
                              : '\$ ${currencyFormat.format(_convertedValue)}',
                          style: TextStyle(
                            color: _isUsdMode ? const Color(0xFF38BDF8) : const Color(0xFF34D399),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Botones adicionales útiles: +16% IVA y Copiar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _onAddIva,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('+ 16% IVA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6366F1),
                        side: const BorderSide(color: Color(0xFF6366F1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text: _currentValue.toStringAsFixed(2),
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Copiado: ${_isUsdMode ? '\$' : 'Bs.'} $_currentInput (Equivalente: ${_isUsdMode ? 'Bs.' : '\$'} ${currencyFormat.format(_convertedValue)})',
                            ),
                            backgroundColor: const Color(0xFF10B981),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        if (widget.onApplyResult != null) {
                          widget.onApplyResult!(_currentValue, _isUsdMode ? 'USD' : 'VES');
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: Text(
                        widget.onApplyResult != null ? 'Usar Monto' : 'Copiar',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Teclado Numérico (Grid de botones)
              Column(
                children: [
                  _buildCalcRow(['C', '⌫', '%', '÷'], isOperatorRow: true),
                  const SizedBox(height: 8),
                  _buildCalcRow(['7', '8', '9', '×']),
                  const SizedBox(height: 8),
                  _buildCalcRow(['4', '5', '6', '-']),
                  const SizedBox(height: 8),
                  _buildCalcRow(['1', '2', '3', '+']),
                  const SizedBox(height: 8),
                  _buildCalcRow(['+/-', '0', '.', '=']),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalcRow(List<String> buttons, {bool isOperatorRow = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: buttons.map((btn) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildCalcButton(btn),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalcButton(String text) {
    final isSpecialOp = ['+', '-', '×', '÷', '='].contains(text);
    final isClear = text == 'C' || text == '⌫';
    final isEqual = text == '=';

    Color bgColor = const Color(0xFFF1F5F9);
    Color textColor = const Color(0xFF1E293B);

    if (isEqual) {
      bgColor = const Color(0xFF6366F1);
      textColor = Colors.white;
    } else if (isSpecialOp) {
      bgColor = const Color(0xFFEEF2FF);
      textColor = const Color(0xFF4F46E5);
    } else if (isClear) {
      bgColor = const Color(0xFFFEE2E2);
      textColor = const Color(0xFFDC2626);
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          if (text == 'C') {
            _onClear();
          } else if (text == '⌫') {
            _onBackspace();
          } else if (text == '=') {
            _onEqualPress();
          } else if (text == '+/-') {
            _onToggleSign();
          } else if (text == '%') {
            _onPercent();
          } else if (['+', '-', '×', '÷'].contains(text)) {
            _onOperatorPress(text);
          } else {
            _onDigitPress(text);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: text == '⌫'
              ? Icon(Icons.backspace_outlined, size: 18, color: textColor)
              : Text(
                  text,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
        ),
      ),
    );
  }
}
