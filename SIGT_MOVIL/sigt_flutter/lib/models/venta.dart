class Venta {
  int? idVenta;
  DateTime fecha;
  double total;
  String direccionEntrega;
  String ciudad;
  String departamento;
  int personaFk;

  Venta({
    this.idVenta,
    required this.fecha,
    required this.total,
    required this.direccionEntrega,
    required this.ciudad,
    required this.departamento,
    required this.personaFk,
  });

  /// FROM JSON (cuando viene del backend)
  factory Venta.fromJson(Map<String, dynamic> json) {
    return Venta(
      idVenta: json['idVenta'],
      fecha: DateTime.parse(json['Fecha']),
      total: (json['Total'] as num).toDouble(),
      direccionEntrega: json['DireccionEntrega'],
      ciudad: json['Ciudad'],
      departamento: json['Departamento'],
      personaFk: json['Persona_FK'],
    );
  }

  /// TO JSON (cuando envías al backend)
  Map<String, dynamic> toJson() {
    return {
      if (idVenta != null) 'idVenta': idVenta,
      'Fecha': fecha.toIso8601String(),
      'Total': total,
      'DireccionEntrega': direccionEntrega,
      'Ciudad': ciudad,
      'Departamento': departamento,
      'Persona_FK': personaFk,
    };
  }
}
