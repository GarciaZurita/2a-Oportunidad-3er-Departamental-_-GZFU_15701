const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcryptjs');
const path = require('path');

// Crear base de datos SQLite en archivo
const dbPath = path.join(__dirname, 'database.sqlite');
const db = new sqlite3.Database(dbPath, (err) => {
    if (err) {
        console.error('❌ Error al conectar a la base de datos:', err);
        process.exit(1);
    } else {
        console.log('✅ Conectado a la base de datos SQLite');
        initDatabase();
    }
});

function initDatabase() {
    // 1. TABLA USUARIOS
    db.run(`CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        avatar_url TEXT DEFAULT '',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`, (err) => {
        if (err) {
            console.error('❌ Error al crear tabla users:', err);
        } else {
            console.log('✅ Tabla users creada/verificada');
        }
    });
    
    // 2. TABLA TAREAS
    db.run(`CREATE TABLE IF NOT EXISTS tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        
        -- Campos requeridos
        titulo TEXT NOT NULL,
        descripcion TEXT,
        prioridad TEXT CHECK(prioridad IN ('alta', 'media', 'baja')) DEFAULT 'media',
        estado TEXT CHECK(estado IN ('pendiente', 'en progreso', 'hecha')) DEFAULT 'pendiente',
        fechaCreacion DATETIME NOT NULL,
        fechaLimite DATETIME,
        
        -- Campos adicionales
        completada INTEGER DEFAULT 0,
        fechaCompletada DATETIME,
        categoria TEXT DEFAULT 'general',
        etiquetas TEXT,
        recordatorio DATETIME,
        
        -- Timestamps
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        
        -- Relación
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )`, (err) => {
        if (err) {
            console.error('❌ Error al crear tabla tasks:', err);
        } else {
            console.log('✅ Tabla tasks creada/verificada');
        }
    });
    
    // 3. ÍNDICES
    db.run(`CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON tasks(user_id)`, () => {
        console.log('✅ Índice idx_tasks_user_id creado');
    });
    
    db.run(`CREATE INDEX IF NOT EXISTS idx_tasks_estado ON tasks(estado)`, () => {
        console.log('✅ Índice idx_tasks_estado creado');
    });
    
    db.run(`CREATE INDEX IF NOT EXISTS idx_tasks_prioridad ON tasks(prioridad)`, () => {
        console.log('✅ Índice idx_tasks_prioridad creado');
    });
    
    // 4. Insertar usuario de prueba
    setTimeout(() => {
        const hashedPassword = bcrypt.hashSync('123456', 10);
        
        db.get('SELECT id FROM users WHERE email = ?', ['test@example.com'], (err, row) => {
            if (err) {
                console.error('❌ Error al verificar usuario de prueba:', err);
                return;
            }
            
            if (!row) {
                db.run(
                    'INSERT INTO users (username, email, password) VALUES (?, ?, ?)',
                    ['test', 'test@example.com', hashedPassword],
                    function(err) {
                        if (err) {
                            console.error('❌ Error al insertar usuario de prueba:', err);
                        } else {
                            const userId = this.lastID;
                            console.log('\n✅ Usuario de prueba creado:');
                            console.log('   👤 Username: test');
                            console.log('   📧 Email: test@example.com');
                            console.log('   🔑 Password: 123456');
                            console.log('   🆔 ID:', userId);
                            
                            // Insertar tareas de ejemplo
                            insertSampleTasks(userId);
                        }
                    }
                );
            } else {
                console.log('\nℹ️ Usuario de prueba ya existe (ID:', row.id, ')');
                insertSampleTasks(row.id);
            }
        });
    }, 1000);
}

function insertSampleTasks(userId) {
    const sampleTasks = [
        {
            titulo: 'Completar proyecto Flutter',
            descripcion: 'Terminar la aplicación de gestión de tareas',
            prioridad: 'alta',
            estado: 'en progreso',
            fechaLimite: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
            categoria: 'trabajo'
        },
        {
            titulo: 'Reunión de equipo',
            descripcion: 'Revisar avances del sprint actual',
            prioridad: 'media',
            estado: 'pendiente',
            fechaLimite: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000).toISOString(),
            categoria: 'reunión'
        },
        {
            titulo: 'Comprar víveres',
            descripcion: 'Leche, huevos, pan y frutas',
            prioridad: 'baja',
            estado: 'pendiente',
            fechaLimite: new Date(Date.now() + 1 * 24 * 60 * 60 * 1000).toISOString(),
            categoria: 'personal'
        },
        {
            titulo: 'Enviar reporte mensual',
            descripcion: 'Preparar y enviar reporte de actividades',
            prioridad: 'alta',
            estado: 'hecha',
            fechaLimite: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
            categoria: 'trabajo',
            completada: 1,
            fechaCompletada: new Date(Date.now() - 12 * 60 * 60 * 1000).toISOString()
        }
    ];
    
    let pendingTasks = sampleTasks.length;
    let insertedCount = 0;
    let skippedCount = 0;
    
    console.log(`\n🔍 Verificando tareas de ejemplo para usuario ${userId}...`);
    
    sampleTasks.forEach((task, index) => {
        // PRIMERO: Verificar si la tarea ya existe para este usuario
        db.get('SELECT id FROM tasks WHERE titulo = ? AND user_id = ?', 
            [task.titulo, userId], 
            (err, existingTask) => {
                if (err) {
                    console.error(`❌ Error al verificar tarea "${task.titulo}":`, err.message);
                    pendingTasks--;
                    checkCompletion(pendingTasks, insertedCount, skippedCount);
                    return;
                }
                
                if (existingTask) {
                    // La tarea YA EXISTE, no insertar
                    skippedCount++;
                    console.log(`⏭️  Tarea "${task.titulo}" ya existe (ID: ${existingTask.id})`);
                    pendingTasks--;
                    checkCompletion(pendingTasks, insertedCount, skippedCount);
                } else {
                    // La tarea NO EXISTE, insertarla
                    const fechaCreacion = new Date(Date.now() - (index * 2 * 60 * 60 * 1000)).toISOString();
                    
                    db.run(
                        `INSERT INTO tasks (
                            user_id, titulo, descripcion, prioridad, estado, 
                            fechaCreacion, fechaLimite, categoria, completada, fechaCompletada
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                        [
                            userId,
                            task.titulo,
                            task.descripcion,
                            task.prioridad,
                            task.estado,
                            fechaCreacion,
                            task.fechaLimite,
                            task.categoria,
                            task.completada || 0,
                            task.fechaCompletada || null
                        ],
                        function(err) {
                            if (err) {
                                console.error(`❌ Error al crear tarea "${task.titulo}":`, err.message);
                            } else {
                                insertedCount++;
                                console.log(`✅ Tarea "${task.titulo}" creada (ID: ${this.lastID})`);
                            }
                            
                            pendingTasks--;
                            checkCompletion(pendingTasks, insertedCount, skippedCount);
                        }
                    );
                }
            }
        );
    });
}

// SOLO MODIFICARÉ ESTA FUNCIÓN - TODO LO DEMÁS QUEDA IGUAL
function checkCompletion(pendingTasks, insertedCount, skippedCount) {
    // Cuando todas las tareas han sido procesadas
    if (pendingTasks === 0) {
        // Primero contar el total de usuarios
        db.get('SELECT COUNT(*) as totalUsers FROM users', [], (err, usersResult) => {
            if (err) {
                console.error('Error al contar usuarios:', err.message);
                return;
            }
            
            // Luego contar tareas del usuario test
            db.get('SELECT COUNT(*) as totalTestTasks FROM tasks WHERE user_id = (SELECT id FROM users WHERE email = ?)', 
                ['test@example.com'], 
                (err, testTasksResult) => {
                    if (err) {
                        console.error('Error al contar tareas de test:', err.message);
                        return;
                    }
                    
                    console.log('\n' + '='.repeat(50));
                    console.log('📊 ESTADO DE LA BASE DE DATOS:');
                    console.log('='.repeat(50));
                    console.log(`👥 Total de usuarios registrados: ${usersResult.totalUsers}`);
                    console.log(`📌 Usuario 'test' tiene: ${testTasksResult.totalTestTasks} tareas`);
                    console.log('='.repeat(50));
                    console.log('🎯 Base de datos lista!');
                    console.log('='.repeat(50));
                }
            );
        });
    }
}

// Función para limpiar tareas duplicadas (opcional - solo si necesitas)
function cleanDuplicateTasks(userId) {
    console.log('\n🧹 Buscando tareas duplicadas...');
    
    // Encontrar tareas duplicadas (mismo título para el mismo usuario)
    db.all(`
        SELECT titulo, COUNT(*) as count 
        FROM tasks 
        WHERE user_id = ?
        GROUP BY titulo 
        HAVING COUNT(*) > 1
        ORDER BY count DESC
    `, [userId], (err, duplicates) => {
        if (err) {
            console.error('Error al buscar duplicados:', err.message);
            return;
        }
        
        if (duplicates.length === 0) {
            console.log('✅ No hay tareas duplicadas');
            return;
        }
        
        console.log(`⚠️  Encontradas ${duplicates.length} tareas con duplicados:`);
        duplicates.forEach(dup => {
            console.log(`   "${dup.titulo}" - ${dup.count} veces`);
        });
    });
}

// Manejar cierre limpio
process.on('SIGINT', () => {
    db.close((err) => {
        if (err) {
            console.error('❌ Error al cerrar la base de datos:', err);
        } else {
            console.log('✅ Base de datos cerrada correctamente');
        }
        process.exit(0);
    });
});

// Exportar la base de datos
module.exports = db;