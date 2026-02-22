import 'package:flutter/material.dart';
import '../../models/movimiento.dart';
import '../../models/persona.dart';
import '../../models/producto.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../widgetsAdmin/modal_editar_movimiento.dart';
import '../widgetsAdmin/modal_eliminar_movimiento.dart';

class ModalDetalleMovimiento extends StatefulWidget {
  final Movimiento movimiento;
  final int numeroSecuencial;

  const ModalDetalleMovimiento({
    super.key,
    required this.movimiento,
    required this.numeroSecuencial,
  });

  @override
  State<ModalDetalleMovimiento> createState() => _ModalDetalleMovimientoState();
}

class _ModalDetalleMovimientoState extends State<ModalDetalleMovimiento> {
  bool _isLoadingDatosAdicionales = true;

  // Datos adicionales
  Persona? _persona;
  Producto? _producto;

  @override
  void initState() {
    super.initState();
    _cargarDatosAdicionales();
  }

  Future<void> _cargarDatosAdicionales() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      // Cargar persona
      final urlPersona = Uri.parse(
        AppConfig.byId('persona', widget.movimiento.personaFk),
      );
      final responsePersona = await http.get(
        urlPersona,
        headers: {...AppConfig.headers, 'Authorization': 'Bearer $token'},
      );

      if (responsePersona.statusCode == 200) {
        final dataPersona = json.decode(responsePersona.body);
        setState(() {
          _persona = Persona.fromJson(dataPersona['body']);
        });
      }

      // Cargar producto
      final urlProducto = Uri.parse(
        AppConfig.byId('producto', widget.movimiento.productoFk),
      );
      final responseProducto = await http.get(
        urlProducto,
        headers: {...AppConfig.headers, 'Authorization': 'Bearer $token'},
      );

      if (responseProducto.statusCode == 200) {
        final dataProducto = json.decode(responseProducto.body);
        // Arreglar el precio si viene como String
        var productoData = dataProducto['body'];
        if (productoData['Precio'] is String) {
          productoData['Precio'] =
              double.tryParse(productoData['Precio']) ?? 0.0;
        }
        setState(() {
          _producto = Producto.fromJson(productoData);
        });
      }

      setState(() {
        _isLoadingDatosAdicionales = false;
      });
    } catch (e) {
      debugPrint(' Error al cargar datos adicionales: $e');
      setState(() {
        _isLoadingDatosAdicionales = false;
      });
    }
  }

  String _formatearFecha(DateTime fecha) {
    final meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    return '${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year}';
  }

  Color _getTipoColor(String tipo) {
    switch (tipo) {
      case "Entrada":
        return Colors.green;
      case "Salida":
        return Colors.orange;
      case "Ajuste":
        return Colors.blue;
      case "Devolucion":
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo) {
      case "Entrada":
        return Icons.arrow_downward_rounded;
      case "Salida":
        return Icons.arrow_upward_rounded;
      case "Ajuste":
        return Icons.tune_rounded;
      case "Devolucion":
        return Icons.keyboard_return_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _getNombreCompleto(Persona persona) {
    return '${persona.primerNombre} ${persona.segundoNombre ?? ''} ${persona.primerApellido} ${persona.segundoApellido ?? ''}'
        .trim();
  }

  String _getDescripcionProducto(Producto producto) {
    return '${producto.nombreProducto} - ${producto.color} / ${producto.talla} / ${producto.estampado}';
  }

  @override
  Widget build(BuildContext context) {
    final numeroFormateado = widget.numeroSecuencial.toString().padLeft(3, '0');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 750),
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.file_present_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detalle Completo del Movimiento',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ID: #$numeroFormateado',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
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

            // BODY - Scrollable
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildSeccionInformacionGeneral(),
                    if (widget.movimiento.motivo != null &&
                        widget.movimiento.motivo!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildSeccionMotivo(),
                    ],
                  ],
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Botones de acción apilados (izquierda)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Abrir modal de editar
                          showDialog(
                            context: context,
                            builder: (context) => ModalEditarMovimiento(
                              movimiento: widget.movimiento,
                              onGuardar: (movimientoActualizado) async {
                                Navigator.of(context).pop();
                              },
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Editar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667eea),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                          minimumSize: const Size(140, 44),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Abrir modal de eliminar
                          showDialog(
                            context: context,
                            builder: (context) => ModalEliminarMovimiento(
                              movimiento: widget.movimiento,
                              onConfirmar: () {},
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_rounded, size: 18),
                        label: const Text('Eliminar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                          minimumSize: const Size(140, 44),
                        ),
                      ),
                    ],
                  ),

                  // Botón cerrar (derecha)
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Cerrar'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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

  Widget _buildSeccionInformacionGeneral() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de sección
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF667eea),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Información General',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tipo de Movimiento - Badge prominente
          _buildInfoCard(
            icon: _getTipoIcon(widget.movimiento.tipo),
            iconColor: _getTipoColor(widget.movimiento.tipo),
            label: 'Tipo de Movimiento',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _getTipoColor(widget.movimiento.tipo),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _getTipoColor(widget.movimiento.tipo).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                widget.movimiento.tipo,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Fecha
          _buildInfoCard(
            icon: Icons.calendar_today_rounded,
            iconColor: Colors.blue,
            label: 'Fecha del Movimiento',
            child: Text(
              _formatearFecha(widget.movimiento.fecha),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Cantidad
          _buildInfoCard(
            icon: Icons.inventory_2_rounded,
            iconColor: Colors.indigo,
            label: 'Cantidad Total',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${widget.movimiento.cantidad} unidades',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Producto
          _buildInfoCard(
            icon: Icons.shopping_bag_rounded,
            iconColor: Colors.deepPurple,
            label: 'Producto',
            child: _isLoadingDatosAdicionales
                ? const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Cargando información...'),
                    ],
                  )
                : _producto != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getDescripcionProducto(_producto!),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildChip(
                                icon: Icons.tag_rounded,
                                label: 'ID: ${widget.movimiento.productoFk}',
                                color: Colors.grey,
                              ),
                              _buildChip(
                                icon: Icons.inventory_rounded,
                                label: 'Stock: ${_producto!.stock}',
                                color: Colors.green,
                              ),
                              _buildChip(
                                icon: Icons.attach_money_rounded,
                                label: '\$${_producto!.precio.toStringAsFixed(0)}',
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ],
                      )
                    : Text(
                        'Producto ID: ${widget.movimiento.productoFk}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
          ),

          const SizedBox(height: 16),

          // Responsable
          _buildInfoCard(
            icon: Icons.person_rounded,
            iconColor: Colors.teal,
            label: 'Responsable',
            child: _isLoadingDatosAdicionales
                ? const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Cargando información...'),
                    ],
                  )
                : _persona != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getNombreCompleto(_persona!),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_persona!.tipoDocumento}: ${_persona!.numeroDocumento}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'ID Persona: ${widget.movimiento.personaFk}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionMotivo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Descripción / Motivo',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              widget.movimiento.motivo!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}