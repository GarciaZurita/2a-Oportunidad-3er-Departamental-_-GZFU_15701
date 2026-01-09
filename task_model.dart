import 'package:flutter/material.dart';
import 'api_service.dart';

/// Modelo que representa una tarea en la aplicación
/// Contiene todos los atributos necesarios para gestionar tareas
class Task {
  final int id;
  final String titulo;
  final String descripcion;
  final String prioridad;
  final String estado;
  final DateTime fechaCreacion;
  final DateTime? fechaLimite;
  final String categoria;
  final bool completada;
  final DateTime? fechaCompletada;
  
  Task({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.prioridad,
    required this.estado,
    required this.fechaCreacion,
    this.fechaLimite,
    this.categoria = 'general',
    this.completada = false,
    this.fechaCompletada,
  });
  
  /// Constructor factory para crear un objeto Task desde JSON
  /// Se usa cuando se reciben datos desde la API
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'] ?? '',
      prioridad: json['prioridad'] ?? 'media',
      estado: json['estado'] ?? 'pendiente',
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      fechaLimite: json['fechaLimite'] != null 
          ? DateTime.parse(json['fechaLimite'])
          : null,
      categoria: json['categoria'] ?? 'general',
      completada: json['completada'] == 1,
      fechaCompletada: json['fechaCompletada'] != null
          ? DateTime.parse(json['fechaCompletada'])
          : null,
    );
  }
  
  /// Convierte el objeto Task a formato JSON para enviar a la API
  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'prioridad': prioridad,
      'estado': estado,
      'fechaLimite': fechaLimite?.toIso8601String(),
      'categoria': categoria,
    };
  }
  
  /// Devuelve el color asociado a la prioridad de la tarea
  Color get priorityColor {
    switch (prioridad) {
      case 'alta':
        return Colors.red;
      case 'media':
        return Colors.orange;
      case 'baja':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  /// Devuelve el icono asociado a la prioridad de la tarea
  IconData get priorityIcon {
    switch (prioridad) {
      case 'alta':
        return Icons.arrow_upward;
      case 'media':
        return Icons.remove;
      case 'baja':
        return Icons.arrow_downward;
      default:
        return Icons.circle;
    }
  }
  
  /// Devuelve el color asociado al estado de la tarea
  Color get statusColor {
    switch (estado) {
      case 'hecha':
        return Colors.green;
      case 'en progreso':
        return Colors.blue;
      case 'pendiente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
  
  /// Devuelve el texto legible del estado de la tarea
  String get statusText {
    switch (estado) {
      case 'hecha':
        return 'Completada';
      case 'en progreso':
        return 'En Progreso';
      case 'pendiente':
        return 'Pendiente';
      default:
        return 'Desconocido';
    }
  }
  
  /// Determina si la tarea está vencida (fecha límite pasada y no completada)
  bool get isOverdue {
    if (fechaLimite == null) return false;
    return fechaLimite!.isBefore(DateTime.now()) && estado != 'hecha';
  }
  
  /// Formatea la fecha límite para mostrar en la interfaz
  String get formattedFechaLimite {
    if (fechaLimite == null) return 'Sin fecha límite';
    return '${fechaLimite!.day}/${fechaLimite!.month}/${fechaLimite!.year}';
  }
}

/// Provider que gestiona el estado de las tareas en la aplicación
/// Utiliza ChangeNotifier para actualizar la UI cuando cambian las tareas
class TaskProvider with ChangeNotifier {
  List<Task> _tasks = []; // Lista completa de tareas
  List<Task> _filteredTasks = []; // Lista filtrada para mostrar
  bool _isLoading = false; // Estado de carga
  String? _filterStatus; // Filtro por estado
  String? _filterPriority; // Filtro por prioridad
  String _searchQuery = ''; // Término de búsqueda
  
  List<Task> get tasks => _filteredTasks; // Getter para tareas filtradas
  bool get isLoading => _isLoading; // Getter para estado de carga
  
  TaskProvider() {
    // No cargamos tareas automáticamente al iniciar
    // La carga se hará después del login exitoso
  }
  
  /// Carga las tareas desde la API
  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await ApiService.getTasks();
      if (response['success'] == true) {
        final tasks = (response['tasks'] as List)
            .map((json) => Task.fromJson(json))
            .toList();
        _tasks = tasks;
        _applyFilters();
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  /// Limpia todas las tareas (usado al cerrar sesión)
  void clearTasks() {
    _tasks = [];
    _filteredTasks = [];
    _filterStatus = null;
    _filterPriority = null;
    _searchQuery = '';
    _isLoading = false;
    notifyListeners();
  }
  
  /// Agrega una nueva tarea
  Future<void> addTask(Task task) async {
    try {
      final response = await ApiService.createTask(task.toJson());
      if (response['success'] == true) {
        final newTask = Task.fromJson(response['task']);
        _tasks.insert(0, newTask);
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error adding task: $e');
      rethrow;
    }
  }
  
  /// Actualiza una tarea existente
  Future<void> updateTask(Task task) async {
    try {
      final response = await ApiService.updateTask(task.id, task.toJson());
      if (response['success'] == true) {
        final updatedTask = Task.fromJson(response['task']);
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = updatedTask;
          _applyFilters();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error updating task: $e');
      rethrow;
    }
  }
  
  /// Elimina una tarea por su ID
  Future<void> deleteTask(int taskId) async {
    try {
      final response = await ApiService.deleteTask(taskId);
      if (response['success'] == true) {
        _tasks.removeWhere((task) => task.id == taskId);
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }
  
  /// Filtra las tareas por estado y/o prioridad
  void filterTasks({String? status, String? priority}) {
    _filterStatus = status;
    _filterPriority = priority;
    _applyFilters();
  }
  
  /// Busca tareas por texto en título o descripción
  void searchTasks(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }
  
  /// Limpia todos los filtros aplicados
  void clearFilters() {
    _filterStatus = null;
    _filterPriority = null;
    _searchQuery = '';
    _filteredTasks = _tasks;
    notifyListeners();
  }
  
  /// Aplica los filtros activos a la lista de tareas
  void _applyFilters() {
    List<Task> filtered = _tasks;
    
    // Aplicar filtro por estado
    if (_filterStatus != null && _filterStatus!.isNotEmpty) {
      filtered = filtered.where((task) => task.estado == _filterStatus).toList();
    }
    
    // Aplicar filtro por prioridad
    if (_filterPriority != null && _filterPriority!.isNotEmpty) {
      filtered = filtered.where((task) => task.prioridad == _filterPriority).toList();
    }
    
    // Aplicar búsqueda por texto
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((task) {
        return task.titulo.toLowerCase().contains(_searchQuery) ||
               task.descripcion.toLowerCase().contains(_searchQuery);
      }).toList();
    }
    
    _filteredTasks = filtered;
    notifyListeners();
  }
  
  // Getters para diferentes categorías de tareas
  
  /// Tareas completadas
  List<Task> get completedTasks => _tasks.where((t) => t.estado == 'hecha').toList();
  
  /// Tareas pendientes
  List<Task> get pendingTasks => _tasks.where((t) => t.estado == 'pendiente').toList();
  
  /// Tareas en progreso
  List<Task> get inProgressTasks => _tasks.where((t) => t.estado == 'en progreso').toList();
  
  /// Total de tareas
  int get totalTasks => _tasks.length;
  
  /// Cantidad de tareas completadas
  int get completedCount => completedTasks.length;
  
  /// Cantidad de tareas pendientes
  int get pendingCount => pendingTasks.length;
  
  /// Cantidad de tareas en progreso
  int get inProgressCount => inProgressTasks.length;
  
  /// Tareas de prioridad alta
  List<Task> get highPriorityTasks => _tasks.where((t) => t.prioridad == 'alta').toList();
  
  /// Tareas de prioridad media
  List<Task> get mediumPriorityTasks => _tasks.where((t) => t.prioridad == 'media').toList();
  
  /// Tareas de prioridad baja
  List<Task> get lowPriorityTasks => _tasks.where((t) => t.prioridad == 'baja').toList();
}

/// Modelo para representar datos meteorológicos de la API externa
class Weather {
  final String city;
  final double temperature;
  final String description;
  final String icon;
  final double humidity;
  final double windSpeed;
  
  Weather({
    required this.city,
    required this.temperature,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
  });
  
  /// Constructor factory para crear Weather desde JSON de OpenWeather API
  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      city: json['name'],
      temperature: json['main']['temp'].toDouble(),
      description: json['weather'][0]['description'],
      icon: json['weather'][0]['icon'],
      humidity: json['main']['humidity'].toDouble(),
      windSpeed: json['wind']['speed'].toDouble(),
    );
  }
  
  /// Convierte el código de icono de OpenWeather a emoji para mostrar
  String get weatherIcon {
    switch (icon) {
      case '01d': return '☀️';
      case '01n': return '🌙';
      case '02d': return '⛅';
      case '02n': return '☁️';
      case '03d': case '03n': return '☁️';
      case '04d': case '04n': return '☁️';
      case '09d': case '09n': return '🌧️';
      case '10d': case '10n': return '🌦️';
      case '11d': case '11n': return '⛈️';
      case '13d': case '13n': return '❄️';
      case '50d': case '50n': return '🌫️';
      default: return '🌈';
    }
  }
}