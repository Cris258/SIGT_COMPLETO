import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importación condicional correcta
import 'pdf_download_service_mobile.dart'
    if (dart.library.html) 'pdf_download_service_web.dart';

class PdfDownloadService {
  // URL dinámica según la plataforma
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3001/api/reportes';
    } else if (Platform.isAndroid) {
      // 10.0.2.2 es la IP del host desde el emulador de Android
      return 'http://10.0.2.2:3001/api/reportes';
    } else if (Platform.isIOS) {
      // localhost funciona en el simulador de iOS
      return 'http://localhost:3001/api/reportes';
    } else {
      return 'http://localhost:3001/api/reportes';
    }
  }

  /// Método genérico para descargar cualquier reporte PDF
  static Future<void> _descargarReporte({
    required BuildContext context,
    required String endpoint,
    required String nombreArchivo,
  }) async {
    // Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generando reporte PDF...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Obtener el token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        if (context.mounted) Navigator.pop(context);
        if (context.mounted) {
          _mostrarError(context, 'No se encontró token de autenticación');
        }
        return;
      }

      print('🔗 Conectando a: $baseUrl/$endpoint'); // Debug

      // Hacer petición al backend
      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: El servidor no respondió');
        },
      );

      // Cerrar diálogo de carga
      if (context.mounted) Navigator.pop(context);

      print('📡 Status code: ${response.statusCode}'); // Debug

      if (response.statusCode == 200) {
        // Verificar si estamos en web o móvil
        if (kIsWeb) {
          // Descargar en navegador web usando la función importada
          descargarPdfWeb(response.bodyBytes, nombreArchivo);
        } else {
          // Descargar en móvil
          await _descargarEnMovil(response.bodyBytes, nombreArchivo);
        }

        // Mostrar mensaje de éxito
        if (context.mounted) {
          _mostrarExito(context, 'Reporte descargado exitosamente');
        }
      } else if (response.statusCode == 401) {
        if (context.mounted) {
          _mostrarError(context, 'Sesión expirada. Por favor inicia sesión nuevamente');
        }
      } else {
        if (context.mounted) {
          _mostrarError(context, 'Error al generar el reporte: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('❌ Error completo: $e'); // Debug
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        _mostrarError(context, 'Error al descargar el reporte: $e');
      }
    }
  }

  // ============= MÉTODOS PÚBLICOS PARA CADA REPORTE =============

  /// Descarga el reporte de clientes
  static Future<void> descargarReporteClientes(BuildContext context) async {
    await _descargarReporte(
      context: context,
      endpoint: 'clientes/pdf',
      nombreArchivo: 'Reporte_Clientes',
    );
  }

  /// Descarga el reporte de ventas
  static Future<void> descargarReporteVentas(BuildContext context) async {
    await _descargarReporte(
      context: context,
      endpoint: 'ventas/pdf',
      nombreArchivo: 'Reporte_Ventas',
    );
  }

  /// Descarga el reporte de inventario
  static Future<void> descargarReporteInventario(BuildContext context) async {
    await _descargarReporte(
      context: context,
      endpoint: 'inventario/pdf',
      nombreArchivo: 'Reporte_Inventario',
    );
  }

  /// Descarga el reporte de producción
  static Future<void> descargarReporteProduccion(BuildContext context) async {
    await _descargarReporte(
      context: context,
      endpoint: 'produccion/pdf',
      nombreArchivo: 'Reporte_Produccion',
    );
  }

  /// Descarga el reporte de empleados
  static Future<void> descargarReporteEmpleados(BuildContext context) async {
    await _descargarReporte(
      context: context,
      endpoint: 'empleados/pdf',
      nombreArchivo: 'Reporte_Empleados',
    );
  }

  /// Descarga el reporte de movimientos
  static Future<void> descargarReporteMovimientos(BuildContext context) async {
    await _descargarReporte(
      context: context,
      endpoint: 'movimientos/pdf',
      nombreArchivo: 'Reporte_Movimientos',
    );
  }

  /// Descarga el reporte de carritos abandonados
  static Future<void> descargarReporteCarritosAbandonados(BuildContext context) async {
    await _descargarReporte(
      context: context,
      endpoint: 'carritos-abandonados/pdf',
      nombreArchivo: 'Reporte_Carritos_Abandonados',
    );
  }

  /// Descarga el reporte de mis tareas
  static Future<void> descargarReporteMisTareas(BuildContext context) async {
    await _descargarReporte(
      context: context,
      endpoint: 'mis-tareas/pdf',
      nombreArchivo: 'Reporte_Mis_Tareas',
    );
  }

  // ============= MÉTODOS PRIVADOS =============

  /// Descarga el PDF en dispositivo móvil
  static Future<void> _descargarEnMovil(List<int> bytes, String nombreArchivo) async {
    // Solicitar permisos de almacenamiento
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      throw Exception('Se requieren permisos de almacenamiento');
    }

    // Guardar el PDF
    final directory = await _getDownloadDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${directory.path}/${nombreArchivo}_$timestamp.pdf';
    
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    print('✅ PDF guardado en: $filePath'); // Debug

    // Abrir el PDF automáticamente
    await OpenFile.open(filePath);
  }

  /// Solicita permisos de almacenamiento según la plataforma
  static Future<bool> _requestStoragePermission() async {
    // Solo para móviles, no para web
    if (kIsWeb) return true;

    if (Platform.isAndroid) {
      // Android 13+ (API 33+) no necesita WRITE_EXTERNAL_STORAGE
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      var status = await Permission.storage.status;
      if (status.isGranted) return true;

      status = await Permission.storage.request();
      if (status.isGranted) return true;

      // Fallback para fotos
      final photosStatus = await Permission.photos.request();
      return photosStatus.isGranted;
    } else if (Platform.isIOS) {
      var status = await Permission.photos.status;
      if (status.isGranted) return true;

      status = await Permission.photos.request();
      return status.isGranted;
    }
    
    return true;
  }

  /// Obtiene el directorio de descargas según la plataforma
  static Future<Directory> _getDownloadDirectory() async {
    // Solo para móviles
    if (Platform.isAndroid) {
      Directory? directory = await getExternalStorageDirectory();
      
      if (directory != null) {
        final List<String> paths = directory.path.split("/");
        final StringBuffer newPath = StringBuffer();
        
        for (int i = 1; i < paths.length; i++) {
          final String folder = paths[i];
          if (folder != "Android") {
            newPath.write("/$folder");
          } else {
            break;
          }
        }
        newPath.write("/Download");
        
        final Directory downloadDir = Directory(newPath.toString());
        
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        return downloadDir;
      }
      
      return await getTemporaryDirectory();
    } else if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    } else {
      return await getApplicationDocumentsDirectory();
    }
  }

  /// Muestra mensaje de error
  static void _mostrarError(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Muestra mensaje de éxito
  static void _mostrarExito(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}