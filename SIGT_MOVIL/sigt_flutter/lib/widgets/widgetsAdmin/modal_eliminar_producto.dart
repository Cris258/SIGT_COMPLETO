import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/app_config.dart';
import '../../models/producto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModalEliminarProducto extends StatefulWidget {
  final Producto producto;
  final VoidCallback onClose;
  final Function(Producto) onConfirmar;

  const ModalEliminarProducto({
    super.key,
    required this.producto,
    required this.onClose,
    required this.onConfirmar,
  });

  @override
  State<ModalEliminarProducto> createState() => _ModalEliminarProductoState();
}

class _ModalEliminarProductoState extends State<ModalEliminarProducto> {
  bool _loading = false;

  // Mapa de colores
  final Map<String, Color> colorMap = {
    "rojo": Colors.red,
    "azul": Colors.blue,
    "verde": Colors.green,
    "amarillo": Colors.yellow,
    "negro": Colors.black,
    "blanco": Colors.white,
    "gris": Colors.grey,
    "rosa": const Color(0xFFFFC0CB),
    "morado": const Color(0xFF800080),
    "naranja": const Color(0xFFFFA500),
    "cafe": const Color(0xFF8B4513),
    "café": const Color(0xFF8B4513),
    "beige": const Color(0xFFF5F5DC),
    "celeste": const Color(0xFF87CEEB),
    "turquesa": const Color(0xFF40E0D0),
    "violeta": const Color(0xFFEE82EE),
    "fucsia": const Color(0xFFFF00FF),
    "marino": const Color(0xFF000080),
    "vino": const Color(0xFF722F37),
    "crema": const Color(0xFFFFFDD0),
  };

  Color getColorCode(String? colorName) {
    if (colorName == null) return Colors.grey;
    final key = colorName.toLowerCase().trim();
    return colorMap[key] ?? Colors.grey;
  }

  String formatearPrecio(double precio) {
    final f = NumberFormat.currency(
      locale: "es_CO",
      symbol: "\$",
      decimalDigits: 0,
    );
    return f.format(precio);
  }

  Future<void> _handleEliminar() async {
    setState(() {
      _loading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      print(' Eliminando producto: ${widget.producto.idProducto}');

      final response = await http.delete(
        Uri.parse(AppConfig.byId('producto', widget.producto.idProducto!)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        if (mounted) {
          _mostrarExito();
        }
      } else {
        final data = json.decode(response.body);
        final errorMessage = data['message'] ?? 
                            data['Message'] ?? 
                            'Error al eliminar el producto';
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
            Text('¡Eliminado!'),
          ],
        ),
        content: const Text('Producto eliminado correctamente ✅'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar solo el diálogo de éxito
              widget.onClose(); // Cerrar el modal de confirmación
              widget.onConfirmar(widget.producto); // Actualizar la lista
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
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "Confirmar Eliminación",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Advertencia
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Esta acción no se puede deshacer.",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Text(
              "¿Está seguro que desea eliminar el producto ${widget.producto.nombreProducto}?",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // CARD INFORMACIÓN
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Información del producto:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),

                  Text("ID: ${widget.producto.idProducto}"),
                  Text("Nombre: ${widget.producto.nombreProducto}"),

                  Row(
                    children: [
                      const Text("Color: "),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: getColorCode(widget.producto.color),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(widget.producto.color),
                    ],
                  ),

                  Text("Talla: ${widget.producto.talla}"),

                  Text(
                    "Stock: ${widget.producto.stock}",
                    style: TextStyle(
                      color: widget.producto.stock > 10
                          ? Colors.green
                          : widget.producto.stock > 5
                              ? Colors.orange
                              : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text("Precio: ${formatearPrecio(widget.producto.precio)}"),
                ],
              ),
            ),

            if (widget.producto.stock > 0)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Este producto tiene stock disponible. Al eliminarlo, se perderá el inventario registrado.",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : widget.onClose,
          child: const Text("Cancelar"),
        ),
        ElevatedButton.icon(
          onPressed: _loading ? null : _handleEliminar,
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.delete),
          label: Text(_loading ? "Eliminando..." : "Eliminar"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}