import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/share_model.dart';
import '../config/api_config.dart';

class ShareProfileDialog extends StatefulWidget {
  const ShareProfileDialog({super.key});

  @override
  State<ShareProfileDialog> createState() => _ShareProfileDialogState();
}

class _ShareProfileDialogState extends State<ShareProfileDialog> {
  int _selectedMinutes = 60;
  bool _isLoading = false;
  SharedProfileToken? _generatedToken;
  List<UserShareItem> _activeShares = [];

  @override
  void initState() {
    super.initState();
    _loadActiveShares();
  }

  Future<void> _loadActiveShares() async {
    try {
      final shares = await ApiService().getUserShares();
      if (mounted) setState(() => _activeShares = shares);
    } catch (_) {}
  }

  Future<void> _generateShare() async {
    setState(() => _isLoading = true);
    try {
      final token = await ApiService().createShareToken(_selectedMinutes);
      final shares = await ApiService().getUserShares();
      if (mounted) {
        setState(() {
          _generatedToken = token;
          _activeShares = shares;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar enlace: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _revokeShare(String token) async {
    try {
      await ApiService().revokeShare(token);
      _loadActiveShares();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Acceso temporal revocado y desconectado con éxito'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (_) {}
  }

  void _previewSharedProfile(String token) async {
    showDialog(
      context: context,
      builder: (ctx) => _SharedProfilePreviewModal(token: token),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                        child: const Icon(Icons.share, color: Color(0xFF6366F1), size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Compartir Perfil Financiero',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Genera un enlace temporal de solo lectura para que otra persona (pareja, contador, asesor) pueda ver tus finanzas durante un tiempo exacto. Al cumplirse el tiempo, se desconecta automáticamente.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.3),
              ),
              const SizedBox(height: 16),

              // Selector de Duración
              const Text(
                'Selecciona el tiempo de acceso:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDurationChip(60, '1 Hora'),
                  _buildDurationChip(180, '3 Horas'),
                  _buildDurationChip(720, '12 Horas'),
                  _buildDurationChip(1440, '24 Horas'),
                ],
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _generateShare,
                  icon: const Icon(Icons.link, size: 18),
                  label: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Generar Enlace Seguro', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              // Si se generó enlace
              if (_generatedToken != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Enlace Temporal Activo',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4338CA), fontSize: 13),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('ACTIVO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${ApiConfig.baseUrl}/profile/shared/${_generatedToken!.shareToken}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(
                                  text: '${ApiConfig.baseUrl}/profile/shared/${_generatedToken!.shareToken}',
                                ));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Enlace copiado al portapapeles'),
                                    backgroundColor: Color(0xFF10B981),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy, size: 14),
                              label: const Text('Copiar Enlace', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF4338CA),
                                side: const BorderSide(color: Color(0xFF818CF8)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _previewSharedProfile(_generatedToken!.shareToken),
                              icon: const Icon(Icons.visibility_outlined, size: 14),
                              label: const Text('Previsualizar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4338CA),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Historial de Enlaces Activos
              if (_activeShares.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Enlaces Compartidos (Gestión & Desconexión):',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                ..._activeShares.map((s) {
                  final isExpired = s.isExpired;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isExpired ? const Color(0xFFF8FAFC) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isExpired ? const Color(0xFFE2E8F0) : const Color(0xFFC7D2FE)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isExpired ? 'Expirado / Desconectado' : 'Expira en ${s.minutesRemaining} min (${s.durationMinutes}m total)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isExpired ? const Color(0xFF94A3B8) : const Color(0xFF10B981),
                                ),
                              ),
                              Text(
                                'Token: ...${s.shareToken.substring(s.shareToken.length - 8)}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        if (!isExpired)
                          TextButton(
                            onPressed: () => _revokeShare(s.shareToken),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                            child: const Text('Desconectar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationChip(int minutes, String label) {
    final isSelected = _selectedMinutes == minutes;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 12)),
      selected: isSelected,
      selectedColor: const Color(0xFF6366F1),
      backgroundColor: const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (sel) {
        if (sel) setState(() => _selectedMinutes = minutes);
      },
    );
  }
}

// Modal de previsualización de lo que ve el invitado
class _SharedProfilePreviewModal extends StatelessWidget {
  final String token;

  const _SharedProfilePreviewModal({required this.token});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      child: FutureBuilder<SharedProfileData>(
        future: ApiService().getSharedProfile(token),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final data = snapshot.data;
          if (data == null || !data.isValid) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_off_outlined, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  const Text('Enlace Expirado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 6),
                  Text(
                    data?.message ?? 'El enlace temporal ha expirado y se ha desconectado automáticamente.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
                ],
              ),
            );
          }

          final meta = data.accessMeta ?? {};
          final fin = data.financialOverview ?? {};
          final payroll = data.payroll ?? {};
          final currencyFmt = NumberFormat('#,##0.00', 'es_VE');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF6366F1)),
                        const SizedBox(width: 8),
                        Text(
                          'Vista Invitado (Solo Lectura)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 8),

                // Contador de Tiempo Restante
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_top, color: Color(0xFFD97706), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tiempo restante de acceso: ${meta['minutes_remaining'] ?? 60} minutos.\nSe desconectará automáticamente al finalizar.',
                          style: const TextStyle(color: Color(0xFF92400E), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Perfil Financiero de: ${meta['shared_by'] ?? 'Usuario'}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),

                // Salud Financiera
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Salud Financiera:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                          Text(
                            '${fin['financial_health_score'] ?? 0} / 100 (${fin['financial_health_status'] ?? 'Excelente'})',
                            style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12, height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Balance Mensual Neto:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                          Text(
                            '\$ ${currencyFmt.format((fin['net_balance'] as num?)?.toDouble() ?? 0)}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Nómina y Deudas
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Próximo Cobro: ${payroll['days_remaining_to_payout'] ?? 0} días restantes',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sueldo esperado: \$ ${payroll['expected_salary_usd']} • Libre restante: \$ ${payroll['net_remaining_salary_usd']}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Deuda Total Activa: \$ ${currencyFmt.format((fin['total_debt_balance'] as num?)?.toDouble() ?? 0)}',
                        style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar Previsualización'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
