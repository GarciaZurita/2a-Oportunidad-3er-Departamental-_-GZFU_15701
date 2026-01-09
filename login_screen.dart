import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'home_screen.dart';

/// Pantalla de autenticación que permite login y registro de usuarios
/// Maneja tanto el inicio de sesión como la creación de nuevas cuentas
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); // Clave para validación del formulario
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLogin = true; // Controla si se muestra login (true) o registro (false)
  bool _isLoading = false; // Estado de carga durante autenticación
  bool _obscurePassword = true; // Controla visibilidad de la contraseña
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo/icono de la aplicación
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.task_alt,
                        size: 60,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Título dinámico según modo (login/registro)
                  Text(
                    _isLogin ? '¡Hola de nuevo!' : 'Crear cuenta',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subtítulo dinámico
                  Text(
                    _isLogin 
                        ? 'Inicia sesión para continuar'
                        : 'Regístrate para comenzar',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Formulario de autenticación
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Campo de nombre de usuario (solo en registro)
                        if (!_isLogin)
                          Column(
                            children: [
                              TextFormField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre de usuario',
                                  prefixIcon: Icon(Icons.person_outline),
                                  filled: true,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingresa tu nombre';
                                  }
                                  if (value.length < 3) {
                                    return 'Mínimo 3 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        // Campo de email (siempre visible)
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.email_outlined),
                            filled: true,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu email';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Ingresa un email válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Campo de contraseña con toggle de visibilidad
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu contraseña';
                            }
                            if (value.length < 6) {
                              return 'Mínimo 6 caracteres';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Mostrar errores de autenticación
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      if (auth.error != null) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  auth.error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: auth.clearError,
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 24),
                  // Botón principal de acción (login/registro)
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(
                              _isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Botón para alternar entre login y registro
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _formKey.currentState?.reset();
                          Provider.of<AuthProvider>(context, listen: false).clearError();
                        });
                      },
                      child: Text(
                        _isLogin
                            ? '¿No tienes cuenta? Regístrate'
                            : '¿Ya tienes cuenta? Inicia sesión',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Credenciales de prueba (solo en modo login)
                  if (_isLogin)
                    const Column(
                      children: [
                        Divider(),
                        SizedBox(height: 20),
                        Text(
                          'Credenciales de prueba',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            Chip(
                              label: Text('test@example.com'),
                              backgroundColor: Color.fromRGBO(158, 158, 158, 0.1),
                            ),
                            Chip(
                              label: Text('123456'),
                              backgroundColor: Color.fromRGBO(158, 158, 158, 0.1),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  /// Procesa el envío del formulario de autenticación
  /// Realiza login o registro según el modo actual
  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      bool success;
      
      // Ejecutar login o registro según el modo
      if (_isLogin) {
        success = await authProvider.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        success = await authProvider.register(
          _usernameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
      
      // Actualizar estado de carga
      if (mounted) {
        setState(() => _isLoading = false);
      }
      
      // Navegar a HomeScreen si la autenticación fue exitosa
      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }
  
  @override
  void dispose() {
    // Limpiar controllers para evitar memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
}