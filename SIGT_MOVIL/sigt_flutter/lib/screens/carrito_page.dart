import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/carrito_item_model.dart';
import '../services/carrito_service.dart';
import '../widgets/header_line.dart';
import '../widgets/footer_line.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────
String _fmt(double n) =>
    NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(n);

String _fmtFecha(DateTime f) =>
    DateFormat("d 'de' MMMM 'de' yyyy", 'es_ES').format(f);

// ─── Modal Dirección ──────────────────────────────────────────────────────────
class _ModalDireccion extends StatefulWidget {
  final void Function(Map<String, String> data) onConfirmar;
  const _ModalDireccion({required this.onConfirmar});

  @override
  State<_ModalDireccion> createState() => _ModalDireccionState();
}

class _ModalDireccionState extends State<_ModalDireccion> {
  final _direccionCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  final _departamentoCtrl = TextEditingController();
  final Map<String, String?> _errors = {};

  bool _validar() {
    setState(() {
      _errors['direccion'] =
          _direccionCtrl.text.trim().isEmpty ? 'La dirección es obligatoria' : null;
      _errors['ciudad'] =
          _ciudadCtrl.text.trim().isEmpty ? 'La ciudad es obligatoria' : null;
      _errors['departamento'] =
          _departamentoCtrl.text.trim().isEmpty ? 'El departamento es obligatorio' : null;
    });
    return _errors.values.every((e) => e == null);
  }

  @override
  void dispose() {
    _direccionCtrl.dispose();
    _ciudadCtrl.dispose();
    _departamentoCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inp(String label, String hint, String? error) => InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: error,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF800080), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('📦 Dirección de envío',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('¿A dónde enviamos tu pedido?',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ]),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Dirección
            TextField(
              controller: _direccionCtrl,
              maxLines: 2,
              decoration: _inp('Dirección', 'Ej: Calle 45 #12-30, Apto 201',
                  _errors['direccion']),
            ),
            const SizedBox(height: 14),

            // Ciudad + Departamento
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _ciudadCtrl,
                  decoration: _inp('Ciudad', 'Bogotá', _errors['ciudad']),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _departamentoCtrl,
                  decoration: _inp('Departamento', 'Cundinamarca',
                      _errors['departamento']),
                ),
              ),
            ]),
            const SizedBox(height: 22),

            // Botón confirmar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_validar()) {
                    widget.onConfirmar({
                      'direccion': _direccionCtrl.text.trim(),
                      'ciudad': _ciudadCtrl.text.trim(),
                      'departamento': _departamentoCtrl.text.trim(),
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF800080),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Confirmar y ver factura →',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Modal Factura ─────────────────────────────────────────────────────────────
class _ModalFactura extends StatelessWidget {
  final Map<String, dynamic> factura;
  const _ModalFactura({required this.factura});

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF800080);
    const purpleLight = Color(0xFFFDF5FF);
    const purpleBorder = Color(0xFFE9D5FF);

    final productos = factura['productos'] as List<Map<String, dynamic>>;
    final cliente = factura['cliente'] as Map<String, dynamic>;
    final envio = factura['envio'] as Map<String, dynamic>;
    final total = (factura['total'] as num).toDouble();
    final fecha = factura['fecha'] as DateTime;
    final idVenta = factura['idVenta'];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header morado ──
            Container(
              padding: const EdgeInsets.fromLTRB(22, 20, 16, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF800080), Color(0xFFB000B0)],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('VIBRA POSITIVA PIJAMAS',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        const Text('Factura de Compra',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(
                            '#${idVenta.toString().padLeft(6, '0')} · ${_fmtFecha(fecha)}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text('✕ Cerrar',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),

            // ── Contenido scrollable ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cliente + Envío
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _InfoBox(
                            titulo: '👤 CLIENTE',
                            children: [
                              _InfoRow(
                                  label: null,
                                  value: cliente['nombre'] ?? '',
                                  bold: true),
                              if ((cliente['documento'] ?? '').isNotEmpty)
                                _InfoRow(
                                    label: 'CC:',
                                    value: cliente['documento']),
                              if ((cliente['email'] ?? '').isNotEmpty)
                                _InfoRow(label: null, value: cliente['email']),
                              if ((cliente['telefono'] ?? '').isNotEmpty)
                                _InfoRow(
                                    label: '📱',
                                    value: cliente['telefono']),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoBox(
                            titulo: '📦 ENVÍO',
                            children: [
                              _InfoRow(label: null, value: envio['direccion']),
                              _InfoRow(label: null, value: envio['ciudad']),
                              _InfoRow(
                                  label: null, value: envio['departamento']),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Productos
                    const Text('🛍️  PRODUCTOS',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: purple,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: purpleBorder),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(children: [
                        // Encabezado
                        Container(
                          color: purpleLight,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: const Row(children: [
                            Expanded(
                                flex: 5,
                                child: Text('Producto',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: purple))),
                            SizedBox(width: 6),
                            Text('Cant.',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: purple)),
                            SizedBox(width: 10),
                            Text('Precio',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: purple)),
                            SizedBox(width: 6),
                            Text('Subtotal',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: purple)),
                          ]),
                        ),
                        const Divider(height: 1, color: purpleBorder),
                        ...productos.asMap().entries.map((entry) {
                          final i = entry.key;
                          final p = entry.value;
                          final imgUrl = p['imagen']?.toString();
                          final esUltimo = i == productos.length - 1;
                          return Column(children: [
                            Container(
                              color: i.isEven ? Colors.white : purpleLight,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Row(children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: imgUrl != null &&
                                                imgUrl.isNotEmpty
                                            ? Image.network(imgUrl,
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    _imgPlaceholder())
                                            : _imgPlaceholder(),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(p['nombre'] ?? '',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13),
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                            Text(
                                                '${p['color']} · T. ${p['talla']}',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey[600])),
                                          ],
                                        ),
                                      ),
                                    ]),
                                  ),
                                  const SizedBox(width: 6),
                                  SizedBox(
                                      width: 28,
                                      child: Text('${p['cantidad']}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14))),
                                  const SizedBox(width: 6),
                                  SizedBox(
                                      width: 54,
                                      child: Text(
                                          _fmt((p['precioUnitario'] as num)
                                              .toDouble()),
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600]))),
                                  const SizedBox(width: 4),
                                  SizedBox(
                                      width: 58,
                                      child: Text(
                                          _fmt((p['subtotal'] as num)
                                              .toDouble()),
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13))),
                                ],
                              ),
                            ),
                            if (!esUltimo)
                              const Divider(
                                  height: 1, color: Color(0xFFF3E8FF)),
                          ]);
                        }),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // Total
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFFDF5FF), Color(0xFFF3E8FF)]),
                        border: Border.all(
                            color: const Color(0xFFD8B4FE), width: 1.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total a pagar',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: purple)),
                          Text('${_fmt(total)} COP',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                  color: purple)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Botón cerrar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('✓ ¡Listo! Continuar comprando',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _imgPlaceholder() => Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
          color: const Color(0xFFF3E8FF),
          borderRadius: BorderRadius.circular(6)),
      child: const Center(child: Text('🩳', style: TextStyle(fontSize: 18))),
    );

// ── Info helpers ──────────────────────────────────────────────────────────────
class _InfoBox extends StatelessWidget {
  final String titulo;
  final List<Widget> children;
  const _InfoBox({required this.titulo, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF5FF),
        border: Border.all(color: const Color(0xFFE9D5FF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF800080),
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String? label;
  final String? value;
  final bool bold;
  const _InfoRow({this.label, this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(
        label != null ? '$label $value' : value!,
        style: TextStyle(
            fontSize: bold ? 14 : 12,
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            color: bold ? Colors.black87 : const Color(0xFF555555)),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ─── Página principal del Carrito ─────────────────────────────────────────────
class CarritoPage extends StatefulWidget {
  const CarritoPage({super.key});

  @override
  State<CarritoPage> createState() => _CarritoPageState();
}

class _CarritoPageState extends State<CarritoPage> {
  final CarritoService _carritoService = CarritoService();

  List<CarritoItem> carrito = [];
  List<bool> productosSeleccionados = [];
  bool isLoading = true;
  bool procesandoCompra = false;

  @override
  void initState() {
    super.initState();
    _cargarCarrito();
  }

  Future<void> _cargarCarrito() async {
    setState(() => isLoading = true);
    final items = await _carritoService.cargarCarritoLocal();
    setState(() {
      carrito = items;
      productosSeleccionados = List.filled(items.length, true);
      isLoading = false;
    });
  }

  Future<void> _guardarCarrito() async {
    await _carritoService.guardarCarritoLocal(carrito);
  }

  void _toggleSeleccion(int index) =>
      setState(() => productosSeleccionados[index] = !productosSeleccionados[index]);

  void _seleccionarTodos() =>
      setState(() => productosSeleccionados = List.filled(carrito.length, true));

  void _deseleccionarTodos() =>
      setState(() => productosSeleccionados = List.filled(carrito.length, false));

  void _actualizarCantidad(int index, int nuevaCantidad) {
    final producto = carrito[index];
    if (nuevaCantidad < 1) return;
    if (nuevaCantidad > producto.stock) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Solo hay ${producto.stock} unidades disponibles'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    setState(() => carrito[index] = producto.copyWith(cantidad: nuevaCantidad));
    _guardarCarrito();
  }

  Future<void> _confirmarEliminacion(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Estás seguro?'),
        content: const Text('Este producto será eliminado de tu carrito'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        carrito.removeAt(index);
        productosSeleccionados.removeAt(index);
      });
      await _guardarCarrito();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Producto eliminado del carrito'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ));
      }
    }
  }

  Future<void> _vaciarCarrito() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Vaciar carrito?'),
        content: const Text('Se eliminarán todos los productos de tu carrito'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Vaciar')),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        carrito.clear();
        productosSeleccionados.clear();
      });
      await _carritoService.limpiarCarritoLocal();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Carrito vaciado'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ));
      }
    }
  }

  Future<void> _finalizarCompra() async {
    final productosAComprar = <CarritoItem>[];
    for (int i = 0; i < carrito.length; i++) {
      if (productosSeleccionados[i]) productosAComprar.add(carrito[i]);
    }

    if (productosAComprar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Por favor selecciona al menos un producto'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    // ── Abrir modal de dirección ──
    final direccionData = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ModalDireccion(
        onConfirmar: (data) => Navigator.pop(context, data),
      ),
    );

    if (direccionData == null || !mounted) return;

    setState(() => procesandoCompra = true);

    final result = await _carritoService.finalizarCompra(
      productosAComprar,
      direccionEntrega: direccionData['direccion']!,
      ciudad: direccionData['ciudad']!,
      departamento: direccionData['departamento']!,
    );

    setState(() => procesandoCompra = false);
    if (!mounted) return;

    if (result['success']) {
      // Actualizar carrito local
      final carritoActualizado = <CarritoItem>[];
      final seleccionActualizada = <bool>[];
      for (int i = 0; i < carrito.length; i++) {
        if (!productosSeleccionados[i]) {
          carritoActualizado.add(carrito[i]);
          seleccionActualizada.add(true);
        }
      }
      setState(() {
        carrito = carritoActualizado;
        productosSeleccionados = seleccionActualizada;
      });
      await _guardarCarrito();

      // Leer datos del usuario para la factura
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('current_user') ?? '{}';
      Map<String, dynamic> user = {};
      try { user = json.decode(userStr); } catch (_) {}

      final nombre =
          '${user['Primer_Nombre'] ?? ''} ${user['Primer_Apellido'] ?? ''}'.trim();

      // Mostrar modal de factura
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _ModalFactura(
          factura: {
            'idVenta': result['idVenta'] ?? 0,
            'fecha': DateTime.now(),
            'cliente': {
              'nombre': nombre.isEmpty ? 'Cliente' : nombre,
              'documento': user['Numero_Documento']?.toString() ?? '',
              'email': user['Correo']?.toString() ?? '',
              'telefono': user['Telefono']?.toString() ?? '',
            },
            'envio': {
              'direccion': direccionData['direccion'],
              'ciudad': direccionData['ciudad'],
              'departamento': direccionData['departamento'],
            },
            'productos': productosAComprar
                .map((p) => {
                      'nombre': p.nombre,
                      'color': p.color,
                      'talla': p.talla,
                      'imagen': p.imagen,
                      'cantidad': p.cantidad,
                      'precioUnitario': p.precio,
                      'subtotal': p.precio * p.cantidad,
                    })
                .toList(),
            'total': productosAComprar.fold<double>(
                0, (acc, p) => acc + p.precio * p.cantidad),
          },
        ),
      );

      if (mounted && carrito.isEmpty) Navigator.pop(context, true);
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error en la compra'),
          content: Text(result['message'] ?? 'Error desconocido'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Aceptar')),
          ],
        ),
      );
    }
  }

  double get total {
    double sum = 0;
    for (int i = 0; i < carrito.length; i++) {
      if (productosSeleccionados[i]) sum += carrito[i].subtotal;
    }
    return sum;
  }

  int get cantidadSeleccionada =>
      productosSeleccionados.where((s) => s).length;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF800080), Color(0xFFE6C7F6)],
            ),
          ),
          child: const Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              SizedBox(height: 16),
              Text('Cargando carrito...',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(children: [
        HeaderLine(onLogout: () {}),
        Container(
          color: const Color(0xFF800080),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const Text('Mi Carrito',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ]),
        ),
        Expanded(
          child: carrito.isEmpty
              ? _buildCarritoVacio()
              : _buildListaCarrito(),
        ),
        const FooterLine(),
      ]),
    );
  }

  Widget _buildCarritoVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 24),
          const Text('Tu carrito está vacío',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('Agrega productos desde la tienda',
              style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.store),
            label: const Text('Ir a la tienda'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF800080),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildListaCarrito() {
    return Column(children: [
      // Controles selección
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              TextButton.icon(
                onPressed: _seleccionarTodos,
                icon: const Icon(Icons.check_box, size: 18),
                label: const Text('Todos'),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF800080)),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: _deseleccionarTodos,
                icon: const Icon(Icons.check_box_outline_blank, size: 18),
                label: const Text('Ninguno'),
                style:
                    TextButton.styleFrom(foregroundColor: Colors.grey[700]),
              ),
            ]),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF800080).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$cantidadSeleccionada de ${carrito.length}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF800080))),
            ),
          ],
        ),
      ),
      // Lista
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: carrito.length,
          itemBuilder: (_, index) => _buildProductoCard(index),
        ),
      ),
      _buildFooter(),
    ]);
  }

  Widget _buildProductoCard(int index) {
    final producto = carrito[index];
    final isSelected = productosSeleccionados[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 2 : 0.5,
      color: isSelected ? Colors.white : Colors.grey[200],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Checkbox(
              value: isSelected,
              onChanged: (_) => _toggleSeleccion(index),
              activeColor: const Color(0xFF800080),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(producto.imagen, width: 80, height: 80,
                  fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(
                      width: 80, height: 80, color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(producto.nombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Text('Color: ${producto.color}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(producto.talla,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(_fmt(producto.precio) + ' COP',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF800080))),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            // Contador
            Container(
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                IconButton(
                  onPressed: producto.cantidad > 1
                      ? () => _actualizarCantidad(index, producto.cantidad - 1)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: const Color(0xFF800080),
                ),
                Text('${producto.cantidad}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: producto.cantidad < producto.stock
                      ? () => _actualizarCantidad(index, producto.cantidad + 1)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  color: const Color(0xFF800080),
                ),
              ]),
            ),
            // Subtotal + eliminar
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Subtotal: ${_fmt(producto.subtotal)}',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () => _confirmarEliminacion(index),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Eliminar'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ]),
          ]),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text('Stock: ${producto.stock}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            TextButton.icon(
              onPressed: procesandoCompra ? null : _vaciarCarrito,
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Vaciar'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('Total:',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
              Text(_fmt(total) + ' COP',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF800080))),
            ]),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    procesandoCompra ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Seguir'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF800080),
                  side: const BorderSide(color: Color(0xFF800080)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: cantidadSeleccionada == 0 || procesandoCompra
                    ? null
                    : _finalizarCompra,
                icon: procesandoCompra
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                    : const Icon(Icons.check_circle),
                label: Text(procesandoCompra
                    ? 'Procesando...'
                    : 'Comprar ($cantidadSeleccionada)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF800080),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ]),
          if (cantidadSeleccionada == 0)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Selecciona al menos un producto',
                  style: TextStyle(color: Colors.red, fontSize: 12)),
            ),
        ]),
      ),
    );
  }
}