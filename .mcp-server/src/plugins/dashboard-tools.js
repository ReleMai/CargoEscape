/**
 * Dashboard Enhancement Tools Plugin
 * File preview, code search, git diff, health score, trends, and more
 */

import fs from 'fs/promises';
import path from 'path';
import { spawn } from 'child_process';

const WORKSPACE = process.env.WORKSPACE_PATH || '/workspace';
const TRENDS_FILE = path.join(WORKSPACE, '.mcp-server', 'trends.json');

// ==================== UTILITY FUNCTIONS ====================

async function findFiles(dir, extension, results = []) {
  try {
    const entries = await fs.readdir(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory() && !entry.name.startsWith('.') && entry.name !== 'addons' && entry.name !== 'node_modules') {
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

function execCommand(command, args, options = {}) {
  return new Promise((resolve, reject) => {
    const proc = spawn(command, args, {
      cwd: options.cwd || WORKSPACE,
      shell: true,
      timeout: options.timeout || 30000
    });
    
    let stdout = '';
    let stderr = '';
    
    proc.stdout?.on('data', (data) => { stdout += data.toString(); });
    proc.stderr?.on('data', (data) => { stderr += data.toString(); });
    
    const timer = setTimeout(() => {
      proc.kill('SIGTERM');
      reject(new Error(`Command timed out`));
    }, options.timeout || 30000);
    
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

// Security: Validate file path is within workspace
function validatePath(inputPath) {
  const resolved = path.resolve(WORKSPACE, inputPath);
  if (!resolved.startsWith(WORKSPACE)) {
    throw new Error('Path traversal attempt blocked');
  }
  return resolved;
}

// ==================== GODOT DOCUMENTATION LINKS ====================

const GODOT_DOCS_BASE = 'https://docs.godotengine.org/en/stable/classes/class_';

// Common Godot classes and their documentation URLs
const GODOT_CLASSES = {
  // Core
  'Node': 'node.html',
  'Node2D': 'node2d.html',
  'Node3D': 'node3d.html',
  'Object': 'object.html',
  'Resource': 'resource.html',
  'RefCounted': 'refcounted.html',
  
  // 2D Nodes
  'Sprite2D': 'sprite2d.html',
  'AnimatedSprite2D': 'animatedsprite2d.html',
  'CharacterBody2D': 'characterbody2d.html',
  'RigidBody2D': 'rigidbody2d.html',
  'StaticBody2D': 'staticbody2d.html',
  'Area2D': 'area2d.html',
  'CollisionShape2D': 'collisionshape2d.html',
  'TileMap': 'tilemap.html',
  'Camera2D': 'camera2d.html',
  'CanvasLayer': 'canvaslayer.html',
  'ParallaxBackground': 'parallaxbackground.html',
  'ParallaxLayer': 'parallaxlayer.html',
  'Line2D': 'line2d.html',
  'Path2D': 'path2d.html',
  'PathFollow2D': 'pathfollow2d.html',
  'Polygon2D': 'polygon2d.html',
  'Light2D': 'light2d.html',
  'PointLight2D': 'pointlight2d.html',
  'GPUParticles2D': 'gpuparticles2d.html',
  'CPUParticles2D': 'cpuparticles2d.html',
  
  // UI
  'Control': 'control.html',
  'Container': 'container.html',
  'BoxContainer': 'boxcontainer.html',
  'VBoxContainer': 'vboxcontainer.html',
  'HBoxContainer': 'hboxcontainer.html',
  'GridContainer': 'gridcontainer.html',
  'MarginContainer': 'margincontainer.html',
  'CenterContainer': 'centercontainer.html',
  'PanelContainer': 'panelcontainer.html',
  'ScrollContainer': 'scrollcontainer.html',
  'Label': 'label.html',
  'RichTextLabel': 'richtextlabel.html',
  'Button': 'button.html',
  'TextureButton': 'texturebutton.html',
  'TextEdit': 'textedit.html',
  'LineEdit': 'lineedit.html',
  'Panel': 'panel.html',
  'TextureRect': 'texturerect.html',
  'ColorRect': 'colorrect.html',
  'NinePatchRect': 'ninepatchrect.html',
  'ProgressBar': 'progressbar.html',
  'HSlider': 'hslider.html',
  'VSlider': 'vslider.html',
  'SpinBox': 'spinbox.html',
  'OptionButton': 'optionbutton.html',
  'CheckBox': 'checkbox.html',
  'CheckButton': 'checkbutton.html',
  'TabContainer': 'tabcontainer.html',
  'TabBar': 'tabbar.html',
  'Tree': 'tree.html',
  'ItemList': 'itemlist.html',
  
  // Audio
  'AudioStreamPlayer': 'audiostreamplayer.html',
  'AudioStreamPlayer2D': 'audiostreamplayer2d.html',
  'AudioStreamPlayer3D': 'audiostreamplayer3d.html',
  
  // Animation
  'AnimationPlayer': 'animationplayer.html',
  'AnimationTree': 'animationtree.html',
  'Tween': 'tween.html',
  'Timer': 'timer.html',
  
  // Resources
  'Texture2D': 'texture2d.html',
  'PackedScene': 'packedscene.html',
  'Script': 'script.html',
  'Shader': 'shader.html',
  'Material': 'material.html',
  'ShaderMaterial': 'shadermaterial.html',
  'CanvasItemMaterial': 'canvasitemmaterial.html',
  
  // Data
  'Array': 'array.html',
  'Dictionary': 'dictionary.html',
  'String': 'string.html',
  'Vector2': 'vector2.html',
  'Vector3': 'vector3.html',
  'Color': 'color.html',
  'Rect2': 'rect2.html',
  'Transform2D': 'transform2d.html',
  
  // Input
  'InputEvent': 'inputevent.html',
  'InputEventKey': 'inputeventkey.html',
  'InputEventMouse': 'inputeventmouse.html',
  'InputEventMouseButton': 'inputeventmousebutton.html',
  'InputEventMouseMotion': 'inputeventmousemotion.html',
  
  // Physics
  'PhysicsBody2D': 'physicsbody2d.html',
  'KinematicCollision2D': 'kinematiccollision2d.html',
  'RayCast2D': 'raycast2d.html',
  'ShapeCast2D': 'shapecast2d.html',
  
  // Misc
  'RandomNumberGenerator': 'randomnumbergenerator.html',
  'HTTPRequest': 'httprequest.html',
  'FileAccess': 'fileaccess.html',
  'DirAccess': 'diraccess.html',
  'JSON': 'json.html',
  'SceneTree': 'scenetree.html',
  'Viewport': 'viewport.html',
  'Window': 'window.html'
};

// Common GDScript keywords and their documentation
const GDSCRIPT_KEYWORDS = {
  '@onready': 'https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#onready-annotation',
  '@export': 'https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_exports.html',
  '@tool': 'https://docs.godotengine.org/en/stable/tutorials/plugins/running_code_in_the_editor.html',
  'signal': 'https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html',
  'preload': 'https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#preload',
  'load': 'https://docs.godotengine.org/en/stable/classes/class_@gdscript.html#class-gdscript-method-load',
  'await': 'https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#awaiting-for-signals-or-coroutines',
  'yield': 'https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#coroutines-with-yield',
  'class_name': 'https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#registering-named-classes',
  'extends': 'https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#inheritance'
};

// ==================== WIKI ANALYZER FUNCTIONS ====================

async function analyzeGDScript(filePath, content) {
  const lines = content.split('\n');
  const analysis = {
    overview: {
      className: null,
      extends: null,
      description: [],
      purpose: null,
      isTool: false
    },
    signals: [],
    exports: [],
    constants: [],
    variables: [],
    onreadyVars: [],
    functions: [],
    innerClasses: [],
    dependencies: [],
    godotLinks: [],
    usedIn: []
  };
  
  let currentComment = [];
  let inMultilineComment = false;
  let currentFunction = null;
  
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const trimmed = line.trim();
    const lineNum = i + 1;
    
    // Track file header comments
    if (i < 30 && (trimmed.startsWith('#') || trimmed.startsWith('"""') || trimmed.startsWith("'''"))) {
      if (trimmed.startsWith('#')) {
        const comment = trimmed.substring(1).trim();
        if (comment && !comment.startsWith('=')) {
          analysis.overview.description.push(comment);
        }
      }
    }
    
    // Check for @tool
    if (trimmed === '@tool') {
      analysis.overview.isTool = true;
    }
    
    // Parse class_name
    const classMatch = trimmed.match(/^class_name\s+(\w+)/);
    if (classMatch) {
      analysis.overview.className = classMatch[1];
    }
    
    // Parse extends
    const extendsMatch = trimmed.match(/^extends\s+(\w+)/);
    if (extendsMatch) {
      analysis.overview.extends = extendsMatch[1];
      if (GODOT_CLASSES[extendsMatch[1]]) {
        analysis.godotLinks.push({
          type: 'Base Class',
          name: extendsMatch[1],
          url: GODOT_DOCS_BASE + GODOT_CLASSES[extendsMatch[1]],
          line: lineNum
        });
      }
    }
    
    // Parse signals
    const signalMatch = trimmed.match(/^signal\s+(\w+)(?:\(([^)]*)\))?/);
    if (signalMatch) {
      const prevComment = i > 0 && lines[i-1].trim().startsWith('#') ? 
        lines[i-1].trim().substring(1).trim() : null;
      analysis.signals.push({
        name: signalMatch[1],
        parameters: signalMatch[2] || '',
        line: lineNum,
        description: prevComment
      });
    }
    
    // Parse @export variables
    const exportMatch = trimmed.match(/^@export(?:_\w+)?(?:\([^)]*\))?\s+var\s+(\w+)\s*(?::\s*(\w+))?/);
    if (exportMatch) {
      const prevComment = i > 0 && lines[i-1].trim().startsWith('#') ? 
        lines[i-1].trim().substring(1).trim() : null;
      analysis.exports.push({
        name: exportMatch[1],
        type: exportMatch[2] || 'Variant',
        line: lineNum,
        description: prevComment
      });
    }
    
    // Parse @onready variables
    const onreadyMatch = trimmed.match(/^@onready\s+var\s+(\w+)\s*(?::\s*(\w+))?/);
    if (onreadyMatch) {
      analysis.onreadyVars.push({
        name: onreadyMatch[1],
        type: onreadyMatch[2] || 'Variant',
        line: lineNum
      });
    }
    
    // Parse constants
    const constMatch = trimmed.match(/^const\s+(\w+)\s*(?::\s*(\w+))?\s*=\s*(.+)/);
    if (constMatch) {
      analysis.constants.push({
        name: constMatch[1],
        type: constMatch[2] || 'auto',
        value: constMatch[3].substring(0, 50),
        line: lineNum
      });
    }
    
    // Parse regular variables (not export or onready)
    const varMatch = trimmed.match(/^var\s+(\w+)\s*(?::\s*(\w+))?/);
    if (varMatch && !trimmed.includes('@export') && !trimmed.includes('@onready')) {
      analysis.variables.push({
        name: varMatch[1],
        type: varMatch[2] || 'Variant',
        line: lineNum
      });
    }
    
    // Parse functions
    const funcMatch = trimmed.match(/^func\s+(\w+)\s*\(([^)]*)\)(?:\s*->\s*(\w+))?/);
    if (funcMatch) {
      const prevComment = i > 0 && lines[i-1].trim().startsWith('#') ? 
        lines[i-1].trim().substring(1).trim() : null;
      
      const isPrivate = funcMatch[1].startsWith('_') && !funcMatch[1].startsWith('_ready') && 
                        !funcMatch[1].startsWith('_process') && !funcMatch[1].startsWith('_physics') &&
                        !funcMatch[1].startsWith('_input') && !funcMatch[1].startsWith('_enter') &&
                        !funcMatch[1].startsWith('_exit') && !funcMatch[1].startsWith('_on_');
      
      const isCallback = funcMatch[1].startsWith('_on_');
      const isOverride = ['_ready', '_process', '_physics_process', '_input', '_unhandled_input',
                          '_enter_tree', '_exit_tree', '_notification', '_draw', '_get_configuration_warnings']
                          .includes(funcMatch[1]);
      
      analysis.functions.push({
        name: funcMatch[1],
        parameters: funcMatch[2] || '',
        returnType: funcMatch[3] || 'void',
        line: lineNum,
        description: prevComment,
        isPrivate,
        isCallback,
        isOverride,
        category: isOverride ? 'Godot Override' : isCallback ? 'Signal Callback' : isPrivate ? 'Private' : 'Public'
      });
    }
    
    // Parse inner classes
    const innerClassMatch = trimmed.match(/^class\s+(\w+)(?:\s+extends\s+(\w+))?/);
    if (innerClassMatch) {
      analysis.innerClasses.push({
        name: innerClassMatch[1],
        extends: innerClassMatch[2] || 'RefCounted',
        line: lineNum
      });
    }
    
    // Parse preload/load dependencies
    const preloadMatch = line.match(/(?:preload|load)\s*\(\s*["']res:\/\/([^"']+)["']\s*\)/g);
    if (preloadMatch) {
      preloadMatch.forEach(match => {
        const pathMatch = match.match(/["']res:\/\/([^"']+)["']/);
        if (pathMatch) {
          analysis.dependencies.push({
            path: pathMatch[1],
            line: lineNum,
            type: match.startsWith('preload') ? 'preload' : 'load'
          });
        }
      });
    }
    
    // Find Godot class references for documentation links
    for (const [className, docPath] of Object.entries(GODOT_CLASSES)) {
      const regex = new RegExp(`\\b${className}\\b`, 'g');
      if (regex.test(line) && !analysis.godotLinks.find(l => l.name === className)) {
        analysis.godotLinks.push({
          type: 'Used Class',
          name: className,
          url: GODOT_DOCS_BASE + docPath,
          line: lineNum
        });
      }
    }
  }
  
  // Determine purpose from analysis
  if (analysis.overview.extends) {
    const ext = analysis.overview.extends;
    if (['CharacterBody2D', 'RigidBody2D'].includes(ext)) {
      analysis.overview.purpose = 'Physics-based game entity';
    } else if (ext === 'Area2D') {
      analysis.overview.purpose = 'Trigger/detection zone';
    } else if (['Control', 'Container', 'Panel'].some(c => ext.includes(c))) {
      analysis.overview.purpose = 'User interface component';
    } else if (ext === 'Node') {
      analysis.overview.purpose = 'Manager/controller script';
    } else if (ext === 'Resource') {
      analysis.overview.purpose = 'Data container resource';
    }
  }
  
  return analysis;
}

async function findFileUsages(filePath, allScripts) {
  const usages = [];
  const fileName = path.basename(filePath);
  const relativePath = path.relative(WORKSPACE, filePath).replace(/\\/g, '/');
  
  for (const scriptPath of allScripts) {
    if (scriptPath === filePath) continue;
    
    const content = await readFileContent(scriptPath);
    if (!content) continue;
    
    const scriptRelative = path.relative(WORKSPACE, scriptPath).replace(/\\/g, '/');
    const lines = content.split('\n');
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      
      // Check for preload/load references
      if (line.includes(relativePath) || line.includes(fileName)) {
        const match = line.match(/(?:preload|load)\s*\(\s*["']res:\/\/([^"']+)["']\s*\)/);
        if (match && match[1].includes(fileName.replace('.gd', ''))) {
          usages.push({
            file: scriptRelative,
            line: i + 1,
            type: 'import',
            context: line.trim().substring(0, 100)
          });
        }
      }
    }
  }
  
  return usages;
}

async function analyzeScene(filePath, content) {
  const analysis = {
    overview: {
      type: 'Scene',
      rootNode: null,
      rootType: null,
      description: []
    },
    nodes: [],
    scripts: [],
    resources: [],
    signals: [],
    groups: [],
    godotLinks: []
  };
  
  const lines = content.split('\n');
  
  // Parse external resources
  const extResourceRegex = /\[ext_resource\s+type="([^"]+)"\s+(?:uid="[^"]+"\s+)?path="res:\/\/([^"]+)"\s+id="([^"]+)"\]/g;
  let match;
  while ((match = extResourceRegex.exec(content)) !== null) {
    const entry = {
      type: match[1],
      path: match[2],
      id: match[3]
    };
    
    if (match[1] === 'Script') {
      analysis.scripts.push(entry);
    } else {
      analysis.resources.push(entry);
    }
  }
  
  // Parse nodes
  const nodeRegex = /\[node\s+name="([^"]+)"(?:\s+type="([^"]+)")?(?:\s+parent="([^"]*)")?(?:\s+instance=ExtResource\(\s*"([^"]+)"\s*\))?\]/g;
  while ((match = nodeRegex.exec(content)) !== null) {
    const node = {
      name: match[1],
      type: match[2] || 'Instance',
      parent: match[3] || null,
      instance: match[4] || null
    };
    
    if (node.parent === null) {
      analysis.overview.rootNode = node.name;
      analysis.overview.rootType = node.type;
    }
    
    analysis.nodes.push(node);
    
    // Add Godot documentation link
    if (node.type && GODOT_CLASSES[node.type] && !analysis.godotLinks.find(l => l.name === node.type)) {
      analysis.godotLinks.push({
        type: 'Node Type',
        name: node.type,
        url: GODOT_DOCS_BASE + GODOT_CLASSES[node.type]
      });
    }
  }
  
  // Parse signal connections
  const signalRegex = /\[connection\s+signal="([^"]+)"\s+from="([^"]+)"\s+to="([^"]+)"\s+method="([^"]+)"\]/g;
  while ((match = signalRegex.exec(content)) !== null) {
    analysis.signals.push({
      signal: match[1],
      from: match[2],
      to: match[3],
      method: match[4]
    });
  }
  
  // Parse groups
  const groupRegex = /groups\s*=\s*\[([^\]]+)\]/g;
  while ((match = groupRegex.exec(content)) !== null) {
    const groups = match[1].split(',').map(g => g.trim().replace(/"/g, ''));
    groups.forEach(g => {
      if (g && !analysis.groups.includes(g)) {
        analysis.groups.push(g);
      }
    });
  }
  
  return analysis;
}

async function analyzeResource(filePath, content) {
  const analysis = {
    overview: {
      type: 'Resource',
      resourceType: null,
      scriptPath: null,
      description: []
    },
    properties: [],
    godotLinks: []
  };
  
  // Get resource type
  const typeMatch = content.match(/\[gd_resource\s+type="([^"]+)"/);
  if (typeMatch) {
    analysis.overview.resourceType = typeMatch[1];
    if (GODOT_CLASSES[typeMatch[1]]) {
      analysis.godotLinks.push({
        type: 'Resource Type',
        name: typeMatch[1],
        url: GODOT_DOCS_BASE + GODOT_CLASSES[typeMatch[1]]
      });
    }
  }
  
  // Get attached script
  const scriptMatch = content.match(/script\s*=\s*ExtResource\(\s*"([^"]+)"\s*\)/);
  const scriptPathMatch = content.match(/\[ext_resource\s+type="Script"[^]]+path="res:\/\/([^"]+)"/);
  if (scriptPathMatch) {
    analysis.overview.scriptPath = scriptPathMatch[1];
  }
  
  // Parse properties from resource section
  const resourceSection = content.split('[resource]')[1] || '';
  const propRegex = /^(\w+)\s*=\s*(.+)$/gm;
  let match;
  while ((match = propRegex.exec(resourceSection)) !== null) {
    if (!match[1].startsWith('script') && !match[1].startsWith('metadata')) {
      analysis.properties.push({
        name: match[1],
        value: match[2].substring(0, 100)
      });
    }
  }
  
  return analysis;
}

// ==================== TOOL DEFINITIONS ====================

const tools = [
  // File Preview
  {
    definition: {
      name: 'preview_file',
      description: 'Read and preview file contents with syntax info',
      category: 'files',
      tags: ['preview', 'read', 'view'],
      inputSchema: {
        type: 'object',
        properties: {
          filePath: { type: 'string', description: 'Relative path to the file' },
          startLine: { type: 'number', description: 'Start line (1-indexed, optional)' },
          endLine: { type: 'number', description: 'End line (1-indexed, optional)' },
          maxLines: { type: 'number', description: 'Max lines to return (default: 200)' }
        },
        required: ['filePath']
      }
    },
    handler: async (args) => {
      const safePath = validatePath(args.filePath);
      const content = await readFileContent(safePath);
      
      if (content === null) {
        throw new Error(`File not found: ${args.filePath}`);
      }
      
      const lines = content.split('\n');
      const totalLines = lines.length;
      const startLine = Math.max(1, args.startLine || 1);
      const maxLines = args.maxLines || 200;
      const endLine = Math.min(totalLines, args.endLine || startLine + maxLines - 1);
      
      const selectedLines = lines.slice(startLine - 1, endLine);
      
      // Determine language from extension
      const ext = path.extname(args.filePath).toLowerCase();
      const langMap = {
        '.gd': 'gdscript',
        '.tscn': 'godot-scene',
        '.tres': 'godot-resource',
        '.gdshader': 'glsl',
        '.json': 'json',
        '.md': 'markdown',
        '.js': 'javascript',
        '.ts': 'typescript',
        '.py': 'python',
        '.cfg': 'ini',
        '.import': 'ini'
      };
      
      return {
        filePath: args.filePath,
        language: langMap[ext] || 'text',
        totalLines,
        startLine,
        endLine,
        content: selectedLines.join('\n'),
        truncated: endLine < totalLines
      };
    }
  },

  // Wiki-style File Analysis
  {
    definition: {
      name: 'wiki_analyze',
      description: 'Generate Wikipedia-style documentation for a project file with code analysis and cross-references',
      category: 'documentation',
      tags: ['wiki', 'documentation', 'analysis', 'reference'],
      inputSchema: {
        type: 'object',
        properties: {
          filePath: { type: 'string', description: 'Relative path to the file to analyze' },
          includeCode: { type: 'boolean', description: 'Include full code content (default: true)' },
          includeUsages: { type: 'boolean', description: 'Find where this file is used (default: true)' }
        },
        required: ['filePath']
      }
    },
    handler: async (args) => {
      const safePath = validatePath(args.filePath);
      const content = await readFileContent(safePath);
      
      if (content === null) {
        throw new Error(`File not found: ${args.filePath}`);
      }
      
      const ext = path.extname(args.filePath).toLowerCase();
      const fileName = path.basename(args.filePath);
      const relativePath = args.filePath.replace(/\\/g, '/');
      const lines = content.split('\n');
      
      let analysis;
      let fileType;
      
      // Analyze based on file type
      if (ext === '.gd') {
        fileType = 'GDScript';
        analysis = await analyzeGDScript(safePath, content);
        
        // Find usages if requested
        if (args.includeUsages !== false) {
          const allScripts = await findFiles(WORKSPACE, '.gd');
          analysis.usedIn = await findFileUsages(safePath, allScripts);
        }
      } else if (ext === '.tscn') {
        fileType = 'Scene';
        analysis = await analyzeScene(safePath, content);
      } else if (ext === '.tres') {
        fileType = 'Resource';
        analysis = await analyzeResource(safePath, content);
      } else if (ext === '.md') {
        fileType = 'Documentation';
        analysis = {
          overview: {
            type: 'Markdown',
            description: lines.slice(0, 10),
            wordCount: content.split(/\s+/).length,
            headings: lines.filter(l => l.startsWith('#')).map(l => l.replace(/^#+\s*/, ''))
          },
          godotLinks: []
        };
      } else {
        fileType = 'File';
        analysis = {
          overview: {
            type: ext.toUpperCase().substring(1) || 'Unknown',
            description: []
          },
          godotLinks: []
        };
      }
      
      // Build comprehensive wiki result
      const result = {
        meta: {
          filePath: relativePath,
          fileName,
          fileType,
          extension: ext,
          totalLines: lines.length,
          fileSize: content.length,
          lastAnalyzed: new Date().toISOString()
        },
        analysis,
        content: args.includeCode !== false ? content : null,
        
        // Quick navigation for dashboard
        sections: []
      };
      
      // Build sections list for navigation
      if (fileType === 'GDScript') {
        if (analysis.overview.className || analysis.overview.extends) {
          result.sections.push({ id: 'overview', title: 'Overview', icon: '📄' });
        }
        if (analysis.signals.length > 0) {
          result.sections.push({ id: 'signals', title: `Signals (${analysis.signals.length})`, icon: '📡' });
        }
        if (analysis.exports.length > 0) {
          result.sections.push({ id: 'exports', title: `Exports (${analysis.exports.length})`, icon: '📤' });
        }
        if (analysis.constants.length > 0) {
          result.sections.push({ id: 'constants', title: `Constants (${analysis.constants.length})`, icon: '🔒' });
        }
        if (analysis.onreadyVars.length > 0) {
          result.sections.push({ id: 'onready', title: `@onready (${analysis.onreadyVars.length})`, icon: '⚡' });
        }
        if (analysis.variables.length > 0) {
          result.sections.push({ id: 'variables', title: `Variables (${analysis.variables.length})`, icon: '📦' });
        }
        if (analysis.functions.length > 0) {
          result.sections.push({ id: 'functions', title: `Functions (${analysis.functions.length})`, icon: '⚙️' });
        }
        if (analysis.innerClasses.length > 0) {
          result.sections.push({ id: 'classes', title: `Inner Classes (${analysis.innerClasses.length})`, icon: '🏗️' });
        }
        if (analysis.dependencies.length > 0) {
          result.sections.push({ id: 'dependencies', title: `Dependencies (${analysis.dependencies.length})`, icon: '🔗' });
        }
        if (analysis.usedIn?.length > 0) {
          result.sections.push({ id: 'usages', title: `Used In (${analysis.usedIn.length})`, icon: '📍' });
        }
        if (analysis.godotLinks.length > 0) {
          result.sections.push({ id: 'godot-docs', title: `Godot Docs (${analysis.godotLinks.length})`, icon: '📚' });
        }
        result.sections.push({ id: 'code', title: 'Source Code', icon: '💻' });
      } else if (fileType === 'Scene') {
        result.sections.push({ id: 'overview', title: 'Overview', icon: '📄' });
        if (analysis.nodes.length > 0) {
          result.sections.push({ id: 'nodes', title: `Nodes (${analysis.nodes.length})`, icon: '🌳' });
        }
        if (analysis.scripts.length > 0) {
          result.sections.push({ id: 'scripts', title: `Scripts (${analysis.scripts.length})`, icon: '📜' });
        }
        if (analysis.signals.length > 0) {
          result.sections.push({ id: 'connections', title: `Signal Connections (${analysis.signals.length})`, icon: '🔌' });
        }
        if (analysis.resources.length > 0) {
          result.sections.push({ id: 'resources', title: `Resources (${analysis.resources.length})`, icon: '📦' });
        }
        if (analysis.godotLinks.length > 0) {
          result.sections.push({ id: 'godot-docs', title: `Godot Docs (${analysis.godotLinks.length})`, icon: '📚' });
        }
        result.sections.push({ id: 'code', title: 'Scene Source', icon: '💻' });
      }
      
      return result;
    }
  },

  // Code Search
  {
    definition: {
      name: 'search_code',
      description: 'Search for text patterns across all scripts in the project',
      category: 'search',
      tags: ['search', 'find', 'grep'],
      inputSchema: {
        type: 'object',
        properties: {
          pattern: { type: 'string', description: 'Search pattern (text or regex)' },
          fileTypes: { type: 'string', description: 'File extensions to search (comma-separated, default: .gd,.tscn,.tres)' },
          caseSensitive: { type: 'boolean', description: 'Case-sensitive search (default: false)' },
          maxResults: { type: 'number', description: 'Maximum results to return (default: 100)' },
          useRegex: { type: 'boolean', description: 'Treat pattern as regex (default: false)' }
        },
        required: ['pattern']
      }
    },
    handler: async (args) => {
      const fileTypes = (args.fileTypes || '.gd,.tscn,.tres').split(',').map(e => e.trim());
      const caseSensitive = args.caseSensitive || false;
      const maxResults = args.maxResults || 100;
      const useRegex = args.useRegex || false;
      
      let regex;
      try {
        regex = useRegex 
          ? new RegExp(args.pattern, caseSensitive ? 'g' : 'gi')
          : new RegExp(args.pattern.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), caseSensitive ? 'g' : 'gi');
      } catch (e) {
        throw new Error(`Invalid regex pattern: ${e.message}`);
      }
      
      const results = [];
      let totalMatches = 0;
      
      for (const ext of fileTypes) {
        const files = await findFiles(WORKSPACE, ext);
        
        for (const file of files) {
          if (results.length >= maxResults) break;
          
          const content = await readFileContent(file);
          if (!content) continue;
          
          const lines = content.split('\n');
          const relativePath = path.relative(WORKSPACE, file).replace(/\\/g, '/');
          
          lines.forEach((line, index) => {
            if (results.length >= maxResults) return;
            
            if (regex.test(line)) {
              results.push({
                file: relativePath,
                line: index + 1,
                content: line.trim().substring(0, 200),
                column: line.search(regex)
              });
              totalMatches++;
            }
            regex.lastIndex = 0; // Reset regex state
          });
        }
      }
      
      return {
        pattern: args.pattern,
        totalMatches,
        results,
        truncated: totalMatches > maxResults
      };
    }
  },

  // Git Diff
  {
    definition: {
      name: 'git_diff',
      description: 'View git diff for a specific file or all changes',
      category: 'git',
      tags: ['diff', 'changes', 'git'],
      inputSchema: {
        type: 'object',
        properties: {
          filePath: { type: 'string', description: 'Specific file to diff (optional, shows all if omitted)' },
          staged: { type: 'boolean', description: 'Show staged changes instead of unstaged (default: false)' },
          unified: { type: 'number', description: 'Number of context lines (default: 3)' }
        }
      }
    },
    handler: async (args) => {
      const diffArgs = ['diff'];
      
      if (args.staged) {
        diffArgs.push('--cached');
      }
      
      if (args.unified !== undefined) {
        diffArgs.push(`-U${args.unified}`);
      }
      
      diffArgs.push('--color=never');
      
      if (args.filePath) {
        const safePath = validatePath(args.filePath);
        diffArgs.push('--', path.relative(WORKSPACE, safePath));
      }
      
      const result = await execCommand('git', diffArgs);
      
      if (result.code !== 0 && result.stderr) {
        throw new Error(result.stderr);
      }
      
      // Parse diff output into structured format
      const diffText = result.stdout;
      const files = [];
      let currentFile = null;
      let currentHunk = null;
      
      for (const line of diffText.split('\n')) {
        if (line.startsWith('diff --git')) {
          if (currentFile) files.push(currentFile);
          const match = line.match(/diff --git a\/(.*) b\/(.*)/);
          currentFile = {
            oldPath: match?.[1] || '',
            newPath: match?.[2] || '',
            hunks: [],
            additions: 0,
            deletions: 0
          };
          currentHunk = null;
        } else if (line.startsWith('@@') && currentFile) {
          const match = line.match(/@@ -(\d+),?(\d*) \+(\d+),?(\d*) @@(.*)/);
          currentHunk = {
            oldStart: parseInt(match?.[1] || 0),
            oldLines: parseInt(match?.[2] || 1),
            newStart: parseInt(match?.[3] || 0),
            newLines: parseInt(match?.[4] || 1),
            header: match?.[5]?.trim() || '',
            lines: []
          };
          currentFile.hunks.push(currentHunk);
        } else if (currentHunk) {
          currentHunk.lines.push(line);
          if (line.startsWith('+') && !line.startsWith('+++')) {
            currentFile.additions++;
          } else if (line.startsWith('-') && !line.startsWith('---')) {
            currentFile.deletions++;
          }
        }
      }
      
      if (currentFile) files.push(currentFile);
      
      return {
        staged: args.staged || false,
        fileCount: files.length,
        totalAdditions: files.reduce((sum, f) => sum + f.additions, 0),
        totalDeletions: files.reduce((sum, f) => sum + f.deletions, 0),
        files,
        raw: diffText.substring(0, 50000) // Limit raw output
      };
    }
  },

  // Health Score Calculator
  {
    definition: {
      name: 'project_health',
      description: 'Calculate project health score based on various metrics',
      category: 'analysis',
      tags: ['health', 'quality', 'metrics'],
      inputSchema: {
        type: 'object',
        properties: {}
      }
    },
    handler: async () => {
      const metrics = {
        todos: { count: 0, weight: 10, maxPenalty: 20 },
        fixmes: { count: 0, weight: 15, maxPenalty: 30 },
        hacks: { count: 0, weight: 20, maxPenalty: 25 },
        largeScripts: { count: 0, weight: 5, threshold: 500, maxPenalty: 15 },
        deepNesting: { count: 0, weight: 3, maxPenalty: 10 },
        longFunctions: { count: 0, weight: 3, maxPenalty: 10 },
        duplicateCode: { score: 0 },
        testCoverage: { hasTests: false, testCount: 0 }
      };
      
      const issues = [];
      const scripts = await findFiles(WORKSPACE, '.gd');
      
      for (const file of scripts) {
        const content = await readFileContent(file);
        if (!content) continue;
        
        const relativePath = path.relative(WORKSPACE, file).replace(/\\/g, '/');
        const lines = content.split('\n');
        
        // Count TODOs, FIXMEs, HACKs
        lines.forEach((line, i) => {
          if (line.includes('# TODO') || line.includes('#TODO')) {
            metrics.todos.count++;
          }
          if (line.includes('# FIXME') || line.includes('#FIXME')) {
            metrics.fixmes.count++;
            issues.push({ type: 'FIXME', file: relativePath, line: i + 1, severity: 'high' });
          }
          if (line.includes('# HACK') || line.includes('#HACK')) {
            metrics.hacks.count++;
            issues.push({ type: 'HACK', file: relativePath, line: i + 1, severity: 'medium' });
          }
        });
        
        // Check for large scripts
        if (lines.length > metrics.largeScripts.threshold) {
          metrics.largeScripts.count++;
          issues.push({ type: 'large_script', file: relativePath, lines: lines.length, severity: 'low' });
        }
        
        // Check for deep nesting (simplified)
        let maxIndent = 0;
        lines.forEach(line => {
          const indent = line.match(/^(\t+)/)?.[1]?.length || 0;
          maxIndent = Math.max(maxIndent, indent);
        });
        if (maxIndent > 5) {
          metrics.deepNesting.count++;
          issues.push({ type: 'deep_nesting', file: relativePath, depth: maxIndent, severity: 'low' });
        }
        
        // Check for test files
        if (relativePath.includes('test/') || relativePath.includes('test_')) {
          metrics.testCoverage.hasTests = true;
          metrics.testCoverage.testCount++;
        }
      }
      
      // Calculate score (start at 100, subtract penalties)
      let score = 100;
      
      // TODO penalty: up to 20 points
      const todoPenalty = Math.min(metrics.todos.maxPenalty, metrics.todos.count * 0.5);
      score -= todoPenalty;
      
      // FIXME penalty: up to 30 points
      const fixmePenalty = Math.min(metrics.fixmes.maxPenalty, metrics.fixmes.count * 2);
      score -= fixmePenalty;
      
      // HACK penalty: up to 25 points
      const hackPenalty = Math.min(metrics.hacks.maxPenalty, metrics.hacks.count * 3);
      score -= hackPenalty;
      
      // Large scripts penalty: up to 15 points
      const largePenalty = Math.min(metrics.largeScripts.maxPenalty, metrics.largeScripts.count * 2);
      score -= largePenalty;
      
      // Bonus for having tests
      if (metrics.testCoverage.hasTests) {
        score += Math.min(10, metrics.testCoverage.testCount * 2);
      }
      
      // Clamp score
      score = Math.max(0, Math.min(100, Math.round(score)));
      
      // Determine grade
      let grade;
      if (score >= 90) grade = 'A';
      else if (score >= 80) grade = 'B';
      else if (score >= 70) grade = 'C';
      else if (score >= 60) grade = 'D';
      else grade = 'F';
      
      return {
        score,
        grade,
        metrics: {
          todos: metrics.todos.count,
          fixmes: metrics.fixmes.count,
          hacks: metrics.hacks.count,
          largeScripts: metrics.largeScripts.count,
          deepNesting: metrics.deepNesting.count,
          testFiles: metrics.testCoverage.testCount,
          totalScripts: scripts.length
        },
        breakdown: {
          todoPenalty: -todoPenalty,
          fixmePenalty: -fixmePenalty,
          hackPenalty: -hackPenalty,
          largePenalty: -largePenalty,
          testBonus: metrics.testCoverage.hasTests ? Math.min(10, metrics.testCoverage.testCount * 2) : 0
        },
        issues: issues.slice(0, 50),
        recommendations: generateRecommendations(metrics, issues)
      };
    }
  },

  // Save/Load Trends
  {
    definition: {
      name: 'record_trends',
      description: 'Record current project metrics for trend tracking',
      category: 'analytics',
      tags: ['trends', 'history', 'tracking'],
      inputSchema: {
        type: 'object',
        properties: {}
      }
    },
    handler: async () => {
      // Get current metrics
      const scripts = await findFiles(WORKSPACE, '.gd');
      const scenes = await findFiles(WORKSPACE, '.tscn');
      
      let totalLines = 0;
      let todoCount = 0;
      
      for (const file of scripts) {
        const content = await readFileContent(file);
        if (!content) continue;
        const lines = content.split('\n');
        totalLines += lines.length;
        lines.forEach(line => {
          if (line.includes('# TODO') || line.includes('# FIXME') || line.includes('# HACK')) {
            todoCount++;
          }
        });
      }
      
      const entry = {
        timestamp: Date.now(),
        date: new Date().toISOString().split('T')[0],
        scripts: scripts.length,
        scenes: scenes.length,
        lines: totalLines,
        todos: todoCount
      };
      
      // Load existing trends
      let trends = { entries: [] };
      try {
        const data = await readFileContent(TRENDS_FILE);
        if (data) trends = JSON.parse(data);
      } catch {}
      
      // Add new entry (limit to last 90 days)
      trends.entries.push(entry);
      trends.entries = trends.entries.slice(-90);
      
      // Save
      await fs.writeFile(TRENDS_FILE, JSON.stringify(trends, null, 2));
      
      return {
        recorded: entry,
        totalEntries: trends.entries.length,
        oldestEntry: trends.entries[0]?.date,
        newestEntry: trends.entries[trends.entries.length - 1]?.date
      };
    }
  },

  // Get Trends
  {
    definition: {
      name: 'get_trends',
      description: 'Get historical project metrics for trend analysis',
      category: 'analytics',
      tags: ['trends', 'history', 'analytics'],
      inputSchema: {
        type: 'object',
        properties: {
          days: { type: 'number', description: 'Number of days to retrieve (default: 30)' }
        }
      }
    },
    handler: async (args) => {
      const days = args.days || 30;
      
      let trends = { entries: [] };
      try {
        const data = await readFileContent(TRENDS_FILE);
        if (data) trends = JSON.parse(data);
      } catch {}
      
      const cutoff = Date.now() - (days * 24 * 60 * 60 * 1000);
      const filtered = trends.entries.filter(e => e.timestamp >= cutoff);
      
      // Calculate changes
      let changes = null;
      if (filtered.length >= 2) {
        const first = filtered[0];
        const last = filtered[filtered.length - 1];
        changes = {
          scripts: last.scripts - first.scripts,
          scenes: last.scenes - first.scenes,
          lines: last.lines - first.lines,
          todos: last.todos - first.todos,
          period: `${first.date} to ${last.date}`
        };
      }
      
      return {
        days,
        entries: filtered,
        changes,
        hasData: filtered.length > 0
      };
    }
  },

  // Dependency Graph
  {
    definition: {
      name: 'dependency_graph',
      description: 'Generate dependency graph showing which scripts depend on which',
      category: 'analysis',
      tags: ['dependencies', 'graph', 'imports'],
      inputSchema: {
        type: 'object',
        properties: {
          focusFile: { type: 'string', description: 'Focus on dependencies of a specific file (optional)' }
        }
      }
    },
    handler: async (args) => {
      const scripts = await findFiles(WORKSPACE, '.gd');
      const dependencies = {};
      const reverseDeps = {};
      
      for (const file of scripts) {
        const content = await readFileContent(file);
        if (!content) continue;
        
        const relativePath = path.relative(WORKSPACE, file).replace(/\\/g, '/');
        dependencies[relativePath] = [];
        
        // Find preload/load statements
        const regex = /(?:preload|load)\s*\(\s*["']res:\/\/([^"']+)["']\s*\)/g;
        let match;
        while ((match = regex.exec(content)) !== null) {
          const dep = match[1];
          dependencies[relativePath].push(dep);
          
          if (!reverseDeps[dep]) reverseDeps[dep] = [];
          reverseDeps[dep].push(relativePath);
        }
      }
      
      // If focusing on a specific file
      if (args.focusFile) {
        const focus = args.focusFile.replace(/\\/g, '/');
        return {
          file: focus,
          dependsOn: dependencies[focus] || [],
          dependedBy: reverseDeps[focus] || [],
          depth: await calculateDependencyDepth(focus, dependencies)
        };
      }
      
      // Calculate statistics
      const stats = {
        totalFiles: Object.keys(dependencies).length,
        filesWithDeps: Object.values(dependencies).filter(d => d.length > 0).length,
        mostDependencies: null,
        mostDepended: null
      };
      
      // Find files with most dependencies
      let maxDeps = 0;
      for (const [file, deps] of Object.entries(dependencies)) {
        if (deps.length > maxDeps) {
          maxDeps = deps.length;
          stats.mostDependencies = { file, count: deps.length };
        }
      }
      
      // Find most depended upon
      let maxReverseDeps = 0;
      for (const [file, deps] of Object.entries(reverseDeps)) {
        if (deps.length > maxReverseDeps) {
          maxReverseDeps = deps.length;
          stats.mostDepended = { file, count: deps.length };
        }
      }
      
      return {
        stats,
        dependencies: Object.fromEntries(
          Object.entries(dependencies).filter(([_, deps]) => deps.length > 0)
        ),
        reverseDependencies: reverseDeps
      };
    }
  },

  // Scene Tree Parser
  {
    definition: {
      name: 'scene_tree',
      description: 'Parse and display the node tree structure of a scene',
      category: 'godot',
      tags: ['scene', 'tree', 'nodes'],
      inputSchema: {
        type: 'object',
        properties: {
          scenePath: { type: 'string', description: 'Path to the .tscn file' }
        },
        required: ['scenePath']
      }
    },
    handler: async (args) => {
      const safePath = validatePath(args.scenePath);
      const content = await readFileContent(safePath);
      
      if (!content) {
        throw new Error(`Scene not found: ${args.scenePath}`);
      }
      
      const nodes = [];
      const nodeRegex = /\[node\s+name="([^"]+)"(?:\s+type="([^"]+)")?(?:\s+parent="([^"]*)")?(?:\s+instance=ExtResource\(\s*"([^"]+)"\s*\))?\]/g;
      
      let match;
      while ((match = nodeRegex.exec(content)) !== null) {
        nodes.push({
          name: match[1],
          type: match[2] || 'Instance',
          parent: match[3] || null,
          instance: match[4] || null,
          path: match[3] ? `${match[3]}/${match[1]}` : match[1]
        });
      }
      
      // Build tree structure
      const root = nodes.find(n => n.parent === null);
      const tree = root ? buildTree(root, nodes) : null;
      
      return {
        scenePath: args.scenePath,
        nodeCount: nodes.length,
        root: tree,
        nodes,
        nodeTypes: [...new Set(nodes.map(n => n.type))].sort()
      };
    }
  },

  // Custom Command Executor (with security restrictions)
  {
    definition: {
      name: 'run_command',
      description: 'Run a pre-approved command in the workspace (limited to safe commands)',
      category: 'system',
      tags: ['command', 'terminal', 'execute'],
      inputSchema: {
        type: 'object',
        properties: {
          command: { 
            type: 'string', 
            description: 'Command to run',
            enum: ['ls', 'pwd', 'cat', 'head', 'tail', 'wc', 'find', 'grep', 'du', 'tree']
          },
          args: { type: 'string', description: 'Command arguments' }
        },
        required: ['command']
      }
    },
    handler: async (args) => {
      const allowedCommands = ['ls', 'pwd', 'cat', 'head', 'tail', 'wc', 'find', 'grep', 'du', 'tree'];
      
      if (!allowedCommands.includes(args.command)) {
        throw new Error(`Command not allowed: ${args.command}`);
      }
      
      // Additional security: sanitize args
      const sanitizedArgs = (args.args || '')
        .replace(/[;&|`$()]/g, '') // Remove dangerous characters
        .split(' ')
        .filter(a => !a.startsWith('-') || /^-[a-zA-Z]{1,3}$/.test(a)); // Only simple flags
      
      const result = await execCommand(args.command, sanitizedArgs, { timeout: 10000 });
      
      return {
        command: args.command,
        args: sanitizedArgs.join(' '),
        exitCode: result.code,
        stdout: result.stdout.substring(0, 50000),
        stderr: result.stderr.substring(0, 5000)
      };
    }
  }
];

// Helper functions
function generateRecommendations(metrics, issues) {
  const recommendations = [];
  
  if (metrics.fixmes.count > 0) {
    recommendations.push({
      priority: 'high',
      message: `Address ${metrics.fixmes.count} FIXME comments - these indicate broken or incomplete code`
    });
  }
  
  if (metrics.hacks.count > 3) {
    recommendations.push({
      priority: 'medium',
      message: `Review ${metrics.hacks.count} HACK comments - consider refactoring these workarounds`
    });
  }
  
  if (metrics.largeScripts.count > 5) {
    recommendations.push({
      priority: 'medium',
      message: `${metrics.largeScripts.count} scripts exceed 500 lines - consider splitting into smaller files`
    });
  }
  
  if (!metrics.testCoverage.hasTests) {
    recommendations.push({
      priority: 'low',
      message: 'Add unit tests to improve code quality and catch regressions'
    });
  }
  
  if (metrics.todos.count > 20) {
    recommendations.push({
      priority: 'low',
      message: `${metrics.todos.count} TODO items need attention - consider scheduling time to address them`
    });
  }
  
  return recommendations;
}

async function calculateDependencyDepth(file, dependencies, visited = new Set()) {
  if (visited.has(file)) return 0;
  visited.add(file);
  
  const deps = dependencies[file] || [];
  if (deps.length === 0) return 0;
  
  let maxDepth = 0;
  for (const dep of deps) {
    const depth = await calculateDependencyDepth(dep, dependencies, visited);
    maxDepth = Math.max(maxDepth, depth + 1);
  }
  
  return maxDepth;
}

function buildTree(node, allNodes) {
  const children = allNodes.filter(n => n.parent === node.path || (node.parent === null && n.parent === '.'));
  return {
    ...node,
    children: children.map(c => buildTree(c, allNodes))
  };
}

// ==================== PLUGIN EXPORT ====================

export function register(pluginManager) {
  tools.forEach(tool => {
    pluginManager.registerTool(tool.definition, tool.handler);
  });
  
  console.log(`[Dashboard Tools] Registered ${tools.length} tools`);
}

export default { register };
