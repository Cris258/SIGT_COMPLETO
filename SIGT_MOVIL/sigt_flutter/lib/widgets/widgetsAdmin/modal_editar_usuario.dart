import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/app_config.dart';
import '../../models/persona.dart';
import '../../models/rol.dart';

class ModalEditarUsuario extends StatefulWidget {
  final Persona persona;
  final Function(Persona) onGuardar;

  const ModalEditarUsuario({
    super.key,
    required this.persona,
    required this.onGuardar,
  });

  @override
  State<ModalEditarUsuario> createState() => _ModalEditarUsuarioState();
}

class _ModalEditarUsuarioState extends State<ModalEditarUsuario> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _numeroDocumentoController;
  late TextEditingController _primerNombreController;
  late TextEditingController _segundoNombreController;
  late TextEditingController _primerApellidoController;
  late TextEditingController _segundoApellidoController;
  late TextEditingController _telefonoController;
  late TextEditingController _correoController;

  bool _isLoading = false;
  bool _rolesLoaded = false; //  Nueva bandera
  String? _tipoDocumento;
  int? _rolSeleccionado;
  int? _estadoSeleccionado;
  List<Rol> _roles = [];

  final List<String> _tiposDocumento = ['CC', 'TI', 'CE', 'Pasaporte'];

  @override
  void initState() {
    super.initState();
    
    _numeroDocumentoController = TextEditingController(
      text: widget.persona.numeroDocumento.toString(),
    );
    _primerNombreController = TextEditingController(
      text: widget.persona.primerNombre,
    );
    _segundoNombreController = TextEditingController(
      text: widget.persona.segundoNombre ?? '',
    );
    _primerApellidoController = TextEditingController(
      text: widget.persona.primerApellido,
    );
    _segundoApellidoController = TextEditingController(
      text: widget.persona.segundoApellido ?? '',
    );
    _telefonoController = TextEditingController(
      text: widget.persona.telefono,
    );
    _correoController = TextEditingController(
      text: widget.persona.correo,
    );

    _tipoDocumento = widget.persona.tipoDocumento;
    _rolSeleccionado = widget.persona.rolFk;
    _estadoSeleccionado = widget.persona.estadoPersonaFk;

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
    super.dispose();
  }

  Future<void> _cargarRoles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final url = Uri.parse(AppConfig.endpoint('rol'));
      final response = await http.get(
        url,
        headers: {
          ...AppConfig.headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rolesData = data['body'] as List;
        
        final roles = rolesData
            .map((rol) => Rol.fromJson(rol))
            .where((rol) => rol.nombreRol != 'SuperAdmin')
            .toList();
        
        setState(() {
          _roles = roles;
          _rolesLoaded = true; //  Marcar como cargado
        });
      }
    } catch (e) {
      debugPrint('Error al cargar roles: $e');
      setState(() {
        _rolesLoaded = true; //  Marcar como cargado aunque haya error
      });
    }
  }

  Future<void> _handleGuardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_tipoDocumento == null || _rolSeleccionado == null || _estadoSeleccionado == null) {
      _mostrarMensaje('Complete todos los campos requeridos', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final datosActualizados = {
        'NumeroDocumento': int.parse(_numeroDocumentoController.text),
        'TipoDocumento': _tipoDocumento,
        'Primer_Nombre': _primerNombreController.text.trim(),
        'Primer_Apellido': _primerApellidoController.text.trim(),
        'Telefono': _telefonoController.text.trim(),
        'Correo': _correoController.text.trim(),
        'Rol_FK': _rolSeleccionado,
        'EstadoPersona_FK': _estadoSeleccionado,
      };

      if (_segundoNombreController.text.trim().isNotEmpty) {
        datosActualizados['Segundo_Nombre'] = _segundoNombreController.text.trim();
      }
      if (_segundoApellidoController.text.trim().isNotEmpty) {
        datosActualizados['Segundo_Apellido'] = _segundoApellidoController.text.trim();
      }

      final url = Uri.parse(AppConfig.endpoint('persona/${widget.persona.idPersona}'));
      debugPrint(' [EDITAR] PUT: $url');
      debugPrint(' [EDITAR] Datos: $datosActualizados');

      final response = await http.put(
        url,
        headers: {
          ...AppConfig.headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(datosActualizados),
      );

      debugPrint(' [EDITAR] Status: ${response.statusCode}');
      debugPrint(' [EDITAR] Body: ${response.body}');

      if (response.statusCode == 200) {
        if (mounted) {
          _mostrarMensaje('Usuario actualizado correctamente', isError: false);
          widget.onGuardar(widget.persona);
          Navigator.of(context).pop();
        }
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['Message'] ?? errorData['message'] ?? 'Error al actualizar';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        _mostrarMensaje(errorMessage, isError: true);
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const InputDecoration fieldDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      filled: true,
      fillColor: Colors.white,
    );

    // ✅ Mostrar loading mientras cargan los roles
    if (!_rolesLoaded) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          height: 300,
          padding: const EdgeInsets.all(24),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Cargando datos...'),
              ],
            ),
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Editar Usuario',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),

              // Contenido scrollable
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Número Documento
                      const Text('Número Documento', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _numeroDocumentoController,
                        keyboardType: TextInputType.number,
                        enabled: !_isLoading,
                        decoration: fieldDecoration,
                        validator: (value) =>
                            value!.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 16),

                      // Tipo Documento
                      const Text('Tipo Documento', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: fieldDecoration,
                        value: _tipoDocumento,
                        items: _tiposDocumento
                            .map((value) => DropdownMenuItem(
                                value: value, child: Text(value)))
                            .toList(),
                        onChanged: _isLoading ? null : (newValue) =>
                            setState(() => _tipoDocumento = newValue),
                      ),
                      const SizedBox(height: 16),

                      // Primer Nombre
                      const Text('Primer Nombre', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _primerNombreController,
                        enabled: !_isLoading,
                        decoration: fieldDecoration,
                        validator: (value) =>
                            value!.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 16),

                      // Segundo Nombre
                      const Text('Segundo Nombre (opcional)', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _segundoNombreController,
                        enabled: !_isLoading,
                        decoration: fieldDecoration,
                      ),
                      const SizedBox(height: 16),

                      // Primer Apellido
                      const Text('Primer Apellido', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _primerApellidoController,
                        enabled: !_isLoading,
                        decoration: fieldDecoration,
                        validator: (value) =>
                            value!.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 16),

                      // Segundo Apellido
                      const Text('Segundo Apellido (opcional)', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _segundoApellidoController,
                        enabled: !_isLoading,
                        decoration: fieldDecoration,
                      ),
                      const SizedBox(height: 16),

                      // Teléfono
                      const Text('Teléfono', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _telefonoController,
                        keyboardType: TextInputType.phone,
                        enabled: !_isLoading,
                        decoration: fieldDecoration,
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
                      const SizedBox(height: 16),

                      // Correo
                      const Text('Correo', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _correoController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isLoading,
                        decoration: fieldDecoration,
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
                      const SizedBox(height: 16),

                      // Rol - ✅ CORREGIDO
                      const Text('Rol', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        decoration: fieldDecoration,
                        value: _roles.any((r) => r.idRol == _rolSeleccionado) 
                            ? _rolSeleccionado 
                            : null, // ✅ Solo asignar si existe en la lista
                        items: _roles
                            .map((rol) => DropdownMenuItem(
                                value: rol.idRol,
                                child: Text(rol.nombreRol)))
                            .toList(),
                        onChanged: _isLoading ? null : (newValue) =>
                            setState(() => _rolSeleccionado = newValue),
                        validator: (value) => value == null ? 'Seleccione un rol' : null,
                      ),
                      const SizedBox(height: 16),

                      // Estado
                      const Text('Estado', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        decoration: fieldDecoration,
                        value: _estadoSeleccionado,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Activo')),
                          DropdownMenuItem(value: 2, child: Text('Inactivo')),
                        ],
                        onChanged: _isLoading ? null : (newValue) =>
                            setState(() => _estadoSeleccionado = newValue),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleGuardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Guardar cambios'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}