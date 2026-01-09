<img width="311" height="311" alt="image" src="https://github.com/user-attachments/assets/f54457dc-2039-46c7-af1b-b0c0dcac4035" />


# 2a-Oportunidad-3er-Departamental-_-Garcia Zurita Fernando Uriel-15701 - Desarrollo de Aplicaciones Moviles
Desarrollo de una aplicación móvil en Flutter que permita a un usuario gestionar tareas, autenticarse, y consultar información desde:   un backend propio (API REST que ustedes implementan), y al menos 1 API pública externa consumida desde Flutter. 

---

# 📌 Aplicación de Gestión de Tareas

Aplicación móvil completa para **gestión de tareas** desarrollada con **Flutter** y **Node.js + Express**.
Incluye autenticación de usuarios, CRUD de tareas y consumo de API externa de clima.

---

## 🚀 Características Principales

* ✅ Autenticación segura con **JWT** (registro y login)
* ✅ CRUD completo de tareas (crear, leer, actualizar, eliminar)
* ✅ Filtros y búsqueda por estado y prioridad
* ✅ API externa integrada (**OpenWeather – clima en tiempo real**)
* ✅ Interfaz moderna con **Flutter Material Design**
* ✅ Backend robusto con **Node.js + Express + SQLite**
* ✅ Persistencia de sesión con **SharedPreferences**

---

## 🏗️ Arquitectura

Frontend (Flutter) → Backend (Node.js/Express) → Base de Datos (SQLite)
             ↓
          OpenWeather API

---

## 📋 Prerrequisitos

### 🔙 Backend

* Node.js v18 o superior
* npm v9 o superior
* Git

### 📱 Frontend

* Flutter SDK v3.0 o superior
* Android Studio o Xcode (emuladores)
* IDE recomendado: VS Code o Android Studio

---

## 🔧 Cómo levantar el Backend (Node.js + Express)

1. **Clonar el repositorio**

```
git clone <tu-repositorio>
cd <nombre-repositorio>/backend
```

2. **Instalar dependencias**

```
npm install
```

3. **Configurar variables de entorno**

Crear archivo `.env` en `/backend`:

```
PORT=3000
SECRET_KEY=clave_secreta_super_segura
```

4. **Iniciar servidor**

```
# modo desarrollo
npm run dev

# modo producción
npm start
```

5. **Verificar servidor**

Abrir en navegador:

```
http://localhost:3000
```

Respuesta esperada:

```
{
 "success": true,
 "message": "🚀 API de Gestión de Tareas funcionando",
 "version": "1.0.0"
}
```

---

## 📱 Cómo ejecutar la App Flutter

1. Ir a carpeta del proyecto Flutter

```
cd <nombre-repositorio>/flutter_app
```

2. Instalar dependencias

```
flutter pub get
```

3. **Configurar URL del backend**

Editar `lib/api_service.dart`:

```dart
// Android emulador
static const String _baseUrl = 'http://10.0.2.2:3000';

// iOS simulador
// static const String _baseUrl = 'http://localhost:3000';

// Dispositivo físico
// static const String _baseUrl = 'http://192.168.1.X:3000';
```

4. **Ejecutar aplicación**

```
flutter run
```

5. **Compilar**

```
flutter build apk
flutter build ios
```

---

## 🔑 Credenciales de prueba

* 📧 Email: [test@example.com]
* 🔑 Contraseña: 123456

Incluye:

* 4 tareas de ejemplo
* Datos básicos de perfil
* Acceso completo a funcionalidades

---

## 🔌 Endpoints principales del Backend

### 🔐 Autenticación

* POST /auth/register — registrar usuario
* POST /auth/login — iniciar sesión

### 📋 Tareas (requieren JWT)

* GET /tasks — listar tareas
* POST /tasks — crear tarea
* GET /tasks/:id — obtener tarea
* PUT /tasks/:id — actualizar tarea
* DELETE /tasks/:id — eliminar tarea

### 👤 Perfil

* GET /auth/profile — datos de perfil

---

## 📡 Ejemplos de uso de la API

### 1️⃣ Login para obtener token

```
curl -X POST http://localhost:3000/auth/login \
-H "Content-Type: application/json" \
-d '{"email":"test@example.com","password":"123456"}'
```

### 2️⃣ Obtener tareas

```
curl http://localhost:3000/tasks \
-H "Authorization: Bearer TU_TOKEN_JWT"
```

### 3️⃣ Crear tarea

```
curl -X POST http://localhost:3000/tasks \
-H "Content-Type: application/json" \
-H "Authorization: Bearer TU_TOKEN_JWT" \
-d '{
 "titulo":"Nueva tarea",
 "descripcion":"Descripción de ejemplo",
 "prioridad":"alta",
 "estado":"pendiente"
}'
```

---

## 🗂️ Estructura del Proyecto

### 🖥️ Backend

```
backend/
├── app.js
├── database.js
├── package.json
├── .env
└── database.sqlite
```

### 📱 Frontend Flutter

```
lib/
├── main.dart
├── api_service.dart
├── auth_provider.dart
├── task_model.dart
├── home_screen.dart
└── login_screen.dart
```

---

## 🌤️ API Externa Integrada

OpenWeather API — clima en tiempo real

* Ciudades: Lima, Buenos Aires, Madrid, Ciudad de México
* Datos: temperatura, humedad, viento, condiciones
* Actualización: inmediata al seleccionar ciudad

---

## 🐛 Solución de problemas comunes

### ❌ No conecta al backend

* iniciar servidor
* verificar URL en `api_service.dart`
* Android → `10.0.2.2:3000`
* iOS → `localhost:3000`

### ❌ Problemas con npm

```
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
```

### ❌ Problemas Flutter

```
flutter clean
flutter pub get
flutter upgrade
```

### ❌ No se crea base de datos

* permisos de Node.js
* borrar `database.sqlite` corrupto
* ejecutar `npm run db:reset`

## 📊 Tecnologías utilizadas

### Backend

* Node.js
* Express.js
* SQLite3
* JWT
* bcryptjs
* CORS

### Frontend

* Flutter
* Dart
* Provider
* HTTP
* SharedPreferences
* Intl
