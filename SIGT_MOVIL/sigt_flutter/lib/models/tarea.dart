class Tarea {
  int? idTarea;
  String? descripcion;
  DateTime fechaAsignacion;
  DateTime fechaLimite;
  String estadoTarea;
  String prioridad;
  int personaFk;
  int productoFk;

  Tarea({
    this.idTarea,
    this.descripcion,
    required this.fechaAsignacion,
    required this.fechaLimite,
    required this.estadoTarea,
    required this.prioridad,
    required this.personaFk,
    required this.productoFk,
  });

  factory Tarea.fromJson(Map<String, dynamic> json) {
    return Tarea(
      idTarea: json['idTarea'],
      descripcion: json['Descripcion'],
      fechaAsignacion: DateTime.parse(json['FechaAsignacion']),
      fechaLimite: DateTime.parse(json['FechaLimite']),
      estadoTarea: json['EstadoTarea'],
      prioridad: json['Prioridad'],
      personaFk: json['Persona_FK'],
      productoFk: json['Producto_FK'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idTarea != null) 'idTarea': idTarea,
      'Descripcion': descripcion,
      'FechaAsignacion': fechaAsignacion.toIso8601String(),
      'FechaLimite': fechaLimite.toIso8601String(),
      'EstadoTarea': estadoTarea,
      'Prioridad': prioridad,
      'Persona_FK': personaFk,
      'Producto_FK': productoFk,
    };
  }
}
