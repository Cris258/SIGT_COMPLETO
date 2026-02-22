  import 'dart:io';
  import 'package:flutter/foundation.dart' show kIsWeb;

  class AppConfig {
    static String get baseUrl {
      // WEB
      if (kIsWeb) {
        return "http://localhost:3001/api";
      }

      // ANDROID
      if (Platform.isAndroid) {
        return "http://10.0.2.2:3001/api";
      }

      // iOS
      if (Platform.isIOS) {
        return "http://localhost:3001/api";
      }

      // Desktop (Windows / Mac / Linux)
      return "http://localhost:3001/api";
    }

    //   FUNCIONES DINÁMICAS

    /// Ruta base para cualquier endpoint
    static String endpoint(String name) => "$baseUrl/$name";

    /// Para rutas con ID (CRUD general)
    static String byId(String name, dynamic id) => "$baseUrl/$name/$id";

    /// Para acciones como login, logout, search, etc.
    static String action(String name, String action) =>
        "$baseUrl/$name/$action";

    //   HEADERS
    static Map<String, String> headers = {
      "Content-Type": "application/json",
    };
  }
