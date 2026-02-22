import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../../models/persona.dart';

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
  bool _isLoading = false;

  late TextEditingController _numeroDocumentoController;
  late TextEditingController _primerNombreController;
  late TextEditingController _segundoNombreController;
  late TextEditingController _primerApellidoController;
  late TextEditingController _segundoApellidoController;
  late TextEditingController _telefonoController;
  late TextEditingController _correoController;

  late String _tipoDocumento;
  late int _estadoPersona;

  @override
  void initState() {
    super.initState();
    // Inicializar controladores con los valores de la persona
    _numeroDocumentoController = TextEditingController(
      text: widget.persona.numeroDocumento.toString()
    );
    _primerNombreController = TextEditingController(
      text: widget.persona.primerNombre
    );
    _segundoNombreController = TextEditingController(
      text: widget.persona.segundoNombre ?? ''
    );
    _primerApellidoController = TextEditingController(
      text: widget.persona.primerApellido
    );
    _segundoApellidoController = TextEditingController(
      text: widget.persona.segundoApellido ?? ''
    );
    _telefonoController = TextEditingController(
      text: widget.persona.telefono
    );
    _correoController = TextEditingController(
      text: widget.persona.correo
    );
    _tipoDocumento = widget.persona.tipoDocumento;
    _estadoPersona = widget.persona.estadoPersonaFk;
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

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      // Preparar datos para enviar usando toJsonAdminUpdate del modelo
      final personaActualizada = {
        'NumeroDocumento': int.parse(_numeroDocumentoController.text),
        'TipoDocumento': _tipoDocumento,
        'Primer_Nombre': _primerNombreController.text,
        'Primer_Apellido': _primerApellidoController.text,
        'Telefono': _telefonoController.text,
        'Correo': _correoController.text,
        'EstadoPersona_FK': _estadoPersona,
        'Rol_FK': widget.persona.rolFk,
      };

      // Agregar campos opcionales solo si tienen valor
      if (_segundoNombreController.text.isNotEmpty) {
        personaActualizada['Segundo_Nombre'] = _segundoNombreController.text;
      }
      if (_segundoApellidoController.text.isNotEmpty) {
        personaActualizada['Segundo_Apellido'] = _segundoApellidoController.text;
      }

      final response = await http.put(
        Uri.parse(AppConfig.byId('persona', widget.persona.idPersona)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(personaActualizada),
      );

      if (response.statusCode == 200) {
        // Crear persona actualizada localmente para actualizar la UI
        final personaLocal = widget.persona.copyWith(
          numeroDocumento: int.parse(_numeroDocumentoController.text),
          tipoDocumento: _tipoDocumento,
          primerNombre: _primerNombreController.text,
          segundoNombre: _segundoNombreController.text.isEmpty 
              ? null 
              : _segundoNombreController.text,
          primerApellido: _primerApellidoController.text,
          segundoApellido: _segundoApellidoController.text.isEmpty 
              ? null 
              : _segundoApellidoController.text,
          telefono: _telefonoController.text,
          correo: _correoController.text,
          estadoPersonaFk: _estadoPersona,
        );

        widget.onGuardar(personaLocal);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Empleado actualizado exitosamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Error al actualizar: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Editar Empleado',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 32),
              
              // Formulario con scroll
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Tipo de Documento
                      DropdownButtonFormField<String>(
                        initialValue: _tipoDocumento,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Documento',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'CC', child: Text('Cédula de Ciudadanía (CC)')),
                          DropdownMenuItem(value: 'CE', child: Text('Cédula de Extranjería (CE)')),
                          DropdownMenuItem(value: 'PA', child: Text('Pasaporte (PA)')),
                          DropdownMenuItem(value: 'TI', child: Text('Tarjeta de Identidad (TI)')),
                        ],
                        onChanged: _isLoading 
                            ? null 
                            : (value) => setState(() => _tipoDocumento = value!),
                      ),
                      const SizedBox(height: 16),
                      
                      // Número de Documento
                      TextFormField(
                        controller: _numeroDocumentoController,
                        decoration: const InputDecoration(
                          labelText: 'Número de Documento',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !_isLoading,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Este campo es obligatorio';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Debe ser un número válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Primer Nombre
                      TextFormField(
                        controller: _primerNombreController,
                        decoration: const InputDecoration(
                          labelText: 'Primer Nombre',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        enabled: !_isLoading,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Este campo es obligatorio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Segundo Nombre
                      TextFormField(
                        controller: _segundoNombreController,
                        decoration: const InputDecoration(
                          labelText: 'Segundo Nombre (Opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      
                      // Primer Apellido
                      TextFormField(
                        controller: _primerApellidoController,
                        decoration: const InputDecoration(
                          labelText: 'Primer Apellido',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        enabled: !_isLoading,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Este campo es obligatorio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Segundo Apellido
                      TextFormField(
                        controller: _segundoApellidoController,
                        decoration: const InputDecoration(
                          labelText: 'Segundo Apellido (Opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      
                      // Teléfono
                      TextFormField(
                        controller: _telefonoController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        enabled: !_isLoading,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Este campo es obligatorio';
                          }
                          if (value.length < 7) {
                            return 'Debe tener al menos 7 dígitos';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Correo
                      TextFormField(
                        controller: _correoController,
                        decoration: const InputDecoration(
                          labelText: 'Correo Electrónico',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isLoading,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Este campo es obligatorio';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Ingrese un correo válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Estado
                      DropdownButtonFormField<int>(
                        initialValue: _estadoPersona,
                        decoration: const InputDecoration(
                          labelText: 'Estado',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.toggle_on),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 1,
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 20),
                                SizedBox(width: 8),
                                Text('Activo'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 2,
                            child: Row(
                              children: [
                                Icon(Icons.cancel, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text('Inactivo'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: _isLoading 
                            ? null 
                            : (value) => setState(() => _estadoPersona = value!),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _guardarCambios,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isLoading ? 'Guardando...' : 'Guardar Cambios'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
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