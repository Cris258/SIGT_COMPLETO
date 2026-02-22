class VentaHistorial {
  final int idVenta;
  final DateTime fechaVenta;
  final double total;
  final String estado;
  final String? direccionEntrega;
  final String? ciudad;
  final String? departamento;
  final List<DetalleVentaHistorial> detalles;

  VentaHistorial({
    required this.idVenta,
    required this.fechaVenta,
    required this.total,
    required this.estado,
    this.direccionEntrega,
    this.ciudad,
    this.departamento,
    required this.detalles,
  });

  factory VentaHistorial.fromJson(Map<String, dynamic> json) {
    return VentaHistorial(
      idVenta: json['idVenta'] ?? 0,
      fechaVenta: DateTime.parse(
        json['FechaVenta'] ?? DateTime.now().toIso8601String(),
      ),
      total: (json['Total'] ?? 0).toDouble(),
      estado: json['Estado'] ?? 'Pendiente',
      direccionEntrega: json['DireccionEntrega'],
      ciudad: json['Ciudad'],
      departamento: json['Departamento'],
      detalles:
          (json['detalles'] as List<dynamic>?)
              ?.map((detalle) => DetalleVentaHistorial.fromJson(detalle))
              .toList() ??
          [],
    );
  }
}

// El backend debe enviar estos datos expandidos (con nombre del producto, color, talla)
class DetalleVentaHistorial {
  final int? idDetalleVenta;
  final int cantidad;
  final double precioUnitario;
  final int? productoFk;

  // Campos expandidos que vienen del backend (JOIN con producto/inventario)
  final String nombreProducto;
  final String color;
  final String talla;
  final String? imagenUrl; // URL de la imagen del producto

  DetalleVentaHistorial({
    this.idDetalleVenta,
    required this.cantidad,
    required this.precioUnitario,
    this.productoFk,
    required this.nombreProducto,
    required this.color,
    required this.talla,
    this.imagenUrl,
  });

  factory DetalleVentaHistorial.fromJson(Map<String, dynamic> json) {
    print('Detalle recibido: $json');

    // Obtener el valor crudo (puede ser String o List)
    final raw =
        json['ImagenUrl'] ??
        json['Imagen'] ??
        json['imagenUrl'] ??
        json['imagen'] ??
        json['ImagenProducto'] ??
        json['Url'];

    // Si es lista tomar el primer elemento, si es String usarlo directo
    String? rawImageUrl;
    if (raw is List) {
      rawImageUrl = raw.isNotEmpty ? raw.first?.toString() : null;
    } else if (raw is String) {
      rawImageUrl = raw;
    }

    String? finalImageUrl;
    if (rawImageUrl != null &&
        rawImageUrl.isNotEmpty &&
        rawImageUrl != 'null') {
      finalImageUrl = rawImageUrl.startsWith('http')
          ? rawImageUrl
          : 'http://localhost:3001$rawImageUrl';
      print('URL imagen procesada: $finalImageUrl');
    } else {
      print('No se encontró imagen para: ${json['NombreProducto']}');
    }

    return DetalleVentaHistorial(
      idDetalleVenta: json['idDetalleVenta'],
      cantidad: json['Cantidad'] ?? 0,
      precioUnitario: (json['PrecioUnitario'] ?? 0).toDouble(),
      productoFk: json['Producto_FK'],
      nombreProducto: json['NombreProducto'] ?? 'Sin nombre',
      color: json['Color'] ?? 'Sin color',
      talla: json['Talla'] ?? 'Sin talla',
      imagenUrl: finalImageUrl,
    );
  }
}
