import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'main_navigation.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool isLoading = false;
  bool rememberMe = true;
  bool hasSavedCredentials = false;
  String? errorMessage;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkSavedSessionAndCredentials();
  }

  Future<void> _checkSavedSessionAndCredentials() async {
    final creds = await ApiService().getSavedCredentials();
    final savedEmail = creds['email'];
    final savedPass = creds['password'];

    if (savedEmail != null && savedEmail.isNotEmpty) {
      if (mounted) {
        setState(() {
          hasSavedCredentials = true;
          emailController.text = savedEmail;
          if (savedPass != null) passwordController.text = savedPass;
        });
      }
    }

    // Comprobar si ya existe una sesión guardada válida
    final hasActiveSession = await ApiService().loadSavedSession();
    if (hasActiveSession && mounted) {
      // Sesión guardada disponible para entrada rápida
      setState(() => hasSavedCredentials = true);
    }
  }

  Future<void> _loginWithBiometrics() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final hasActiveSession = await ApiService().loadSavedSession();
      if (hasActiveSession) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.fingerprint, color: Colors.white),
                  SizedBox(width: 8),
                  Text('¡Acceso biométrico verificado exitosamente!'),
                ],
              ),
              backgroundColor: Color(0xFF10B981),
              duration: Duration(seconds: 1),
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNavigation()),
          );
        }
        return;
      }

      // Si no hay token en caché pero hay credenciales guardadas
      final creds = await ApiService().getSavedCredentials();
      final email = creds['email'];
      final pass = creds['password'];
      if (email != null && pass != null) {
        await ApiService().login(email, pass, remember: true);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNavigation()),
          );
        }
      } else {
        setState(() => errorMessage = 'No hay credenciales registradas para biometría. Inicia sesión primero.');
      }
    } catch (e) {
      setState(() => errorMessage = 'Error biométrico: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _submit() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (!isLogin && name.isEmpty)) {
      setState(() {
        isLoading = false;
        errorMessage = 'Por favor completa todos los campos requeridos';
      });
      return;
    }

    try {
      if (isLogin) {
        await ApiService().login(email, password, remember: rememberMe);
      } else {
        await ApiService().register(name, email, password);
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo & Branding
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/app_logo.jpeg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          size: 44,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Kryon',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tu Administrador Financiero Personal',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 32),

                // Selector Login / Registro
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            isLogin = true;
                            errorMessage = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isLogin ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isLogin
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isLogin ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            isLogin = false;
                            errorMessage = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !isLogin ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: !isLogin
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Crear Perfil',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: !isLogin ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (!isLogin) ...[
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre Completo',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña (mínimo 6 caracteres)',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 8),

                // CHECKBOX RECORDAR USUARIO
                Row(
                  children: [
                    Checkbox(
                      value: rememberMe,
                      activeColor: const Color(0xFF10B981),
                      onChanged: (val) {
                        setState(() => rememberMe = val ?? true);
                      },
                    ),
                    const Text(
                      'Recordar usuario en este dispositivo',
                      style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Botón Iniciar Sesión / Crear Perfil
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            isLogin ? 'Entrar a Kryon' : 'Crear Mi Perfil',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                // BOTÓN ACCESO BIOMÉTRICO (HUELLA DACTILAR / FACE ID)
                if (hasSavedCredentials && isLogin) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : _loginWithBiometrics,
                      icon: const Icon(Icons.fingerprint, color: Color(0xFF6366F1), size: 26),
                      label: const Text(
                        'Ingresar con Datos Biométricos (Huella)',
                        style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Modo invitado / sin credenciales
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const MainNavigation()),
                    );
                  },
                  child: const Text(
                    'Explorar sin iniciar sesión (Modo Offline/Demo)',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
