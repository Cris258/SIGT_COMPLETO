import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/app_config.dart';
import '../../models/movimiento.dart';

class ModalEditarMovimiento extends StatefulWidget {
  final Movimiento movimiento;
  final Function(Movimiento) onGuardar;

  const ModalEditarMovimiento({
    super.key,
    required this.movimiento,
    required this.onGuardar,
  });

  @override
  State<ModalEditarMovimiento> createState() => _ModalEditarMovimientoState();
}

class _ModalEditarMovimientoState extends State<ModalEditarMovimiento> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late String _tipo;
  late int _cantidad;
  late DateTime _fecha;
  late String _motivo;
  late int _personaFk;
  late int _productoFk;

  @override
  void initState() {
    super.initState();
    _tipo = widget.movimiento.tipo;
    _cantidad = widget.movimiento.cantidad;
    _fecha = widget.movimiento.fecha;
    _motivo = widget.movimiento.motivo ?? '';
    _personaFk = widget.movimiento.personaFk;
    _productoFk = widget.movimiento.productoFk;
  }

  Future<void> _actualizarMovimiento() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final movimientoActualizado = Movimiento(
        idMovimiento: widget.movimiento.idMovimiento,
        tipo: _tipo,
        cantidad: _cantidad,
        fecha: _fecha,
        motivo: _motivo,
        personaFk: _personaFk,
        productoFk: _productoFk,
      );

      final url = Uri.parse(
        AppConfig.byId('movimiento', widget.movimiento.idMovimiento),
      );

      final response = await http.put(
        url,
        headers: {
          ...AppConfig.headers,
          'Authorization': 'Bearer $token',
        },
        body: json.encode(movimientoActualizado.toJson()),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          widget.onGuardar(movimientoActualizado);
          Navigator.of(context).pop();
          _mostrarMensaje('Movimiento actualizado correctamente', isError: false);
        }
      } else {
        throw Exception('Error al actualizar: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        _mostrarMensaje('Error: ${e.toString()}', isError: true);
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
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _seleccionarFecha() async {
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF667eea),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fechaSeleccionada != null) {
      setState(() {
        _fecha = fechaSeleccionada;
      });
    }
  }

  Color _getTipoColor(String tipo) {
    switch (tipo) {
      case 'Entrada':
        return Colors.green;
      case 'Salida':
        return Colors.orange;
      case 'Ajuste':
        return Colors.blue;
      case 'Devolucion':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getTipoColor(_tipo).withOpacity(0.8),
                    _getTipoColor(_tipo),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Editar Movimiento',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Actualiza la información del movimiento',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),

            // BODY
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tipo
                      DropdownButtonFormField<String>(
                        value: _tipo,
                        decoration: InputDecoration(
                          labelText: 'Tipo de Movimiento',
                          prefixIcon: Icon(Icons.category_rounded, color: _getTipoColor(_tipo)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _getTipoColor(_tipo), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Entrada',
                            child: Row(
                              children: [
                                Icon(Icons.arrow_downward, color: Colors.green, size: 20),
                                SizedBox(width: 8),
                                Text('Entrada'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Salida',
                            child: Row(
                              children: [
                                Icon(Icons.arrow_upward, color: Colors.orange, size: 20),
                                SizedBox(width: 8),
                                Text('Salida'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Ajuste',
                            child: Row(
                              children: [
                                Icon(Icons.tune, color: Colors.blue, size: 20),
                                SizedBox(width: 8),
                                Text('Ajuste'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Devolucion',
                            child: Row(
                              children: [
                                Icon(Icons.keyboard_return, color: Colors.purple, size: 20),
                                SizedBox(width: 8),
                                Text('Devolución'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _tipo = value;
                            });
                          }
                        },
                        validator: (value) =>
                            value == null ? 'Seleccione un tipo' : null,
                      ),

                      const SizedBox(height: 20),

                      // Cantidad
                      TextFormField(
                        initialValue: _cantidad.toString(),
                        decoration: InputDecoration(
                          labelText: 'Cantidad',
                          prefixIcon: const Icon(Icons.numbers_rounded, color: Color(0xFF667eea)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese la cantidad';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Ingrese un número válido';
                          }
                          return null;
                        },
                        onSaved: (value) => _cantidad = int.parse(value!),
                      ),

                      const SizedBox(height: 20),

                      // Fecha
                      InkWell(
                        onTap: _seleccionarFecha,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Fecha',
                            prefixIcon: const Icon(Icons.calendar_today_rounded, color: Color(0xFF667eea)),
                            suffixIcon: const Icon(Icons.edit_calendar, color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          child: Text(
                            '${_fecha.day}/${_fecha.month}/${_fecha.year}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Producto FK
                      TextFormField(
                        initialValue: _productoFk.toString(),
                        decoration: InputDecoration(
                          labelText: 'ID Producto',
                          prefixIcon: const Icon(Icons.inventory_2_rounded, color: Color(0xFF667eea)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese el ID del producto';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Ingrese un número válido';
                          }
                          return null;
                        },
                        onSaved: (value) => _productoFk = int.parse(value!),
                      ),

                      const SizedBox(height: 20),

                      // Persona FK
                      TextFormField(
                        initialValue: _personaFk.toString(),
                        decoration: InputDecoration(
                          labelText: 'ID Persona Responsable',
                          prefixIcon: const Icon(Icons.person_rounded, color: Color(0xFF667eea)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese el ID de la persona';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Ingrese un número válido';
                          }
                          return null;
                        },
                        onSaved: (value) => _personaFk = int.parse(value!),
                      ),

                      const SizedBox(height: 20),

                      // Motivo
                      TextFormField(
                        initialValue: _motivo,
                        decoration: InputDecoration(
                          labelText: 'Motivo (Opcional)',
                          prefixIcon: const Icon(Icons.description_rounded, color: Color(0xFF667eea)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        onSaved: (value) => _motivo = value ?? '',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // FOOTER
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _actualizarMovimiento,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check_circle_rounded),
                    label: Text(
                      _isLoading ? 'Guardando...' : 'Guardar Cambios',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getTipoColor(_tipo),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}