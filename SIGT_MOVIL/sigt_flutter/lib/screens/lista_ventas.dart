import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/venta.dart';
import '../models/persona.dart';
import '../models/detalleventa.dart';
import '../models/producto.dart';
import '../widgets/footer_widget.dart';
import '../widgets/header_widget.dart';
import '../widgets/widgetsAdmin/modal_editar_venta.dart';
import '../widgets/widgetsAdmin/modal_eliminar_venta.dart';
import '../services/pdf_download_service.dart';

class ListaVentas extends StatefulWidget {
  const ListaVentas({super.key});

  @override
  State<ListaVentas> createState() => _ListaVentasState();
}

class _ListaVentasState extends State<ListaVentas> {
  List<VentaConPersona> ventas = [];
  bool loading = true;
  String search = "";
  int? ventaExpandida;
  Map<int, List<DetalleVentaConProducto>> detallesVenta = {};
  String? token;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('auth_token');

      if (token == null) {
        _mostrarError('No se encontró token de autenticación');
        setState(() => loading = false);
        return;
      }

      await cargarVentas();
    } catch (e) {
      _mostrarError('Error al inicializar: $e');
      setState(() => loading = false);
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleaned = value.trim().replaceAll(',', '.');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value.trim()) ?? 0;
    }
    if (value is double) return value.toInt();
    return 0;
  }

  Future<void> cargarVentas() async {
    setState(() => loading = true);

    try {
      final response = await http.get(
        Uri.parse(AppConfig.endpoint('venta')),
        headers: {...AppConfig.headers, 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> ventasData = data['body'];

        // Cargar ventas y sus clientes
        List<VentaConPersona> ventasConCliente = [];

        for (var ventaJson in ventasData) {
          // Crear Venta manualmente manejando la conversión
          final venta = Venta(
            idVenta: ventaJson['idVenta'],
            fecha: DateTime.parse(ventaJson['Fecha']),
            total: _parseDouble(ventaJson['Total']),
            direccionEntrega: ventaJson['DireccionEntrega'] ?? '',
            ciudad: ventaJson['Ciudad'] ?? '',
            departamento: ventaJson['Departamento'] ?? '',
            personaFk: _parseInt(ventaJson['Persona_FK']),
          );

          Persona? persona;

          // Cargar información del cliente
          try {
            final personaResponse = await http.get(
              Uri.parse(AppConfig.byId('persona', venta.personaFk)),
              headers: {...AppConfig.headers, 'Authorization': 'Bearer $token'},
            );

            if (personaResponse.statusCode == 200) {
              final personaData = json.decode(personaResponse.body);
              persona = Persona.fromJson(personaData);
            }
          } catch (e) {
            debugPrint('Error cargando cliente: $e');
          }

          ventasConCliente.add(VentaConPersona(venta: venta, persona: persona));
        }

        setState(() {
          ventas = ventasConCliente;
          ventas.sort((a, b) => b.venta.fecha.compareTo(a.venta.fecha));
          loading = false;
        });
      } else {
        throw Exception('Error al obtener ventas: ${response.statusCode}');
      }
    } catch (e) {
      _mostrarError('Error al cargar ventas: $e');
      setState(() => loading = false);
    }
  }

  Future<void> cargarDetallesVenta(int idVenta) async {
    // Si ya está expandido, lo colapsamos
    if (ventaExpandida == idVenta) {
      setState(() => ventaExpandida = null);
      return;
    }

    // Si ya tenemos los detalles en caché, solo expandimos
    if (detallesVenta.containsKey(idVenta)) {
      setState(() => ventaExpandida = idVenta);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(AppConfig.endpoint('detalleventa/venta/$idVenta')),
        headers: {...AppConfig.headers, 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> detallesData = data['body'];

        List<DetalleVentaConProducto> detalles = [];

        for (var detalleJson in detallesData) {
          // Crear DetalleVenta manualmente manejando la conversión
          final detalle = DetalleVenta(
            idDetalleVenta: detalleJson['idDetalleVenta'],
            cantidad: _parseInt(detalleJson['Cantidad']),
            precioUnitario: _parseDouble(detalleJson['PrecioUnitario']),
            productoFk: _parseInt(detalleJson['Producto_FK']),
            ventaFk: _parseInt(detalleJson['Venta_FK']),
          );

          // El producto puede venir en el JSON
          Producto? producto;
          if (detalleJson['Producto'] != null) {
            final prodJson = detalleJson['Producto'];
            producto = Producto(
              idProducto: prodJson['idProducto'],
              nombreProducto: prodJson['NombreProducto'] ?? '',
              color: prodJson['Color'] ?? '',
              talla: prodJson['Talla'] ?? '',
              estampado: prodJson['Estampado'] ?? '',
              stock: _parseInt(prodJson['Stock']),
              precio: _parseDouble(prodJson['Precio']),
            );
          }

          detalles.add(
            DetalleVentaConProducto(detalle: detalle, producto: producto),
          );
        }

        setState(() {
          detallesVenta[idVenta] = detalles;
          ventaExpandida = idVenta;
        });

        _mostrarExito('Detalles cargados correctamente');
      } else {
        throw Exception('Error al cargar detalles: ${response.statusCode}');
      }
    } catch (e) {
      _mostrarError('Error al cargar detalles: $e');
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

    return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year}, ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  String formatearPrecio(num precio) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(precio);
  }

  List<VentaConPersona> get ventasFiltradas {
    if (search.isEmpty) return ventas;

    return ventas.where((v) {
      String searchLower = search.toLowerCase();
      String nombreCliente = v.persona != null
          ? '${v.persona!.primerNombre} ${v.persona!.primerApellido}'
                .toLowerCase()
          : '';

      return (v.venta.idVenta?.toString() ?? '').toLowerCase().contains(
            searchLower,
          ) ||
          (v.venta.total.toString()).toLowerCase().contains(searchLower) ||
          nombreCliente.contains(searchLower);
    }).toList();
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void abrirModalEditar(VentaConPersona ventaConPersona) {
    showDialog(
      context: context,
      builder: (context) => ModalEditarVenta(
        venta: ventaConPersona.venta,
        onGuardar: (ventaActualizada) {
          setState(() {
            final index = ventas.indexWhere(
              (v) => v.venta.idVenta == ventaActualizada.idVenta,
            );
            if (index != -1) {
              ventas[index] = VentaConPersona(
                venta: ventaActualizada,
                persona: ventaConPersona.persona,
              );
            }
          });
          _mostrarExito('Venta actualizada correctamente');
        },
      ),
    );
  }

  void abrirModalEliminar(VentaConPersona ventaConPersona) {
    final nombreCliente = ventaConPersona.persona != null
        ? '${ventaConPersona.persona!.primerNombre} ${ventaConPersona.persona!.primerApellido}'
        : null;

    showDialog(
      context: context,
      builder: (context) => ModalEliminarVenta(
        venta: ventaConPersona.venta,
        nombreCliente: nombreCliente,
        onConfirmar: (ventaEliminada) {
          setState(() {
            ventas.removeWhere(
              (v) => v.venta.idVenta == ventaEliminada.idVenta,
            );
          });
          _mostrarExito('Venta eliminada correctamente');
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
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Si el ancho es menor a 600px, mostramos diseño vertical
          final bool esMovil = constraints.maxWidth < 600;

          if (esMovil) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono y título
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shopping_cart_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lista de Ventas',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Gestiona y visualiza todas las ventas',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Botón en toda la fila
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: loading
                        ? null
                        : () async {
                            await PdfDownloadService.descargarReporteVentas(
                              context,
                            );
                          },
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: const Text(
                      'Generar Reporte PDF',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF667eea),
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
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shopping_cart_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lista de Ventas Registradas',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Gestiona y visualiza todas las ventas del sistema',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: loading
                    ? null
                    : () async {
                        await PdfDownloadService.descargarReporteVentas(
                          context,
                        );
                      },
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: const Text(
                  'Generar Reporte',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF667eea),
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
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando ventas...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const HeaderWidget(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildEncabezado(),

                    // BUSCADOR
                    Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Buscar por ID, total, cliente...",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) => setState(() => search = value),
                      ),
                    ),

                    // LISTA DE VENTAS
                    _buildListaVentas(),
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

  Widget _buildListaVentas() {
    if (ventasFiltradas.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            search.isNotEmpty
                ? 'No se encontraron resultados'
                : 'No hay ventas registradas',
            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return Column(
      children: ventasFiltradas.asMap().entries.map((entry) {
        final index = entry.key;
        final ventaConPersona = entry.value;
        final venta = ventaConPersona.venta;
        final persona = ventaConPersona.persona;
        final bool expandido = ventaExpandida == venta.idVenta;
        final numeroSecuencial = (index + 1).toString().padLeft(3, '0');

        String nombreCliente = 'Cliente no disponible';
        if (persona != null) {
          nombreCliente = '${persona.primerNombre} ${persona.primerApellido}';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: Column(
            children: [
              // INFORMACIÓN PRINCIPAL DE LA VENTA
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Row(
                  children: [
                    // ID SECUENCIAL
                    SizedBox(
                      width: 80,
                      child: Text(
                        '#$numeroSecuencial',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // TOTAL
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        formatearPrecio(venta.total),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // ACCIONES
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ver detalles
                        IconButton(
                          icon: Icon(
                            expandido ? Icons.visibility_off : Icons.visibility,
                            color: Colors.blue,
                          ),
                          onPressed: () => cargarDetallesVenta(venta.idVenta!),
                          tooltip: 'Ver productos',
                        ),

                        // Editar
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => abrirModalEditar(ventaConPersona),
                          tooltip: 'Editar',
                        ),

                        // Eliminar
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => abrirModalEliminar(ventaConPersona),
                          tooltip: 'Eliminar',
                        ),
                      ],
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(nombreCliente),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(formatearFecha(venta.fecha)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // DETALLES EXPANDIBLES
              if (expandido) _buildDetallesVenta(ventaConPersona),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetallesVenta(VentaConPersona ventaConPersona) {
    final detalles = detallesVenta[ventaConPersona.venta.idVenta];

    if (detalles == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (detalles.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No hay productos en esta venta'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Productos de la Venta',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // TABLA DE PRODUCTOS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey[300]),
              columnSpacing: 30,
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Producto')),
                DataColumn(label: Text('Cantidad')),
                DataColumn(label: Text('Precio Unit.')),
                DataColumn(label: Text('Subtotal')),
              ],
              rows: detalles.map<DataRow>((detalleConProducto) {
                final detalle = detalleConProducto.detalle;
                final producto = detalleConProducto.producto;

                final subtotal = detalle.cantidad * detalle.precioUnitario;

                return DataRow(
                  cells: [
                    DataCell(Text(detalle.productoFk.toString())),
                    DataCell(
                      Text(
                        producto?.nombreProducto ?? 'Producto no disponible',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    DataCell(
                      Text(
                        detalle.cantidad.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(Text(formatearPrecio(detalle.precioUnitario))),
                    DataCell(
                      Text(
                        formatearPrecio(subtotal),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          const Divider(height: 24),

          // TOTAL
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'Total: ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                formatearPrecio(ventaConPersona.venta.total),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Clases auxiliares para manejar las relaciones
class VentaConPersona {
  final Venta venta;
  final Persona? persona;

  VentaConPersona({required this.venta, this.persona});
}

class DetalleVentaConProducto {
  final DetalleVenta detalle;
  final Producto? producto;

  DetalleVentaConProducto({required this.detalle, this.producto});
}
