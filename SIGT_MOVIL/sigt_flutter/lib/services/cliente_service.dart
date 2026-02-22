import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ClienteService {
  // Obtener el token del localStorage
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    print(' Token obtenido: ${token != null ? "Existe" : "No existe"}');
    if (token != null && token.isNotEmpty) {
      print(' Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
    }
    return token;
  }

  // Headers con autorización
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
    print(' Headers: Authorization: Bearer ${token?.substring(0, 20) ?? 'NO_TOKEN'}...');
    return headers;
  }

  // Obtener clientes con sus compras
  Future<Map<String, dynamic>> obtenerClientesCompras() async {
    try {
      print(' Solicitando clientes-compras...');
      final headers = await _getHeaders();
      final url = Uri.parse(AppConfig.endpoint('clientes-compras'));
      print(' URL: $url');
      
      final response = await http.get(url, headers: headers);
      
      print(' Respuesta clientes-compras: ${response.statusCode}');
      print(' Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Manejar diferentes formatos de respuesta
        List clientesData;
        if (data is Map && data.containsKey('data')) {
          clientesData = data['data'] ?? [];
        } else if (data is List) {
          clientesData = data;
        } else {
          clientesData = [];
        }
        
        print('Clientes obtenidos: ${clientesData.length}');
        return {
          'success': true,
          'data': clientesData,
        };
      } else if (response.statusCode == 401) {
        print(' Error 401: Token inválido o expirado');
        return {
          'success': false,
          'message': 'Sesión expirada. Por favor, inicia sesión nuevamente.',
        };
      } else {
        print(' Error ${response.statusCode}: ${response.body}');
        return {
          'success': false,
          'message': 'Error al obtener clientes: ${response.statusCode}',
        };
      }
    } catch (e, stackTrace) {
      print(' Excepción en obtenerClientesCompras: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Obtener top 5 clientes
  Future<Map<String, dynamic>> obtenerTopClientes() async {
    try {
      print(' Solicitando top-clientes...');
      final headers = await _getHeaders();
      final url = Uri.parse(AppConfig.endpoint('top-clientes'));
      print(' URL: $url');
      
      final response = await http.get(url, headers: headers);
      
      print(' Respuesta top-clientes: ${response.statusCode}');
      print(' Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Manejar diferentes formatos de respuesta
        List topClientesData;
        if (data is Map && data.containsKey('data')) {
          topClientesData = data['data'] ?? [];
        } else if (data is List) {
          topClientesData = data;
        } else {
          topClientesData = [];
        }
        
        print(' Top clientes obtenidos: ${topClientesData.length}');
        return {
          'success': true,
          'data': topClientesData,
        };
      } else if (response.statusCode == 401) {
        print(' Error 401: Token inválido o expirado');
        return {
          'success': false,
          'message': 'Sesión expirada',
        };
      } else {
        print(' Error ${response.statusCode}: ${response.body}');
        return {
          'success': false,
          'message': 'Error al obtener top clientes: ${response.statusCode}',
        };
      }
    } catch (e, stackTrace) {
      print(' Excepción en obtenerTopClientes: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Obtener estadísticas de clientes
  Future<Map<String, dynamic>> obtenerEstadisticasClientes() async {
    try {
      print(' Solicitando estadisticas-clientes...');
      final headers = await _getHeaders();
      final url = Uri.parse(AppConfig.endpoint('estadisticas-clientes'));
      print(' URL: $url');
      
      final response = await http.get(url, headers: headers);
      
      print(' Respuesta estadisticas-clientes: ${response.statusCode}');
      print(' Body estadisticas: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(' Estadísticas obtenidas');
        print(' Tipo de data: ${data.runtimeType}');
        print(' Data recibida: $data');
        
        // Manejar diferentes formatos de respuesta
        dynamic estadisticasData;
        
        if (data is Map) {
          // Si viene como {data: [...]} o {data: {porEstado: [...]}}
          estadisticasData = data['data'];
        } else {
          // Si viene directamente como array
          estadisticasData = data;
        }
        
        print(' Tipo de estadisticasData: ${estadisticasData.runtimeType}');
        
        // Convertir a formato esperado
        if (estadisticasData is List) {
          // Si es una lista directa, envolverla en {porEstado: [...]}
          return {
            'success': true,
            'data': {'porEstado': estadisticasData},
          };
        } else if (estadisticasData is Map) {
          // Si ya es un mapa, usarlo directamente
          return {
            'success': true,
            'data': estadisticasData,
          };
        } else {
          // Fallback: devolver estructura vacía
          return {
            'success': true,
            'data': {'porEstado': []},
          };
        }
      } else if (response.statusCode == 401) {
        print(' Error 401: Token inválido o expirado');
        return {
          'success': false,
          'message': 'Sesión expirada',
        };
      } else {
        print(' Error ${response.statusCode}: ${response.body}');
        return {
          'success': false,
          'message': 'Error al obtener estadísticas: ${response.statusCode}',
        };
      }
    } catch (e, stackTrace) {
      print(' Excepción en obtenerEstadisticasClientes: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Cargar todos los datos en una sola llamada
  Future<Map<String, dynamic>> cargarTodosDatos() async {
    try {
      print(' ========================================');
      print(' Iniciando carga de todos los datos...');
      print(' ========================================');
      
      final results = await Future.wait([
        obtenerClientesCompras(),
        obtenerTopClientes(),
        obtenerEstadisticasClientes(),
      ]);

      print(' Resultados:');
      print('   - Clientes: ${results[0]['success']}');
      print('   - Top Clientes: ${results[1]['success']}');
      print('   - Estadísticas: ${results[2]['success']}');
      print(' ========================================');

      return {
        'success': true,
        'clientes': results[0]['success'] ? results[0]['data'] : [],
        'topClientes': results[1]['success'] ? results[1]['data'] : [],
        'estadisticas': results[2]['success'] ? results[2]['data'] : {},
        'errors': [
          if (!results[0]['success']) results[0]['message'],
          if (!results[1]['success']) results[1]['message'],
          if (!results[2]['success']) results[2]['message'],
        ],
      };
    } catch (e) {
      print(' Error en cargarTodosDatos: $e');
      return {
        'success': false,
        'message': 'Error al cargar datos: $e',
      };
    }
  }

  // Método para debug: verificar si hay token guardado
  Future<void> debugTokenInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final currentUser = prefs.getString('current_user');
    
    print('═══════════════════════════════════════');
    print(' DEBUG - ClienteService');
    print('═══════════════════════════════════════');
    print('Token existe: ${token != null && token.isNotEmpty}');
    if (token != null && token.isNotEmpty) {
      print('Token length: ${token.length}');
      print('Token: ${token.substring(0, token.length > 50 ? 50 : token.length)}...');
    } else {
      print(' NO HAY TOKEN GUARDADO');
    }
    print('---');
    if (currentUser != null) {
      final user = json.decode(currentUser);
      print('Usuario:');
      print('  - ID: ${user['id']}');
      print('  - ID Persona: ${user['idPersona']}');
      print('  - Rol: ${user['rol']}');
      print('  - Correo: ${user['correo']}');
    } else {
      print('NO HAY USUARIO GUARDADO');
    }
    print('Todas las keys: ${prefs.getKeys()}');
    print('═══════════════════════════════════════');
  }
}