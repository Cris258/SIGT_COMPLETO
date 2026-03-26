import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../models/persona.dart';
import '../widgets/header_widget.dart';
import '../widgets/footer_widget.dart';
import '../widgets/widgetsAdmin/modal_editar_usuario.dart';
import '../widgets/widgetsAdmin/modal_eliminar_usuario.dart';

// ------------------------------------
// SERVICIO DE PERSONAS
// ------------------------------------
class PersonaService {
  // Obtener todas las personas
  static Future<List<Persona>> obtenerPersonas() async {
    try {
      debugPrint(' [PERSONAS] Obteniendo personas...');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final url = Uri.parse(AppConfig.endpoint('persona'));
      debugPrint(' [PERSONAS] GET: $url');

      final response = await http.get(
        url,
        headers: {...AppConfig.headers, 'Authorization': 'Bearer $token'},
      );

      debugPrint(' [PERSONAS] Status: ${response.statusCode}');
      debugPrint(' [PERSONAS] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final personasData = data['body'] as List;

        final personas = personasData
            .map((persona) => Persona.fromJson(persona))
            .toList();

        debugPrint('[PERSONAS] ${personas.length} personas obtenidas');
        return personas;
      } else {
        final errorBody = response.body;
        debugPrint(' [PERSONAS] Error ${response.statusCode}: $errorBody');
        throw Exception('Error ${response.statusCode}: $errorBody');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [PERSONAS] Error: $e');
      debugPrint('❌ [PERSONAS] StackTrace: $stackTrace');
      rethrow;
    }
  }
}

// ------------------------------------
// PANTALLA DE LISTA DE USUARIOS
// ------------------------------------
class ListaUsuarios extends StatefulWidget {
  const ListaUsuarios({super.key});

  @override
  State<ListaUsuarios> createState() => _ListaUsuariosState();
}

class _ListaUsuariosState extends State<ListaUsuarios> {
  List<Persona> _personas = [];
  bool _isLoading = false;
  String _search = "";
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarPersonas();
  }

  Future<void> _cargarPersonas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final personas = await PersonaService.obtenerPersonas();
      setState(() {
        _personas = personas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      if (mounted) {
        _mostrarMensaje(
          'Error al cargar usuarios: $_errorMessage',
          isError: true,
        );
      }
    }
  }

  List<Persona> get _personasFiltradas {
    if (_search.isEmpty) return _personas;

    String searchLower = _search.toLowerCase();
    return _personas.where((p) {
      return p.numeroDocumento.toString().toLowerCase().contains(searchLower) ||
          p.tipoDocumento.toLowerCase().contains(searchLower) ||
          p.primerNombre.toLowerCase().contains(searchLower) ||
          (p.segundoNombre ?? '').toLowerCase().contains(searchLower) ||
          p.primerApellido.toLowerCase().contains(searchLower) ||
          (p.segundoApellido ?? '').toLowerCase().contains(searchLower) ||
          (p.nombreRol ?? '').toLowerCase().contains(searchLower) ||
          p.telefono.toLowerCase().contains(searchLower) ||
          p.correo.toLowerCase().contains(searchLower);
    }).toList();
  }

  void _abrirModalEditar(Persona persona) {
    showDialog(
      context: context,
      builder: (context) => ModalEditarUsuario(
        persona: persona,
        onGuardar: (personaActualizada) async {
          await _cargarPersonas();
        },
      ),
    );
  }

  void _abrirModalEliminar(Persona persona) {
    showDialog(
      context: context,
      builder: (context) => ModalEliminar(
        persona: persona,
        tipoUsuario: "usuario",
        onConfirmar: () async {
          await _cargarPersonas();
        },
      ),
    );
  }

  void _mostrarMensaje(String mensaje, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _getEstadoColor(int estado) {
    return estado == 1 ? const Color.fromARGB(255, 95, 229, 99) : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          HeaderWidget(),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Cargando usuarios...',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Título
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'Lista de Usuarios Registrados',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // Buscador
                          Container(
                            constraints: const BoxConstraints(maxWidth: 600),
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText:
                                    'Buscar por nombre, correo, documento...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _search = value;
                                });
                              },
                            ),
                          ),

                          // Lista de Cards
                          _buildListaUsuarios(),
                        ],
                      ),
                    ),
                  ),
          ),

          FooterWidget(),
        ],
      ),
    );
  }

  Widget _buildListaUsuarios() {
    if (_personasFiltradas.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _search.isNotEmpty
                    ? 'No se encontraron resultados'
                    : 'No hay usuarios registrados',
                style: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (_search.isNotEmpty) ...[
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
      children: _personasFiltradas.map((persona) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FILA PRINCIPAL: ID, Nombre y Estado
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila 1: ID + Estado + Botones
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '#${persona.idPersona ?? ''}',
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
                                color: _getEstadoColor(persona.estadoPersonaFk),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                persona.estadoPersonaFk == 1
                                    ? 'Activo'
                                    : 'Inactivo',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _abrirModalEditar(persona),
                              tooltip: 'Editar',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _abrirModalEliminar(persona),
                              tooltip: 'Eliminar',
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Fila 2: Nombre completo
                    Text(
                      '${persona.primerNombre} ${persona.segundoNombre ?? ''} ${persona.primerApellido} ${persona.segundoApellido ?? ''}'
                          .trim(),
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
                    // Documento
                    _buildInfoChip(
                      Icons.badge,
                      '${persona.tipoDocumento}: ${persona.numeroDocumento}',
                    ),

                    // Rol
                    _buildInfoChip(Icons.work, persona.nombreRol ?? 'Sin rol'),

                    // Teléfono
                    _buildInfoChip(Icons.phone, persona.telefono),

                    // Correo
                    _buildInfoChip(Icons.email, persona.correo),
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
