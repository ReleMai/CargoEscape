/**
 * Plugin System for MCP Tools
 * Allows dynamic loading of tool plugins without modifying core server
 */

import fs from 'fs/promises';
import path from 'path';
import { logger } from './logger.js';

class PluginManager {
  constructor() {
    this.tools = new Map();
    this.resources = new Map();
    this.prompts = new Map();
    this.hooks = new Map();
    this.plugins = new Map();
  }
  
  /**
   * Register a tool
   */
  registerTool(definition, handler) {
    if (this.tools.has(definition.name)) {
      logger.warn(`Tool ${definition.name} is being overwritten`);
    }
    
    this.tools.set(definition.name, {
      definition,
      handler,
      category: definition.category || 'general',
      tags: definition.tags || []
    });
    
    logger.debug(`Registered tool: ${definition.name}`);
  }
  
  /**
   * Register multiple tools at once
   */
  registerTools(toolsArray) {
    for (const { definition, handler } of toolsArray) {
      this.registerTool(definition, handler);
    }
  }
  
  /**
   * Register a resource
   */
  registerResource(definition, handler) {
    this.resources.set(definition.uri, {
      definition,
      handler
    });
    logger.debug(`Registered resource: ${definition.uri}`);
  }
  
  /**
   * Register a prompt template
   */
  registerPrompt(definition, handler) {
    this.prompts.set(definition.name, {
      definition,
      handler
    });
    logger.debug(`Registered prompt: ${definition.name}`);
  }
  
  /**
   * Register a hook for extensibility
   */
  registerHook(event, callback) {
    if (!this.hooks.has(event)) {
      this.hooks.set(event, []);
    }
    this.hooks.get(event).push(callback);
  }
  
  /**
   * Execute hooks for an event
   */
  async executeHooks(event, context) {
    const hooks = this.hooks.get(event) || [];
    for (const hook of hooks) {
      try {
        await hook(context);
      } catch (error) {
        logger.error(`Hook error for ${event}`, { error: error.message });
      }
    }
  }
  
  /**
   * Get all tool definitions
   */
  getToolDefinitions() {
    return Array.from(this.tools.values()).map(t => t.definition);
  }
  
  /**
   * Get tools by category
   */
  getToolsByCategory() {
    const categories = {};
    
    for (const [name, tool] of this.tools) {
      const category = tool.category;
      if (!categories[category]) {
        categories[category] = [];
      }
      categories[category].push({
        name,
        description: tool.definition.description,
        tags: tool.tags
      });
    }
    
    return categories;
  }
  
  /**
   * Execute a tool
   */
  async executeTool(name, args, context = {}) {
    const tool = this.tools.get(name);
    
    if (!tool) {
      throw new Error(`Unknown tool: ${name}`);
    }
    
    // Execute pre-hooks
    await this.executeHooks('beforeToolExecution', { tool: name, args, context });
    
    const startTime = Date.now();
    let result;
    let error;
    
    try {
      result = await tool.handler(args, context);
    } catch (err) {
      error = err;
      throw err;
    } finally {
      const duration = Date.now() - startTime;
      
      // Execute post-hooks
      await this.executeHooks('afterToolExecution', {
        tool: name,
        args,
        context,
        result,
        error,
        duration
      });
    }
    
    return result;
  }
  
  /**
   * Get all resource definitions
   */
  getResourceDefinitions() {
    return Array.from(this.resources.values()).map(r => r.definition);
  }
  
  /**
   * Read a resource
   */
  async readResource(uri) {
    const resource = this.resources.get(uri);
    
    if (!resource) {
      throw new Error(`Unknown resource: ${uri}`);
    }
    
    return resource.handler(uri);
  }
  
  /**
   * Get all prompt definitions
   */
  getPromptDefinitions() {
    return Array.from(this.prompts.values()).map(p => p.definition);
  }
  
  /**
   * Get a prompt
   */
  async getPrompt(name, args = {}) {
    const prompt = this.prompts.get(name);
    
    if (!prompt) {
      throw new Error(`Unknown prompt: ${name}`);
    }
    
    return prompt.handler(args);
  }
  
  /**
   * Load a plugin module
   */
  async loadPlugin(pluginPath) {
    try {
      const plugin = await import(pluginPath);
      
      if (plugin.register) {
        await plugin.register(this);
        logger.info(`Loaded plugin: ${pluginPath}`);
      }
      
      this.plugins.set(pluginPath, plugin);
      return true;
    } catch (error) {
      logger.error(`Failed to load plugin: ${pluginPath}`, { error: error.message });
      return false;
    }
  }
  
  /**
   * Load all plugins from a directory
   */
  async loadPluginsFromDirectory(dir) {
    try {
      const entries = await fs.readdir(dir, { withFileTypes: true });
      let loaded = 0;
      
      for (const entry of entries) {
        if (entry.isFile() && entry.name.endsWith('.js') && !entry.name.startsWith('_')) {
          const pluginPath = path.join(dir, entry.name);
          if (await this.loadPlugin(pluginPath)) {
            loaded++;
          }
        }
      }
      
      logger.info(`Loaded ${loaded} plugins from ${dir}`);
      return loaded;
    } catch (error) {
      logger.warn(`Could not load plugins from ${dir}`, { error: error.message });
      return 0;
    }
  }
  
  /**
   * Get all tools (alias for compatibility)
   */
  getAllTools() {
    return Array.from(this.tools.values());
  }
  
  /**
   * Get a specific tool
   */
  getTool(name) {
    return this.tools.get(name);
  }
  
  /**
   * Get all resources (alias for compatibility)
   */
  getAllResources() {
    return Array.from(this.resources.values()).map(r => r.definition);
  }
  
  /**
   * Get a specific resource
   */
  getResource(uri) {
    return this.resources.get(uri);
  }
  
  /**
   * Get all prompts (alias for compatibility)
   */
  getAllPrompts() {
    return Array.from(this.prompts.values()).map(p => p.definition);
  }
  
  /**
   * Get a specific prompt
   */
  getPrompt(name) {
    return this.prompts.get(name);
  }
  
  /**
   * Get plugin statistics
   */
  getStats() {
    return {
      tools: this.tools.size,
      resources: this.resources.size,
      prompts: this.prompts.size,
      plugins: this.plugins.size,
      categories: Object.keys(this.getToolsByCategory())
    };
  }
}

export const pluginManager = new PluginManager();
export default pluginManager;
