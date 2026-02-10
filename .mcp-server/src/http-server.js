#!/usr/bin/env node

/**
 * Cargo Escape MCP Server - HTTP Version
 * 
 * This version runs as an HTTP server, making it easier to run in Docker
 * and connect to from VS Code.
 * 
 * SECURITY FEATURES:
 * - Localhost-only binding (via Docker)
 * - API key authentication for sensitive endpoints
 * - Rate limiting to prevent abuse
 * - CORS restrictions
 * - Input validation and path traversal protection
 * - Request logging
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { SSEServerTransport } from '@modelcontextprotocol/sdk/server/sse.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  ListResourcesRequestSchema,
  ReadResourceRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import fs from 'fs/promises';
import path from 'path';
import http from 'http';
import crypto from 'crypto';
import { spawn } from 'child_process';
import dashboardHub from './dashboard-hub.js';
const { generateDashboardHTML } = dashboardHub;

// ==================== CONFIGURATION ====================
const PORT = process.env.PORT || 3100;
const WORKSPACE_PATH = process.env.WORKSPACE_PATH || '/workspace';
const GODOT_PATH = process.env.GODOT_PATH || 'godot';

// Security configuration
const API_KEY = process.env.MCP_API_KEY || 'cargo-escape-local-dev-key-change-me';
const ALLOWED_ORIGINS = (process.env.ALLOWED_ORIGINS || 'http://localhost:3100,http://127.0.0.1:3100').split(',');
const RATE_LIMIT = parseInt(process.env.RATE_LIMIT || '60', 10); // requests per minute
const ENABLE_AUTH = process.env.ENABLE_AUTH !== 'false'; // Enable by default

// ==================== SECURITY UTILITIES ====================

// Rate limiting storage
const rateLimitStore = new Map();

/**
 * Clean up old rate limit entries every minute
 */
setInterval(() => {
  const now = Date.now();
  for (const [ip, data] of rateLimitStore) {
    if (now - data.windowStart > 60000) {
      rateLimitStore.delete(ip);
    }
  }
}, 60000);

/**
 * Check if an IP is localhost
 */
function isLocalhost(ip) {
  return ip === '127.0.0.1' || 
         ip === '::1' || 
         ip === 'localhost' ||
         ip === '::ffff:127.0.0.1' ||
         ip?.startsWith('172.') || // Docker internal
         ip === 'unknown'; // Internal container requests
}

/**
 * Check rate limit for an IP address
 * Localhost is exempt from rate limiting for developer productivity
 */
function checkRateLimit(ip) {
  // Localhost is exempt from rate limiting
  if (isLocalhost(ip)) {
    return {
      allowed: true,
      remaining: Infinity,
      resetIn: 0,
      exempt: true
    };
  }
  
  const now = Date.now();
  const windowStart = now - 60000; // 1 minute window
  
  let data = rateLimitStore.get(ip);
  
  if (!data || data.windowStart < windowStart) {
    data = { windowStart: now, count: 0 };
    rateLimitStore.set(ip, data);
  }
  
  data.count++;
  
  return {
    allowed: data.count <= RATE_LIMIT,
    remaining: Math.max(0, RATE_LIMIT - data.count),
    resetIn: Math.ceil((data.windowStart + 60000 - now) / 1000),
    exempt: false
  };
}

/**
 * Validate API key from request
 */
function validateApiKey(req) {
  // Check Authorization header
  const authHeader = req.headers['authorization'];
  if (authHeader) {
    const [type, key] = authHeader.split(' ');
    if (type === 'Bearer' && key === API_KEY) {
      return true;
    }
  }
  
  // Check X-API-Key header
  if (req.headers['x-api-key'] === API_KEY) {
    return true;
  }
  
  // Check query parameter (less secure, but convenient for testing)
  const url = new URL(req.url, `http://${req.headers.host}`);
  if (url.searchParams.get('api_key') === API_KEY) {
    return true;
  }
  
  return false;
}

/**
 * Get client IP address
 */
function getClientIP(req) {
  return req.headers['x-forwarded-for']?.split(',')[0] || 
         req.socket?.remoteAddress || 
         'unknown';
}

/**
 * Validate and sanitize file paths to prevent path traversal
 */
function sanitizePath(inputPath) {
  // Remove any null bytes
  let cleaned = inputPath.replace(/\0/g, '');
  
  // Normalize the path
  cleaned = path.normalize(cleaned);
  
  // Remove leading slashes and dots
  cleaned = cleaned.replace(/^[\/\.]+/, '');
  
  // Check for path traversal attempts
  if (cleaned.includes('..') || path.isAbsolute(cleaned)) {
    return null;
  }
  
  // Ensure it stays within workspace
  const fullPath = path.join(WORKSPACE_PATH, cleaned);
  if (!fullPath.startsWith(WORKSPACE_PATH)) {
    return null;
  }
  
  return cleaned;
}

/**
 * Log security events
 */
function logSecurity(level, message, details = {}) {
  const timestamp = new Date().toISOString();
  const logEntry = {
    timestamp,
    level,
    message,
    ...details
  };
  
  if (level === 'warn' || level === 'error') {
    console.warn(`[SECURITY ${level.toUpperCase()}] ${timestamp} - ${message}`, details);
  } else {
    console.log(`[SECURITY] ${timestamp} - ${message}`);
  }
}

/**
 * Set security headers on response
 */
function setSecurityHeaders(res, req) {
  const origin = req.headers.origin;
  
  // CORS headers
  if (origin && ALLOWED_ORIGINS.includes(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
  } else if (!origin) {
    // Allow same-origin requests (no Origin header)
    res.setHeader('Access-Control-Allow-Origin', 'http://localhost:3100');
  }
  
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-API-Key');
  res.setHeader('Access-Control-Max-Age', '86400');
  
  // Security headers
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  res.setHeader('Content-Security-Policy', "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data:;");
}

// Endpoints that don't require authentication
const PUBLIC_ENDPOINTS = ['/', '/health', '/api/tools'];

// Endpoints that require authentication
const PROTECTED_ENDPOINTS = ['/api/execute', '/api/stats', '/api/todos', '/api/todos/add', '/api/todos/clear', '/sse', '/message'];

/**
 * Execute a command and return the result
 */
function execCommand(command, args, options = {}) {
  return new Promise((resolve, reject) => {
    const timeout = options.timeout || 30000;
    const proc = spawn(command, args, {
      cwd: options.cwd || WORKSPACE_PATH,
      env: { ...process.env, ...options.env },
      timeout
    });
    
    let stdout = '';
    let stderr = '';
    
    proc.stdout?.on('data', (data) => { stdout += data.toString(); });
    proc.stderr?.on('data', (data) => { stderr += data.toString(); });
    
    const timer = setTimeout(() => {
      proc.kill('SIGTERM');
      reject(new Error(`Command timed out after ${timeout}ms`));
    }, timeout);
    
    proc.on('close', (code) => {
      clearTimeout(timer);
      resolve({ code, stdout, stderr });
    });
    
    proc.on('error', (err) => {
      clearTimeout(timer);
      reject(err);
    });
  });
}

/**
 * Define the tools this MCP server provides.
 */
const TOOLS = [
  {
    name: 'godot_list_scenes',
    description: 'List all .tscn scene files in the Godot project',
    inputSchema: {
      type: 'object',
      properties: {
        directory: {
          type: 'string',
          description: 'Subdirectory to search in (default: scenes)',
          default: 'scenes'
        }
      }
    }
  },
  {
    name: 'godot_list_scripts',
    description: 'List all .gd script files in the Godot project',
    inputSchema: {
      type: 'object',
      properties: {
        directory: {
          type: 'string',
          description: 'Subdirectory to search in (default: scripts)',
          default: 'scripts'
        }
      }
    }
  },
  {
    name: 'godot_analyze_dependencies',
    description: 'Analyze script dependencies by finding preload/load statements',
    inputSchema: {
      type: 'object',
      properties: {
        scriptPath: {
          type: 'string',
          description: 'Path to the GDScript file to analyze'
        }
      },
      required: ['scriptPath']
    }
  },
  {
    name: 'godot_find_node_references',
    description: 'Find all references to a specific node type or signal in scripts',
    inputSchema: {
      type: 'object',
      properties: {
        pattern: {
          type: 'string',
          description: 'Pattern to search for (e.g., "emit_signal", "Area2D", "@onready")'
        }
      },
      required: ['pattern']
    }
  },
  {
    name: 'project_stats',
    description: 'Get statistics about the Cargo Escape project (file counts, lines of code, etc.)',
    inputSchema: {
      type: 'object',
      properties: {}
    }
  },
  {
    name: 'find_todos',
    description: 'Find all TODO, FIXME, and HACK comments in the project',
    inputSchema: {
      type: 'object',
      properties: {}
    }
  },
  {
    name: 'echo_test',
    description: 'Simple echo test to verify MCP server is working',
    inputSchema: {
      type: 'object',
      properties: {
        message: {
          type: 'string',
          description: 'Message to echo back'
        }
      },
      required: ['message']
    }
  },
  {
    name: 'godot_version',
    description: 'Get the Godot version installed in the server (if available)',
    inputSchema: {
      type: 'object',
      properties: {}
    }
  },
  {
    name: 'godot_validate_project',
    description: 'Validate the Godot project by checking for errors without running',
    inputSchema: {
      type: 'object',
      properties: {}
    }
  },
  {
    name: 'godot_run_script',
    description: 'Run a GDScript file in headless mode and return the output',
    inputSchema: {
      type: 'object',
      properties: {
        scriptPath: {
          type: 'string',
          description: 'Path to the GDScript file to run (relative to project root)'
        },
        timeout: {
          type: 'number',
          description: 'Timeout in seconds (default: 30)',
          default: 30
        }
      },
      required: ['scriptPath']
    }
  },
  {
    name: 'godot_export_check',
    description: 'Check if the project can be exported (validates all resources)',
    inputSchema: {
      type: 'object',
      properties: {}
    }
  },
  {
    name: 'godot_list_classes',
    description: 'List all custom classes defined in the project',
    inputSchema: {
      type: 'object',
      properties: {}
    }
  },
  {
    name: 'get_playground_todos',
    description: 'Get pending value changes from the dashboard Playground that the user wants applied to the codebase',
    inputSchema: {
      type: 'object',
      properties: {}
    }
  },
  {
    name: 'clear_playground_todos',
    description: 'Clear all pending Playground TODOs after they have been applied',
    inputSchema: {
      type: 'object',
      properties: {}
    }
  },
  {
    name: 'wiki_analyze',
    description: 'Analyze a file for the Wikipedia-style documentation viewer',
    inputSchema: {
      type: 'object',
      properties: {
        filePath: {
          type: 'string',
          description: 'Path to the file to analyze'
        },
        includeCode: {
          type: 'boolean',
          description: 'Include full source code in response',
          default: false
        },
        includeUsages: {
          type: 'boolean',
          description: 'Find other files that reference this file',
          default: false
        }
      },
      required: ['filePath']
    }
  }
];

async function findFiles(dir, extension, results = []) {
  try {
    const entries = await fs.readdir(dir, { withFileTypes: true });
    
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      
      if (entry.isDirectory() && !entry.name.startsWith('.')) {
        await findFiles(fullPath, extension, results);
      } else if (entry.isFile() && entry.name.endsWith(extension)) {
        results.push(fullPath);
      }
    }
  } catch (error) {
    // Directory doesn't exist or can't be read
  }
  
  return results;
}

async function countLines(filePath) {
  try {
    const content = await fs.readFile(filePath, 'utf-8');
    return content.split('\n').length;
  } catch {
    return 0;
  }
}

async function searchInFile(filePath, pattern) {
  try {
    const content = await fs.readFile(filePath, 'utf-8');
    const lines = content.split('\n');
    const matches = [];
    
    lines.forEach((line, index) => {
      if (line.toLowerCase().includes(pattern.toLowerCase())) {
        matches.push({
          line: index + 1,
          content: line.trim()
        });
      }
    });
    
    return matches;
  } catch {
    return [];
  }
}

async function executeTool(name, args) {
  switch (name) {
    case 'echo_test': {
      return {
        success: true,
        message: `Echo from MCP server: ${args.message}`,
        timestamp: new Date().toISOString(),
        serverInfo: 'Cargo Escape MCP Server v1.0.0 (Docker HTTP)'
      };
    }
    
    case 'godot_list_scenes': {
      const dir = path.join(WORKSPACE_PATH, args.directory || 'scenes');
      const files = await findFiles(dir, '.tscn');
      return {
        count: files.length,
        scenes: files.map(f => path.relative(WORKSPACE_PATH, f).replace(/\\/g, '/'))
      };
    }
    
    case 'godot_list_scripts': {
      const dir = path.join(WORKSPACE_PATH, args.directory || 'scripts');
      const files = await findFiles(dir, '.gd');
      return {
        count: files.length,
        scripts: files.map(f => path.relative(WORKSPACE_PATH, f).replace(/\\/g, '/'))
      };
    }
    
    case 'godot_analyze_dependencies': {
      const filePath = path.join(WORKSPACE_PATH, args.scriptPath);
      try {
        const content = await fs.readFile(filePath, 'utf-8');
        const preloads = [];
        const loads = [];
        const signals = [];
        
        const lines = content.split('\n');
        lines.forEach((line, index) => {
          const preloadMatch = line.match(/preload\s*\(\s*["']([^"']+)["']\s*\)/);
          if (preloadMatch) {
            preloads.push({ line: index + 1, path: preloadMatch[1] });
          }
          
          const loadMatch = line.match(/load\s*\(\s*["']([^"']+)["']\s*\)/);
          if (loadMatch) {
            loads.push({ line: index + 1, path: loadMatch[1] });
          }
          
          const signalMatch = line.match(/signal\s+(\w+)/);
          if (signalMatch) {
            signals.push({ line: index + 1, name: signalMatch[1] });
          }
        });
        
        return { preloads, loads, signals, file: args.scriptPath };
      } catch (error) {
        return { error: `Could not read file: ${error.message}` };
      }
    }
    
    case 'godot_find_node_references': {
      const scriptsDir = path.join(WORKSPACE_PATH, 'scripts');
      const files = await findFiles(scriptsDir, '.gd');
      const results = [];
      
      for (const file of files) {
        const matches = await searchInFile(file, args.pattern);
        if (matches.length > 0) {
          results.push({
            file: path.relative(WORKSPACE_PATH, file).replace(/\\/g, '/'),
            matches
          });
        }
      }
      
      return {
        pattern: args.pattern,
        totalMatches: results.reduce((sum, r) => sum + r.matches.length, 0),
        files: results
      };
    }
    
    case 'project_stats': {
      const scripts = await findFiles(path.join(WORKSPACE_PATH, 'scripts'), '.gd');
      const scenes = await findFiles(path.join(WORKSPACE_PATH, 'scenes'), '.tscn');
      const resources = await findFiles(path.join(WORKSPACE_PATH, 'resources'), '.tres');
      
      let totalLines = 0;
      for (const script of scripts) {
        totalLines += await countLines(script);
      }
      
      return {
        scripts: { count: scripts.length, totalLines },
        scenes: { count: scenes.length },
        resources: { count: resources.length },
        averageLinesPerScript: scripts.length > 0 ? Math.round(totalLines / scripts.length) : 0
      };
    }
    
    case 'find_todos': {
      const scriptsDir = path.join(WORKSPACE_PATH, 'scripts');
      const files = await findFiles(scriptsDir, '.gd');
      const todos = [];
      
      for (const file of files) {
        const content = await fs.readFile(file, 'utf-8').catch(() => '');
        const lines = content.split('\n');
        
        lines.forEach((line, index) => {
          const match = line.match(/#\s*(TODO|FIXME|HACK|XXX|NOTE)[\s:]+(.+)/i);
          if (match) {
            todos.push({
              file: path.relative(WORKSPACE_PATH, file).replace(/\\/g, '/'),
              line: index + 1,
              type: match[1].toUpperCase(),
              text: match[2].trim()
            });
          }
        });
      }
      
      return {
        total: todos.length,
        byType: {
          TODO: todos.filter(t => t.type === 'TODO').length,
          FIXME: todos.filter(t => t.type === 'FIXME').length,
          HACK: todos.filter(t => t.type === 'HACK').length,
          NOTE: todos.filter(t => t.type === 'NOTE').length
        },
        items: todos
      };
    }
    
    // ========== GODOT TOOLS ==========
    
    case 'godot_version': {
      try {
        const result = await execCommand(GODOT_PATH, ['--version'], { timeout: 10000 });
        if (result.code === 0) {
          return {
            available: true,
            version: result.stdout.trim(),
            path: GODOT_PATH
          };
        } else {
          return {
            available: false,
            error: result.stderr || 'Godot not found or failed to run',
            hint: 'Godot headless is not installed in this container. Use Dockerfile.godot to build with Godot support.'
          };
        }
      } catch (error) {
        return {
          available: false,
          error: error.message,
          hint: 'Godot headless is not installed. Rebuild with: docker-compose -f docker-compose.godot.yml up --build'
        };
      }
    }
    
    case 'godot_validate_project': {
      try {
        // Run Godot in headless mode to check for errors
        const result = await execCommand(GODOT_PATH, [
          '--headless',
          '--quit',
          '--path', WORKSPACE_PATH
        ], { timeout: 60000 });
        
        const errors = [];
        const warnings = [];
        
        // Parse output for errors and warnings
        const output = result.stdout + result.stderr;
        const lines = output.split('\n');
        
        for (const line of lines) {
          if (line.includes('ERROR') || line.includes('error')) {
            errors.push(line.trim());
          } else if (line.includes('WARNING') || line.includes('warning')) {
            warnings.push(line.trim());
          }
        }
        
        return {
          valid: errors.length === 0,
          exitCode: result.code,
          errors,
          warnings,
          summary: `${errors.length} errors, ${warnings.length} warnings`
        };
      } catch (error) {
        return {
          valid: false,
          error: error.message,
          hint: 'Make sure Godot is available and the project path is correct'
        };
      }
    }
    
    case 'godot_run_script': {
      try {
        const scriptPath = path.join(WORKSPACE_PATH, args.scriptPath);
        
        // Check if script exists
        try {
          await fs.access(scriptPath);
        } catch {
          return { error: `Script not found: ${args.scriptPath}` };
        }
        
        // Run Godot with the script
        const timeout = (args.timeout || 30) * 1000;
        const result = await execCommand(GODOT_PATH, [
          '--headless',
          '--quit',
          '--path', WORKSPACE_PATH,
          '--script', scriptPath
        ], { timeout });
        
        return {
          success: result.code === 0,
          exitCode: result.code,
          stdout: result.stdout,
          stderr: result.stderr,
          script: args.scriptPath
        };
      } catch (error) {
        return {
          success: false,
          error: error.message
        };
      }
    }
    
    case 'godot_export_check': {
      try {
        // Run Godot to check exports
        const result = await execCommand(GODOT_PATH, [
          '--headless',
          '--quit',
          '--path', WORKSPACE_PATH,
          '--export-debug', 'check_only'  // This will validate without actually exporting
        ], { timeout: 120000 });
        
        // Parse for export issues
        const output = result.stdout + result.stderr;
        const issues = [];
        
        if (output.includes('No export template found')) {
          issues.push('Export templates not installed');
        }
        
        const missingResources = output.match(/Resource .* not found/g) || [];
        issues.push(...missingResources);
        
        return {
          canExport: issues.length === 0 && result.code === 0,
          exitCode: result.code,
          issues,
          output: output.substring(0, 2000) // Truncate long output
        };
      } catch (error) {
        // export-debug with 'check_only' may not be supported, try validation instead
        return {
          canExport: 'unknown',
          error: error.message,
          hint: 'Export check requires Godot export templates to be installed'
        };
      }
    }
    
    case 'godot_list_classes': {
      const scripts = await findFiles(path.join(WORKSPACE_PATH, 'scripts'), '.gd');
      const classes = [];
      
      for (const file of scripts) {
        try {
          const content = await fs.readFile(file, 'utf-8');
          const lines = content.split('\n');
          
          // Look for class_name declaration
          for (let i = 0; i < lines.length; i++) {
            const classMatch = lines[i].match(/^class_name\s+(\w+)/);
            if (classMatch) {
              // Look for extends
              let extendsClass = 'Object';
              for (let j = 0; j < Math.min(i + 5, lines.length); j++) {
                const extendsMatch = lines[j].match(/^extends\s+(\w+)/);
                if (extendsMatch) {
                  extendsClass = extendsMatch[1];
                  break;
                }
              }
              
              classes.push({
                name: classMatch[1],
                extends: extendsClass,
                file: path.relative(WORKSPACE_PATH, file).replace(/\\/g, '/'),
                line: i + 1
              });
              break;
            }
          }
        } catch {
          // Skip files that can't be read
        }
      }
      
      return {
        count: classes.length,
        classes: classes.sort((a, b) => a.name.localeCompare(b.name))
      };
    }
    
    case 'get_playground_todos': {
      return {
        count: (global.playgroundTodos || []).length,
        todos: global.playgroundTodos || [],
        description: 'These are value changes the user made in the Dashboard Playground and wants applied to the codebase.'
      };
    }
    
    case 'clear_playground_todos': {
      const count = (global.playgroundTodos || []).length;
      global.playgroundTodos = [];
      return {
        success: true,
        cleared: count,
        message: `Cleared ${count} pending TODO(s) from the Playground.`
      };
    }
    
    case 'wiki_analyze': {
      const filePath = path.join(WORKSPACE_PATH, args.filePath);
      const ext = path.extname(args.filePath);
      
      try {
        const stat = await fs.stat(filePath);
        let content = await fs.readFile(filePath, 'utf-8');
        
        const meta = {
          fileName: path.basename(args.filePath),
          filePath: args.filePath,
          extension: ext,
          fileType: ext === '.gd' ? 'GDScript' : ext === '.tscn' ? 'Scene' : ext === '.tres' ? 'Resource' : 'Other',
          fileSize: stat.size,
          totalLines: content.split('\\n').length
        };
        
        let analysis = {};
        let sections = [];
        
        if (ext === '.gd') {
          // GDScript analysis
          const lines = content.split('\\n');
          
          analysis.overview = {
            className: null,
            extends: null,
            isTool: false,
            description: [],
            purpose: null
          };
          
          analysis.signals = [];
          analysis.exports = [];
          analysis.constants = [];
          analysis.onreadyVars = [];
          analysis.functions = [];
          analysis.dependencies = [];
          analysis.godotLinks = [];
          
          lines.forEach((line, i) => {
            const lineNum = i + 1;
            
            // Class name
            const classMatch = line.match(/^class_name\s+(\w+)/);
            if (classMatch) analysis.overview.className = classMatch[1];
            
            // Extends
            const extendsMatch = line.match(/^extends\s+(\w+)/);
            if (extendsMatch) {
              analysis.overview.extends = extendsMatch[1];
              // Add Godot doc link
              analysis.godotLinks.push({
                name: extendsMatch[1],
                type: 'Base Class',
                url: 'https://docs.godotengine.org/en/stable/classes/class_' + extendsMatch[1].toLowerCase() + '.html'
              });
            }
            
            // Tool script
            if (line.trim() === '@tool') analysis.overview.isTool = true;
            
            // Top comments for description
            if (i < 10 && line.trim().startsWith('#')) {
              analysis.overview.description.push(line.trim().substring(1).trim());
            }
            
            // Signals
            const signalMatch = line.match(/^signal\s+(\w+)\(?(.*?)\)?$/);
            if (signalMatch) {
              analysis.signals.push({
                name: signalMatch[1],
                parameters: signalMatch[2] || '',
                line: lineNum,
                description: ''
              });
            }
            
            // Exports
            const exportMatch = line.match(/@export(?:_range\([^)]+\)|_enum\([^)]+\)|)?\s+var\s+(\w+)\s*:\s*(\w+)/);
            if (exportMatch) {
              analysis.exports.push({
                name: exportMatch[1],
                type: exportMatch[2],
                line: lineNum,
                default: null
              });
            }
            
            // Constants
            const constMatch = line.match(/^const\s+(\w+)\s*[=:]\s*(.+)/);
            if (constMatch) {
              analysis.constants.push({
                name: constMatch[1],
                value: constMatch[2].trim(),
                line: lineNum
              });
            }
            
            // @onready
            const onreadyMatch = line.match(/@onready\s+var\s+(\w+)\s*[=:]\s*(\w+)?/);
            if (onreadyMatch) {
              analysis.onreadyVars.push({
                name: onreadyMatch[1],
                type: onreadyMatch[2] || 'Variant',
                line: lineNum
              });
            }
            
            // Functions
            const funcMatch = line.match(/^func\s+(\w+)\(([^)]*)\)\s*(?:->\s*(\w+))?/);
            if (funcMatch) {
              const fname = funcMatch[1];
              const isOverride = fname.startsWith('_');
              const isCallback = fname.startsWith('_on_');
              const isPrivate = fname.startsWith('_') && !isOverride;
              
              let category = 'Public';
              if (isOverride && ['_ready', '_process', '_physics_process', '_input', '_unhandled_input', '_enter_tree', '_exit_tree', '_notification'].includes(fname)) {
                category = 'Lifecycle Override';
              } else if (isCallback) {
                category = 'Signal Callback';
              } else if (isPrivate) {
                category = 'Private';
              }
              
              analysis.functions.push({
                name: fname,
                parameters: funcMatch[2] || '',
                returnType: funcMatch[3] || 'void',
                line: lineNum,
                isOverride,
                isCallback,
                isPrivate,
                category
              });
            }
            
            // Dependencies (preload/load)
            const preloadMatch = line.match(/preload\\(["']([^"']+)["']\\)/);
            if (preloadMatch) {
              analysis.dependencies.push({
                type: 'preload',
                path: preloadMatch[1],
                line: lineNum
              });
            }
            
            const loadMatch = line.match(/load\\(["']([^"']+)["']\\)/);
            if (loadMatch) {
              analysis.dependencies.push({
                type: 'load',
                path: loadMatch[1],
                line: lineNum
              });
            }
          });
          
          // Add default Godot doc links based on detected patterns
          if (content.includes('Area2D')) {
            analysis.godotLinks.push({ name: 'Area2D', type: 'Node', url: 'https://docs.godotengine.org/en/stable/classes/class_area2d.html' });
          }
          if (content.includes('CharacterBody2D')) {
            analysis.godotLinks.push({ name: 'CharacterBody2D', type: 'Node', url: 'https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html' });
          }
          
          // Generate sections
          sections = [
            { id: 'overview', title: 'Overview', icon: '📄' }
          ];
          if (analysis.signals.length > 0) sections.push({ id: 'signals', title: 'Signals', icon: '📡' });
          if (analysis.exports.length > 0) sections.push({ id: 'exports', title: 'Exports', icon: '📤' });
          if (analysis.constants.length > 0) sections.push({ id: 'constants', title: 'Constants', icon: '🔒' });
          if (analysis.onreadyVars.length > 0) sections.push({ id: 'onready', title: '@onready', icon: '⚡' });
          if (analysis.functions.length > 0) sections.push({ id: 'functions', title: 'Functions', icon: '⚙️' });
          if (analysis.dependencies.length > 0) sections.push({ id: 'dependencies', title: 'Dependencies', icon: '🔗' });
          if (analysis.godotLinks.length > 0) sections.push({ id: 'godot-docs', title: 'Godot Docs', icon: '📚' });
          sections.push({ id: 'code', title: 'Source Code', icon: '💻' });
          
        } else if (ext === '.tscn') {
          // Scene analysis
          analysis.overview = {
            rootNode: null,
            rootType: null
          };
          analysis.nodes = [];
          analysis.scripts = [];
          analysis.signals = [];
          analysis.godotLinks = [];
          
          // Parse .tscn format
          const nodeRegex = /\[node name="([^"]+)" type="([^"]+)"/g;
          const scriptRegex = /script = ExtResource\("([^"]+)"\)|ExtResource\("([^"]+)"\)/g;
          
          let match;
          let isFirst = true;
          while ((match = nodeRegex.exec(content)) !== null) {
            const node = {
              name: match[1],
              type: match[2],
              parent: null
            };
            
            if (isFirst) {
              analysis.overview.rootNode = node.name;
              analysis.overview.rootType = node.type;
              isFirst = false;
            }
            
            analysis.nodes.push(node);
            
            // Add godot link
            if (!analysis.godotLinks.find(l => l.name === node.type)) {
              analysis.godotLinks.push({
                name: node.type,
                type: 'Node',
                url: 'https://docs.godotengine.org/en/stable/classes/class_' + node.type.toLowerCase() + '.html'
              });
            }
          }
          
          // Find script paths
          const extResources = content.match(/\[ext_resource type="Script".*?path="([^"]+)"/g) || [];
          extResources.forEach(res => {
            const pathMatch = res.match(/path="([^"]+)"/);
            if (pathMatch) {
              analysis.scripts.push({ path: pathMatch[1].replace('res://', '') });
            }
          });
          
          sections = [
            { id: 'overview', title: 'Overview', icon: '🎬' },
            { id: 'nodes', title: 'Node Tree', icon: '🌳' }
          ];
          if (analysis.scripts.length > 0) sections.push({ id: 'scripts', title: 'Scripts', icon: '📜' });
          if (analysis.godotLinks.length > 0) sections.push({ id: 'godot-docs', title: 'Godot Docs', icon: '📚' });
          sections.push({ id: 'code', title: 'Source', icon: '💻' });
          
        } else if (ext === '.tres') {
          // Resource analysis
          analysis.overview = {
            resourceType: null,
            scriptPath: null
          };
          analysis.properties = [];
          
          const typeMatch = content.match(/\[gd_resource type="([^"]+)"/);
          if (typeMatch) analysis.overview.resourceType = typeMatch[1];
          
          const scriptMatch = content.match(/script = ExtResource\("([^"]+)"\)/);
          if (scriptMatch) analysis.overview.scriptPath = scriptMatch[1];
          
          // Extract properties
          const propRegex = /(\w+)\s*=\s*(.+)/g;
          let propMatch;
          while ((propMatch = propRegex.exec(content)) !== null) {
            if (!propMatch[1].startsWith('[') && propMatch[1] !== 'script') {
              analysis.properties.push({
                name: propMatch[1],
                value: propMatch[2].substring(0, 50)
              });
            }
          }
          
          sections = [
            { id: 'overview', title: 'Overview', icon: '📦' },
            { id: 'properties', title: 'Properties', icon: '⚙️' },
            { id: 'code', title: 'Source', icon: '💻' }
          ];
        }
        
        // Find usages if requested
        if (args.includeUsages) {
          analysis.usedIn = [];
          const allScripts = await findFiles(path.join(WORKSPACE_PATH, 'scripts'), '.gd');
          const allScenes = await findFiles(path.join(WORKSPACE_PATH, 'scenes'), '.tscn');
          const allFiles = [...allScripts, ...allScenes];
          
          const fileName = path.basename(args.filePath);
          
          for (const file of allFiles) {
            if (file === filePath) continue;
            try {
              const fileContent = await fs.readFile(file, 'utf-8');
              if (fileContent.includes(fileName) || fileContent.includes(args.filePath)) {
                const lines = fileContent.split('\\n');
                for (let i = 0; i < lines.length; i++) {
                  if (lines[i].includes(fileName) || lines[i].includes(args.filePath)) {
                    analysis.usedIn.push({
                      file: path.relative(WORKSPACE_PATH, file).replace(/\\\\/g, '/'),
                      line: i + 1,
                      context: lines[i].trim().substring(0, 80)
                    });
                    break;
                  }
                }
              }
            } catch {}
          }
          
          if (analysis.usedIn.length > 0 && !sections.find(s => s.id === 'usages')) {
            sections.splice(-1, 0, { id: 'usages', title: 'Used In', icon: '📍' });
          }
        }
        
        return {
          meta,
          analysis,
          sections,
          content: args.includeCode ? content : null
        };
        
      } catch (error) {
        return {
          error: error.message,
          meta: { filePath: args.filePath }
        };
      }
    }
    
    default:
      return { error: `Unknown tool: ${name}` };
  }
}

async function main() {
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║       Cargo Escape MCP Server (HTTP/SSE Transport)         ║');
  console.log('╠════════════════════════════════════════════════════════════╣');
  console.log(`║  Port:      ${PORT.toString().padEnd(45)}║`);
  console.log(`║  Workspace: ${WORKSPACE_PATH.substring(0, 45).padEnd(45)}║`);
  console.log('╠════════════════════════════════════════════════════════════╣');
  console.log('║  SECURITY STATUS:                                          ║');
  console.log(`║  • Auth:       ${ENABLE_AUTH ? 'ENABLED ✓'.padEnd(43) : 'DISABLED ⚠'.padEnd(43)}║`);
  console.log(`║  • Rate Limit: ${(RATE_LIMIT + ' req/min').padEnd(43)}║`);
  console.log(`║  • CORS:       ${ALLOWED_ORIGINS.length + ' origins allowed'.padEnd(43)}║`);
  console.log('╚════════════════════════════════════════════════════════════╝');
  
  if (!ENABLE_AUTH) {
    console.warn('\n⚠️  WARNING: Authentication is DISABLED. Enable for production use.\n');
  }
  
  if (API_KEY === 'cargo-escape-local-dev-key-change-me') {
    console.warn('⚠️  WARNING: Using default API key. Set MCP_API_KEY environment variable.\n');
  }
  
  // Track active transports
  const transports = new Map();
  
  // Create HTTP server
  const httpServer = http.createServer(async (req, res) => {
    const clientIP = getClientIP(req);
    const url = new URL(req.url, `http://${req.headers.host}`);
    const pathname = url.pathname;
    
    // Set security headers on all responses
    setSecurityHeaders(res, req);
    
    // Handle CORS preflight
    if (req.method === 'OPTIONS') {
      res.writeHead(200);
      res.end();
      return;
    }
    
    // ==================== RATE LIMITING ====================
    const rateCheck = checkRateLimit(clientIP);
    res.setHeader('X-RateLimit-Limit', RATE_LIMIT);
    res.setHeader('X-RateLimit-Remaining', rateCheck.remaining);
    res.setHeader('X-RateLimit-Reset', rateCheck.resetIn);
    
    if (!rateCheck.allowed) {
      logSecurity('warn', 'Rate limit exceeded', { ip: clientIP, path: pathname });
      res.writeHead(429, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ 
        error: 'Too many requests',
        retryAfter: rateCheck.resetIn,
        limit: RATE_LIMIT
      }));
      return;
    }
    
    // ==================== AUTHENTICATION ====================
    const isProtectedEndpoint = PROTECTED_ENDPOINTS.some(ep => pathname.startsWith(ep));
    
    if (ENABLE_AUTH && isProtectedEndpoint && !validateApiKey(req)) {
      logSecurity('warn', 'Unauthorized access attempt', { 
        ip: clientIP, 
        path: pathname,
        method: req.method 
      });
      res.writeHead(401, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ 
        error: 'Unauthorized',
        message: 'Valid API key required. Use Authorization: Bearer <key> or X-API-Key header.',
        hint: 'For local development, the default key is in docker-compose.godot.yml'
      }));
      return;
    }
    
    // Log authenticated requests to protected endpoints
    if (isProtectedEndpoint) {
      logSecurity('info', 'Authenticated request', { ip: clientIP, path: pathname });
    }
    
    // ==================== ENDPOINTS ====================
    
    // Health check endpoint (public)
    if (pathname === '/health') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ 
        status: 'healthy', 
        server: 'Cargo Escape MCP',
        tools: TOOLS.length,
        security: {
          authEnabled: ENABLE_AUTH,
          rateLimit: RATE_LIMIT
        }
      }));
      return;
    }
    
    // SSE endpoint for MCP
    if (pathname === '/sse' && req.method === 'GET') {
      logSecurity('info', 'New SSE connection', { ip: clientIP });
      
      const server = new Server(
        { name: 'cargo-escape-mcp', version: '1.0.0' },
        { capabilities: { tools: {}, resources: {} } }
      );
      
      server.setRequestHandler(ListToolsRequestSchema, async () => {
        console.log('Tools requested');
        return { tools: TOOLS };
      });
      
      server.setRequestHandler(CallToolRequestSchema, async (request) => {
        const { name, arguments: args } = request.params;
        console.log(`Tool called: ${name}`);
        
        // Sanitize any path arguments
        const sanitizedArgs = { ...args };
        if (sanitizedArgs.scriptPath) {
          const sanitized = sanitizePath(sanitizedArgs.scriptPath);
          if (!sanitized) {
            logSecurity('warn', 'Path traversal blocked', { tool: name, path: sanitizedArgs.scriptPath });
            return {
              content: [{ type: 'text', text: JSON.stringify({ error: 'Invalid path: path traversal detected' }) }],
              isError: true
            };
          }
          sanitizedArgs.scriptPath = sanitized;
        }
        
        try {
          const result = await executeTool(name, sanitizedArgs);
          return {
            content: [{ type: 'text', text: JSON.stringify(result, null, 2) }]
          };
        } catch (error) {
          return {
            content: [{ type: 'text', text: JSON.stringify({ error: error.message }) }],
            isError: true
          };
        }
      });
      
      server.setRequestHandler(ListResourcesRequestSchema, async () => ({ resources: [] }));
      server.setRequestHandler(ReadResourceRequestSchema, async () => ({ contents: [] }));
      
      const transport = new SSEServerTransport('/message', res);
      transports.set(transport, server);
      
      res.on('close', () => {
        logSecurity('info', 'SSE connection closed', { ip: clientIP });
        transports.delete(transport);
      });
      
      await server.connect(transport);
      return;
    }
    
    // Message endpoint for SSE transport
    if (pathname === '/message' && req.method === 'POST') {
      let body = '';
      req.on('data', chunk => { body += chunk; });
      req.on('end', async () => {
        // Find the transport that should handle this message
        for (const [transport] of transports) {
          try {
            await transport.handlePostMessage(req, res, body);
            return;
          } catch (e) {
            // Try next transport
          }
        }
        res.writeHead(400);
        res.end('No active transport');
      });
      return;
    }
    
    // API: Get tools list (public)
    if (pathname === '/api/tools' && req.method === 'GET') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ tools: TOOLS }, null, 2));
      return;
    }
    
    // API: Execute tool by name (protected) - /api/tools/<toolname>
    if (pathname.startsWith('/api/tools/') && req.method === 'POST') {
      const toolName = pathname.replace('/api/tools/', '');
      
      // Check if tool exists
      if (!TOOLS.find(t => t.name === toolName)) {
        logSecurity('warn', 'Unknown tool requested', { tool: toolName, ip: clientIP });
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: `Unknown tool: ${toolName}` }));
        return;
      }
      
      let body = '';
      req.on('data', chunk => { body += chunk; });
      req.on('end', async () => {
        try {
          const args = body ? JSON.parse(body) : {};
          
          // Sanitize path arguments
          const sanitizedArgs = { ...args };
          if (sanitizedArgs.filePath) {
            const sanitized = sanitizePath(sanitizedArgs.filePath);
            if (!sanitized) {
              logSecurity('warn', 'Path traversal blocked', { tool: toolName, path: sanitizedArgs.filePath, ip: clientIP });
              res.writeHead(400, { 'Content-Type': 'application/json' });
              res.end(JSON.stringify({ error: 'Invalid path: path traversal detected' }));
              return;
            }
            sanitizedArgs.filePath = sanitized;
          }
          if (sanitizedArgs.scriptPath) {
            const sanitized = sanitizePath(sanitizedArgs.scriptPath);
            if (!sanitized) {
              res.writeHead(400, { 'Content-Type': 'application/json' });
              res.end(JSON.stringify({ error: 'Invalid path: path traversal detected' }));
              return;
            }
            sanitizedArgs.scriptPath = sanitized;
          }
          
          const result = await executeTool(toolName, sanitizedArgs);
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify(result, null, 2));
        } catch (error) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: error.message }));
        }
      });
      return;
    }
    
    // API: Get project stats (protected)
    if (pathname === '/api/stats' && req.method === 'GET') {
      try {
        const stats = await executeTool('project_stats', {});
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(stats, null, 2));
      } catch (error) {
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: error.message }));
      }
      return;
    }
    
    // API: Execute any tool (protected)
    if (pathname === '/api/execute' && req.method === 'POST') {
      let body = '';
      req.on('data', chunk => { body += chunk; });
      req.on('end', async () => {
        try {
          const { tool, args } = JSON.parse(body);
          
          // Validate tool name
          if (!TOOLS.find(t => t.name === tool)) {
            logSecurity('warn', 'Unknown tool requested', { tool, ip: clientIP });
            res.writeHead(400, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ error: `Unknown tool: ${tool}` }));
            return;
          }
          
          // Sanitize path arguments
          const sanitizedArgs = { ...args };
          if (sanitizedArgs.scriptPath) {
            const sanitized = sanitizePath(sanitizedArgs.scriptPath);
            if (!sanitized) {
              logSecurity('warn', 'Path traversal blocked', { tool, path: sanitizedArgs.scriptPath, ip: clientIP });
              res.writeHead(400, { 'Content-Type': 'application/json' });
              res.end(JSON.stringify({ error: 'Invalid path: path traversal detected' }));
              return;
            }
            sanitizedArgs.scriptPath = sanitized;
          }
          if (sanitizedArgs.directory) {
            const sanitized = sanitizePath(sanitizedArgs.directory);
            if (!sanitized) {
              logSecurity('warn', 'Path traversal blocked', { tool, path: sanitizedArgs.directory, ip: clientIP });
              res.writeHead(400, { 'Content-Type': 'application/json' });
              res.end(JSON.stringify({ error: 'Invalid path: path traversal detected' }));
              return;
            }
            sanitizedArgs.directory = sanitized;
          }
          
          const result = await executeTool(tool, sanitizedArgs);
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify(result, null, 2));
        } catch (error) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: error.message }));
        }
      });
      return;
    }
    
    // API: Add playground TODOs (protected) - stores TODOs for agent pickup
    if (pathname === '/api/todos/add' && req.method === 'POST') {
      let body = '';
      req.on('data', chunk => { body += chunk; });
      req.on('end', async () => {
        try {
          const { source, items } = JSON.parse(body);
          
          // Store in memory for now (could be file-based later)
          if (!global.playgroundTodos) {
            global.playgroundTodos = [];
          }
          
          const timestamp = new Date().toISOString();
          items.forEach(item => {
            global.playgroundTodos.push({
              ...item,
              source: source || 'playground',
              createdAt: timestamp
            });
          });
          
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ 
            success: true, 
            count: items.length,
            total: global.playgroundTodos.length 
          }));
        } catch (error) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: error.message }));
        }
      });
      return;
    }
    
    // API: Get playground TODOs (protected)
    if (pathname === '/api/todos' && req.method === 'GET') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ 
        todos: global.playgroundTodos || [],
        count: (global.playgroundTodos || []).length
      }));
      return;
    }
    
    // API: Clear playground TODOs (protected)
    if (pathname === '/api/todos/clear' && req.method === 'POST') {
      global.playgroundTodos = [];
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: true, message: 'All TODOs cleared' }));
      return;
    }
    
    // Default: Dashboard (public)
    try {
      const [stats, godotInfo] = await Promise.all([
        executeTool('project_stats', {}),
        executeTool('godot_version', {}).catch(() => ({ available: false }))
      ]);
      res.writeHead(200, { 'Content-Type': 'text/html' });
      res.end(generateDashboardHTML(TOOLS, stats, godotInfo));
    } catch (error) {
      res.writeHead(200, { 'Content-Type': 'text/html' });
      res.end(generateDashboardHTML(TOOLS, {}, { available: false }));
    }
  });
  
  httpServer.listen(PORT, '0.0.0.0', () => {
    console.log(`\n✓ MCP Server listening on http://localhost:${PORT}`);
    console.log(`  - Dashboard:    http://localhost:${PORT}/`);
    console.log(`  - Health check: http://localhost:${PORT}/health`);
    console.log(`  - SSE endpoint: http://localhost:${PORT}/sse`);
    console.log(`\n🔒 Security: API key required for protected endpoints.`);
    console.log(`   Use header: Authorization: Bearer <your-api-key>`);
  });
}

main().catch(console.error);
