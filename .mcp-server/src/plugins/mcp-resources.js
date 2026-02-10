/**
 * MCP Resources Plugin
 * Provides resources for LLMs to access project context
 */

import fs from 'fs/promises';
import path from 'path';

const WORKSPACE = process.env.WORKSPACE_PATH || '/workspace';

// ==================== RESOURCE DEFINITIONS ====================

const resources = [
  // Project Structure Resource
  {
    uri: 'project://structure',
    name: 'Project Structure',
    description: 'Overview of the project directory structure',
    mimeType: 'application/json',
    handler: async () => {
      async function getStructure(dir, depth = 0, maxDepth = 3) {
        if (depth > maxDepth) return null;
        
        try {
          const entries = await fs.readdir(dir, { withFileTypes: true });
          const structure = {};
          
          for (const entry of entries) {
            if (entry.name.startsWith('.') && entry.name !== '.mcp-server') continue;
            if (entry.name === 'node_modules' || entry.name === '.godot') continue;
            
            if (entry.isDirectory()) {
              const subStructure = await getStructure(
                path.join(dir, entry.name),
                depth + 1,
                maxDepth
              );
              structure[entry.name + '/'] = subStructure || '...';
            } else {
              structure[entry.name] = null;
            }
          }
          
          return structure;
        } catch {
          return null;
        }
      }
      
      const structure = await getStructure(WORKSPACE);
      return JSON.stringify(structure, null, 2);
    }
  },
  
  // Autoloads Resource
  {
    uri: 'godot://autoloads',
    name: 'Godot Autoloads',
    description: 'List of all autoload singletons in the project',
    mimeType: 'application/json',
    handler: async () => {
      const projectPath = path.join(WORKSPACE, 'project.godot');
      const content = await fs.readFile(projectPath, 'utf-8');
      
      const autoloads = [];
      const autoloadSection = content.split('[autoload]')[1]?.split('[')[0];
      
      if (autoloadSection) {
        const lines = autoloadSection.split('\n');
        for (const line of lines) {
          const match = line.match(/^(\w+)="?\*?res:\/\/([^"]+)"?/);
          if (match) {
            autoloads.push({
              name: match[1],
              path: match[2]
            });
          }
        }
      }
      
      return JSON.stringify({ autoloads }, null, 2);
    }
  },
  
  // Signals Reference Resource
  {
    uri: 'godot://signals',
    name: 'Project Signals',
    description: 'All signals defined in the project',
    mimeType: 'application/json',
    handler: async () => {
      const scriptsDir = path.join(WORKSPACE, 'scripts');
      const signals = [];
      
      async function findSignals(dir) {
        try {
          const entries = await fs.readdir(dir, { withFileTypes: true });
          
          for (const entry of entries) {
            const fullPath = path.join(dir, entry.name);
            
            if (entry.isDirectory()) {
              await findSignals(fullPath);
            } else if (entry.name.endsWith('.gd')) {
              const content = await fs.readFile(fullPath, 'utf-8');
              const relativePath = path.relative(WORKSPACE, fullPath).replace(/\\/g, '/');
              
              const signalRegex = /^signal\s+(\w+)\s*(\([^)]*\))?/gm;
              let match;
              
              while ((match = signalRegex.exec(content)) !== null) {
                signals.push({
                  name: match[1],
                  params: match[2] || '()',
                  file: relativePath
                });
              }
            }
          }
        } catch {}
      }
      
      await findSignals(scriptsDir);
      return JSON.stringify({ count: signals.length, signals }, null, 2);
    }
  },
  
  // Documentation Index Resource
  {
    uri: 'project://docs',
    name: 'Documentation Index',
    description: 'List of all markdown documentation files',
    mimeType: 'application/json',
    handler: async () => {
      const docs = [];
      
      try {
        const entries = await fs.readdir(WORKSPACE, { withFileTypes: true });
        
        for (const entry of entries) {
          if (entry.isFile() && entry.name.endsWith('.md')) {
            const content = await fs.readFile(path.join(WORKSPACE, entry.name), 'utf-8');
            const firstLine = content.split('\n')[0].replace(/^#\s*/, '').trim();
            
            docs.push({
              file: entry.name,
              title: firstLine || entry.name
            });
          }
        }
      } catch {}
      
      return JSON.stringify({ count: docs.length, documents: docs }, null, 2);
    }
  },
  
  // Scenes Index Resource
  {
    uri: 'godot://scenes',
    name: 'Scenes Index',
    description: 'All scene files in the project',
    mimeType: 'application/json',
    handler: async () => {
      const scenes = [];
      
      async function findScenes(dir) {
        try {
          const entries = await fs.readdir(dir, { withFileTypes: true });
          
          for (const entry of entries) {
            const fullPath = path.join(dir, entry.name);
            
            if (entry.isDirectory() && !entry.name.startsWith('.')) {
              await findScenes(fullPath);
            } else if (entry.name.endsWith('.tscn')) {
              const relativePath = path.relative(WORKSPACE, fullPath).replace(/\\/g, '/');
              scenes.push(relativePath);
            }
          }
        } catch {}
      }
      
      await findScenes(WORKSPACE);
      return JSON.stringify({ count: scenes.length, scenes }, null, 2);
    }
  },
  
  // Git Info Resource
  {
    uri: 'git://info',
    name: 'Git Repository Info',
    description: 'Current git repository information',
    mimeType: 'application/json',
    handler: async () => {
      const { exec } = await import('child_process');
      const { promisify } = await import('util');
      const execAsync = promisify(exec);
      
      try {
        const [branch, remote, status] = await Promise.all([
          execAsync('git branch --show-current', { cwd: WORKSPACE }),
          execAsync('git remote get-url origin', { cwd: WORKSPACE }).catch(() => ({ stdout: '' })),
          execAsync('git status --porcelain', { cwd: WORKSPACE })
        ]);
        
        return JSON.stringify({
          branch: branch.stdout.trim(),
          remote: remote.stdout.trim(),
          hasChanges: status.stdout.trim().length > 0,
          changedFiles: status.stdout.trim().split('\n').filter(l => l).length
        }, null, 2);
      } catch {
        return JSON.stringify({ error: 'Not a git repository' }, null, 2);
      }
    }
  }
];

// ==================== PLUGIN EXPORT ====================

export function register(pluginManager) {
  for (const resource of resources) {
    pluginManager.registerResource(resource);
  }
}

export default { register };
