class EstadoPersona {
  int? idEstadoPersona;
  String nombreEstado;
  String? descriptionEstado;

  EstadoPersona({
    this.idEstadoPersona,
    required this.nombreEstado,
    this.descriptionEstado,
  });

  factory EstadoPersona.fromJson(Map<String, dynamic> json) {
    return EstadoPersona(
      idEstadoPersona: json['idEstadoPersona'],
      nombreEstado: json['NombreEstado'],
      descriptionEstado: json['DescriptionEstado'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idEstadoPersona != null) 'idEstadoPersona': idEstadoPersona,
      'NombreEstado': nombreEstado,
      'DescriptionEstado': descriptionEstado,
    };
  }
}
