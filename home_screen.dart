import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'auth_provider.dart';
import 'task_model.dart';
import 'api_service.dart';
import 'login_screen.dart';

/// Pantalla principal de la aplicación con navegación entre tareas y clima
/// Incluye drawer lateral, barra de navegación inferior y funcionalidades CRUD
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Índice de la pantalla seleccionada (0: Tareas, 1: Clima)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false; // Controla si se está buscando
  
  // Pantallas disponibles en la navegación inferior
  final List<Widget> _screens = [
    const TaskListScreen(),
    const WeatherScreen(),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        // Muestra campo de búsqueda o título según el estado
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar tareas...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.black87),
                onChanged: (value) {
                  // Actualiza búsqueda en tiempo real
                  Provider.of<TaskProvider>(context, listen: false)
                      .searchTasks(value);
                },
              )
            : const Text('Segunda Vuelta'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState!.openDrawer(),
        ),
        actions: [
          // Botón de búsqueda (solo visible cuando no se está buscando)
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() => _isSearching = true);
              },
            ),
          // Botón para cancelar búsqueda
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  Provider.of<TaskProvider>(context, listen: false)
                      .searchTasks('');
                });
              },
            ),
          // Botón de notificaciones
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No hay notificaciones nuevas'),
                ),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(), // Drawer lateral personalizado
      body: _screens[_selectedIndex], // Muestra la pantalla seleccionada
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.task),
            label: 'Tareas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud),
            label: 'Clima',
          ),
        ],
      ),
      // FAB solo visible en la pantalla de tareas
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showAddTaskDialog(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
  
  /// Construye el drawer lateral con opciones de navegación y perfil
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header del drawer con información del usuario
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade700, Colors.blue.shade400],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.account_circle,
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                // Muestra nombre de usuario desde AuthProvider
                Consumer<AuthProvider>(
                  builder: (context, auth, _) => Text(
                    auth.username ?? 'Usuario',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Muestra email del usuario desde AuthProvider
                Consumer<AuthProvider>(
                  builder: (context, auth, _) => Text(
                    auth.email ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Opciones del menú
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              setState(() => _selectedIndex = 0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud),
            title: const Text('Clima'),
            onTap: () {
              setState(() => _selectedIndex = 1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.filter_list),
            title: const Text('Filtrar Tareas'),
            onTap: () => _showFilterDialog(),
          ),
          const Divider(),
          // Opciones adicionales
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Acerca de'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Segunda Vuelta',
                applicationVersion: '1.0.0',
                applicationLegalese: 'Aplicación de gestión de tareas\n© 2024',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar Sesión'),
            onTap: () {
              // Obtener ambos providers ANTES de cualquier operación async
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final taskProvider = Provider.of<TaskProvider>(context, listen: false);
              
              // Cerrar el drawer inmediatamente
              Navigator.pop(context);
              
              // Programar el logout para después de cerrar el drawer
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // Limpiar las tareas de la sesión actual
                taskProvider.clearTasks();
                
                // Realizar logout
                authProvider.logout().then((_) {
                  // Navegar después de logout
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  });
                });
              });
            },
          ),
        ],
      ),
    );
  }
  
  /// Muestra diálogo para crear o editar una tarea
  void _showAddTaskDialog({Task? task}) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: task?.titulo ?? '');
    final descController = TextEditingController(text: task?.descripcion ?? '');
    String priority = task?.prioridad ?? 'media';
    String status = task?.estado ?? 'pendiente';
    String categoria = task?.categoria ?? 'general';
    DateTime? fechaLimite = task?.fechaLimite;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(task == null ? 'Nueva Tarea' : 'Editar Tarea'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Campo para título (requerido)
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Título*',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El título es requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Campo para descripción (opcional)
                      TextFormField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      // Selector de prioridad
                      DropdownButtonFormField<String>(
                        initialValue: priority,
                        decoration: const InputDecoration(
                          labelText: 'Prioridad',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'alta',
                            child: Row(
                              children: [
                                Icon(Icons.arrow_upward, color: Colors.red, size: 16),
                                SizedBox(width: 8),
                                Text('Alta'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'media',
                            child: Row(
                              children: [
                                Icon(Icons.remove, color: Colors.orange, size: 16),
                                SizedBox(width: 8),
                                Text('Media'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'baja',
                            child: Row(
                              children: [
                                Icon(Icons.arrow_downward, color: Colors.green, size: 16),
                                SizedBox(width: 8),
                                Text('Baja'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => priority = value!);
                        },
                      ),
                      const SizedBox(height: 16),
                      // Selector de estado
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: const InputDecoration(
                          labelText: 'Estado',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'pendiente',
                            child: Text('Pendiente'),
                          ),
                          DropdownMenuItem(
                            value: 'en progreso',
                            child: Text('En Progreso'),
                          ),
                          DropdownMenuItem(
                            value: 'hecha',
                            child: Text('Completada'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => status = value!);
                        },
                      ),
                      const SizedBox(height: 16),
                      // Selector de fecha límite
                      ListTile(
                        title: const Text('Fecha Límite'),
                        subtitle: Text(
                          fechaLimite == null
                              ? 'No establecida'
                              : DateFormat('dd/MM/yyyy').format(fechaLimite!),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Botón para limpiar fecha
                            if (fechaLimite != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setState(() => fechaLimite = null);
                                },
                              ),
                            // Botón para seleccionar fecha
                            IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null) {
                                  setState(() => fechaLimite = date);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Campo para categoría (opcional)
                      TextFormField(
                        initialValue: categoria,
                        decoration: const InputDecoration(
                          labelText: 'Categoría (opcional)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          categoria = value;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                // Botón para cancelar
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                // Botón para guardar
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      // Crear objeto Task con los datos del formulario
                      final newTask = Task(
                        id: task?.id ?? 0,
                        titulo: titleController.text,
                        descripcion: descController.text,
                        prioridad: priority,
                        estado: status,
                        fechaCreacion: task?.fechaCreacion ?? DateTime.now(),
                        fechaLimite: fechaLimite,
                        categoria: categoria,
                        completada: status == 'hecha',
                        fechaCompletada: status == 'hecha' ? DateTime.now() : null,
                      );
                      
                      if (context.mounted) {
                        try {
                          // Crear nueva tarea o actualizar existente
                          if (task == null) {
                            await Provider.of<TaskProvider>(context, listen: false)
                                .addTask(newTask);
                          } else {
                            await Provider.of<TaskProvider>(context, listen: false)
                                .updateTask(newTask);
                          }
                          
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  task == null 
                                      ? 'Tarea creada exitosamente'
                                      : 'Tarea actualizada exitosamente',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          // Manejar errores
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  /// Muestra diálogo para filtrar tareas por estado y prioridad
  void _showFilterDialog() {
    String? selectedStatus;
    String? selectedPriority;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filtrar Tareas'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Filtro por estado
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('Todos los estados'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'pendiente',
                        child: Text('Pendiente'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'en progreso',
                        child: Text('En Progreso'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'hecha',
                        child: Text('Completada'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => selectedStatus = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Filtro por prioridad
                  DropdownButtonFormField<String>(
                    initialValue: selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Prioridad',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('Todas las prioridades'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'alta',
                        child: Text('Alta'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'media',
                        child: Text('Media'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'baja',
                        child: Text('Baja'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => selectedPriority = value);
                    },
                  ),
                ],
              ),
              actions: [
                // Botón para limpiar filtros
                TextButton(
                  onPressed: () {
                    Provider.of<TaskProvider>(context, listen: false).clearFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('Limpiar'),
                ),
                // Botón para cancelar
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                // Botón para aplicar filtros
                ElevatedButton(
                  onPressed: () {
                    Provider.of<TaskProvider>(context, listen: false).filterTasks(
                      status: selectedStatus,
                      priority: selectedPriority,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Pantalla que muestra la lista de tareas con estadísticas
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});
  
  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar tareas cuando se inicializa el TaskListScreen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      taskProvider.loadTasks();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    
    return RefreshIndicator(
      onRefresh: () => taskProvider.loadTasks(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta con estadísticas de tareas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      'Total',
                      taskProvider.totalTasks.toString(),
                      Colors.blue,
                      Icons.list,
                    ),
                    _buildStatCard(
                      'Pendientes',
                      taskProvider.pendingCount.toString(),
                      Colors.orange,
                      Icons.pending,
                    ),
                    _buildStatCard(
                      'Completadas',
                      taskProvider.completedCount.toString(),
                      Colors.green,
                      Icons.check_circle,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Header de la lista de tareas
            Row(
              children: [
                const Text(
                  'Mis Tareas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Botón para abrir filtros
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    (context.findAncestorStateOfType<_HomeScreenState>()
                        ?._showFilterDialog());
                  },
                  tooltip: 'Filtrar tareas',
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Lista de tareas o estado vacío/carga
            Expanded(
              child: taskProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : taskProvider.tasks.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.task, size: 80, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No hay tareas',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Toca el botón + para crear una',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: taskProvider.tasks.length,
                          itemBuilder: (context, index) {
                            final task = taskProvider.tasks[index];
                            return _buildTaskCard(context, task);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Construye una tarjeta de estadística
  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
  
  /// Construye una tarjeta para mostrar una tarea
  Widget _buildTaskCard(BuildContext context, Task task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        // Ícono de prioridad
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: task.priorityColor.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(
            task.priorityIcon,
            color: task.priorityColor,
          ),
        ),
        // Título de la tarea (tachado si está completada)
        title: Text(
          task.titulo,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: task.estado == 'hecha' 
                ? TextDecoration.lineThrough 
                : null,
          ),
        ),
        // Información adicional de la tarea
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // Descripción (o texto por defecto)
            Text(
              task.descripcion.isNotEmpty 
                  ? task.descripcion 
                  : 'Sin descripción',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            // Chips para estado, fecha límite y categoría
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Chip de estado
                Chip(
                  label: Text(task.statusText),
                  backgroundColor: task.statusColor.withAlpha(25),
                  labelStyle: TextStyle(color: task.statusColor),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                // Chip de fecha límite (si existe)
                if (task.fechaLimite != null)
                  Chip(
                    label: Text(task.formattedFechaLimite),
                    backgroundColor: task.isOverdue
                        ? Colors.red.withAlpha(25)
                        : Colors.grey.withAlpha(25),
                    labelStyle: TextStyle(
                      color: task.isOverdue ? Colors.red : Colors.grey,
                    ),
                  ),
                // Chip de categoría (si no es "general")
                if (task.categoria.isNotEmpty && task.categoria != 'general')
                  Chip(
                    label: Text(task.categoria),
                    backgroundColor: Colors.blue.withAlpha(25),
                    labelStyle: const TextStyle(color: Colors.blue),
                  ),
              ],
            ),
          ],
        ),
        // Menú de opciones (editar/eliminar)
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            if (value == 'edit') {
              // Abrir diálogo de edición
              final homeState = context.findAncestorStateOfType<_HomeScreenState>();
              if (homeState != null) {
                homeState._showAddTaskDialog(task: task);
              }
            } else if (value == 'delete') {
              // Confirmar eliminación
              final confirmed = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Eliminar Tarea'),
                  content: const Text('¿Estás seguro de eliminar esta tarea?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Eliminar'),
                    ),
                  ],
                ),
              );
              
              // Eliminar tarea si se confirmó
              if (confirmed == true && context.mounted) {
                try {
                  await Provider.of<TaskProvider>(context, listen: false)
                      .deleteTask(task.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tarea eliminada'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            }
          },
        ),
        // Al tocar la tarjeta, abrir diálogo de edición
        onTap: () {
          final homeState = context.findAncestorStateOfType<_HomeScreenState>();
          if (homeState != null) {
            homeState._showAddTaskDialog(task: task);
          }
        },
      ),
    );
  }
}

/// Pantalla que muestra información meteorológica usando API externa
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});
  
  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Weather? _weather; // Datos del clima actual
  bool _isLoading = false; // Estado de carga
  String _error = ''; // Mensaje de error
  final List<String> _cities = ['Lima', 'Buenos Aires', 'Madrid', 'Ciudad de México'];
  String _selectedCity = 'Lima'; // Ciudad seleccionada
  
  @override
  void initState() {
    super.initState();
    _fetchWeather(); // Obtener clima al iniciar
  }
  
  /// Obtiene información del clima desde la API
  Future<void> _fetchWeather() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    
    try {
      final weather = await ApiService.getWeather(_selectedCity);
      if (mounted) {
        setState(() => _weather = weather);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'No se pudo obtener el clima. $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de la sección
            const Text(
              'Clima Actual',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Descripción de la funcionalidad
            const Text(
              'Información del clima usando OpenWeather API',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            // Tarjeta principal con información del clima
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Selector de ciudad
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ciudad:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        DropdownButton<String>(
                          value: _selectedCity,
                          items: _cities.map((city) {
                            return DropdownMenuItem<String>(
                              value: city,
                              child: Text(city),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedCity = value!);
                            _fetchWeather();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Estados: carga, error o datos del clima
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline, size: 60, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              _error,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchWeather,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    else if (_weather != null)
                      Column(
                        children: [
                          // Información principal del clima
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _weather!.weatherIcon,
                                style: const TextStyle(fontSize: 60),
                              ),
                              const SizedBox(width: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _weather!.city,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _weather!.description,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Métricas del clima (temperatura, humedad, viento)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildWeatherInfo(
                                'Temperatura',
                                '${_weather!.temperature.toStringAsFixed(1)}°C',
                                Icons.thermostat,
                                Colors.red,
                              ),
                              _buildWeatherInfo(
                                'Humedad',
                                '${_weather!.humidity.toStringAsFixed(0)}%',
                                Icons.water_drop,
                                Colors.blue,
                              ),
                              _buildWeatherInfo(
                                'Viento',
                                '${_weather!.windSpeed.toStringAsFixed(1)} m/s',
                                Icons.air,
                                Colors.green,
                              ),
                            ],
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    // Botón para actualizar datos
                    ElevatedButton.icon(
                      onPressed: _fetchWeather,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualizar'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Información sobre la API externa
            const Text(
              'API Externa Integrada',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.cloud, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'OpenWeather API',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                     ],   
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Esta aplicación consume datos en tiempo real de OpenWeather, '
                      'una API pública que proporciona información meteorológica '
                      'actualizada de ciudades alrededor del mundo.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    // Chips descriptivos de la API
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: const Text('API REST'),
                          backgroundColor: Colors.blue.shade50,
                        ),
                        Chip(
                          label: const Text('Tiempo Real'),
                          backgroundColor: Colors.green.shade50,
                        ),
                        Chip(
                          label: const Text('Global'),
                          backgroundColor: Colors.orange.shade50,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  /// Construye un widget para mostrar una métrica del clima
  Widget _buildWeatherInfo(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}