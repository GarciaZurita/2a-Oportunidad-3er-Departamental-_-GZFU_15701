import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Provider de autenticación que maneja el estado de sesión del usuario
/// Utiliza ChangeNotifier para actualizar la UI cuando cambia el estado
class AuthProvider extends ChangeNotifier {
  // Propiedades privadas del estado de autenticación
  String? _token;        // Token JWT de autenticación
  String? _username;     // Nombre de usuario
  String? _email;        // Email del usuario
  bool _isLoading = false; // Estado de carga
  String? _error;        // Mensaje de error (si existe)
  
  // Getters públicos para acceder al estado
  String? get token => _token;
  String? get username => _username;
  String? get email => _email;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Constructor - Carga las credenciales guardadas al iniciar
  AuthProvider() {
    _loadToken();
  }
  
  /// Carga el token y datos del usuario desde SharedPreferences
  /// Se ejecuta al iniciar la aplicación para restaurar sesión
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _username = prefs.getString('username');
    _email = prefs.getString('email');
    notifyListeners(); // Notifica a los listeners que el estado cambió
  }
  
  /// Inicia sesión con email y contraseña
  /// Devuelve true si el login es exitoso, false en caso contrario
  Future<bool> login(String email, String password) async {
    _isLoading = true;    // Activa indicador de carga
    _error = null;        // Limpia errores anteriores
    notifyListeners();    // Notifica cambio de estado
    
    try {
      // Llama al servicio API para autenticación
      final response = await ApiService.login(email, password);
      
      if (response['success'] == true) {
        // Guarda datos de la respuesta
        _token = response['token'];
        _username = response['user']['username'];
        _email = response['user']['email'];
        
        // Persiste datos en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('username', _username!);
        await prefs.setString('email', _email!);
        
        _isLoading = false; // Desactiva indicador de carga
        notifyListeners();  // Notifica cambio de estado exitoso
        return true;        // Login exitoso
      } else {
        // Maneja error del servidor
        _error = response['error'] ?? 'Error de autenticación';
      }
    } catch (e) {
      // Maneja errores de conexión
      _error = 'Error de conexión: $e';
    }
    
    // Si llegamos aquí, el login falló
    _isLoading = false; // Desactiva indicador de carga
    notifyListeners();  // Notifica cambio de estado (error)
    return false;       // Login fallido
  }
  
  /// Registra un nuevo usuario
  /// Devuelve true si el registro es exitoso, false en caso contrario
  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;    // Activa indicador de carga
    _error = null;        // Limpia errores anteriores
    notifyListeners();    // Notifica cambio de estado
    
    try {
      // Llama al servicio API para registro
      final response = await ApiService.register(username, email, password);
      
      if (response['success'] == true) {
        // Guarda datos de la respuesta
        _token = response['token'];
        _username = response['user']['username'];
        _email = response['user']['email'];
        
        // Persiste datos en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('username', _username!);
        await prefs.setString('email', _email!);
        
        _isLoading = false; // Desactiva indicador de carga
        notifyListeners();  // Notifica cambio de estado exitoso
        return true;        // Registro exitoso
      } else {
        // Maneja error del servidor
        _error = response['error'] ?? 'Error en el registro';
      }
    } catch (e) {
      // Maneja errores de conexión
      _error = 'Error de conexión: $e';
    }
    
    // Si llegamos aquí, el registro falló
    _isLoading = false; // Desactiva indicador de carga
    notifyListeners();  // Notifica cambio de estado (error)
    return false;       // Registro fallido
  }
  
  /// Cierra la sesión del usuario actual
  /// Limpia el estado y elimina datos persistentes
  Future<void> logout() async {
    // Limpia el estado en memoria
    _token = null;
    _username = null;
    _email = null;
    _error = null;
    
    // Elimina datos persistentes de SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('username');
    await prefs.remove('email');
    
    notifyListeners(); // Notifica a la UI que la sesión cerró
  }
  
  /// Limpia el mensaje de error actual
  /// Útil para ocultar errores después de mostrarlos
  void clearError() {
    _error = null;
    notifyListeners(); // Notifica que el error fue limpiado
  }
}