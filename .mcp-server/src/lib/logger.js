/**
 * Structured Logger for MCP Server
 * Provides JSON logging with levels, request tracing, and security events
 */

const LOG_LEVELS = {
  debug: 0,
  info: 1,
  warn: 2,
  error: 3,
  security: 4
};

const currentLevel = LOG_LEVELS[process.env.LOG_LEVEL || 'info'];

function formatLog(level, message, meta = {}) {
  return JSON.stringify({
    timestamp: new Date().toISOString(),
    level,
    message,
    ...meta,
    pid: process.pid
  });
}

export const logger = {
  debug(message, meta) {
    if (currentLevel <= LOG_LEVELS.debug) {
      console.log(formatLog('debug', message, meta));
    }
  },
  
  info(message, meta) {
    if (currentLevel <= LOG_LEVELS.info) {
      console.log(formatLog('info', message, meta));
    }
  },
  
  warn(message, meta) {
    if (currentLevel <= LOG_LEVELS.warn) {
      console.warn(formatLog('warn', message, meta));
    }
  },
  
  error(message, meta) {
    if (currentLevel <= LOG_LEVELS.error) {
      console.error(formatLog('error', message, meta));
    }
  },
  
  security(message, meta) {
    console.warn(formatLog('security', message, { ...meta, category: 'SECURITY' }));
  },
  
  request(req, res, duration) {
    const meta = {
      method: req?.method,
      url: req?.url,
      status: res?.statusCode,
      duration: `${duration}ms`,
      ip: req?.headers?.['x-forwarded-for']?.split(',')[0] || req?.socket?.remoteAddress || 'unknown'
    };
    
    if (res.statusCode >= 400) {
      this.warn('Request failed', meta);
    } else {
      this.info('Request completed', meta);
    }
  },
  
  tool(toolName, duration, success, meta = {}) {
    this.info(`Tool executed: ${toolName}`, {
      tool: toolName,
      duration: `${duration}ms`,
      success,
      ...meta
    });
  }
};

export default logger;
