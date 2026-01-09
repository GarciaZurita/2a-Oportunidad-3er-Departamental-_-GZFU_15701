import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_provider.dart';
import 'task_model.dart';
import 'home_screen.dart';
import 'login_screen.dart';

// Punto de entrada principal de la aplicación
void main() async {
  // Asegura que Flutter esté inicializado antes de ejecutar la app
  WidgetsFlutterBinding.ensureInitialized();
  // Ejecuta la aplicación
  runApp(const MyApp());
}

// Widget principal de la aplicación que maneja el estado inicial
class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  
  @override
  State<MyApp> createState() => _MyAppState();
}

// Estado del widget MyApp
class _MyAppState extends State<MyApp> {
  String? _initialToken; // Token almacenado al iniciar la app
  bool _isLoading = true; // Indica si está cargando el token
  
  @override
  void initState() {
    super.initState();
    // Verifica si hay un token almacenado al iniciar
    _checkToken();
  }
  
  // Verifica si existe un token en SharedPreferences
  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    setState(() {
      _initialToken = token;
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Muestra un loading mientras verifica el token
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    // Proveedores de estado para toda la aplicación
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: MaterialApp(
        title: 'Segunda Vuelta',
        debugShowCheckedModeBanner: false,
        // Configuración del tema visual
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: const Color(0xFF2196F3),
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.blue,
            accentColor: Colors.blueAccent,
          ),
          scaffoldBackgroundColor: Colors.grey[50],
          appBarTheme: const AppBarTheme(
            elevation: 1,
            backgroundColor: Colors.white,
            iconTheme: IconThemeData(color: Colors.black87),
            titleTextStyle: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF2196F3),
            foregroundColor: Colors.white,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // ← Ahora funciona
            ),
            color: Colors.white,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        // Si hay token, va a HomeScreen, si no, a LoginScreen
        home: _initialToken != null && _initialToken!.isNotEmpty
            ? const HomeScreen()
            : const LoginScreen(),
      ),
    );
  }
}