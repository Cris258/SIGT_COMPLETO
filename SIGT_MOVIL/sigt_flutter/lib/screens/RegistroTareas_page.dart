import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/header_widget.dart';
import '../widgets/footer_widget.dart';
import '../models/persona.dart';
import '../config/app_config.dart';

class RegistroTareasPage extends StatefulWidget {
  const RegistroTareasPage({super.key});

  @override
  State<RegistroTareasPage> createState() => _RegistroTareasPageState();
}

class _RegistroTareasPageState extends State<RegistroTareasPage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  late TextEditingController _descripcionController;
  late TextEditingController _fechaAsignacionController;
  late TextEditingController _fechaLimiteController;
  late TextEditingController _cantidadController;

  // Estado del formulario
  String _prioridad = '';
  int _personaFk = 0;
  int? _productoFk;
  bool _isLoading = false;
  bool _isLoadingData = true;

  // Listas
  List<Persona> empleados = [];
  List<Map<String, dynamic>> productos = [];

  String? token;

  @override
  void initState() {
    super.initState();
    _descripcionController = TextEditingController();
    _cantidadController = TextEditingController();

    // Establecer fecha de hoy por defecto
    final hoy = DateTime.now();
    _fechaAsignacionController = TextEditingController(
      text: _formatearFechaParaInput(hoy),
    );
    _fechaLimiteController = TextEditingController();

    cargarDatos();
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _fechaAsignacionController.dispose();
    _fechaLimiteController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  String _formatearFechaParaInput(DateTime fecha) {
    return '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
  }

  Future<void> cargarDatos() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('auth_token');

      if (token == null) {
        _mostrarError('No se encontró token de autenticación');
        return;
      }

      await Future.wait([cargarEmpleados(), cargarProductos()]);

      setState(() {
        _isLoadingData = false;
      });
    } catch (e) {
      _mostrarError('Error al cargar datos: $e');
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> cargarEmpleados() async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.endpoint('persona')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> personasJson = data['body'] ?? [];

        setState(() {
          empleados = personasJson
              .map((json) => Persona.fromJson(json))
              .where(
                (persona) => persona.nombreRol?.toLowerCase() == 'empleado',
              )
              .toList();
        });
      }
    } catch (e) {
      print('Error al cargar empleados: $e');
    }
  }

  Future<void> cargarProductos() async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.endpoint('producto')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> productosJson = data['body'] ?? [];

        setState(() {
          productos = productosJson
              .map(
                (p) => {
                  'id': p['idProducto'],
                  'nombre': p['NombreProducto'] ?? '',
                  'color': p['Color'] ?? '',
                  'talla': p['Talla'] ?? '',
                  'estampado': p['Estampado'] ?? '',
                  'stock': p['Stock'] ?? 0,
                  'precio': p['Precio'] ?? 0,
                },
              )
              .toList();
        });

        print(' Productos cargados: ${productos.length}');
      }
    } catch (e) {
      print(' Error al cargar productos: $e');
    }
  }

  void _generarDescripcion() {
    if (_productoFk != null && _cantidadController.text.isNotEmpty) {
      // Buscar el producto seleccionado
      final producto = productos.firstWhere(
        (p) => p['id'] == _productoFk,
        orElse: () => {},
      );

      if (producto.isNotEmpty) {
        final descripcion =
            'Hacer ${_cantidadController.text} pijamas estilo ${producto['nombre']}, '
            'color ${producto['color']}, talla ${producto['talla']}, '
            'estampado ${producto['estampado']}';

        setState(() {
          _descripcionController.text = descripcion;
        });
      }
    }
  }

  String _formatearProducto(Map<String, dynamic> producto) {
    return '${producto['nombre']} - ${producto['color']} - '
        '${producto['talla']} - ${producto['estampado']} '
        '(Stock: ${producto['stock']})';
  }

  Future<void> _guardarTarea() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_productoFk == null) {
      _mostrarError('Debe seleccionar un producto');
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
      final tareaData = {
        'Descripcion': _descripcionController.text,
        'FechaAsignacion': _fechaAsignacionController.text,
        'FechaLimite': _fechaLimiteController.text,
        'EstadoTarea': 'Pendiente',
        'Prioridad': _prioridad,
        'Persona_FK': _personaFk,
        'Producto_FK': _productoFk, //  Ahora se envía directamente
      };

      print(' Creando tarea: $tareaData');

      final response = await http.post(
        Uri.parse(AppConfig.endpoint('tarea')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(tareaData),
      );

      print(' Status: ${response.statusCode}');
      print(' Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        _mostrarExito('Tarea asignada', 'La tarea se asignó exitosamente ✅');
        _limpiarFormulario();
      } else {
        final error = json.decode(response.body);
        _mostrarError(
          error['Message'] ?? error['message'] ?? 'No se pudo asignar la tarea',
        );
      }
    } catch (e) {
      print(' Error completo: $e');
      _mostrarError('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _limpiarFormulario() {
    setState(() {
      _descripcionController.clear();
      _cantidadController.clear();
      final hoy = DateTime.now();
      _fechaAsignacionController.text = _formatearFechaParaInput(hoy);
      _fechaLimiteController.clear();
      _prioridad = '';
      _personaFk = 0;
      _productoFk = null;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6C7F6),
      body: SafeArea(
        child: Column(
          children: [
            HeaderWidget(),
            Expanded(
              child: _isLoadingData
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '¡Vibra Positiva Pijamas!',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF7B2CBF),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Asigna una nueva tarea a un empleado.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 32),

                                    // Producto
                                    const Text(
                                      'Seleccionar Producto',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<int>(
                                      initialValue: _productoFk,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: 'Seleccione un producto',
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                      ),
                                      isExpanded: true,
                                      isDense: false,
                                      menuMaxHeight: 300,
                                      items: [
                                        const DropdownMenuItem(
                                          value: null,
                                          child: Text(
                                            'Seleccione un producto',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        ...productos.map((producto) {
                                          return DropdownMenuItem(
                                            value: producto['id'],
                                            child: Text(
                                              _formatearProducto(producto),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _productoFk = value;
                                          _generarDescripcion();
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null) {
                                          return 'Debe seleccionar un producto';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Cantidad
                                    const Text(
                                      'Cantidad a Producir',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _cantidadController,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: 'Ej: 25',
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        _generarDescripcion();
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'La cantidad es requerida';
                                        }
                                        if (int.tryParse(value) == null) {
                                          return 'Debe ser un número válido';
                                        }
                                        if (int.parse(value) <= 0) {
                                          return 'Debe ser mayor a 0';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Descripción (auto-generada)
                                    const Text(
                                      'Descripción de la Tarea',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _descripcionController,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText:
                                            'Se generará automáticamente...',
                                      ),
                                      maxLines: 3,
                                      readOnly: true,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Seleccione un producto y cantidad';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Fecha Asignación
                                    const Text(
                                      'Fecha de Asignación',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _fechaAsignacionController,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        suffixIcon: Icon(Icons.calendar_today),
                                      ),
                                      readOnly: true,
                                      onTap: () async {
                                        final DateTime? picked =
                                            await showDatePicker(
                                              context: context,
                                              initialDate: DateTime.parse(
                                                _fechaAsignacionController.text,
                                              ),
                                              firstDate: DateTime(2020),
                                              lastDate: DateTime(2030),
                                            );
                                        if (picked != null) {
                                          setState(() {
                                            _fechaAsignacionController.text =
                                                _formatearFechaParaInput(
                                                  picked,
                                                );
                                          });
                                        }
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'La fecha es requerida';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Fecha Límite
                                    const Text(
                                      'Fecha Límite',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _fechaLimiteController,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        suffixIcon: Icon(Icons.calendar_today),
                                      ),
                                      readOnly: true,
                                      onTap: () async {
                                        final DateTime? picked =
                                            await showDatePicker(
                                              context: context,
                                              initialDate: DateTime.parse(
                                                _fechaAsignacionController.text,
                                              ),
                                              firstDate: DateTime.parse(
                                                _fechaAsignacionController.text,
                                              ),
                                              lastDate: DateTime(2030),
                                            );
                                        if (picked != null) {
                                          setState(() {
                                            _fechaLimiteController.text =
                                                _formatearFechaParaInput(
                                                  picked,
                                                );
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
                                    const SizedBox(height: 16),

                                    const Text(
                                      'Prioridad',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      initialValue: _prioridad.isEmpty
                                          ? null
                                          : _prioridad,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                      ),
                                      isExpanded: true,
                                      isDense: false,
                                      menuMaxHeight: 300,
                                      items: const [
                                        DropdownMenuItem(
                                          value: null,
                                          child: Text(
                                            'Seleccione una prioridad',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Alta',
                                          child: Text(
                                            '🔴 Alta',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Media',
                                          child: Text(
                                            '🟡 Media',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Baja',
                                          child: Text(
                                            '🟢 Baja',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Urgente',
                                          child: Text(
                                            '🚨 Urgente',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _prioridad = value ?? '';
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'La prioridad es requerida';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Empleado
                                    const Text(
                                      'Asignar a Empleado',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<int>(
                                      initialValue: _personaFk == 0
                                          ? null
                                          : _personaFk,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                      ),
                                      isExpanded: true,
                                      isDense: false,
                                      menuMaxHeight: 300,
                                      items: [
                                        const DropdownMenuItem(
                                          value: null,
                                          child: Text(
                                            'Seleccione un empleado',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        ...empleados.map((empleado) {
                                          return DropdownMenuItem(
                                            value: empleado.idPersona,
                                            child: Text(
                                              _obtenerNombreCompleto(empleado),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _personaFk = value ?? 0;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value == 0) {
                                          return 'Debe seleccionar un empleado';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 32),

                                    // Botón Asignar
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _guardarTarea,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF7B2CBF,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : const Text(
                                                'Asignar Tarea',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            FooterWidget(),
          ],
        ),
      ),
    );
  }
}
