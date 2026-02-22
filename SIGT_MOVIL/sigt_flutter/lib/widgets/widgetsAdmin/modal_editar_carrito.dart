import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../../models/carrito.dart';

class ModalEditarCarrito extends StatefulWidget {
  final Carrito carrito;
  final Function(Carrito) onGuardar;

  const ModalEditarCarrito({
    super.key,
    required this.carrito,
    required this.onGuardar,
  });

  @override
  State<ModalEditarCarrito> createState() => _ModalEditarCarritoState();
}

class _ModalEditarCarritoState extends State<ModalEditarCarrito> {
  final _formKey = GlobalKey<FormState>();
  late String estadoSeleccionado;
  bool guardando = false;

  //  AGREGADO "Completado" a la lista de estados
  final List<String> estados = ['Pendiente', 'Cancelado', 'Completado'];

  @override
  void initState() {
    super.initState();
    estadoSeleccionado = widget.carrito.estado;
    
    //  VALIDACIÓN: Si el estado no existe en la lista, usar "Pendiente" por defecto
    if (!estados.contains(estadoSeleccionado)) {
      print(' Estado no válido: $estadoSeleccionado, usando "Pendiente"');
      estadoSeleccionado = 'Pendiente';
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

      final carritoActualizado = Carrito(
        idCarrito: widget.carrito.idCarrito,
        fechaCreacion: widget.carrito.fechaCreacion,
        estado: estadoSeleccionado,
        personaFk: widget.carrito.personaFk,
      );

      final url = AppConfig.byId('carrito', widget.carrito.idCarrito);
      
      final bodyData = {
        'FechaCreacion': widget.carrito.fechaCreacion.toIso8601String(),
        'Estado': estadoSeleccionado,
        'Persona_FK': widget.carrito.personaFk,
      };
      final body = json.encode(bodyData);

      print('=== DEBUG EDITAR CARRITO ===');
      print('URL: $url');
      print('Body: $body');
      print('Estado anterior: ${widget.carrito.estado}');
      print('Estado nuevo: $estadoSeleccionado');

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
      print('===========================');

      if (response.statusCode == 200 || response.statusCode == 204) {
        widget.onGuardar(carritoActualizado);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Carrito actualizado correctamente'),
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Editar Carrito',
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

              Text(
                'ID Carrito: ${widget.carrito.idCarrito}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Fecha: ${_formatearFecha(widget.carrito.fechaCreacion)}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),

              const Text(
                'Estado del Carrito',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: estadoSeleccionado,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                items: estados.map((String estado) {
                  return DropdownMenuItem<String>(
                    value: estado,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getEstadoColor(estado),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(estado),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => estadoSeleccionado = newValue);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Seleccione un estado';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

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
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'Completado':
        return const Color(0xFF4CAF50);
      case 'Cancelado':
        return Colors.red;
      case 'Pendiente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }
}