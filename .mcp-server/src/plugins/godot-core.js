/**
 * Core Godot Tools Plugin
 * Provides essential Godot project analysis and management tools
 */

import fs from 'fs/promises';
import path from 'path';
import { spawn } from 'child_process';

const WORKSPACE = process.env.WORKSPACE_PATH || '/workspace';
const GODOT_PATH = process.env.GODOT_PATH || 'godot';

// ==================== UTILITY FUNCTIONS ====================

async function findFiles(dir, extension, results = []) {
  try {
    const entries = await fs.readdir(dir, { withFileTypes: true });
    
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      
      if (entry.isDirectory() && !entry.name.startsWith('.') && entry.name !== 'addons') {
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

async function readFileContent(filePath) {
  try {
    return await fs.readFile(filePath, 'utf-8');
  } catch {
    return null;
  }
}

async function countLines(filePath) {
  const content = await readFileContent(filePath);
  return content ? content.split('\n').length : 0;
}

function execCommand(command, args, options = {}) {
  return new Promise((resolve, reject) => {
    const timeout = options.timeout || 30000;
    const proc = spawn(command, args, {
      cwd: options.cwd || WORKSPACE,
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

// ==================== TOOL DEFINITIONS ====================

const tools = [
  // Basic listing tools
  {
    definition: {
      name: 'godot_list_scenes',
      description: 'List all .tscn scene files in the Godot project',
      category: 'project',
      tags: ['scenes', 'list'],
      inputSchema: {
        type: 'object',
        properties: {
          directory: {
            type: 'string',
            description: 'Subdirectory to search in (default: entire project)'
          }
        }
      }
    },
    handler: async (args) => {
      const dir = args.directory ? path.join(WORKSPACE, args.directory) : WORKSPACE;
      const files = await findFiles(dir, '.tscn');
      return {
        count: files.length,
        scenes: files.map(f => path.relative(WORKSPACE, f).replace(/\\/g, '/'))
      };
    }
  },
  
  {
    definition: {
      name: 'godot_list_scripts',
      description: 'List all .gd script files in the Godot project',
      category: 'project',
      tags: ['scripts', 'list'],
      inputSchema: {
        type: 'object',
        properties: {
          directory: {
            type: 'string',
            description: 'Subdirectory to search in (default: entire project)'
          }
        }
      }
    },
    handler: async (args) => {
      const dir = args.directory ? path.join(WORKSPACE, args.directory) : WORKSPACE;
      const files = await findFiles(dir, '.gd');
      return {
        count: files.length,
        scripts: files.map(f => path.relative(WORKSPACE, f).replace(/\\/g, '/'))
      };
    }
  },
  
  // Dependency analysis
  {
    definition: {
      name: 'godot_analyze_dependencies',
      description: 'Analyze script dependencies by finding preload/load statements',
      category: 'analysis',
      tags: ['dependencies', 'preload', 'load'],
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
    handler: async (args) => {
      const filePath = path.join(WORKSPACE, args.scriptPath);
      const content = await readFileContent(filePath);
      
      if (!content) {
        throw new Error(`Could not read file: ${args.scriptPath}`);
      }
      
      const preloads = [];
      const loads = [];
      const signals = [];
      const extendsClasses = [];
      const classNames = [];
      
      const lines = content.split('\n');
      lines.forEach((line, index) => {
        // Preload statements
        const preloadMatch = line.match(/preload\s*\(\s*["']([^"']+)["']\s*\)/);
        if (preloadMatch) {
          preloads.push({ line: index + 1, path: preloadMatch[1] });
        }
        
        // Load statements
        const loadMatch = line.match(/load\s*\(\s*["']([^"']+)["']\s*\)/);
        if (loadMatch) {
          loads.push({ line: index + 1, path: loadMatch[1] });
        }
        
        // Signal definitions
        const signalMatch = line.match(/signal\s+(\w+)/);
        if (signalMatch) {
          signals.push({ line: index + 1, name: signalMatch[1] });
        }
        
        // Extends
        const extendsMatch = line.match(/^extends\s+(\w+)/);
        if (extendsMatch) {
          extendsClasses.push(extendsMatch[1]);
        }
        
        // Class name
        const classMatch = line.match(/^class_name\s+(\w+)/);
        if (classMatch) {
          classNames.push(classMatch[1]);
        }
      });
      
      return {
        file: args.scriptPath,
        className: classNames[0] || null,
        extends: extendsClasses[0] || 'RefCounted',
        preloads,
        loads,
        signals,
        totalDependencies: preloads.length + loads.length
      };
    }
  },
  
  // Node reference finder
  {
    definition: {
      name: 'godot_find_node_references',
      description: 'Find all references to a specific node type or signal in scripts',
      category: 'search',
      tags: ['search', 'nodes', 'signals'],
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
    handler: async (args) => {
      const files = await findFiles(WORKSPACE, '.gd');
      const results = [];
      
      for (const file of files) {
        const content = await readFileContent(file);
        if (!content) continue;
        
        const lines = content.split('\n');
        const matches = [];
        
        lines.forEach((line, index) => {
          if (line.toLowerCase().includes(args.pattern.toLowerCase())) {
            matches.push({
              line: index + 1,
              content: line.trim().substring(0, 100)
            });
          }
        });
        
        if (matches.length > 0) {
          results.push({
            file: path.relative(WORKSPACE, file).replace(/\\/g, '/'),
            matches
          });
        }
      }
      
      return {
        pattern: args.pattern,
        filesMatched: results.length,
        totalMatches: results.reduce((sum, r) => sum + r.matches.length, 0),
        results
      };
    }
  },
  
  // Project statistics
  {
    definition: {
      name: 'project_stats',
      description: 'Get statistics about the Godot project',
      category: 'analysis',
      tags: ['stats', 'overview'],
      inputSchema: { type: 'object', properties: {} }
    },
    handler: async () => {
      const scripts = await findFiles(WORKSPACE, '.gd');
      const scenes = await findFiles(WORKSPACE, '.tscn');
      const resources = await findFiles(WORKSPACE, '.tres');
      const shaders = await findFiles(WORKSPACE, '.gdshader');
      
      let totalLines = 0;
      let longestScript = { path: '', lines: 0 };
      
      for (const script of scripts) {
        const lines = await countLines(script);
        totalLines += lines;
        if (lines > longestScript.lines) {
          longestScript = {
            path: path.relative(WORKSPACE, script).replace(/\\/g, '/'),
            lines
          };
        }
      }
      
      return {
        scripts: {
          count: scripts.length,
          totalLines,
          averageLines: scripts.length > 0 ? Math.round(totalLines / scripts.length) : 0,
          longestScript
        },
        scenes: { count: scenes.length },
        resources: { count: resources.length },
        shaders: { count: shaders.length },
        total: {
          files: scripts.length + scenes.length + resources.length + shaders.length,
          linesOfCode: totalLines
        }
      };
    }
  },
  
  // TODO finder
  {
    definition: {
      name: 'find_todos',
      description: 'Find all TODO, FIXME, HACK, and NOTE comments in the project',
      category: 'analysis',
      tags: ['todo', 'fixme', 'comments'],
      inputSchema: { type: 'object', properties: {} }
    },
    handler: async () => {
      const files = await findFiles(WORKSPACE, '.gd');
      const patterns = ['TODO', 'FIXME', 'HACK', 'NOTE', 'BUG', 'XXX'];
      const results = { TODO: [], FIXME: [], HACK: [], NOTE: [], BUG: [], XXX: [] };
      
      for (const file of files) {
        const content = await readFileContent(file);
        if (!content) continue;
        
        const lines = content.split('\n');
        const relativePath = path.relative(WORKSPACE, file).replace(/\\/g, '/');
        
        lines.forEach((line, index) => {
          for (const pattern of patterns) {
            if (line.includes(`# ${pattern}`) || line.includes(`#${pattern}`)) {
              results[pattern].push({
                file: relativePath,
                line: index + 1,
                content: line.trim().substring(0, 100)
              });
            }
          }
        });
      }
      
      const summary = {};
      for (const [key, items] of Object.entries(results)) {
        summary[key] = items.length;
      }
      
      return { summary, details: results };
    }
  },
  
  // Echo test
  {
    definition: {
      name: 'echo_test',
      description: 'Simple echo test to verify MCP server is working',
      category: 'utility',
      tags: ['test', 'debug'],
      inputSchema: {
        type: 'object',
        properties: {
          message: { type: 'string', description: 'Message to echo back' }
        },
        required: ['message']
      }
    },
    handler: async (args) => {
      const start = Date.now();
      return {
        success: true,
        message: `Echo: ${args.message}`,
        timestamp: new Date().toISOString(),
        latency: `${Date.now() - start}ms`,
        server: 'Cargo Escape MCP Server v2.0.0'
      };
    }
  },
  
  // Godot version
  {
    definition: {
      name: 'godot_version',
      description: 'Get the Godot version installed in the server',
      category: 'godot',
      tags: ['version', 'info'],
      inputSchema: { type: 'object', properties: {} }
    },
    handler: async () => {
      try {
        const result = await execCommand(GODOT_PATH, ['--version'], { timeout: 10000 });
        return {
          installed: true,
          version: result.stdout.trim(),
          path: GODOT_PATH
        };
      } catch (error) {
        return {
          installed: false,
          error: 'Godot not available in this container',
          hint: 'Use docker-compose.godot.yml for Godot support'
        };
      }
    }
  },
  
  // Project validation
  {
    definition: {
      name: 'godot_validate_project',
      description: 'Validate the Godot project by checking for errors',
      category: 'godot',
      tags: ['validate', 'check'],
      inputSchema: { type: 'object', properties: {} }
    },
    handler: async () => {
      try {
        const result = await execCommand(GODOT_PATH, [
          '--headless',
          '--quit',
          '--path', WORKSPACE
        ], { timeout: 60000 });
        
        const errors = [];
        const warnings = [];
        
        const lines = (result.stdout + result.stderr).split('\n');
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
          errorCount: errors.length,
          warningCount: warnings.length
        };
      } catch (error) {
        return {
          valid: false,
          error: error.message
        };
      }
    }
  },
  
  // Run script
  {
    definition: {
      name: 'godot_run_script',
      description: 'Run a GDScript file in headless mode',
      category: 'godot',
      tags: ['run', 'execute'],
      inputSchema: {
        type: 'object',
        properties: {
          scriptPath: { type: 'string', description: 'Path to the script' },
          timeout: { type: 'number', description: 'Timeout in seconds', default: 30 }
        },
        required: ['scriptPath']
      }
    },
    handler: async (args) => {
      const timeout = (args.timeout || 30) * 1000;
      
      try {
        const result = await execCommand(GODOT_PATH, [
          '--headless',
          '--path', WORKSPACE,
          '--script', args.scriptPath
        ], { timeout });
        
        return {
          success: result.code === 0,
          exitCode: result.code,
          stdout: result.stdout,
          stderr: result.stderr
        };
      } catch (error) {
        return {
          success: false,
          error: error.message
        };
      }
    }
  },
  
  // List custom classes
  {
    definition: {
      name: 'godot_list_classes',
      description: 'List all custom classes defined in the project',
      category: 'analysis',
      tags: ['classes', 'types'],
      inputSchema: { type: 'object', properties: {} }
    },
    handler: async () => {
      const files = await findFiles(WORKSPACE, '.gd');
      const classes = [];
      
      for (const file of files) {
        const content = await readFileContent(file);
        if (!content) continue;
        
        const classMatch = content.match(/^class_name\s+(\w+)/m);
        const extendsMatch = content.match(/^extends\s+(\w+)/m);
        
        if (classMatch) {
          classes.push({
            name: classMatch[1],
            extends: extendsMatch ? extendsMatch[1] : 'RefCounted',
            file: path.relative(WORKSPACE, file).replace(/\\/g, '/')
          });
        }
      }
      
      // Sort by name
      classes.sort((a, b) => a.name.localeCompare(b.name));
      
      return {
        count: classes.length,
        classes
      };
    }
  }
];

// ==================== PLUGIN EXPORT ====================

export function register(pluginManager) {
  pluginManager.registerTools(tools);
}

export default { register };
