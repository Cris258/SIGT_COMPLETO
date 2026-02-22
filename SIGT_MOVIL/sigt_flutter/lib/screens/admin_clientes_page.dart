import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cliente_service.dart';
import '../widgets/actualizar_datos_modal.dart';
import '../widgets/cambiar_contraseña_modal.dart';
import '../widgets/header_line.dart';
import '../widgets/footer_line.dart';
import 'admin_inventario_page.dart';
import 'admin_page.dart';
import '../services/pdf_download_service.dart';

class AdminClientesPage extends StatefulWidget {
  const AdminClientesPage({super.key});

  @override
  State<AdminClientesPage> createState() => _AdminClientesPageState();
}

class _AdminClientesPageState extends State<AdminClientesPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ClienteService _clienteService = ClienteService();

  bool loading = false;
  bool _initialLoading = true;
  String nombreUsuario = "Administrador";
  List<dynamic> clientes = [];
  List<dynamic> topClientes = [];
  Map<String, dynamic> estadisticas = {'porEstado': []};
  String? errorMessage;
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    try {
      print('Iniciando carga de datos iniciales...');

      final prefs = await SharedPreferences.getInstance();
      final currentUserJson = prefs.getString('current_user');

      if (currentUserJson != null) {
        try {
          final user = json.decode(currentUserJson);
          setState(() {
            nombreUsuario = user['correo'] ?? 'Administrador';
          });
          print('Usuario cargado: $nombreUsuario');
        } catch (e) {
          print('Error parseando usuario: $e');
        }
      }

      await _clienteService.debugTokenInfo();
      print('Iniciando carga de datos de la API...');
      await cargarDatos();

      print('Carga de datos completada');
    } catch (e) {
      print('Error en _cargarDatosIniciales: $e');
    } finally {
      setState(() {
        _initialLoading = false;
      });
    }
  }

  Future<void> cargarDatos() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      print('Cargando datos del backend...');
      final result = await _clienteService.cargarTodosDatos();

      print('Resultado recibido:');
      print(' - success: ${result['success']}');
      print(' - clientes: ${result['clientes']?.length ?? 0}');
      print(' - topClientes: ${result['topClientes']?.length ?? 0}');
      print(' - estadisticas: ${result['estadisticas']}');

      if (result['success']) {
        if (!mounted) return;

        setState(() {
          clientes = result['clientes'] ?? [];
          topClientes = result['topClientes'] ?? [];
          estadisticas = result['estadisticas'] ?? {'porEstado': []};
          loading = false;
        });

        print('Estado actualizado correctamente');
        print(' - clientes en estado: ${clientes.length}');
        print(' - topClientes en estado: ${topClientes.length}');

        if (result['errors'] != null && result['errors'].isNotEmpty) {
          final errors = result['errors'] as List;
          if (errors.isNotEmpty) {
            _mostrarError(errors.first);
          }
        }
      } else {
        if (!mounted) return;

        setState(() {
          loading = false;
          errorMessage = result['message'];
        });

        print('Error en resultado: ${result['message']}');

        if (result['message']?.contains('Sesión expirada') ?? false) {
          _mostrarDialogoSesionExpirada();
        } else {
          _mostrarError(result['message'] ?? 'Error desconocido');
        }
      }
    } catch (e, stackTrace) {
      print('EXCEPCIÓN en cargarDatos: $e');
      print('Stack trace: $stackTrace');

      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = 'Error: $e';
      });
      _mostrarError('Error cargando datos: $e');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _mostrarDialogoSesionExpirada() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Sesión Expirada'),
        content: const Text(
          'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Ir al Login'),
          ),
        ],
      ),
    );
  }

  void _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final nombre = prefs.getString('Primer_Nombre') ?? '';
    final apellido = prefs.getString('Primer_Apellido') ?? '';

    setState(() {
      nombreUsuario = "$nombre $apellido";
    });
  }

  Map<String, dynamic> getNivelCliente(dynamic compras) {
    int numCompras = 0;

    if (compras is int) {
      numCompras = compras;
    } else if (compras is String) {
      numCompras = int.tryParse(compras) ?? 0;
    } else if (compras is double) {
      numCompras = compras.toInt();
    }

    if (numCompras >= 10) {
      return {'nivel': 'VIP', 'color': Colors.amber, 'icono': Icons.star};
    }
    if (numCompras >= 5) {
      return {
        'nivel': 'Premium',
        'color': Colors.lightBlue,
        'icono': Icons.diamond,
      };
    }
    return {
      'nivel': 'Regular',
      'color': Colors.grey[600],
      'icono': Icons.person,
    };
  }

  String formatearPrecio(dynamic precio) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    if (precio == null) return '\$0';

    if (precio is String) {
      final numero = double.tryParse(precio) ?? 0;
      return formatter.format(numero);
    }

    return formatter.format(precio);
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

              Navigator.pop(context);

              if (mounted) {
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
                  'Cargando Panel de Clientes...',
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
      backgroundColor: Colors.grey[100],
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
                  'Panel de Clientes',
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
            child: loading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Cargando datos de clientes...'),
                      ],
                    ),
                  )
                : errorMessage != null
                ? _buildErrorWidget()
                : _buildContent(),
          ),
          const FooterLine(),
        ],
      ),
      drawer: _buildDrawer(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? 'Error al cargar datos',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: cargarDatos,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: cargarDatos,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClientesTable(),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildEstadisticas()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTopClientes()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildCalendario()),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildEstadisticas(),
                      const SizedBox(height: 16),
                      _buildTopClientes(),
                      const SizedBox(height: 16),
                      _buildCalendario(),
                    ],
                  );
                }
              },
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
                    nombreUsuario,
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminPage()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.inventory,
              title: 'Inventario',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminInventarioPage(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.people,
              title: 'Clientes',
              onTap: () => Navigator.pop(context),
              selected: true,
            ),
            const Divider(color: Colors.white30, thickness: 1),
            _buildDrawerItem(
              icon: Icons.manage_accounts,
              title: 'Administrar Clientes',
              onTap: () {
                Navigator.pushNamed(context, '/lista_clientes');
              },
            ),
            _buildDrawerItem(
              icon: Icons.shopping_cart,
              title: 'Administrar Carritos',
              onTap: () {
                Navigator.pushNamed(context, '/lista_carritos');
              },
            ),
            _buildDrawerItem(
              icon: Icons.point_of_sale,
              title: 'Administrar Ventas',
              onTap: () {
                Navigator.pushNamed(context, '/lista_ventas');
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

  Widget _buildClientesTable() {
    // Calcular paginación
    final totalPages = (clientes.length / _itemsPerPage).ceil();
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage > clientes.length)
        ? clientes.length
        : startIndex + _itemsPerPage;
    final clientesPaginados = clientes.sublist(startIndex, endIndex);

    return Card(
      elevation: 3,
      child: Column(
        children: [
          // Header responsive
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
                    Icon(Icons.people, size: 20, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Clientes y Compras',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Botones apilados verticalmente
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: loading ? null : cargarDatos,
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
                      onPressed: loading
                          ? null
                          : () async {
                              await PdfDownloadService.descargarReporteClientes(
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
          clientes.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No hay clientes registrados'),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Lista de clientes en cards (mejor para móvil)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      itemCount: clientesPaginados.length,
                      itemBuilder: (context, index) {
                        final cliente = clientesPaginados[index];
                        final numeroSecuencial = startIndex + index + 1;
                        final numeroFormateado = numeroSecuencial
                            .toString()
                            .padLeft(3, '0');
                        final nivel = getNivelCliente(cliente['TotalCompras']);
                        final totalCompras =
                            cliente['TotalCompras']?.toString() ?? '0';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Fila superior: Número y Nombre
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
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.person_outline,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              '${cliente['Nombre'] ?? ''} ${cliente['Apellido'] ?? ''}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Correo
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.email_outlined,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        cliente['Email'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // Teléfono
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone_outlined,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      cliente['Telefono'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Estadísticas en fila
                                Row(
                                  children: [
                                    // Compras
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFA8E6CF),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            const Icon(
                                              Icons.shopping_bag,
                                              size: 20,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              totalCompras,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const Text(
                                              'Compras',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Total Gastado
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[400],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            const Icon(
                                              Icons.attach_money,
                                              size: 20,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              formatearPrecio(
                                                cliente['TotalGastado'],
                                              ),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const Text(
                                              'Gastado',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Nivel y Estado
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Nivel
                                    Chip(
                                      avatar: Icon(
                                        nivel['icono'],
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        nivel['nivel'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      backgroundColor: nivel['color'],
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                    ),

                                    // Estado
                                    Chip(
                                      label: Text(
                                        cliente['Estado'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      backgroundColor:
                                          cliente['Estado'] == 'Activo'
                                          ? Colors.green
                                          : cliente['Estado'] == 'Inactivo'
                                          ? Colors.red
                                          : Colors.amber,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
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
                    if (clientes.length > _itemsPerPage)
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
                              'Mostrando ${startIndex + 1}-$endIndex de ${clientes.length}',
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

  Widget _buildEstadisticas() {
    final porEstado = estadisticas['porEstado'] as List? ?? [];

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart, size: 20),
                SizedBox(width: 8),
                Text(
                  'Estado de Clientes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            porEstado.isEmpty
                ? const Column(
                    children: [
                      Icon(Icons.info_outline, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No hay estadísticas disponibles'),
                    ],
                  )
                : Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: porEstado.map((item) {
                              final estado = item['Estado'];
                              final cantidad = item['Cantidad'];
                              Color color = Colors.grey;

                              if (estado == 'Activo') {
                                color = const Color(0xFF54E075);
                              }
                              if (estado == 'Inactivo') {
                                color = const Color(0xFFEE5666);
                              }
                              if (estado == 'Nuevo') {
                                color = const Color(0xFFFFD965);
                              }

                              return PieChartSectionData(
                                value: cantidad.toDouble(),
                                title: cantidad.toString(),
                                color: color,
                                radius: 50,
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList(),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...porEstado.map((item) {
                        final estado = item['Estado'];
                        final cantidad = item['Cantidad'];
                        Color color = Colors.grey;

                        if (estado == 'Activo') {
                          color = const Color(0xFF54E075);
                        }
                        if (estado == 'Inactivo') {
                          color = const Color(0xFFEE5666);
                        }
                        if (estado == 'Nuevo') {
                          color = const Color(0xFFFFD965);
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E7E7),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    estado,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              Chip(
                                label: Text(
                                  cantidad.toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: Colors.grey[600],
                                padding: const EdgeInsets.all(0),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopClientes() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.emoji_events, size: 24, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Top 5 Mejores Clientes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            topClientes.isEmpty
                ? const Column(
                    children: [
                      Icon(Icons.info_outline, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No hay datos suficientes'),
                    ],
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: topClientes.length > 5 ? 5 : topClientes.length,
                    itemBuilder: (context, index) {
                      final cliente = topClientes[index];
                      final nivel = getNivelCliente(cliente['TotalCompras']);
                      final totalCompras =
                          cliente['TotalCompras']?.toString() ?? '0';

                      IconData trofeo = Icons.emoji_events;
                      Color colorTrofeo = Colors.grey;

                      if (index == 0) {
                        trofeo = Icons.emoji_events;
                        colorTrofeo = Colors.amber;
                      } else if (index == 1) {
                        trofeo = Icons.military_tech;
                        colorTrofeo = Colors.grey[400]!;
                      } else if (index == 2) {
                        trofeo = Icons.military_tech;
                        colorTrofeo = Colors.brown[300]!;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundColor: colorTrofeo.withOpacity(0.2),
                            child: Icon(trofeo, color: colorTrofeo, size: 28),
                          ),
                          title: Row(
                            children: [
                              if (index < 3)
                                Icon(trofeo, size: 18, color: colorTrofeo),
                              if (index < 3) const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${cliente['Nombre'] ?? ''} ${cliente['Apellido'] ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                cliente['Email'] ?? '',
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Chip(
                                    label: Text(
                                      '$totalCompras compras',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                  Chip(
                                    avatar: Icon(
                                      nivel['icono'],
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    label: Text(
                                      nivel['nivel'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    backgroundColor: nivel['color'],
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Text(
                            formatearPrecio(cliente['TotalGastado']),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendario() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_today, size: 20),
                SizedBox(width: 8),
                Text(
                  'Calendario',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
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
          ],
        ),
      ),
    );
  }
}
