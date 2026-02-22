import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ProductosService {
  Future<Map<String, dynamic>> obtenerProductosAgrupados() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'No hay token de autenticación'
        };
      }

      final url = Uri.parse(AppConfig.endpoint('productos/agrupados'));
      
      print(' Llamando a: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(' Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // El backend devuelve: { body: [...] } o { data: [...] }
        final productosData = data['body'] ?? data['data'] ?? data;
        
        if (productosData is! List) {
          return {
            'success': false,
            'message': 'Formato de respuesta inválido'
          };
        }

        print(' Productos cargados: ${(productosData).length}');

        return {
          'success': true,
          'productos': productosData,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Sesión expirada'
        };
      } else {
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}'
        };
      }
    } catch (e) {
      print(' Error en ProductosService: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e'
      };
    }
  }
}