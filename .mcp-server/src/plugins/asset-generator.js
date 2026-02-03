/**
 * Asset Generator Plugin
 * Generates SVG assets for Godot game items, icons, and sprites
 */

import fs from 'fs/promises';
import path from 'path';

const WORKSPACE = process.env.WORKSPACE_PATH || '/workspace';
const ASSETS_PATH = path.join(WORKSPACE, 'assets', 'sprites');

// ==================== SVG TEMPLATES ====================

const SVG_TEMPLATES = {
  // Item icon templates by category
  item_scrap: (params) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="${params.size || 64}" height="${params.size || 64}">
  <defs>
    <linearGradient id="scrapGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:${params.primaryColor || '#6b7280'};stop-opacity:1" />
      <stop offset="100%" style="stop-color:${params.secondaryColor || '#374151'};stop-opacity:1" />
    </linearGradient>
    <filter id="shadow"><feDropShadow dx="1" dy="2" stdDeviation="2" flood-opacity="0.3"/></filter>
  </defs>
  <rect x="8" y="12" width="48" height="40" rx="4" fill="url(#scrapGrad)" filter="url(#shadow)"/>
  <rect x="12" y="16" width="18" height="8" rx="2" fill="${params.accentColor || '#9ca3af'}" opacity="0.8"/>
  <rect x="34" y="16" width="18" height="8" rx="2" fill="${params.accentColor || '#9ca3af'}" opacity="0.6"/>
  <circle cx="20" cy="36" r="6" fill="${params.accentColor || '#9ca3af'}" opacity="0.7"/>
  <circle cx="44" cy="38" r="4" fill="${params.accentColor || '#9ca3af'}" opacity="0.5"/>
</svg>`,

  item_component: (params) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="${params.size || 64}" height="${params.size || 64}">
  <defs>
    <linearGradient id="compGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:${params.primaryColor || '#10b981'};stop-opacity:1" />
      <stop offset="100%" style="stop-color:${params.secondaryColor || '#047857'};stop-opacity:1" />
    </linearGradient>
    <filter id="glow"><feGaussianBlur stdDeviation="2" result="coloredBlur"/><feMerge><feMergeNode in="coloredBlur"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
  </defs>
  <rect x="10" y="20" width="44" height="24" rx="3" fill="#1f2937"/>
  <rect x="14" y="24" width="36" height="16" fill="#0f172a"/>
  <rect x="18" y="28" width="6" height="8" fill="${params.primaryColor || '#10b981'}" filter="url(#glow)"/>
  <rect x="26" y="28" width="6" height="8" fill="${params.primaryColor || '#10b981'}" filter="url(#glow)"/>
  <rect x="34" y="28" width="6" height="8" fill="${params.primaryColor || '#10b981'}" filter="url(#glow)"/>
  <rect x="42" y="28" width="4" height="8" fill="${params.accentColor || '#fbbf24'}"/>
  <line x1="20" y1="12" x2="20" y2="20" stroke="#6b7280" stroke-width="2"/>
  <line x1="32" y1="12" x2="32" y2="20" stroke="#6b7280" stroke-width="2"/>
  <line x1="44" y1="12" x2="44" y2="20" stroke="#6b7280" stroke-width="2"/>
  <line x1="20" y1="44" x2="20" y2="52" stroke="#6b7280" stroke-width="2"/>
  <line x1="32" y1="44" x2="32" y2="52" stroke="#6b7280" stroke-width="2"/>
  <line x1="44" y1="44" x2="44" y2="52" stroke="#6b7280" stroke-width="2"/>
</svg>`,

  item_valuable: (params) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="${params.size || 64}" height="${params.size || 64}">
  <defs>
    <linearGradient id="gemGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:${params.primaryColor || '#3b82f6'};stop-opacity:1" />
      <stop offset="50%" style="stop-color:${params.secondaryColor || '#1d4ed8'};stop-opacity:1" />
      <stop offset="100%" style="stop-color:${params.primaryColor || '#3b82f6'};stop-opacity:1" />
    </linearGradient>
    <filter id="gemGlow"><feGaussianBlur stdDeviation="3" result="coloredBlur"/><feMerge><feMergeNode in="coloredBlur"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
  </defs>
  <polygon points="32,8 52,24 44,56 20,56 12,24" fill="url(#gemGrad)" filter="url(#gemGlow)"/>
  <polygon points="32,12 48,24 42,52 22,52 16,24" fill="${params.primaryColor || '#3b82f6'}" opacity="0.6"/>
  <polygon points="32,8 32,24 20,56 12,24" fill="white" opacity="0.2"/>
</svg>`,

  item_epic: (params) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="${params.size || 64}" height="${params.size || 64}">
  <defs>
    <linearGradient id="epicGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:${params.primaryColor || '#8b5cf6'};stop-opacity:1" />
      <stop offset="100%" style="stop-color:${params.secondaryColor || '#6d28d9'};stop-opacity:1" />
    </linearGradient>
    <filter id="epicGlow"><feGaussianBlur stdDeviation="4" result="coloredBlur"/><feMerge><feMergeNode in="coloredBlur"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
  </defs>
  <circle cx="32" cy="32" r="24" fill="url(#epicGrad)" filter="url(#epicGlow)"/>
  <circle cx="32" cy="32" r="18" fill="${params.secondaryColor || '#6d28d9'}"/>
  <path d="M32 14 L36 28 L50 28 L38 36 L42 50 L32 42 L22 50 L26 36 L14 28 L28 28 Z" fill="${params.accentColor || '#fbbf24'}" filter="url(#epicGlow)"/>
  <circle cx="32" cy="32" r="6" fill="white" opacity="0.3"/>
</svg>`,

  item_legendary: (params) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="${params.size || 64}" height="${params.size || 64}">
  <defs>
    <linearGradient id="legendGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:${params.primaryColor || '#f59e0b'};stop-opacity:1" />
      <stop offset="50%" style="stop-color:${params.secondaryColor || '#d97706'};stop-opacity:1" />
      <stop offset="100%" style="stop-color:${params.primaryColor || '#f59e0b'};stop-opacity:1" />
    </linearGradient>
    <filter id="legendGlow"><feGaussianBlur stdDeviation="4" result="coloredBlur"/><feMerge><feMergeNode in="coloredBlur"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
    <radialGradient id="aura">
      <stop offset="0%" style="stop-color:${params.primaryColor || '#f59e0b'};stop-opacity:0.6"/>
      <stop offset="100%" style="stop-color:${params.primaryColor || '#f59e0b'};stop-opacity:0"/>
    </radialGradient>
  </defs>
  <circle cx="32" cy="32" r="30" fill="url(#aura)"/>
  <polygon points="32,4 38,22 58,22 42,34 48,54 32,42 16,54 22,34 6,22 26,22" fill="url(#legendGrad)" filter="url(#legendGlow)"/>
  <polygon points="32,10 36,22 50,22 38,32 42,46 32,38 22,46 26,32 14,22 28,22" fill="${params.secondaryColor || '#d97706'}"/>
  <circle cx="32" cy="28" r="4" fill="white" opacity="0.5"/>
</svg>`,

  module_engine: (params) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="${params.size || 64}" height="${params.size || 64}">
  <defs>
    <linearGradient id="engineGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:${params.primaryColor || '#3b82f6'};stop-opacity:1" />
      <stop offset="100%" style="stop-color:${params.secondaryColor || '#1e40af'};stop-opacity:1" />
    </linearGradient>
  </defs>
  <rect x="8" y="16" width="48" height="32" rx="4" fill="#374151"/>
  <rect x="12" y="20" width="40" height="24" fill="#1f2937"/>
  <circle cx="24" cy="32" r="8" fill="url(#engineGrad)"/>
  <circle cx="40" cy="32" r="8" fill="url(#engineGrad)"/>
  <circle cx="24" cy="32" r="4" fill="${params.accentColor || '#60a5fa'}"/>
  <circle cx="40" cy="32" r="4" fill="${params.accentColor || '#60a5fa'}"/>
  <rect x="30" y="26" width="4" height="12" fill="${params.accentColor || '#60a5fa'}"/>
  <polygon points="4,28 8,24 8,40 4,36" fill="${params.primaryColor || '#3b82f6'}"/>
  <polygon points="60,28 56,24 56,40 60,36" fill="${params.primaryColor || '#3b82f6'}"/>
</svg>`,

  module_shield: (params) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="${params.size || 64}" height="${params.size || 64}">
  <defs>
    <linearGradient id="shieldGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" style="stop-color:${params.primaryColor || '#06b6d4'};stop-opacity:1" />
      <stop offset="100%" style="stop-color:${params.secondaryColor || '#0891b2'};stop-opacity:1" />
    </linearGradient>
    <filter id="shieldGlow"><feGaussianBlur stdDeviation="3"/></filter>
  </defs>
  <path d="M32 6 L54 16 L54 32 C54 48 32 58 32 58 C32 58 10 48 10 32 L10 16 Z" fill="url(#shieldGrad)" filter="url(#shieldGlow)"/>
  <path d="M32 10 L50 18 L50 32 C50 44 32 54 32 54 C32 54 14 44 14 32 L14 18 Z" fill="${params.secondaryColor || '#0891b2'}"/>
  <path d="M32 14 L46 22 L46 32 C46 42 32 50 32 50" fill="white" opacity="0.2"/>
  <circle cx="32" cy="32" r="8" fill="${params.accentColor || '#22d3ee'}" opacity="0.8"/>
</svg>`,

  module_weapon: (params) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="${params.size || 64}" height="${params.size || 64}">
  <defs>
    <linearGradient id="weaponGrad" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" style="stop-color:${params.primaryColor || '#ef4444'};stop-opacity:1" />
      <stop offset="100%" style="stop-color:${params.secondaryColor || '#b91c1c'};stop-opacity:1" />
    </linearGradient>
  </defs>
  <rect x="4" y="26" width="40" height="12" rx="2" fill="#374151"/>
  <rect x="8" y="28" width="32" height="8" fill="#1f2937"/>
  <rect x="44" y="22" width="16" height="20" rx="2" fill="url(#weaponGrad)"/>
  <circle cx="52" cy="32" r="4" fill="${params.accentColor || '#fca5a5'}"/>
  <rect x="12" y="30" width="24" height="4" fill="${params.primaryColor || '#ef4444'}" opacity="0.6"/>
</svg>`,

  ship_shuttle: (params) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 64" width="${params.width || 128}" height="${params.height || 64}">
  <defs>
    <linearGradient id="hullGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" style="stop-color:${params.hullColor || '#64748b'};stop-opacity:1" />
      <stop offset="100%" style="stop-color:${params.hullColorDark || '#475569'};stop-opacity:1" />
    </linearGradient>
  </defs>
  <ellipse cx="64" cy="32" rx="56" ry="24" fill="url(#hullGrad)"/>
  <ellipse cx="64" cy="32" rx="48" ry="18" fill="${params.interiorColor || '#334155'}"/>
  <rect x="20" y="26" width="20" height="12" rx="2" fill="${params.windowColor || '#0ea5e9'}" opacity="0.8"/>
  <rect x="88" y="26" width="20" height="12" rx="2" fill="${params.windowColor || '#0ea5e9'}" opacity="0.8"/>
  <ellipse cx="64" cy="32" rx="16" ry="10" fill="${params.accentColor || '#f59e0b'}"/>
  <polygon points="8,32 4,28 4,36" fill="${params.engineColor || '#3b82f6'}"/>
  <polygon points="120,32 124,28 124,36" fill="${params.engineColor || '#3b82f6'}"/>
</svg>`,

  enemy_drone: (params) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="${params.size || 48}" height="${params.size || 48}">
  <defs>
    <linearGradient id="droneGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:${params.primaryColor || '#6b7280'};stop-opacity:1" />
      <stop offset="100%" style="stop-color:${params.secondaryColor || '#374151'};stop-opacity:1" />
    </linearGradient>
    <filter id="droneGlow"><feGaussianBlur stdDeviation="2"/></filter>
  </defs>
  <circle cx="24" cy="24" r="16" fill="url(#droneGrad)"/>
  <circle cx="24" cy="24" r="12" fill="${params.secondaryColor || '#374151'}"/>
  <circle cx="24" cy="24" r="6" fill="${params.eyeColor || '#ef4444'}" filter="url(#droneGlow)"/>
  <circle cx="24" cy="24" r="3" fill="white" opacity="0.5"/>
  <line x1="8" y1="24" x2="2" y2="24" stroke="${params.primaryColor || '#6b7280'}" stroke-width="3"/>
  <line x1="40" y1="24" x2="46" y2="24" stroke="${params.primaryColor || '#6b7280'}" stroke-width="3"/>
  <line x1="24" y1="8" x2="24" y2="2" stroke="${params.primaryColor || '#6b7280'}" stroke-width="3"/>
  <line x1="24" y1="40" x2="24" y2="46" stroke="${params.primaryColor || '#6b7280'}" stroke-width="3"/>
</svg>`,

  ui_button: (params) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 40" width="${params.width || 120}" height="${params.height || 40}">
  <defs>
    <linearGradient id="btnGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" style="stop-color:${params.primaryColor || '#6366f1'};stop-opacity:1" />
      <stop offset="100%" style="stop-color:${params.secondaryColor || '#4f46e5'};stop-opacity:1" />
    </linearGradient>
  </defs>
  <rect x="2" y="2" width="116" height="36" rx="6" fill="url(#btnGrad)"/>
  <rect x="2" y="2" width="116" height="18" rx="6" fill="white" opacity="0.1"/>
  <rect x="4" y="4" width="112" height="32" rx="4" fill="none" stroke="white" stroke-width="1" opacity="0.3"/>
</svg>`,

  placeholder: (params) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="${params.size || 64}" height="${params.size || 64}">
  <rect x="4" y="4" width="56" height="56" rx="8" fill="${params.primaryColor || '#374151'}" stroke="${params.borderColor || '#6b7280'}" stroke-width="2" stroke-dasharray="4 2"/>
  <text x="32" y="36" text-anchor="middle" fill="${params.textColor || '#9ca3af'}" font-family="sans-serif" font-size="10">${params.label || '?'}</text>
</svg>`
};

// ==================== COLOR PALETTES ====================

const RARITY_PALETTES = {
  common: { primary: '#6b7280', secondary: '#4b5563', accent: '#9ca3af', glow: 'none' },
  uncommon: { primary: '#10b981', secondary: '#059669', accent: '#34d399', glow: '#10b981' },
  rare: { primary: '#3b82f6', secondary: '#2563eb', accent: '#60a5fa', glow: '#3b82f6' },
  epic: { primary: '#8b5cf6', secondary: '#7c3aed', accent: '#a78bfa', glow: '#8b5cf6' },
  legendary: { primary: '#f59e0b', secondary: '#d97706', accent: '#fbbf24', glow: '#f59e0b' }
};

// ==================== SHAPE GENERATORS ====================

const SHAPE_GENERATORS = {
  crystal: (color) => `<polygon points="32,8 48,24 48,48 32,56 16,48 16,24" fill="${color}"/>`,
  circle: (color) => `<circle cx="32" cy="32" r="20" fill="${color}"/>`,
  hexagon: (color) => `<polygon points="32,8 52,18 52,46 32,56 12,46 12,18" fill="${color}"/>`,
  star: (color) => `<polygon points="32,8 38,24 56,24 42,36 48,52 32,42 16,52 22,36 8,24 26,24" fill="${color}"/>`,
  diamond: (color) => `<polygon points="32,4 56,32 32,60 8,32" fill="${color}"/>`,
  square: (color) => `<rect x="12" y="12" width="40" height="40" rx="4" fill="${color}"/>`,
  gear: (color) => `<path d="M32,12 L36,12 L38,18 L44,16 L48,22 L42,26 L44,32 L42,38 L48,42 L44,48 L38,46 L36,52 L32,52 L28,52 L26,46 L20,48 L16,42 L22,38 L20,32 L22,26 L16,22 L20,16 L26,18 L28,12 Z" fill="${color}"/>`
};

// ==================== HELPER FUNCTIONS ====================

function adjustColor(hex, amount) {
  const num = parseInt(hex.replace('#', ''), 16);
  const r = Math.max(0, Math.min(255, (num >> 16) + amount));
  const g = Math.max(0, Math.min(255, ((num >> 8) & 0x00FF) + amount));
  const b = Math.max(0, Math.min(255, (num & 0x0000FF) + amount));
  return '#' + (0x1000000 + (r << 16) + (g << 8) + b).toString(16).slice(1);
}

// ==================== TOOL DEFINITIONS ====================

const tools = [
  {
    definition: {
      name: 'generate_item_icon',
      description: 'Generate an SVG icon for a game item. Creates visually distinct icons based on item category and rarity.',
      inputSchema: {
        type: 'object',
        properties: {
          name: { type: 'string', description: 'Item name (used for filename)' },
          category: { 
            type: 'string', 
            enum: ['scrap', 'component', 'valuable', 'epic', 'legendary', 'module_engine', 'module_shield', 'module_weapon'],
            description: 'Item category determines base visual style'
          },
          rarity: { 
            type: 'string', 
            enum: ['common', 'uncommon', 'rare', 'epic', 'legendary'],
            description: 'Rarity affects color palette and effects'
          },
          primaryColor: { type: 'string', description: 'Override primary color (hex)' },
          secondaryColor: { type: 'string', description: 'Override secondary color (hex)' },
          accentColor: { type: 'string', description: 'Override accent color (hex)' },
          size: { type: 'number', description: 'Icon size in pixels (default: 64)' },
          savePath: { type: 'string', description: 'Custom save path relative to assets/sprites' }
        },
        required: ['name', 'category']
      }
    },
    handler: async (args) => {
      const { name, category, rarity = 'common', primaryColor, secondaryColor, accentColor, size = 64, savePath } = args;
      
      const templateKey = category.startsWith('module_') ? category : `item_${category}`;
      const template = SVG_TEMPLATES[templateKey] || SVG_TEMPLATES.placeholder;
      const palette = RARITY_PALETTES[rarity] || RARITY_PALETTES.common;
      
      const params = {
        size,
        primaryColor: primaryColor || palette.primary,
        secondaryColor: secondaryColor || palette.secondary,
        accentColor: accentColor || palette.accent
      };
      
      const svg = template(params);
      const filename = name.toLowerCase().replace(/[^a-z0-9]/g, '_') + '.svg';
      const folder = savePath || (category.startsWith('module_') ? 'modules' : 'items');
      const fullPath = path.join(ASSETS_PATH, folder, filename);
      
      await fs.mkdir(path.dirname(fullPath), { recursive: true });
      await fs.writeFile(fullPath, svg.trim());
      
      return {
        content: [{
          type: 'text',
          text: JSON.stringify({
            success: true,
            path: `res://assets/sprites/${folder}/${filename}`,
            absolutePath: fullPath,
            preview: svg.trim(),
            message: `Generated ${rarity} ${category} icon: ${filename}`
          }, null, 2)
        }]
      };
    }
  },
  
  {
    definition: {
      name: 'generate_procedural_icon',
      description: 'Generate a procedural icon using geometric shapes and colors.',
      inputSchema: {
        type: 'object',
        properties: {
          name: { type: 'string', description: 'Icon name (used for filename)' },
          shape: { 
            type: 'string', 
            enum: ['crystal', 'circle', 'hexagon', 'star', 'diamond', 'square', 'gear'],
            description: 'Base shape for the icon'
          },
          baseColor: { type: 'string', description: 'Primary color (hex)' },
          glowColor: { type: 'string', description: 'Glow effect color (hex, or "none")' },
          backgroundColor: { type: 'string', description: 'Background color (hex, or "transparent")' },
          size: { type: 'number', description: 'Icon size in pixels' },
          addDetails: { type: 'boolean', description: 'Add decorative details' },
          savePath: { type: 'string', description: 'Save path relative to assets/sprites' }
        },
        required: ['name', 'shape', 'baseColor']
      }
    },
    handler: async (args) => {
      const { name, shape, baseColor, glowColor = 'none', backgroundColor = 'transparent', size = 64, addDetails = true, savePath = 'generated' } = args;
      
      const shapeGen = SHAPE_GENERATORS[shape] || SHAPE_GENERATORS.circle;
      
      let svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="${size}" height="${size}">
  <defs>
    <linearGradient id="mainGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:${baseColor};stop-opacity:1" />
      <stop offset="100%" style="stop-color:${adjustColor(baseColor, -30)};stop-opacity:1" />
    </linearGradient>
    ${glowColor !== 'none' ? `<filter id="glow"><feGaussianBlur stdDeviation="3" result="coloredBlur"/><feMerge><feMergeNode in="coloredBlur"/><feMergeNode in="SourceGraphic"/></feMerge></filter>` : ''}
  </defs>`;
      
      if (backgroundColor !== 'transparent') {
        svg += `\n  <rect x="0" y="0" width="64" height="64" fill="${backgroundColor}"/>`;
      }
      
      const mainShape = shapeGen('url(#mainGrad)');
      svg += `\n  <g ${glowColor !== 'none' ? 'filter="url(#glow)"' : ''}>${mainShape}</g>`;
      
      if (addDetails) {
        svg += `\n  <circle cx="28" cy="28" r="6" fill="white" opacity="0.3"/>`;
        svg += `\n  <circle cx="26" cy="26" r="2" fill="white" opacity="0.5"/>`;
      }
      
      svg += '\n</svg>';
      
      const filename = name.toLowerCase().replace(/[^a-z0-9]/g, '_') + '.svg';
      const fullPath = path.join(ASSETS_PATH, savePath, filename);
      await fs.mkdir(path.dirname(fullPath), { recursive: true });
      await fs.writeFile(fullPath, svg);
      
      return {
        content: [{
          type: 'text',
          text: JSON.stringify({
            success: true,
            path: `res://assets/sprites/${savePath}/${filename}`,
            absolutePath: fullPath,
            preview: svg,
            message: `Generated procedural ${shape} icon: ${filename}`
          }, null, 2)
        }]
      };
    }
  },
  
  {
    definition: {
      name: 'generate_ship_sprite',
      description: 'Generate an SVG sprite for a ship',
      inputSchema: {
        type: 'object',
        properties: {
          name: { type: 'string', description: 'Ship name' },
          type: { type: 'string', enum: ['shuttle', 'hauler', 'frigate', 'destroyer'], description: 'Ship type template' },
          hullColor: { type: 'string', description: 'Main hull color (hex)' },
          accentColor: { type: 'string', description: 'Accent/trim color (hex)' },
          engineColor: { type: 'string', description: 'Engine glow color (hex)' },
          windowColor: { type: 'string', description: 'Window/cockpit color (hex)' },
          width: { type: 'number', description: 'Sprite width' },
          height: { type: 'number', description: 'Sprite height' }
        },
        required: ['name', 'type']
      }
    },
    handler: async (args) => {
      const { name, type, hullColor = '#64748b', accentColor = '#f59e0b', engineColor = '#3b82f6', windowColor = '#0ea5e9', width = 128, height = 64 } = args;
      
      const params = {
        hullColor,
        hullColorDark: adjustColor(hullColor, -20),
        accentColor,
        engineColor,
        windowColor,
        interiorColor: adjustColor(hullColor, -30),
        width,
        height
      };
      
      const template = SVG_TEMPLATES[`ship_${type}`] || SVG_TEMPLATES.ship_shuttle;
      const svg = template(params);
      
      const filename = name.toLowerCase().replace(/[^a-z0-9]/g, '_') + '.svg';
      const fullPath = path.join(ASSETS_PATH, 'ships', filename);
      await fs.mkdir(path.dirname(fullPath), { recursive: true });
      await fs.writeFile(fullPath, svg.trim());
      
      return {
        content: [{
          type: 'text',
          text: JSON.stringify({
            success: true,
            path: `res://assets/sprites/ships/${filename}`,
            absolutePath: fullPath,
            preview: svg.trim(),
            message: `Generated ${type} ship sprite: ${filename}`
          }, null, 2)
        }]
      };
    }
  },
  
  {
    definition: {
      name: 'generate_enemy_sprite',
      description: 'Generate an SVG sprite for an enemy',
      inputSchema: {
        type: 'object',
        properties: {
          name: { type: 'string', description: 'Enemy name' },
          type: { type: 'string', enum: ['drone', 'fighter', 'turret', 'boss'], description: 'Enemy type' },
          primaryColor: { type: 'string', description: 'Main body color (hex)' },
          eyeColor: { type: 'string', description: 'Eye/sensor color (hex)' },
          size: { type: 'number', description: 'Sprite size' }
        },
        required: ['name', 'type']
      }
    },
    handler: async (args) => {
      const { name, type, primaryColor = '#6b7280', eyeColor = '#ef4444', size = 48 } = args;
      
      const params = {
        primaryColor,
        secondaryColor: adjustColor(primaryColor, -20),
        eyeColor,
        size
      };
      
      const template = SVG_TEMPLATES[`enemy_${type}`] || SVG_TEMPLATES.enemy_drone;
      const svg = template(params);
      
      const filename = name.toLowerCase().replace(/[^a-z0-9]/g, '_') + '.svg';
      const fullPath = path.join(ASSETS_PATH, 'enemies', filename);
      await fs.mkdir(path.dirname(fullPath), { recursive: true });
      await fs.writeFile(fullPath, svg.trim());
      
      return {
        content: [{
          type: 'text',
          text: JSON.stringify({
            success: true,
            path: `res://assets/sprites/enemies/${filename}`,
            absolutePath: fullPath,
            preview: svg.trim(),
            message: `Generated ${type} enemy sprite: ${filename}`
          }, null, 2)
        }]
      };
    }
  },
  
  {
    definition: {
      name: 'list_asset_templates',
      description: 'List all available asset generation templates',
      inputSchema: { type: 'object', properties: {} }
    },
    handler: async () => {
      return {
        content: [{
          type: 'text',
          text: JSON.stringify({
            templates: Object.keys(SVG_TEMPLATES).map(key => ({
              id: key,
              category: key.split('_')[0],
              type: key.split('_').slice(1).join('_')
            })),
            shapes: Object.keys(SHAPE_GENERATORS),
            rarities: Object.keys(RARITY_PALETTES),
            message: 'Use these templates with the asset generation tools'
          }, null, 2)
        }]
      };
    }
  },
  
  {
    definition: {
      name: 'preview_asset',
      description: 'Generate a preview SVG without saving to file',
      inputSchema: {
        type: 'object',
        properties: {
          template: { type: 'string', description: 'Template name (e.g., item_scrap, module_engine, ship_shuttle)' },
          params: { type: 'object', description: 'Parameters to pass to template' }
        },
        required: ['template']
      }
    },
    handler: async (args) => {
      const { template, params = {} } = args;
      
      const templateFn = SVG_TEMPLATES[template];
      if (!templateFn) {
        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              error: true,
              message: `Unknown template: ${template}`,
              available: Object.keys(SVG_TEMPLATES)
            }, null, 2)
          }]
        };
      }
      
      return {
        content: [{
          type: 'text',
          text: JSON.stringify({
            preview: templateFn(params),
            template,
            params
          }, null, 2)
        }]
      };
    }
  }
];

// ==================== PLUGIN EXPORT ====================

export function register(pluginManager) {
  tools.forEach(tool => {
    pluginManager.registerTool(tool.definition, tool.handler);
  });
  
  console.log(`[Asset Generator] Registered ${tools.length} asset generation tools`);
}

export default { register };
