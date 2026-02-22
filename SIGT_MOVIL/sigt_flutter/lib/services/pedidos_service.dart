import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/venta_historial_model.dart';

class PedidosService {
  // Usar las MISMAS claves que AuthService
  static const String _tokenKey = 'auth_token';
  static const String _currentUserKey = 'current_user';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<int?> _getIdPersona() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_currentUserKey);
    
    if (userJson == null) return null;
    
    try {
      final user = json.decode(userJson);
      // Intentar obtener 'idPersona' primero, si no existe usar 'id'
      return user['idPersona'] ?? user['id'];
    } catch (e) {
      print('Error al parsear usuario: $e');
      return null;
    }
  }

  Future<List<VentaHistorial>> obtenerHistorial() async {
    try {
      final token = await _getToken();
      final idPersona = await _getIdPersona();

      print(' ========================================');
      print(' DEBUG PEDIDOS SERVICE');
      print(' =======================================');
      print(' Token existe: ${token != null && token.isNotEmpty}');
      print(' idPersona: $idPersona');

      if (token == null || idPersona == null) {
        throw Exception('No hay sesión activa. Verifica el login.');
      }

      final url = Uri.parse(AppConfig.action('venta', 'historial/$idPersona'));
    
      print(' URL: $url');
      print(' ========================================');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print(' Status Code: ${response.statusCode}');
      print(' Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List ventasJson = data['body'] ?? [];
        
        print(' Ventas encontradas: ${ventasJson.length}');
        
        // Debug: imprimir primera venta completa
        if (ventasJson.isNotEmpty) {
          print(' Primera venta completa: ${ventasJson[0]}');
        }
        
        return ventasJson.map((json) => VentaHistorial.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        // No hay ventas, retornar lista vacía
        print('ℹ No se encontraron ventas para este usuario');
        return [];
      } else {
        throw Exception('Error al obtener historial: ${response.statusCode}');
      }
    } catch (e) {
      print(' Error en obtenerHistorial: $e');
      throw Exception('Error de conexión: $e');
    }
  }
}