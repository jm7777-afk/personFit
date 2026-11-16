import { createApp } from './app.js';
import { env } from './config/env.js';
import { db, initDatabase } from './config/database.js';

const startServer = () => {
  try {
    // Inicializar tablas y constraints en SQLite
    initDatabase();
    console.log('✅ Base de datos SQLite inicializada y conectada.');

    const app = createApp();

    const server = app.listen(env.PORT, '0.0.0.0', () => {
      console.log(`🚀 Servidor ejecutándose en http://0.0.0.0:${env.PORT}`);
      console.log(`📡 Entorno: ${env.NODE_ENV}`);
    });

    // Cierre controlado (Graceful shutdown) esencial para Render y contenedores
    const shutdown = (signal) => {
      console.log(`\n🛑 Señal ${signal} recibida. Cerrando servidor de forma segura...`);
      server.close(() => {
        try {
          db.close();
          console.log('🔒 Conexión a SQLite cerrada.');
        } catch (dbErr) {
          console.error('Error al cerrar SQLite:', dbErr);
        }
        process.exit(0);
      });
    };

    process.on('SIGTERM', () => shutdown('SIGTERM'));
    process.on('SIGINT', () => shutdown('SIGINT'));

  } catch (error) {
    console.error('❌ Error fatal al iniciar el servidor:', error);
    process.exit(1);
  }
};

startServer();
