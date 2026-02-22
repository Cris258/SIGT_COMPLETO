import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/tarea.dart'; // Importa el modelo creado en el paso 1

class TareaService {
  // Configuración de la URL BASE. 
  // NOTA: Para EMULADORES de Android, debes cambiar 'localhost' por '10.0.2.2' manualmente.
  final String _baseIP = 'localhost'; // Usamos 'localhost' como predeterminado
  late final String _baseUrl = 'http://$_baseIP:3001/api/tarea'; 
  
  //  TOKEN JWT INSERTADO 
  // Se añade el prefijo 'Bearer ' que es el esquema de autenticación estándar.
  final String _authToken = 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwiY29ycmVvIjoiY3Jpc21hdGl1czQ2QGdtYWlsLmNvbSIsInJvbCI6IlN1cGVyQWRtaW4iLCJpYXQiOjE3NjM5MzQxMzMsImV4cCI6MTc2MzkzNzczM30.WrRxhSOUNYwaMVAwg4QlKxXOQJjyDtGawPOziorFyf8'; 

  /// Realiza la solicitud POST para crear una nueva tarea.
  /// Retorna un Map (respuesta JSON del servidor) si tiene éxito (201), o null si falla.
  Future<Map<String, dynamic>?> crearTarea(Tarea nuevaTarea) async {
    final url = Uri.parse(_baseUrl);

    // 1. Mapeo del modelo Dart a la estructura JSON esperada por tu API
    final bodyData = {
      'Descripcion': nuevaTarea.descripcion,
      'FechaAsignacion': nuevaTarea.fechaAsignacion,
      'FechaLimite': nuevaTarea.fechaLimite,
      'EstadoTarea': nuevaTarea.estadoTarea,
      'Prioridad': nuevaTarea.prioridad,
      'Persona_FK': nuevaTarea.personaFk.toString(), 
    };

    try {
      print('Intentando enviar POST a: $_baseUrl');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json', // Informa al servidor que enviamos JSON
          'Authorization': _authToken,        //  AQUÍ SE ENVÍA EL TOKEN 
        },
        body: json.encode(bodyData), // Convierte el mapa de Dart a una cadena JSON
      );

      if (response.statusCode == 201) {
        // Tarea Creada exitosamente
        print('API Éxito: Tarea Creada.');
        return json.decode(response.body); // Retorna la respuesta completa del servidor
      } else {
        // Error de la API (400, 500, etc., o 401 si el token es incorrecto)
        print('API Error: Status ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return null;
      }
    } catch (e) {
      // Error de red o conexión
      print('Error de conexión/excepción: $e');
      return null;
    }
  }
}