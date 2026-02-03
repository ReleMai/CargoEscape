/**
 * MCP Server - HTTP/SSE Transport
 * Features: Plugin architecture, caching, metrics, resources, prompts, and more
 * 
 * @version 2.0.0
 */

import http from 'http';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import { EventEmitter } from 'events';

// Import lib modules
import { logger } from './lib/logger.js';
import { Cache, toolCache, statsCache, fileCache } from './lib/cache.js';
import { metrics } from './lib/metrics.js';
import { pluginManager } from './lib/plugins.js';

// Import dashboard
import { generateDashboardHTML } from './dashboard-hub.js';

// ==================== CONFIGURATION ====================

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const WORKSPACE = process.env.WORKSPACE_PATH || '/workspace';
const PORT = parseInt(process.env.PORT) || 3000;
const HOST = process.env.HOST || '127.0.0.1';
const API_KEY = process.env.MCP_API_KEY || 'CargoEscapeBigProject';
const PROJECT_NAME = process.env.PROJECT_NAME || 'Cargo Escape';

// ==================== INITIALIZE MODULES ====================

// Set workspace for plugin manager
pluginManager.workspace = WORKSPACE;

// Log startup
logger.info('MCP Hub Server starting', {
  workspace: WORKSPACE,
  port: PORT,
  host: HOST
});

// ==================== SECURITY ====================

function isLocalhost(ip) {
  return ip === '127.0.0.1' || ip === '::1' || ip === 'localhost' || ip === '::ffff:127.0.0.1';
}

function validateApiKey(req) {
  const auth = req.headers.authorization;
  if (!auth) return false;
  
  const [type, key] = auth.split(' ');
  return type === 'Bearer' && key === API_KEY;
}

function getClientIP(req) {
  return req.headers['x-forwarded-for']?.split(',')[0]?.trim() || 
         req.socket?.remoteAddress || 
         'unknown';
}

// Rate limiting (non-localhost only)
const rateLimits = new Map();
const RATE_LIMIT = 100;
const RATE_WINDOW = 60000;

function checkRateLimit(ip) {
  if (isLocalhost(ip)) return true;
  
  const now = Date.now();
  const record = rateLimits.get(ip) || { count: 0, start: now };
  
  if (now - record.start > RATE_WINDOW) {
    record.count = 0;
    record.start = now;
  }
  
  record.count++;
  rateLimits.set(ip, record);
  
  return record.count <= RATE_LIMIT;
}

// ==================== CORS ====================

function setCORSHeaders(res, origin) {
  const allowedOrigins = [
    'http://localhost:3100',
    'http://127.0.0.1:3100',
    'http://localhost:3000',
    'http://127.0.0.1:3000'
  ];
  
  if (allowedOrigins.includes(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
  }
  
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Max-Age', '86400');
}

// ==================== SECURITY HEADERS ====================

function setSecurityHeaders(res) {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
}

// ==================== RESPONSE HELPERS ====================

function sendJSON(res, data, status = 200) {
  setSecurityHeaders(res);
  const json = JSON.stringify(data);
  res.writeHead(status, { 
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(json),
    'Cache-Control': 'private, max-age=5'
  });
  res.end(json);
}

function sendError(res, message, status = 400) {
  setSecurityHeaders(res);
  // Sanitize error messages to prevent information leakage
  const safeMessage = typeof message === 'string' ? message.replace(/\/workspace\/[^\s]*/g, '[path]') : 'An error occurred';
  const json = JSON.stringify({ error: safeMessage });
  res.writeHead(status, { 
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(json)
  });
  res.end(json);
}

function sendHTML(res, html) {
  setSecurityHeaders(res);
  // CSP allows inline scripts/styles (needed for single-page dashboard) and localhost API calls
  res.setHeader('Content-Security-Policy', "default-src 'self' http://localhost:* http://127.0.0.1:*; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self' http://localhost:* http://127.0.0.1:* ws://localhost:* ws://127.0.0.1:*");
  // Disable caching to always serve fresh content
  res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
  res.setHeader('Pragma', 'no-cache');
  res.setHeader('Expires', '0');
  res.setHeader('ETag', Date.now().toString());
  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
  res.end(html);
}

// ==================== SSE (Server-Sent Events) ====================

const sseClients = new Set();

function sendSSE(data) {
  const message = `data: ${JSON.stringify(data)}\n\n`;
  for (const client of sseClients) {
    client.write(message);
  }
}

// ==================== PROJECT STATS ====================

async function getProjectStats() {
  const cached = statsCache.get('project');
  if (cached) {
    metrics.trackCacheHit('stats', true);
    return cached;
  }
  
  const stats = {
    scripts: 0,
    scenes: 0,
    resources: 0,
    linesOfCode: 0,
    todos: 0,
    lastUpdated: new Date().toISOString()
  };
  
  // Parallel file scanning with batched I/O
  async function countFiles(dir, extensions, countTodos = false) {
    const results = { count: 0, lines: 0, todos: 0 };
    const pendingReads = [];
    
    async function scanDir(currentDir) {
      try {
        const entries = await fs.readdir(currentDir, { withFileTypes: true });
        const subDirs = [];
        
        for (const entry of entries) {
          if (entry.name.startsWith('.')) continue;
          
          const fullPath = path.join(currentDir, entry.name);
          
          if (entry.isDirectory()) {
            subDirs.push(fullPath);
          } else if (entry.isFile()) {
            const ext = extensions.find(e => entry.name.endsWith(e));
            if (ext) {
              results.count++;
              pendingReads.push(fullPath);
            }
          }
        }
        
        // Scan subdirs in parallel (max 4 at once)
        for (let i = 0; i < subDirs.length; i += 4) {
          const batch = subDirs.slice(i, i + 4);
          await Promise.all(batch.map(d => scanDir(d)));
        }
      } catch {}
    }
    
    await scanDir(dir);
    
    // Read files in parallel batches (max 10 at once for memory)
    for (let i = 0; i < pendingReads.length; i += 10) {
      const batch = pendingReads.slice(i, i + 10);
      const contents = await Promise.all(
        batch.map(async (filePath) => {
          try {
            return await fs.readFile(filePath, 'utf-8');
          } catch {
            return '';
          }
        })
      );
      
      for (const content of contents) {
        if (content) {
          results.lines += content.split('\n').length;
          if (countTodos) {
            const matches = content.match(/TODO|FIXME|HACK|XXX/gi);
            if (matches) results.todos += matches.length;
          }
        }
      }
    }
    
    return results;
  }
  
  // Run all three scans in parallel
  const [scripts, scenes, resources] = await Promise.all([
    countFiles(WORKSPACE, ['.gd'], true),  // Count TODOs only in scripts
    countFiles(WORKSPACE, ['.tscn'], false),
    countFiles(WORKSPACE, ['.tres'], false)
  ]);
  
  stats.scripts = scripts.count;
  stats.scenes = scenes.count;
  stats.resources = resources.count;
  stats.linesOfCode = scripts.lines;
  stats.todos = scripts.todos;
  
  // Cache for 2 minutes (stats don't change often)
  statsCache.set('project', stats, 120000);
  return stats;
}

// ==================== NOTIFICATIONS ====================

const SETTINGS_FILE = path.join(WORKSPACE, '.mcp-server', 'settings.json');
const NOTIFICATIONS_FILE = path.join(WORKSPACE, '.mcp-server', 'notifications.json');

async function getNotifications() {
  const stats = await getProjectStats();
  const notifications = [];
  
  // Load saved notifications
  try {
    const data = await fs.readFile(NOTIFICATIONS_FILE, 'utf-8');
    const saved = JSON.parse(data);
    notifications.push(...saved.filter(n => !n.dismissed));
  } catch {}
  
  // Check for thresholds
  const settings = await getSettings();
  
  if (settings.notifications?.todoThreshold && stats.todos > settings.notifications.todoThreshold) {
    notifications.push({
      id: 'todo-threshold',
      type: 'warning',
      title: 'TODO Threshold Exceeded',
      message: `You have ${stats.todos} TODOs (threshold: ${settings.notifications.todoThreshold})`,
      timestamp: Date.now(),
      persistent: true
    });
  }
  
  if (settings.notifications?.linesThreshold && stats.linesOfCode > settings.notifications.linesThreshold) {
    notifications.push({
      id: 'lines-threshold',
      type: 'info',
      title: 'Large Codebase',
      message: `Your codebase has ${stats.linesOfCode.toLocaleString()} lines of code`,
      timestamp: Date.now(),
      persistent: true
    });
  }
  
  // Check git status
  try {
    const { spawn } = await import('child_process');
    const gitStatus = await new Promise((resolve) => {
      const proc = spawn('git', ['status', '--porcelain'], { cwd: WORKSPACE });
      let output = '';
      proc.stdout.on('data', (d) => output += d);
      proc.on('close', () => resolve(output));
    });
    
    const changes = gitStatus.split('\n').filter(l => l.trim()).length;
    if (changes > 10) {
      notifications.push({
        id: 'git-changes',
        type: 'info',
        title: 'Uncommitted Changes',
        message: `You have ${changes} uncommitted changes`,
        timestamp: Date.now(),
        persistent: false
      });
    }
  } catch {}
  
  return {
    notifications,
    count: notifications.length,
    unread: notifications.filter(n => !n.read).length
  };
}

async function getSettings() {
  const defaults = {
    theme: 'dark',
    autoRefresh: true,
    refreshInterval: 30000,
    notifications: {
      enabled: true,
      todoThreshold: 50,
      linesThreshold: 100000
    },
    favorites: ['project_stats', 'git_status', 'find_todos'],
    collapsedSections: []
  };
  
  try {
    const data = await fs.readFile(SETTINGS_FILE, 'utf-8');
    return { ...defaults, ...JSON.parse(data) };
  } catch {
    return defaults;
  }
}

async function saveSettings(settings) {
  try {
    await fs.mkdir(path.dirname(SETTINGS_FILE), { recursive: true });
    await fs.writeFile(SETTINGS_FILE, JSON.stringify(settings, null, 2));
  } catch (error) {
    logger.error(`Failed to save settings: ${error.message}`);
  }
}

async function exportData(type) {
  switch (type) {
    case 'stats':
      return await getProjectStats();
    case 'tools':
      return pluginManager.getAllTools().map(t => t.definition);
    case 'metrics':
      return metrics.getMetrics();
    case 'history':
      try {
        const data = await fs.readFile(path.join(WORKSPACE, '.mcp-server', 'history.json'), 'utf-8');
        return JSON.parse(data);
      } catch {
        return [];
      }
    default:
      return { error: 'Unknown export type' };
  }
}

async function exportCSV(type) {
  if (type === 'todos') {
    const tool = pluginManager.getTool('find_todos');
    if (!tool) return 'Error: find_todos tool not found';
    
    const result = await tool.handler({});
    const rows = ['Type,File,Line,Content'];
    
    for (const [todoType, items] of Object.entries(result.details || {})) {
      for (const item of items) {
        const escapedContent = (item.content || '').replace(/"/g, '""');
        rows.push(`"${todoType}","${item.file}",${item.line},"${escapedContent}"`);
      }
    }
    
    return rows.join('\n');
  }
  
  if (type === 'scripts') {
    const tool = pluginManager.getTool('godot_list_scripts');
    if (!tool) return 'Error: godot_list_scripts tool not found';
    
    const result = await tool.handler({});
    const rows = ['Path'];
    (result.scripts || []).forEach(s => rows.push(`"${s}"`));
    return rows.join('\n');
  }
  
  if (type === 'scenes') {
    const tool = pluginManager.getTool('godot_list_scenes');
    if (!tool) return 'Error: godot_list_scenes tool not found';
    
    const result = await tool.handler({});
    const rows = ['Path'];
    (result.scenes || []).forEach(s => rows.push(`"${s}"`));
    return rows.join('\n');
  }
  
  return 'Error: Unknown export type';
}

// ==================== REQUEST HANDLER ====================

async function handleRequest(req, res) {
  const startTime = Date.now();
  const clientIP = getClientIP(req);
  const origin = req.headers.origin || '';
  const url = new URL(req.url, `http://${req.headers.host}`);
  const pathname = url.pathname;
  
  // Track request
  metrics.trackRequest(req.method, pathname, clientIP);
  
  // Set CORS headers
  setCORSHeaders(res, origin);
  
  // Handle preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }
  
  // Rate limiting
  if (!checkRateLimit(clientIP)) {
    logger.security('Rate limit exceeded', { ip: clientIP });
    sendError(res, 'Rate limit exceeded', 429);
    return;
  }
  
  // Log request
  logger.request(req.method, pathname, clientIP);
  
  try {
    // ==================== PUBLIC ROUTES ====================
    
    // Dashboard
    if (pathname === '/' || pathname === '/dashboard') {
      const html = generateDashboardHTML(PROJECT_NAME);
      sendHTML(res, html);
      return;
    }
    
    // Health check
    if (pathname === '/health') {
      sendJSON(res, {
        status: 'healthy',
        uptime: process.uptime(),
        project: PROJECT_NAME,
        timestamp: new Date().toISOString()
      });
      return;
    }
    
    // SSE endpoint
    if (pathname === '/events') {
      res.writeHead(200, {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive'
      });
      
      sseClients.add(res);
      res.write('data: {"type":"connected"}\n\n');
      
      req.on('close', () => {
        sseClients.delete(res);
      });
      return;
    }
    
    // ==================== PROTECTED ROUTES ====================
    
    // API routes require authentication
    if (pathname.startsWith('/api/')) {
      if (!validateApiKey(req)) {
        logger.security('Unauthorized API access attempt', { ip: clientIP, path: pathname });
        sendError(res, 'Unauthorized', 401);
        return;
      }
      
      // Stats
      if (pathname === '/api/stats') {
        const stats = await getProjectStats();
        sendJSON(res, stats);
        return;
      }
      
      // Tools list
      if (pathname === '/api/tools' && req.method === 'GET') {
        const tools = pluginManager.getAllTools().map(t => ({
          name: t.definition.name,
          description: t.definition.description,
          category: t.definition.category,
          tags: t.definition.tags,
          inputSchema: t.definition.inputSchema
        }));
        sendJSON(res, { tools, count: tools.length });
        return;
      }
      
      // Tool execution
      const toolMatch = pathname.match(/^\/api\/tools\/(.+)$/);
      if (toolMatch && req.method === 'POST') {
        const toolName = toolMatch[1];
        
        // Security: Validate tool name (alphanumeric and underscores only)
        if (!/^[a-zA-Z0-9_]+$/.test(toolName)) {
          logger.security('Invalid tool name attempted', { toolName, ip: clientIP });
          sendError(res, 'Invalid tool name', 400);
          return;
        }
        
        const tool = pluginManager.getTool(toolName);
        
        if (!tool) {
          sendError(res, 'Tool not found', 404);
          return;
        }
        
        // Parse body with size limit (1MB max)
        let body = {};
        const contentLength = parseInt(req.headers['content-length'] || '0');
        const MAX_BODY_SIZE = 1024 * 1024; // 1MB
        
        if (contentLength > MAX_BODY_SIZE) {
          logger.security('Body size limit exceeded', { size: contentLength, ip: clientIP });
          sendError(res, 'Request body too large', 413);
          return;
        }
        
        if (contentLength > 0) {
          const data = await new Promise((resolve, reject) => {
            let chunks = '';
            let received = 0;
            
            req.on('data', chunk => {
              received += chunk.length;
              if (received > MAX_BODY_SIZE) {
                reject(new Error('Body too large'));
                return;
              }
              chunks += chunk;
            });
            req.on('end', () => resolve(chunks));
            req.on('error', reject);
          });
          try {
            body = JSON.parse(data);
          } catch {
            body = {};
          }
        }
        
        // Check cache
        const cacheKey = `${toolName}:${JSON.stringify(body)}`;
        const cached = toolCache.get(cacheKey);
        if (cached) {
          metrics.trackCacheHit('tool', true);
          logger.info(`Tool ${toolName} served from cache`);
          sendJSON(res, cached);
          return;
        }
        
        // Execute tool
        const toolStart = Date.now();
        try {
          logger.info(`Executing tool ${toolName}`, { args: body });
          const result = await tool.handler(body);
          const duration = Date.now() - toolStart;
          
          metrics.trackToolExecution(toolName, true, duration);
          
          // Cache result
          toolCache.set(cacheKey, result);
          
          // Send SSE notification
          sendSSE({ type: 'tool_executed', tool: toolName, duration, success: true });
          
          sendJSON(res, result);
        } catch (error) {
          const duration = Date.now() - toolStart;
          metrics.trackToolExecution(toolName, false, duration);
          logger.error(`Tool ${toolName} failed: ${error.message}`);
          sendError(res, error.message, 500);
        }
        return;
      }
      
      // Resources list
      if (pathname === '/api/resources' && req.method === 'GET') {
        const resources = pluginManager.getAllResources().map(r => ({
          uri: r.uri,
          name: r.name,
          description: r.description,
          mimeType: r.mimeType
        }));
        sendJSON(res, { resources, count: resources.length });
        return;
      }
      
      // Resource read
      const resourceMatch = pathname.match(/^\/api\/resources\/(.+)$/);
      if (resourceMatch && req.method === 'GET') {
        const resourceUri = decodeURIComponent(resourceMatch[1]);
        const resource = pluginManager.getResource(resourceUri);
        
        if (!resource) {
          sendError(res, 'Resource not found', 404);
          return;
        }
        
        try {
          const content = await resource.handler();
          sendJSON(res, { uri: resourceUri, content });
        } catch (error) {
          sendError(res, error.message, 500);
        }
        return;
      }
      
      // Prompts list
      if (pathname === '/api/prompts' && req.method === 'GET') {
        const prompts = pluginManager.getAllPrompts().map(p => ({
          name: p.name,
          description: p.description,
          arguments: p.arguments
        }));
        sendJSON(res, { prompts, count: prompts.length });
        return;
      }
      
      // Prompt execution
      const promptMatch = pathname.match(/^\/api\/prompts\/(.+)$/);
      if (promptMatch && req.method === 'POST') {
        const promptName = promptMatch[1];
        const prompt = pluginManager.getPrompt(promptName);
        
        if (!prompt) {
          sendError(res, 'Prompt not found', 404);
          return;
        }
        
        // Parse body
        let body = {};
        if (req.headers['content-length'] > 0) {
          const data = await new Promise((resolve) => {
            let chunks = '';
            req.on('data', chunk => chunks += chunk);
            req.on('end', () => resolve(chunks));
          });
          try {
            body = JSON.parse(data);
          } catch {
            body = {};
          }
        }
        
        try {
          const result = await prompt.handler(body);
          sendJSON(res, result);
        } catch (error) {
          sendError(res, error.message, 500);
        }
        return;
      }
      
      // Metrics
      if (pathname === '/api/metrics') {
        const metricsData = metrics.getMetrics();
        sendJSON(res, metricsData);
        return;
      }
      
      // Prometheus metrics
      if (pathname === '/api/metrics/prometheus') {
        const prom = metrics.toPrometheus();
        res.writeHead(200, { 'Content-Type': 'text/plain' });
        res.end(prom);
        return;
      }
      
      // Cache stats
      if (pathname === '/api/cache') {
        sendJSON(res, {
          tool: toolCache.getStats(),
          stats: statsCache.getStats(),
          file: fileCache.getStats()
        });
        return;
      }
      
      // Clear cache
      if (pathname === '/api/cache/clear' && req.method === 'POST') {
        toolCache.clear();
        statsCache.clear();
        fileCache.clear();
        sendJSON(res, { message: 'Cache cleared' });
        return;
      }
      
      // ==================== NOTIFICATION SYSTEM ====================
      
      // Get notifications
      if (pathname === '/api/notifications' && req.method === 'GET') {
        const notifications = await getNotifications();
        sendJSON(res, notifications);
        return;
      }
      
      // ==================== SETTINGS SYSTEM ====================
      
      // Get settings
      if (pathname === '/api/settings' && req.method === 'GET') {
        const settings = await getSettings();
        sendJSON(res, settings);
        return;
      }
      
      // Save settings
      if (pathname === '/api/settings' && req.method === 'POST') {
        let body = {};
        if (req.headers['content-length'] > 0) {
          const data = await new Promise((resolve) => {
            let chunks = '';
            req.on('data', chunk => chunks += chunk);
            req.on('end', () => resolve(chunks));
          });
          body = JSON.parse(data);
        }
        await saveSettings(body);
        sendJSON(res, { message: 'Settings saved' });
        return;
      }
      
      // ==================== EXPORT ENDPOINTS ====================
      
      // Export data as JSON
      if (pathname === '/api/export/json' && req.method === 'GET') {
        const type = url.searchParams.get('type') || 'stats';
        const data = await exportData(type);
        res.writeHead(200, {
          'Content-Type': 'application/json',
          'Content-Disposition': `attachment; filename="${type}-export.json"`
        });
        res.end(JSON.stringify(data, null, 2));
        return;
      }
      
      // Export data as CSV
      if (pathname === '/api/export/csv' && req.method === 'GET') {
        const type = url.searchParams.get('type') || 'todos';
        const csv = await exportCSV(type);
        res.writeHead(200, {
          'Content-Type': 'text/csv',
          'Content-Disposition': `attachment; filename="${type}-export.csv"`
        });
        res.end(csv);
        return;
      }
    }
    
    // ==================== MCP PROTOCOL ROUTES ====================
    
    // MCP capabilities
    if (pathname === '/mcp/capabilities') {
      sendJSON(res, {
        protocol: 'mcp',
        version: '1.0.0',
        capabilities: {
          tools: true,
          resources: true,
          prompts: true,
          sampling: false,
          logging: true
        },
        server: {
          name: 'cargo-escape-mcp-hub',
          version: '2.0.0'
        }
      });
      return;
    }
    
    // MCP tools/list
    if (pathname === '/mcp/tools/list') {
      const tools = pluginManager.getAllTools().map(t => t.definition);
      sendJSON(res, { tools });
      return;
    }
    
    // MCP resources/list
    if (pathname === '/mcp/resources/list') {
      const resources = pluginManager.getAllResources().map(r => ({
        uri: r.uri,
        name: r.name,
        description: r.description,
        mimeType: r.mimeType
      }));
      sendJSON(res, { resources });
      return;
    }
    
    // MCP prompts/list
    if (pathname === '/mcp/prompts/list') {
      const prompts = pluginManager.getAllPrompts().map(p => ({
        name: p.name,
        description: p.description,
        arguments: p.arguments
      }));
      sendJSON(res, { prompts });
      return;
    }
    
    // 404
    sendError(res, 'Not found', 404);
    
  } catch (error) {
    logger.error(`Request handler error: ${error.message}`);
    sendError(res, 'Internal server error', 500);
  } finally {
    const duration = Date.now() - startTime;
    logger.debug(`Request completed in ${duration}ms`);
  }
}

// ==================== PLUGIN LOADING ====================

async function loadPlugins() {
  const pluginsDir = path.join(__dirname, 'plugins');
  
  try {
    const files = await fs.readdir(pluginsDir);
    
    for (const file of files) {
      if (file.endsWith('.js')) {
        const pluginPath = path.join(pluginsDir, file);
        try {
          const plugin = await import(`file://${pluginPath}`);
          if (plugin.register) {
            plugin.register(pluginManager);
            logger.info(`Loaded plugin: ${file}`);
          }
        } catch (error) {
          logger.error(`Failed to load plugin ${file}: ${error.message}`);
        }
      }
    }
    
    const stats = pluginManager.getStats();
    logger.info(`Plugins loaded: ${stats.tools} tools, ${stats.resources} resources, ${stats.prompts} prompts`);
  } catch (error) {
    logger.error(`Failed to load plugins directory: ${error.message}`);
  }
}

// ==================== SERVER STARTUP ====================

async function startServer() {
  logger.info('='.repeat(50));
  logger.info('🚀 MCP Project Hub');
  logger.info('='.repeat(50));
  
  // Load plugins
  await loadPlugins();
  
  // Create server
  const server = http.createServer(handleRequest);
  
  // Graceful shutdown
  const shutdown = async () => {
    logger.info('Shutting down server...');
    
    // Close SSE connections
    for (const client of sseClients) {
      client.end();
    }
    
    // Close server
    server.close(() => {
      logger.info('Server closed');
      process.exit(0);
    });
    
    // Force exit after 5 seconds
    setTimeout(() => {
      logger.warn('Forcing shutdown');
      process.exit(1);
    }, 5000);
  };
  
  process.on('SIGTERM', shutdown);
  process.on('SIGINT', shutdown);
  
  // Start listening
  server.listen(PORT, HOST, () => {
    logger.info(`Server listening on http://${HOST}:${PORT}`);
    logger.info(`Project: ${PROJECT_NAME}`);
    logger.info(`Workspace: ${WORKSPACE}`);
    logger.info(`Dashboard: http://${HOST}:${PORT}/`);
    logger.info('='.repeat(50));
  });
}

// Start the server
startServer().catch(error => {
  logger.error(`Failed to start server: ${error.message}`);
  process.exit(1);
});
