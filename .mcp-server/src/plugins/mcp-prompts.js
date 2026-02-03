/**
 * MCP Prompts Plugin
 * Predefined prompt templates for common Godot development tasks
 */

// ==================== PROMPT DEFINITIONS ====================

const prompts = [
  // Code Review Prompt
  {
    name: 'godot_code_review',
    description: 'Review GDScript code for best practices and issues',
    arguments: [
      {
        name: 'script_path',
        description: 'Path to the GDScript file to review',
        required: true
      }
    ],
    handler: async (args) => {
      return {
        messages: [
          {
            role: 'user',
            content: {
              type: 'text',
              text: `Please review the GDScript file at ${args.script_path} and check for:

1. **Code Style**
   - Proper naming conventions (snake_case for variables/functions, PascalCase for classes)
   - Type hints on function parameters and return values
   - Consistent indentation

2. **Best Practices**
   - Proper signal usage (past tense naming)
   - Appropriate use of @onready vs get_node in _ready
   - Avoiding hardcoded values (use constants/exports)

3. **Performance**
   - Unnecessary _process calls
   - Node lookups that could be cached
   - Areas that could benefit from object pooling

4. **Potential Bugs**
   - Null reference risks
   - Missing null checks
   - Signal connections that might fail

Please provide specific line numbers and suggestions for improvements.`
            }
          }
        ]
      };
    }
  },
  
  // Scene Analysis Prompt
  {
    name: 'godot_scene_analysis',
    description: 'Analyze a scene file structure and provide recommendations',
    arguments: [
      {
        name: 'scene_path',
        description: 'Path to the .tscn scene file',
        required: true
      }
    ],
    handler: async (args) => {
      return {
        messages: [
          {
            role: 'user',
            content: {
              type: 'text',
              text: `Please analyze the scene file at ${args.scene_path} and provide:

1. **Structure Overview**
   - Node hierarchy visualization
   - External dependencies (scripts, resources)
   - Signal connections

2. **Organization Check**
   - Are nodes logically grouped?
   - Is the hierarchy depth appropriate?
   - Are there any orphaned or unused nodes?

3. **Performance Considerations**
   - Too many nodes in the tree?
   - Heavy resources that could be lazy-loaded?
   - Nodes that could be instanced from separate scenes?

4. **Recommendations**
   - Suggestions for better organization
   - Potential optimizations
   - Best practices for similar scenes`
            }
          }
        ]
      };
    }
  },
  
  // Bug Fix Prompt
  {
    name: 'godot_debug_help',
    description: 'Help debug a specific issue in Godot code',
    arguments: [
      {
        name: 'error_message',
        description: 'The error message or description of the issue',
        required: true
      },
      {
        name: 'script_path',
        description: 'Path to the relevant script file',
        required: false
      }
    ],
    handler: async (args) => {
      const scriptContext = args.script_path 
        ? `The issue is in the script at ${args.script_path}.`
        : 'Please help identify which file might be causing this.';
      
      return {
        messages: [
          {
            role: 'user',
            content: {
              type: 'text',
              text: `I'm encountering an issue in my Godot 4.x project:

**Error/Issue:**
${args.error_message}

${scriptContext}

Please help me:
1. Understand what's causing this error
2. Identify the root cause
3. Provide a fix with code examples
4. Explain how to prevent this in the future

If you need to see specific code, please ask.`
            }
          }
        ]
      };
    }
  },
  
  // Feature Implementation Prompt
  {
    name: 'godot_implement_feature',
    description: 'Get guidance on implementing a game feature',
    arguments: [
      {
        name: 'feature_description',
        description: 'Description of the feature to implement',
        required: true
      },
      {
        name: 'related_systems',
        description: 'Existing systems this feature should integrate with',
        required: false
      }
    ],
    handler: async (args) => {
      const systemsContext = args.related_systems
        ? `\n\n**Related Systems:** ${args.related_systems}`
        : '';
      
      return {
        messages: [
          {
            role: 'user',
            content: {
              type: 'text',
              text: `I want to implement a new feature in my Godot 4.x game:

**Feature:** ${args.feature_description}${systemsContext}

Please provide:
1. **Architecture Overview**
   - What nodes/scenes will be needed
   - What scripts to create
   - How it integrates with existing systems

2. **Implementation Steps**
   - Step-by-step guide
   - Code examples for key parts
   - Signal flow diagram

3. **Best Practices**
   - Common pitfalls to avoid
   - Performance considerations
   - Testing recommendations

4. **Example Code**
   - Core script structure
   - Key function implementations`
            }
          }
        ]
      };
    }
  },
  
  // Optimization Prompt
  {
    name: 'godot_optimize',
    description: 'Get optimization suggestions for a script or system',
    arguments: [
      {
        name: 'target',
        description: 'Script path or system name to optimize',
        required: true
      },
      {
        name: 'issue',
        description: 'Specific performance issue (e.g., "slow frame rate", "high memory")',
        required: false
      }
    ],
    handler: async (args) => {
      const issueContext = args.issue
        ? `\n\n**Specific Issue:** ${args.issue}`
        : '';
      
      return {
        messages: [
          {
            role: 'user',
            content: {
              type: 'text',
              text: `Please help optimize: ${args.target}${issueContext}

Analyze and provide:
1. **Performance Audit**
   - Identify bottlenecks
   - Memory usage concerns
   - CPU-intensive operations

2. **Optimization Strategies**
   - Object pooling opportunities
   - Caching recommendations
   - Algorithm improvements

3. **Godot-Specific Tips**
   - Engine features to leverage
   - Built-in optimizations
   - LOD and culling strategies

4. **Before/After Code**
   - Show problematic code
   - Provide optimized version
   - Explain the improvements`
            }
          }
        ]
      };
    }
  },
  
  // Documentation Generator Prompt
  {
    name: 'godot_document_class',
    description: 'Generate documentation for a GDScript class',
    arguments: [
      {
        name: 'script_path',
        description: 'Path to the script to document',
        required: true
      },
      {
        name: 'format',
        description: 'Documentation format (markdown, xml-doc)',
        required: false
      }
    ],
    handler: async (args) => {
      const format = args.format || 'markdown';
      
      return {
        messages: [
          {
            role: 'user',
            content: {
              type: 'text',
              text: `Please generate ${format} documentation for the script at ${args.script_path}.

Include:
1. **Class Overview**
   - Purpose and responsibility
   - Inheritance hierarchy
   - Related classes

2. **Properties**
   - All exported variables with descriptions
   - Internal state variables

3. **Signals**
   - Each signal with its purpose
   - When it's emitted
   - Expected parameters

4. **Methods**
   - Public API documentation
   - Parameter descriptions
   - Return value documentation
   - Example usage

5. **Usage Examples**
   - How to instantiate/use this class
   - Common patterns
   - Integration with other systems`
            }
          }
        ]
      };
    }
  },
  
  // Refactoring Prompt
  {
    name: 'godot_refactor',
    description: 'Get refactoring suggestions for improving code quality',
    arguments: [
      {
        name: 'script_path',
        description: 'Path to the script to refactor',
        required: true
      },
      {
        name: 'goal',
        description: 'Refactoring goal (e.g., "reduce complexity", "improve testability")',
        required: false
      }
    ],
    handler: async (args) => {
      const goalContext = args.goal
        ? `\n\n**Refactoring Goal:** ${args.goal}`
        : '';
      
      return {
        messages: [
          {
            role: 'user',
            content: {
              type: 'text',
              text: `Please suggest refactoring for ${args.script_path}${goalContext}

Analyze and provide:
1. **Code Smells**
   - Long functions
   - Duplicate code
   - High coupling
   - Magic numbers/strings

2. **Design Patterns**
   - Applicable patterns
   - How to implement them
   - Benefits

3. **Separation of Concerns**
   - What to extract into separate scripts
   - How to decouple components
   - Signal-based communication opportunities

4. **Step-by-Step Refactoring**
   - Safe incremental changes
   - Testing between steps
   - Final clean architecture`
            }
          }
        ]
      };
    }
  },
  
  // Project Setup Prompt
  {
    name: 'godot_project_setup',
    description: 'Get guidance on setting up a new Godot project structure',
    arguments: [
      {
        name: 'game_type',
        description: 'Type of game (e.g., "2D platformer", "top-down shooter")',
        required: true
      },
      {
        name: 'features',
        description: 'Key features needed (comma-separated)',
        required: false
      }
    ],
    handler: async (args) => {
      const featuresContext = args.features
        ? `\n\n**Required Features:** ${args.features}`
        : '';
      
      return {
        messages: [
          {
            role: 'user',
            content: {
              type: 'text',
              text: `Help me set up a Godot 4.x project for a ${args.game_type}${featuresContext}

Please provide:
1. **Project Structure**
   - Recommended folder organization
   - Naming conventions
   - File organization best practices

2. **Core Systems**
   - What autoloads/singletons to create
   - Essential manager scripts
   - Scene hierarchy recommendations

3. **Initial Scripts**
   - Game manager template
   - Player controller template
   - Scene transition system

4. **Configuration**
   - project.godot settings
   - Input map suggestions
   - Export settings

5. **Development Workflow**
   - Testing strategy
   - Version control tips
   - Documentation approach`
            }
          }
        ]
      };
    }
  }
];

// ==================== PLUGIN EXPORT ====================

export function register(pluginManager) {
  for (const prompt of prompts) {
    pluginManager.registerPrompt(prompt);
  }
}

export default { register };
