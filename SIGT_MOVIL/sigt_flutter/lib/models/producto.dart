class Producto {
  int? idProducto;
  String nombreProducto;
  String color;
  String talla;
  String estampado;
  int stock;
  double precio;

  Producto({
    this.idProducto,
    required this.nombreProducto,
    required this.color,
    required this.talla,
    required this.estampado,
    required this.stock,
    required this.precio,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      idProducto: json['idProducto'],
      nombreProducto: json['NombreProducto'],
      color: json['Color'],
      talla: json['Talla'],
      estampado: json['Estampado'],
      stock: json['Stock'],
      precio: (json['Precio'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idProducto != null) 'idProducto': idProducto,
      'NombreProducto': nombreProducto,
      'Color': color,
      'Talla': talla,
      'Estampado': estampado,
      'Stock': stock,
      'Precio': precio,
    };
  }
}
