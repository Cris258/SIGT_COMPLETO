import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/app_config.dart';
import '../../models/persona.dart';

class ModalEliminar extends StatefulWidget {
  final Persona persona;
  final String tipoUsuario;
  final VoidCallback onConfirmar;

  const ModalEliminar({
    super.key,
    required this.persona,
    required this.tipoUsuario,
    required this.onConfirmar,
  });

  @override
  State<ModalEliminar> createState() => _ModalEliminarState();
}

class _ModalEliminarState extends State<ModalEliminar> {
  bool _isLoading = false;

  Future<void> _handleEliminar() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final url = Uri.parse(AppConfig.endpoint('persona/${widget.persona.idPersona}'));
      debugPrint(' [DELETE] URL: $url');

      final response = await http.delete(
        url,
        headers: {
          ...AppConfig.headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      debugPrint(' [DELETE] Status: ${response.statusCode}');
      debugPrint(' [DELETE] Body: ${response.body}');

      if (response.statusCode == 200) {
        if (mounted) {
          _mostrarMensaje('Usuario eliminado correctamente', isError: false);
          widget.onConfirmar(); // Llamar callback
          Navigator.of(context).pop();
        }
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['Message'] ?? errorData['message'] ?? 'Error al eliminar';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        _mostrarMensaje(errorMessage, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _mostrarMensaje(String mensaje, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono de advertencia
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),

            // Título
            const Text(
              '¿Eliminar usuario?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Mensaje (usando el getter nombreCompleto de tu modelo)
            Text(
              '¿Está seguro que desea eliminar a ${widget.persona.nombreCompleto}?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Esta acción no se puede deshacer.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            // Información del usuario
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Documento', widget.persona.numeroDocumento.toString()),
                  const Divider(height: 16),
                  _buildInfoRow('Correo', widget.persona.correo),
                  const Divider(height: 16),
                  _buildInfoRow('Rol', widget.persona.nombreRol ?? 'Sin rol'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleEliminar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Eliminar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}