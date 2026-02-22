import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config/app_config.dart';

class AuthService {
  static const String _currentUserKey = 'current_user';
  static const String _tokenKey = 'auth_token';

  // ==================== LOGIN ====================
  Future<bool> login({required String email, required String password}) async {
    try {
      final url = Uri.parse(AppConfig.action("persona", "login"));

      final response = await http.post(
        url,
        headers: AppConfig.headers,
        body: jsonEncode({'Correo': email, 'Password': password}),
      );

      print('Login Status: ${response.statusCode}');
      print('Login Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final prefs = await SharedPreferences.getInstance();

        // Guardar token
        if (data['token'] != null) {
          await prefs.setString(_tokenKey, data['token']);
        }

        // Guardar usuario
        await prefs.setString(
          _currentUserKey,
          jsonEncode({
            // Asegúrate de usar la clave correcta de la respuesta del servidor
            // Yo usaré 'idPersona' para que coincida con tu ejemplo inicial:
            'id': data['id'], // 'id' que ya tenías
            'idPersona': data['idPersona'], // <-- CLAVE AGREGADA AQUÍ
            'rol': data['rol'],
            'correo': email,
            'message': data['Message'],
          }),
        );
        // --- FIN DE LA MODIFICACIÓN ---

        return true;
      }
      return false;
    } catch (e) {
      print('Error en login: $e');
      return false;
    }
  }

  // ==================== REGISTRO ====================
  Future<Map<String, dynamic>> register({
    required String numeroDocumento,
    required String tipoDocumento,
    required String primerNombre,
    String? segundoNombre,
    required String primerApellido,
    String? segundoApellido,
    required String telefono,
    required String correo,
    required String password,
  }) async {
    try {
      final url = Uri.parse(AppConfig.endpoint("register"));

      final response = await http.post(
        url,
        headers: AppConfig.headers,
        body: jsonEncode({
          'NumeroDocumento': numeroDocumento,
          'TipoDocumento': tipoDocumento,
          'Primer_Nombre': primerNombre,
          'Segundo_Nombre': segundoNombre,
          'Primer_Apellido': primerApellido,
          'Segundo_Apellido': segundoApellido,
          'Telefono': telefono,
          'Correo': correo,
          'Password': password,
        }),
      );

      print('Register Status: ${response.statusCode}');
      print('Register Response: ${response.body}');

      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 201,
        'message': data['Message'] ?? "Registro exitoso",
        'data': data,
      };
    } catch (e) {
      print('Error en registro: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ==================== CERRAR SESIÓN ====================
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    await prefs.remove(_tokenKey);
  }

  // ==================== OBTENER USUARIO ====================
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_currentUserKey);
      if (jsonStr == null) return null;
      return jsonDecode(jsonStr);
    } catch (e) {
      print('Error obteniendo usuario: $e');
      return null;
    }
  }

  Future<bool> isLoggedIn() async => (await getToken()) != null;

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<int?> getUserId() async {
    final user = await getCurrentUser();
    return user?['id'];
  }

  Future<String?> getUserRole() async {
    final user = await getCurrentUser();
    return user?['rol'];
  }
}
