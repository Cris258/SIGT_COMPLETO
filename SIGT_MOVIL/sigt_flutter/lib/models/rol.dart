class Rol {
  int? idRol;
  String nombreRol;
  String? descripcionRol;

  Rol({
    this.idRol,
    required this.nombreRol,
    this.descripcionRol,
  });

  factory Rol.fromJson(Map<String, dynamic> json) {
    return Rol(
      idRol: json['idRol'],
      nombreRol: json['NombreRol'],
      descripcionRol: json['DescripcionRol'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idRol != null) 'idRol': idRol,
      'NombreRol': nombreRol,
      'DescripcionRol': descripcionRol,
    };
  }
}
