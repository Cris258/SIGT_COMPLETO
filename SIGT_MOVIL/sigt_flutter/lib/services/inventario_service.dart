import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class InventarioService {
  // Obtener token de autenticación
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Headers con token
  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  // Cargar productos
  Future<List<dynamic>> cargarProductos() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(AppConfig.endpoint('productos')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception('Error al cargar productos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al cargar productos: $e');
    }
  }

  // Cargar top productos
  Future<List<dynamic>> cargarTopProductos() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(AppConfig.endpoint('top-productos')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception('Error al cargar top productos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al cargar top productos: $e');
    }
  }

  // Cargar estadísticas
  Future<Map<String, dynamic>?> cargarEstadisticas() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(AppConfig.endpoint('estadisticas-inventario')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Error al cargar estadísticas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al cargar estadísticas: $e');
    }
  }

  // Cargar todos los datos en paralelo
  Future<Map<String, dynamic>> cargarTodosDatos() async {
    try {
      final token = await getToken();

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Llamadas paralelas a las 3 APIs
      final responses = await Future.wait([
        http.get(Uri.parse(AppConfig.endpoint('productos')), headers: headers),
        http.get(Uri.parse(AppConfig.endpoint('top-productos')), headers: headers),
        http.get(Uri.parse(AppConfig.endpoint('estadisticas-inventario')), headers: headers),
      ]);

      List<dynamic> productos = [];
      List<dynamic> topProductos = [];
      Map<String, dynamic>? estadisticas;

      // Procesar respuesta de productos
      if (responses[0].statusCode == 200) {
        final data = json.decode(responses[0].body);
        productos = data['data'] ?? [];
      }

      // Procesar respuesta de top productos
      if (responses[1].statusCode == 200) {
        final data = json.decode(responses[1].body);
        topProductos = data['data'] ?? [];
      }

      // Procesar respuesta de estadísticas
      if (responses[2].statusCode == 200) {
        final data = json.decode(responses[2].body);
        estadisticas = data['data'];
      }

      return {
        'productos': productos,
        'topProductos': topProductos,
        'estadisticas': estadisticas,
      };
    } catch (e) {
      throw Exception('Error al cargar datos del inventario: $e');
    }
  }
}