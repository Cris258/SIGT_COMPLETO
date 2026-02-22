import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../models/producto.dart';
import '../widgets/header_widget.dart';
import '../widgets/footer_line.dart';
import '../widgets/widgetsAdmin/modal_editar_producto.dart';
import '../widgets/widgetsAdmin/modal_eliminar_producto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListaProductos extends StatefulWidget {
  const ListaProductos({super.key});

  @override
  State<ListaProductos> createState() => _ListaProductosState();
}

class _ListaProductosState extends State<ListaProductos> {
  List<Producto> productos = [];
  bool loading = true;
  String search = "";
  final TextEditingController searchController = TextEditingController();

  // Mapa de colores
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
    'cafe': const Color(0xFF8B4513),
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
    cargarProductos();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Color getColorCode(String? colorName) {
    if (colorName == null || colorName.isEmpty) {
      return const Color(0xFFCCCCCC);
    }
    final color = colorName.toLowerCase().trim();
    return colorMap[color] ?? const Color(0xFFCCCCCC);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> cargarProductos() async {
    setState(() {
      loading = true;
    });

    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final response = await http.get(
        Uri.parse(AppConfig.endpoint('producto')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> productosJson = data['body'] ?? [];
        
        setState(() {
          productos = productosJson.map((json) {
            // Convertir Precio a double si viene como String
            if (json['Precio'] is String) {
              json['Precio'] = double.tryParse(json['Precio']) ?? 0.0;
            }
            // Convertir Stock a int si viene como String
            if (json['Stock'] is String) {
              json['Stock'] = int.tryParse(json['Stock']) ?? 0;
            }
            return Producto.fromJson(json);
          }).toList();
          loading = false;
        });
      } else {
        throw Exception('Error al obtener productos');
      }
    } catch (e) {
      print('Error al cargar productos: $e');
      if (mounted) {
        setState(() {
          loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar productos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void abrirModalEditar(Producto producto) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalEditarProducto(
        producto: producto,
        onClose: () => Navigator.of(context).pop(),
        onGuardar: (productoActualizado) {
          setState(() {
            final index = productos.indexWhere(
                (p) => p.idProducto == productoActualizado.idProducto);
            if (index != -1) {
              productos[index] = productoActualizado;
            }
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void abrirModalEliminar(Producto producto) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalEliminarProducto(
        producto: producto,
        onClose: () => Navigator.of(context).pop(),
        onConfirmar: (productoEliminado) {
          setState(() {
            productos.removeWhere(
                (p) => p.idProducto == productoEliminado.idProducto);
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }

  List<Producto> get productosFiltrados {
    if (search.isEmpty) return productos;

    return productos.where((p) {
      final searchLower = search.toLowerCase();
      return (p.idProducto?.toString() ?? '')
              .toLowerCase()
              .contains(searchLower) ||
          p.nombreProducto.toLowerCase().contains(searchLower) ||
          p.color.toLowerCase().contains(searchLower) ||
          p.talla.toLowerCase().contains(searchLower) ||
          p.stock.toString().toLowerCase().contains(searchLower) ||
          p.precio.toString().toLowerCase().contains(searchLower);
    }).toList();
  }

  String formatearPrecio(double precio) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(precio);
  }

  Color getStockColor(int stock) {
    if (stock > 10) return const Color.fromARGB(255, 95, 229, 99);
    if (stock > 5) return Colors.orange;
    return Colors.red;
  }

  String getStockLabel(int stock) {
    if (stock > 10) return 'Disponible';
    if (stock > 5) return 'Bajo stock';
    return 'Crítico';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const HeaderWidget(),
          Expanded(
            child: loading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Cargando productos...'),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Lista de Productos Registrados',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Merriweather',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        // Buscador
                        Container(
                          constraints: const BoxConstraints(maxWidth: 600),
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          child: TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                              hintText: 'Buscar por nombre, color, talla, precio...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: search.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          search = '';
                                          searchController.clear();
                                        });
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onChanged: (value) {
                              setState(() {
                                search = value;
                              });
                            },
                          ),
                        ),

                        // Lista de Cards
                        _buildListaProductos(),
                      ],
                    ),
                  ),
          ),
          const FooterLine(),
        ],
      ),
    );
  }

  Widget _buildListaProductos() {
    if (productosFiltrados.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                search.isNotEmpty
                    ? 'No se encontraron resultados'
                    : 'No hay productos registrados',
                style: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (search.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Intenta con otros términos de búsqueda',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      children: productosFiltrados.map((producto) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FILA PRINCIPAL: ID, Nombre y Acciones
                Row(
                  children: [
                    // Color Circle (grande y destacado)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: getColorCode(producto.color),
                        border: Border.all(
                          color: Colors.grey[400]!,
                          width: 3,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // ID y Nombre
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${producto.idProducto ?? ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            producto.nombreProducto,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ACCIONES
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Editar
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => abrirModalEditar(producto),
                          tooltip: 'Editar',
                        ),

                        // Eliminar
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => abrirModalEliminar(producto),
                          tooltip: 'Eliminar',
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // INFORMACIÓN DETALLADA
                Row(
                  children: [
                    // Color
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.palette,
                        label: 'Color',
                        value: producto.color,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Talla
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.straighten,
                        label: 'Talla',
                        value: producto.talla,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Stock
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.inventory,
                        label: getStockLabel(producto.stock),
                        value: producto.stock.toString(),
                        color: getStockColor(producto.stock),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // PRECIO (destacado)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green[700]!,
                        Colors.green[500]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.attach_money,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatearPrecio(producto.precio),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}