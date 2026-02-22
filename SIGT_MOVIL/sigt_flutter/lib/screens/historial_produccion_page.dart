import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../config/app_config.dart';
import '../widgets/header_line.dart';
import '../widgets/footer_line.dart';

class HistorialProduccionPage extends StatefulWidget {
  const HistorialProduccionPage({super.key});

  @override
  State<HistorialProduccionPage> createState() => _HistorialProduccionPageState();
}

class _HistorialProduccionPageState extends State<HistorialProduccionPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? token;
  int? idPersona;
  bool isLoading = false;
  bool _initialLoading = true;

  List<dynamic> tareasCompletadas = [];
  String? errorMessage;

  // Filtros
  String filtroSeleccionado = 'Todos';
  final TextEditingController _searchController = TextEditingController();

  // Estadísticas
  int totalTareasCompletadas = 0;
  int tareasHoy = 0;
  int tareasSemana = 0;
  int tareasMes = 0;

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
      
      // Obtener el ID del usuario logueado desde current_user
      final userJson = prefs.getString('current_user');
      if (userJson != null) {
        final userData = json.decode(userJson);
        // Intentar obtener idPersona primero, si no existe usar id
        idPersona = userData['idPersona'] ?? userData['id'];
        print('ID del usuario logueado: $idPersona');
        print('Datos del usuario: $userData');
      }

      if (token == null) {
        _mostrarError('No se encontró token de autenticación');
        return;
      }

      if (idPersona == null) {
        _mostrarError('No se encontró información del usuario');
        print('current_user data: $userJson');
        return;
      }

      await _cargarHistorial();
    } catch (e) {
      print('Error en _cargarDatos: $e');
      _mostrarError('Error al cargar datos: $e');
    } finally {
      setState(() {
        _initialLoading = false;
      });
    }
  }

  Future<void> _cargarHistorial() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Usar el endpoint específico del empleado igual que en EmpleadoPage
      final response = await http.get(
        Uri.parse(AppConfig.byId('tarea/empleado', idPersona)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Status: ${response.statusCode}');
      print('📡 URL: ${AppConfig.byId('tarea/empleado', idPersona)}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> todasLasTareas = data['body'] ?? [];

        // Filtrar solo las tareas completadas (el endpoint ya filtra por usuario)
        final completadas = todasLasTareas
            .where((t) => t['EstadoTarea'] == 'Completada')
            .toList();

        // Cargar datos adicionales para cada tarea completada
        for (var tarea in completadas) {
          // Obtener datos del Producto
          if (tarea['Producto_FK'] != null) {
            await _cargarProducto(tarea);
          }
          
          // Obtener datos de la Producción (CantidadProducida)
          await _cargarProduccion(tarea);
        }

        // Ordenar por fecha de completado (más reciente primero)
        completadas.sort((a, b) {
          final fechaA = DateTime.tryParse(a['updatedAt'] ?? '') ?? DateTime.now();
          final fechaB = DateTime.tryParse(b['updatedAt'] ?? '') ?? DateTime.now();
          return fechaB.compareTo(fechaA);
        });

        _calcularEstadisticas(completadas);

        setState(() {
          tareasCompletadas = completadas;
          isLoading = false;
        });

        print('Historial cargado: ${completadas.length} tareas completadas del usuario $idPersona');
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Error al cargar el historial';
        });
      }
    } catch (e) {
      print('Error en _cargarHistorial: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Error de conexión: $e';
      });
    }
  }

  Future<void> _cargarProducto(dynamic tarea) async {
    try {
      final productoId = tarea['Producto_FK'];
      print('Cargando producto con ID: $productoId');
      
      final url = Uri.parse(AppConfig.byId('producto', productoId));
      print('URL del producto: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Producto Response Status: ${response.statusCode}');
      print('Producto Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // El backend devuelve { ok: true, message: "...", body: producto }
        if (data['body'] != null) {
          tarea['Producto'] = data['body'];
          final nombreProducto = data['body']['NombreProducto'] ?? data['body']['Nombre'] ?? data['body']['nombre'] ?? 'Producto sin nombre';
          print('Producto cargado: $nombreProducto');
        } else {
          print('Respuesta sin campo body');
          tarea['Producto'] = null;
        }
      } else {
        print('Error al cargar producto: Status ${response.statusCode}');
        tarea['Producto'] = null;
      }
    } catch (e) {
      print('Excepción cargando producto: $e');
      tarea['Producto'] = null;
    }
  }

  Future<void> _cargarProduccion(dynamic tarea) async {
    try {
      final tareaId = tarea['idTarea'];
      // Buscar la producción asociada a esta tarea
      final response = await http.get(
        Uri.parse('${AppConfig.endpoint('produccion')}?Tarea_FK=$tareaId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final producciones = data['body'] as List?;
        
        if (producciones != null && producciones.isNotEmpty) {
          final produccion = producciones.first;
          tarea['CantidadProducida'] = produccion['CantidadProducida'];
          print('Producción cargada: ${produccion['CantidadProducida']} unidades');
        } else {
          tarea['CantidadProducida'] = 0;
        }
      }
    } catch (e) {
      print('Error cargando producción: $e');
      tarea['CantidadProducida'] = 0;
    }
  }

  void _calcularEstadisticas(List<dynamic> tareas) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final inicioSemana = hoy.subtract(Duration(days: ahora.weekday - 1));
    final inicioMes = DateTime(ahora.year, ahora.month, 1);

    totalTareasCompletadas = tareas.length;
    tareasHoy = 0;
    tareasSemana = 0;
    tareasMes = 0;

    for (var tarea in tareas) {
      // Intentar obtener la fecha de completado o updatedAt
      final fechaCompletado = DateTime.tryParse(
        tarea['FechaCompletado'] ?? tarea['updatedAt'] ?? ''
      );
      
      if (fechaCompletado != null) {
        if (fechaCompletado.isAfter(hoy)) {
          tareasHoy++;
        }
        if (fechaCompletado.isAfter(inicioSemana)) {
          tareasSemana++;
        }
        if (fechaCompletado.isAfter(inicioMes)) {
          tareasMes++;
        }
      }
    }
  }

  List<dynamic> _aplicarFiltros() {
    List<dynamic> tareasFiltradas = List.from(tareasCompletadas);

    // Aplicar filtro de tiempo
    final ahora = DateTime.now();
    switch (filtroSeleccionado) {
      case 'Hoy':
        final hoy = DateTime(ahora.year, ahora.month, ahora.day);
        tareasFiltradas = tareasFiltradas.where((t) {
          final fecha = DateTime.tryParse(t['FechaCompletado'] ?? '');
          return fecha != null && fecha.isAfter(hoy);
        }).toList();
        break;
      case 'Esta Semana':
        final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
        tareasFiltradas = tareasFiltradas.where((t) {
          final fecha = DateTime.tryParse(t['FechaCompletado'] ?? '');
          return fecha != null && fecha.isAfter(inicioSemana);
        }).toList();
        break;
      case 'Este Mes':
        final inicioMes = DateTime(ahora.year, ahora.month, 1);
        tareasFiltradas = tareasFiltradas.where((t) {
          final fecha = DateTime.tryParse(t['FechaCompletado'] ?? '');
          return fecha != null && fecha.isAfter(inicioMes);
        }).toList();
        break;
    }

    // Aplicar búsqueda
    final searchTerm = _searchController.text.toLowerCase();
    if (searchTerm.isNotEmpty) {
      tareasFiltradas = tareasFiltradas.where((t) {
        final descripcion = (t['Descripcion'] ?? '').toString().toLowerCase();
        final producto = (t['Producto']?['nombre'] ?? '').toString().toLowerCase();
        return descripcion.contains(searchTerm) || producto.contains(searchTerm);
      }).toList();
    }

    return tareasFiltradas;
  }

  void _mostrarDetallesTarea(dynamic tarea) {
    final descripcion = tarea['Descripcion'] ?? 'Sin descripción';
    final producto = tarea['Producto'];
    final nombreProducto = producto != null 
        ? (producto['NombreProducto'] ?? producto['Nombre'] ?? producto['nombre'] ?? 'N/A')
        : 'N/A';
    final cantidadProducida = tarea['CantidadProducida'] ?? 0;
    final fechaCompletado = tarea['FechaCompletado'] ?? tarea['updatedAt'];
    final prioridad = tarea['Prioridad'] ?? 'Media';
    final estadoTarea = tarea['EstadoTarea'] ?? 'Completada';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.assignment_turned_in, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Detalles de Producción',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Descripción', descripcion, Icons.description),
              const Divider(height: 24),
              
              _buildDetailRow('Producto', nombreProducto, Icons.inventory_2),
              if (producto != null && (producto['Color'] != null || producto['Talla'] != null || producto['Estampado'] != null))
                Row(
                  children: [
                    if (producto['Color'] != null) ...[
                      Expanded(
                        child: _buildDetailRow('Color', producto['Color'], Icons.palette, valueColor: Colors.black87),
                      ),
                    ],
                    if (producto['Talla'] != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDetailRow('Talla', producto['Talla'], Icons.straighten, valueColor: Colors.black87),
                      ),
                    ],
                  ],
                ),
              if (producto != null && producto['Estampado'] != null)
                _buildDetailRow('Estampado', producto['Estampado'], Icons.pattern, valueColor: Colors.black87),
              const Divider(height: 24),
              
              _buildDetailRow(
                'Estado',
                estadoTarea,
                Icons.flag,
                valueColor: Colors.green,
              ),
              _buildDetailRow(
                'Cantidad Producida',
                '$cantidadProducida unidades',
                Icons.production_quantity_limits,
              ),
              _buildDetailRow(
                'Prioridad',
                prioridad,
                Icons.priority_high,
                valueColor: _getPrioridadColor(prioridad),
              ),
              
              if (fechaCompletado != null) ...[
                const Divider(height: 24),
                _buildDetailRow(
                  'Completado',
                  _formatearFecha(fechaCompletado),
                  Icons.check_circle,
                  valueColor: Colors.green,
                ),
              ] else if (tarea['updatedAt'] != null) ...[
                const Divider(height: 24),
                _buildDetailRow(
                  'Actualizado',
                  _formatearFecha(tarea['updatedAt']),
                  Icons.update,
                  valueColor: Colors.blue,
                ),
              ],
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

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatearFecha(String? fecha) {
    if (fecha == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(fecha);
      final ahora = DateTime.now();
      final diferencia = ahora.difference(dateTime);

      if (diferencia.inDays == 0) {
        final formato = DateFormat('HH:mm');
        return 'Hoy a las ${formato.format(dateTime)}';
      } else if (diferencia.inDays == 1) {
        final formato = DateFormat('HH:mm');
        return 'Ayer a las ${formato.format(dateTime)}';
      } else if (diferencia.inDays < 7) {
        return 'Hace ${diferencia.inDays} días';
      } else {
        final formato = DateFormat('dd/MM/yyyy HH:mm');
        return formato.format(dateTime);
      }
    } catch (e) {
      return 'N/A';
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

    final tareasFiltradas = _aplicarFiltros();

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
                  'Historial de Producción',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: isLoading ? null : _cargarHistorial,
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? _buildErrorWidget()
                    : _buildContent(tareasFiltradas),
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
            onPressed: _cargarHistorial,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<dynamic> tareasFiltradas) {
    return RefreshIndicator(
      onRefresh: _cargarHistorial,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estadísticas
            _buildEstadisticas(),
            const SizedBox(height: 24),

            // Filtros
            _buildFiltros(),
            const SizedBox(height: 16),

            // Barra de búsqueda
            _buildSearchBar(),
            const SizedBox(height: 24),

            // Lista de tareas
            if (tareasFiltradas.isEmpty)
              _buildEmptyState()
            else
              _buildListaTareas(tareasFiltradas),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticas() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Resumen de Producción',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildEstadisticaCard(
                  'Total',
                  totalTareasCompletadas,
                  Icons.check_circle,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEstadisticaCard(
                  'Hoy',
                  tareasHoy,
                  Icons.today,
                  Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildEstadisticaCard(
                  'Esta Semana',
                  tareasSemana,
                  Icons.date_range,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEstadisticaCard(
                  'Este Mes',
                  tareasMes,
                  Icons.calendar_month,
                  Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticaCard(String label, int valor, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            '$valor',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    final filtros = ['Todos', 'Hoy', 'Esta Semana', 'Este Mes'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filtros.map((filtro) {
          final isSelected = filtroSeleccionado == filtro;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filtro),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  filtroSeleccionado = filtro;
                });
              },
              selectedColor: const Color(0xFF7B2CBF),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Buscar por descripción o producto...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[100],
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
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay tareas completadas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Completa tus primeras tareas de producción para ver el historial aquí',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListaTareas(List<dynamic> tareas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${tareas.length} ${tareas.length == 1 ? 'tarea' : 'tareas'} ${tareas.length == 1 ? 'encontrada' : 'encontradas'}',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tareas.length,
          itemBuilder: (context, index) {
            return _buildTareaCard(tareas[index]);
          },
        ),
      ],
    );
  }

  Widget _buildTareaCard(dynamic tarea) {
    final descripcion = tarea['Descripcion'] ?? 'Sin descripción';
    final producto = tarea['Producto'];
    final nombreProducto = producto != null 
        ? (producto['NombreProducto'] ?? producto['Nombre'] ?? producto['nombre'] ?? 'N/A')
        : 'N/A';
    final cantidadProducida = tarea['CantidadProducida'] ?? 0;
    final fechaCompletado = tarea['FechaCompletado'] ?? tarea['updatedAt'];
    final prioridad = tarea['Prioridad'] ?? 'Media';
    final estadoTarea = tarea['EstadoTarea'] ?? 'Completada';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _mostrarDetallesTarea(tarea),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          descripcion,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nombreProducto,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            estadoTarea,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPrioridadColor(prioridad),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      prioridad,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.production_quantity_limits, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    '$cantidadProducida unidades',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    _formatearFecha(fechaCompletado),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}