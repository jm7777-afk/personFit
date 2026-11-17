import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      icon: Icons.calendar_today_rounded,
      iconColor: const Color(0xFF6366F1),
      title: 'Control de Nómina y Deudas',
      subtitle: 'Cuenta regresiva para tu próximo cobro (Quincenal, Semanal o Diario). Si pides prestado, se descuenta de tu sueldo para que siempre sepas cuánto te va quedando libre.',
      badgeText: 'GESTIÓN ACTIVA',
    ),
    OnboardingSlide(
      icon: Icons.shopping_cart_outlined,
      iconColor: const Color(0xFF10B981),
      title: 'Supermercados & ¿Cuánto Subió?',
      subtitle: 'Lleva tu lista interactiva de compras ("qué llevo, cuánto llevo en tiempo real"), analiza la variación de precios en Bs y \$ entre supermercados y descubre cuál es más económico.',
      badgeText: 'AHORRO INTELIGENTE',
    ),
    OnboardingSlide(
      icon: Icons.calculate_outlined,
      iconColor: const Color(0xFF06B6D4),
      title: 'Calculadora con Tasas y Seguridad',
      subtitle: 'Calcula con tasas en vivo (BCV, Paralelo y Euro), añade 16% IVA y comparte tu perfil financiero temporalmente por 1 hora con desconexión automática protegida.',
      badgeText: 'PROTECCIÓN TOTAL',
    ),
  ];

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      body: SafeArea(
        child: Column(
          children: [
            // Barra superior con botón Saltar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22D3EE).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shield_outlined, color: Color(0xFF22D3EE), size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'KRYON',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: const Text(
                      'Saltar',
                      style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            // PageView de Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icono Ilustrativo dentro de contenedor estilizado
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                slide.iconColor.withValues(alpha: 0.25),
                                Colors.transparent,
                              ],
                            ),
                            border: Border.all(
                              color: slide.iconColor.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Icon(slide.icon, size: 68, color: slide.iconColor),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: slide.iconColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: slide.iconColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            slide.badgeText,
                            style: TextStyle(
                              color: slide.iconColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Título
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Subtítulo
                        Text(
                          slide.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicador de Puntos (Dots) y Botón Siguiente / Comenzar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (idx) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == idx ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == idx ? const Color(0xFF22D3EE) : const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _slides.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _finishOnboarding();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF06B6D4),
                        foregroundColor: const Color(0xFF0A0F1D),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _currentPage == _slides.length - 1 ? 'Comenzar a Usar Kryon' : 'Siguiente',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
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

class OnboardingSlide {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String badgeText;

  OnboardingSlide({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badgeText,
  });
}
