#!/usr/bin/env node

/**
 * Cargo Escape MCP Server
 * 
 * This is a custom MCP (Model Context Protocol) server that provides tools
 * to AI assistants like Claude. MCP servers expose "tools" that the AI can
 * call to perform actions or retrieve information.
 * 
 * Architecture:
 * - This server runs locally (or in Docker)
 * - VS Code connects to it via stdio or HTTP
 * - Claude (running on Anthropic's servers) sees the tools and can call them
 * - Results are returned to Claude to help answer your questions
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  ListResourcesRequestSchema,
  ReadResourceRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import fs from 'fs/promises';
import path from 'path';

// Get workspace path from environment or use default
const WORKSPACE_PATH = process.env.WORKSPACE_PATH || '/workspace';

/**
 * Define the tools this MCP server provides.
 * Each tool has a name, description, and input schema.
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
  }
];

/**
 * Recursively find files matching a pattern
 */
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

/**
 * Count lines in a file
 */
async function countLines(filePath) {
  try {
    const content = await fs.readFile(filePath, 'utf-8');
    return content.split('\n').length;
  } catch {
    return 0;
  }
}

/**
 * Search for pattern in file
 */
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

/**
 * Handle tool execution
 */
async function executeTool(name, args) {
  switch (name) {
    case 'echo_test': {
      return {
        success: true,
        message: `Echo from MCP server: ${args.message}`,
        timestamp: new Date().toISOString(),
        serverInfo: 'Cargo Escape MCP Server v1.0.0'
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
          // Find preload statements
          const preloadMatch = line.match(/preload\s*\(\s*["']([^"']+)["']\s*\)/);
          if (preloadMatch) {
            preloads.push({ line: index + 1, path: preloadMatch[1] });
          }
          
          // Find load statements
          const loadMatch = line.match(/load\s*\(\s*["']([^"']+)["']\s*\)/);
          if (loadMatch) {
            loads.push({ line: index + 1, path: loadMatch[1] });
          }
          
          // Find signal definitions
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
        scripts: {
          count: scripts.length,
          totalLines
        },
        scenes: {
          count: scenes.length
        },
        resources: {
          count: resources.length
        },
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
    
    default:
      return { error: `Unknown tool: ${name}` };
  }
}

/**
 * Create and run the MCP server
 */
async function main() {
  console.error('Starting Cargo Escape MCP Server...');
  console.error(`Workspace path: ${WORKSPACE_PATH}`);
  
  const server = new Server(
    {
      name: 'cargo-escape-mcp',
      version: '1.0.0',
    },
    {
      capabilities: {
        tools: {},
        resources: {},
      },
    }
  );

  // Handle list tools request
  server.setRequestHandler(ListToolsRequestSchema, async () => {
    console.error('Tools requested by client');
    return { tools: TOOLS };
  });

  // Handle tool execution
  server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args } = request.params;
    console.error(`Tool called: ${name}`, args);
    
    try {
      const result = await executeTool(name, args || {});
      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify(result, null, 2)
          }
        ]
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify({ error: error.message })
          }
        ],
        isError: true
      };
    }
  });

  // Handle list resources request
  server.setRequestHandler(ListResourcesRequestSchema, async () => {
    return { resources: [] };
  });

  // Handle read resource request
  server.setRequestHandler(ReadResourceRequestSchema, async () => {
    return { contents: [] };
  });

  // Connect via stdio transport
  const transport = new StdioServerTransport();
  await server.connect(transport);
  
  console.error('MCP Server running and connected via stdio');
}

main().catch(console.error);
