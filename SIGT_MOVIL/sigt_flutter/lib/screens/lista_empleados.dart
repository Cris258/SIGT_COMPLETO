import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/footer_widget.dart';
import '../widgets/header_widget.dart';
import '../config/app_config.dart';
import '../models/persona.dart';
import '../widgets/widgetsAdmin/modal_editar_usuario.dart';
import '../widgets/widgetsAdmin/modal_eliminar_empleado.dart';

class ListaEmpleados extends StatefulWidget {
  const ListaEmpleados({super.key});

  @override
  State<ListaEmpleados> createState() => _ListaEmpleadosState();
}

class _ListaEmpleadosState extends State<ListaEmpleados> {
  List<Persona> empleados = [];
  bool loading = true;
  String search = "";
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarEmpleados();
  }

  Future<void> _cargarEmpleados() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final response = await http.get(
        Uri.parse(AppConfig.endpoint('persona')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> personasJson = data['body'];

        final List<Persona> todasPersonas = personasJson
            .map((json) => Persona.fromJson(json))
            .toList();

        final soloEmpleados = todasPersonas.where((persona) {
          return persona.rolFk == 3;
        }).toList();

        setState(() {
          empleados = soloEmpleados;
          loading = false;
        });
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        loading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar empleados: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _abrirModalEditar(Persona persona) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalEditarUsuario(
        persona: persona,
        onGuardar: (personaActualizada) async {
          await _cargarEmpleados();
        },
      ),
    );
  }

  void _abrirModalEliminar(Persona persona) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalEliminar(
        persona: persona,
        tipoUsuario: "empleado",
        onConfirmar: () async {
          await _cargarEmpleados();
        },
      ),
    );
  }

  List<Persona> get empleadosFiltrados {
    if (search.isEmpty) return empleados;

    String searchLower = search.toLowerCase();
    return empleados.where((e) {
      return (e.numeroDocumento.toString()).toLowerCase().contains(searchLower) ||
          e.tipoDocumento.toLowerCase().contains(searchLower) ||
          e.primerNombre.toLowerCase().contains(searchLower) ||
          (e.segundoNombre ?? '').toLowerCase().contains(searchLower) ||
          e.primerApellido.toLowerCase().contains(searchLower) ||
          (e.segundoApellido ?? '').toLowerCase().contains(searchLower) ||
          e.telefono.toLowerCase().contains(searchLower) ||
          e.correo.toLowerCase().contains(searchLower);
    }).toList();
  }

  Color _getEstadoColor(bool activo) {
    return activo ? const Color.fromARGB(255, 95, 229, 99) : Colors.red;
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
                        Text('Cargando empleados...'),
                      ],
                    ),
                  )
                : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar datos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _cargarEmpleados,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargarEmpleados,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Text(
                                'Lista de Empleados Registrados',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            Container(
                              constraints: const BoxConstraints(maxWidth: 600),
                              margin: const EdgeInsets.symmetric(vertical: 16),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Buscar por nombre, correo, documento...',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: search.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            setState(() {
                                              search = '';
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

                            _buildListaEmpleados(),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          FooterWidget(),
        ],
      ),
    );
  }

  Widget _buildListaEmpleados() {
    if (empleadosFiltrados.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.badge_outlined, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                search.isNotEmpty
                    ? 'No se encontraron resultados'
                    : 'No hay empleados registrados',
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
      children: empleadosFiltrados.asMap().entries.map((entry) {
        final index = entry.key;
        final empleado = entry.value;
        final numeroSecuencial = (index + 1).toString().padLeft(3, '0');

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FILA PRINCIPAL: 2 filas
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila 1: Número + Estado + Botones
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '#$numeroSecuencial',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getEstadoColor(empleado.estaActivo),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                empleado.estaActivo ? 'Activo' : 'Inactivo',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _abrirModalEditar(empleado),
                              tooltip: 'Editar',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _abrirModalEliminar(empleado),
                              tooltip: 'Eliminar',
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Fila 2: Nombre completo
                    Text(
                      '${empleado.primerNombre} ${empleado.segundoNombre ?? ''} ${empleado.primerApellido} ${empleado.segundoApellido ?? ''}'.trim(),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // INFORMACIÓN DETALLADA
                Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      Icons.badge,
                      '${empleado.tipoDocumento}: ${empleado.numeroDocumento}',
                    ),
                    _buildInfoChip(Icons.work, empleado.nombreRol ?? 'Sin rol'),
                    _buildInfoChip(Icons.phone, empleado.telefono),
                    _buildInfoChip(Icons.email, empleado.correo),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
      ],
    );
  }
}