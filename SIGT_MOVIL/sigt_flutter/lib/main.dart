import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_page.dart';
import 'screens/login_page.dart';
import 'screens/forgot_password_page.dart';
import 'screens/reset_password_page.dart';
import 'screens/registro_page.dart';
import 'screens/admin_page.dart';
import 'screens/empleado_page.dart';
import 'screens/admin_clientes_page.dart';
import 'screens/admin_inventario_page.dart';
import 'screens/lista_carritos.dart';
import 'screens/lista_clientes.dart';
import 'screens/lista_empleados.dart';
import 'screens/lista_productos.dart';
import 'screens/lista_tareas.dart';
import 'screens/lista_usuarios.dart';
import 'screens/lista_ventas.dart';
import 'screens/registro_productos.dart';
import 'screens/registro_usuarios.dart';
import 'screens/RegistroTareas_page.dart';
import 'screens/lista_movimientos.dart';
import 'screens/registrar_produccion_page.dart';
import 'screens/historial_produccion_page.dart';
import 'screens/tienda_cliente_page.dart';
import 'screens/carrito_page.dart';
import 'screens/mispedidos_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CO', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vibra Positiva Pijamas',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'CO'), Locale('es', '')],
      locale: const Locale('es', 'CO'),
      theme: ThemeData(
        primarySwatch: Colors.purple,
        primaryColor: const Color(0xFFE6C7F6),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE6C7F6)),
        useMaterial3: true,
      ),

      initialRoute: '/',
      routes: {
        // === RUTAS PÚBLICAS ===
        '/': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/forgot_password': (context) => const ForgotPasswordPage(),
        '/reset_password': (context) => const ResetPasswordPage(),
        '/registro': (context) => const RegistroPage(),
        '/home': (context) => const HomePage(),

        // === RUTAS PRIVADAS ===
        '/administrador': (context) => const AdminPage(),
        '/admin': (context) => const AdminPage(),
        '/empleado': (context) => const EmpleadoPage(),
        '/admin_clientes': (context) => const AdminClientesPage(),
        '/admin_inventario': (context) => const AdminInventarioPage(),
        '/lista_carritos': (context) => const ListaCarritos(),
        '/lista_clientes': (context) => const ListaClientes(),
        '/lista_empleados': (context) => const ListaEmpleados(),
        '/lista_productos': (context) => const ListaProductos(),
        '/lista_tareas': (context) => const ListaTareas(),
        '/lista_usuarios': (context) => const ListaUsuarios(),
        '/lista_ventas': (context) => const ListaVentas(),
        '/registro_productos': (context) => const RegistroProductos(),
        '/registro_usuarios': (context) => const RegistroUsuarios(),
        '/registro_tareas': (context) => const RegistroTareasPage(),
        '/lista_movimientos': (context) => const ListaMovimientos(),
        '/registrar_produccion': (context) => const RegistrarProduccionPage(),
        '/historial_produccion': (context) => const HistorialProduccionPage(),
        '/tienda': (context) => const TiendaClientePage(),
        '/carrito': (context) => const CarritoPage(),
        '/mis_pedidos': (context) => const MisPedidosScreen(),
      },
    );
  }
}
