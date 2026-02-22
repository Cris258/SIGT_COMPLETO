import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class EmpleadoService {
  // Obtener el token del localStorage
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    print(' Token obtenido: ${token != null ? "Existe" : "No existe"}');
    if (token != null && token.isNotEmpty) {
      print('🔑 Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
    }
    return token;
  }

  // Obtener idPersona del usuario actual
  Future<String?> _getIdPersona() async {
    final prefs = await SharedPreferences.getInstance();
    
    print(' Buscando idPersona...');
    
    // OPCIÓN 1: Desde current_user (formato snake_case o camelCase)
    final currentUserJson = prefs.getString('current_user');
    if (currentUserJson != null) {
      try {
        final user = json.decode(currentUserJson);
        print(' Usuario completo: $user');
        
        // Intentar diferentes formatos del campo
        final idPersona = user['idPersona']?.toString() ?? 
                          user['id_persona']?.toString() ??
                          user['IdPersona']?.toString();
        
        if (idPersona != null && idPersona.isNotEmpty && idPersona != 'null') {
          print('idPersona obtenido desde current_user: $idPersona');
          return idPersona;
        }
      } catch (e) {
        print(' Error parseando current_user: $e');
      }
    }
    
    // OPCIÓN 2: Directamente desde SharedPreferences (diferentes formatos)
    final idPersonaDirect = prefs.getString('idPersona') ?? 
                           prefs.getString('id_persona') ??
                           prefs.getString('IdPersona');
    
    if (idPersonaDirect != null && idPersonaDirect.isNotEmpty) {
      print(' idPersona obtenido directo: $idPersonaDirect');
      return idPersonaDirect;
    }
    
    // OPCIÓN 3: Usar el ID del usuario como fallback
    if (currentUserJson != null) {
      try {
        final user = json.decode(currentUserJson);
        final userId = user['id']?.toString();
        if (userId != null && userId.isNotEmpty) {
          print(' Usando ID de usuario como fallback: $userId');
          return userId;
        }
      } catch (e) {
        print(' Error obteniendo ID de usuario: $e');
      }
    }
    
    print(' No se pudo obtener idPersona de ninguna fuente');
    return null;
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

  // Obtener tareas del empleado
  Future<Map<String, dynamic>> obtenerTareasEmpleado() async {
    try {
      print(' Solicitando tareas del empleado...');
      
      final idPersona = await _getIdPersona();
      
      if (idPersona == null || idPersona.isEmpty) {
        print('No se pudo obtener idPersona');
        return {
          'success': false,
          'message': 'No se pudo identificar al usuario',
        };
      }
      
      final headers = await _getHeaders();
      final url = Uri.parse(AppConfig.endpoint('tarea/empleado/$idPersona'));
      print(' URL: $url');
      
      final response = await http.get(url, headers: headers);
      
      print(' Respuesta tareas empleado: ${response.statusCode}');
      print(' Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Manejar diferentes formatos de respuesta
        List tareasData;
        if (data is Map && data.containsKey('body')) {
          tareasData = data['body'] ?? [];
        } else if (data is Map && data.containsKey('data')) {
          tareasData = data['data'] ?? [];
        } else if (data is List) {
          tareasData = data;
        } else {
          tareasData = [];
        }
        
        print(' Tareas obtenidas: ${tareasData.length}');
        return {
          'success': true,
          'data': tareasData,
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
          'message': 'Error al obtener tareas: ${response.statusCode}',
        };
      }
    } catch (e, stackTrace) {
      print(' Excepción en obtenerTareasEmpleado: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Actualizar estado de una tarea
  Future<Map<String, dynamic>> actualizarEstadoTarea(
    int idTarea,
    String nuevoEstado,
  ) async {
    try {
      print(' Actualizando estado de tarea $idTarea a "$nuevoEstado"...');
      
      final headers = await _getHeaders();
      final url = Uri.parse(AppConfig.endpoint('tarea/$idTarea/estado'));
      print(' URL: $url');
      
      final body = json.encode({'EstadoTarea': nuevoEstado});
      print(' Body: $body');
      
      final response = await http.put(
        url,
        headers: headers,
        body: body,
      );
      
      print(' Respuesta actualizar estado: ${response.statusCode}');
      print(' Body: ${response.body}');
      
      if (response.statusCode == 200) {
        print(' Estado actualizado correctamente');
        return {
          'success': true,
          'message': 'Estado actualizado correctamente',
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
          'message': 'Error al actualizar estado: ${response.statusCode}',
        };
      }
    } catch (e, stackTrace) {
      print(' Excepción en actualizarEstadoTarea: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Método para debug: verificar información del token y usuario
  Future<void> debugTokenInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final currentUser = prefs.getString('current_user');
    
    print('═══════════════════════════════════════');
    print(' DEBUG - EmpleadoService');
    print('═══════════════════════════════════════');
    print('Token existe: ${token != null && token.isNotEmpty}');
    if (token != null && token.isNotEmpty) {
      print('Token length: ${token.length}');
      print('Token: ${token.substring(0, token.length > 50 ? 50 : token.length)}...');
    } else {
      print('NO HAY TOKEN GUARDADO');
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
      print(' NO HAY USUARIO GUARDADO');
    }
    print('Todas las keys: ${prefs.getKeys()}');
    print('═══════════════════════════════════════');
  }
}