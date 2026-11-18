import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/wallet_model.dart';
import '../services/api_service.dart';

class WalletsSectionWidget extends StatelessWidget {
  final WalletsSummaryModel? summary;
  final VoidCallback onUpdated;

  const WalletsSectionWidget({
    super.key,
    required this.summary,
    required this.onUpdated,
  });

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  IconData _walletIcon(String type) {
    switch (type) {
      case 'bolivares':
        return Icons.account_balance;
      case 'efectivo_usd':
        return Icons.payments_outlined;
      case 'binance_usdt':
        return Icons.currency_bitcoin;
      case 'zelle':
        return Icons.send_to_mobile;
      case 'zinli_wally':
        return Icons.credit_card;
      case 'euro':
        return Icons.euro_symbol;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  void _showEditWalletDialog(BuildContext context, WalletModel wallet) {
    final balanceCtrl = TextEditingController(text: wallet.balance.toStringAsFixed(2));
    final detailsCtrl = TextEditingController(text: wallet.accountDetails ?? '');
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(_walletIcon(wallet.walletType), color: _parseColor(wallet.colorHex)),
              const SizedBox(width: 8),
              Expanded(child: Text(wallet.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: balanceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Saldo Actual (${wallet.currency})',
                  prefixIcon: const Icon(Icons.account_balance_wallet),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Mis Datos de Cobro (Copiar/Pegar)',
                  hintText: 'Ej: Banesco 0134 | 0414-1234567 | V-20123456',
                  prefixIcon: const Icon(Icons.copy_all),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (wallet.accountDetails != null && wallet.accountDetails!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: wallet.accountDetails!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Datos de cuenta copiados al portapapeles'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copiar mis datos'),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      setState(() => saving = true);
                      try {
                        final bal = double.tryParse(balanceCtrl.text.replaceAll(',', '.')) ?? 0.0;
                        await ApiService().updateWallet(wallet.id, {
                          'balance': bal,
                          'account_details': detailsCtrl.text.trim(),
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        onUpdated();
                      } catch (e) {
                        setState(() => saving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (summary == null || summary!.wallets.isEmpty) return const SizedBox.shrink();

    final fmt = NumberFormat('#,##0.00', 'es_VE');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance_wallet, size: 16, color: Color(0xFF6366F1)),
                SizedBox(width: 6),
                Text(
                  'Mis Billeteras Venezuela',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Total: \$${fmt.format(summary!.totalUsd)}',
                style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: summary!.wallets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final w = summary!.wallets[index];
              final color = _parseColor(w.colorHex);
              final symbol = w.currency == 'VES'
                  ? 'Bs.'
                  : (w.currency == 'EUR' ? '€' : (w.currency == 'USDT' ? 'USDT' : '\$'));

              return InkWell(
                onTap: () => _showEditWalletDialog(context, w),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 158,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.28)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(_walletIcon(w.walletType), color: color, size: 16),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              w.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$symbol ${fmt.format(w.balance)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            w.currency == 'VES'
                                ? '≈ \$${w.equivalentUsd.toStringAsFixed(2)} BCV'
                                : '≈ Bs. ${fmt.format(w.equivalentBs)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
