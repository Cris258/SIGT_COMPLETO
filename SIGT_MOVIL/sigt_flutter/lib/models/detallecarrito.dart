class DetalleCarrito {
  int? idDetalleCarrito;
  int cantidad;
  int carritoFk;
  int productoFk;

  DetalleCarrito({
    this.idDetalleCarrito,
    required this.cantidad,
    required this.carritoFk,
    required this.productoFk,
  });

  factory DetalleCarrito.fromJson(Map<String, dynamic> json) {
    return DetalleCarrito(
      idDetalleCarrito: json['idDetalleCarrito'],
      cantidad: json['Cantidad'],
      carritoFk: json['Carrito_FK'],
      productoFk: json['Producto_FK'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idDetalleCarrito != null) 'idDetalleCarrito': idDetalleCarrito,
      'Cantidad': cantidad,
      'Carrito_FK': carritoFk,
      'Producto_FK': productoFk,
    };
  }
}
