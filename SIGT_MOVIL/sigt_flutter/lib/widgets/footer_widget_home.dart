// lib/widgets/footer_widget_home.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 

// Color utilizado en el Header y Navbar: 0xFFE6C7F6 (Malva Claro)
const Color _footerBgColor = Color(0xFFE6C7F6); 

class FooterWidgetHome extends StatelessWidget {
  const FooterWidgetHome({super.key});

  // Función para manejar la apertura de enlaces externos
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Manejo de error si no se puede abrir el enlace (opcional)
      print('No se pudo abrir el enlace: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      color: _footerBgColor, // Color morado de fondo
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 30 : 50, 
        horizontal: isMobile ? 20 : 60,
      ),
      child: Column(
        children: [
          // Sección principal: Contacto, Enlaces y Redes Sociales
          Wrap(
            spacing: 50, // Espacio horizontal entre columnas
            runSpacing: 40, // Espacio vertical entre secciones en móvil
            alignment: isMobile ? WrapAlignment.center : WrapAlignment.spaceBetween,
            children: [
              // 1. Contacto
              _buildContactSection(isMobile),
              
              // 2. Enlaces Rápidos
         
              
              // 3. Redes Sociales
              _buildSocialSection(isMobile),
            ],
          ),

          // Derechos Reservados
          Divider(height: isMobile ? 40 : 60, color: Colors.black38),
          const Text(
            '© 2025 Tienda de Pijamas Vibra Positiva - Todos los derechos reservados',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS DE CONSTRUCCIÓN ESPECÍFICOS ---

  Widget _buildFooterTitle(String title, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900, // fw-bold
          color: Colors.black,
        ),
        textAlign: isMobile ? TextAlign.center : TextAlign.left,
      ),
    );
  }

  // 1. Contacto (Columna 1)
  Widget _buildContactSection(bool isMobile) {
    return SizedBox(
      width: isMobile ? double.infinity : 250,
      child: Column(
        crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          _buildFooterTitle('Contacto', isMobile),
          
          // Dirección
          _buildContactItem(
            icon: Icons.location_on, 
            label: 'Dirección:', 
            value: 'Calle 2 Sur #10 - 39, Bogotá, Colombia',
            isMobile: isMobile,
          ),
          
          // Teléfono
          _buildContactItem(
            icon: Icons.phone, 
            label: 'Teléfono:', 
            value: '+57 305 930 9024',
            isMobile: isMobile,
            onTap: () => _launchUrl('tel:+573059309024'),
          ),
          
          // Email
          _buildContactItem(
            icon: Icons.email, 
            label: 'Email:', 
            value: 'vibrapositiva1720@gmail.com',
            isMobile: isMobile,
            onTap: () => _launchUrl('mailto:vibrapositiva1720@gmail.com'),
          ),
        ],
      ),
    );
  }

  // Elemento individual de contacto (con o sin acción de tap)
  Widget _buildContactItem({
    required IconData icon, 
    required String label, 
    required String value, 
    required bool isMobile,
    VoidCallback? onTap,
  }) {
    final Widget content = RichText(
      textAlign: isMobile ? TextAlign.center : TextAlign.left,
      text: TextSpan(
        style: const TextStyle(fontSize: 14, color: Colors.black),
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: ' $value'),
        ],
      ),
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
          mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: Colors.black),
            const SizedBox(width: 5),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

 

  // 3. Redes Sociales (Columna 3)
  Widget _buildSocialSection(bool isMobile) {
    return SizedBox(
      width: isMobile ? double.infinity : 150,
      child: Column(
        crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          _buildFooterTitle('Síguenos', isMobile),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              _buildSocialIcon(
                icon: Icons.chat, 
                url: 'https://wa.me/573059309024?text=Hola%20quiero%20más%20información',
              ),
              const SizedBox(width: 25),
              _buildSocialIcon(
                icon: Icons.facebook, 
                url: 'https://www.facebook.com/share/19rxvzvkqo/',
              ),
              const SizedBox(width: 25),
              _buildSocialIcon(
                icon: Icons.camera_alt, 
                url: 'https://www.instagram.com/vibrapositivapijamas?igsh=Ym9zaTVnMmxrc29i',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Ícono de red social
  Widget _buildSocialIcon({required IconData icon, required String url}) {
    return IconButton(
      icon: Icon(icon, size: 28, color: Colors.black),
      onPressed: () => _launchUrl(url),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 30),
    );
  }
}