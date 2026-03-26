import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/inventario_service.dart';
import '../widgets/header_line.dart';
import '../widgets/footer_line.dart';
import '../widgets/actualizar_datos_modal.dart';
import '../widgets/cambiar_contraseña_modal.dart';
import '../services/pdf_download_service.dart';

class AdminInventarioPage extends StatefulWidget {
  const AdminInventarioPage({super.key});

  @override
  State<AdminInventarioPage> createState() => _AdminInventarioPageState();
}

class _AdminInventarioPageState extends State<AdminInventarioPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final InventarioService _inventarioService = InventarioService();

  bool _loading = false;
  bool _initialLoading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Datos del usuario
  String? nombreUsuario = "Administrador";

  // Datos de la API
  List<dynamic> productos = [];
  List<dynamic> topProductos = [];
  Map<String, dynamic>? estadisticas;

  // Paginación
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  // Mapa de colores
  final Map<String, Color> colorMap = {
    'rojo': Colors.red,
    'azul': Colors.blue,
    'verde': Colors.green,
    'amarillo': Colors.yellow,
    'negro': Colors.black,
    'blanco': Colors.white,
    'gris': Colors.grey,
    'rosa': Colors.pink,
    'morado': Colors.purple,
    'naranja': Colors.orange,
    'cafe': const Color(0xFF8B4513),
    'café': const Color(0xFF8B4513),
    'beige': const Color(0xFFF5F5DC),
    'celeste': Colors.lightBlue,
    'turquesa': Colors.teal,
    'violeta': Colors.purpleAccent,
    'fucsia': Colors.pinkAccent,
    'marino': const Color(0xFF000080),
    'vino': const Color(0xFF722F37),
    'crema': const Color(0xFFFFFDD0),
  };

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    try {
      print('Iniciando carga de datos iniciales...');

      // Cargar nombre de usuario
      final prefs = await SharedPreferences.getInstance();
      final currentUserJson = prefs.getString('current_user');

      if (currentUserJson != null) {
        try {
          final user = json.decode(currentUserJson);
          setState(() {
            final primerNombre =
                user['primer_nombre'] ?? user['primerNombre'] ?? '';
            final primerApellido =
                user['primer_apellido'] ?? user['primerApellido'] ?? '';

            if (primerNombre.isNotEmpty && primerApellido.isNotEmpty) {
              nombreUsuario = '$primerNombre $primerApellido';
            } else {
              nombreUsuario = user['correo'] ?? 'Administrador';
            }
          });
          print('Usuario cargado: $nombreUsuario');
        } catch (e) {
          print('Error parseando usuario: $e');
          // Intentar con las claves antiguas de SharedPreferences
          final nombre = prefs.getString('Primer_Nombre') ?? '';
          final apellido = prefs.getString('Primer_Apellido') ?? '';
          if (nombre.isNotEmpty && apellido.isNotEmpty) {
            setState(() {
              nombreUsuario = '$nombre $apellido';
            });
          }
        }
      } else {
        // Intentar con las claves antiguas de SharedPreferences
        final nombre = prefs.getString('Primer_Nombre') ?? '';
        final apellido = prefs.getString('Primer_Apellido') ?? '';
        if (nombre.isNotEmpty && apellido.isNotEmpty) {
          setState(() {
            nombreUsuario = '$nombre $apellido';
          });
        }
      }

      // Cargar datos de inventario
      await _cargarDatos();

      print('Carga de datos completada');
    } catch (e) {
      print('Error en _cargarDatosIniciales: $e');
    } finally {
      setState(() {
        _initialLoading = false;
      });
    }
  }

  // Cargar todos los datos de la API usando el servicio
  Future<void> _cargarDatos() async {
    setState(() {
      _loading = true;
    });

    try {
      final datos = await _inventarioService.cargarTodosDatos();

      setState(() {
        productos = datos['productos'] ?? [];
        topProductos = datos['topProductos'] ?? [];
        estadisticas = datos['estadisticas'];
      });
    } catch (e) {
      print('Error al cargar inventario: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Color getColorCode(String? colorName) {
    if (colorName == null) return Colors.grey[300]!;
    return colorMap[colorName.toLowerCase().trim()] ?? Colors.grey[300]!;
  }

  void _recargarDatos() {
    _cargarDatos();
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              // Cerrar el AlertDialog
              Navigator.pop(context);

              if (mounted) {
                // Redirigir al HOME eliminando todo el historial
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
              }
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
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
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF800080), Color(0xFFE6C7F6)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 5,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Cargando Gestión de Inventario...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Por favor espera',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      body: Column(
        children: [
          HeaderLine(onLogout: _handleLogout),
          Container(
            color: const Color(0xFF800080),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                const Text(
                  'Gestión de Inventario',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
          const FooterLine(),
        ],
      ),
      drawer: _buildDrawer(),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInventarioCard(),
            const SizedBox(height: 16),
            _buildEstadisticasRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFFE6C7F6),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFFE6C7F6)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFF7E57C2),
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    nombreUsuario ?? 'Administrador',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.settings,
              title: 'Actualizar Datos',
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => const ActualizarDatosModal(),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.lock,
              title: 'Cambiar Contraseña',
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => const CambiarContrasenaModal(),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.person_add,
              title: 'Registro de Usuarios',
              onTap: () {
                Navigator.pushNamed(context, '/registro_usuarios');
              },
            ),
            _buildDrawerItem(
              icon: Icons.list,
              title: 'Listar Usuarios',
              onTap: () {
                Navigator.pushNamed(context, '/lista_usuarios');
              },
            ),

            const Divider(color: Colors.white30, thickness: 1),
            _buildDrawerItem(
              icon: Icons.badge,
              title: 'Empleados',
              onTap: () {
                Navigator.pushNamed(context, '/admin');
              },
            ),

            _buildDrawerItem(
              icon: Icons.inventory_2,
              title: 'Inventario',
              onTap: () => Navigator.pop(context),
              selected: true,
            ),
            _buildDrawerItem(
              icon: Icons.people_outline,
              title: 'Clientes',
              onTap: () {
                Navigator.pushNamed(context, '/admin_clientes');
              },
            ),

            const Divider(color: Colors.white30, thickness: 1),
            _buildDrawerItem(
              icon: Icons.badge,
              title: 'Registro productos',
              onTap: () {
                Navigator.pushNamed(context, '/registro_productos');
              },
            ),

            _buildDrawerItem(
              icon: Icons.manage_search,
              title: 'Administrar Productos',
              onTap: () {
                Navigator.pushNamed(context, '/lista_productos');
              },
            ),

            _buildDrawerItem(
              icon: Icons.manage_search,
              title: 'Administrar Movimientos',
              onTap: () {
                Navigator.pushNamed(context, '/lista_movimientos');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? const Color(0xFF4A148C) : Colors.white,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: selected ? const Color(0xFF4A148C) : Colors.white,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedTileColor: Colors.white.withOpacity(0.2),
      onTap: onTap,
    );
  }

  Widget _buildInventarioCard() {
    // Calcular paginación
    final totalPages = (productos.length / _itemsPerPage).ceil();
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage > productos.length)
        ? productos.length
        : startIndex + _itemsPerPage;
    final productosPaginados = productos.sublist(startIndex, endIndex);

    return Card(
      elevation: 2,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF7cbbe4),
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.inventory_2, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Inventario de Pijamas',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Botones apilados en móvil
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _recargarDatos,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Actualizar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A148C),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _loading
                          ? null
                          : () async {
                              await PdfDownloadService.descargarReporteInventario(
                                context,
                              );
                            },
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text('Generar Reporte PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A148C),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Contenido
          productos.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No hay productos registrados',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Lista de productos en cards (mejor para móvil)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      itemCount: productosPaginados.length,
                      itemBuilder: (context, index) {
                        final prod = productosPaginados[index];
                        final numeroSecuencial = startIndex + index + 1;
                        final numeroFormateado = numeroSecuencial
                            .toString()
                            .padLeft(3, '0');

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Número y nombre
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7cbbe4),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '#$numeroFormateado',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        prod['Nombre'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Color y Talla
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: getColorCode(
                                                prod['Color'],
                                              ),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.grey[300]!,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              prod['Color'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.blue[200]!,
                                        ),
                                      ),
                                      child: Text(
                                        'Talla ${prod['Talla'] ?? ''}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Stock y Precio
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Stock
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.inventory,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'Stock: ',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                (int.tryParse(
                                                          prod['Stock']
                                                                  ?.toString() ??
                                                              '0',
                                                        ) ??
                                                        0) >
                                                    10
                                                ? Colors.green
                                                : (int.tryParse(
                                                            prod['Stock']
                                                                    ?.toString() ??
                                                                '0',
                                                          ) ??
                                                          0) >
                                                      5
                                                ? Colors.orange
                                                : Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            prod['Stock'].toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Precio
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.attach_money,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        Text(
                                          _formatPrice(prod['Precio']),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF4A148C),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Controles de paginación
                    if (productos.length > _itemsPerPage)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border: Border(
                            top: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Mostrando ${startIndex + 1}-$endIndex de ${productos.length}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: _currentPage > 0
                                      ? () {
                                          setState(() {
                                            _currentPage--;
                                          });
                                        }
                                      : null,
                                  icon: const Icon(Icons.chevron_left),
                                  tooltip: 'Anterior',
                                  color: const Color(0xFF4A148C),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7cbbe4),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${_currentPage + 1} / $totalPages',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _currentPage < totalPages - 1
                                      ? () {
                                          setState(() {
                                            _currentPage++;
                                          });
                                        }
                                      : null,
                                  icon: const Icon(Icons.chevron_right),
                                  tooltip: 'Siguiente',
                                  color: const Color(0xFF4A148C),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ],
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '\$0';
    final priceStr = price.toString();
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return '\$${priceStr.replaceAllMapped(regex, (m) => '${m[1]}.')}';
  }

  Widget _buildEstadisticasRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildGraficoCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildTopProductosCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildCalendarioCard()),
            ],
          );
        } else {
          return Column(
            children: [
              _buildGraficoCard(),
              const SizedBox(height: 16),
              _buildTopProductosCard(),
              const SizedBox(height: 16),
              _buildCalendarioCard(),
            ],
          );
        }
      },
    );
  }

  Widget _buildGraficoCard() {
    final colors = [
      const Color(0xFF36a2eb),
      const Color(0xFFff6384),
      const Color(0xFFffcd56),
      const Color(0xFF4bc0c0),
      Colors.deepPurple,
    ];

    final porTalla = estadisticas?['porTalla'] as List<dynamic>? ?? [];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF7cbbe4),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Estadísticas por Talla',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: porTalla.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(Icons.info_outline, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'No hay estadísticas',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sections: porTalla.asMap().entries.map((entry) {
                          final total = porTalla.fold<double>(
                            0,
                            (sum, item) =>
                                sum +
                                (double.tryParse(
                                      item['Cantidad']?.toString() ?? '0',
                                    ) ??
                                    0),
                          );
                          final value =
                              double.tryParse(
                                entry.value['Cantidad']?.toString() ?? '0',
                              ) ??
                              0.0;
                          final percent = ((value / total) * 100)
                              .toStringAsFixed(1);

                          return PieChartSectionData(
                            value: value,
                            title: '${entry.value['Cantidad']}\n($percent%)',
                            color: colors[entry.key % colors.length],
                            radius: 90,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
          ),
          if (porTalla.isNotEmpty)
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: porTalla.asMap().entries.map((entry) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[entry.key % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('${entry.value['Talla']}'),
                  ],
                );
              }).toList(),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTopProductosCard() {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF7cbbe4),
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.emoji_events),
                SizedBox(width: 8),
                Text(
                  'Top 5 Productos más Vendidos',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          topProductos.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No hay datos suficientes',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: topProductos.length,
                  itemBuilder: (context, index) {
                    final prod = topProductos[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        prod['Nombre'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: getColorCode(prod['Color']),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${prod['Color'] ?? ''} - ${prod['Talla'] ?? ''}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          prod['UnidadesVendidas']?.toString() ?? '0',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildCalendarioCard() {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF7cbbe4),
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.calendar_month),
                SizedBox(width: 8),
                Text(
                  'Calendario',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarFormat: CalendarFormat.month,
              locale: 'es_CO',
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Color(0xFF7cbbe4),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Color(0xFF4A148C),
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: TextStyle(color: Colors.red),
                outsideDaysVisible: false,
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekendStyle: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
