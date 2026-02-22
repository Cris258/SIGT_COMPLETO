class DetalleProduccion {
  int? idDetalleProduccion;
  int cantidad;
  int productoFk;
  int produccionFk;

  DetalleProduccion({
    this.idDetalleProduccion,
    required this.cantidad,
    required this.productoFk,
    required this.produccionFk,
  });

  factory DetalleProduccion.fromJson(Map<String, dynamic> json) {
    return DetalleProduccion(
      idDetalleProduccion: json['idDetalleProduccion'],
      cantidad: json['Cantidad'],
      productoFk: json['Producto_FK'],
      produccionFk: json['Produccion_FK'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idDetalleProduccion != null) 'idDetalleProduccion': idDetalleProduccion,
      'Cantidad': cantidad,
      'Producto_FK': productoFk,
      'Produccion_FK': produccionFk,
    };
  }
}
