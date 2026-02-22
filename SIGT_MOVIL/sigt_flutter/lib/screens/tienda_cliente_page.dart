import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/productos_service.dart';
import '../widgets/header_line.dart';
import '../widgets/footer_line.dart';
import '../widgets/actualizar_datos_modal.dart';
import '../widgets/cambiar_contraseña_modal.dart';

// ─── Color helper ─────────────────────────────────────────────────────────────
Color _getColorCode(String? name) {
  const map = {
    'rojo': Color(0xFFE53E3E),
    'azul': Color(0xFF3182CE),
    'verde': Color(0xFF38A169),
    'amarillo': Color(0xFFECC94B),
    'negro': Color(0xFF1A202C),
    'blanco': Color(0xFFF7FAFC),
    'gris': Color(0xFF718096),
    'rosa': Color(0xFFF687B3),
    'morado': Color(0xFF805AD5),
    'naranja': Color(0xFFED8936),
    'cafe': Color(0xFF8B4513),
    'café': Color(0xFF8B4513),
    'beige': Color(0xFFF5F5DC),
    'celeste': Color(0xFF87CEEB),
    'turquesa': Color(0xFF40E0D0),
    'violeta': Color(0xFF9F7AEA),
    'fucsia': Color(0xFFD53F8C),
    'marino': Color(0xFF2C5282),
    'vino': Color(0xFF702459),
    'crema': Color(0xFFFFFDD0),
  };
  return map[(name ?? '').toLowerCase().trim()] ?? const Color(0xFFA0AEC0);
}

// ─── Modal de producto ────────────────────────────────────────────────────────
class _ProductoModal extends StatefulWidget {
  final dynamic producto;
  final void Function(dynamic producto, String color, String talla, int cantidad) onAgregar;

  const _ProductoModal({required this.producto, required this.onAgregar});

  @override
  State<_ProductoModal> createState() => _ProductoModalState();
}

class _ProductoModalState extends State<_ProductoModal> {
  int imgIdx = 0;
  String? colorSel;
  String? tallaSel;
  int cantidad = 1;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    final colores = (widget.producto['colores'] as List?) ?? [];
    if (colores.isNotEmpty) colorSel = colores.first['color'];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _imagenes {
    if (colorSel == null) {
      final img = widget.producto['imagen_principal'];
      return img != null ? [img.toString()] : [];
    }
    final colores = (widget.producto['colores'] as List?) ?? [];
    final colorObj = colores.cast<Map>().firstWhere(
      (c) => c['color'] == colorSel, orElse: () => {},
    );
    final imgs = (colorObj['imagenes'] as List?) ?? [];
    if (imgs.isNotEmpty) return imgs.map((e) => e.toString()).toList();

    final variantes = (widget.producto['variantes'] as List?) ?? [];
    final v = variantes.cast<Map>().firstWhere(
      (v) => v['color'] == colorSel, orElse: () => {},
    );
    final vImgs = (v['imagenes'] as List?) ?? [];
    if (vImgs.isNotEmpty) return vImgs.map((e) => e.toString()).toList();

    final img = widget.producto['imagen_principal'];
    return img != null ? [img.toString()] : [];
  }

  List<dynamic> get _varsFiltradas {
    final variantes = (widget.producto['variantes'] as List?) ?? [];
    return variantes.where((v) => v['color'] == colorSel).toList();
  }

  bool get _tieneStock => _varsFiltradas.any((v) => (v['stock'] ?? 0) > 0);

  Map? get _varSel => _varsFiltradas.cast<Map?>()
      .firstWhere((v) => v?['talla'] == tallaSel, orElse: () => null);

  int get _stockActual => (_varSel?['stock'] ?? 0) as int;

  double get _precio {
    if (_varSel != null) return (_varSel!['precio'] ?? widget.producto['precio_base'] ?? 0).toDouble();
    if (_varsFiltradas.isNotEmpty) return (_varsFiltradas.first['precio'] ?? widget.producto['precio_base'] ?? 0).toDouble();
    return (widget.producto['precio_base'] ?? 0).toDouble();
  }

  void _setColor(String color) {
    setState(() { colorSel = color; tallaSel = null; cantidad = 1; imgIdx = 0; });
    _pageController.jumpToPage(0);
  }

  Widget _netImg(String url, {BoxFit fit = BoxFit.cover}) => Image.network(
    url, fit: fit, width: double.infinity,
    errorBuilder: (_, __, ___) => Container(
      color: Colors.grey[200],
      child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey[400]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final imagenes = _imagenes;
    final colores = (widget.producto['colores'] as List?) ?? [];
    final nombre = widget.producto['nombre'] ?? '';
    final estampado = widget.producto['estampado'] ?? '';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── Slider de imágenes ──
            Stack(children: [
              SizedBox(
                height: 260,
                child: imagenes.isEmpty
                    ? Container(color: Colors.grey[200],
                        child: Center(child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey[400])))
                    : PageView.builder(
                        controller: _pageController,
                        itemCount: imagenes.length,
                        onPageChanged: (i) => setState(() => imgIdx = i),
                        itemBuilder: (_, i) => _netImg(imagenes[i]),
                      ),
              ),
              // Flechas
              if (imagenes.length > 1) ...[
                if (imgIdx > 0)
                  Positioned(left: 8, top: 0, bottom: 0, child: Center(
                    child: _ArrowBtn(icon: Icons.chevron_left, onTap: () {
                      _pageController.previousPage(duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
                    }),
                  )),
                if (imgIdx < imagenes.length - 1)
                  Positioned(right: 8, top: 0, bottom: 0, child: Center(
                    child: _ArrowBtn(icon: Icons.chevron_right, onTap: () {
                      _pageController.nextPage(duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
                    }),
                  )),
                // Dots
                Positioned(bottom: 10, left: 0, right: 0,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(imagenes.length, (i) => GestureDetector(
                      onTap: () => _pageController.animateToPage(i,
                          duration: const Duration(milliseconds: 200), curve: Curves.easeInOut),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == imgIdx ? 10 : 7,
                        height: i == imgIdx ? 10 : 7,
                        decoration: BoxDecoration(
                          color: i == imgIdx ? Colors.white : Colors.white54,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )),
                  ),
                ),
              ],
              // Botón cerrar
              Positioned(top: 8, right: 8,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32, height: 32,
                    decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ]),

            // ── Miniaturas ──
            if (imagenes.length > 1)
              Container(
                height: 64, color: Colors.grey[200],
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: imagenes.length,
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => _pageController.animateToPage(i,
                        duration: const Duration(milliseconds: 200), curve: Curves.easeInOut),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      width: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: i == imgIdx ? const Color(0xFF4299E1) : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Opacity(
                          opacity: i == imgIdx ? 1 : 0.5,
                          child: Image.network(imagenes[i], fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: Colors.grey[300])),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Controles (scrollable) ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre + estampado
                    Text(nombre, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    if (estampado.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(estampado, style: TextStyle(fontSize: 13, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                    ],
                    const SizedBox(height: 10),

                    // Precio
                    Text('\$${_precio.toStringAsFixed(0)} COP',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2B6CB0))),
                    const SizedBox(height: 14),

                    // Colores bolitas
                    if (colores.isNotEmpty) ...[
                      RichText(text: TextSpan(
                        style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
                        children: [
                          const TextSpan(text: 'Color: ', style: TextStyle(fontWeight: FontWeight.w600)),
                          TextSpan(text: colorSel ?? ''),
                        ],
                      )),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8,
                        children: colores.map<Widget>((c) {
                          final cName = c['color'] as String?;
                          final selected = cName == colorSel;
                          return GestureDetector(
                            onTap: () => _setColor(cName ?? ''),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 30, height: 30,
                              decoration: BoxDecoration(
                                color: _getColorCode(cName),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected ? const Color(0xFF4299E1) : Colors.grey[300]!,
                                  width: selected ? 3 : 1.5,
                                ),
                                boxShadow: selected
                                    ? [const BoxShadow(color: Color(0x664299E1), blurRadius: 6, spreadRadius: 1)]
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Sin stock
                    if (!_tieneStock)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red[50], borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.error_outline, color: Colors.red[700], size: 16),
                          const SizedBox(width: 6),
                          Text('Sin stock para este color',
                              style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w600, fontSize: 13)),
                        ]),
                      )
                    else ...[
                      // Tallas
                      const Text('Talla', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF555555))),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8,
                        children: _varsFiltradas.map<Widget>((v) {
                          final talla = v['talla'] as String?;
                          final stock = (v['stock'] ?? 0) as int;
                          final agotado = stock == 0;
                          final selected = talla == tallaSel;
                          return GestureDetector(
                            onTap: agotado ? null : () => setState(() { tallaSel = talla; cantidad = 1; }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              constraints: const BoxConstraints(minWidth: 46),
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: selected ? const Color(0xFFEBF8FF) : agotado ? Colors.grey[100] : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selected ? const Color(0xFF4299E1) : Colors.grey[300]!,
                                  width: selected ? 2 : 1.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(talla ?? '',
                                style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: agotado ? Colors.grey[400] : const Color(0xFF2D3748),
                                  decoration: agotado ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (tallaSel != null) ...[
                        const SizedBox(height: 6),
                        Text('$_stockActual unidades disponibles',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                      const SizedBox(height: 16),

                      // Cantidad
                      const Text('Cantidad', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF555555))),
                      const SizedBox(height: 8),
                      Row(children: [
                        _CantBtn(icon: Icons.remove, onTap: () { if (cantidad > 1) setState(() => cantidad--); }),
                        SizedBox(width: 44,
                          child: Text('$cantidad', textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                        _CantBtn(icon: Icons.add, onTap: () {
                          if (tallaSel == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Selecciona una talla'), backgroundColor: Colors.orange,
                              duration: Duration(seconds: 1),
                            ));
                            return;
                          }
                          if (cantidad < _stockActual) setState(() => cantidad++);
                        }),
                      ]),
                      const SizedBox(height: 20),

                      // Botón agregar
                      SizedBox(width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (tallaSel == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                content: Text('Selecciona una talla'), backgroundColor: Colors.orange,
                                duration: Duration(seconds: 2),
                              ));
                              return;
                            }
                            widget.onAgregar(widget.producto, colorSel ?? '', tallaSel!, cantidad);
                          },
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Agregar al carrito',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF800080),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
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

class _ArrowBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ArrowBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34, height: 34,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.88), shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)]),
      child: Icon(icon, size: 22, color: Colors.black87),
    ),
  );
}

class _CantBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CantBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(border: Border.all(color: Colors.grey[400]!), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 18, color: Colors.black87),
    ),
  );
}

// ─── Página principal ─────────────────────────────────────────────────────────
class TiendaClientePage extends StatefulWidget {
  const TiendaClientePage({super.key});

  @override
  State<TiendaClientePage> createState() => _TiendaClientePageState();
}

class _TiendaClientePageState extends State<TiendaClientePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ProductosService _productosService = ProductosService();

  String? nombreUsuario = 'Cliente';
  bool isLoading = true;
  bool _initialLoading = true;
  String? errorMessage;

  List<dynamic> productosAgrupados = [];
  List<Map<String, dynamic>> carrito = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    try {
      await _cargarDatosUsuario();
      await _cargarCarrito();
      await _cargarProductos();
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _initialLoading = false);
    }
  }

  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final nombre = prefs.getString('Primer_Nombre') ?? '';
    final apellido = prefs.getString('Primer_Apellido') ?? '';
    if (mounted) {
      setState(() {
        nombreUsuario = nombre.isNotEmpty && apellido.isNotEmpty
            ? '$nombre $apellido'
            : prefs.getString('correo') ?? 'Cliente';
      });
    }
  }

  Future<void> _cargarCarrito() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('carro');
    if (str != null && str != 'null' && str.isNotEmpty) {
      try {
        final list = json.decode(str) as List;
        if (mounted) setState(() => carrito = list.cast<Map<String, dynamic>>());
      } catch (_) {
        if (mounted) setState(() => carrito = []);
      }
    }
  }

  Future<void> _guardarCarrito() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('carro', json.encode(carrito));
  }

  Future<void> _cargarProductos() async {
    if (mounted) setState(() { isLoading = true; errorMessage = null; });
    try {
      final result = await _productosService.obtenerProductosAgrupados();
      if (mounted) {
        if (result['success']) {
          setState(() { productosAgrupados = result['productos'] ?? []; isLoading = false; });
        } else {
          setState(() { isLoading = false; errorMessage = result['message']; });
          if (result['message']?.contains('Sesión expirada') ?? false) _mostrarSesionExpirada();
        }
      }
    } catch (e) {
      if (mounted) setState(() { isLoading = false; errorMessage = 'Error al cargar productos: $e'; });
    }
  }

  void _mostrarSesionExpirada() {
    showDialog(context: context, barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Sesión Expirada'),
        content: const Text('Tu sesión ha expirado. Por favor, inicia sesión nuevamente.'),
        actions: [TextButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          child: const Text('Ir al Login'),
        )],
      ),
    );
  }

  void _handleLogout() {
    showDialog(context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final carritoActual = prefs.getString('carro');
              await prefs.clear();
              if (carritoActual != null) await prefs.setString('carro', carritoActual);
              if (!mounted) return;
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  void _irAlCarrito() async {
    final result = await Navigator.pushNamed(context, '/carrito');
    if (!mounted) return;
    await _cargarCarrito();
    if (result == true) await _cargarProductos();
  }

  // Primera imagen disponible para la portada
  String _getPortada(dynamic producto) {
    for (final v in (producto['variantes'] as List? ?? [])) {
      final imgs = v['imagenes'] as List?;
      if (imgs != null && imgs.isNotEmpty) return imgs.first.toString();
    }
    return producto['imagen_principal']?.toString() ?? '';
  }

  void _abrirModal(dynamic producto) {
    showDialog(
      context: context,
      builder: (_) => _ProductoModal(
        producto: producto,
        onAgregar: (prod, color, talla, cant) {
          final variantes = (prod['variantes'] as List?) ?? [];
          final variante = variantes.cast<Map>().firstWhere(
            (v) => v['color'] == color && v['talla'] == talla,
            orElse: () => {},
          );

          if (variante.isEmpty || (variante['stock'] ?? 0) == 0) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Sin stock para esta combinación'), backgroundColor: Colors.red));
            return;
          }
          if (cant > (variante['stock'] ?? 0)) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Solo hay ${variante['stock']} disponibles'), backgroundColor: Colors.orange));
            return;
          }

          final imagenMostrar = (variante['imagenes'] as List?)?.isNotEmpty == true
              ? variante['imagenes'].first.toString()
              : prod['imagen_principal']?.toString() ?? '';

          setState(() {
            carrito.add({
              'idProducto': variante['idProducto'],
              'nombre': prod['nombre'],
              'precio': variante['precio'] ?? prod['precio_base'],
              'imagen': imagenMostrar,
              'color': color,
              'talla': talla,
              'cantidad': cant,
              'stock': variante['stock'],
            });
          });
          _guardarCarrito();
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('$cant × ${prod['nombre']} ($talla) al carrito')),
            ]),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF800080), Color(0xFFE6C7F6)],
            ),
          ),
          child: const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white), strokeWidth: 5),
              SizedBox(height: 24),
              Text('Cargando Tienda...', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          )),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          HeaderLine(onLogout: _handleLogout),
          // AppBar tienda
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF800080),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white, size: 26),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const Text('TIENDA', style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
                ]),
                Stack(children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 26),
                    onPressed: _irAlCarrito,
                  ),
                  if (carrito.isNotEmpty)
                    Positioned(right: 4, top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text('${carrito.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ]),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF800080)))
                : errorMessage != null ? _buildError() : _buildGrid(),
          ),
          const FooterLine(),
        ],
      ),
      drawer: _buildDrawer(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(errorMessage ?? 'Error al cargar productos',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _cargarProductos,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF800080), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildGrid() {
    if (productosAgrupados.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text('No hay productos disponibles', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
      ]));
    }

    return RefreshIndicator(
      onRefresh: _cargarProductos,
      color: const Color(0xFF800080),
      child: CustomScrollView(
        slivers: [
          // Header decorativo
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [const Color(0xFF800080).withOpacity(0.08), Colors.transparent],
                ),
              ),
              child: Column(children: [
                const Text('TIENDA ONLINE', style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2, color: Color(0xFF800080))),
                const SizedBox(height: 4),
                Text('Dulces sueños con estilo',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700],
                        fontWeight: FontWeight.w500, fontStyle: FontStyle.italic)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF800080).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${productosAgrupados.length} productos disponibles',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
          ),
          // Grid 2 columnas
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _buildCard(productosAgrupados[i]),
                childCount: productosAgrupados.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.63,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildCard(dynamic producto) {
    final nombre = producto['nombre'] ?? '';
    final estampado = producto['estampado'] ?? '';
    final precioBase = (producto['precio_base'] ?? 0).toDouble();
    final portada = _getPortada(producto);
    final colores = (producto['colores'] as List?) ?? [];
    final variantes = (producto['variantes'] as List?) ?? [];
    final tieneStock = variantes.any((v) => (v['stock'] ?? 0) > 0);
    final precio = variantes.isNotEmpty
        ? (variantes.first['precio'] ?? precioBase).toDouble()
        : precioBase;

    return GestureDetector(
      onTap: () => _abrirModal(producto),
      child: Card(
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen (60% de la card)
            Expanded(
              flex: 6,
              child: portada.isEmpty
                  ? Container(color: Colors.grey[200],
                      child: Center(child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey[400])))
                  : Image.network(portada, width: double.infinity, fit: BoxFit.cover,
                      loadingBuilder: (_, child, p) =>
                          p == null ? child : Container(color: Colors.grey[100],
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                      errorBuilder: (_, __, ___) => Container(color: Colors.grey[200],
                          child: Center(child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey[400])))),
            ),

            // Info (40%)
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Nombre
                  Text(nombre, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, height: 1.2)),
                  // Estampado
                  if (estampado.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(estampado, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                  ],
                  const SizedBox(height: 6),
                  // Bolitas de colores (hasta 7)
                  if (colores.isNotEmpty)
                    Wrap(spacing: 4, runSpacing: 4,
                      children: [
                        ...colores.take(7).map<Widget>((c) {
                          final cName = c['color'] as String?;
                          return Container(
                            width: 14, height: 14,
                            decoration: BoxDecoration(
                              color: _getColorCode(cName),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey[300]!, width: 1.2),
                            ),
                          );
                        }),
                        if (colores.length > 7)
                          Text('+${colores.length - 7}',
                              style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                      ],
                    ),
                  const Spacer(),
                  // Precio
                  Text('\$${precio.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2B6CB0))),
                  const SizedBox(height: 4),
                  // Hint
                  if (!tieneStock)
                    Text('Sin stock',
                        style: TextStyle(fontSize: 11, color: Colors.red[700], fontWeight: FontWeight.w600))
                  else
                    Row(children: [
                      Icon(Icons.touch_app_outlined, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 3),
                      Text('Ver tallas y colores', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ]),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFFE6C7F6),
        child: ListView(padding: EdgeInsets.zero, children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFE6C7F6)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const CircleAvatar(radius: 40,
                  backgroundColor: Color(0xFF7E57C2),
                  child: Icon(Icons.person, size: 50, color: Colors.white)),
              const SizedBox(height: 10),
              Text(nombreUsuario ?? 'Cliente',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
          ),
          _drawerItem(icon: Icons.settings, title: 'Actualizar Datos', onTap: () {
            Navigator.pop(context);
            showDialog(context: context, builder: (_) => const ActualizarDatosModal());
          }),
          _drawerItem(icon: Icons.lock, title: 'Cambiar Contraseña', onTap: () {
            Navigator.pop(context);
            showDialog(context: context, builder: (_) => const CambiarContrasenaModal());
          }),
          const Divider(color: Colors.white30, thickness: 1, height: 32),
          _drawerItem(icon: Icons.store, title: 'Tienda', onTap: () => Navigator.pop(context), selected: true),
          _drawerItem(icon: Icons.shopping_cart, title: 'Mi Carrito', badge: carrito.length, onTap: _irAlCarrito),
          _drawerItem(icon: Icons.receipt_long, title: 'Mis Pedidos',
              onTap: () => Navigator.pushNamed(context, '/mis_pedidos')),
        ]),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon, required String title, required VoidCallback onTap,
    bool selected = false, int badge = 0,
  }) {
    return ListTile(
      leading: Stack(clipBehavior: Clip.none, children: [
        Icon(icon, color: selected ? const Color(0xFF4A148C) : Colors.white, size: 26),
        if (badge > 0)
          Positioned(right: -4, top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
      ]),
      title: Text(title, style: TextStyle(
          color: selected ? const Color(0xFF4A148C) : Colors.white,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      selected: selected,
      selectedTileColor: Colors.white.withOpacity(0.2),
      onTap: onTap,
    );
  }
}