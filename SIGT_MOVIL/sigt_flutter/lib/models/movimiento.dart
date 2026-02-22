class Movimiento {
  int? idMovimiento;
  String tipo; 
  int cantidad;
  DateTime fecha;
  String? motivo;
  int personaFk;
  int productoFk;
  int? produccionFk;

  Movimiento({
    this.idMovimiento,
    required this.tipo,
    required this.cantidad,
    required this.fecha,
    this.motivo,
    required this.personaFk,
    required this.productoFk,
    this.produccionFk,
  });

  factory Movimiento.fromJson(Map<String, dynamic> json) {
    return Movimiento(
      idMovimiento: json['idMovimiento'],
      tipo: json['Tipo'],
      cantidad: json['Cantidad'],
      fecha: DateTime.parse(json['Fecha']),
      motivo: json['Motivo'],
      personaFk: json['Persona_FK'],
      productoFk: json['Producto_FK'],
      produccionFk: json['Produccion_FK'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idMovimiento != null) 'idMovimiento': idMovimiento,
      'Tipo': tipo,
      'Cantidad': cantidad,
      'Fecha': fecha.toIso8601String(),
      'Motivo': motivo,
      'Persona_FK': personaFk,
      'Producto_FK': productoFk,
      'Produccion_FK': produccionFk,
    };
  }
}
