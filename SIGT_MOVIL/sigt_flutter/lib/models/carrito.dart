class Carrito {
  int? idCarrito;
  DateTime fechaCreacion;
  String estado;
  int personaFk;

  Carrito({
    this.idCarrito,
    required this.fechaCreacion,
    required this.estado,
    required this.personaFk,
  });

  factory Carrito.fromJson(Map<String, dynamic> json) {
    return Carrito(
      idCarrito: json['idCarrito'],
      fechaCreacion: DateTime.parse(json['FechaCreacion']),
      estado: json['Estado'],
      personaFk: json['Persona_FK'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idCarrito != null) 'idCarrito': idCarrito,
      'FechaCreacion': fechaCreacion.toIso8601String(),
      'Estado': estado,
      'Persona_FK': personaFk,
    };
  }
}
