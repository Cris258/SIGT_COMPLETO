import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../models/movimiento.dart';
import '../models/produccion.dart';
import '../models/detalleproduccion.dart';
import '../models/persona.dart';
import '../models/producto.dart';
import '../widgets/header_widget.dart';
import '../widgets/footer_widget.dart';
import '../widgets/widgetsAdmin/modal_detalle_movimiento.dart';
import '../services/pdf_download_service.dart';

// SERVICIO DE MOVIMIENTOS
class MovimientoService {
  // Obtener todos los movimientos
  static Future<List<Movimiento>> obtenerMovimientos() async {
    try {
      debugPrint('🔵 [MOVIMIENTOS] Obteniendo movimientos...');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final url = Uri.parse(AppConfig.endpoint('movimiento'));
      debugPrint(' [MOVIMIENTOS] GET: $url');

      final response = await http.get(
        url,
        headers: {...AppConfig.headers, 'Authorization': 'Bearer $token'},
      );

      debugPrint(' [MOVIMIENTOS] Status: ${response.statusCode}');
      debugPrint(' [MOVIMIENTOS] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final movimientosData = data['body'] as List;

        final movimientos = movimientosData
            .map((mov) => Movimiento.fromJson(mov))
            .toList();

        debugPrint(
          '[MOVIMIENTOS] ${movimientos.length} movimientos obtenidos',
        );
        return movimientos;
      } else {
        final errorBody = response.body;
        debugPrint(' [MOVIMIENTOS] Error ${response.statusCode}: $errorBody');
        throw Exception('Error ${response.statusCode}: $errorBody');
      }
    } catch (e, stackTrace) {
      debugPrint(' [MOVIMIENTOS] Error: $e');
      debugPrint(' [MOVIMIENTOS] StackTrace: $stackTrace');
      rethrow;
    }
  }

  // Cargar todas las personas
  static Future<Map<int, Persona>> obtenerTodasLasPersonas() async {
    try {
      debugPrint('🔵 [PERSONAS] Obteniendo todas las personas...');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final url = Uri.parse(AppConfig.endpoint('persona'));
      final response = await http.get(
        url,
        headers: {...AppConfig.headers, 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final personasData = data['body'] as List;

        // Crear un mapa: idPersona -> Persona
        final Map<int, Persona> personasMap = {};
        for (var personaJson in personasData) {
          final persona = Persona.fromJson(personaJson);
          // Verificar que el ID no sea null
          if (persona.idPersona != null) {
            personasMap[persona.idPersona!] = persona;
          }
        }

        debugPrint(' [PERSONAS] ${personasMap.length} personas cargadas');
        return personasMap;
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      debugPrint(' [PERSONAS] Error: $e');
      return {};
    }
  }

  //  Cargar todos los productos
  static Future<Map<int, Producto>> obtenerTodosLosProductos() async {
    try {
      debugPrint('[PRODUCTOS] Obteniendo todos los productos...');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final url = Uri.parse(AppConfig.endpoint('producto'));
      final response = await http.get(
        url,
        headers: {...AppConfig.headers, 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final productosData = data['body'] as List;

        // Crear un mapa: idProducto -> Producto
        final Map<int, Producto> productosMap = {};
        for (var productoJson in productosData) {
          // Arreglar el precio si viene como String
          if (productoJson['Precio'] is String) {
            productoJson['Precio'] =
                double.tryParse(productoJson['Precio']) ?? 0.0;
          }
          final producto = Producto.fromJson(productoJson);
          // CORREGIDO: Verificar que el ID no sea null
          if (producto.idProducto != null) {
            productosMap[producto.idProducto!] = producto;
          }
        }

        debugPrint('[PRODUCTOS] ${productosMap.length} productos cargados');
        return productosMap;
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[PRODUCTOS] Error: $e');
      return {};
    }
  }

  // Obtener todas las producciones
  static Future<List<Produccion>> obtenerProducciones() async {
    try {
      debugPrint(' [PRODUCCIONES] Obteniendo producciones...');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final url = Uri.parse(AppConfig.endpoint('produccion'));
      debugPrint(' [PRODUCCIONES] GET: $url');

      final response = await http.get(
        url,
        headers: {...AppConfig.headers, 'Authorization': 'Bearer $token'},
      );

      debugPrint(' [PRODUCCIONES] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final produccionesData = data['body'] as List;

        final producciones = produccionesData
            .map((prod) => Produccion.fromJson(prod))
            .toList();

        debugPrint(
          ' [PRODUCCIONES] ${producciones.length} producciones obtenidas',
        );
        return producciones;
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      debugPrint(' [PRODUCCIONES] Error: $e');
      rethrow;
    }
  }

  // Obtener detalles de producción
  static Future<List<DetalleProduccion>> obtenerDetallesProduccion() async {
    try {
      debugPrint(' [DETALLES PRODUCCION] Obteniendo detalles...');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final url = Uri.parse(AppConfig.endpoint('detalleproduccion'));
      debugPrint(' [DETALLES PRODUCCION] GET: $url');

      final response = await http.get(
        url,
        headers: {...AppConfig.headers, 'Authorization': 'Bearer $token'},
      );

      debugPrint(' [DETALLES PRODUCCION] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final detallesData = data['body'] as List;

        final detalles = detallesData
            .map((det) => DetalleProduccion.fromJson(det))
            .toList();

        debugPrint(
          ' [DETALLES PRODUCCION] ${detalles.length} detalles obtenidos',
        );
        return detalles;
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      debugPrint(' [DETALLES PRODUCCION] Error: $e');
      rethrow;
    }
  }
}


// PANTALLA DE LISTA DE MOVIMIENTOS

class ListaMovimientos extends StatefulWidget {
  const ListaMovimientos({super.key});

  @override
  State<ListaMovimientos> createState() => _ListaMovimientosState();
}

class _ListaMovimientosState extends State<ListaMovimientos> {
  List<Movimiento> _movimientos = [];
  Map<int, Persona> _personasMap = {};
  Map<int, Producto> _productosMap = {};
  bool _isLoading = false;
  String _search = "";
  String _filtroTipo = "Todos";
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarTodosDatos();
  }

  // Cargar movimientos, personas y productos juntos
  Future<void> _cargarTodosDatos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Cargar todo en paralelo para mejor rendimiento
      final resultados = await Future.wait([
        MovimientoService.obtenerMovimientos(),
        MovimientoService.obtenerTodasLasPersonas(),
        MovimientoService.obtenerTodosLosProductos(),
      ]);

      setState(() {
        _movimientos = resultados[0] as List<Movimiento>;
        _personasMap = resultados[1] as Map<int, Persona>;
        _productosMap = resultados[2] as Map<int, Producto>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      if (mounted) {
        _mostrarMensaje('Error al cargar datos: $_errorMessage', isError: true);
      }
    }
  }

  List<Movimiento> get _movimientosFiltrados {
    var filtrados = _movimientos;

    // Filtro por tipo
    if (_filtroTipo != "Todos") {
      filtrados = filtrados.where((m) => m.tipo == _filtroTipo).toList();
    }

    // Filtro por búsqueda
    if (_search.isNotEmpty) {
      String searchLower = _search.toLowerCase();
      filtrados = filtrados.where((m) {
        //  Buscar por nombre de persona y producto también
        final persona = _personasMap[m.personaFk];
        final producto = _productosMap[m.productoFk];

        final nombrePersona = persona != null
            ? '${persona.primerNombre} ${persona.primerApellido}'.toLowerCase()
            : '';
        final nombreProducto = producto != null
            ? producto.nombreProducto.toLowerCase()
            : '';

        return m.idMovimiento.toString().contains(searchLower) ||
            (m.motivo ?? '').toLowerCase().contains(searchLower) ||
            m.tipo.toLowerCase().contains(searchLower) ||
            m.fecha.toString().contains(searchLower) ||
            nombrePersona.contains(searchLower) ||
            nombreProducto.contains(searchLower);
      }).toList();
    }

    return filtrados;
  }

  int get _totalEntradas {
    return _movimientos.where((m) => m.tipo == "Entrada").length;
  }

  int get _totalSalidas {
    return _movimientos.where((m) => m.tipo == "Salida").length;
  }

  void _verDetalles(Movimiento movimiento, int numeroSecuencial) {
    showDialog(
      context: context,
      builder: (context) => ModalDetalleMovimiento(
        movimiento: movimiento,
        numeroSecuencial: numeroSecuencial,
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

  Color _getTipoColor(String tipo) {
    switch (tipo) {
      case "Entrada":
        return Colors.green;
      case "Salida":
        return Colors.orange;
      case "Ajuste":
        return Colors.blue;
      case "Devolucion":
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo) {
      case "Entrada":
        return Icons.arrow_downward;
      case "Salida":
        return Icons.arrow_upward;
      case "Ajuste":
        return Icons.tune;
      case "Devolucion":
        return Icons.keyboard_return;
      default:
        return Icons.help_outline;
    }
  }

  String _formatearFecha(DateTime fecha) {
    final meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    return '${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year}';
  }

  //  Obtener nombre completo de persona
  String _getNombrePersona(int idPersona) {
    final persona = _personasMap[idPersona];
    if (persona == null) return 'ID: $idPersona';

    return '${persona.primerNombre} ${persona.segundoNombre ?? ''} ${persona.primerApellido} ${persona.segundoApellido ?? ''}'
        .trim()
        .replaceAll(RegExp(r'\s+'), ' '); // Eliminar espacios extras
  }

  //Obtener descripción de producto 
  String _getDescripcionProducto(int idProducto) {
    final producto = _productosMap[idProducto];
    if (producto == null) return 'ID: $idProducto';

    return '${producto.nombreProducto} - ${producto.color} / ${producto.talla}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const HeaderWidget(),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Cargando movimientos...',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargarTodosDatos,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Título
                            _buildTitulo(),
                            const SizedBox(height: 20),

                            // Buscador
                            _buildBuscador(),
                            const SizedBox(height: 16),

                            // Filtro de tipo
                            _buildFiltroTipo(),
                            const SizedBox(height: 20),

                            // Estadísticas
                            _buildEstadisticas(),
                            const SizedBox(height: 20),

                            // Lista de movimientos
                            _buildListaMovimientos(),
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

  Widget _buildTitulo() {
    return Container(
      padding: const EdgeInsets.all(20),
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
                  Icons.show_chart,
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
                      'Panel de Control',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Movimientos de Inventario',
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
                  onTap: _isLoading
                      ? null
                      : () async {
                          await PdfDownloadService.descargarReporteMovimientos(
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

  Widget _buildBuscador() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar por ID, persona, producto, motivo...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _search = "";
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
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
    );
  }

  Widget _buildFiltroTipo() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _filtroTipo,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.filter_list),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        isExpanded: true,
        isDense: false,
        menuMaxHeight: 300,
        items: const [
          DropdownMenuItem(
            value: "Todos",
            child: Text("Todos los tipos", overflow: TextOverflow.ellipsis),
          ),
          DropdownMenuItem(
            value: "Entrada",
            child: Text(
              "Entrada (Producción)",
              overflow: TextOverflow.ellipsis,
            ),
          ),
          DropdownMenuItem(
            value: "Salida",
            child: Text("Salida (Venta)", overflow: TextOverflow.ellipsis),
          ),
          DropdownMenuItem(
            value: "Ajuste",
            child: Text("Ajuste", overflow: TextOverflow.ellipsis),
          ),
          DropdownMenuItem(
            value: "Devolucion",
            child: Text("Devolución", overflow: TextOverflow.ellipsis),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _filtroTipo = value;
            });
          }
        },
      ),
    );
  }

  Widget _buildEstadisticas() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, size: 20, color: Color(0xFF667eea)),
              SizedBox(width: 8),
              Text(
                'Estadísticas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF667eea),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tres estadísticas en una fila
          Row(
            children: [
              // Total
              Expanded(
                child: _buildStatMini(
                  'Total',
                  _movimientos.length.toString(),
                  Icons.swap_horiz,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 10),
              // Entradas
              Expanded(
                child: _buildStatMini(
                  'Entradas',
                  _totalEntradas.toString(),
                  Icons.arrow_downward,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 10),
              // Salidas
              Expanded(
                child: _buildStatMini(
                  'Salidas',
                  _totalSalidas.toString(),
                  Icons.arrow_upward,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatMini(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildListaMovimientos() {
    if (_movimientosFiltrados.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _search.isNotEmpty || _filtroTipo != "Todos"
                    ? 'No se encontraron resultados con los filtros aplicados'
                    : 'No hay movimientos registrados en el sistema',
                style: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Lista de Movimientos (${_movimientosFiltrados.length})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ...List.generate(_movimientosFiltrados.length, (index) {
          final movimiento = _movimientosFiltrados[index];
          final numeroSecuencial = index + 1;
          final numeroFormateado = numeroSecuencial.toString().padLeft(3, '0');

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: InkWell(
              onTap: () => _verDetalles(movimiento, numeroSecuencial),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FILA PRINCIPAL: Número, Tipo y Flecha
                    Row(
                      children: [
                        // Número secuencial
                        SizedBox(
                          width: 50,
                          child: Text(
                            '#$numeroFormateado',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Tipo con badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getTipoColor(movimiento.tipo),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getTipoIcon(movimiento.tipo),
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                movimiento.tipo,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // Flecha para ver detalles
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // INFORMACIÓN DETALLADA CON NOMBRES 
                    Wrap(
                      spacing: 20,
                      runSpacing: 8,
                      children: [
                        _buildInfoChip(
                          Icons.calendar_today,
                          _formatearFecha(movimiento.fecha),
                        ),
                        _buildInfoChip(
                          Icons.inventory_2,
                          _getDescripcionProducto(movimiento.productoFk),
                        ),
                        _buildInfoChip(
                          Icons.numbers,
                          'Cantidad: ${movimiento.cantidad}',
                        ),
                        _buildInfoChip(
                          Icons.person,
                          _getNombrePersona(movimiento.personaFk),
                        ),
                      ],
                    ),

                    if (movimiento.motivo != null &&
                        movimiento.motivo!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.description,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                movimiento.motivo!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
