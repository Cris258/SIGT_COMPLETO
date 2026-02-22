import 'package:flutter/material.dart';

class HeaderLine extends StatelessWidget {
  final VoidCallback? onLogout; // Callback para cerrar sesión
  
  const HeaderLine({
    super.key,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Color(0xFFE6C7F6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo + Título
            Expanded(
              child: Row(
                children: [
                  // Logo
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Color(0xFFE6C7F6),
                        width: 1,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/Logo Vibra Positiva.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Color(0xFFE6C7F6),
                            child: const Icon(
                              Icons.image,
                              color: Colors.grey,
                              size: 24,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Título
                  const Flexible(
                    child: Text(
                      'VIBRA POSITIVA PIJAMAS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 0.5,
                        fontFamily: 'Merriweather', // Asegúrate de tener esta fuente configurada
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            // Menú - Botón de Cerrar Sesión
            if (onLogout != null)
              TextButton(
                onPressed: onLogout,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Ejemplo de uso:
// HeaderLine(
//   onLogout: () {
//     // Lógica para cerrar sesión
//     print('Cerrando sesión...');
//     Navigator.pushReplacementNamed(context, '/login');
//   },
// )