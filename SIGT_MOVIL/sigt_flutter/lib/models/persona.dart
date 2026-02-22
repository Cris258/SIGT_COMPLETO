// models/persona.dart

class Persona {
  int? idPersona;
  int numeroDocumento;
  String tipoDocumento;
  String primerNombre;
  String? segundoNombre;
  String primerApellido;
  String? segundoApellido;
  String telefono;
  String correo;
  String password;
  int rolFk;
  int estadoPersonaFk;

  //  Campos para mostrar (vienen de las relaciones)
  String? nombreRol;
  String? nombreEstado;

  Persona({
    this.idPersona,
    required this.numeroDocumento,
    required this.tipoDocumento,
    required this.primerNombre,
    this.segundoNombre,
    required this.primerApellido,
    this.segundoApellido,
    required this.telefono,
    required this.correo,
    required this.password,
    required this.rolFk,
    required this.estadoPersonaFk,
    this.nombreRol,
    this.nombreEstado,
  });

  factory Persona.fromJson(Map<String, dynamic> json) {
    final data = json['body'] ?? json;
    
    return Persona(
      idPersona: data['idPersona'],
      numeroDocumento: data['NumeroDocumento'] ?? 0,
      tipoDocumento: data['TipoDocumento'] ?? '',
      primerNombre: data['Primer_Nombre'] ?? '',
      segundoNombre: data['Segundo_Nombre'],
      primerApellido: data['Primer_Apellido'] ?? '',
      segundoApellido: data['Segundo_Apellido'],
      telefono: data['Telefono']?.toString() ?? '',
      correo: data['Correo'] ?? '',
      password: data['Password'] ?? '',
      rolFk: data['Rol_FK'] ?? 0,
      estadoPersonaFk: data['EstadoPersona_FK'] ?? 0,
      nombreRol: data['Rol']?['NombreRol'] ?? data['NombreRol'],
      nombreEstado: data['EstadoPersona']?['NombreEstado'] ?? data['NombreEstado'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idPersona != null) 'idPersona': idPersona,
      'NumeroDocumento': numeroDocumento,
      'TipoDocumento': tipoDocumento,
      'Primer_Nombre': primerNombre,
      if (segundoNombre != null && segundoNombre!.isNotEmpty) 'Segundo_Nombre': segundoNombre,
      'Primer_Apellido': primerApellido,
      if (segundoApellido != null && segundoApellido!.isNotEmpty) 'Segundo_Apellido': segundoApellido,
      'Telefono': telefono,
      'Correo': correo,
      'Password': password,
      'Rol_FK': rolFk,
      'EstadoPersona_FK': estadoPersonaFk,
    };
  }

  // Para actualizar desde el perfil del usuario (solo campos permitidos)
  Map<String, dynamic> toJsonUpdate() {
    return {
      'Primer_Nombre': primerNombre,
      if (segundoNombre != null && segundoNombre!.isNotEmpty) 'Segundo_Nombre': segundoNombre,
      'Primer_Apellido': primerApellido,
      if (segundoApellido != null && segundoApellido!.isNotEmpty) 'Segundo_Apellido': segundoApellido,
      'Telefono': telefono,
    };
  }

  // Para actualizar desde el panel de administración (todos los campos)
  Map<String, dynamic> toJsonAdminUpdate() {
    return {
      'NumeroDocumento': numeroDocumento,
      'TipoDocumento': tipoDocumento,
      'Primer_Nombre': primerNombre,
      if (segundoNombre != null && segundoNombre!.isNotEmpty) 'Segundo_Nombre': segundoNombre,
      'Primer_Apellido': primerApellido,
      if (segundoApellido != null && segundoApellido!.isNotEmpty) 'Segundo_Apellido': segundoApellido,
      'Telefono': telefono,
      'Correo': correo,
      'Rol_FK': rolFk,
      'EstadoPersona_FK': estadoPersonaFk,
    };
  }

  
  // Método útil para obtener el nombre completo
  String get nombreCompleto {
    final partes = [
      primerNombre,
      if (segundoNombre != null && segundoNombre!.isNotEmpty) segundoNombre,
      primerApellido,
      if (segundoApellido != null && segundoApellido!.isNotEmpty) segundoApellido,
    ];
    return partes.join(' ');
  }

  //  Método útil para saber si está activo
  bool get estaActivo => estadoPersonaFk == 1;

  //  Método para copiar con cambios (útil para ediciones locales)
  Persona copyWith({
    int? idPersona,
    int? numeroDocumento,
    String? tipoDocumento,
    String? primerNombre,
    String? segundoNombre,
    String? primerApellido,
    String? segundoApellido,
    String? telefono,
    String? correo,
    String? password,
    int? rolFk,
    int? estadoPersonaFk,
    String? nombreRol,
    String? nombreEstado,
  }) {
    return Persona(
      idPersona: idPersona ?? this.idPersona,
      numeroDocumento: numeroDocumento ?? this.numeroDocumento,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      primerNombre: primerNombre ?? this.primerNombre,
      segundoNombre: segundoNombre ?? this.segundoNombre,
      primerApellido: primerApellido ?? this.primerApellido,
      segundoApellido: segundoApellido ?? this.segundoApellido,
      telefono: telefono ?? this.telefono,
      correo: correo ?? this.correo,
      password: password ?? this.password,
      rolFk: rolFk ?? this.rolFk,
      estadoPersonaFk: estadoPersonaFk ?? this.estadoPersonaFk,
      nombreRol: nombreRol ?? this.nombreRol,
      nombreEstado: nombreEstado ?? this.nombreEstado,
    );
  }
}