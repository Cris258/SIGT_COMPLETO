import 'package:flutter/material.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../widgets/header_widget_home.dart';
import '../widgets/footer_widget_home.dart';

const Color _navbarColor = Color.fromARGB(255, 170, 0, 255); 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  late Timer _timer;
  int _currentSlide = 0;
  
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, String>> productos = [
    {'image': 'assets/images/Aguacate 2.jpg'},
    {'image': 'assets/images/Mafalda.jpg'},
    {'image': 'assets/images/Bob Esponja 2.jpg'},
    {'image': 'assets/images/Coco.jpg'},
    {'image': 'assets/images/Aguacate. Parejajpg.jpg'},
    {'image': 'assets/images/Escandalosos Amigos.jpg'},
    {'image': 'assets/images/Barman.jpg'},
    {'image': 'assets/images/Cerdito.jpg'},
    {'image': 'assets/images/Liga de la Justicia.jpg'},
    {'image': 'assets/images/Micke Mouse.jpg'},
    {'image': 'assets/images/Minni Mouse.jpg'},
    {'image': 'assets/images/Scoby Do.jpg'},
  ];

  final List<String> sliderImages = [
    'assets/images/Slider 2.jpg',
    'assets/images/Slider 3.png',
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentSlide = _pageController.page?.round() ?? 0;
      });
    });
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentSlide < sliderImages.length - 1) {
        _currentSlide++;
      } else {
        _currentSlide = 0;
      }
      _pageController.animateToPage(
        _currentSlide,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _showImageModal(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer(); 
  }

  Future<void> _abrirMapa() async {
    const lat = 4.5867;
    const lng = -74.1026;
    
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng'
    );
    
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(
          googleMapsUrl,
          mode: kIsWeb 
              ? LaunchMode.platformDefault
              : LaunchMode.externalApplication,
        );
      } else {
        throw 'No se pudo abrir el mapa';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir Google Maps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: isMobile ? _buildDrawer(context) : null,
      body: Column(
        children: [
          _buildTopHeader(isMobile),
          _buildNavbar(isMobile),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildInicioSection(),
                  const Divider(thickness: 2, height: 40),
                  _buildProductosSection(),
                  const Divider(thickness: 2, height: 40),
                  _buildQuienesSomosSection(),
                  const Divider(thickness: 2, height: 40),
                  _buildFeaturesSection(),
                  const Divider(thickness: 2, height: 40),
                  _buildUbicacionSection(),
                  const SizedBox(height: 40),
                  const FooterWidgetHome(), 
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTopHeader(bool isMobile) {
    if (isMobile) {
      return Container(
        decoration: BoxDecoration(
          color: _navbarColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: const Image(
                      image: AssetImage('assets/images/Logo Vibra Positiva.jpg'),
                      width: 45,
                      height: 45,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Vibra Positiva',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Pijamas',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                onPressed: _openDrawer,
                tooltip: 'Menú',
              ),
            ),
          ],
        ),
      );
    }
    return const HeaderWidgetHome();
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _navbarColor,
              _navbarColor.withOpacity(0.9),
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: const Image(
                            image: AssetImage('assets/images/Logo Vibra Positiva.jpg'),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Vibra Positiva',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Menú Principal',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _buildDrawerAuthItem(
                        'Registrarse',
                        Icons.person_add_rounded,
                        '/registro',
                        context,
                      ),
                      const SizedBox(width: 10),
                      _buildDrawerAuthItem(
                        'Iniciar Sesión',
                        Icons.login_rounded,
                        '/login',
                        context,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildDrawerItem('Inicio', Icons.home_rounded, '/', context),
            _buildDrawerItem('Tienda', Icons.shopping_bag_rounded, '/home', context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDrawerItem(
    String text,
    IconData icon,
    String route,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        title: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.white70,
          size: 16,
        ),
        onTap: () {
          Navigator.pop(context);
          if (route != '/') {
            Navigator.pushNamed(context, route);
          }
        },
      ),
    );
  }

  Widget _buildDrawerAuthItem(
    String text,
    IconData icon,
    String route,
    BuildContext context,
  ) {
    return Expanded(
      child: TextButton.icon(
        onPressed: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, route);
        },
        icon: Icon(icon, color: Colors.black, size: 18),
        label: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        style: TextButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildNavbar(bool isMobile) {
    if (isMobile) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _navbarColor,
              _navbarColor.withOpacity(0.85),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem('Inicio', '/'),
            Container(
              height: 30,
              width: 1.5,
              color: Colors.white.withOpacity(0.3),
            ),
            _buildNavItem('Tienda', '/home'),
          ],
        ),
      );
    }
    
    return Container(
      color: _navbarColor,
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Center(
        child: Wrap(
          spacing: 30,
          alignment: WrapAlignment.center,
          children: [
            _buildNavItem('Inicio', '/'),
            _buildNavItem('Tienda', '/home'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(String text, String route) {
    return InkWell(
      onTap: () {
        if (route != '/' && route != '/home') {
          Navigator.pushNamed(context, route);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                color: Colors.black26,
                offset: Offset(1, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInicioSection() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 768;
          
          if (isMobile) {
            return Column(
              children: [
                _buildInicioText(),
                const SizedBox(height: 30),
                _buildSlider(),
              ],
            );
          }
          
          return Row(
            children: [
              Expanded(child: _buildInicioText()),
              const SizedBox(width: 40),
              Expanded(child: _buildSlider()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInicioText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Descansar bien también es parte del éxito',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            height: 1.3,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 25),
        const Text(
          'Comienza tu día con energía positiva y alcanza cada meta que te propongas. La comodidad empieza contigo.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Colors.black54,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 18,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          child: const Text(
            'Ver productos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider() {
    return Column(
      children: [
        Container(
          height: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
          ),
          child: PageView.builder(
            controller: _pageController,
            itemCount: sliderImages.length,
            onPageChanged: (index) {
              setState(() {
                _currentSlide = index;
              });
            },
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    sliderImages[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image, size: 50),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: sliderImages.asMap().entries.map((entry) {
            return GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  entry.key,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentSlide == entry.key
                      ? const Color(0xFF9B7EBD) 
                      : Colors.grey[400],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProductosSection() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Text(
            'Nuestros Productos',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 30),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 768 ? 4 : 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.65, 
            ),
            itemCount: productos.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showImageModal(productos[index]['image']!),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      productos[index]['image']!,
                      fit: BoxFit.cover, 
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.image, size: 40),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuienesSomosSection() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Text(
            'Quiénes Somos',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 30),
          LayoutBuilder(
            builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 768;
              
              if (isMobile) {
                return Column(
                  children: [
                    _buildQuienesSomosText(),
                    const SizedBox(height: 30),
                    _buildQuienesSomosLogo(),
                  ],
                );
              }
              
              return Row(
                children: [
                  Expanded(child: _buildQuienesSomosText()),
                  const SizedBox(width: 40),
                  Expanded(child: _buildQuienesSomosLogo()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuienesSomosText() {
    return const Text(
      'Vibra Positiva nació en 2020 como una iniciativa familiar que combinó creatividad, pasión por el diseño y visión emprendedora. Empezamos elaborando productos de bioseguridad, y fue una tela con estampado de aguacates la que nos inspiró a ir más allá. A partir de ese momento, descubrimos en las pijamas una forma de expresar bienestar, color y personalidad. Creamos nuestros primeros diseños digitales con dedicación y comenzamos a compartirlos en redes sociales, donde muchas personas conectaron con nuestra propuesta. Hoy, seguimos creciendo con el mismo propósito: ofrecer comodidad, estilo y buena energía en cada prenda, acompañando los momentos de descanso con auténtica vibra positiva.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 18,
        color: Colors.black87,
        height: 1.6,
      ),
    );
  }

  Widget _buildQuienesSomosLogo() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          'assets/images/Logo Vibra Positiva.jpg',
          width: 300,
          height: 300,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 300,
              height: 300,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.image, size: 60),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(40),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 768;
          
          if (isMobile) {
            return Column(
              children: [
                _buildFeatureCard(
                  'assets/images/pijamas.jpg',
                  'Diseño',
                  'Imaginamos juntos qué es lo que más te gustaría, todo nuestro equipo de diseño está presto siempre a escucharte y a pensar lo impensable para ti. Si algún día tienes una idea de Pijama o babucha y la quieres compartir, estamos aquí en cualquier canal para desarrollarla.',
                ),
                const SizedBox(height: 30),
                _buildFeatureCard(
                  'assets/images/corazon morado.png',
                  'Comodidad',
                  'Investigamos los materiales más cómodos y con la mejor sensación al tacto con la piel, de esta manera cuando tocas tu lugar de descanso vas a experimentar una sensación indescriptible.',
                ),
                const SizedBox(height: 30),
                _buildFeatureCard(
                  'assets/images/Maquina de Coser.jpg',
                  'Calidad',
                  'Fabricamos tus hermosas pijamas, todo un equipo de madres cabeza de hogar expertas en el proceso textil. Nosotros mismos hacemos todo el proceso desde el corte, hasta la confección y empaque, comprometidos en darte un diseño único de excelente calidad.',
                ),
              ],
            );
          }
          
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildFeatureCard(
                  'assets/images/pijamas.jpg',
                  'Diseño',
                  'Imaginamos juntos qué es lo que más te gustaría, todo nuestro equipo de diseño de está presto siempre a escucharte y a pensar lo impensable para ti. Si algún día tienes una idea de Pijama o babucha y la quieres compartir, estamos aquí en cualquier canal para desarrollarla.',
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildFeatureCard(
                  'assets/images/corazon morado.png',
                  'Comodidad',
                  'Investigamos los materiales más cómodos y con la mejor sensación al tacto con la piel, de esta manera cuando tocas tu lugar de descanso vas a experimentar una sensación indescriptible.',
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildFeatureCard(
                  'assets/images/Maquina de Coser.jpg',
                  'Calidad',
                  'Fabricamos tus hermosas pijamas, todo un equipo de madres cabeza de hogar expertas en el proceso textil. Nosotros mismos hacemos todo el proceso desde el corte, hasta la confección y empaque, comprometidos en darte un diseño único de excelente calidad.',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeatureCard(String imagePath, String title, String description) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Image.asset(
              imagePath,
              width: 120,
              height: 120,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.image, size: 40),
                  ),
                );
              },
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUbicacionSection() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Text(
            'Dónde Estamos',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 30),
          
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                  child: Container(
                    height: 250,
                    width: double.infinity,
                    color: const Color(0xFF9B7EBD).withOpacity(0.1),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 80,
                          color: Color(0xFF9B7EBD),
                        ),
                        Positioned(
                          bottom: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Text(
                              'Antonio Nariño, Bogotá',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.store,
                        size: 40,
                        color: Color(0xFF9B7EBD),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Vibra Positiva Pijamas',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Cl. 2 Sur #10-39\nAntonio Nariño, Bogotá D.C.\nColombia',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _abrirMapa,
                          icon: const Icon(Icons.map, size: 24),
                          label: Text(
                            kIsWeb 
                                ? 'Ver en Google Maps'
                                : 'Abrir en Google Maps',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9B7EBD),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 3,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 15),
                      
                      Text(
                        kIsWeb
                            ? 'Se abrirá Google Maps en una nueva pestaña'
                            : 'Se abrirá en la app de Google Maps',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}