import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/carrito_item_model.dart';
import '../models/carrito.dart';

class CarritoService {
  // Cargar carrito desde SharedPreferences
  Future<List<CarritoItem>> cargarCarritoLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final carritoStr = prefs.getString('carro');

      if (carritoStr == null || carritoStr == 'null' || carritoStr.isEmpty) {
        return [];
      }

      // Parsear el string que viene como lista de Maps
      final List<dynamic> carritoJson = json.decode(carritoStr);
      return carritoJson.map((item) => CarritoItem.fromJson(item)).toList();
    } catch (e) {
      print('Error cargando carrito local: $e');
      return [];
    }
  }

  // Guardar carrito en SharedPreferences
  Future<void> guardarCarritoLocal(List<CarritoItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final carritoJson = items.map((item) => item.toJson()).toList();
      await prefs.setString('carro', json.encode(carritoJson));
      print(' Carrito guardado localmente');
    } catch (e) {
      print(' Error guardando carrito local: $e');
    }
  }

  // Limpiar carrito local
  Future<void> limpiarCarritoLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('carro');
      print(' Carrito local limpiado');
    } catch (e) {
      print(' Error limpiando carrito local: $e');
    }
  }

  // PROCESO DE COMPRA COMPLETO
  Future<Map<String, dynamic>> finalizarCompra(
    List<CarritoItem> productosAComprar, {
    required String direccionEntrega,
    required String ciudad,
    required String departamento,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      //  Obtener idPersona del objeto current_user
      final currentUserStr = prefs.getString('current_user');
      int? idPersona;

      if (currentUserStr != null) {
        final currentUser = json.decode(currentUserStr);
        idPersona = currentUser['idPersona'] ?? currentUser['id'];
      }

      if (token == null || idPersona == null) {
        return {
          'success': false,
          'message':
              'No se encontró información del usuario. Inicia sesión nuevamente.',
        };
      }

      print(' Iniciando proceso de compra...');
      print(' Productos a comprar: ${productosAComprar.length}');
      print(' Dirección: $direccionEntrega');
      print(' Ciudad: $ciudad');
      print(' Departamento: $departamento');

      // PASO 1: Crear el Carrito
      final carritoData = Carrito(
        fechaCreacion: DateTime.now(),
        estado: 'Pendiente',
        personaFk: idPersona,
      );

      final carritoResponse = await http.post(
        Uri.parse(AppConfig.endpoint('carrito')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(carritoData.toJson()),
      );

      if (carritoResponse.statusCode != 200 &&
          carritoResponse.statusCode != 201) {
        final error = json.decode(carritoResponse.body);
        throw Exception(error['message'] ?? 'Error al crear el carrito');
      }

      final carritoResult = json.decode(carritoResponse.body);
      final idCarrito = carritoResult['body']?['id'] ??
          carritoResult['id'] ??
          carritoResult['body']?['idCarrito'] ??
          carritoResult['idCarrito'];

      if (idCarrito == null) {
        throw Exception('No se pudo obtener el ID del carrito');
      }

      print(' Carrito creado con ID: $idCarrito');

      // PASO 2: Crear DetalleCarrito para cada producto
      for (var producto in productosAComprar) {
        final detalleCarritoData = {
          'Carrito_FK': idCarrito,
          'Producto_FK': producto.idProducto,
          'Cantidad': producto.cantidad,
        };

        final detalleResponse = await http.post(
          Uri.parse(AppConfig.endpoint('detallecarrito')),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(detalleCarritoData),
        );

        if (detalleResponse.statusCode != 200 &&
            detalleResponse.statusCode != 201) {
          final error = json.decode(detalleResponse.body);
          throw Exception(
            'Error al guardar detalle de ${producto.nombre}: ${error['message']}',
          );
        }
      }

      print(' DetalleCarrito creado');

      // PASO 3: Crear la Venta
      final totalVenta = productosAComprar.fold<double>(
        0,
        (sum, prod) => sum + (prod.precio * prod.cantidad),
      );

      final ventaData = {
        'Persona_FK': idPersona,
        'Fecha': DateTime.now().toIso8601String().split('T')[0],
        'Total': totalVenta,
        'DireccionEntrega': direccionEntrega,
        'Ciudad': ciudad,
        'Departamento': departamento,
      };

      print(' ========================================');
      print(' DATOS QUE SE ENVÍAN AL CREAR VENTA:');
      print(' ========================================');
      print('URL: ${AppConfig.endpoint('venta')}');
      print('Datos: ${json.encode(ventaData)}');
      print('Token: ${token.substring(0, 20)}...');
      print(' ========================================');

      final ventaResponse = await http.post(
        Uri.parse(AppConfig.endpoint('venta')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(ventaData),
      );

      print(' Respuesta del servidor:');
      print('Status: ${ventaResponse.statusCode}');
      print('Body: ${ventaResponse.body}');

      if (ventaResponse.statusCode != 200 && ventaResponse.statusCode != 201) {
        final error = json.decode(ventaResponse.body);
        throw Exception(
          error['message'] ?? error['Message'] ?? 'Error al crear la venta',
        );
      }

      final ventaResult = json.decode(ventaResponse.body);
      final idVenta = ventaResult['id'] ??
          ventaResult['body']?['id'] ??
          ventaResult['body']?['idVenta'] ??
          ventaResult['idVenta'];

      if (idVenta == null) {
        throw Exception('No se pudo obtener el ID de la venta');
      }

      print(' Venta creada con ID: $idVenta');

      // PASO 4: Crear DetalleVenta para cada producto
      for (var producto in productosAComprar) {
        final detalleVentaData = {
          'Venta_FK': idVenta,
          'Producto_FK': producto.idProducto,
          'Cantidad': producto.cantidad,
          'PrecioUnitario': producto.precio,
        };

        final detalleResponse = await http.post(
          Uri.parse(AppConfig.endpoint('detalleventa')),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(detalleVentaData),
        );

        if (detalleResponse.statusCode != 200 &&
            detalleResponse.statusCode != 201) {
          final error = json.decode(detalleResponse.body);
          throw Exception(
            'Error al guardar detalle de venta de ${producto.nombre}: ${error['message']}',
          );
        }
      }
      print(' DetalleVenta creado');

      // PASO 5: Crear Movimientos de Salida
      for (var producto in productosAComprar) {
        final movimientoData = {
          'Tipo': 'Salida',
          'Cantidad': producto.cantidad,
          'Fecha': DateTime.now().toIso8601String(),
          'Motivo': 'Venta #$idVenta - ${producto.nombre}',
          'Persona_FK': idPersona,
          'Producto_FK': producto.idProducto,
        };

        final movimientoResponse = await http.post(
          Uri.parse(AppConfig.endpoint('movimiento')),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(movimientoData),
        );

        if (movimientoResponse.statusCode != 200 &&
            movimientoResponse.statusCode != 201) {
          final error = json.decode(movimientoResponse.body);
          throw Exception(
            'Error al registrar movimiento de ${producto.nombre}: ${error['Message'] ?? error['message']}',
          );
        }
      }

      print('Movimientos de salida creados');

      // PASO 6: Actualizar Stock
      for (var producto in productosAComprar) {
        final nuevoStock = producto.stock - producto.cantidad;

        final stockResponse = await http.put(
          Uri.parse(AppConfig.byId('producto', producto.idProducto)),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({'Stock': nuevoStock}),
        );

        if (stockResponse.statusCode != 200) {
          final error = json.decode(stockResponse.body);
          throw Exception(
            'Error al actualizar stock de ${producto.nombre}: ${error['message']}',
          );
        }
      }

      print(' Stock actualizado');

      // PASO 7: Actualizar estado del carrito
      await http.put(
        Uri.parse(AppConfig.byId('carrito', idCarrito)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'Estado': 'completado'}),
      );

      print('Carrito completado');

      return {
        'success': true,
        'message': '¡Compra realizada exitosamente!',
        'idVenta': idVenta,
      };
    } catch (e) {
      print(' Error en finalizarCompra: $e');
      return {'success': false, 'message': 'Error al procesar la compra: $e'};
    }
  }
}