class DetalleVenta {
  int? idDetalleVenta;
  int cantidad;
  double precioUnitario;
  int productoFk;
  int ventaFk;

  DetalleVenta({
    this.idDetalleVenta,
    required this.cantidad,
    required this.precioUnitario,
    required this.productoFk,
    required this.ventaFk,
  });

  factory DetalleVenta.fromJson(Map<String, dynamic> json) {
    return DetalleVenta(
      idDetalleVenta: json['idDetalleVenta'],
      cantidad: json['Cantidad'],
      precioUnitario: (json['PrecioUnitario'] as num).toDouble(),
      productoFk: json['Producto_FK'],
      ventaFk: json['Venta_FK'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idDetalleVenta != null) 'idDetalleVenta': idDetalleVenta,
      'Cantidad': cantidad,
      'PrecioUnitario': precioUnitario,
      'Producto_FK': productoFk,
      'Venta_FK': ventaFk,
    };
  }
}
  