import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/tarea.dart';
import '../../models/persona.dart';
import '../../config/app_config.dart';

class ModalEditarTarea extends StatefulWidget {
  final Tarea tarea;
  final String token;
  final VoidCallback onGuardar;

  const ModalEditarTarea({
    super.key,
    required this.tarea,
    required this.token,
    required this.onGuardar,
  });

  @override
  State<ModalEditarTarea> createState() => _ModalEditarTareaState();
}

class _ModalEditarTareaState extends State<ModalEditarTarea> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descripcionController;
  late TextEditingController _fechaAsignacionController;
  late TextEditingController _fechaLimiteController;
  late String _prioridad;
  late String _estadoTarea;
  late int _personaFk;
  bool _isLoading = false;
  bool _isLoadingEmpleados = true;
  List<Persona> empleados = [];

  final List<String> _prioridades = ['Alta', 'Media', 'Baja'];
  final List<String> _estados = [
    'Pendiente',
    'En Progreso',
    'Completada',
    'Cancelada',
  ];

  @override
  void initState() {
    super.initState();
    _descripcionController = TextEditingController(
      text: widget.tarea.descripcion ?? '',
    );

    // Formatear fechas como YYYY-MM-DD para el input type="date"
    _fechaAsignacionController = TextEditingController(
      text: _formatearFechaParaInput(widget.tarea.fechaAsignacion),
    );
    _fechaLimiteController = TextEditingController(
      text: _formatearFechaParaInput(widget.tarea.fechaLimite),
    );

    _prioridad = widget.tarea.prioridad;
    _estadoTarea = widget.tarea.estadoTarea;
    _personaFk = widget.tarea.personaFk;

    cargarEmpleados();
  }

  String _formatearFechaParaInput(DateTime fecha) {
    return '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
  }

  Future<void> cargarEmpleados() async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.endpoint('persona')),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> personasJson = data['body'] ?? [];

        setState(() {
          // Filtrar solo empleados
          empleados = personasJson
              .map((json) => Persona.fromJson(json))
              .where(
                (persona) => persona.nombreRol?.toLowerCase() == 'empleado',
              )
              .toList();
          _isLoadingEmpleados = false;
        });
      } else {
        _mostrarError('Error al cargar empleados: ${response.statusCode}');
        setState(() {
          _isLoadingEmpleados = false;
        });
      }
    } catch (e) {
      _mostrarError('Error al cargar empleados: $e');
      setState(() {
        _isLoadingEmpleados = false;
      });
    }
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _fechaAsignacionController.dispose();
    _fechaLimiteController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar que la fecha límite no sea anterior a la fecha de asignación
    final fechaAsignacion = DateTime.parse(_fechaAsignacionController.text);
    final fechaLimite = DateTime.parse(_fechaLimiteController.text);

    if (fechaLimite.isBefore(fechaAsignacion)) {
      _mostrarAdvertencia(
        'Fecha inválida',
        'La fecha límite no puede ser anterior a la fecha de asignación',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tareaActualizada = {
        'Descripcion': _descripcionController.text,
        'FechaAsignacion': _fechaAsignacionController.text,
        'FechaLimite': _fechaLimiteController.text,
        'EstadoTarea': _estadoTarea,
        'Prioridad': _prioridad,
        'Persona_FK': _personaFk,
      };

      final response = await http.put(
        Uri.parse(AppConfig.byId('tarea', widget.tarea.idTarea)),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode(tareaActualizada),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          _mostrarExito(
            'Tarea actualizada',
            'La tarea se actualizó exitosamente ✅',
          );
          Navigator.of(context).pop();
          widget.onGuardar();
        }
      } else {
        final error = json.decode(response.body);
        _mostrarError(error['Message'] ?? 'Error al actualizar');
      }
    } catch (e) {
      _mostrarError('No se pudo conectar con el servidor ❌');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _mostrarError(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _mostrarAdvertencia(String titulo, String mensaje) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 8),
              Text(titulo),
            ],
          ),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    }
  }

  void _mostrarExito(String titulo, String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(mensaje)),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _obtenerNombreCompleto(Persona empleado) {
    final partes = [
      empleado.primerNombre,
      if (empleado.segundoNombre != null && empleado.segundoNombre!.isNotEmpty)
        empleado.segundoNombre,
      empleado.primerApellido,
      if (empleado.segundoApellido != null &&
          empleado.segundoApellido!.isNotEmpty)
        empleado.segundoApellido,
    ];
    return partes.join(' ');
  }

  // REEMPLAZA todo el método build() en modal_editar_tarea.dart (línea ~213)

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header mejorado
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Editar Tarea',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                // Body con campos organizados
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Descripción
                      _buildLabel('Descripción de la Tarea', Icons.description),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descripcionController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: 'Ingrese la descripción de la tarea',
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La descripción es requerida';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Fecha de Asignación
                      _buildLabel('Fecha de Asignación', Icons.calendar_today),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _fechaAsignacionController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: const Icon(Icons.calendar_today),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        readOnly: true,
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.parse(
                              _fechaAsignacionController.text,
                            ),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            locale: const Locale('es', 'ES'),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color(0xFF667eea),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              _fechaAsignacionController.text =
                                  _formatearFechaParaInput(picked);
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La fecha de asignación es requerida';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Fecha Límite
                      _buildLabel('Fecha Límite', Icons.event),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _fechaLimiteController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: const Icon(Icons.event),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        readOnly: true,
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.parse(
                              _fechaLimiteController.text,
                            ),
                            firstDate: DateTime.parse(
                              _fechaAsignacionController.text,
                            ),
                            lastDate: DateTime(2030),
                            locale: const Locale('es', 'ES'),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color(0xFF667eea),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              _fechaLimiteController.text =
                                  _formatearFechaParaInput(picked);
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La fecha límite es requerida';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Prioridad
                      _buildLabel('Prioridad', Icons.flag),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _prioridad,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        isExpanded: true,
                        isDense: false,
                        menuMaxHeight: 300,
                        items: _prioridades.map((prioridad) {
                          String emoji = '';
                          switch (prioridad) {
                            case 'Alta':
                              emoji = '🔴';
                              break;
                            case 'Media':
                              emoji = '🟡';
                              break;
                            case 'Baja':
                              emoji = '🟢';
                              break;
                          }
                          return DropdownMenuItem(
                            value: prioridad,
                            child: Text(
                              '$emoji $prioridad',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _prioridad = value;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Seleccione una prioridad';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Estado
                      _buildLabel('Estado de la Tarea', Icons.assignment),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _estadoTarea,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        isExpanded: true,
                        isDense: false,
                        menuMaxHeight: 300,
                        items: _estados.map((estado) {
                          return DropdownMenuItem(
                            value: estado,
                            child: Text(
                              estado,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _estadoTarea = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Empleado
                      _buildLabel('Asignar a Empleado', Icons.person),
                      const SizedBox(height: 8),
                      _isLoadingEmpleados
                          ? Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : DropdownButtonFormField<int>(
                              value: _personaFk,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              isExpanded: true,
                              isDense: false,
                              menuMaxHeight: 300,
                              items: empleados.map((empleado) {
                                return DropdownMenuItem(
                                  value: empleado.idPersona,
                                  child: Text(
                                    _obtenerNombreCompleto(empleado),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _personaFk = value;
                                  });
                                }
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Debe seleccionar un empleado';
                                }
                                return null;
                              },
                            ),
                    ],
                  ),
                ),

                // Footer mejorado
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: const BorderSide(color: Colors.grey),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _guardarCambios,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF667eea),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Guardar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF667eea)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF4A4A4A),
          ),
        ),
      ],
    );
  }
}
