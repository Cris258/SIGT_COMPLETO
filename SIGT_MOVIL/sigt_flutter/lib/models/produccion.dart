class Produccion {
  int? idProduccion;
  DateTime fechaProduccion;
  int cantidadProducida;
  int personaFk;
  int detalleTareaFk;

  Produccion({
    this.idProduccion,
    required this.fechaProduccion,
    required this.cantidadProducida,
    required this.personaFk,
    required this.detalleTareaFk,
  });

  factory Produccion.fromJson(Map<String, dynamic> json) {
    return Produccion(
      idProduccion: json['idProduccion'],
      fechaProduccion: DateTime.parse(json['FechaProduccion']),
      cantidadProducida: json['CantidadProducida'],
      personaFk: json['Persona_FK'],
      detalleTareaFk: json['DetalleTarea_FK'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idProduccion != null) 'idTarea': idProduccion,
      'FechaProduccion': fechaProduccion.toIso8601String(),
      'CantidadProducida': cantidadProducida,
      'Persona_FK': personaFk,
      'DetalleTarea_FK': detalleTareaFk,
    };
  }
}
