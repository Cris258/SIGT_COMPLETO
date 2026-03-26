import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/admin_service.dart';
import '../widgets/header_line.dart';
import '../widgets/footer_line.dart';
import '../widgets/actualizar_datos_modal.dart';
import '../widgets/cambiar_contraseña_modal.dart';
import '../services/pdf_download_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AdminService _adminService = AdminService();

  String? nombreUsuario = "Administrador";
  bool isLoading = false;
  bool _initialLoading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<dynamic> empleados = [];
  List<dynamic> topEmpleados = [];
  Map<String, dynamic> estadisticas = {'general': []};
  String? errorMessage;
  int _currentPage = 0;
  final int _itemsPerPage = 10;

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
        }
      }

      await _adminService.debugTokenInfo();

      print('Iniciando carga de datos de la API...');
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

  Future<void> _cargarDatos() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      print('Cargando datos del backend...');
      final result = await _adminService.cargarTodosDatos();

      print('Resultado recibido:');
      print(' - success: ${result['success']}');
      print(' - empleados: ${result['empleados']?.length ?? 0}');
      print(' - topEmpleados: ${result['topEmpleados']?.length ?? 0}');
      print(' - estadisticas: ${result['estadisticas']}');

      if (result['success']) {
        if (!mounted) return;

        setState(() {
          empleados = result['empleados'] ?? [];
          topEmpleados = result['topEmpleados'] ?? [];
          estadisticas = result['estadisticas'] ?? {'general': []};
          isLoading = false;
        });

        print('Estado actualizado correctamente');
        print(' - empleados en estado: ${empleados.length}');
        print(' - topEmpleados en estado: ${topEmpleados.length}');

        if (result['errors'] != null && result['errors'].isNotEmpty) {
          final errors = result['errors'] as List;
          if (errors.isNotEmpty) {
            _mostrarError(errors.first);
          }
        }
      } else {
        if (!mounted) return;

        setState(() {
          isLoading = false;
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
      print('EXCEPCIÓN en _cargarDatos: $e');
      print('Stack trace: $stackTrace');

      if (!mounted) return;

      setState(() {
        isLoading = false;
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

  int _calcularProgreso(int hechas, int total) {
    if (total == 0) return 0;
    return ((hechas / total) * 100).round();
  }

  Color _getColorProgreso(int progreso) {
    if (progreso >= 75) return Colors.green;
    if (progreso >= 50) return Colors.blue;
    if (progreso >= 25) return Colors.orange;
    return Colors.red;
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'Completada':
        return const Color(0xFF54e075);
      case 'En Progreso':
        return const Color(0xFFffd965);
      case 'Pendiente':
        return const Color(0xFFee5666);
      case 'Cancelada':
        return Colors.grey;
      default:
        return Colors.blue;
    }
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

  void _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final nombre = prefs.getString('Primer_Nombre') ?? '';
    final apellido = prefs.getString('Primer_Apellido') ?? '';

    setState(() {
      nombreUsuario = "$nombre $apellido";
    });
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
                  'Cargando Panel de Administración...',
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
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                const Text(
                  'Panel de Administración',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
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
            onPressed: _cargarDatos,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
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
              onTap: () => Navigator.pop(context),
              selected: true,
            ),
            _buildDrawerItem(
              icon: Icons.inventory,
              title: 'Inventario',
              onTap: () {
                Navigator.pushNamed(context, '/admin_inventario');
              },
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
              icon: Icons.manage_accounts,
              title: 'Administrar Empleados',
              onTap: () {
                Navigator.pushNamed(context, '/lista_empleados');
              },
            ),
            _buildDrawerItem(
              icon: Icons.assignment_add,
              title: 'Asignar Tareas',
              onTap: () {
                Navigator.pushNamed(context, '/registro_tareas');
              },
            ),
            _buildDrawerItem(
              icon: Icons.task,
              title: 'Administrar Tareas',
              onTap: () {
                Navigator.pushNamed(context, '/lista_tareas');
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

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEmpleadosCard(),
            const SizedBox(height: 16),
            _buildStatsRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpleadosCard() {
    // PROTECCIÓN: si no hay empleados, mostrar mensaje
    if (empleados.isEmpty) {
      return Card(
        elevation: 2,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF7cbbe4),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.people, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Empleados y Tareas',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: isLoading ? null : _cargarDatos,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Actualizar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A148C),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No hay empleados registrados'),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // PROTECCIÓN: resetear página si está fuera de rango
    final totalPages = (empleados.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages) {
      _currentPage = 0;
    }

    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage > empleados.length)
        ? empleados.length
        : startIndex + _itemsPerPage;

    // PROTECCIÓN: verificar que los índices sean válidos
    if (startIndex >= empleados.length) {
      _currentPage = 0;
      return const Center(child: CircularProgressIndicator());
    }

    final empleadosPaginados = empleados.sublist(startIndex, endIndex);

    return Card(
      elevation: 2,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF7cbbe4),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.people, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Empleados y Tareas',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : _cargarDatos,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Actualizar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A148C),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () async {
                              await PdfDownloadService.descargarReporteEmpleados(
                                context,
                              );
                            },
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text('Generar Reporte'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A148C),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
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
          Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(
                      label: Text(
                        'N°',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(label: Text('Empleado')),
                    DataColumn(label: Text('Rol')),
                    DataColumn(label: Text('Hechas')),
                    DataColumn(label: Text('Pendientes')),
                    DataColumn(label: Text('Total')),
                    DataColumn(label: Text('Progreso')),
                  ],
                  rows: empleadosPaginados.asMap().entries.map((entry) {
                    final index = entry.key;
                    final emp = entry.value;
                    final numeroSecuencial = startIndex + index + 1;
                    final numeroFormateado = numeroSecuencial
                        .toString()
                        .padLeft(3, '0');
                    final tareasHechas =
                        int.tryParse(emp['TareasHechas']?.toString() ?? '0') ??
                        0;
                    final totalTareas =
                        int.tryParse(emp['TotalTareas']?.toString() ?? '0') ??
                        0;
                    final progreso = _calcularProgreso(
                      tareasHechas,
                      totalTareas,
                    );
                    return DataRow(
                      cells: [
                        DataCell(
                          Center(
                            child: Text(
                              numeroFormateado,
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 16),
                              const SizedBox(width: 4),
                              Text(emp['Empleado']?.toString() ?? ''),
                            ],
                          ),
                        ),
                        DataCell(Text(emp['Rol']?.toString() ?? '')),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA8E6CF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('$tareasHechas'),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB6B9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${int.tryParse(emp['Pendientes']?.toString() ?? '0') ?? 0}',
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '$totalTareas',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 100,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                LinearProgressIndicator(
                                  value: progreso.toDouble() / 100,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getColorProgreso(progreso),
                                  ),
                                  minHeight: 20,
                                ),
                                Text(
                                  '$progreso%',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              if (empleados.length > _itemsPerPage)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border(top: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mostrando ${startIndex + 1}-$endIndex de ${empleados.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
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
                            color: const Color(0xFF4A148C),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7cbbe4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Página ${_currentPage + 1} de $totalPages',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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

  Widget _buildStatsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildEstadisticasCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildTopEmpleadosCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildCalendarioCard()),
            ],
          );
        } else {
          return Column(
            children: [
              _buildEstadisticasCard(),
              const SizedBox(height: 16),
              _buildTopEmpleadosCard(),
              const SizedBox(height: 16),
              _buildCalendarioCard(),
            ],
          );
        }
      },
    );
  }

  Widget _buildEstadisticasCard() {
    final generalStats = estadisticas['general'] as List? ?? [];

    return Card(
      elevation: 2,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF7cbbe4),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.bar_chart, size: 20),
                SizedBox(width: 8),
                Text(
                  'Estadísticas de Tareas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: generalStats.isEmpty
                ? const Column(
                    children: [
                      Icon(Icons.info_outline, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No hay tareas registradas'),
                    ],
                  )
                : Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: generalStats.map((item) {
                              return PieChartSectionData(
                                value: double.tryParse(item['Cantidad']?.toString() ?? '0') ?? 0.0,
                                title: '${item['Cantidad']}',
                                color: _getColorEstado(item['EstadoTarea']),
                                radius: 50,
                                titleStyle: const TextStyle(
                                  fontSize: 14,
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
                      const SizedBox(height: 16),
                      ...generalStats.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
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
                                        color: _getColorEstado(
                                          item['EstadoTarea'],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(item['EstadoTarea'] ?? ''),
                                  ],
                                ),
                                Chip(
                                  label: Text('${item['Cantidad']}'),
                                  backgroundColor: Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopEmpleadosCard() {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF7cbbe4),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.emoji_events, size: 20),
                SizedBox(width: 8),
                Text(
                  'Top 5 Empleados',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          topEmpleados.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No hay datos suficientes'),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(8),
                  itemCount: topEmpleados.length > 5 ? 5 : topEmpleados.length,
                  itemBuilder: (context, index) {
                    final emp = topEmpleados[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: index == 0
                              ? Colors.amber
                              : index == 1
                              ? Colors.grey
                              : Colors.brown,
                          child: index == 0
                              ? const Icon(
                                  Icons.emoji_events,
                                  color: Colors.white,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                        ),
                        title: Text(
                          emp['NombreEmpleado'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(emp['NombreRol'] ?? ''),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              children: [
                                Chip(
                                  label: Text(
                                    '✓ ${emp['TareasCompletadas']}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  backgroundColor: Colors.green[100],
                                  visualDensity: VisualDensity.compact,
                                ),
                                Chip(
                                  label: Text(
                                    '⏳ ${emp['TareasEnProgreso']}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  backgroundColor: Colors.orange[100],
                                  visualDensity: VisualDensity.compact,
                                ),
                                Chip(
                                  label: Text(
                                    '! ${emp['TareasPendientes']}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  backgroundColor: Colors.red[100],
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ],
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
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.calendar_month, size: 20),
                SizedBox(width: 8),
                Text(
                  'Calendario',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
