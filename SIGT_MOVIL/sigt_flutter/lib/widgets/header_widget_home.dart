// lib/widgets/header_widget_home.dart

import 'package:flutter/material.dart';

const Color _navbarColor = Color(0xFFE6C7F6);

class HeaderWidgetHome extends StatelessWidget {
  const HeaderWidgetHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _navbarColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo + Título
          Row(
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/images/Logo Vibra Positiva.jpg',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'VIBRA POSITIVA PIJAMAS',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          // Botones de autenticación
          Row(
            children: [
              _buildAuthButton(
                context: context,
                icon: Icons.person_add,
                text: 'Registrarse',
                route: '/registro', //  Usa ruta
              ),
              const SizedBox(width: 10),
              _buildAuthButton(
                context: context,
                icon: Icons.login,
                text: 'Iniciar Sesión',
                route: '/login', //  Usa ruta
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAuthButton({
    required BuildContext context,
    required IconData icon,
    required String text,
    required String route, //  Cambiado de Widget page a String route
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, route); //  Navega con ruta nombrada
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 5),
            Icon(icon, size: 18),
          ],
        ),
      ),
    );
  }
}