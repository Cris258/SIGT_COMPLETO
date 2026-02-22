import 'package:flutter/material.dart';

class FooterLine extends StatelessWidget {
  const FooterLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      color: Color(0xFFE6C7F6),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            '© 2025 Tienda de Pijamas Vibra Positiva - Todos los derechos reservados',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'PoiretOne', // Asegúrate de tener esta fuente configurada
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

