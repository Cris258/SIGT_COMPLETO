class CarritoItem {
  final int idProducto;
  final String nombre;
  final double precio;
  final String imagen;
  final String color;
  final String talla;
  int cantidad;
  final int stock;

  CarritoItem({
    required this.idProducto,
    required this.nombre,
    required this.precio,
    required this.imagen,
    required this.color,
    required this.talla,
    required this.cantidad,
    required this.stock,
  });

  // Convertir desde JSON (lo que guardaste en SharedPreferences)
  factory CarritoItem.fromJson(Map<String, dynamic> json) {
    return CarritoItem(
      idProducto: json['idProducto'] as int,
      nombre: json['nombre'] as String,
      precio: (json['precio'] as num).toDouble(),
      imagen: json['imagen'] as String,
      color: json['color'] as String,
      talla: json['talla'] as String,
      cantidad: json['cantidad'] as int,
      stock: json['stock'] as int,
    );
  }

  // Convertir a JSON (para guardar en SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'idProducto': idProducto,
      'nombre': nombre,
      'precio': precio,
      'imagen': imagen,
      'color': color,
      'talla': talla,
      'cantidad': cantidad,
      'stock': stock,
    };
  }

  // Calcular subtotal
  double get subtotal => precio * cantidad;

  // Copiar con modificaciones
  CarritoItem copyWith({
    int? idProducto,
    String? nombre,
    double? precio,
    String? imagen,
    String? color,
    String? talla,
    int? cantidad,
    int? stock,
  }) {
    return CarritoItem(
      idProducto: idProducto ?? this.idProducto,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      imagen: imagen ?? this.imagen,
      color: color ?? this.color,
      talla: talla ?? this.talla,
      cantidad: cantidad ?? this.cantidad,
      stock: stock ?? this.stock,
    );
  }
}