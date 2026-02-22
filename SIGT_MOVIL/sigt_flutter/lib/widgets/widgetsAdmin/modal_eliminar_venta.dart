import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../config/app_config.dart';
import '../../models/venta.dart';

class ModalEliminarVenta extends StatefulWidget {
  final Venta venta;
  final String? nombreCliente;
  final Function(Venta) onConfirmar;

  const ModalEliminarVenta({
    super.key,
    required this.venta,
    this.nombreCliente,
    required this.onConfirmar,
  });

  @override
  State<ModalEliminarVenta> createState() => _ModalEliminarVentaState();
}

class _ModalEliminarVentaState extends State<ModalEliminarVenta> {
  bool eliminando = false;

  Future<void> confirmarEliminacion() async {
    setState(() => eliminando = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      if (token.isEmpty) {
        _mostrarError('No hay token de autenticación');
        setState(() => eliminando = false);
        return;
      }

      final response = await http.delete(
        Uri.parse(AppConfig.byId('venta', widget.venta.idVenta)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('=== DEBUG ELIMINAR VENTA ===');
      print('Status Code: ${response.statusCode}');
      print('Response: ${response.body}');
      print('===========================');

      if (response.statusCode == 200 || response.statusCode == 204) {
        widget.onConfirmar(widget.venta);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Venta eliminada correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        _mostrarError('Error al eliminar la venta: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      _mostrarError('Error de conexión: $e');
    } finally {
      if (mounted) {
        setState(() => eliminando = false);
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono de advertencia
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_rounded,
                size: 50,
                color: Colors.red[600],
              ),
            ),

            const SizedBox(height: 24),

            // Título
            const Text(
              '¿Eliminar Venta?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Mensaje
            Text(
              '¿Estás seguro que deseas eliminar la venta #${widget.venta.idVenta}?',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            const Text(
              'Esta acción no se puede deshacer y eliminará también todos los detalles asociados.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Información de la venta
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    'ID Venta:',
                    widget.venta.idVenta.toString(),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Fecha:',
                    _formatearFecha(widget.venta.fecha),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Total:',
                    _formatearPrecio(widget.venta.total),
                    colorValor: Colors.green[700],
                    boldValor: true,
                  ),
                  if (widget.nombreCliente != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Cliente:',
                      widget.nombreCliente!,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Botones
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: eliminando
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: eliminando ? null : confirmarEliminacion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: eliminando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Eliminar',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String valor, {
    Color? colorValor,
    bool boldValor = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Flexible(
          child: Text(
            valor,
            style: TextStyle(
              color: colorValor ?? Colors.black87,
              fontWeight: boldValor ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}