const fs = require('fs');
const path = require('path');
const app = require('./app');
const config = require('./config');
const db = require('./config/database');

async function start() {
  try {
    await db.testConnection();
    console.log('MySQL connected');
  } catch (err) {
    console.warn('MySQL not available:', err.message);
    console.warn('Run: npm run db:init (requires MySQL running)');
  }

  app.listen(config.port, () => {
    console.log(`MacallinAI API running on http://localhost:${config.port}`);
    console.log(`Environment: ${config.nodeEnv}`);
  });
}

start();
