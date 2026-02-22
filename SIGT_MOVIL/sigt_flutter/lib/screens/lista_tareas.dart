import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/header_widget.dart';
import '../widgets/footer_line.dart';
import '../widgets/widgetsAdmin/modal_editar_tarea.dart';
import '../widgets/widgetsAdmin/modal_eliminar_tarea.dart';
import '../models/tarea.dart';
import '../models/persona.dart';
import '../config/app_config.dart';
import '../services/pdf_download_service.dart';

class ListaTareas extends StatefulWidget {
  const ListaTareas({super.key});

  @override
  State<ListaTareas> createState() => _ListaTareasState();
}

class _ListaTareasState extends State<ListaTareas> {
  bool isLoading = true;
  String search = "";
  final TextEditingController searchController = TextEditingController();
  List<Tarea> tareas = [];
  Map<int, Persona> personas = {};
  String? token;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> cargarDatos() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('auth_token');

      if (token == null) {
        _mostrarError('No se encontró token de autenticación');
        return;
      }

      // Cargar personas y tareas en paralelo
      await Future.wait([cargarPersonas(), cargarTareas()]);

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      _mostrarError('Error al cargar datos: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> cargarPersonas() async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.endpoint('persona')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> personasJson = data['body'] ?? [];

        // Convertir lista a Map para lookup rápido por ID
        for (var json in personasJson) {
          final persona = Persona.fromJson(json);
          if (persona.idPersona != null) {
            personas[persona.idPersona!] = persona;
          }
        }
      } else {
        print('Error al obtener personas: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al cargar personas: $e');
    }
  }

  Future<void> cargarTareas() async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.endpoint('tarea')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> tareasJson = data['body'] ?? [];

        tareas = tareasJson.map((json) => Tarea.fromJson(json)).toList();
      } else {
        _mostrarError('Error al obtener tareas: ${response.statusCode}');
      }
    } catch (e) {
      _mostrarError('Error al cargar tareas: $e');
    }
  }

  void _mostrarError(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
      );
    }
  }

  String obtenerNombreEmpleado(int personaFk) {
    final persona = personas[personaFk];
    if (persona != null) {
      return '${persona.primerNombre} ${persona.primerApellido}';
    }
    return 'N/A';
  }

  List<Tarea> get tareasFiltradas {
    List<Tarea> resultado;

    if (search.isEmpty) {
      resultado = List.from(tareas);
    } else {
      resultado = tareas.where((tarea) {
        final descripcion = (tarea.descripcion ?? '').toLowerCase();
        final prioridad = tarea.prioridad.toLowerCase();
        final estado = tarea.estadoTarea.toLowerCase();
        final empleado = obtenerNombreEmpleado(tarea.personaFk).toLowerCase();
        final searchLower = search.toLowerCase();

        return descripcion.contains(searchLower) ||
            prioridad.contains(searchLower) ||
            estado.contains(searchLower) ||
            empleado.contains(searchLower);
      }).toList();
    }

    // Ordenar por fecha límite: más cercanas primero
    resultado.sort((a, b) {
      // Si una está completada, va al final
      if (a.estadoTarea == 'Completada' && b.estadoTarea != 'Completada') {
        return 1; // a va después
      }
      if (b.estadoTarea == 'Completada' && a.estadoTarea != 'Completada') {
        return -1; // b va después
      }
      // Ambas completadas o ambas no completadas: ordenar por fecha límite
      return a.fechaLimite.compareTo(b.fechaLimite);
    });

    return resultado;
  }

  Color getPrioridadColor(String prioridad) {
    switch (prioridad) {
      case 'Alta':
        return Colors.red;
      case 'Media':
        return Colors.orange;
      case 'Baja':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color getEstadoColor(String estado) {
    switch (estado) {
      case 'Completada':
        return Colors.green;
      case 'En Progreso':
        return Colors.orange;
      case 'Pendiente':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String formatearFecha(DateTime fecha) {
    final meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];

    return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year}';
  }

  void abrirModalEditar(Tarea tarea) {
    showDialog(
      context: context,
      builder: (context) => ModalEditarTarea(
        tarea: tarea,
        token: token ?? '',
        onGuardar: () {
          cargarDatos();
        },
      ),
    );
  }

  void abrirModalEliminar(Tarea tarea) {
    showDialog(
      context: context,
      builder: (context) => ModalEliminarTarea(
        tarea: tarea,
        token: token ?? '',
        onConfirmar: () {
          cargarDatos();
        },
      ),
    );
  }

  Widget _buildEncabezado() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con ícono y título
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.task_alt,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lista de Tareas',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Gestiona la producción',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Estadísticas en una sola fila compacta
          Row(
            children: [
              // Total
              Expanded(
                child: _buildStatCard(
                  icon: Icons.assignment,
                  label: 'Total',
                  value: tareas.length.toString(),
                ),
              ),
              const SizedBox(width: 8),
              // Pendientes
              Expanded(
                child: _buildStatCard(
                  icon: Icons.pending_actions,
                  label: 'Pendientes',
                  value: tareas
                      .where((t) => t.estadoTarea == 'Pendiente')
                      .length
                      .toString(),
                ),
              ),
              const SizedBox(width: 8),
              // Completadas
              Expanded(
                child: _buildStatCard(
                  icon: Icons.check_circle,
                  label: 'Listas',
                  value: tareas
                      .where((t) => t.estadoTarea == 'Completada')
                      .length
                      .toString(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Botón de reporte centrado
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: isLoading
                      ? null
                      : () async {
                          await PdfDownloadService.descargarReporteProduccion(
                            context,
                          );
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.picture_as_pdf,
                          color: Color(0xFF667eea),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Descargar Reporte PDF',
                          style: TextStyle(
                            color: Color(0xFF667eea),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Método auxiliar para las tarjetas de estadísticas
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          HeaderWidget(),
          Expanded(
            child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Cargando tareas...'),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildEncabezado(),

                        // Buscador
                        Container(
                          constraints: const BoxConstraints(maxWidth: 600),
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          child: TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                              hintText:
                                  'Buscar por descripción, prioridad, estado...',
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
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                search = value;
                              });
                            },
                          ),
                        ),

                        // Lista de Cards
                        _buildListaTareas(),
                      ],
                    ),
                  ),
          ),
          const FooterLine(),
        ],
      ),
    );
  }

  Widget _buildListaTareas() {
    final tareasMostradas = tareasFiltradas;

    if (tareasMostradas.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.task_outlined, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                search.isNotEmpty
                    ? 'No se encontraron resultados'
                    : 'No hay tareas registradas',
                style: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (search.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Intenta con otros términos de búsqueda',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      children: tareasMostradas.asMap().entries.map((entry) {
        final index = entry.key;
        final tarea = entry.value;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FILA PRINCIPAL: ID, Badges y Acciones
                Row(
                  children: [
                    // ID
                    SizedBox(
                      width: 60,
                      child: Text(
                        '#${(index + 1).toString().padLeft(3, '0')}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // PRIORIDAD
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: getPrioridadColor(tarea.prioridad),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tarea.prioridad,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // ESTADO
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: getEstadoColor(tarea.estadoTarea),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tarea.estadoTarea,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // ACCIONES
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Editar
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => abrirModalEditar(tarea),
                          tooltip: 'Editar',
                        ),

                        // Eliminar
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => abrirModalEliminar(tarea),
                          tooltip: 'Eliminar',
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // DESCRIPCIÓN
                if (tarea.descripcion != null && tarea.descripcion!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      tarea.descripcion!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // INFORMACIÓN DETALLADA
                Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    // Empleado
                    _buildInfoChip(
                      Icons.person,
                      obtenerNombreEmpleado(tarea.personaFk),
                    ),

                    // Fecha Asignación
                    _buildInfoChip(
                      Icons.calendar_today,
                      'Asignada: ${formatearFecha(tarea.fechaAsignacion)}',
                    ),

                    // Fecha Límite
                    _buildInfoChip(
                      Icons.event,
                      'Límite: ${formatearFecha(tarea.fechaLimite)}',
                      color: _esFechaProxima(tarea.fechaLimite)
                          ? Colors.red
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  bool _esFechaProxima(DateTime fechaLimite) {
    final ahora = DateTime.now();
    final diferencia = fechaLimite.difference(ahora).inDays;
    return diferencia >= 0 && diferencia <= 3; // Próxima en 3 días o menos
  }

  Widget _buildInfoChip(IconData icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: color ?? Colors.grey[700],
            fontWeight: color != null ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
