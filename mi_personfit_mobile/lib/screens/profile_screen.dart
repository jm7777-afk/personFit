import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/notification_model.dart';
import '../widgets/share_profile_dialog.dart';
import '../widgets/standard_calculator_dialog.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<NotificationModel> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => isLoading = true);
    try {
      final notifs = await ApiService().getNotifications();
      if (mounted) setState(() => notifications = notifs);
    } catch (e) {
      // Ignorar
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showChangeServerUrlDialog() {
    final urlController = TextEditingController(text: ApiConfig.baseUrl.replaceAll('/api/v1', ''));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configurar Servidor / API'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajusta la URL base para conectar con tu backend local o en Render:',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                hintText: 'http://10.0.2.2:3000 o https://mi-api.onrender.com',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ApiConfig.updateBaseUrl(urlController.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Servidor configurado a: ${ApiConfig.baseUrl}')),
              );
              _loadNotifications();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Mi Perfil & Recordatorios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _showChangeServerUrlDialog,
            tooltip: 'Configurar URL de Servidor',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de Perfil
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFF10B981).withOpacity(0.15),
                    child: Text(
                      user != null && user.name.isNotEmpty ? user.name[0].toUpperCase() : 'P',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Usuario Kryon',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'usuario@kryon.app',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Plan Personal Pro Activo',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recordatorios & Notificaciones Activas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recordatorios de Deudas y Alertas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                Text(
                  '${notifications.length} activas',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (notifications.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF10B981), size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('No tienes pagos atrasados ni alertas urgentes pendientes.'),
                    ),
                  ],
                ),
              )
            else
              ...notifications.map((notif) {
                final isUrgent = notif.isUrgent;
                final isCelebration = notif.type == 'celebration';
                Color color = const Color(0xFF3B82F6);
                IconData icon = Icons.info_outline;

                if (isCelebration) {
                  color = const Color(0xFF10B981);
                  icon = Icons.celebration_outlined;
                } else if (isUrgent) {
                  color = const Color(0xFFEF4444);
                  icon = Icons.warning_amber_rounded;
                } else if (notif.priority == 'medium') {
                  color = const Color(0xFFF59E0B);
                  icon = Icons.schedule;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif.title,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notif.message,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 20),

            // COMPARTIR PERFIL FINANCIERO TEMPORAL (1 HORA, ETC.)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.share, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Compartir Perfil Financiero',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Genera un enlace con límite de tiempo (ej. 1 hora, 3 horas) para que otra persona vea tu estado financiero. Al vencer el tiempo, se desconecta automáticamente.',
                    style: TextStyle(color: Color(0xFFE0E7FF), fontSize: 13, height: 1.3),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const ShareProfileDialog(),
                        );
                      },
                      icon: const Icon(Icons.timer_outlined, size: 18),
                      label: const Text('Gestionar Enlace Temporal', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4338CA),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // HERRAMIENTAS ADICIONALES (Calculadora & Preferencias)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calculate_outlined, color: Color(0xFF6366F1)),
                    ),
                    title: const Text('Calculadora Kryon con Tasas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Suma, resta, IVA y conversión Bs / \$ en vivo', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => const StandardCalculatorDialog(),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Servidor & DevOps Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cloud_sync_outlined, color: Color(0xFF64748B)),
                    title: const Text('Servidor API Conectado', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(ApiConfig.baseUrl, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    trailing: TextButton(
                      onPressed: _showChangeServerUrlDialog,
                      child: const Text('Cambiar'),
                    ),
                  ),
                  const Divider(color: Color(0xFFF1F5F9)),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout, color: Color(0xFFEF4444)),
                    title: const Text('Cerrar Sesión', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                    onTap: () {
                      ApiService().logout();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
