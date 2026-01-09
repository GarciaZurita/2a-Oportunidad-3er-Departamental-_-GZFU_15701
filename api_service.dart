import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'task_model.dart';

/// Servicio API centralizado para todas las llamadas HTTP
/// Maneja autenticación, tareas y API externa de clima
class ApiService {
  // URLs configuradas como constantes para evitar hardcode
  static const String _baseUrl = 'http://10.0.2.2:3000'; // Para Android emulador
  //static const String _baseUrl = 'http://localhost:3000'; // Para iOS/Web
  
  // Configuración API externa - OpenWeather
  static const String _weatherApiKey = '9709d18012b6ae695dfaf9770cd7877a';
  static const String _weatherUrl = 'https://api.openweathermap.org/data/2.5/weather';
  
  /// Método genérico para realizar solicitudes HTTP
  /// Maneja headers, autenticación y parsing de respuestas
  static Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    // Obtener token de autenticación desde SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    // Configurar headers HTTP
    final headers = {
      'Content-Type': 'application/json',
    };
    
    // Añadir token de autorización si es necesario
    if (requiresAuth && token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    // Construir URL completa
    final url = Uri.parse('$_baseUrl$endpoint');
    http.Response response;
    
    try {
      // Ejecutar solicitud según método HTTP
      switch (method) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: json.encode(body),
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: headers,
            body: json.encode(body),
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw Exception('Método HTTP no soportado');
      }
      
      // Parsear respuesta JSON
      final responseBody = json.decode(response.body);
      
      // Validar código de estado HTTP
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody;
      } else {
        // Lanzar error con mensaje del servidor o genérico
        throw Exception(responseBody['error'] ?? 'Error en la solicitud');
      }
    } catch (e) {
      // Manejar errores de conexión
      throw Exception('Error de conexión: $e');
    }
  }
  
  // --- MÉTODOS DE AUTENTICACIÓN ---
  
  /// Iniciar sesión con email y contraseña
  static Future<Map<String, dynamic>> login(String email, String password) async {
    return await _makeRequest(
      'POST',
      '/auth/login',
      body: {'email': email, 'password': password},
      requiresAuth: false, // No requiere token para login
    );
  }
  
  /// Registrar nuevo usuario
  static Future<Map<String, dynamic>> register(
    String username, String email, String password) async {
    return await _makeRequest(
      'POST',
      '/auth/register',
      body: {'username': username, 'email': email, 'password': password},
      requiresAuth: false, // No requiere token para registro
    );
  }
  
  // --- MÉTODOS DE GESTIÓN DE TAREAS ---
  
  /// Obtener lista de tareas con filtros opcionales
  static Future<Map<String, dynamic>> getTasks({String? status, String? priority}) async {
    String endpoint = '/tasks';
    
    // Construir query parameters para filtros
    if (status != null || priority != null) {
      final params = [];
      if (status != null) params.add('estado=$status');
      if (priority != null) params.add('prioridad=$priority');
      endpoint += '?${params.join('&')}';
    }
    
    return await _makeRequest('GET', endpoint);
  }
  
  /// Crear nueva tarea
  static Future<Map<String, dynamic>> createTask(Map<String, dynamic> taskData) async {
    return await _makeRequest('POST', '/tasks', body: taskData);
  }
  
  /// Actualizar tarea existente
  static Future<Map<String, dynamic>> updateTask(int taskId, Map<String, dynamic> taskData) async {
    return await _makeRequest('PUT', '/tasks/$taskId', body: taskData);
  }
  
  /// Eliminar tarea por ID
  static Future<Map<String, dynamic>> deleteTask(int taskId) async {
    return await _makeRequest('DELETE', '/tasks/$taskId');
  }
  
  // --- API EXTERNA: SERVICIO DE CLIMA ---
  
  /// Obtener información meteorológica de una ciudad usando OpenWeather API
  static Future<Weather> getWeather(String city) async {
    // Construir URL con parámetros para OpenWeather
    final url = Uri.parse(
      '$_weatherUrl?q=$city&appid=$_weatherApiKey&units=metric&lang=es'
    );
    
    final response = await http.get(url);
    
    // Validar respuesta y parsear a objeto Weather
    if (response.statusCode == 200) {
      return Weather.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al obtener el clima. Código: ${response.statusCode}');
    }
  }
  
  // --- PERFIL DE USUARIO ---
  
  /// Obtener información del perfil del usuario autenticado
  static Future<Map<String, dynamic>> getProfile() async {
    return await _makeRequest('GET', '/auth/profile');
  }
}