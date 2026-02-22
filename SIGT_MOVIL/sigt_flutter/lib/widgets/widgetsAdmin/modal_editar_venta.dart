import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../config/app_config.dart';
import '../../models/venta.dart';

class ModalEditarVenta extends StatefulWidget {
  final Venta venta;
  final Function(Venta) onGuardar;

  const ModalEditarVenta({
    super.key,
    required this.venta,
    required this.onGuardar,
  });

  @override
  State<ModalEditarVenta> createState() => _ModalEditarVentaState();
}

class _ModalEditarVentaState extends State<ModalEditarVenta> {
  final _formKey = GlobalKey<FormState>();
  late DateTime fechaSeleccionada;
  late TextEditingController totalController;
  late TextEditingController direccionController;
  late TextEditingController ciudadController;
  late TextEditingController departamentoController;
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    fechaSeleccionada = widget.venta.fecha;
    totalController = TextEditingController(
      text: widget.venta.total.toStringAsFixed(0),
    );
    direccionController = TextEditingController(
      text: widget.venta.direccionEntrega,
    );
    ciudadController = TextEditingController(text: widget.venta.ciudad);
    departamentoController = TextEditingController(
      text: widget.venta.departamento,
    );
  }

  @override
  void dispose() {
    totalController.dispose();
    direccionController.dispose();
    ciudadController.dispose();
    departamentoController.dispose();
    super.dispose();
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleaned = value.trim().replaceAll(',', '.');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  Future<void> seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'CO'),
    );

    if (picked != null) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(fechaSeleccionada),
      );

      if (timePicked != null) {
        setState(() {
          fechaSeleccionada = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
        });
      }
    }
  }

  Future<void> guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => guardando = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      if (token.isEmpty) {
        _mostrarError('No hay token de autenticación');
        setState(() => guardando = false);
        return;
      }

      final totalNuevo = _parseDouble(totalController.text);

      final ventaActualizada = Venta(
        idVenta: widget.venta.idVenta,
        fecha: fechaSeleccionada,
        total: totalNuevo,
        direccionEntrega: direccionController.text.trim(),
        ciudad: ciudadController.text.trim(),
        departamento: departamentoController.text.trim(),
        personaFk: widget.venta.personaFk,
      );

      final url = AppConfig.byId('venta', widget.venta.idVenta);

      final bodyData = {
        'Fecha': fechaSeleccionada.toIso8601String(),
        'Total': totalNuevo,
        'DireccionEntrega': direccionController.text.trim(),
        'Ciudad': ciudadController.text.trim(),
        'Departamento': departamentoController.text.trim(),
        'Persona_FK': widget.venta.personaFk,
      };
      final body = json.encode(bodyData);

      print('=== DEBUG EDITAR VENTA ===');
      print('URL: $url');
      print('Body: $body');
      print('==========================');

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        widget.onGuardar(ventaActualizada);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Venta actualizada correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        _mostrarError('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error al guardar: $e');
      _mostrarError('Error de conexión: $e');
    } finally {
      if (mounted) {
        setState(() => guardando = false);
      }
    }
  }

  void _mostrarError(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  String _formatearFecha(DateTime fecha) {
    return DateFormat('MMM dd, yyyy - HH:mm', 'es_CO').format(fecha);
  }

  String _formatearPrecio(num precio) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(precio);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Editar Venta',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // ID Venta (solo lectura)
                Text(
                  'ID Venta: ${widget.venta.idVenta}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),

                // Fecha
                const Text(
                  'Fecha de la Venta',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: seleccionarFecha,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[100],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatearFecha(fechaSeleccionada),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Icon(Icons.calendar_today, color: Colors.blue),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Total
                const Text(
                  'Total de la Venta',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: totalController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    prefixText: '\$ ',
                    hintText: 'Ingrese el total',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese el total';
                    }
                    final numero = _parseDouble(value);
                    if (numero <= 0) {
                      return 'El total debe ser mayor a 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Dirección
                TextFormField(
                  controller: direccionController,
                  decoration: InputDecoration(
                    labelText: 'Dirección de entrega',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese la dirección';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Ciudad
                TextFormField(
                  controller: ciudadController,
                  decoration: InputDecoration(
                    labelText: 'Ciudad',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese la ciudad';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Departamento
                TextFormField(
                  controller: departamentoController,
                  decoration: InputDecoration(
                    labelText: 'Departamento',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese el departamento';
                    }
                    return null;
                  },
                ),

                // Vista previa del total formateado
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total formateado:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        _formatearPrecio(_parseDouble(totalController.text)),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Nota informativa
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Nota: Los detalles de la venta no se modifican con esta edición.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: guardando
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: guardando ? null : guardarCambios,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: guardando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Guardar Cambios'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
