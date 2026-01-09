const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
require('dotenv').config();
const db = require('./database.js');

const app = express();
const PORT = process.env.PORT || 3000;
const SECRET_KEY = process.env.SECRET_KEY || 'clave_secreta_super_segura';

// Middleware
app.use(cors());
app.use(express.json());

// Middleware de autenticación
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    
    if (!token) return res.sendStatus(401);
    
    jwt.verify(token, SECRET_KEY, (err, user) => {
        if (err) return res.sendStatus(403);
        req.user = user;
        next();
    });
};

// RUTAS DE AUTENTICACIÓN

// Registro
app.post('/auth/register', async (req, res) => {
    try {
        const { username, email, password } = req.body;
        
        if (!username || !email || !password) {
            return res.status(400).json({ 
                success: false,
                error: 'Todos los campos son requeridos' 
            });
        }
        
        if (password.length < 6) {
            return res.status(400).json({
                success: false,
                error: 'La contraseña debe tener al menos 6 caracteres'
            });
        }
        
        // Verificar si el usuario ya existe
        db.get('SELECT id FROM users WHERE email = ? OR username = ?', 
            [email, username], 
            async (err, row) => {
                if (err) {
                    return res.status(500).json({ 
                        success: false,
                        error: 'Error en la base de datos' 
                    });
                }
                
                if (row) {
                    return res.status(400).json({ 
                        success: false,
                        error: 'Usuario o email ya existe' 
                    });
                }
                
                // Hashear contraseña
                const hashedPassword = await bcrypt.hash(password, 10);
                
                // Insertar usuario
                db.run('INSERT INTO users (username, email, password) VALUES (?, ?, ?)',
                    [username, email, hashedPassword],
                    function(err) {
                        if (err) {
                            return res.status(500).json({ 
                                success: false,
                                error: 'Error al crear usuario' 
                            });
                        }
                        
                        const token = jwt.sign(
                            { 
                                id: this.lastID, 
                                username, 
                                email 
                            },
                            SECRET_KEY,
                            { expiresIn: '24h' }
                        );
                        
                        res.status(201).json({
                            success: true,
                            message: 'Usuario registrado exitosamente',
                            token,
                            user: { 
                                id: this.lastID, 
                                username, 
                                email 
                            }
                        });
                    }
                );
            }
        );
    } catch (error) {
        res.status(500).json({ 
            success: false,
            error: 'Error interno del servidor' 
        });
    }
});

// Login
app.post('/auth/login', (req, res) => {
    const { email, password } = req.body;
    
    if (!email || !password) {
        return res.status(400).json({ 
            success: false,
            error: 'Email y contraseña son requeridos' 
        });
    }
    
    db.get('SELECT * FROM users WHERE email = ?', [email], async (err, user) => {
        if (err) {
            return res.status(500).json({ 
                success: false,
                error: 'Error en la base de datos' 
            });
        }
        
        if (!user) {
            return res.status(401).json({ 
                success: false,
                error: 'Credenciales inválidas' 
            });
        }
        
        const validPassword = await bcrypt.compare(password, user.password);
        if (!validPassword) {
            return res.status(401).json({ 
                success: false,
                error: 'Credenciales inválidas' 
            });
        }
        
        const token = jwt.sign(
            { 
                id: user.id, 
                username: user.username, 
                email: user.email 
            },
            SECRET_KEY,
            { expiresIn: '24h' }
        );
        
        res.json({
            success: true,
            message: 'Login exitoso',
            token,
            user: { 
                id: user.id, 
                username: user.username, 
                email: user.email 
            }
        });
    });
});

// Obtener perfil del usuario
app.get('/auth/profile', authenticateToken, (req, res) => {
    db.get('SELECT id, username, email, avatar_url, created_at FROM users WHERE id = ?',
        [req.user.id],
        (err, user) => {
            if (err) {
                return res.status(500).json({ 
                    success: false,
                    error: 'Error al obtener perfil' 
                });
            }
            
            res.json({
                success: true,
                user
            });
        }
    );
});

// RUTAS DE TAREAS

// Obtener todas las tareas del usuario
app.get('/tasks', authenticateToken, (req, res) => {
    const { estado, prioridad } = req.query;
    
    let query = 'SELECT * FROM tasks WHERE user_id = ?';
    const params = [req.user.id];
    
    if (estado) {
        query += ' AND estado = ?';
        params.push(estado);
    }
    
    if (prioridad) {
        query += ' AND prioridad = ?';
        params.push(prioridad);
    }
    
    query += ' ORDER BY fechaCreacion DESC';
    
    db.all(query, params, (err, tasks) => {
        if (err) {
            return res.status(500).json({ 
                success: false,
                error: 'Error al obtener tareas' 
            });
        }
        
        res.json({
            success: true,
            tasks: tasks || [],
            total: tasks ? tasks.length : 0
        });
    });
});

// Crear nueva tarea
app.post('/tasks', authenticateToken, (req, res) => {
    const { 
        titulo, 
        descripcion, 
        prioridad, 
        estado, 
        fechaLimite
    } = req.body;
    
    if (!titulo || titulo.trim() === '') {
        return res.status(400).json({ 
            success: false,
            error: 'El título es requerido' 
        });
    }
    
    const fechaCreacion = new Date().toISOString();
    
    db.run(
        `INSERT INTO tasks (
            user_id, titulo, descripcion, prioridad, estado, 
            fechaCreacion, fechaLimite, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [
            req.user.id, 
            titulo.trim(), 
            descripcion || '', 
            prioridad || 'media', 
            estado || 'pendiente', 
            fechaCreacion, 
            fechaLimite || null,
            fechaCreacion
        ],
        function(err) {
            if (err) {
                return res.status(500).json({ 
                    success: false,
                    error: 'Error al crear tarea' 
                });
            }
            
            db.get('SELECT * FROM tasks WHERE id = ?', [this.lastID], (err, task) => {
                if (err) {
                    return res.status(500).json({ 
                        success: false,
                        error: 'Error al obtener tarea creada' 
                    });
                }
                
                res.status(201).json({
                    success: true,
                    message: 'Tarea creada exitosamente',
                    task
                });
            });
        }
    );
});

// Obtener tarea específica
app.get('/tasks/:id', authenticateToken, (req, res) => {
    db.get(
        'SELECT * FROM tasks WHERE id = ? AND user_id = ?',
        [req.params.id, req.user.id],
        (err, task) => {
            if (err) {
                return res.status(500).json({ 
                    success: false,
                    error: 'Error al obtener tarea' 
                });
            }
            
            if (!task) {
                return res.status(404).json({ 
                    success: false,
                    error: 'Tarea no encontrada' 
                });
            }
            
            res.json({
                success: true,
                task
            });
        }
    );
});

// Actualizar tarea
app.put('/tasks/:id', authenticateToken, (req, res) => {
    const { 
        titulo, 
        descripcion, 
        prioridad, 
        estado, 
        fechaLimite
    } = req.body;
    
    const updatedAt = new Date().toISOString();
    
    db.run(
        `UPDATE tasks 
         SET titulo = ?, descripcion = ?, prioridad = ?, estado = ?, 
             fechaLimite = ?, updated_at = ?
         WHERE id = ? AND user_id = ?`,
        [
            titulo || '',
            descripcion || '',
            prioridad || 'media',
            estado || 'pendiente',
            fechaLimite || null,
            updatedAt,
            req.params.id,
            req.user.id
        ],
        function(err) {
            if (err) {
                return res.status(500).json({ 
                    success: false,
                    error: 'Error al actualizar tarea' 
                });
            }
            
            if (this.changes === 0) {
                return res.status(404).json({ 
                    success: false,
                    error: 'Tarea no encontrada' 
                });
            }
            
            db.get('SELECT * FROM tasks WHERE id = ?', [req.params.id], (err, task) => {
                if (err) {
                    return res.status(500).json({ 
                        success: false,
                        error: 'Error al obtener tarea actualizada' 
                    });
                }
                
                res.json({
                    success: true,
                    message: 'Tarea actualizada exitosamente',
                    task
                });
            });
        }
    );
});

// Eliminar tarea
app.delete('/tasks/:id', authenticateToken, (req, res) => {
    db.run(
        'DELETE FROM tasks WHERE id = ? AND user_id = ?',
        [req.params.id, req.user.id],
        function(err) {
            if (err) {
                return res.status(500).json({ 
                    success: false,
                    error: 'Error al eliminar tarea' 
                });
            }
            
            if (this.changes === 0) {
                return res.status(404).json({ 
                    success: false,
                    error: 'Tarea no encontrada' 
                });
            }
            
            res.json({ 
                success: true,
                message: 'Tarea eliminada exitosamente' 
            });
        }
    );
});

// Ruta de prueba
app.get('/', (req, res) => {
    res.json({ 
        success: true,
        message: '🚀 API de Gestión de Tareas funcionando - Segunda vuelta',
        version: '1.0.0'
    });
});

// Ruta 404
app.use((req, res) => {
    res.status(404).json({ 
        success: false,
        error: 'Ruta no encontrada' 
    });
});

// Iniciar servidor
app.listen(PORT, () => {
    console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
});