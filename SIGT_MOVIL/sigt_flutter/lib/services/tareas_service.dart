import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/tarea.dart';

class TareaService {
  // Obtener token desde SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Headers con autorización
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  // Crear una nueva tarea
  Future<Map<String, dynamic>?> crearTarea(Tarea nuevaTarea) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(AppConfig.endpoint('tarea'));

      final bodyData = {
        'Descripcion': nuevaTarea.descripcion,
        'FechaAsignacion': nuevaTarea.fechaAsignacion,
        'FechaLimite': nuevaTarea.fechaLimite,
        'EstadoTarea': nuevaTarea.estadoTarea,
        'Prioridad': nuevaTarea.prioridad,
        'Persona_FK': nuevaTarea.personaFk.toString(),
      };

      print('POST a: ${AppConfig.endpoint('tarea')}');

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(bodyData),
      );

      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 201) {
        print('Tarea creada exitosamente');
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        print('Token inválido o expirado');
        return null;
      } else {
        print('Error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error de conexión: $e');
      return null;
    }
  }
}