import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'auth_screen.dart';
import 'main_navigation.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Fase 1: 0.0s – 0.6s (0.00 a 0.19)
  late Animation<double> _baseFadeAnimation;
  late Animation<double> _cyanGlowAnimation;

  // Fase 2: 0.6s – 1.4s (0.19 a 0.44)
  late Animation<double> _arrowGrowthAnimation;
  late Animation<double> _arrowFlashAnimation;

  // Fase 3: 1.4s – 2.0s (0.44 a 0.63)
  late Animation<double> _lockScaleAnimation;
  late Animation<double> _lockGleamAnimation;

  // Fase 4: 2.0s – 2.8s (0.63 a 0.88)
  late Animation<double> _textRevealAnimation;
  late Animation<double> _spinnerFadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // Fase 1: Base fade-in y resplandor (0.0s - 0.6s)
    _baseFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.19, curve: Curves.easeOutCubic),
      ),
    );
    _cyanGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.05, 0.19, curve: Curves.easeInOut),
      ),
    );

    // Fase 2: Crecimiento de la gráfica / flecha ascendente y destellos (0.6s - 1.4s)
    _arrowGrowthAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.19, 0.44, curve: Curves.easeInOutCubic),
      ),
    );
    _arrowFlashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.38, 0.46, curve: Curves.easeOut),
      ),
    );

    // Fase 3: Candado con rebote y destello superior derecho (1.4s - 2.0s)
    _lockScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.44, 0.63, curve: Curves.elasticOut),
      ),
    );
    _lockGleamAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.65, curve: Curves.easeInOut),
      ),
    );

    // Fase 4: Revelación del texto blanco y spinner circular (2.0s - 2.8s)
    _textRevealAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.63, 0.88, curve: Curves.easeIn),
      ),
    );
    _spinnerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.70, 0.90, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // Navegar después de la animación completa
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateNext();
      }
    });
  }

  Future<void> _navigateNext() async {
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
    final hasSession = await ApiService().loadSavedSession();

    if (!mounted) return;

    if (!seenOnboarding) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => const OnboardingScreen(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        ),
      );
    } else if (hasSession) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => const MainNavigation(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => const AuthScreen(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D), // Azul oscuro profundo
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // Fondo con tenue resplandor central
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.9,
                      colors: [
                        const Color(0xFF0E1A38).withValues(alpha: 0.8),
                        const Color(0xFF0A0F1D),
                      ],
                    ),
                  ),
                ),
              ),

              // Elemento Central: Logo Animado con "K", Flecha y Candado
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Canvas de Logo con fases 1, 2 y 3
                    SizedBox(
                      width: 170,
                      height: 170,
                      child: CustomPaint(
                        painter: _KryonLogoPainter(
                          baseProgress: _baseFadeAnimation.value,
                          glowProgress: _cyanGlowAnimation.value,
                          arrowProgress: _arrowGrowthAnimation.value,
                          arrowFlashProgress: _arrowFlashAnimation.value,
                          lockScale: _lockScaleAnimation.value,
                          lockGleam: _lockGleamAnimation.value,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Fase 4: Texto "Kryon" revelado en blanco puro nítido
                    Opacity(
                      opacity: _textRevealAnimation.value,
                      child: Column(
                        children: [
                          Text(
                            'Kryon',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  color: const Color(0xFF22D3EE).withValues(alpha: 0.6 * _textRevealAnimation.value),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tu Administrador Financiero Inteligente',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 38),

                    // Fase 4: Indicador de carga circular en degradado cian
                    Opacity(
                      opacity: _spinnerFadeAnimation.value,
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color.lerp(const Color(0xFF06B6D4), const Color(0xFF22D3EE), _controller.value) ??
                                const Color(0xFF06B6D4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Pintor vectorial para la animación de Kryon: "K" base, flecha ascendente con destellos y candado protector
class _KryonLogoPainter extends CustomPainter {
  final double baseProgress;
  final double glowProgress;
  final double arrowProgress;
  final double arrowFlashProgress;
  final double lockScale;
  final double lockGleam;

  _KryonLogoPainter({
    required this.baseProgress,
    required this.glowProgress,
    required this.arrowProgress,
    required this.arrowFlashProgress,
    required this.lockScale,
    required this.lockGleam,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // 1. Resplandor cian suave detrás del logo (Fase 1)
    if (glowProgress > 0) {
      final glowPaint = Paint()
        ..color = const Color(0xFF06B6D4).withValues(alpha: 0.25 * glowProgress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
      canvas.drawCircle(Offset(cx, cy), 65, glowPaint);
    }

    // 2. Fondo del hexágono / emblema de marca (Fase 1)
    if (baseProgress > 0) {
      final emblemPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF1E293B).withValues(alpha: baseProgress),
            const Color(0xFF0F172A).withValues(alpha: baseProgress),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: 130, height: 130),
        const Radius.circular(32),
      );
      canvas.drawRRect(rrect, emblemPaint);

      // Borde cian sutil
      final borderPaint = Paint()
        ..color = const Color(0xFF22D3EE).withValues(alpha: 0.4 * baseProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(rrect, borderPaint);

      // Columna vertical izquierda de la letra "K"
      final kBarPaint = Paint()
        ..color = Colors.white.withValues(alpha: baseProgress)
        ..style = PaintingStyle.fill;
      final kBarRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 36, cy - 36, 14, 72),
        const Radius.circular(6),
      );
      canvas.drawRRect(kBarRRect, kBarPaint);
    }

    // 3. FASE 2: Gráfica luminosa en zigzag ascendente que forma la flecha de crecimiento (0.6s - 1.4s)
    if (arrowProgress > 0) {
      final path = Path();
      // Puntos del zigzag que nacen del centro de la K y se proyectan hacia arriba a la derecha
      final start = Offset(cx - 20, cy + 22);
      final p1 = Offset(cx - 4, cy - 2);
      final p2 = Offset(cx + 8, cy + 10);
      final arrowTip = Offset(cx + 34, cy - 32);

      path.moveTo(start.dx, start.dy);

      if (arrowProgress <= 0.35) {
        final t = arrowProgress / 0.35;
        path.lineTo(
          start.dx + (p1.dx - start.dx) * t,
          start.dy + (p1.dy - start.dy) * t,
        );
      } else if (arrowProgress <= 0.65) {
        path.lineTo(p1.dx, p1.dy);
        final t = (arrowProgress - 0.35) / 0.30;
        path.lineTo(
          p1.dx + (p2.dx - p1.dx) * t,
          p1.dy + (p2.dy - p1.dy) * t,
        );
      } else {
        path.lineTo(p1.dx, p1.dy);
        path.lineTo(p2.dx, p2.dy);
        final t = (arrowProgress - 0.65) / 0.35;
        final curTip = Offset(
          p2.dx + (arrowTip.dx - p2.dx) * t,
          p2.dy + (arrowTip.dy - p2.dy) * t,
        );
        path.lineTo(curTip.dx, curTip.dy);

        // Si la flecha casi culmina, dibujar la cabeza de la flecha
        if (arrowProgress > 0.85) {
          final headPaint = Paint()
            ..color = const Color(0xFF22D3EE)
            ..style = PaintingStyle.fill;

          final headPath = Path();
          headPath.moveTo(arrowTip.dx, arrowTip.dy);
          headPath.lineTo(arrowTip.dx - 14, arrowTip.dy + 4);
          headPath.lineTo(arrowTip.dx - 4, arrowTip.dy + 14);
          headPath.close();
          canvas.drawPath(headPath, headPaint);
        }
      }

      // Dibujar trazo luminoso con resplandor turquesa
      final glowLinePaint = Paint()
        ..color = const Color(0xFF06B6D4).withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawPath(path, glowLinePaint);

      final linePaint = Paint()
        ..color = const Color(0xFF22D3EE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, linePaint);

      // Destello en la punta de la flecha (Fase 2)
      if (arrowFlashProgress > 0) {
        final sparkPaint = Paint()
          ..color = Colors.white.withValues(alpha: (1.0 - (arrowFlashProgress - 0.5).abs() * 2).clamp(0.0, 1.0))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(arrowTip, 6 * arrowFlashProgress, sparkPaint);

        // Rayos de destello
        final rayPaint = Paint()
          ..color = const Color(0xFFE0F2FE).withValues(alpha: (1.0 - arrowFlashProgress).clamp(0.0, 1.0))
          ..strokeWidth = 1.5;
        for (int i = 0; i < 4; i++) {
          final angle = (i * math.pi / 2) + (arrowFlashProgress * math.pi / 4);
          final dx = math.cos(angle) * 12;
          final dy = math.sin(angle) * 12;
          canvas.drawLine(arrowTip, Offset(arrowTip.dx + dx, arrowTip.dy + dy), rayPaint);
        }
      }
    }

    // 4. FASE 3: Candado debajo de la flecha con escala/rebote y destello superior derecho (1.4s - 2.0s)
    if (lockScale > 0) {
      canvas.save();
      final lockCenter = Offset(cx + 8, cy + 22);
      canvas.translate(lockCenter.dx, lockCenter.dy);
      canvas.scale(lockScale);

      // Arco del candado
      final shacklePaint = Paint()
        ..color = const Color(0xFF94A3B8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;

      final shackleRect = Rect.fromCenter(center: const Offset(0, -10), width: 14, height: 16);
      canvas.drawArc(shackleRect, math.pi, math.pi, false, shacklePaint);

      // Cuerpo del candado
      final bodyPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(const Rect.fromLTWH(-11, -4, 22, 18));

      final bodyRRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-11, -4, 22, 18),
        const Radius.circular(5),
      );
      canvas.drawRRect(bodyRRect, bodyPaint);

      // Ojo de la cerradura
      final keyholePaint = Paint()..color = const Color(0xFF0F172A);
      canvas.drawCircle(const Offset(0, 3), 2.5, keyholePaint);
      canvas.drawRect(const Rect.fromLTWH(-1, 4, 2, 4), keyholePaint);

      // Destello brillante en su borde superior derecho al encajar (Fase 3)
      if (lockGleam > 0) {
        final gleamPoint = const Offset(9, -4);
        final gleamPaint = Paint()
          ..color = Colors.white.withValues(alpha: (1.0 - (lockGleam - 0.5).abs() * 2).clamp(0.0, 1.0))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(gleamPoint, 5 * lockGleam, gleamPaint);

        final crossPaint = Paint()
          ..color = Colors.white.withValues(alpha: (1.0 - lockGleam).clamp(0.0, 1.0))
          ..strokeWidth = 1.5;
        canvas.drawLine(Offset(gleamPoint.dx - 6, gleamPoint.dy), Offset(gleamPoint.dx + 6, gleamPoint.dy), crossPaint);
        canvas.drawLine(Offset(gleamPoint.dx, gleamPoint.dy - 6), Offset(gleamPoint.dx, gleamPoint.dy + 6), crossPaint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _KryonLogoPainter oldDelegate) {
    return oldDelegate.baseProgress != baseProgress ||
        oldDelegate.glowProgress != glowProgress ||
        oldDelegate.arrowProgress != arrowProgress ||
        oldDelegate.arrowFlashProgress != arrowFlashProgress ||
        oldDelegate.lockScale != lockScale ||
        oldDelegate.lockGleam != lockGleam;
  }
}
