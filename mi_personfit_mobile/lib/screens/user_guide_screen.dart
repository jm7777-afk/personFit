import 'package:flutter/material.dart';

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final guides = [
      {
        'icon': Icons.balance,
        'color': const Color(0xFF059669),
        'title': '1. Asistente "¿Cómo me conviene pagar hoy?"',
        'subtitle': 'Brecha Cambiaria + IGTF 3% Venezuela',
        'body':
            'Desde el Inicio, toca el botón "¿Bs o \$ hoy?". Escribe el precio marcado en el comercio (Dólar BCV o Euro BCV) y Kryon calcula automáticamente si ahorras más pagando en Bolívares por Pago Móvil/Punto o pagando en efectivo USD con el 3% de IGTF.',
      },
      {
        'icon': Icons.account_balance_wallet,
        'color': const Color(0xFF6366F1),
        'title': '2. Mis Billeteras Venezolanas',
        'subtitle': 'Bolívares, Efectivo \$, Binance USDT, Zelle, Zinli y Euro',
        'body':
            'Toca cualquiera de tus 6 billeteras en el Dashboard para actualizar su saldo real y guardar tus propios datos de cobro (ej. tu Pago Móvil o Zelle) con botón de copiar rápido.',
      },
      {
        'icon': Icons.calendar_month,
        'color': const Color(0xFFF59E0B),
        'title': '3. Control de Cuotas Cashea / Krece y Nómina',
        'subtitle': 'Cuotas cada 14 días descontadas de tu quincena',
        'body':
            'Registra tu sueldo (quincenal, semanal o diario) y tus compras en cuotas de Cashea o Krece. Kryon genera el calendario cada 14 días y descuenta automáticamente préstamos y cuotas para decirte exactamente cuánto sueldo libre te va quedando.',
      },
      {
        'icon': Icons.storefront,
        'color': const Color(0xFF0284C7),
        'title': '4. Supermercados de Carabobo, Minimarkets y Modo Offline',
        'subtitle': 'Listas, precios colaborativos y distancias en Carabobo',
        'body':
            'Filtra por Estado y Municipio (Valencia, Naguanagua, San Diego, Guacara, Los Guayos, Puerto Cabello). Si compras en un abasto o minimarket que no está en el directorio, créalo en segundos con "+ Minimarket". Además, tu lista activa funciona en Modo Offline dentro del supermercado aunque se caiga la señal.',
      },
      {
        'icon': Icons.copy_all,
        'color': const Color(0xFFDC2626),
        'title': '5. Deudas con Copiar Datos de Pago en 1 Toque',
        'subtitle': 'Pago Móvil, Zelle y Binance Pay sin errores',
        'body':
            'Al registrar una deuda o préstamo, guarda los datos bancarios del acreedor (Banco, Cédula, Teléfono o correo Zelle). Luego solo toca "Copiar Datos de Pago" en la tarjeta para pegar directo en tu banco.',
      },
      {
        'icon': Icons.bar_chart,
        'color': const Color(0xFF7C3AED),
        'title': '6. Control Diario, Semanal y Mensual + Servicios',
        'subtitle': 'Fibex, Inter, Corpoelec, Condominio BCV y más',
        'body':
            'En la pestaña de Gastos puedes alternar al instante entre Hoy (Diario), Esta Semana (Semanal) y Este Mes (Mensual), y usar plantillas de 1 toque para los servicios más comunes de Venezuela y Carabobo.',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Guía Rápida de Kryon', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFF38BDF8), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Bienvenido a Kryon Venezuela',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Aprende en 2 minutos a controlar tu dinero en Bolívares y Divisas, ganarle a la inflación en supermercados de Carabobo y organizar tus quincenas sin estrés.',
                  style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...guides.map((g) {
            final color = g['color'] as Color;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: ExpansionTile(
                initiallyExpanded: g == guides.first,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(g['icon'] as IconData, color: color, size: 22),
                ),
                title: Text(
                  g['title'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                subtitle: Text(
                  g['subtitle'] as String,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Text(
                    g['body'] as String,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.45),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
