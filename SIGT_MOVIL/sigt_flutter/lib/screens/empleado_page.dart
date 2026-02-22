import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/empleado_service.dart';
import '../widgets/header_line.dart';
import '../widgets/footer_line.dart';
import '../widgets/actualizar_datos_modal.dart';
import '../widgets/cambiar_contraseña_modal.dart';
import '../services/pdf_download_service.dart';

class EmpleadoPage extends StatefulWidget {
  const EmpleadoPage({super.key});

  @override
  State<EmpleadoPage> createState() => _EmpleadoPageState();
}

class _EmpleadoPageState extends State<EmpleadoPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final EmpleadoService _empleadoService = EmpleadoService();

  String? nombreUsuario = "Empleado";
  bool isLoading = false;
  bool _initialLoading = true;

  List<dynamic> tareas = [];
  List<dynamic> tareasFiltradas = [];
  String? errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              nombreUsuario = user['correo'] ?? 'Empleado';
            }
          });
          print('Usuario cargado: $nombreUsuario');
        } catch (e) {
          print('Error parseando usuario: $e');
        }
      }

      if (nombreUsuario == "Empleado") {
        final nombre = prefs.getString('Primer_Nombre') ?? '';
        final apellido = prefs.getString('Primer_Apellido') ?? '';
        if (nombre.isNotEmpty && apellido.isNotEmpty) {
          setState(() {
            nombreUsuario = '$nombre $apellido';
          });
        }
      }

      await _empleadoService.debugTokenInfo();
      await _cargarTareas();

      print('Carga de datos completada');
    } catch (e) {
      print('Error en _cargarDatosIniciales: $e');
    } finally {
      setState(() {
        _initialLoading = false;
      });
    }
  }

  Future<void> _cargarTareas() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      print('Cargando tareas del empleado...');
      final result = await _empleadoService.obtenerTareasEmpleado();

      if (result['success']) {
        if (!mounted) return;

        setState(() {
          tareas = result['data'] ?? [];
          _ordenarYFiltrarTareas();
          isLoading = false;
        });

        print('Estado actualizado correctamente');
      } else {
        if (!mounted) return;

        setState(() {
          isLoading = false;
          errorMessage = result['message'];
        });

        if (result['message']?.contains('Sesión expirada') ?? false) {
          _mostrarDialogoSesionExpirada();
        } else {
          _mostrarError(result['message'] ?? 'Error desconocido');
        }
      }
    } catch (e, stackTrace) {
      print('EXCEPCIÓN en _cargarTareas: $e');
      print('Stack trace: $stackTrace');

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Error: $e';
      });
      _mostrarError('Error cargando tareas: $e');
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

  void _ordenarYFiltrarTareas() {
    List<dynamic> tareasOrdenadas = List.from(tareas);

    tareasOrdenadas.sort((a, b) {
      final estadoA = a['EstadoTarea'] ?? 'Pendiente';
      final estadoB = b['EstadoTarea'] ?? 'Pendiente';

      int getPrioridadEstado(String estado) {
        switch (estado) {
          case 'Pendiente':
            return 1;
          case 'En Progreso':
            return 2;
          case 'Completada':
            return 3;
          default:
            return 4;
        }
      }

      final prioridadA = getPrioridadEstado(estadoA);
      final prioridadB = getPrioridadEstado(estadoB);

      if (prioridadA != prioridadB) {
        return prioridadA.compareTo(prioridadB);
      }

      if (estadoA == 'Pendiente' || estadoA == 'En Progreso') {
        final fechaA = a['FechaLimite'];
        final fechaB = b['FechaLimite'];

        if (fechaA != null && fechaB != null) {
          try {
            return DateTime.parse(fechaA).compareTo(DateTime.parse(fechaB));
          } catch (e) {
            return 0;
          }
        }
      }

      return 0;
    });

    if (_searchQuery.isEmpty) {
      tareasFiltradas = tareasOrdenadas;
    } else {
      tareasFiltradas = tareasOrdenadas.where((tarea) {
        final descripcion = (tarea['Descripcion'] ?? '')
            .toString()
            .toLowerCase();
        final estado = (tarea['EstadoTarea'] ?? '').toString().toLowerCase();
        final prioridad = (tarea['Prioridad'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();

        return descripcion.contains(query) ||
            estado.contains(query) ||
            prioridad.contains(query);
      }).toList();
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _ordenarYFiltrarTareas();
    });
  }

  Color _getPrioridadColor(String? prioridad) {
    switch (prioridad) {
      case 'Alta':
        return const Color(0xFFee5666);
      case 'Media':
        return const Color(0xFFffd965);
      case 'Baja':
        return const Color(0xFF54e075);
      default:
        return Colors.grey;
    }
  }

  Color _getEstadoColor(String? estado) {
    switch (estado) {
      case 'Completada':
        return const Color(0xFF54e075);
      case 'En Progreso':
        return const Color(0xFFffd965);
      case 'Pendiente':
        return const Color(0xFFee5666);
      default:
        return Colors.grey;
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
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                  'Panel de Empleado',
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
            onPressed: _cargarTareas,
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
                    nombreUsuario ?? 'Empleado',
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
            const Divider(color: Colors.white54),
            _buildDrawerItem(
              icon: Icons.factory,
              title: 'Registrar Producción',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/registrar_produccion');
              },
            ),
            _buildDrawerItem(
              icon: Icons.history,
              title: 'Historial de Producción',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/historial_produccion');
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
      onRefresh: _cargarTareas,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: _buildTareasCard(),
      ),
    );
  }

  Widget _buildTareasCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF7cbbe4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Si el ancho es menor a 600px, mostramos diseño vertical
              final bool esMovil = constraints.maxWidth < 550;

              if (esMovil) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título y botón de refrescar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.task_alt, size: 24, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Mis Tareas',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: isLoading ? null : _cargarTareas,
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          tooltip: 'Actualizar',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Botón de generar reporte en toda la fila
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () async {
                                await PdfDownloadService.descargarReporteMisTareas(
                                  context,
                                );
                              },
                        icon: const Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Generar Reporte PDF',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF7cbbe4),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              // Diseño horizontal para escritorio
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.task_alt, size: 24, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Mis Tareas',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: isLoading ? null : _cargarTareas,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        tooltip: 'Actualizar',
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () async {
                                await PdfDownloadService.descargarReporteMisTareas(
                                  context,
                                );
                              },
                        icon: const Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Generar Reporte',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF7cbbe4),
                          elevation: 0,
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
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        if (tareas.isNotEmpty) _buildSearchBar(),
        if (tareas.isNotEmpty) const SizedBox(height: 16),
        if (tareas.isNotEmpty) _buildTareasStats(),
        const SizedBox(height: 16),

        tareasFiltradas.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tareasFiltradas.length,
                itemBuilder: (context, index) {
                  final tarea = tareasFiltradas[index];
                  return _buildTareaCard(tarea, index);
                },
              ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Buscar tareas...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTareasStats() {
    final pendientes = tareasFiltradas
        .where((t) => t['EstadoTarea'] == 'Pendiente')
        .length;
    final enProgreso = tareasFiltradas
        .where((t) => t['EstadoTarea'] == 'En Progreso')
        .length;
    final completadas = tareasFiltradas
        .where((t) => t['EstadoTarea'] == 'Completada')
        .length;

    return Row(
      children: [
        Expanded(
          child: _buildStatChip(
            'Pendientes',
            pendientes,
            const Color(0xFFee5666),
            Icons.pending_actions,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatChip(
            'En Progreso',
            enProgreso,
            const Color(0xFFffd965),
            Icons.autorenew,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatChip(
            'Completadas',
            completadas,
            const Color(0xFF54e075),
            Icons.check_circle,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            _searchQuery.isNotEmpty
                ? Icons.search_off
                : Icons.assignment_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No se encontraron tareas'
                : 'No tienes tareas asignadas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTareaCard(dynamic tarea, int index) {
    final estadoActual = tarea['EstadoTarea'] ?? 'Pendiente';
    final prioridad = tarea['Prioridad'] ?? 'Media';
    final numeroFormateado = (index + 1).toString().padLeft(3, '0');

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getEstadoColor(estadoActual).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _mostrarDetallesTarea(tarea),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      numeroFormateado,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildPrioridadChip(prioridad),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                tarea['Descripcion'] ?? 'Sin descripción',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getEstadoColor(estadoActual).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _getEstadoColor(estadoActual).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getEstadoIcon(estadoActual),
                      size: 18,
                      color: _getEstadoColor(estadoActual),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      estadoActual,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getEstadoColor(estadoActual),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado) {
      case 'Completada':
        return Icons.check_circle;
      case 'En Progreso':
        return Icons.autorenew;
      case 'Pendiente':
        return Icons.pending_actions;
      default:
        return Icons.help;
    }
  }

  Widget _buildPrioridadChip(String prioridad) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getPrioridadColor(prioridad),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        prioridad,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  void _mostrarDetallesTarea(dynamic tarea) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detalles de la Tarea',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 32),
                _buildDetailRow('Descripción', tarea['Descripcion'] ?? 'N/A'),
                const SizedBox(height: 16),
                _buildDetailRow('Estado', tarea['EstadoTarea'] ?? 'Pendiente'),
                const SizedBox(height: 16),
                _buildDetailRow('Prioridad', tarea['Prioridad'] ?? 'Media'),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'Fecha Asignación',
                  tarea['FechaAsignacion'] != null
                      ? _formatDate(tarea['FechaAsignacion'])
                      : 'N/A',
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'Fecha Límite',
                  tarea['FechaLimite'] != null
                      ? _formatDate(tarea['FechaLimite'])
                      : 'N/A',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}
