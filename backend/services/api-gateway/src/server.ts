import { buildApp } from './app'
import { config } from './config'
import { logger } from './utils/logger'
import { connectDatabase } from './utils/database'

async function start() {
  try {
    // Connect to database
    await connectDatabase()

    // Build and start the app
    const app = await buildApp()

    await app.listen({
      port: config.PORT,
      host: '0.0.0.0',
    })

    logger.info(`🚀 Server running at http://localhost:${config.PORT}`)
    
    if (config.NODE_ENV !== 'production') {
      logger.info(`📚 API Documentation at http://localhost:${config.PORT}/documentation`)
    }

    // Graceful shutdown
    const signals = ['SIGINT', 'SIGTERM']
    signals.forEach((signal) => {
      process.on(signal, async () => {
        logger.info(`Received ${signal}, shutting down gracefully...`)
        await app.close()
        process.exit(0)
      })
    })
  } catch (err) {
    logger.error(err, 'Failed to start server')
    process.exit(1)
  }
}

start()
