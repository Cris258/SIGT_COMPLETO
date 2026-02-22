import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../widgets/header_line.dart';
import '../widgets/footer_line.dart';

class RegistrarProduccionPage extends StatefulWidget {
  const RegistrarProduccionPage({super.key});

  @override
  State<RegistrarProduccionPage> createState() => _RegistrarProduccionPageState();
}

class _RegistrarProduccionPageState extends State<RegistrarProduccionPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? token;
  bool isLoading = false;
  bool _initialLoading = true;

  List<dynamic> tareasPendientes = [];
  List<dynamic> tareasEnProgreso = [];
  String? errorMessage;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _initialLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('auth_token');

      if (token == null) {
        _mostrarError('No se encontró token de autenticación');
        return;
      }

      await _cargarTareas();
    } catch (e) {
      print(' Error en _cargarDatos: $e');
      _mostrarError('Error al cargar datos: $e');
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
      final response = await http.get(
        Uri.parse(AppConfig.endpoint('tarea')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> todasLasTareas = data['body'] ?? [];

        setState(() {
          tareasPendientes = todasLasTareas
              .where((t) => t['EstadoTarea'] == 'Pendiente')
              .toList();
          tareasEnProgreso = todasLasTareas
              .where((t) => t['EstadoTarea'] == 'En Progreso')
              .toList();
          isLoading = false;
        });

        print(' Tareas cargadas: ${tareasPendientes.length} pendientes, ${tareasEnProgreso.length} en progreso');
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Error al cargar tareas';
        });
      }
    } catch (e) {
      print(' Error en _cargarTareas: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Error de conexión: $e';
      });
    }
  }

  Future<void> _cambiarEstado(int idTarea, String nuevoEstado) async {
    try {
      print('🔄 Cambiando estado de tarea $idTarea a $nuevoEstado');

      final response = await http.put(
        Uri.parse(AppConfig.byId('tarea', idTarea)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'EstadoTarea': nuevoEstado,
        }),
      );

      print(' Status: ${response.statusCode}');
      print(' Response: ${response.body}');

      if (response.statusCode == 200) {
        _mostrarExito('Estado actualizado correctamente');
        await _cargarTareas(); // Recargar tareas
      } else {
        final error = json.decode(response.body);
        _mostrarError(error['Message'] ?? 'Error al actualizar estado');
      }
    } catch (e) {
      print(' Error en _cambiarEstado: $e');
      _mostrarError('Error al cambiar estado: $e');
    }
  }

  Future<void> _completarTarea(int idTarea) async {
    setState(() {
      isLoading = true;
    });

    try {
      print(' Completando tarea $idTarea');

      final response = await http.put(
        Uri.parse(AppConfig.byId('tarea', '$idTarea/completar')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print(' Status: ${response.statusCode}');
      print(' Response: ${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        
        _mostrarDialogoExito(result);
        await _cargarTareas();
      } else {
        final error = json.decode(response.body);
        _mostrarError(error['message'] ?? 'Error al completar tarea');
      }
    } catch (e) {
      print(' Error en _completarTarea: $e');
      _mostrarError('Error al completar tarea: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _mostrarDialogoExito(Map<String, dynamic> result) {
    final data = result['data'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('¡Producción Completada!'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Producto', data['producto']['nombre'] ?? 'N/A'),
              _buildInfoRow('Cantidad Producida', '${data['cantidadProducida']} unidades'),
              _buildInfoRow('Stock Anterior', '${data['stock']['anterior']}'),
              _buildInfoRow('Stock Nuevo', '${data['stock']['nuevo']}'),
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'El stock se ha actualizado automáticamente',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
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

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmarCambioEstado(int idTarea, String estadoActual, String nuevoEstado) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar Cambio de Estado'),
        content: Text(
          '¿Deseas cambiar el estado de "$estadoActual" a "$nuevoEstado"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cambiarEstado(idTarea, nuevoEstado);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B2CBF),
            ),
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmarCompletarTarea(int idTarea, String descripcion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green),
            SizedBox(width: 8),
            Text('Completar Tarea'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Estás seguro de completar esta tarea?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              descripcion,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esto actualizará el stock automáticamente',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completarTarea(idTarea);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Completar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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

  Color _getPrioridadColor(String? prioridad) {
    switch (prioridad) {
      case 'Alta':
      case 'Urgente':
        return const Color(0xFFee5666);
      case 'Media':
        return const Color(0xFFffd965);
      case 'Baja':
        return const Color(0xFF54e075);
      default:
        return Colors.grey;
    }
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Registrar Producción',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: isLoading ? null : _cargarTareas,
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

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _cargarTareas,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tareas Pendientes
            _buildSeccionTareas(
              'Tareas Pendientes',
              tareasPendientes,
              Colors.orange,
              Icons.pending_actions,
              'Pendiente',
            ),
            const SizedBox(height: 24),

            // Tareas En Progreso
            _buildSeccionTareas(
              'Tareas En Progreso',
              tareasEnProgreso,
              Colors.blue,
              Icons.autorenew,
              'En Progreso',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionTareas(
    String titulo,
    List<dynamic> tareas,
    Color color,
    IconData icon,
    String estadoActual,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${tareas.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        tareas.isEmpty
            ? _buildEmptyState(estadoActual)
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tareas.length,
                itemBuilder: (context, index) {
                  return _buildTareaCard(tareas[index], estadoActual);
                },
              ),
      ],
    );
  }

  Widget _buildEmptyState(String estado) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'No hay tareas $estado',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTareaCard(dynamic tarea, String estadoActual) {
    final idTarea = tarea['idTarea'];
    final descripcion = tarea['Descripcion'] ?? 'Sin descripción';
    final prioridad = tarea['Prioridad'] ?? 'Media';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    descripcion,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (estadoActual == 'Pendiente')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmarCambioEstado(
                        idTarea,
                        'Pendiente',
                        'En Progreso',
                      ),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Iniciar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (estadoActual == 'En Progreso') ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmarCambioEstado(
                        idTarea,
                        'En Progreso',
                        'Pendiente',
                      ),
                      icon: const Icon(Icons.pause, size: 18),
                      label: const Text('Pausar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmarCompletarTarea(
                        idTarea,
                        descripcion,
                      ),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Completar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}