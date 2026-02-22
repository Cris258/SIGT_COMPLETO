import 'dart:html' as html;

/// Descarga el PDF en navegador web
void descargarPdfWeb(List<int> bytes, String nombreArchivo) {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  
  // Crear elemento anchor y forzar descarga
  final anchor = html.document.createElement('a') as html.AnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = '${nombreArchivo}_$timestamp.pdf';
  
  // Agregar al DOM, hacer clic y remover
  html.document.body?.children.add(anchor);
  anchor.click();
  
  // Limpiar después de un momento
  Future.delayed(const Duration(milliseconds: 100), () {
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  });
}