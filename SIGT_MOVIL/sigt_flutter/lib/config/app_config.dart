class AppConfig {
  static String get baseUrl {
    return "https://sigt-backend.onrender.com/api";
  }

  /// Ruta base para cualquier endpoint
  static String endpoint(String name) => "$baseUrl/$name";

  /// Para rutas con ID (CRUD general)
  static String byId(String name, dynamic id) => "$baseUrl/$name/$id";

  /// Para acciones como login, logout, search, etc.
  static String action(String name, String action) =>
      "$baseUrl/$name/$action";

  static Map<String, String> headers = {
    "Content-Type": "application/json",
  };
}