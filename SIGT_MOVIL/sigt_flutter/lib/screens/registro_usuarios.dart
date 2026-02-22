import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../widgets/header_widget.dart';
import '../widgets/footer_widget.dart';
import '../models/rol.dart';

// ------------------------------------
// SERVICIO DE REGISTRO
// ------------------------------------
class RegistroService {
  // Obtener roles disponibles
  static Future<List<Rol>> obtenerRoles() async {
    try {
      debugPrint(' [ROLES] Obteniendo roles...');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      debugPrint(' [ROLES] Token presente: ${token != null}');
      
      final url = Uri.parse(AppConfig.endpoint('rol'));
      debugPrint(' [ROLES] GET: $url');

      final response = await http.get(
        url,
        headers: {
          ...AppConfig.headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      debugPrint(' [ROLES] Status: ${response.statusCode}');
      debugPrint(' [ROLES] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint(' [ROLES] Data structure: ${data.keys}');
        
        // Verificar si 'body' existe en la respuesta
        if (!data.containsKey('body')) {
          debugPrint(' [ROLES] La respuesta no contiene "body". Estructura completa: $data');
          throw Exception('Respuesta del servidor sin campo "body"');
        }
        
        final rolesData = data['body'] as List;
        debugPrint('📋 [ROLES] Cantidad de roles recibidos: ${rolesData.length}');
        
        // Filtrar SuperAdmin
        final roles = rolesData
            .map((rol) => Rol.fromJson(rol))
            .where((rol) => rol.nombreRol != 'SuperAdmin')
            .toList();
        
        debugPrint(' [ROLES] ${roles.length} roles obtenidos (sin SuperAdmin)');
        return roles;
      } else {
        final errorBody = response.body;
        debugPrint(' [ROLES] Error ${response.statusCode}: $errorBody');
        throw Exception('Error ${response.statusCode}: $errorBody');
      }
    } catch (e, stackTrace) {
      debugPrint(' [ROLES] Error: $e');
      debugPrint(' [ROLES] StackTrace: $stackTrace');
      rethrow;
    }
  }

  // Registrar nueva persona
  static Future<void> registrarPersona(Map<String, dynamic> datosPersona) async {
    try {
      debugPrint(' [REGISTRO] Iniciando registro...');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final url = Uri.parse(AppConfig.endpoint('persona'));
      debugPrint(' [REGISTRO] POST: $url');
      debugPrint(' [REGISTRO] Datos: $datosPersona');

      final response = await http.post(
        url,
        headers: {
          ...AppConfig.headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(datosPersona),
      );

      debugPrint(' [REGISTRO] Status: ${response.statusCode}');
      debugPrint(' [REGISTRO] Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint(' [REGISTRO] Usuario registrado exitosamente');
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['Message'] ?? errorData['message'] ?? 'Error al registrar';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint(' [REGISTRO] Error: $e');
      rethrow;
    }
  }
}


// PANTALLA DE REGISTRO

class RegistroUsuarios extends StatefulWidget {
  const RegistroUsuarios({super.key});

  @override
  State<RegistroUsuarios> createState() => _RegistroUsuariosState();
}

class _RegistroUsuariosState extends State<RegistroUsuarios> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _numeroDocumentoController = TextEditingController();
  final _primerNombreController = TextEditingController();
  final _segundoNombreController = TextEditingController();
  final _primerApellidoController = TextEditingController();
  final _segundoApellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _showPassword = false;
  bool _isLoading = false;
  String? _tipoDocumento;
  int? _rolSeleccionado;
  List<Rol> _roles = [];

  final List<String> _tiposDocumento = ['CC', 'TI', 'CE', 'Pasaporte'];

  @override
  void initState() {
    super.initState();
    _cargarRoles();
  }

  @override
  void dispose() {
    _numeroDocumentoController.dispose();
    _primerNombreController.dispose();
    _segundoNombreController.dispose();
    _primerApellidoController.dispose();
    _segundoApellidoController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _cargarRoles() async {
    try {
      final roles = await RegistroService.obtenerRoles();
      setState(() {
        _roles = roles;
      });
    } catch (e) {
      debugPrint('Error al cargar roles: $e');
      if (mounted) {
        _mostrarMensaje('Error al cargar roles', isError: true);
      }
    }
  }

  void _togglePassword() {
    setState(() => _showPassword = !_showPassword);
  }

  void _limpiarFormulario() {
    _numeroDocumentoController.clear();
    _primerNombreController.clear();
    _segundoNombreController.clear();
    _primerApellidoController.clear();
    _segundoApellidoController.clear();
    _telefonoController.clear();
    _correoController.clear();
    _passwordController.clear();
    setState(() {
      _tipoDocumento = null;
      _rolSeleccionado = null;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_tipoDocumento == null) {
      _mostrarMensaje('Seleccione un tipo de documento', isError: true);
      return;
    }

    if (_rolSeleccionado == null) {
      _mostrarMensaje('Seleccione un rol', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final datosPersona = {
        'NumeroDocumento': int.parse(_numeroDocumentoController.text),
        'TipoDocumento': _tipoDocumento,
        'Primer_Nombre': _primerNombreController.text.trim(),
        'Segundo_Nombre': _segundoNombreController.text.trim(),
        'Primer_Apellido': _primerApellidoController.text.trim(),
        'Segundo_Apellido': _segundoApellidoController.text.trim(),
        'Telefono': _telefonoController.text.trim(),
        'Correo': _correoController.text.trim(),
        'Password': _passwordController.text,
        'Rol_FK': _rolSeleccionado,
      };

      await RegistroService.registrarPersona(datosPersona);

      if (mounted) {
        _mostrarDialogoExito();
        _limpiarFormulario();
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        _mostrarDialogoError(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _mostrarMensaje(String mensaje, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _mostrarDialogoExito() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 30),
            SizedBox(width: 10),
            Text('¡Registro exitoso!'),
          ],
        ),
        content: const Text('El usuario fue registrado correctamente'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoError(String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 30),
            SizedBox(width: 10),
            Text('Error'),
          ],
        ),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Intentar de nuevo'),
          ),
        ],
      ),
    );
  }

  HeaderWidget headerWidget = HeaderWidget();
  FooterWidget footerWidget = FooterWidget();

  @override
  Widget build(BuildContext context) {
    const Color rosaBoton = Color(0xFFE6C7F6);
    const Color colorTextoBoton = Color(0xFF4A4A4A);

    const InputDecoration fieldDecoration = InputDecoration(
      hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: Colors.grey, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: Colors.grey, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: Color(0xFFE91E63), width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.all(16),
    );

    const TextStyle labelStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 15,
      color: Color(0xFF4A4A4A),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFE6C7F6),
      body: SingleChildScrollView(
        child: Column(
          children: [
            headerWidget,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "¡Vibra Positiva Pijamas!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4A4A4A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Regístra a una Persona para que forme parte de nuestro equipo.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                      const SizedBox(height: 35),

                      // Número Documento
                      const Text("Número Documento", style: labelStyle),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _numeroDocumentoController,
                        keyboardType: TextInputType.number,
                        enabled: !_isLoading,
                        decoration: fieldDecoration.copyWith(
                          hintText: "Escriba su número de documento",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Campo requerido';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Debe ser un número válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 25),

                      // Tipo Documento
                      const Text("Tipo Documento", style: labelStyle),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        decoration: fieldDecoration.copyWith(
                          hintText: "Seleccione su tipo de documento",
                        ),
                        initialValue: _tipoDocumento,
                        items: _tiposDocumento
                            .map((value) => DropdownMenuItem(
                                value: value, child: Text(value)))
                            .toList(),
                        onChanged: _isLoading ? null : (newValue) =>
                            setState(() => _tipoDocumento = newValue),
                        validator: (value) =>
                            value == null ? 'Seleccione un tipo de documento' : null,
                      ),
                      const SizedBox(height: 25),

                      // Primer Nombre
                      const Text("Primer Nombre", style: labelStyle),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _primerNombreController,
                        enabled: !_isLoading,
                        decoration: fieldDecoration.copyWith(
                          hintText: "Escriba su nombre",
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 25),

                      // Segundo Nombre
                      const Text("Segundo Nombre", style: labelStyle),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _segundoNombreController,
                        enabled: !_isLoading,
                        decoration: fieldDecoration.copyWith(
                          hintText: "Escriba su segundo nombre (opcional)",
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Primer Apellido
                      const Text("Primer Apellido", style: labelStyle),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _primerApellidoController,
                        enabled: !_isLoading,
                        decoration: fieldDecoration.copyWith(
                          hintText: "Escriba su primer apellido",
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 25),

                      // Segundo Apellido
                      const Text("Segundo Apellido", style: labelStyle),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _segundoApellidoController,
                        enabled: !_isLoading,
                        decoration: fieldDecoration.copyWith(
                          hintText: "Escriba su segundo apellido (opcional)",
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Teléfono
                      const Text("Número de Teléfono", style: labelStyle),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _telefonoController,
                        keyboardType: TextInputType.phone,
                        enabled: !_isLoading,
                        decoration: fieldDecoration.copyWith(
                          hintText: "Ej: 3123456789",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Campo requerido';
                          }
                          if (value.length != 10) {
                            return 'Debe tener 10 dígitos';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 25),

                      // Correo
                      const Text("Correo electrónico", style: labelStyle),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _correoController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isLoading,
                        decoration: fieldDecoration.copyWith(
                          hintText: "sucorreo@ejemplo.com",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Campo requerido';
                          }
                          if (!value.contains('@')) {
                            return 'Correo inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 25),

                      // Contraseña
                      const Text("Contraseña", style: labelStyle),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        enabled: !_isLoading,
                        decoration: fieldDecoration.copyWith(
                          hintText: "Ingrese su contraseña",
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: _isLoading ? null : _togglePassword,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Campo requerido';
                          }
                          if (value.length < 6) {
                            return 'Mínimo 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 25),

                      // Rol
                      const Text("Rol", style: labelStyle),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        decoration: fieldDecoration.copyWith(
                          hintText: "Seleccione un rol",
                        ),
                        initialValue: _rolSeleccionado,
                        items: _roles
                            .map((rol) => DropdownMenuItem(
                                value: rol.idRol,
                                child: Text(rol.nombreRol)))
                            .toList(),
                        onChanged: _isLoading ? null : (newValue) =>
                            setState(() => _rolSeleccionado = newValue),
                        validator: (value) =>
                            value == null ? 'Seleccione un rol' : null,
                      ),
                      const SizedBox(height: 45),

                      // Botón de registro
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: rosaBoton,
                          foregroundColor: colorTextoBoton,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorTextoBoton,
                                  ),
                                ),
                              )
                            : const Text("REGISTRARSE"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            footerWidget,
          ],
        ),
      ),
    );
  }
}