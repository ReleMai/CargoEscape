/**
 * Advanced Godot Analysis Tools Plugin
 * Scene graph analysis, asset tracking, autoload mapping, and more
 */

import fs from 'fs/promises';
import path from 'path';

const WORKSPACE = process.env.WORKSPACE_PATH || '/workspace';

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
  } catch (error) {}
  
  return results;
}

async function readFileContent(filePath) {
  try {
    return await fs.readFile(filePath, 'utf-8');
  } catch {
    return null;
  }
}

async function fileExists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

// ==================== TOOL DEFINITIONS ====================

const tools = [
  // Scene Graph Analyzer
  {
    definition: {
      name: 'godot_scene_graph',
      description: 'Analyze the node hierarchy and structure of a scene file',
      category: 'analysis',
      tags: ['scene', 'nodes', 'hierarchy'],
      inputSchema: {
        type: 'object',
        properties: {
          scenePath: { type: 'string', description: 'Path to the .tscn file' }
        },
        required: ['scenePath']
      }
    },
    handler: async (args) => {
      const filePath = path.join(WORKSPACE, args.scenePath);
      const content = await readFileContent(filePath);
      
      if (!content) {
        throw new Error(`Could not read scene: ${args.scenePath}`);
      }
      
      const nodes = [];
      const externalResources = [];
      const subResources = [];
      const connections = [];
      
      // Parse external resources
      const extResRegex = /\[ext_resource\s+type="([^"]+)"\s+.*?path="([^"]+)".*?id="([^"]+)"\]/g;
      let match;
      while ((match = extResRegex.exec(content)) !== null) {
        externalResources.push({
          type: match[1],
          path: match[2],
          id: match[3]
        });
      }
      
      // Parse sub resources
      const subResRegex = /\[sub_resource\s+type="([^"]+)"\s+id="([^"]+)"\]/g;
      while ((match = subResRegex.exec(content)) !== null) {
        subResources.push({
          type: match[1],
          id: match[2]
        });
      }
      
      // Parse nodes
      const nodeRegex = /\[node\s+name="([^"]+)"\s*(type="([^"]+)")?\s*(parent="([^"]*)")?\s*(instance=([^\]]+))?\]/g;
      while ((match = nodeRegex.exec(content)) !== null) {
        nodes.push({
          name: match[1],
          type: match[3] || 'instanced',
          parent: match[5] || null,
          isInstance: !!match[7]
        });
      }
      
      // Parse signal connections
      const connRegex = /\[connection\s+signal="([^"]+)"\s+from="([^"]+)"\s+to="([^"]+)"\s+method="([^"]+)"\]/g;
      while ((match = connRegex.exec(content)) !== null) {
        connections.push({
          signal: match[1],
          from: match[2],
          to: match[3],
          method: match[4]
        });
      }
      
      // Build tree structure
      const buildTree = (parentPath) => {
        return nodes
          .filter(n => n.parent === parentPath)
          .map(n => ({
            name: n.name,
            type: n.type,
            isInstance: n.isInstance,
            children: buildTree(parentPath ? `${parentPath}/${n.name}` : n.name)
          }));
      };
      
      const root = nodes.find(n => !n.parent);
      const tree = root ? {
        name: root.name,
        type: root.type,
        children: buildTree('.')
      } : null;
      
      return {
        scene: args.scenePath,
        summary: {
          totalNodes: nodes.length,
          externalResources: externalResources.length,
          subResources: subResources.length,
          connections: connections.length
        },
        rootNode: root,
        tree,
        externalResources,
        connections
      };
    }
  },
  
  // Asset Usage Tracker
  {
    definition: {
      name: 'godot_asset_usage',
      description: 'Find unused or heavily used assets in the project',
      category: 'analysis',
      tags: ['assets', 'usage', 'optimization'],
      inputSchema: {
        type: 'object',
        properties: {
          assetType: {
            type: 'string',
            enum: ['sprites', 'audio', 'resources', 'all'],
            description: 'Type of assets to check',
            default: 'all'
          }
        }
      }
    },
    handler: async (args) => {
      const assetType = args.assetType || 'all';
      
      // Find all assets
      const extensions = {
        sprites: ['.png', '.jpg', '.svg', '.webp'],
        audio: ['.wav', '.ogg', '.mp3'],
        resources: ['.tres']
      };
      
      const typesToCheck = assetType === 'all' 
        ? Object.keys(extensions) 
        : [assetType];
      
      const assets = [];
      for (const type of typesToCheck) {
        for (const ext of extensions[type] || []) {
          const found = await findFiles(WORKSPACE, ext);
          assets.push(...found.map(f => ({
            path: path.relative(WORKSPACE, f).replace(/\\/g, '/'),
            type,
            extension: ext
          })));
        }
      }
      
      // Find all references in scripts and scenes
      const scripts = await findFiles(WORKSPACE, '.gd');
      const scenes = await findFiles(WORKSPACE, '.tscn');
      const allFiles = [...scripts, ...scenes];
      
      const references = new Map();
      assets.forEach(a => references.set(a.path, { ...a, usedIn: [] }));
      
      for (const file of allFiles) {
        const content = await readFileContent(file);
        if (!content) continue;
        
        const relativePath = path.relative(WORKSPACE, file).replace(/\\/g, '/');
        
        for (const [assetPath, data] of references) {
          // Check for res:// references
          if (content.includes(`res://${assetPath}`) || 
              content.includes(`"${assetPath}"`) ||
              content.includes(`'${assetPath}'`)) {
            data.usedIn.push(relativePath);
          }
        }
      }
      
      const unused = [];
      const mostUsed = [];
      
      for (const [assetPath, data] of references) {
        if (data.usedIn.length === 0) {
          unused.push({ path: assetPath, type: data.type });
        }
        mostUsed.push({ path: assetPath, type: data.type, usageCount: data.usedIn.length });
      }
      
      // Sort by usage
      mostUsed.sort((a, b) => b.usageCount - a.usageCount);
      
      return {
        totalAssets: assets.length,
        unusedCount: unused.length,
        unused: unused.slice(0, 50), // Limit to 50
        mostUsed: mostUsed.slice(0, 20),
        byType: typesToCheck.reduce((acc, type) => {
          acc[type] = assets.filter(a => a.type === type).length;
          return acc;
        }, {})
      };
    }
  },
  
  // Autoload Dependency Map
  {
    definition: {
      name: 'godot_autoload_map',
      description: 'Map which scripts depend on which autoloads (singletons)',
      category: 'analysis',
      tags: ['autoload', 'singleton', 'dependencies'],
      inputSchema: { type: 'object', properties: {} }
    },
    handler: async () => {
      // Read project.godot to find autoloads
      const projectFile = path.join(WORKSPACE, 'project.godot');
      const projectContent = await readFileContent(projectFile);
      
      if (!projectContent) {
        throw new Error('Could not read project.godot');
      }
      
      // Parse autoloads
      const autoloads = [];
      const autoloadRegex = /^(\w+)="?\*?res:\/\/([^"]+)"?/gm;
      const autoloadSection = projectContent.split('[autoload]')[1]?.split('[')[0];
      
      if (autoloadSection) {
        let match;
        while ((match = autoloadRegex.exec(autoloadSection)) !== null) {
          autoloads.push({
            name: match[1],
            path: match[2]
          });
        }
      }
      
      // Find all scripts that reference autoloads
      const scripts = await findFiles(WORKSPACE, '.gd');
      const dependencies = {};
      
      for (const autoload of autoloads) {
        dependencies[autoload.name] = {
          path: autoload.path,
          usedBy: []
        };
      }
      
      for (const script of scripts) {
        const content = await readFileContent(script);
        if (!content) continue;
        
        const relativePath = path.relative(WORKSPACE, script).replace(/\\/g, '/');
        
        for (const autoload of autoloads) {
          // Check for direct references
          const patterns = [
            new RegExp(`\\b${autoload.name}\\.`, 'g'),
            new RegExp(`\\b${autoload.name}\\b`, 'g')
          ];
          
          for (const pattern of patterns) {
            if (pattern.test(content)) {
              dependencies[autoload.name].usedBy.push(relativePath);
              break;
            }
          }
        }
      }
      
      // Remove duplicates and sort
      for (const name of Object.keys(dependencies)) {
        dependencies[name].usedBy = [...new Set(dependencies[name].usedBy)].sort();
        dependencies[name].usageCount = dependencies[name].usedBy.length;
      }
      
      return {
        autoloadCount: autoloads.length,
        autoloads: autoloads.map(a => a.name),
        dependencies,
        mostUsed: Object.entries(dependencies)
          .sort(([, a], [, b]) => b.usageCount - a.usageCount)
          .map(([name, data]) => ({ name, usageCount: data.usageCount }))
      };
    }
  },
  
  // Input Map Analyzer
  {
    definition: {
      name: 'godot_input_map',
      description: 'List all input actions and their bindings from project.godot',
      category: 'analysis',
      tags: ['input', 'controls', 'keybindings'],
      inputSchema: { type: 'object', properties: {} }
    },
    handler: async () => {
      const projectFile = path.join(WORKSPACE, 'project.godot');
      const projectContent = await readFileContent(projectFile);
      
      if (!projectContent) {
        throw new Error('Could not read project.godot');
      }
      
      // Parse input section
      const inputSection = projectContent.split('[input]')[1]?.split('\n[')[0];
      const actions = [];
      
      if (inputSection) {
        const lines = inputSection.split('\n');
        let currentAction = null;
        
        for (const line of lines) {
          const actionMatch = line.match(/^(\w+)=\{/);
          if (actionMatch) {
            currentAction = actionMatch[1];
            const deadzone = line.match(/deadzone":\s*([\d.]+)/)?.[1];
            const events = [];
            
            // Extract key events
            const keyMatches = line.matchAll(/InputEventKey[^}]*keycode":\s*(\d+)/g);
            for (const match of keyMatches) {
              events.push({ type: 'key', keycode: parseInt(match[1]) });
            }
            
            // Extract joypad buttons
            const joyMatches = line.matchAll(/InputEventJoypadButton[^}]*button_index":\s*(\d+)/g);
            for (const match of joyMatches) {
              events.push({ type: 'joypad_button', index: parseInt(match[1]) });
            }
            
            // Extract mouse buttons
            const mouseMatches = line.matchAll(/InputEventMouseButton[^}]*button_index":\s*(\d+)/g);
            for (const match of mouseMatches) {
              events.push({ type: 'mouse_button', index: parseInt(match[1]) });
            }
            
            actions.push({
              name: currentAction,
              deadzone: deadzone ? parseFloat(deadzone) : 0.5,
              events
            });
          }
        }
      }
      
      // Find usage in scripts
      const scripts = await findFiles(WORKSPACE, '.gd');
      const actionUsage = {};
      
      for (const action of actions) {
        actionUsage[action.name] = [];
      }
      
      for (const script of scripts) {
        const content = await readFileContent(script);
        if (!content) continue;
        
        const relativePath = path.relative(WORKSPACE, script).replace(/\\/g, '/');
        
        for (const action of actions) {
          if (content.includes(`"${action.name}"`) || content.includes(`'${action.name}'`)) {
            actionUsage[action.name].push(relativePath);
          }
        }
      }
      
      return {
        actionCount: actions.length,
        actions: actions.map(a => ({
          ...a,
          usedIn: actionUsage[a.name] || []
        })),
        unusedActions: actions.filter(a => (actionUsage[a.name] || []).length === 0).map(a => a.name)
      };
    }
  },
  
  // GDScript Linter (basic)
  {
    definition: {
      name: 'godot_lint',
      description: 'Check GDScript files for common style issues and anti-patterns',
      category: 'quality',
      tags: ['lint', 'style', 'quality'],
      inputSchema: {
        type: 'object',
        properties: {
          path: {
            type: 'string',
            description: 'Specific file or directory to check (default: all scripts)'
          }
        }
      }
    },
    handler: async (args) => {
      const targetPath = args.path 
        ? path.join(WORKSPACE, args.path)
        : path.join(WORKSPACE, 'scripts');
      
      const files = (await fs.stat(targetPath)).isDirectory()
        ? await findFiles(targetPath, '.gd')
        : [targetPath];
      
      const issues = [];
      const rules = [
        {
          name: 'long_line',
          pattern: /^.{121,}$/gm,
          message: 'Line exceeds 120 characters',
          severity: 'warning'
        },
        {
          name: 'trailing_whitespace',
          pattern: /[ \t]+$/gm,
          message: 'Trailing whitespace',
          severity: 'info'
        },
        {
          name: 'multiple_blank_lines',
          pattern: /\n{4,}/g,
          message: 'Multiple consecutive blank lines',
          severity: 'info'
        },
        {
          name: 'missing_type_hint',
          pattern: /^var\s+\w+\s*=(?!\s*(preload|load))/gm,
          message: 'Variable declaration without type hint',
          severity: 'info'
        },
        {
          name: 'pass_in_function',
          pattern: /^func\s+\w+\([^)]*\)[^:]*:\s*\n\s+pass\s*$/gm,
          message: 'Empty function with only pass statement',
          severity: 'warning'
        },
        {
          name: 'hardcoded_number',
          pattern: /(?<![\w.])\d{3,}(?![\w])/g,
          message: 'Magic number (consider using a constant)',
          severity: 'info'
        },
        {
          name: 'print_statement',
          pattern: /\bprint\s*\(/g,
          message: 'Debug print statement found',
          severity: 'info'
        }
      ];
      
      for (const file of files) {
        const content = await readFileContent(file);
        if (!content) continue;
        
        const relativePath = path.relative(WORKSPACE, file).replace(/\\/g, '/');
        const lines = content.split('\n');
        
        for (const rule of rules) {
          const matches = content.matchAll(rule.pattern);
          
          for (const match of matches) {
            // Find line number
            const beforeMatch = content.substring(0, match.index);
            const lineNumber = (beforeMatch.match(/\n/g) || []).length + 1;
            
            issues.push({
              file: relativePath,
              line: lineNumber,
              rule: rule.name,
              message: rule.message,
              severity: rule.severity,
              snippet: lines[lineNumber - 1]?.trim().substring(0, 60)
            });
          }
        }
      }
      
      // Group by severity
      const bySeverity = {
        error: issues.filter(i => i.severity === 'error'),
        warning: issues.filter(i => i.severity === 'warning'),
        info: issues.filter(i => i.severity === 'info')
      };
      
      return {
        filesChecked: files.length,
        totalIssues: issues.length,
        summary: {
          errors: bySeverity.error.length,
          warnings: bySeverity.warning.length,
          info: bySeverity.info.length
        },
        issues: issues.slice(0, 100), // Limit output
        byFile: [...new Set(issues.map(i => i.file))].map(f => ({
          file: f,
          count: issues.filter(i => i.file === f).length
        })).sort((a, b) => b.count - a.count).slice(0, 20)
      };
    }
  },
  
  // Performance Hints
  {
    definition: {
      name: 'godot_performance_hints',
      description: 'Detect common performance anti-patterns in GDScript',
      category: 'quality',
      tags: ['performance', 'optimization'],
      inputSchema: { type: 'object', properties: {} }
    },
    handler: async () => {
      const scripts = await findFiles(WORKSPACE, '.gd');
      const hints = [];
      
      const patterns = [
        {
          pattern: /get_node\s*\([^)]+\)/g,
          hint: 'Consider caching get_node() result in @onready var',
          severity: 'medium'
        },
        {
          pattern: /\$[^\s]+/g,
          hint: 'Consider caching $ node reference in @onready var if used frequently',
          severity: 'low'
        },
        {
          pattern: /for\s+\w+\s+in\s+range\s*\(\s*len\s*\([^)]+\)\s*\)/g,
          hint: 'Use "for item in array" instead of "for i in range(len(array))"',
          severity: 'low'
        },
        {
          pattern: /\._process\s*\([^)]*\)\s*:/g,
          hint: 'Check if _process is necessary, consider using signals or timers',
          severity: 'info'
        },
        {
          pattern: /\._physics_process\s*\([^)]*\)\s*:/g,
          hint: 'Check if _physics_process is necessary',
          severity: 'info'
        },
        {
          pattern: /instantiate\s*\(\)/g,
          hint: 'Consider object pooling for frequently instantiated objects',
          severity: 'medium'
        },
        {
          pattern: /queue_free\s*\(\)/g,
          hint: 'Consider object pooling instead of frequent create/destroy',
          severity: 'low'
        },
        {
          pattern: /\.connect\s*\([^)]+\)\s*$/gm,
          hint: 'Consider connecting signals in _ready() with @onready nodes',
          severity: 'info'
        }
      ];
      
      for (const script of scripts) {
        const content = await readFileContent(script);
        if (!content) continue;
        
        const relativePath = path.relative(WORKSPACE, script).replace(/\\/g, '/');
        const lines = content.split('\n');
        
        for (const { pattern, hint, severity } of patterns) {
          const matches = content.matchAll(pattern);
          
          for (const match of matches) {
            const beforeMatch = content.substring(0, match.index);
            const lineNumber = (beforeMatch.match(/\n/g) || []).length + 1;
            
            hints.push({
              file: relativePath,
              line: lineNumber,
              hint,
              severity,
              code: match[0].substring(0, 50)
            });
          }
        }
      }
      
      // Deduplicate by file+hint
      const seen = new Set();
      const dedupedHints = hints.filter(h => {
        const key = `${h.file}:${h.hint}`;
        if (seen.has(key)) return false;
        seen.add(key);
        return true;
      });
      
      return {
        filesAnalyzed: scripts.length,
        totalHints: dedupedHints.length,
        bySeverity: {
          high: dedupedHints.filter(h => h.severity === 'high').length,
          medium: dedupedHints.filter(h => h.severity === 'medium').length,
          low: dedupedHints.filter(h => h.severity === 'low').length,
          info: dedupedHints.filter(h => h.severity === 'info').length
        },
        hints: dedupedHints.slice(0, 50)
      };
    }
  },
  
  // Documentation Generator
  {
    definition: {
      name: 'godot_generate_docs',
      description: 'Generate documentation from GDScript comments and signatures',
      category: 'documentation',
      tags: ['docs', 'api', 'comments'],
      inputSchema: {
        type: 'object',
        properties: {
          scriptPath: {
            type: 'string',
            description: 'Specific script to document (optional)'
          },
          format: {
            type: 'string',
            enum: ['markdown', 'json'],
            default: 'json'
          }
        }
      }
    },
    handler: async (args) => {
      const files = args.scriptPath
        ? [path.join(WORKSPACE, args.scriptPath)]
        : await findFiles(path.join(WORKSPACE, 'scripts'), '.gd');
      
      const docs = [];
      
      for (const file of files) {
        const content = await readFileContent(file);
        if (!content) continue;
        
        const relativePath = path.relative(WORKSPACE, file).replace(/\\/g, '/');
        const doc = {
          file: relativePath,
          className: null,
          extends: null,
          description: null,
          signals: [],
          exports: [],
          functions: [],
          constants: []
        };
        
        const lines = content.split('\n');
        let currentComment = [];
        
        for (let i = 0; i < lines.length; i++) {
          const line = lines[i];
          const trimmed = line.trim();
          
          // Collect doc comments
          if (trimmed.startsWith('##')) {
            currentComment.push(trimmed.substring(2).trim());
            continue;
          }
          
          // Class name
          const classMatch = trimmed.match(/^class_name\s+(\w+)/);
          if (classMatch) {
            doc.className = classMatch[1];
          }
          
          // Extends
          const extendsMatch = trimmed.match(/^extends\s+(\w+)/);
          if (extendsMatch) {
            doc.extends = extendsMatch[1];
          }
          
          // Signals
          const signalMatch = trimmed.match(/^signal\s+(\w+)\s*(\([^)]*\))?/);
          if (signalMatch) {
            doc.signals.push({
              name: signalMatch[1],
              params: signalMatch[2] || '()',
              description: currentComment.join(' ')
            });
          }
          
          // Exports
          const exportMatch = trimmed.match(/^@export\s+var\s+(\w+)\s*:\s*(\w+)/);
          if (exportMatch) {
            doc.exports.push({
              name: exportMatch[1],
              type: exportMatch[2],
              description: currentComment.join(' ')
            });
          }
          
          // Functions
          const funcMatch = trimmed.match(/^func\s+(\w+)\s*\(([^)]*)\)\s*(->\s*(\w+))?/);
          if (funcMatch && !funcMatch[1].startsWith('_')) {
            doc.functions.push({
              name: funcMatch[1],
              params: funcMatch[2],
              returnType: funcMatch[4] || 'void',
              description: currentComment.join(' '),
              line: i + 1
            });
          }
          
          // Constants
          const constMatch = trimmed.match(/^const\s+(\w+)\s*[=:]/);
          if (constMatch) {
            doc.constants.push({
              name: constMatch[1],
              description: currentComment.join(' ')
            });
          }
          
          // Clear comment if we hit a non-comment, non-empty line
          if (trimmed && !trimmed.startsWith('#')) {
            currentComment = [];
          }
        }
        
        // Only include if has meaningful content
        if (doc.className || doc.signals.length || doc.functions.length) {
          docs.push(doc);
        }
      }
      
      if (args.format === 'markdown') {
        // Convert to markdown
        const md = docs.map(doc => {
          let out = `# ${doc.className || doc.file}\n\n`;
          if (doc.extends) out += `**Extends:** ${doc.extends}\n\n`;
          if (doc.description) out += `${doc.description}\n\n`;
          
          if (doc.signals.length) {
            out += `## Signals\n\n`;
            for (const sig of doc.signals) {
              out += `- \`${sig.name}${sig.params}\`${sig.description ? ': ' + sig.description : ''}\n`;
            }
            out += '\n';
          }
          
          if (doc.exports.length) {
            out += `## Exports\n\n`;
            for (const exp of doc.exports) {
              out += `- \`${exp.name}: ${exp.type}\`${exp.description ? ': ' + exp.description : ''}\n`;
            }
            out += '\n';
          }
          
          if (doc.functions.length) {
            out += `## Methods\n\n`;
            for (const func of doc.functions) {
              out += `### ${func.name}(${func.params}) -> ${func.returnType}\n`;
              if (func.description) out += `${func.description}\n`;
              out += '\n';
            }
          }
          
          return out;
        }).join('\n---\n\n');
        
        return { format: 'markdown', content: md };
      }
      
      return {
        format: 'json',
        scriptsDocumented: docs.length,
        docs
      };
    }
  }
];

// ==================== PLUGIN EXPORT ====================

export function register(pluginManager) {
  pluginManager.registerTools(tools);
}

export default { register };
