import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../models/persona.dart'; //  IMPORTAMOS EL MODELO EXISTENTE

// ------------------------------------
// SERVICIO API
// ------------------------------------
class PersonaService {
  // Obtener datos del usuario
  static Future<Persona> obtenerDatosUsuario() async {
    try {
      debugPrint(' [API] Iniciando obtenerDatosUsuario...');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Obtener el ID desde el objeto current_user
      final userJson = prefs.getString('current_user');
      final token = prefs.getString('auth_token');
      
      debugPrint(' [API] Datos de SharedPreferences:');
      debugPrint('   - current_user JSON: $userJson');
      debugPrint('   - Token existe: ${token != null ? 'SÍ ✅' : 'NO ❌'}');

      if (userJson == null || userJson.isEmpty) {
        debugPrint(' [API] Error: No hay current_user en SharedPreferences');
        throw Exception('No se encontró información del usuario. Por favor, inicie sesión nuevamente.');
      }

      // Parsear el JSON para obtener el ID
      final userData = json.decode(userJson);
      
      // CORRECCIÓN: Intentar obtener el ID desde 'idPersona' o 'id'
      final userId = userData['idPersona']?.toString() ?? userData['id']?.toString();
      
      debugPrint('   - User ID extraído: $userId');
      debugPrint('   - Estructura completa userData: $userData');

      if (userId == null || userId.isEmpty) {
        debugPrint(' [API] Error: No hay ID en current_user');
        throw Exception('No se encontró el ID del usuario.');
      }

      // Usar AppConfig.byId para construir la URL
      final urlString = AppConfig.byId('persona', userId);
      final url = Uri.parse(urlString);
      debugPrint(' [API] Haciendo petición GET a: $url');

      final headers = {
        ...AppConfig.headers,
        if (token != null) 'Authorization': 'Bearer $token',
      };
      debugPrint(' [API] Headers: ${headers.keys}');

      final response = await http.get(url, headers: headers);

      debugPrint(' [API] Respuesta del servidor:');
      debugPrint('   - Status Code: ${response.statusCode}');
      debugPrint('   - Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint(' [API] JSON parseado exitosamente');
        debugPrint(' [API] Estructura del JSON: ${data.keys}');
        
        // CORRECCIÓN: Los datos vienen dentro de 'body'
        final personaData = data['body'] ?? data;
        debugPrint(' [API] Datos de persona extraídos: $personaData');
        
        final persona = Persona.fromJson(personaData);
        debugPrint(' [API] Objeto Persona creado exitosamente');
        debugPrint('   - Datos cargados:');
        debugPrint('     • ID: ${persona.idPersona}');
        debugPrint('     • Tipo Doc: ${persona.tipoDocumento}');
        debugPrint('     • Num Doc: ${persona.numeroDocumento}');
        debugPrint('     • Nombre: ${persona.primerNombre} ${persona.segundoNombre ?? ""}');
        debugPrint('     • Apellido: ${persona.primerApellido} ${persona.segundoApellido ?? ""}');
        debugPrint('     • Teléfono: ${persona.telefono}');
        debugPrint('     • Correo: ${persona.correo}');
        
        return persona;
      } else {
        debugPrint(' [API] Error HTTP ${response.statusCode}');
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Error al cargar los datos');
      }
    } catch (e, stackTrace) {
      debugPrint(' [API] Excepción capturada: $e');
      debugPrint(' [API] StackTrace: $stackTrace');
      rethrow;
    }
  }

  // Actualizar datos del usuario
  static Future<void> actualizarDatosUsuario(Persona persona) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final userJson = prefs.getString('current_user');
      final token = prefs.getString('auth_token');

      if (userJson == null || userJson.isEmpty) {
        throw Exception('No se encontró información del usuario');
      }

      final userData = json.decode(userJson);
      // CORRECCIÓN: Intentar obtener el ID desde 'idPersona' o 'id'
      final userId = userData['idPersona']?.toString() ?? userData['id']?.toString();

      if (userId == null || userId.isEmpty) {
        throw Exception('No se encontró el ID del usuario');
      }

      final url = Uri.parse(AppConfig.byId('persona', userId));
      debugPrint(' Enviando actualización a: $url');
      debugPrint(' Datos: ${persona.toJsonUpdate()}');

      final response = await http.put(
        url,
        headers: {
          ...AppConfig.headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(persona.toJsonUpdate()),
      );

      debugPrint(' Respuesta de actualización:');
      debugPrint('  - Status: ${response.statusCode}');
      debugPrint('  - Body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint(' Datos actualizados correctamente');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Error al actualizar los datos');
      }
    } catch (e) {
      debugPrint(' Error al actualizar datos: $e');
      rethrow;
    }
  }
}

// ------------------------------------
// WIDGET DEL MODAL
// ------------------------------------
class ActualizarDatosModal extends StatefulWidget {
  const ActualizarDatosModal({super.key});

  @override
  State<ActualizarDatosModal> createState() => _ActualizarDatosModalState();
}

class _ActualizarDatosModalState extends State<ActualizarDatosModal> {
  Persona? formData;
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();
  Map<String, String?> errors = {};

  @override
  void initState() {
    super.initState();
    debugPrint('🔵 [INIT] Modal inicializando...');
    
    // Llamar después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatosUsuario();
    });
  }

  Future<void> _cargarDatosUsuario() async {
    debugPrint(' [CARGA] Iniciando carga de datos...');
    
    // DIAGNÓSTICO: Ver TODO lo que hay en SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      debugPrint(' [DIAGNÓSTICO] Todas las claves en SharedPreferences:');
      for (var key in allKeys) {
        final value = prefs.get(key);
        if (key.toLowerCase().contains('token')) {
          debugPrint('   - $key: ${value.toString().substring(0, value.toString().length > 30 ? 30 : value.toString().length)}...');
        } else {
          debugPrint('   - $key: $value');
        }
      }
    } catch (e) {
      debugPrint(' [DIAGNÓSTICO] Error al leer SharedPreferences: $e');
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      debugPrint(' [CARGA] Llamando al servicio...');
      final data = await PersonaService.obtenerDatosUsuario();
    
      debugPrint('[CARGA] Datos recibidos del servicio');
      
      if (mounted) {
        setState(() {
          formData = data;
          _isLoading = false;
        });
        debugPrint('🏁 [CARGA] Datos aplicados al formulario exitosamente');
      }
    } catch (e, stackTrace) {
      debugPrint(' [ERROR] Error al cargar datos: $e');
      debugPrint(' [ERROR] StackTrace: $stackTrace');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        _mostrarSnackBar(
          context,
          'Error al cargar los datos del usuario: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    debugPrint(' Iniciando actualización...');
    
    if (formData == null) {
      debugPrint(' No hay datos para actualizar');
      return;
    }
    
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await PersonaService.actualizarDatosUsuario(formData!);
        
        if (mounted) {
          _mostrarSnackBar(
            context,
            '¡Datos actualizados correctamente!',
            isError: false,
          );
          
          await Future.delayed(const Duration(milliseconds: 800));
          
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        debugPrint(' Error al actualizar: $e');
        
        if (mounted) {
          _mostrarSnackBar(
            context,
            'Error al actualizar: ${e.toString()}',
            isError: true,
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      debugPrint(' Validación del formulario fallida');
    }
  }

  void _mostrarSnackBar(BuildContext context, String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String initialValue,
    required void Function(String)? onChanged,
    bool readOnly = false,
    bool isRequired = false,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        initialValue: initialValue,
        onChanged: onChanged,
        readOnly: readOnly,
        enabled: !_isLoading,
        keyboardType: keyboardType,
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return '$label es requerido';
          }
          if (validator != null) {
            return validator(value);
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          border: const OutlineInputBorder(),
          filled: readOnly,
          fillColor: readOnly ? Colors.grey[200] : null,
          errorText: errors[label],
          helperText: readOnly ? 'Este campo no se puede modificar' : null,
          helperStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Actualizar Datos'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: _isLoading || formData == null
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Cargando datos...'),
                        ],
                      ),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _buildTextField(
                        label: 'Tipo de Documento',
                        initialValue: formData!.tipoDocumento,
                        onChanged: null,
                        readOnly: true,
                      ),
                      _buildTextField(
                        label: 'Número de Documento',
                        initialValue: formData!.numeroDocumento.toString(),
                        onChanged: null,
                        readOnly: true,
                      ),
                      _buildTextField(
                        label: 'Primer Nombre',
                        initialValue: formData!.primerNombre,
                        isRequired: true,
                        onChanged: (value) {
                          setState(() {
                            formData = Persona(
                              idPersona: formData!.idPersona,
                              numeroDocumento: formData!.numeroDocumento,
                              tipoDocumento: formData!.tipoDocumento,
                              primerNombre: value,
                              segundoNombre: formData!.segundoNombre,
                              primerApellido: formData!.primerApellido,
                              segundoApellido: formData!.segundoApellido,
                              telefono: formData!.telefono,
                              correo: formData!.correo,
                              password: formData!.password,
                              rolFk: formData!.rolFk,
                              estadoPersonaFk: formData!.estadoPersonaFk,
                            );
                          });
                        },
                        validator: (value) {
                          if (value != null && !RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]*$').hasMatch(value)) {
                            return 'El nombre solo puede contener letras';
                          }
                          return null;
                        },
                      ),
                      _buildTextField(
                        label: 'Segundo Nombre',
                        initialValue: formData!.segundoNombre ?? '',
                        onChanged: (value) {
                          setState(() {
                            formData = Persona(
                              idPersona: formData!.idPersona,
                              numeroDocumento: formData!.numeroDocumento,
                              tipoDocumento: formData!.tipoDocumento,
                              primerNombre: formData!.primerNombre,
                              segundoNombre: value,
                              primerApellido: formData!.primerApellido,
                              segundoApellido: formData!.segundoApellido,
                              telefono: formData!.telefono,
                              correo: formData!.correo,
                              password: formData!.password,
                              rolFk: formData!.rolFk,
                              estadoPersonaFk: formData!.estadoPersonaFk,
                            );
                          });
                        },
                        validator: (value) {
                          if (value != null && value.isNotEmpty && !RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]*$').hasMatch(value)) {
                            return 'El nombre solo puede contener letras';
                          }
                          return null;
                        },
                      ),
                      _buildTextField(
                        label: 'Primer Apellido',
                        initialValue: formData!.primerApellido,
                        isRequired: true,
                        onChanged: (value) {
                          setState(() {
                            formData = Persona(
                              idPersona: formData!.idPersona,
                              numeroDocumento: formData!.numeroDocumento,
                              tipoDocumento: formData!.tipoDocumento,
                              primerNombre: formData!.primerNombre,
                              segundoNombre: formData!.segundoNombre,
                              primerApellido: value,
                              segundoApellido: formData!.segundoApellido,
                              telefono: formData!.telefono,
                              correo: formData!.correo,
                              password: formData!.password,
                              rolFk: formData!.rolFk,
                              estadoPersonaFk: formData!.estadoPersonaFk,
                            );
                          });
                        },
                        validator: (value) {
                          if (value != null && !RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]*$').hasMatch(value)) {
                            return 'El apellido solo puede contener letras';
                          }
                          return null;
                        },
                      ),
                      _buildTextField(
                        label: 'Segundo Apellido',
                        initialValue: formData!.segundoApellido ?? '',
                        onChanged: (value) {
                          setState(() {
                            formData = Persona(
                              idPersona: formData!.idPersona,
                              numeroDocumento: formData!.numeroDocumento,
                              tipoDocumento: formData!.tipoDocumento,
                              primerNombre: formData!.primerNombre,
                              segundoNombre: formData!.segundoNombre,
                              primerApellido: formData!.primerApellido,
                              segundoApellido: value,
                              telefono: formData!.telefono,
                              correo: formData!.correo,
                              password: formData!.password,
                              rolFk: formData!.rolFk,
                              estadoPersonaFk: formData!.estadoPersonaFk,
                            );
                          });
                        },
                        validator: (value) {
                          if (value != null && value.isNotEmpty && !RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]*$').hasMatch(value)) {
                            return 'El apellido solo puede contener letras';
                          }
                          return null;
                        },
                      ),
                      _buildTextField(
                        label: 'Número de Teléfono',
                        initialValue: formData!.telefono,
                        keyboardType: TextInputType.phone,
                        onChanged: (value) {
                          setState(() {
                            formData = Persona(
                              idPersona: formData!.idPersona,
                              numeroDocumento: formData!.numeroDocumento,
                              tipoDocumento: formData!.tipoDocumento,
                              primerNombre: formData!.primerNombre,
                              segundoNombre: formData!.segundoNombre,
                              primerApellido: formData!.primerApellido,
                              segundoApellido: formData!.segundoApellido,
                              telefono: value,
                              correo: formData!.correo,
                              password: formData!.password,
                              rolFk: formData!.rolFk,
                              estadoPersonaFk: formData!.estadoPersonaFk,
                            );
                          });
                        },
                        validator: (value) {
                          if (value != null && value.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(value)) {
                            return 'El teléfono debe tener 10 dígitos';
                          }
                          return null;
                        },
                      ),
                      _buildTextField(
                        label: 'Correo Electrónico',
                        initialValue: formData!.correo,
                        onChanged: null,
                        readOnly: true,
                      ),
                    ],
                  ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Finalizar'),
        ),
      ],
    );
  }
}

// ------------------------------------
// FUNCIÓN PARA MOSTRAR EL MODAL
// ------------------------------------
void mostrarModalActualizarDatos(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const ActualizarDatosModal();
    },
  );
}