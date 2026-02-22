import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/app_config.dart';
import '../../models/producto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModalEditarProducto extends StatefulWidget {
  final Producto producto;
  final VoidCallback onClose;
  final Function(Producto) onGuardar;

  const ModalEditarProducto({
    super.key,
    required this.producto,
    required this.onClose,
    required this.onGuardar,
  });

  @override
  State<ModalEditarProducto> createState() => _ModalEditarProductoState();
}

class _ModalEditarProductoState extends State<ModalEditarProducto> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nombreCtrl;
  late TextEditingController estampadoCtrl;
  late TextEditingController stockCtrl;
  late TextEditingController precioCtrl;

  String? colorSeleccionado;
  String? tallaSeleccionada;
  bool _loading = false;

  final List<String> colores = [
    "Rojo", "Azul", "Verde", "Amarillo", "Negro", "Blanco",
    "Gris", "Rosa", "Morado", "Naranja", "Café", "Beige",
    "Celeste", "Turquesa", "Violeta", "Fucsia", "Marino", "Vino", "Crema"
  ];

  final List<String> tallas = [
    "2", "4", "6", "8", "10", "12", "14", "16",
    "XS", "S", "M", "L", "XL", "XXL"
  ];

  // Mapa de colores para vista previa
  final Map<String, Color> colorMap = {
    'rojo': const Color(0xFFFF0000),
    'azul': const Color(0xFF0000FF),
    'verde': const Color(0xFF00FF00),
    'amarillo': const Color(0xFFFFFF00),
    'negro': const Color(0xFF000000),
    'blanco': const Color(0xFFFFFFFF),
    'gris': const Color(0xFF808080),
    'rosa': const Color(0xFFFFC0CB),
    'morado': const Color(0xFF800080),
    'naranja': const Color(0xFFFFA500),
    'café': const Color(0xFF8B4513),
    'beige': const Color(0xFFF5F5DC),
    'celeste': const Color(0xFF87CEEB),
    'turquesa': const Color(0xFF40E0D0),
    'violeta': const Color(0xFFEE82EE),
    'fucsia': const Color(0xFFFF00FF),
    'marino': const Color(0xFF000080),
    'vino': const Color(0xFF722F37),
    'crema': const Color(0xFFFFFDD0),
  };

  @override
  void initState() {
    super.initState();

    nombreCtrl = TextEditingController(text: widget.producto.nombreProducto);
    estampadoCtrl = TextEditingController(text: widget.producto.estampado);
    stockCtrl = TextEditingController(text: widget.producto.stock.toString());
    precioCtrl = TextEditingController(text: widget.producto.precio.toString());

    colorSeleccionado = widget.producto.color;
    tallaSeleccionada = widget.producto.talla;
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    estampadoCtrl.dispose();
    stockCtrl.dispose();
    precioCtrl.dispose();
    super.dispose();
  }

  Color getColorCode(String? colorName) {
    if (colorName == null) return Colors.transparent;
    return colorMap[colorName.toLowerCase().trim()] ?? const Color(0xFFCCCCCC);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      // Preparar datos para actualizar (sin idProducto)
      final datosParaActualizar = {
        'NombreProducto': nombreCtrl.text.trim(),
        'Color': colorSeleccionado,
        'Talla': tallaSeleccionada,
        'Estampado': estampadoCtrl.text.trim().isEmpty 
            ? 'Sin estampado' 
            : estampadoCtrl.text.trim(),
        'Stock': int.parse(stockCtrl.text.trim()),
        'Precio': double.parse(precioCtrl.text.trim()),
      };

      print(' Enviando actualización a: ${AppConfig.byId('producto', widget.producto.idProducto)}');
      print(' Datos: $datosParaActualizar');

      final response = await http.put(
        Uri.parse(AppConfig.byId('producto', widget.producto.idProducto!)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(datosParaActualizar),
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Crear producto actualizado
        final productoActualizado = Producto(
          idProducto: widget.producto.idProducto,
          nombreProducto: nombreCtrl.text.trim(),
          color: colorSeleccionado!,
          talla: tallaSeleccionada!,
          estampado: estampadoCtrl.text.trim().isEmpty 
              ? 'Sin estampado' 
              : estampadoCtrl.text.trim(),
          stock: int.parse(stockCtrl.text.trim()),
          precio: double.parse(precioCtrl.text.trim()),
        );

        if (mounted) {
          // Primero llamar onGuardar para actualizar la lista
          widget.onGuardar(productoActualizado);
          // Luego mostrar el mensaje de éxito
          _mostrarExito();
        }
      } else {
        final data = json.decode(response.body);
        final errorMessage = data['message'] ?? 
                            data['Message'] ?? 
                            'Error al actualizar el producto';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print(' Error: $e');
      if (mounted) {
        _mostrarError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _mostrarExito() {
    showDialog(
      context: context,
      barrierDismissible: false, // Evita cerrar tocando fuera
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 30),
            SizedBox(width: 10),
            Text('¡Actualizado!'),
          ],
        ),
        content: const Text('Producto Actualizado Correctamente'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo de éxito
              widget.onClose(); // Cerrar modal de edición
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _mostrarError(String mensaje) {
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
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Editar Producto",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: CircularProgressIndicator(),
                    ),

                  // Nombre producto
                  TextFormField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: "Nombre del Producto *",
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_loading,
                    validator: (value) =>
                        value!.trim().isEmpty ? "El nombre es obligatorio" : null,
                  ),
                  const SizedBox(height: 16),

                  // Color con vista previa
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: colorSeleccionado,
                          decoration: const InputDecoration(
                            labelText: "Color *",
                            border: OutlineInputBorder(),
                          ),
                          items: colores
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: _loading ? null : (v) => setState(() => colorSeleccionado = v),
                          validator: (value) =>
                              value == null ? "Seleccione un color" : null,
                        ),
                      ),
                      if (colorSeleccionado != null) ...[
                        const SizedBox(width: 10),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: getColorCode(colorSeleccionado),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[300]!, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Talla
                  DropdownButtonFormField<String>(
                    initialValue: tallaSeleccionada,
                    decoration: const InputDecoration(
                      labelText: "Talla *",
                      border: OutlineInputBorder(),
                    ),
                    items: tallas
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: _loading ? null : (v) => setState(() => tallaSeleccionada = v),
                    validator: (value) =>
                        value == null ? "Seleccione una talla" : null,
                  ),
                  const SizedBox(height: 16),

                  // Estampado
                  TextFormField(
                    controller: estampadoCtrl,
                    decoration: const InputDecoration(
                      labelText: "Estampado (Opcional)",
                      border: OutlineInputBorder(),
                      hintText: "Ej: Unicornios, Estrellas",
                    ),
                    enabled: !_loading,
                  ),
                  const SizedBox(height: 16),

                  // Stock
                  TextFormField(
                    controller: stockCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Stock *",
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_loading,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Campo requerido";
                      }
                      if (int.tryParse(value) == null || int.parse(value) < 0) {
                        return "Ingrese un número válido";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Precio
                  TextFormField(
                    controller: precioCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Precio *",
                      prefixText: "\$ ",
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_loading,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Campo requerido";
                      }
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return "Ingrese un precio válido";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 25),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _loading ? null : widget.onClose,
                        child: const Text("Cancelar"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _loading ? null : _guardar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text("Guardar Cambios"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}