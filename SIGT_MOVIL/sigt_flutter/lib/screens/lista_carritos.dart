import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/carrito.dart';
import '../models/detallecarrito.dart';
import '../models/producto.dart';
import '../models/persona.dart';
import '../widgets/header_widget.dart';
import '../widgets/footer_widget.dart';
import '../widgets/widgetsAdmin/modal_editar_carrito.dart';
import '../widgets/widgetsAdmin/modal_eliminar_carrito.dart';
import '../services/pdf_download_service.dart';

class ListaCarritos extends StatefulWidget {
  const ListaCarritos({super.key});

  @override
  State<ListaCarritos> createState() => _ListaCarritosState();
}

class _ListaCarritosState extends State<ListaCarritos> {
  List<Map<String, dynamic>> carritos = [];
  Map<int, List<Map<String, dynamic>>> detallesCarrito = {};
  bool loading = true;
  String search = "";
  int? carritoExpandido;

  @override
  void initState() {
    super.initState();
    cargarCarritos();
  }

  Future<void> cargarCarritos() async {
    setState(() => loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      print('Cargando carritos desde: ${AppConfig.endpoint('carrito')}');

      final response = await http.get(
        Uri.parse(AppConfig.endpoint('carrito')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> carritosData = data['body'];

        List<Map<String, dynamic>> carritosConCliente = [];
        for (var carritoJson in carritosData) {
          final carrito = Carrito.fromJson(carritoJson);
          Map<String, dynamic> carritoMap = {
            'carrito': carrito,
            'persona': null,
          };

          try {
            final personaResponse = await http.get(
              Uri.parse(AppConfig.byId('persona', carrito.personaFk)),
              headers: {'Authorization': 'Bearer $token'},
            );

            if (personaResponse.statusCode == 200) {
              final personaData = json.decode(personaResponse.body);
              carritoMap['persona'] = Persona.fromJson(personaData);
            }
          } catch (e) {
            print('Error cargando cliente: $e');
          }

          carritosConCliente.add(carritoMap);
        }

        setState(() {
          carritos = carritosConCliente;
          carritos.sort((a, b) {
            final fechaA = a['carrito'].fechaCreacion;
            final fechaB = b['carrito'].fechaCreacion;
            return fechaB.compareTo(fechaA);
          });
          loading = false;
        });
      } else {
        throw Exception('Error al obtener carritos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error general: $e');
      setState(() => loading = false);
      _mostrarError('Error al cargar carritos: $e');
    }
  }

  Future<void> cargarDetallesCarrito(int idCarrito) async {
    // Si ya está expandido, lo colapsamos
    if (carritoExpandido == idCarrito) {
      setState(() => carritoExpandido = null);
      return;
    }

    // Si ya tenemos los detalles en caché, solo expandimos
    if (detallesCarrito.containsKey(idCarrito)) {
      setState(() => carritoExpandido = idCarrito);
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      // URL para obtener detalles del carrito
      final url = AppConfig.endpoint('detallecarrito/carrito/$idCarrito');
      print('Cargando detalles desde: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Detalles response status: ${response.statusCode}');
      print('Detalles response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> detallesData = data['body'];

        print('Total detalles recibidos: ${detallesData.length}');
        print('Primer detalle completo: ${json.encode(detallesData.first)}');

        if (detallesData.isEmpty) {
          _mostrarError('Este carrito no tiene productos');
          return;
        }

        List<Map<String, dynamic>> detallesConProducto = [];
        for (var detalleJson in detallesData) {
          print('Procesando detalle: ${json.encode(detalleJson)}');

          final detalle = DetalleCarrito.fromJson(detalleJson);

          // Verificar si el producto ya viene en la respuesta (Sequelize include)
          Producto? producto;
          if (detalleJson['Producto'] != null) {
            print('Producto encontrado en respuesta Sequelize');
            try {
              // CONVERTIR EL PRECIO ANTES DE PARSEAR
              var productoJson = Map<String, dynamic>.from(
                detalleJson['Producto'],
              );
              if (productoJson['Precio'] is String) {
                productoJson['Precio'] = double.parse(productoJson['Precio']);
              }

              producto = Producto.fromJson(productoJson);
              print('Producto parseado: ${producto.nombreProducto}');
            } catch (e) {
              print('Error parseando producto de Sequelize: $e');
            }
          }

          // Si no vino el producto, hacer petición individual
          if (producto == null) {
            print(
              'Producto no encontrado en respuesta, haciendo petición individual...',
            );
            try {
              final productoResponse = await http.get(
                Uri.parse(AppConfig.byId('producto', detalle.productoFk)),
                headers: {'Authorization': 'Bearer $token'},
              );

              if (productoResponse.statusCode == 200) {
                final productoData = json.decode(productoResponse.body);
                print(
                  'Respuesta producto individual: ${productoResponse.body}',
                );

                Map<String, dynamic> productoJson;
                if (productoData['body'] != null) {
                  productoJson = Map<String, dynamic>.from(
                    productoData['body'],
                  );
                } else {
                  productoJson = Map<String, dynamic>.from(productoData);
                }

                // CONVERTIR EL PRECIO AQUÍ TAMBIÉN
                if (productoJson['Precio'] is String) {
                  productoJson['Precio'] = double.parse(productoJson['Precio']);
                }

                producto = Producto.fromJson(productoJson);
                print(
                  'Producto cargado individualmente: ${producto.nombreProducto}',
                );
              }
            } catch (e) {
              print('Error cargando producto individual: $e');
            }
          }

          Map<String, dynamic> detalleMap = {
            'detalle': detalle,
            'producto': producto,
          };

          detallesConProducto.add(detalleMap);
        }

        setState(() {
          detallesCarrito[idCarrito] = detallesConProducto;
          carritoExpandido = idCarrito;
        });

        _mostrarExito('Detalles cargados correctamente');
      } else if (response.statusCode == 404) {
        _mostrarError('No se encontraron detalles para este carrito');
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error al cargar detalles: $e');
      _mostrarError('Error al cargar detalles del carrito: $e');
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

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
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

  List<Map<String, dynamic>> get carritosFiltrados {
    if (search.isEmpty) return carritos;

    String s = search.toLowerCase();
    return carritos.where((c) {
      final Carrito carrito = c['carrito'];
      final Persona? persona = c['persona'];

      String nombreCliente = '';
      if (persona != null) {
        nombreCliente = persona.nombreCompleto.toLowerCase();
      }

      return carrito.idCarrito.toString().contains(s) ||
          carrito.estado.toLowerCase().contains(s) ||
          carrito.personaFk.toString().contains(s) ||
          nombreCliente.contains(s);
    }).toList();
  }

  Color getEstadoColor(String estado) {
    switch (estado) {
      case 'Completado':
        return const Color.fromARGB(255, 95, 229, 99);
      case 'Cancelado':
        return Colors.red;
      case 'Pendiente':
        return const Color.fromARGB(255, 248, 232, 59);
      default:
        return Colors.grey;
    }
  }

  void abrirModalEditar(Map<String, dynamic> carritoData) {
    showDialog(
      context: context,
      builder: (context) => ModalEditarCarrito(
        carrito: carritoData['carrito'],
        onGuardar: (carritoActualizado) {
          setState(() {
            int index = carritos.indexWhere(
              (c) => c['carrito'].idCarrito == carritoActualizado.idCarrito,
            );
            if (index != -1) {
              carritos[index]['carrito'] = carritoActualizado;
            }
          });
          _mostrarExito('Carrito actualizado correctamente');
        },
      ),
    );
  }

  void abrirModalEliminar(Map<String, dynamic> carritoData) {
    showDialog(
      context: context,
      builder: (context) => ModalEliminarCarrito(
        carrito: carritoData['carrito'],
        onConfirmar: (carritoEliminado) {
          setState(() {
            carritos.removeWhere(
              (c) => c['carrito'].idCarrito == carritoEliminado.idCarrito,
            );
          });
          _mostrarExito('Carrito eliminado correctamente');
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
                        Icons.shopping_basket_rounded,
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
                            'Lista de Carritos',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Gestiona carritos activos y abandonados',
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
                            await PdfDownloadService.descargarReporteCarritosAbandonados(
                              context,
                            );
                          },
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: const Text(
                      'Reporte de Abandonados',
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
                  Icons.shopping_basket_rounded,
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
                      'Lista de Carritos Registrados',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Gestiona carritos activos, pendientes y abandonados',
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
                        await PdfDownloadService.descargarReporteCarritosAbandonados(
                          context,
                        );
                      },
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: const Text(
                  'Reporte Carritos Abandonados',
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
              Text('Cargando carritos...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          HeaderWidget(),
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
                          hintText: "Buscar por ID, estado, cliente...",
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

                    // LISTA DE CARRITOS
                    _buildListaCarritos(),
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

  Widget _buildListaCarritos() {
    if (carritosFiltrados.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            search.isNotEmpty
                ? 'No se encontraron resultados'
                : 'No hay carritos registrados',
            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return Column(
      children: carritosFiltrados.asMap().entries.map((entry) {
        final index = entry.key;
        final carritoData = entry.value;
        final Carrito carrito = carritoData['carrito'];
        final Persona? persona = carritoData['persona'];
        final bool expandido = carritoExpandido == carrito.idCarrito;
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
              // INFORMACIÓN PRINCIPAL DEL CARRITO
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Row(
                  children: [
                    // ID SECUENCIAL
                    SizedBox(
                      width: 60,
                      child: Text(
                        '#$numeroSecuencial',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // ESTADO
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: getEstadoColor(carrito.estado),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        carrito.estado,
                        style: TextStyle(
                          color: carrito.estado == 'Pendiente'
                              ? Colors.black
                              : Colors.white,
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
                        // Ver detalles
                        IconButton(
                          icon: Icon(
                            expandido ? Icons.visibility_off : Icons.visibility,
                            color: Colors.blue,
                          ),
                          onPressed: () =>
                              cargarDetallesCarrito(carrito.idCarrito!),
                          tooltip: 'Ver productos',
                        ),

                        // Editar
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => abrirModalEditar(carritoData),
                          tooltip: 'Editar',
                        ),

                        // Eliminar
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => abrirModalEliminar(carritoData),
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
                          Text(formatearFecha(carrito.fechaCreacion)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // DETALLES EXPANDIBLES
              if (expandido) _buildDetallesCarrito(carrito.idCarrito!),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetallesCarrito(int idCarrito) {
    final detalles = detallesCarrito[idCarrito];

    if (detalles == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (detalles.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No hay productos en este carrito'),
      );
    }

    double total = 0;
    for (var d in detalles) {
      final DetalleCarrito detalle = d['detalle'];
      final Producto? producto = d['producto'];
      if (producto != null) {
        total += producto.precio * detalle.cantidad;
      }
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
            'Productos del Carrito',
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
              rows: detalles.map<DataRow>((d) {
                final DetalleCarrito detalle = d['detalle'];
                final Producto? producto = d['producto'];

                final subtotal = producto != null
                    ? producto.precio * detalle.cantidad
                    : 0.0;

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
                    DataCell(
                      Text(
                        producto != null
                            ? '\$${producto.precio.toStringAsFixed(0)}'
                            : 'N/A',
                      ),
                    ),
                    DataCell(
                      Text(
                        '\$${subtotal.toStringAsFixed(0)}',
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
                '\$${total.toStringAsFixed(0)}',
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
