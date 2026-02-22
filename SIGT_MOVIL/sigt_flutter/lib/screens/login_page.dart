import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      print('========================================');
      print('INICIANDO PROCESO DE LOGIN');
      print('========================================');
      print('Email: ${_emailController.text.trim()}');

      final success = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      print('Resultado del login: ${success ? "EXITOSO" : "FALLIDO"}');

      if (!mounted) return;

      if (success) {
        // VERIFICAR QUE EL TOKEN SE GUARDÓ
        await _verificarTokenGuardado();

        // Obtener información del usuario
        final user = await _authService.getCurrentUser();
        final rol = user?['rol'] ?? 'Cliente';

        print('Usuario autenticado:');
        print(' - Rol: $rol');
        print(' - Datos completos: $user');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Bienvenido, $rol!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Redirigir según el rol
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _redirectByRole(rol);
        }
      } else {
        print('Login fallido: Credenciales incorrectas o cuenta inactiva');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credenciales incorrectas o cuenta inactiva'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('EXCEPCIÓN EN LOGIN: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Método para verificar que el token se guardó correctamente
  Future<void> _verificarTokenGuardado() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final currentUser = prefs.getString('current_user');

    print('========================================');
    print('VERIFICACIÓN POST-LOGIN');
    print('========================================');
    print('Token existe: ${token != null && token.isNotEmpty}');
    if (token != null && token.isNotEmpty) {
      print('Token length: ${token.length}');
      print(
        'Token preview: ${token.substring(0, token.length > 40 ? 40 : token.length)}...',
      );
    } else {
      print('¡ADVERTENCIA! El token NO se guardo correctamente');
    }
    print('---');
    print('Usuario guardado: ${currentUser != null}');
    if (currentUser != null) {
      print('Usuario data: $currentUser');
    }
    print('Todas las keys: ${prefs.getKeys()}');
    print('========================================');
  }

  void _redirectByRole(String rol) {
    final rolNormalizado = rol.toLowerCase().trim();

    print('========================================');
    print('REDIRECCIONAMIENTO POR ROL');
    print('========================================');
    print('Rol recibido: "$rol"');
    print('Rol normalizado: "$rolNormalizado"');

    // Redirigir según el rol usando rutas nombradas
    if (rolNormalizado == 'superadmin' || rolNormalizado == 'administrador') {
      // SuperAdmin y Administrador van al AdminPage
      print('Redirigiendo a /administrador');
      Navigator.pushReplacementNamed(context, '/administrador');
    } else if (rolNormalizado == 'empleado') {
      // Empleado va a su dashboard
      print('Redirigiendo a /empleado_dashboard');
      Navigator.pushReplacementNamed(context, '/empleado');
    } else if (rolNormalizado == 'cliente') {
      // Cliente va a su home
      print('Redirigiendo a /tienda');
      Navigator.pushReplacementNamed(context, '/tienda');
    } else {
      // Rol desconocido - por defecto redirigir a home
      print('Rol desconocido: "$rolNormalizado", redirigiendo a /home');
      Navigator.pushReplacementNamed(context, '/home');
    }
    print('========================================');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE6C7F6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Iniciar Sesión',
          style: TextStyle(color: Colors.black87),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Logo
                Center(
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/Logo Vibra Positiva.jpg',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE6C7F6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_user,
                            size: 60,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Título
                const Text(
                  '¡Bienvenido de nuevo!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Ingresa tus credenciales para continuar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),

                const SizedBox(height: 40),

                // Campo Email
                CustomTextField(
                  controller: _emailController,
                  label: 'Correo Electrónico',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu correo';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Ingresa un correo válido';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Campo Contraseña
                CustomTextField(
                  controller: _passwordController,
                  label: 'Contraseña',
                  icon: Icons.lock,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.black54,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu contraseña';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Link "¿Olvidaste tu contraseña?"
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/forgot_password');
                    },
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(color: Color(0xFFE6C7F6), fontSize: 13),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Botón Login
                CustomButton(
                  text: 'INICIAR SESIÓN',
                  onPressed: _isLoading ? null : _handleLogin,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 20),

                // Divider con "O"
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Colors.grey.shade400, thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'O',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Colors.grey.shade400, thickness: 1),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Link a Registro
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '¿No tienes cuenta? ',
                      style: TextStyle(color: Colors.black54),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/registro');
                      },
                      child: const Text(
                        'Regístrate aquí',
                        style: TextStyle(
                          color: Color(0xFFE6C7F6),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
