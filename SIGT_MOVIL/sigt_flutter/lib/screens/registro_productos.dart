import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../config/app_config.dart';
import '../widgets/header_widget.dart';
import '../widgets/footer_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class RegistroProductos extends StatefulWidget {
  const RegistroProductos({super.key});

  @override
  State<RegistroProductos> createState() => _RegistroProductosState();
}

class _RegistroProductosState extends State<RegistroProductos> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _estampadoController = TextEditingController();
  final _stockController = TextEditingController();
  final _precioController = TextEditingController();

  String? _colorSeleccionado;
  String? _tallaSeleccionada;
  bool _isSubmitting = false;

  File? _imagenSeleccionada;
  Uint8List? _imagenBytes;
  final ImagePicker _picker = ImagePicker();

  final List<String> colores = [
    "Rojo",
    "Azul",
    "Verde",
    "Amarillo",
    "Negro",
    "Blanco",
    "Gris",
    "Rosa",
    "Morado",
    "Naranja",
    "Café",
    "Beige",
    "Celeste",
    "Turquesa",
    "Violeta",
    "Fucsia",
    "Marino",
    "Vino",
    "Crema",
  ];

  final List<String> tallas = [
    "2",
    "4",
    "6",
    "8",
    "10",
    "12",
    "14",
    "16",
    "XS",
    "S",
    "M",
    "L",
    "XL"
  ];

  final Map<String, Color> colorMap = {
    'rojo': const Color(0xFFFF0000),
    'azul': const Color(0xFF0000FF),
    'verde': const Color(0xFF00FF00),
    'amarillo': const Color(0xFFFFFF00),
    'negro': const Color(0xFF000000),
    'blanco': const Color(0xFFFFFFFF),
    'gris': const Color(0xFF808080),
    'rosa': const Color(0xFFFFC0CB),
    'morado': const Color(0xFF800080),
    'naranja': const Color(0xFFFFA500),
    'café': const Color(0xFF8B4513),
    'beige': const Color(0xFFF5F5DC),
    'celeste': const Color(0xFF87CEEB),
    'turquesa': const Color(0xFF40E0D0),
    'violeta': const Color(0xFFEE82EE),
    'fucsia': const Color(0xFFFF00FF),
    'marino': const Color(0xFF000080),
    'vino': const Color(0xFF722F37),
    'crema': const Color(0xFFFFFDD0),
  };

  HeaderWidget headerWidget = HeaderWidget();
  FooterWidget footerWidget = FooterWidget();

  @override
  void dispose() {
    _nombreController.dispose();
    _estampadoController.dispose();
    _stockController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  Color getColorCode(String? colorName) {
    if (colorName == null) return Colors.transparent;
    return colorMap[colorName.toLowerCase().trim()] ?? const Color(0xFFCCCCCC);
  }

  Future<void> _seleccionarImagen(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        
        setState(() {
          _imagenBytes = bytes;
          if (!kIsWeb) {
            _imagenSeleccionada = File(image.path);
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imagen seleccionada correctamente ✓'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error al seleccionar imagen: $e');
      if (mounted) {
        _mostrarError('Error al seleccionar la imagen: $e');
      }
    }
  }

  void _mostrarOpcionesImagen() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Seleccionar imagen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.purple),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.purple),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.camera);
              },
            ),
            if (_imagenSeleccionada != null || _imagenBytes != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar imagen'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _imagenSeleccionada = null;
                    _imagenBytes = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _registrarProducto() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_colorSeleccionado == null) {
      _mostrarError('Por favor selecciona un color');
      return;
    }

    if (_tallaSeleccionada == null) {
      _mostrarError('Por favor selecciona una talla');
      return;
    }

    if (_imagenBytes == null) {
      _mostrarError('Por favor selecciona una imagen del producto');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(AppConfig.endpoint('producto')),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['NombreProducto'] = _nombreController.text.trim();
      request.fields['Color'] = _colorSeleccionado!;
      request.fields['Talla'] = _tallaSeleccionada!;
      request.fields['Estampado'] = _estampadoController.text.trim().isEmpty 
          ? 'Sin estampado' 
          : _estampadoController.text.trim();
      request.fields['Stock'] = _stockController.text.trim();
      request.fields['Precio'] = _precioController.text.trim();

      request.files.add(
        http.MultipartFile.fromBytes(
          'imagen',
          _imagenBytes!,
          filename: 'producto_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
      
      debugPrint('Imagen agregada (${_imagenBytes!.length} bytes)');
      debugPrint('Enviando producto al servidor...');
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint(' Status Code: ${response.statusCode}');
      debugPrint(' Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          _limpiarFormulario();
          _mostrarExito('¡Producto registrado exitosamente! 🎉');
        }
      } else {
        final data = json.decode(response.body);
        final errorMessage = data['Message'] ?? 
                            data['message'] ?? 
                            data['error'] ?? 
                            'No se pudo registrar el producto';
        debugPrint(' Error del servidor: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint(' Error en el registro: $e');
      if (mounted) {
        _mostrarError(
          e.toString().contains('No hay token')
              ? 'Sesión expirada. Por favor inicia sesión nuevamente'
              : e.toString().contains('Exception:')
                  ? e.toString().replaceAll('Exception: ', '')
                  : 'Error de conexión: No se pudo conectar con el servidor ❌'
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _mostrarExito(String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 30),
            SizedBox(width: 10),
            Expanded(child: Text('¡Éxito!')),
          ],
        ),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _mostrarError(String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 30),
            SizedBox(width: 10),
            Expanded(child: Text('Error')),
          ],
        ),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _limpiarFormulario() {
    setState(() {
      _nombreController.clear();
      _estampadoController.clear();
      _stockController.clear();
      _precioController.clear();
      _colorSeleccionado = null;
      _tallaSeleccionada = null;
      _imagenSeleccionada = null;
      _imagenBytes = null;
    });
    
    Future.delayed(const Duration(milliseconds: 100), () {
      _formKey.currentState?.reset();
    });
    
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    const Color fondo = Color(0xFFE6C7F6);
    const Color rosaBoton = Color(0xFFE6C7F6);
    const Color colorTextoBoton = Color(0xFF4A4A4A);

    const InputDecoration fieldDecoration = InputDecoration(
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: Colors.grey, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: Colors.grey, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: Colors.purple, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );

    const TextStyle labelStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 14,
      color: Color(0xFF4A4A4A),
    );

    return Scaffold(
      backgroundColor: fondo,
      body: SingleChildScrollView(
        child: Column(
          children: [
            headerWidget,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "¡Vibra Positiva Pijamas!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4A4A4A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        "Registra un nuevo producto",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),

                      // Imagen del Producto
                      Row(
                        children: [
                          const Text("Imagen del Producto", style: labelStyle),
                          const SizedBox(width: 4),
                          const Text(
                            "*",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _mostrarOpcionesImagen,
                        child: Container(
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _imagenBytes == null 
                                  ? Colors.red.shade300 
                                  : Colors.green.shade300,
                              width: 2,
                            ),
                          ),
                          child: _imagenBytes != null
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        _imagenBytes!,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Imagen lista',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          constraints: const BoxConstraints(),
                                          onPressed: _mostrarOpcionesImagen,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 48,
                                      color: Colors.red.shade300,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Toca para agregar imagen',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    const Text(
                                      '(Requerido)',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nombre Producto
                      const Text("Nombre del Producto", style: labelStyle),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nombreController,
                        decoration: fieldDecoration.copyWith(
                          hintText: "Ej: Pijama Unicornio",
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Campo requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Color con vista previa
                      const Text("Color", style: labelStyle),
                      const SizedBox(height: 6),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Column(
                            children: [
                              DropdownButtonFormField<String>(
                                decoration: fieldDecoration.copyWith(
                                  hintText: "Seleccione un color",
                                ),
                                value: _colorSeleccionado,
                                items: colores
                                    .map((c) =>
                                        DropdownMenuItem(value: c, child: Text(c)))
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _colorSeleccionado = value),
                                validator: (value) {
                                  if (value == null) {
                                    return 'Selecciona un color';
                                  }
                                  return null;
                                },
                              ),
                              if (_colorSeleccionado != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text(
                                      "Vista previa: ",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: getColorCode(_colorSeleccionado),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Talla
                      const Text("Talla", style: labelStyle),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        decoration: fieldDecoration.copyWith(
                          hintText: "Seleccione una talla",
                        ),
                        value: _tallaSeleccionada,
                        items: tallas
                            .map((t) =>
                                DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _tallaSeleccionada = value),
                        validator: (value) {
                          if (value == null) {
                            return 'Selecciona una talla';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Estampado
                      const Text("Estampado (Opcional)", style: labelStyle),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _estampadoController,
                        decoration: fieldDecoration.copyWith(
                          hintText: "Ej: Unicornios, Estrellas",
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Stock
                      const Text("Stock", style: labelStyle),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: fieldDecoration.copyWith(
                          hintText: "Ej: 10, 20, 30",
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Campo requerido';
                          }
                          final stock = int.tryParse(value.trim());
                          if (stock == null || stock < 0) {
                            return 'Ingresa un número válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Precio
                      const Text("Precio (COP)", style: labelStyle),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _precioController,
                        keyboardType: TextInputType.number,
                        decoration: fieldDecoration.copyWith(
                          hintText: "Ej: 50000",
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Campo requerido';
                          }
                          final precio = double.tryParse(value.trim());
                          if (precio == null || precio < 0) {
                            return 'Ingresa un precio válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Botón Registrar
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _registrarProducto,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: rosaBoton,
                          foregroundColor: colorTextoBoton,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          elevation: 0,
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text("REGISTRAR PRODUCTO"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            footerWidget,
          ],
        ),
      ),
    );
  }
}