import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class PasswordService {
  // Solicitar recuperación de contraseña (envía email con token)
  Future<Map<String, dynamic>> forgotPassword(String correo) async {
    try {
      print(' Solicitando recuperación de contraseña para: $correo');
      
      final url = Uri.parse(AppConfig.endpoint('persona/forgot-password'));
      print(' URL: $url');
      
      final body = json.encode({'Correo': correo});
      print(' Body: $body');
      
      final response = await http.post(
        url,
        headers: AppConfig.headers,
        body: body,
      );
      
      print('Respuesta: ${response.statusCode}');
      print(' Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(' Email de recuperación enviado exitosamente');
        
        return {
          'success': true,
          'message': data['Message'] ?? 'Correo enviado exitosamente',
          'resetLink': data['resetLink'], // Solo para pruebas en desarrollo
        };
      } else if (response.statusCode == 404) {
        print(' Correo no encontrado');
        return {
          'success': false,
          'message': 'El correo no está registrado',
        };
      } else {
        final data = json.decode(response.body);
        print(' Error ${response.statusCode}: ${data['Message']}');
        return {
          'success': false,
          'message': data['Message'] ?? 'Error al enviar correo',
        };
      }
    } catch (e, stackTrace) {
      print(' Excepción en forgotPassword: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Restablecer contraseña con token
  Future<Map<String, dynamic>> resetPassword(
    String token,
    String newPassword,
  ) async {
    try {
      print(' Restableciendo contraseña con token...');
      
      final url = Uri.parse(AppConfig.endpoint('persona/reset-password'));
      print(' URL: $url');
      
      final body = json.encode({
        'token': token,
        'newPassword': newPassword,
      });
      print(' Body enviado (sin password)');
      
      final response = await http.post(
        url,
        headers: AppConfig.headers,
        body: body,
      );
      
      print(' Respuesta: ${response.statusCode}');
      print(' Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(' Contraseña actualizada exitosamente');
        
        return {
          'success': true,
          'message': data['Message'] ?? 'Contraseña actualizada exitosamente',
        };
      } else if (response.statusCode == 404) {
        print('Usuario no encontrado');
        return {
          'success': false,
          'message': 'Usuario no encontrado',
        };
      } else {
        final data = json.decode(response.body);
        print(' Error ${response.statusCode}: ${data['Message']}');
        return {
          'success': false,
          'message': data['Message'] ?? 'Error al restablecer contraseña',
        };
      }
    } catch (e, stackTrace) {
      print(' Excepción en resetPassword: $e');
      print('Stack trace: $stackTrace');
      
      // Verificar si es error de token expirado
      if (e.toString().contains('jwt') || e.toString().contains('expired')) {
        return {
          'success': false,
          'message': 'El token ha expirado. Solicita un nuevo enlace de recuperación.',
        };
      }
      
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Validar formato de email
  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Validar contraseña (mínimo 6 caracteres)
  bool isValidPassword(String password) {
    return password.length >= 6;
  }
}