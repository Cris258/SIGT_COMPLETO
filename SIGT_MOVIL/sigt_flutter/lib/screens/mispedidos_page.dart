import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/pedidos_service.dart';
import '../models/venta_historial_model.dart';

// ─── Color helper ─────────────────────────────────────────────────────────────
Color _getColorCode(String? name) {
  const map = {
    'rojo': Color(0xFFE53E3E), 'azul': Color(0xFF3182CE), 'verde': Color(0xFF38A169),
    'amarillo': Color(0xFFECC94B), 'negro': Color(0xFF1A202C), 'blanco': Color(0xFFF7FAFC),
    'gris': Color(0xFF718096), 'rosa': Color(0xFFF687B3), 'morado': Color(0xFF805AD5),
    'naranja': Color(0xFFED8936), 'cafe': Color(0xFF8B4513), 'café': Color(0xFF8B4513),
    'beige': Color(0xFFF5F5DC), 'celeste': Color(0xFF87CEEB), 'turquesa': Color(0xFF40E0D0),
    'violeta': Color(0xFF9F7AEA), 'fucsia': Color(0xFFD53F8C), 'marino': Color(0xFF2C5282),
    'vino': Color(0xFF702459), 'crema': Color(0xFFFFFDD0),
  };
  return map[(name ?? '').toLowerCase().trim()] ?? const Color(0xFFA0AEC0);
}

String _fmt(double n) =>
    NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(n);

String _fmtFecha(DateTime f) =>
    DateFormat("d 'de' MMMM 'de' yyyy", 'es_ES').format(f);

String _fmtFechaCorta(DateTime f) =>
    DateFormat("d MMM yyyy", 'es_ES').format(f);

// ─── Modal de detalle ─────────────────────────────────────────────────────────
class _ModalDetalle extends StatelessWidget {
  final VentaHistorial venta;
  const _ModalDetalle({required this.venta});

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF800080);
    const purpleLight = Color(0xFFFDF5FF);
    const purpleBorder = Color(0xFFE9D5FF);

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
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
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
                        const Text('Detalle del Pedido',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(
                          '#${venta.idVenta.toString().padLeft(6, '0')} · ${_fmtFecha(venta.fechaVenta)}',
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección productos
                    const Text('🛍️  PRODUCTOS',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: purple,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: purpleBorder),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          // Encabezado tabla
                          Container(
                            color: purpleLight,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            child: const Row(children: [
                              Expanded(
                                  flex: 5,
                                  child: Text('Producto',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: purple))),
                              SizedBox(width: 8),
                              Text('Cant.',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: purple)),
                              SizedBox(width: 12),
                              Text('Precio',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: purple)),
                              SizedBox(width: 8),
                              Text('Subtotal',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: purple)),
                            ]),
                          ),
                          const Divider(height: 1, color: purpleBorder),

                          // Filas de productos
                          if (venta.detalles.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text('No hay productos disponibles',
                                  style:
                                      TextStyle(color: Colors.grey, fontSize: 13)),
                            )
                          else
                            ...venta.detalles.asMap().entries.map((entry) {
                              final i = entry.key;
                              final d = entry.value;
                              final esUltimo = i == venta.detalles.length - 1;
                              final imgUrl =
                                  d.imagenUrl?.isNotEmpty == true &&
                                          d.imagenUrl != 'null'
                                      ? d.imagenUrl!
                                      : null;

                              return Column(children: [
                                Container(
                                  color: i.isEven ? Colors.white : purpleLight,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Info producto
                                      Expanded(
                                        flex: 5,
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            // Imagen
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: imgUrl != null
                                                  ? Image.network(
                                                      imgUrl,
                                                      width: 44,
                                                      height: 44,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) =>
                                                          _placeholder())
                                                  : _placeholder(),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(d.nombreProducto,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 13),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis),
                                                  const SizedBox(height: 3),
                                                  Row(children: [
                                                    Container(
                                                      width: 10,
                                                      height: 10,
                                                      decoration: BoxDecoration(
                                                        color: _getColorCode(
                                                            d.color),
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                            color: Colors
                                                                .grey[300]!,
                                                            width: 1),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Flexible(
                                                      child: Text(
                                                          '${d.color} · T. ${d.talla}',
                                                          style: TextStyle(
                                                              fontSize: 10,
                                                              color: Colors
                                                                  .grey[600]),
                                                          overflow: TextOverflow
                                                              .ellipsis),
                                                    ),
                                                  ]),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Cantidad
                                      SizedBox(
                                          width: 28,
                                          child: Text('${d.cantidad}',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14))),
                                      const SizedBox(width: 8),
                                      // Precio unitario
                                      SizedBox(
                                          width: 52,
                                          child: Text(_fmt(d.precioUnitario),
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600]))),
                                      const SizedBox(width: 6),
                                      // Subtotal
                                      SizedBox(
                                          width: 60,
                                          child: Text(
                                              _fmt(d.cantidad *
                                                  d.precioUnitario),
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13))),
                                    ],
                                  ),
                                ),
                                if (!esUltimo)
                                  const Divider(
                                      height: 1,
                                      color: Color(0xFFF3E8FF)),
                              ]);
                            }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Total
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFDF5FF), Color(0xFFF3E8FF)],
                        ),
                        border: Border.all(
                            color: const Color(0xFFD8B4FE), width: 1.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total del pedido',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: purple)),
                          Text(_fmt(venta.total),
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
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('✓ Cerrar',
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

  Widget _placeholder() => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            color: const Color(0xFFF3E8FF),
            borderRadius: BorderRadius.circular(8)),
        child: const Center(child: Text('🩳', style: TextStyle(fontSize: 20))),
      );
}

// ─── Pantalla principal ───────────────────────────────────────────────────────
class MisPedidosScreen extends StatefulWidget {
  const MisPedidosScreen({Key? key}) : super(key: key);

  @override
  State<MisPedidosScreen> createState() => _MisPedidosScreenState();
}

class _MisPedidosScreenState extends State<MisPedidosScreen> {
  final PedidosService _pedidosService = PedidosService();
  final TextEditingController _searchController = TextEditingController();

  List<VentaHistorial> _ventas = [];
  List<VentaHistorial> _ventasFiltradas = [];
  bool _isLoading = true;

  static const purple = Color(0xFF800080);
  static const purpleLight = Color(0xFFFDF5FF);
  static const purpleBorder = Color(0xFFE9D5FF);

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarHistorial() async {
    setState(() => _isLoading = true);
    try {
      final ventas = await _pedidosService.obtenerHistorial();
      setState(() {
        _ventas = ventas;
        _ventasFiltradas = ventas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al cargar historial: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _filtrar(String query) {
    setState(() {
      if (query.isEmpty) {
        _ventasFiltradas = _ventas;
      } else {
        final q = query.toLowerCase();
        _ventasFiltradas = _ventas
            .where((v) =>
                v.idVenta.toString().contains(q) ||
                _fmtFecha(v.fechaVenta).toLowerCase().contains(q) ||
                v.total.toString().contains(q))
            .toList();
      }
    });
  }

  void _abrirDetalle(VentaHistorial venta) {
    showDialog(
      context: context,
      builder: (_) => _ModalDetalle(venta: venta),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mis Pedidos',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white)),
        backgroundColor: purple,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: purple))
          : RefreshIndicator(
              onRefresh: _cargarHistorial,
              color: purple,
              child: Column(children: [
                // ── Buscador ──
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filtrar,
                    decoration: InputDecoration(
                      hintText: 'Buscar por ID, fecha o total...',
                      prefixIcon: const Icon(Icons.search, color: purple),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filtrar('');
                              })
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey[300]!)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey[300]!)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: purple, width: 2)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ),

                // ── Lista ──
                Expanded(
                  child: _ventasFiltradas.isEmpty
                      ? Center(
                          child: Container(
                            margin: const EdgeInsets.all(24),
                            padding: const EdgeInsets.all(36),
                            decoration: BoxDecoration(
                              color: purpleLight,
                              border:
                                  Border.all(color: purpleBorder, width: 1.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child:
                                Column(mainAxisSize: MainAxisSize.min, children: [
                              const Text('🛍️',
                                  style: TextStyle(fontSize: 40)),
                              const SizedBox(height: 12),
                              Text(
                                _searchController.text.isNotEmpty
                                    ? 'No se encontraron resultados'
                                    : 'Aún no tienes compras',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: purple,
                                    fontSize: 15),
                              ),
                              if (_searchController.text.isEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                    'Cuando hagas una compra aparecerá aquí',
                                    style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12)),
                              ],
                            ]),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _ventasFiltradas.length,
                          itemBuilder: (_, i) =>
                              _buildCard(_ventasFiltradas[i]),
                        ),
                ),
              ]),
            ),
    );
  }

  Widget _buildCard(VentaHistorial venta) {
    final detalles = venta.detalles;
    final miniCount = detalles.take(4).length;
    // Ancho exacto del stack: 40px base + 24px por cada miniatura extra
    final stackWidth = 40.0 + (miniCount - 1).clamp(0, 3) * 24.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF3E8FF)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        // ── Header morado ──
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF800080), Color(0xFFB000B0)],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pedido #${venta.idVenta.toString().padLeft(6, '0')}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.calendar_today,
                          size: 11, color: Colors.white70),
                      const SizedBox(width: 5),
                      Text(_fmtFechaCorta(venta.fechaVenta),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white70)),
                    ]),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_fmt(venta.total),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white)),
              ),
            ],
          ),
        ),

        // ── Cuerpo: miniaturas + botón ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Row(
            children: [
              // Miniaturas apiladas — SizedBox con ancho fijo para el Stack
              SizedBox(
                width: stackWidth,
                height: 40,
                child: Stack(
                  children: detalles
                      .take(4)
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                    final idx = entry.key;
                    final d = entry.value;
                    final imgUrl =
                        d.imagenUrl?.isNotEmpty == true &&
                                d.imagenUrl != 'null'
                            ? d.imagenUrl!
                            : null;
                    return Positioned(
                      left: idx * 24.0,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.white, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: imgUrl != null
                              ? Image.network(imgUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _miniPlaceholder())
                              : _miniPlaceholder(),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${detalles.length} ${detalles.length == 1 ? "producto" : "productos"}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const Spacer(),
              // Botón ver detalle
              GestureDetector(
                onTap: () => _abrirDetalle(venta),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: purple,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(children: [
                    Icon(Icons.receipt_long,
                        color: Colors.white, size: 15),
                    SizedBox(width: 6),
                    Text('Ver detalle',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _miniPlaceholder() => Container(
        color: const Color(0xFFF3E8FF),
        child:
            const Center(child: Text('🩳', style: TextStyle(fontSize: 16))),
      );
}