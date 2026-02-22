import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';

// ------------------------------------
// SERVICIO DE CAMBIO DE CONTRASEÑA
// ------------------------------------
class PasswordService {
  static Future<void> cambiarContrasena({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      debugPrint(' [PASSWORD] Iniciando cambio de contraseña...');
      
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      final token = prefs.getString('auth_token');
      
      debugPrint(' [PASSWORD] Datos de SharedPreferences:');
      debugPrint('   - current_user existe: ${userJson != null ? 'SÍ ' : 'NO '}');
      debugPrint('   - Token existe: ${token != null ? 'SÍ ' : 'NO '}');

      if (userJson == null || userJson.isEmpty) {
        throw Exception('No se encontró información del usuario');
      }

      final userData = json.decode(userJson);
      final userId = userData['idPersona']?.toString() ?? userData['id']?.toString();
      
      debugPrint('   - User ID extraído: $userId');

      if (userId == null || userId.isEmpty) {
        throw Exception('No se encontró el ID del usuario');
      }

      // Construir URL: /api/persona/{id}/password
      final url = Uri.parse('${AppConfig.byId('persona', userId)}/password');
      debugPrint(' [PASSWORD] Haciendo petición PUT a: $url');

      final body = {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      };
      
      debugPrint(' [PASSWORD] Datos enviados: ${body.keys}');

      final response = await http.put(
        url,
        headers: {
          ...AppConfig.headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      debugPrint(' [PASSWORD] Respuesta del servidor:');
      debugPrint('   - Status Code: ${response.statusCode}');
      debugPrint('   - Body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint(' [PASSWORD] Contraseña actualizada exitosamente');
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['Message'] ?? errorData['message'] ?? 'Error al cambiar la contraseña';
        debugPrint(' [PASSWORD] Error del servidor: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('[PASSWORD] Error: $e');
      rethrow;
    }
  }
}

// ------------------------------------
// WIDGET DEL MODAL
// ------------------------------------
class CambiarContrasenaModal extends StatefulWidget {
  const CambiarContrasenaModal({super.key});

  @override
  State<CambiarContrasenaModal> createState() => _CambiarContrasenaModalState();
}

class _CambiarContrasenaModalState extends State<CambiarContrasenaModal> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  
  String? _serverError; // Error general del servidor
  String? _currentPasswordError; // Error específico de contraseña actual

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateCurrentPassword(String? value) {
    // Primero verificar error del servidor
    if (_currentPasswordError != null) {
      return _currentPasswordError;
    }
    if (value == null || value.trim().isEmpty) {
      return 'La contraseña actual es requerida';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La nueva contraseña es requerida';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    if (_currentPasswordController.text.isNotEmpty && 
        value == _currentPasswordController.text) {
      return 'La nueva contraseña debe ser diferente a la actual';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Confirmar la contraseña es requerido';
    }
    if (value != _newPasswordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  Color _getPasswordStrengthColor() {
    final length = _newPasswordController.text.length;
    if (length >= 8) return Colors.green;
    if (length >= 6) return Colors.orange;
    return Colors.red;
  }

  double _getPasswordStrengthProgress() {
    final length = _newPasswordController.text.length;
    return (length * 12.5).clamp(0.0, 100.0) / 100;
  }

  Future<void> _handleSubmit() async {
    debugPrint('[SUBMIT] Iniciando cambio de contraseña...');
    
    // Limpiar errores previos del servidor
    setState(() {
      _serverError = null;
      _currentPasswordError = null;
    });

    if (!_formKey.currentState!.validate()) {
      debugPrint(' [SUBMIT] Validación fallida');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await PasswordService.cambiarContrasena(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      
      if (mounted) {
        // Limpiar campos
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        
        // Mostrar mensaje de éxito
        _mostrarSnackBar(
          '¡Contraseña actualizada!',
          'Tu contraseña fue cambiada correctamente.',
          isError: false,
        );
        
        // Esperar un momento para que el usuario vea el mensaje
        await Future.delayed(const Duration(milliseconds: 800));
        
        // Cerrar el modal
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
      
      debugPrint('[SUBMIT] Contraseña actualizada exitosamente');
      
    } catch (e) {
      debugPrint(' [SUBMIT] Error: $e');
      
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        
        // Detectar si es error de contraseña incorrecta
        if (errorMessage.toLowerCase().contains('actual') || 
            errorMessage.toLowerCase().contains('incorrecta') ||
            errorMessage.toLowerCase().contains('incorrect') ||
            errorMessage.toLowerCase().contains('current')) {
          // Mostrar error en el campo de contraseña actual
          setState(() {
            _currentPasswordError = errorMessage;
            _formKey.currentState!.validate(); // Forzar revalidación
          });
        } else {
          // Mostrar error general en el modal
          setState(() {
            _serverError = errorMessage;
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('🏁 [SUBMIT] Proceso finalizado');
    }
  }

  void _mostrarSnackBar(String title, String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(message),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool showPassword,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            obscureText: !showPassword,
            enabled: !_isLoading,
            validator: validator,
            onChanged: (value) {
              // Revalidar en tiempo real
              if (controller == _currentPasswordController && _currentPasswordError != null) {
                setState(() {
                  _currentPasswordError = null;
                  _formKey.currentState!.validate();
                });
              }
              // Actualizar la barra de fortaleza si es la nueva contraseña
              if (controller == _newPasswordController) {
                setState(() {});
              }
            },
            decoration: InputDecoration(
              labelText: '$label *',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  showPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: _isLoading ? null : onToggleVisibility,
              ),
            ),
          ),
          if (helperText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12),
              child: Text(
                helperText,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cambiar Contraseña'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Mostrar error general del servidor si existe
                if (_serverError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _serverError!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Contraseña Actual
                _buildPasswordField(
                  label: 'Contraseña Actual',
                  controller: _currentPasswordController,
                  showPassword: _showCurrentPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _showCurrentPassword = !_showCurrentPassword;
                    });
                  },
                  validator: _validateCurrentPassword,
                ),

                // Nueva Contraseña
                _buildPasswordField(
                  label: 'Nueva Contraseña',
                  controller: _newPasswordController,
                  showPassword: _showNewPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _showNewPassword = !_showNewPassword;
                    });
                  },
                  validator: _validateNewPassword,
                  helperText: 'Mínimo 6 caracteres',
                ),

                // Confirmar Nueva Contraseña
                _buildPasswordField(
                  label: 'Confirmar Nueva Contraseña',
                  controller: _confirmPasswordController,
                  showPassword: _showConfirmPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _showConfirmPassword = !_showConfirmPassword;
                    });
                  },
                  validator: _validateConfirmPassword,
                ),

                // Barra de fortaleza de contraseña
                if (_newPasswordController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Fortaleza de contraseña:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _getPasswordStrengthProgress(),
                      minHeight: 6,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getPasswordStrengthColor(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Cambiar Contraseña'),
        ),
      ],
    );
  }
}

// ------------------------------------
// FUNCIÓN PARA MOSTRAR EL MODAL
// ------------------------------------
void mostrarModalCambiarContrasena(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const CambiarContrasenaModal();
    },
  );
}