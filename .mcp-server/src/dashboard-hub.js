/**
 * Project Hub Dashboard - MCP Server Dashboard
 * Multi-project support, tool categories, execution history, and more
 */

export function generateDashboardHTML(projectName = 'Cargo Escape') {
  const cacheVersion = Date.now();
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
  <meta http-equiv="Pragma" content="no-cache">
  <meta http-equiv="Expires" content="0">
  <title>MCP Project Hub - ${projectName}</title>
  <!-- Cache Version: ${cacheVersion} -->
  <style>
    :root {
      --bg-primary: #0a0e17;
      --bg-secondary: #0f1520;
      --bg-tertiary: #151c2c;
      --bg-card: #1a2235;
      --accent-primary: #00d4ff;
      --accent-secondary: #7c3aed;
      --accent-success: #22c55e;
      --accent-warning: #f59e0b;
      --accent-error: #ef4444;
      --text-primary: #e2e8f0;
      --text-secondary: #94a3b8;
      --text-muted: #64748b;
      --border-color: #2d3748;
      --glow-primary: rgba(0, 212, 255, 0.3);
      --glow-secondary: rgba(124, 58, 237, 0.3);
    }
    
    * { box-sizing: border-box; margin: 0; padding: 0; }
    
    body {
      font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
      background: var(--bg-primary);
      color: var(--text-primary);
      min-height: 100vh;
      overflow-x: hidden;
    }
    
    /* Animated Background */
    .bg-animation {
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      z-index: -1;
      opacity: 0.5;
      pointer-events: none;  /* CRITICAL: Ensure background never blocks clicks */
    }
    
    .star {
      position: absolute;
      width: 2px;
      height: 2px;
      background: white;
      border-radius: 50%;
      animation: twinkle 3s ease-in-out infinite;
      pointer-events: none;  /* Ensure stars don't intercept clicks */
    }
    
    @keyframes twinkle {
      0%, 100% { opacity: 0.3; }
      50% { opacity: 1; }
    }
    
    /* Layout */
    .app-container {
      display: grid;
      grid-template-columns: 260px 1fr;
      grid-template-rows: auto 1fr;
      min-height: 100vh;
    }
    
    /* Header */
    .header {
      grid-column: 1 / -1;
      background: linear-gradient(135deg, var(--bg-secondary) 0%, var(--bg-tertiary) 100%);
      border-bottom: 1px solid var(--border-color);
      padding: 1rem 2rem;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 2rem;
    }
    
    .logo-section {
      display: flex;
      align-items: center;
      gap: 1rem;
    }
    
    .logo {
      width: 48px;
      height: 48px;
      background: linear-gradient(135deg, var(--accent-primary), var(--accent-secondary));
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 24px;
      box-shadow: 0 4px 20px var(--glow-primary);
    }
    
    .logo-text h1 {
      font-size: 1.5rem;
      font-weight: 700;
      background: linear-gradient(90deg, var(--accent-primary), var(--accent-secondary));
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
    }
    
    .logo-text span {
      font-size: 0.85rem;
      color: var(--text-secondary);
    }
    
    /* Search Bar */
    .search-bar {
      flex: 1;
      max-width: 500px;
      position: relative;
    }
    
    .search-bar input {
      width: 100%;
      padding: 0.75rem 1rem 0.75rem 2.75rem;
      background: var(--bg-card);
      border: 1px solid var(--border-color);
      border-radius: 12px;
      color: var(--text-primary);
      font-size: 0.95rem;
      transition: all 0.2s;
    }
    
    .search-bar input:focus {
      outline: none;
      border-color: var(--accent-primary);
      box-shadow: 0 0 20px var(--glow-primary);
    }
    
    .search-bar::before {
      content: '🔍';
      position: absolute;
      left: 1rem;
      top: 50%;
      transform: translateY(-50%);
      font-size: 1rem;
      opacity: 0.5;
    }
    
    /* Header Actions */
    .header-actions {
      display: flex;
      align-items: center;
      gap: 1rem;
    }
    
    .status-indicator {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.5rem 1rem;
      background: var(--bg-card);
      border-radius: 20px;
      font-size: 0.85rem;
    }
    
    .status-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: var(--accent-success);
      animation: pulse 2s ease-in-out infinite;
    }
    
    @keyframes pulse {
      0%, 100% { opacity: 1; box-shadow: 0 0 0 0 rgba(34, 197, 94, 0.7); }
      50% { opacity: 0.8; box-shadow: 0 0 0 8px rgba(34, 197, 94, 0); }
    }
    
    .btn {
      padding: 0.5rem 1rem;
      border-radius: 8px;
      border: none;
      font-size: 0.9rem;
      cursor: pointer;
      transition: all 0.2s;
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }
    
    .btn-primary {
      background: linear-gradient(135deg, var(--accent-primary), var(--accent-secondary));
      color: white;
    }
    
    .btn-primary:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 20px var(--glow-primary);
    }
    
    .btn-ghost {
      background: transparent;
      color: var(--text-secondary);
      border: 1px solid var(--border-color);
    }
    
    .btn-ghost:hover {
      background: var(--bg-card);
      color: var(--text-primary);
    }
    
    /* Sidebar */
    .sidebar {
      background: var(--bg-secondary);
      border-right: 1px solid var(--border-color);
      padding: 1rem 0;
      overflow-y: auto;
      position: relative;  /* Create stacking context */
      z-index: 10;         /* Ensure sidebar is above background elements */
    }
    
    .sidebar-section {
      margin-bottom: 1.5rem;
    }
    
    .sidebar-title {
      font-size: 0.75rem;
      font-weight: 600;
      color: var(--text-muted);
      text-transform: uppercase;
      letter-spacing: 0.05em;
      padding: 0 1rem;
      margin-bottom: 0.5rem;
    }
    
    .nav-item {
      display: flex;
      align-items: center;
      gap: 0.75rem;
      padding: 0.75rem 1rem;
      color: var(--text-secondary);
      text-decoration: none;
      cursor: pointer;
      transition: all 0.2s;
      border-left: 3px solid transparent;
    }
    
    .nav-item:hover {
      background: var(--bg-tertiary);
      color: var(--text-primary);
    }
    
    .nav-item.active {
      background: linear-gradient(90deg, rgba(0, 212, 255, 0.1), transparent);
      color: var(--accent-primary);
      border-left-color: var(--accent-primary);
    }
    
    .nav-item .icon {
      font-size: 1.2rem;
      width: 24px;
      text-align: center;
    }
    
    .nav-item .badge {
      margin-left: auto;
      padding: 0.2rem 0.5rem;
      background: var(--accent-secondary);
      color: white;
      border-radius: 10px;
      font-size: 0.7rem;
      font-weight: 600;
    }
    
    /* Project Selector */
    .project-selector {
      padding: 0.75rem 1rem;
      margin: 0 0.75rem 1rem;
      background: var(--bg-card);
      border-radius: 8px;
      cursor: pointer;
      transition: all 0.2s;
    }
    
    .project-selector:hover {
      background: var(--bg-tertiary);
    }
    
    .project-selector .current {
      display: flex;
      align-items: center;
      gap: 0.75rem;
    }
    
    .project-selector .project-icon {
      width: 32px;
      height: 32px;
      background: linear-gradient(135deg, #f59e0b, #ef4444);
      border-radius: 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 1rem;
    }
    
    .project-selector .project-name {
      font-weight: 600;
      font-size: 0.9rem;
    }
    
    .project-selector .project-path {
      font-size: 0.75rem;
      color: var(--text-muted);
    }
    
    /* Main Content */
    .main-content {
      padding: 1.5rem 2rem;
      overflow-y: auto;
    }
    
    /* Tab System */
    .tab-container {
      display: none;
    }
    
    .tab-container.active {
      display: block;
    }
    
    /* Dashboard Grid */
    .dashboard-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: 1.5rem;
      margin-bottom: 2rem;
    }
    
    /* Stats Card */
    .stats-card {
      background: var(--bg-card);
      border-radius: 16px;
      padding: 1.5rem;
      border: 1px solid var(--border-color);
      transition: all 0.3s;
      cursor: pointer;
      position: relative;
      z-index: 1;
      user-select: none;
    }
    
    .stats-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 8px 30px rgba(0, 212, 255, 0.2);
      border-color: var(--accent-primary);
      background: var(--bg-tertiary);
    }
    
    .stats-card:active {
      transform: translateY(-2px);
      box-shadow: 0 4px 15px rgba(0, 212, 255, 0.3);
    }
    
    .stats-card::after {
      content: 'Click to view →';
      position: absolute;
      right: 1rem;
      bottom: 0.5rem;
      font-size: 0.7rem;
      opacity: 0;
      transition: all 0.3s;
      color: var(--accent-primary);
    }
    
    .stats-card:hover::after {
      opacity: 1;
    }
    
    .stats-card .card-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 1rem;
    }
    
    .stats-card .card-icon {
      width: 48px;
      height: 48px;
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 1.5rem;
    }
    
    .stats-card .card-icon.blue { background: linear-gradient(135deg, rgba(0, 212, 255, 0.2), rgba(0, 212, 255, 0.1)); }
    .stats-card .card-icon.purple { background: linear-gradient(135deg, rgba(124, 58, 237, 0.2), rgba(124, 58, 237, 0.1)); }
    .stats-card .card-icon.green { background: linear-gradient(135deg, rgba(34, 197, 94, 0.2), rgba(34, 197, 94, 0.1)); }
    .stats-card .card-icon.orange { background: linear-gradient(135deg, rgba(245, 158, 11, 0.2), rgba(245, 158, 11, 0.1)); }
    
    .stats-card .card-value {
      font-size: 2rem;
      font-weight: 700;
      margin-bottom: 0.25rem;
    }
    
    .stats-card .card-label {
      color: var(--text-secondary);
      font-size: 0.9rem;
    }
    
    .stats-card .card-trend {
      display: flex;
      align-items: center;
      gap: 0.25rem;
      font-size: 0.85rem;
      margin-top: 0.75rem;
    }
    
    .stats-card .card-trend.up { color: var(--accent-success); }
    .stats-card .card-trend.down { color: var(--accent-error); }
    
    /* Section Title */
    .section-title {
      font-size: 1.25rem;
      font-weight: 600;
      margin-bottom: 1rem;
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }
    
    /* Tool Grid */
    .tool-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
      gap: 1rem;
    }
    
    .tool-card {
      background: var(--bg-card);
      border-radius: 12px;
      padding: 1.25rem;
      border: 1px solid var(--border-color);
      cursor: pointer;
      transition: all 0.2s;
    }
    
    .tool-card:hover {
      border-color: var(--accent-primary);
      box-shadow: 0 4px 20px var(--glow-primary);
    }
    
    .tool-card .tool-header {
      display: flex;
      align-items: center;
      gap: 0.75rem;
      margin-bottom: 0.75rem;
    }
    
    .tool-card .tool-icon {
      font-size: 1.5rem;
    }
    
    .tool-card .tool-name {
      font-weight: 600;
      font-size: 1rem;
    }
    
    .tool-card .tool-category {
      margin-left: auto;
      padding: 0.25rem 0.5rem;
      background: var(--bg-tertiary);
      border-radius: 6px;
      font-size: 0.7rem;
      color: var(--text-muted);
      text-transform: uppercase;
    }
    
    .tool-card .tool-desc {
      font-size: 0.85rem;
      color: var(--text-secondary);
      line-height: 1.5;
    }
    
    .tool-card .tool-tags {
      display: flex;
      flex-wrap: wrap;
      gap: 0.5rem;
      margin-top: 0.75rem;
    }
    
    .tool-card .tag {
      padding: 0.2rem 0.5rem;
      background: var(--bg-secondary);
      border-radius: 4px;
      font-size: 0.7rem;
      color: var(--accent-primary);
    }
    
    /* Tool Execution Panel */
    .tool-panel {
      background: var(--bg-card);
      border-radius: 16px;
      border: 1px solid var(--border-color);
      overflow: hidden;
      margin-top: 2rem;
    }
    
    .tool-panel-header {
      background: var(--bg-tertiary);
      padding: 1rem 1.5rem;
      display: flex;
      align-items: center;
      justify-content: space-between;
      border-bottom: 1px solid var(--border-color);
    }
    
    .tool-panel-title {
      font-weight: 600;
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }
    
    .tool-panel-body {
      padding: 1.5rem;
    }
    
    .input-group {
      margin-bottom: 1rem;
    }
    
    .input-group label {
      display: block;
      font-size: 0.85rem;
      color: var(--text-secondary);
      margin-bottom: 0.5rem;
    }
    
    .input-group input,
    .input-group select,
    .input-group textarea {
      width: 100%;
      padding: 0.75rem 1rem;
      background: var(--bg-secondary);
      border: 1px solid var(--border-color);
      border-radius: 8px;
      color: var(--text-primary);
      font-size: 0.95rem;
      transition: all 0.2s;
    }
    
    .input-group input:focus,
    .input-group select:focus,
    .input-group textarea:focus {
      outline: none;
      border-color: var(--accent-primary);
    }
    
    /* Output Display */
    .output-display {
      background: var(--bg-primary);
      border-radius: 8px;
      padding: 1rem;
      font-size: 0.9rem;
      line-height: 1.6;
      max-height: 500px;
      overflow-y: auto;
    }
    
    .output-display.error {
      border-left: 3px solid var(--accent-error);
      color: var(--accent-error);
      font-family: 'Cascadia Code', 'Fira Code', monospace;
      white-space: pre-wrap;
    }
    
    .output-display.success {
      border-left: 3px solid var(--accent-success);
    }
    
    .output-display pre {
      margin: 0;
      font-family: 'Cascadia Code', 'Fira Code', monospace;
      font-size: 0.85rem;
      white-space: pre-wrap;
      word-break: break-word;
    }
    
    /* Formatted Output Styles */
    .output-section {
      margin-bottom: 1rem;
      padding-bottom: 1rem;
      border-bottom: 1px solid var(--border-subtle);
    }
    
    .output-section:last-child {
      margin-bottom: 0;
      padding-bottom: 0;
      border-bottom: none;
    }
    
    .output-section h4 {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      margin-bottom: 0.5rem;
      font-size: 0.95rem;
      color: var(--accent-primary);
    }
    
    .output-list {
      display: flex;
      flex-direction: column;
      gap: 0.25rem;
    }
    
    .output-list-item {
      display: flex;
      align-items: flex-start;
      gap: 0.5rem;
      padding: 0.5rem 0.75rem;
      background: var(--bg-secondary);
      border-radius: 6px;
      font-family: monospace;
      font-size: 0.85rem;
    }
    
    .output-list-item .file-path {
      color: var(--text-secondary);
    }
    
    .output-list-item .line-num {
      color: var(--accent-warning);
      min-width: 40px;
    }
    
    .output-list-item .content {
      color: var(--text-primary);
      flex: 1;
    }
    
    .output-stat-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
      gap: 0.75rem;
    }
    
    .output-stat-item {
      background: var(--bg-secondary);
      padding: 0.75rem;
      border-radius: 8px;
      text-align: center;
    }
    
    .output-stat-item .stat-value {
      font-size: 1.5rem;
      font-weight: 700;
      color: var(--accent-primary);
    }
    
    .output-stat-item .stat-label {
      font-size: 0.8rem;
      color: var(--text-secondary);
    }
    
    .output-badge {
      display: inline-flex;
      align-items: center;
      gap: 0.25rem;
      padding: 0.25rem 0.5rem;
      border-radius: 4px;
      font-size: 0.8rem;
      font-weight: 500;
    }
    
    .output-badge.todo { background: rgba(245, 158, 11, 0.2); color: var(--accent-warning); }
    .output-badge.fixme { background: rgba(239, 68, 68, 0.2); color: var(--accent-error); }
    .output-badge.hack { background: rgba(124, 58, 237, 0.2); color: var(--accent-secondary); }
    .output-badge.note { background: rgba(34, 197, 94, 0.2); color: var(--accent-success); }
    .output-badge.success { background: rgba(34, 197, 94, 0.2); color: var(--accent-success); }
    .output-badge.info { background: rgba(0, 212, 255, 0.2); color: var(--accent-primary); }
    
    /* History Section */
    .history-list {
      display: flex;
      flex-direction: column;
      gap: 0.5rem;
    }
    
    .history-item {
      display: flex;
      align-items: center;
      gap: 1rem;
      padding: 0.75rem 1rem;
      background: var(--bg-secondary);
      border-radius: 8px;
      cursor: pointer;
      transition: all 0.2s;
    }
    
    .history-item:hover {
      background: var(--bg-tertiary);
    }
    
    .history-item .time {
      font-size: 0.8rem;
      color: var(--text-muted);
      min-width: 80px;
    }
    
    .history-item .tool-name {
      font-weight: 500;
      flex: 1;
    }
    
    .history-item .status {
      padding: 0.2rem 0.5rem;
      border-radius: 4px;
      font-size: 0.75rem;
      font-weight: 500;
    }
    
    .history-item .status.success {
      background: rgba(34, 197, 94, 0.2);
      color: var(--accent-success);
    }
    
    .history-item .status.error {
      background: rgba(239, 68, 68, 0.2);
      color: var(--accent-error);
    }
    
    /* Metrics Section */
    .metrics-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 1rem;
    }
    
    .metric-box {
      background: var(--bg-card);
      border-radius: 12px;
      padding: 1.25rem;
      border: 1px solid var(--border-color);
    }
    
    .metric-box .metric-label {
      font-size: 0.8rem;
      color: var(--text-muted);
      margin-bottom: 0.5rem;
    }
    
    .metric-box .metric-value {
      font-size: 1.5rem;
      font-weight: 700;
    }
    
    .metric-box .metric-chart {
      height: 40px;
      margin-top: 0.75rem;
      display: flex;
      align-items: flex-end;
      gap: 2px;
    }
    
    .metric-box .chart-bar {
      flex: 1;
      background: linear-gradient(to top, var(--accent-primary), var(--accent-secondary));
      border-radius: 2px 2px 0 0;
      transition: height 0.3s;
    }
    
    /* Learning Section */
    .learning-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: 1.5rem;
    }
    
    .learning-card {
      background: var(--bg-card);
      border-radius: 12px;
      overflow: hidden;
      border: 1px solid var(--border-color);
      transition: all 0.3s;
    }
    
    .learning-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 8px 30px rgba(0, 0, 0, 0.3);
    }
    
    .learning-card .card-banner {
      height: 120px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 3rem;
    }
    
    .learning-card .card-banner.mcp { background: linear-gradient(135deg, #00d4ff, #7c3aed); }
    .learning-card .card-banner.docker { background: linear-gradient(135deg, #0db7ed, #384d54); }
    .learning-card .card-banner.godot { background: linear-gradient(135deg, #478cbf, #333); }
    .learning-card .card-banner.git { background: linear-gradient(135deg, #f05032, #333); }
    
    .learning-card .card-content {
      padding: 1.25rem;
    }
    
    .learning-card .card-title {
      font-weight: 600;
      font-size: 1.1rem;
      margin-bottom: 0.5rem;
    }
    
    .learning-card .card-desc {
      font-size: 0.85rem;
      color: var(--text-secondary);
      line-height: 1.5;
    }
    
    .learning-card .card-links {
      margin-top: 1rem;
      display: flex;
      flex-wrap: wrap;
      gap: 0.5rem;
    }
    
    .learning-card .card-link {
      padding: 0.4rem 0.75rem;
      background: var(--bg-secondary);
      border-radius: 6px;
      font-size: 0.8rem;
      color: var(--accent-primary);
      text-decoration: none;
      transition: all 0.2s;
    }
    
    .learning-card .card-link:hover {
      background: var(--bg-tertiary);
    }
    
    /* Favorites */
    .favorites-bar {
      display: flex;
      gap: 0.5rem;
      margin-bottom: 1.5rem;
      padding: 0.5rem;
      background: var(--bg-card);
      border-radius: 12px;
      overflow-x: auto;
    }
    
    .favorite-btn {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.5rem 1rem;
      background: var(--bg-secondary);
      border: none;
      border-radius: 8px;
      color: var(--text-primary);
      font-size: 0.85rem;
      cursor: pointer;
      white-space: nowrap;
      transition: all 0.2s;
    }
    
    .favorite-btn:hover {
      background: var(--bg-tertiary);
    }
    
    .favorite-btn .star {
      color: var(--accent-warning);
    }
    
    /* Keyboard Shortcuts Modal */
    .modal-overlay {
      position: fixed;
      inset: 0;
      background: rgba(0, 0, 0, 0.7);
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 1000;
      opacity: 0;
      visibility: hidden;
      pointer-events: none;  /* CRITICAL: Prevent click blocking when hidden */
      transition: all 0.3s;
    }
    
    .modal-overlay.show {
      opacity: 1;
      visibility: visible;
      pointer-events: auto;  /* Re-enable clicks when modal is shown */
    }
    
    .modal {
      background: var(--bg-card);
      border-radius: 16px;
      padding: 2rem;
      max-width: 500px;
      width: 90%;
      max-height: 80vh;
      overflow-y: auto;
      transform: scale(0.9);
      transition: all 0.3s;
    }
    
    .modal-overlay.show .modal {
      transform: scale(1);
    }
    
    .modal h2 {
      margin-bottom: 1.5rem;
    }
    
    .modal-close {
      position: absolute;
      top: 1rem;
      right: 1rem;
      background: none;
      border: none;
      font-size: 1.5rem;
      cursor: pointer;
      color: var(--text-secondary);
      transition: color 0.2s;
    }
    
    .modal-close:hover {
      color: var(--text-primary);
    }
    
    .detail-modal {
      max-width: 800px;
      position: relative;
    }
    
    .detail-modal h2 {
      display: flex;
      align-items: center;
      gap: 0.75rem;
    }
    
    .detail-list {
      display: flex;
      flex-direction: column;
      gap: 0.5rem;
      max-height: 400px;
      overflow-y: auto;
    }
    
    .detail-item {
      display: flex;
      align-items: flex-start;
      gap: 0.75rem;
      padding: 0.75rem 1rem;
      background: var(--bg-secondary);
      border-radius: 8px;
      border-left: 3px solid var(--accent-primary);
    }
    
    .detail-item.todo { border-left-color: var(--accent-warning); }
    .detail-item.fixme { border-left-color: var(--accent-error); }
    .detail-item.hack { border-left-color: var(--accent-secondary); }
    .detail-item.note { border-left-color: var(--accent-success); }
    
    .detail-item .item-type {
      font-size: 0.7rem;
      font-weight: 600;
      padding: 0.2rem 0.4rem;
      border-radius: 4px;
      min-width: 50px;
      text-align: center;
    }
    
    .detail-item .item-type.todo { background: rgba(245, 158, 11, 0.2); color: var(--accent-warning); }
    .detail-item .item-type.fixme { background: rgba(239, 68, 68, 0.2); color: var(--accent-error); }
    .detail-item .item-type.hack { background: rgba(124, 58, 237, 0.2); color: var(--accent-secondary); }
    .detail-item .item-type.note { background: rgba(34, 197, 94, 0.2); color: var(--accent-success); }
    
    .detail-item .item-content {
      flex: 1;
    }
    
    .detail-item .item-file {
      font-size: 0.8rem;
      color: var(--text-muted);
      font-family: monospace;
      margin-bottom: 0.25rem;
    }
    
    .detail-item .item-text {
      font-size: 0.9rem;
      color: var(--text-secondary);
    }
    
    .detail-summary {
      display: flex;
      gap: 1rem;
      margin-bottom: 1rem;
      flex-wrap: wrap;
    }
    
    .summary-badge {
      padding: 0.5rem 1rem;
      border-radius: 8px;
      font-size: 0.85rem;
      font-weight: 500;
    }
    
    .summary-badge.todo { background: rgba(245, 158, 11, 0.2); color: var(--accent-warning); }
    .summary-badge.fixme { background: rgba(239, 68, 68, 0.2); color: var(--accent-error); }
    .summary-badge.scripts { background: rgba(0, 212, 255, 0.2); color: var(--accent-primary); }
    .summary-badge.scenes { background: rgba(124, 58, 237, 0.2); color: var(--accent-secondary); }
    .summary-badge.lines { background: rgba(34, 197, 94, 0.2); color: var(--accent-success); }

    .shortcut-list {
      display: flex;
      flex-direction: column;
      gap: 0.75rem;
    }
    
    .shortcut-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    
    .shortcut-key {
      padding: 0.3rem 0.6rem;
      background: var(--bg-secondary);
      border-radius: 6px;
      font-family: monospace;
      font-size: 0.85rem;
    }
    
    /* Loading Spinner */
    .spinner {
      width: 24px;
      height: 24px;
      border: 2px solid var(--border-color);
      border-top-color: var(--accent-primary);
      border-radius: 50%;
      animation: spin 1s linear infinite;
    }
    
    @keyframes spin {
      to { transform: rotate(360deg); }
    }
    
    /* Responsive */
    @media (max-width: 768px) {
      .app-container {
        grid-template-columns: 1fr;
      }
      
      .sidebar {
        display: none;
      }
      
      .header {
        flex-wrap: wrap;
        gap: 1rem;
      }
      
      .search-bar {
        order: 3;
        max-width: none;
      }
    }
    
    /* Scrollbar */
    ::-webkit-scrollbar {
      width: 8px;
      height: 8px;
    }
    
    ::-webkit-scrollbar-track {
      background: var(--bg-secondary);
    }
    
    ::-webkit-scrollbar-thumb {
      background: var(--border-color);
      border-radius: 4px;
    }
    
    ::-webkit-scrollbar-thumb:hover {
      background: var(--text-muted);
    }
    
    /* ==================== NEW FEATURE STYLES ==================== */
    
    /* Light Theme */
    body.light-theme {
      --bg-primary: #f8fafc;
      --bg-secondary: #ffffff;
      --bg-tertiary: #f1f5f9;
      --bg-card: #ffffff;
      --text-primary: #1e293b;
      --text-secondary: #475569;
      --text-muted: #94a3b8;
      --border-color: #e2e8f0;
      --border-subtle: #f1f5f9;
    }
    
    body.light-theme .bg-animation { display: none; }
    
    /* Theme Toggle */
    .theme-toggle {
      position: relative;
      width: 56px;
      height: 28px;
      background: var(--bg-card);
      border-radius: 14px;
      border: 1px solid var(--border-color);
      cursor: pointer;
      transition: all 0.3s;
    }
    
    .theme-toggle::after {
      content: '🌙';
      position: absolute;
      left: 4px;
      top: 50%;
      transform: translateY(-50%);
      width: 20px;
      height: 20px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 12px;
      transition: all 0.3s;
    }
    
    body.light-theme .theme-toggle::after {
      content: '☀️';
      left: calc(100% - 24px);
    }
    
    /* Auto-refresh Indicator */
    .auto-refresh {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.5rem 0.75rem;
      background: var(--bg-card);
      border-radius: 8px;
      font-size: 0.8rem;
      color: var(--text-secondary);
    }
    
    .auto-refresh.active .refresh-icon {
      animation: spin 2s linear infinite;
    }
    
    @keyframes spin {
      from { transform: rotate(0deg); }
      to { transform: rotate(360deg); }
    }
    
    /* Notification Bell */
    .notification-btn {
      position: relative;
      background: var(--bg-card);
      border: 1px solid var(--border-color);
      border-radius: 8px;
      padding: 0.5rem;
      cursor: pointer;
      font-size: 1.25rem;
    }
    
    .notification-badge {
      position: absolute;
      top: -4px;
      right: -4px;
      background: var(--accent-error);
      color: white;
      font-size: 0.7rem;
      font-weight: 600;
      min-width: 18px;
      height: 18px;
      border-radius: 9px;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    
    /* Notification Panel */
    .notification-panel {
      position: fixed;
      top: 70px;
      right: 20px;
      width: 360px;
      max-height: 500px;
      background: var(--bg-card);
      border: 1px solid var(--border-color);
      border-radius: 12px;
      box-shadow: 0 10px 40px rgba(0, 0, 0, 0.3);
      z-index: 1000;
      display: none;
      overflow: hidden;
    }
    
    .notification-panel.show {
      display: block;
    }
    
    .notification-panel-header {
      padding: 1rem;
      border-bottom: 1px solid var(--border-color);
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    
    .notification-list {
      max-height: 400px;
      overflow-y: auto;
    }
    
    .notification-item {
      padding: 1rem;
      border-bottom: 1px solid var(--border-subtle);
      display: flex;
      gap: 0.75rem;
    }
    
    .notification-item:hover {
      background: var(--bg-tertiary);
    }
    
    .notification-item .icon {
      font-size: 1.25rem;
    }
    
    .notification-item.warning .icon { color: var(--accent-warning); }
    .notification-item.error .icon { color: var(--accent-error); }
    .notification-item.info .icon { color: var(--accent-primary); }
    .notification-item.success .icon { color: var(--accent-success); }
    
    .notification-content h4 {
      font-size: 0.9rem;
      margin-bottom: 0.25rem;
    }
    
    .notification-content p {
      font-size: 0.8rem;
      color: var(--text-secondary);
    }
    
    /* Copy Button */
    .copy-btn {
      background: var(--bg-tertiary);
      border: 1px solid var(--border-color);
      border-radius: 4px;
      padding: 0.25rem 0.5rem;
      font-size: 0.75rem;
      cursor: pointer;
      color: var(--text-secondary);
      transition: all 0.2s;
    }
    
    .copy-btn:hover {
      background: var(--accent-primary);
      color: white;
      border-color: var(--accent-primary);
    }
    
    .copy-btn.copied {
      background: var(--accent-success);
      color: white;
      border-color: var(--accent-success);
    }
    
    /* Settings Panel */
    .settings-modal {
      max-width: 600px;
    }
    
    .settings-section {
      margin-bottom: 1.5rem;
    }
    
    .settings-section h4 {
      font-size: 1rem;
      margin-bottom: 1rem;
      color: var(--accent-primary);
    }
    
    .setting-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 0.75rem 0;
      border-bottom: 1px solid var(--border-subtle);
    }
    
    .setting-row:last-child {
      border-bottom: none;
    }
    
    .setting-label {
      display: flex;
      flex-direction: column;
      gap: 0.25rem;
    }
    
    .setting-label span:first-child {
      font-weight: 500;
    }
    
    .setting-label span:last-child {
      font-size: 0.8rem;
      color: var(--text-muted);
    }
    
    /* Toggle Switch */
    .toggle-switch {
      position: relative;
      width: 48px;
      height: 24px;
      background: var(--border-color);
      border-radius: 12px;
      cursor: pointer;
      transition: all 0.3s;
    }
    
    .toggle-switch.active {
      background: var(--accent-primary);
    }
    
    .toggle-switch::after {
      content: '';
      position: absolute;
      left: 2px;
      top: 2px;
      width: 20px;
      height: 20px;
      background: white;
      border-radius: 50%;
      transition: all 0.3s;
    }
    
    .toggle-switch.active::after {
      left: 26px;
    }
    
    /* Health Score Display */
    .health-score {
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 1.5rem;
      background: var(--bg-card);
      border-radius: 16px;
      border: 1px solid var(--border-color);
    }
    
    .health-score-circle {
      width: 120px;
      height: 120px;
      border-radius: 50%;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      margin-bottom: 1rem;
      position: relative;
    }
    
    .health-score-circle::before {
      content: '';
      position: absolute;
      inset: 0;
      border-radius: 50%;
      border: 8px solid var(--border-color);
    }
    
    .health-score-circle::after {
      content: '';
      position: absolute;
      inset: 0;
      border-radius: 50%;
      border: 8px solid transparent;
      border-top-color: var(--accent-success);
      animation: healthRotate 1s ease-out forwards;
    }
    
    @keyframes healthRotate {
      from { transform: rotate(0deg); }
      to { transform: rotate(var(--health-rotation, 270deg)); }
    }
    
    .health-score-value {
      font-size: 2.5rem;
      font-weight: 700;
    }
    
    .health-score-grade {
      font-size: 1rem;
      color: var(--text-secondary);
    }
    
    .health-score.A .health-score-value { color: var(--accent-success); }
    .health-score.B .health-score-value { color: #84cc16; }
    .health-score.C .health-score-value { color: var(--accent-warning); }
    .health-score.D .health-score-value { color: #f97316; }
    .health-score.F .health-score-value { color: var(--accent-error); }
    
    /* Wiki Inline Viewer - No Popups */
    .wiki-page {
      height: calc(100vh - 200px);
      display: flex;
      flex-direction: column;
    }
    
    .wiki-page-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding-bottom: 1rem;
      border-bottom: 1px solid var(--border-color);
      flex-shrink: 0;
      margin-bottom: 1rem;
    }
    
    .wiki-page-layout {
      display: flex;
      gap: 1rem;
      flex: 1;
      overflow: hidden;
    }
    
    .wiki-file-panel {
      width: 280px;
      flex-shrink: 0;
      display: flex;
      flex-direction: column;
      gap: 0.5rem;
    }
    
    .wiki-file-filters {
      display: flex;
      flex-direction: column;
      gap: 0.5rem;
      padding: 0.5rem;
      background: var(--bg-card);
      border-radius: 8px;
    }
    
    .wiki-file-list {
      flex: 1;
      background: var(--bg-card);
      border-radius: 8px;
      overflow-y: auto;
      padding: 0.5rem;
    }
    
    .wiki-main-panel {
      flex: 1;
      display: flex;
      flex-direction: column;
      overflow: hidden;
    }
    
    .wiki-main-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      padding: 1rem;
      background: var(--bg-card);
      border-radius: 8px 8px 0 0;
      border-bottom: 1px solid var(--border-color);
    }
    
    .wiki-title-section {
      flex: 1;
    }
    
    .wiki-title {
      display: flex;
      align-items: center;
      gap: 0.75rem;
      margin-bottom: 0.5rem;
    }
    
    .wiki-title h2 {
      margin: 0;
      font-size: 1.25rem;
    }
    
    .wiki-file-type {
      display: inline-block;
      padding: 0.25rem 0.75rem;
      background: var(--accent-primary);
      color: white;
      border-radius: 999px;
      font-size: 0.75rem;
      font-weight: 600;
    }
    
    .wiki-path {
      font-family: monospace;
      font-size: 0.8rem;
      color: var(--text-secondary);
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }
    
    .wiki-actions {
      display: flex;
      gap: 0.5rem;
      flex-shrink: 0;
    }
    
    .wiki-main-content {
      flex: 1;
      display: flex;
      overflow: hidden;
      background: var(--bg-card);
      border-radius: 0 0 8px 8px;
    }
    
    .wiki-toc {
      width: 180px;
      flex-shrink: 0;
      padding: 1rem;
      border-right: 1px solid var(--border-color);
      overflow-y: auto;
    }
    
    .wiki-nav {
      background: transparent;
    }
    
    .wiki-nav-title {
      font-size: 0.7rem;
      font-weight: 600;
      color: var(--text-muted);
      text-transform: uppercase;
      letter-spacing: 0.05em;
      margin-bottom: 0.5rem;
    }
    
    .wiki-nav-item {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.4rem 0.6rem;
      border-radius: 6px;
      cursor: pointer;
      font-size: 0.8rem;
      transition: all 0.2s;
    }
    
    .wiki-nav-item:hover {
      background: var(--bg-secondary);
    }
    
    .wiki-nav-item.active {
      background: var(--accent-primary);
      color: white;
    }
    
    .wiki-content {
      flex: 1;
      overflow-y: auto;
      padding: 1rem 1.5rem;
    }
    
    .wiki-section {
      margin-bottom: 2rem;
    }
    
    .wiki-section-title {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      font-size: 1.05rem;
      font-weight: 600;
      margin-bottom: 0.75rem;
      padding-bottom: 0.5rem;
      border-bottom: 1px solid var(--border-color);
    }
    
    .wiki-quick-stats {
      display: flex;
      gap: 1rem;
      margin-top: 0.5rem;
      flex-wrap: wrap;
    }
    
    .wiki-stat {
      font-size: 0.8rem;
      color: var(--text-secondary);
    }
    
    /* Wiki File List Items */
    .wiki-folder {
      margin-bottom: 0.25rem;
    }
    
    .wiki-folder-header {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.4rem 0.5rem;
      cursor: pointer;
      border-radius: 6px;
      font-size: 0.85rem;
      font-weight: 500;
      transition: background 0.2s;
    }
    
    .wiki-folder-header:hover {
      background: var(--bg-secondary);
    }
    
    .wiki-folder-header .folder-icon {
      font-size: 0.7rem;
      transition: transform 0.2s;
    }
    
    .wiki-folder.collapsed .folder-icon {
      transform: rotate(-90deg);
    }
    
    .wiki-folder.collapsed .wiki-folder-files {
      display: none;
    }
    
    .wiki-folder-files {
      margin-left: 1rem;
    }
    
    .wiki-file-item {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.35rem 0.5rem;
      border-radius: 6px;
      cursor: pointer;
      font-size: 0.8rem;
      transition: all 0.2s;
    }
    
    .wiki-file-item:hover {
      background: var(--bg-secondary);
    }
    
    .wiki-file-item.active {
      background: var(--accent-primary);
      color: white;
    }
    
    .wiki-file-item .file-icon {
      font-size: 0.9rem;
    }
    
    .wiki-file-item .file-name {
      flex: 1;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    
    /* Wiki Infobox & Items */
    .wiki-infobox {
      background: var(--bg-primary);
      border-radius: 8px;
      padding: 1rem;
      margin-bottom: 1rem;
    }
    
    .wiki-infobox-row {
      display: flex;
      padding: 0.5rem 0;
      border-bottom: 1px solid var(--border-color);
    }
    
    .wiki-infobox-row:last-child {
      border-bottom: none;
    }
    
    .wiki-infobox-label {
      width: 120px;
      font-weight: 500;
      color: var(--text-muted);
      flex-shrink: 0;
    }
    
    .wiki-infobox-value {
      flex: 1;
      font-family: monospace;
    }
    
    .wiki-description {
      color: var(--text-secondary);
      line-height: 1.6;
      margin-bottom: 1rem;
    }
    
    .wiki-item-grid {
      display: grid;
      gap: 0.5rem;
    }
    
    .wiki-item {
      display: flex;
      align-items: flex-start;
      gap: 1rem;
      padding: 0.75rem;
      background: var(--bg-primary);
      border-radius: 8px;
      cursor: pointer;
      transition: all 0.2s;
    }
    
    .wiki-item:hover {
      background: var(--bg-secondary);
      transform: translateX(4px);
    }
    
    .wiki-item-line {
      font-family: monospace;
      font-size: 0.75rem;
      color: var(--text-muted);
      min-width: 50px;
    }
    
    .wiki-item-name {
      font-weight: 500;
      color: var(--accent-primary);
    }
    
    .wiki-item-type {
      font-size: 0.75rem;
      color: var(--text-muted);
      margin-left: 0.5rem;
    }
    
    .wiki-item-desc {
      font-size: 0.85rem;
      color: var(--text-secondary);
      margin-top: 0.25rem;
    }
    
    .wiki-item-badge {
      padding: 0.15rem 0.5rem;
      background: var(--bg-secondary);
      border-radius: 999px;
      font-size: 0.7rem;
      font-weight: 500;
    }
    
    .wiki-item-badge.public { background: rgba(16, 185, 129, 0.2); color: var(--accent-success); }
    .wiki-item-badge.private { background: rgba(239, 68, 68, 0.2); color: var(--accent-error); }
    .wiki-item-badge.callback { background: rgba(245, 158, 11, 0.2); color: var(--accent-warning); }
    .wiki-item-badge.override { background: rgba(99, 102, 241, 0.2); color: #818cf8; }
    
    .wiki-link-card {
      display: inline-flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.5rem 0.75rem;
      background: var(--bg-primary);
      border-radius: 8px;
      margin: 0.25rem;
      text-decoration: none;
      color: var(--text-primary);
      transition: all 0.2s;
    }
    
    .wiki-link-card:hover {
      background: var(--accent-primary);
      color: white;
    }
    
    .wiki-link-card.external {
      border: 1px solid var(--border-color);
    }
    
    .wiki-link-card.external:hover {
      border-color: var(--accent-primary);
    }
    
    .wiki-code-block {
      background: var(--bg-primary);
      border-radius: 8px;
      overflow: hidden;
    }
    
    .wiki-code-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 0.5rem 1rem;
      background: var(--bg-secondary);
      border-bottom: 1px solid var(--border-color);
    }
    
    .wiki-code-lang {
      font-size: 0.75rem;
      color: var(--text-muted);
      text-transform: uppercase;
    }
    
    .wiki-code-content {
      padding: 1rem;
      font-family: 'Cascadia Code', 'Fira Code', monospace;
      font-size: 0.8rem;
      line-height: 1.6;
      overflow-x: auto;
      max-height: 400px;
      overflow-y: auto;
    }
    
    .wiki-code-content .line {
      display: flex;
    }
    
    .wiki-code-content .line-num {
      display: inline-block;
      width: 45px;
      color: var(--text-muted);
      user-select: none;
      text-align: right;
      padding-right: 1rem;
      flex-shrink: 0;
    }
    
    .wiki-code-content .line-content {
      flex: 1;
    }
    
    .wiki-code-content .line.highlighted {
      background: rgba(245, 158, 11, 0.15);
    }
    
    .wiki-empty {
      padding: 2rem;
      text-align: center;
      color: var(--text-muted);
    }
    
    .wiki-tabs {
      display: flex;
      gap: 0.25rem;
      margin-bottom: 1rem;
    }
    
    .wiki-tab {
      padding: 0.5rem 1rem;
      border-radius: 8px 8px 0 0;
      cursor: pointer;
      font-size: 0.85rem;
      background: var(--bg-primary);
      border: 1px solid var(--border-color);
      border-bottom: none;
      transition: all 0.2s;
    }
    
    .wiki-tab.active {
      background: var(--bg-secondary);
      border-color: var(--accent-primary);
      color: var(--accent-primary);
    }
    
    /* Playground Styles */
    .playground {
      height: calc(100vh - 200px);
      display: flex;
      flex-direction: column;
    }
    
    .playground-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding-bottom: 1rem;
      border-bottom: 1px solid var(--border-color);
      margin-bottom: 1rem;
    }
    
    .playground-layout {
      display: flex;
      gap: 1rem;
      flex: 1;
      overflow: hidden;
    }
    
    .playground-editor {
      flex: 1;
      display: flex;
      flex-direction: column;
      background: var(--bg-card);
      border-radius: 8px;
      overflow: hidden;
    }
    
    .playground-editor-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 0.75rem 1rem;
      background: var(--bg-secondary);
      border-bottom: 1px solid var(--border-color);
    }
    
    .playground-editor-content {
      flex: 1;
      display: flex;
      flex-direction: column;
      overflow: hidden;
    }
    
    .playground-code {
      flex: 1;
      padding: 1rem;
      font-family: 'Cascadia Code', 'Fira Code', monospace;
      font-size: 0.85rem;
      line-height: 1.6;
      background: var(--bg-primary);
      border: none;
      resize: none;
      color: var(--text-primary);
      overflow: auto;
    }
    
    .playground-code:focus {
      outline: none;
    }
    
    .playground-sidebar {
      width: 320px;
      display: flex;
      flex-direction: column;
      gap: 1rem;
      overflow-y: auto;
    }
    
    .playground-panel {
      background: var(--bg-card);
      border-radius: 8px;
      overflow: hidden;
    }
    
    .playground-panel-header {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.75rem 1rem;
      background: var(--bg-secondary);
      border-bottom: 1px solid var(--border-color);
      font-weight: 500;
      cursor: pointer;
    }
    
    .playground-panel-header:hover {
      background: var(--bg-tertiary);
    }
    
    .playground-panel-content {
      padding: 1rem;
    }
    
    .playground-field {
      margin-bottom: 0.75rem;
    }
    
    .playground-field:last-child {
      margin-bottom: 0;
    }
    
    .playground-field-label {
      display: flex;
      align-items: center;
      justify-content: space-between;
      font-size: 0.8rem;
      color: var(--text-muted);
      margin-bottom: 0.25rem;
    }
    
    .playground-field-type {
      font-family: monospace;
      font-size: 0.7rem;
      padding: 0.1rem 0.3rem;
      background: var(--bg-primary);
      border-radius: 4px;
    }
    
    .playground-field input,
    .playground-field select {
      width: 100%;
      padding: 0.5rem;
      background: var(--bg-primary);
      border: 1px solid var(--border-color);
      border-radius: 6px;
      color: var(--text-primary);
      font-size: 0.85rem;
    }
    
    .playground-field input:focus,
    .playground-field select:focus {
      outline: none;
      border-color: var(--accent-primary);
    }
    
    .playground-field input[type="checkbox"] {
      width: auto;
      margin-right: 0.5rem;
    }
    
    .playground-field input[type="range"] {
      -webkit-appearance: none;
      height: 6px;
      border-radius: 3px;
      background: var(--bg-secondary);
    }
    
    .playground-field input[type="range"]::-webkit-slider-thumb {
      -webkit-appearance: none;
      width: 16px;
      height: 16px;
      border-radius: 50%;
      background: var(--accent-primary);
      cursor: pointer;
    }
    
    .playground-field input[type="color"] {
      width: 100%;
      height: 36px;
      padding: 2px;
      cursor: pointer;
    }
    
    .playground-help {
      font-size: 0.75rem;
      color: var(--text-muted);
      margin-top: 0.25rem;
      font-style: italic;
    }
    
    .playground-todo {
      margin-top: 1rem;
      padding: 1rem;
      background: var(--bg-primary);
      border-radius: 8px;
    }
    
    .playground-todo-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 0.5rem;
      background: var(--bg-card);
      border-radius: 6px;
      margin-bottom: 0.5rem;
      font-size: 0.85rem;
    }
    
    .playground-todo-item:last-child {
      margin-bottom: 0;
    }
    
    .todo-change-old {
      text-decoration: line-through;
      color: var(--accent-error);
    }
    
    .todo-change-new {
      color: var(--accent-success);
    }
    
    .todo-change-arrow {
      color: var(--text-muted);
      margin: 0 0.5rem;
    }
    
    /* Playground Code Editor */
    .code-editor {
      font-family: 'JetBrains Mono', 'Fira Code', 'Consolas', monospace;
      font-size: 0.8rem;
      line-height: 1.6;
      background: var(--bg-primary);
      border-radius: 8px;
      overflow: auto;
      max-height: 100%;
      min-width: 0;
    }
    
    .code-line {
      display: flex;
      min-height: 1.6em;
      white-space: nowrap;
    }
    
    .code-line:hover {
      background: rgba(255, 255, 255, 0.03);
    }
    
    .code-line.export-line {
      background: rgba(147, 51, 234, 0.1);
      border-left: 3px solid var(--accent-primary);
    }
    
    .code-line.modified-line {
      background: rgba(16, 185, 129, 0.15);
      border-left: 3px solid var(--accent-success);
    }
    
    .code-line.highlighted {
      background: rgba(147, 51, 234, 0.3) !important;
    }
    
    .code-line .line-number {
      flex-shrink: 0;
      width: 45px;
      padding: 0 0.75rem;
      text-align: right;
      color: var(--text-muted);
      user-select: none;
      background: var(--bg-secondary);
      border-right: 1px solid var(--border-color);
      font-size: 0.75rem;
    }
    
    .code-line .line-content {
      flex: 1;
      padding: 0 0.75rem;
      white-space: pre;
      overflow-x: visible;
      min-width: 0;
    }
    
    /* GDScript Syntax Highlighting */
    .code-line .kw { color: #c792ea; } /* Keywords */
    .code-line .str { color: #c3e88d; } /* Strings */
    .code-line .num { color: #f78c6c; } /* Numbers */
    .code-line .cmt { color: #546e7a; font-style: italic; } /* Comments */
    .code-line .fn { color: #82aaff; } /* Function names */
    
    .playground-panel.collapsed .playground-panel-content {
      display: none;
    }
    
    .playground-panel.collapsed .toggle-icon {
      transform: rotate(-90deg);
    }
    
    .toggle-icon {
      transition: transform 0.2s;
      margin-left: auto;
    }
    
    .info-row {
      display: flex;
      justify-content: space-between;
      padding: 0.25rem 0;
      font-size: 0.85rem;
    }
    
    .info-row code {
      font-family: monospace;
      background: var(--bg-secondary);
      padding: 0.1rem 0.3rem;
      border-radius: 3px;
      font-size: 0.8rem;
    }
    
    .field-type {
      font-size: 0.7rem;
      color: var(--text-muted);
    }
    
    .vector-input {
      display: flex;
      gap: 0.5rem;
    }
    
    .vector-input input {
      flex: 1;
    }
    
    .changes-list {
      display: flex;
      flex-direction: column;
      gap: 0.5rem;
    }
    
    .change-item {
      display: flex;
      align-items: center;
      font-size: 0.85rem;
      padding: 0.5rem;
      background: var(--bg-primary);
      border-radius: 4px;
    }
    
    .change-name {
      font-family: monospace;
      color: var(--accent-primary);
    }
    
    .change-arrow {
      margin: 0 0.5rem;
      color: var(--text-muted);
    }
    
    .change-value {
      font-family: monospace;
      color: var(--accent-success);
    }

    /* File Preview in wiki */
    .wiki-quick-info {
      padding: 1rem;
      background: var(--bg-primary);
      border-radius: 8px;
      margin-bottom: 1rem;
    }
    
    .wiki-quick-info h3 {
      margin: 0 0 0.5rem 0;
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }
    
    .wiki-quick-info .info-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 0.5rem;
      font-size: 0.85rem;
    }
    
    .wiki-quick-info .info-item {
      display: flex;
      justify-content: space-between;
    }
    
    .wiki-quick-info .info-label {
      color: var(--text-muted);
    }
    
    .wiki-action-bar {
      display: flex;
      gap: 0.5rem;
      margin-bottom: 1rem;
    }
    
    .wiki-empty {
      padding: 3rem;
      text-align: center;
      color: var(--text-muted);
    }
    
    .wiki-empty .icon {
      font-size: 3rem;
      margin-bottom: 0.5rem;
    }
    
    /* Dependency Graph */
    .dep-graph {
      padding: 1rem;
      background: var(--bg-primary);
      border-radius: 8px;
    }
    
    .dep-node {
      padding: 0.75rem 1rem;
      background: var(--bg-card);
      border-radius: 8px;
      margin-bottom: 0.5rem;
      border-left: 3px solid var(--accent-primary);
    }
    
    .dep-node .node-name {
      font-weight: 500;
      font-family: monospace;
    }
    
    .dep-node .node-deps {
      font-size: 0.8rem;
      color: var(--text-muted);
      margin-top: 0.25rem;
    }
    
    /* Scene Tree */
    .scene-tree {
      padding: 1rem;
    }
    
    .tree-node {
      margin-left: 1.5rem;
      position: relative;
    }
    
    .tree-node::before {
      content: '';
      position: absolute;
      left: -1rem;
      top: 0;
      height: 100%;
      width: 1px;
      background: var(--border-color);
    }
    
    .tree-node-header {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.25rem 0;
      cursor: pointer;
    }
    
    .tree-node-header:hover {
      color: var(--accent-primary);
    }
    
    .tree-node-icon {
      font-size: 1rem;
    }
    
    /* Export Buttons */
    .export-buttons {
      display: flex;
      gap: 0.5rem;
      margin-top: 1rem;
    }
    
    .export-btn {
      padding: 0.5rem 1rem;
      background: var(--bg-tertiary);
      border: 1px solid var(--border-color);
      border-radius: 6px;
      color: var(--text-secondary);
      font-size: 0.85rem;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 0.5rem;
      transition: all 0.2s;
    }
    
    .export-btn:hover {
      background: var(--accent-primary);
      color: white;
      border-color: var(--accent-primary);
    }
    
    /* Collapsible Sections */
    .collapsible {
      cursor: pointer;
    }
    
    .collapsible::before {
      content: '▼';
      display: inline-block;
      margin-right: 0.5rem;
      font-size: 0.75rem;
      transition: transform 0.2s;
    }
    
    .collapsible.collapsed::before {
      transform: rotate(-90deg);
    }
    
    .collapsible-content {
      overflow: hidden;
      transition: max-height 0.3s ease-out;
      max-height: 2000px;
    }
    
    .collapsible.collapsed + .collapsible-content {
      max-height: 0;
    }
    
    /* Trend Sparkline */
    .sparkline {
      display: inline-block;
      height: 30px;
      width: 80px;
    }
    
    .sparkline svg {
      width: 100%;
      height: 100%;
    }
    
    .trend-indicator {
      display: inline-flex;
      align-items: center;
      gap: 0.25rem;
      font-size: 0.8rem;
      padding: 0.25rem 0.5rem;
      border-radius: 4px;
    }
    
    .trend-indicator.up {
      color: var(--accent-success);
      background: rgba(34, 197, 94, 0.1);
    }
    
    .trend-indicator.down {
      color: var(--accent-error);
      background: rgba(239, 68, 68, 0.1);
    }
    
    .trend-indicator.neutral {
      color: var(--text-muted);
      background: var(--bg-tertiary);
    }
    
    /* Search Modal */
    .search-modal {
      max-width: 700px;
    }
    
    .search-input-group {
      display: flex;
      gap: 0.5rem;
      margin-bottom: 1rem;
    }
    
    .search-input-group input {
      flex: 1;
      padding: 0.75rem 1rem;
      background: var(--bg-primary);
      border: 1px solid var(--border-color);
      border-radius: 8px;
      color: var(--text-primary);
      font-size: 0.95rem;
    }
    
    .search-results {
      max-height: 400px;
      overflow-y: auto;
    }
    
    .search-result-item {
      padding: 0.75rem;
      border-bottom: 1px solid var(--border-subtle);
      cursor: pointer;
    }
    
    .search-result-item:hover {
      background: var(--bg-tertiary);
    }
    
    .search-result-file {
      font-size: 0.8rem;
      color: var(--text-muted);
      font-family: monospace;
    }
    
    .search-result-line {
      margin-top: 0.25rem;
      font-family: monospace;
      font-size: 0.85rem;
    }
    
    .search-result-line mark {
      background: rgba(245, 158, 11, 0.3);
      color: var(--accent-warning);
      border-radius: 2px;
      padding: 0 2px;
    }
    
    /* Terminal Modal */
    .terminal-modal {
      max-width: 800px;
    }
    
    .terminal-container {
      background: #0d1117;
      border-radius: 8px;
      overflow: hidden;
    }
    
    .terminal-header {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.75rem 1rem;
      background: #161b22;
    }
    
    .terminal-dot {
      width: 12px;
      height: 12px;
      border-radius: 50%;
    }
    
    .terminal-dot.red { background: #ff5f57; }
    .terminal-dot.yellow { background: #ffbd2e; }
    .terminal-dot.green { background: #28c840; }
    
    .terminal-body {
      padding: 1rem;
      font-family: 'Cascadia Code', 'Fira Code', monospace;
      font-size: 0.9rem;
      min-height: 300px;
      max-height: 400px;
      overflow-y: auto;
    }
    
    .terminal-line {
      margin-bottom: 0.25rem;
    }
    
    .terminal-prompt {
      color: var(--accent-success);
    }
    
    .terminal-input {
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }
    
    .terminal-input input {
      flex: 1;
      background: transparent;
      border: none;
      color: var(--text-primary);
      font-family: inherit;
      font-size: inherit;
      outline: none;
    }
    
    /* Toast Notifications */
    .toast-container {
      position: fixed;
      bottom: 20px;
      right: 20px;
      z-index: 10000;
      display: flex;
      flex-direction: column;
      gap: 0.5rem;
      pointer-events: none;  /* Allow clicks through when empty */
    }
    
    .toast {
      padding: 1rem 1.5rem;
      background: var(--bg-card);
      border: 1px solid var(--border-color);
      border-radius: 8px;
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
      display: flex;
      align-items: center;
      gap: 0.75rem;
      animation: slideIn 0.3s ease-out;
      min-width: 300px;
      pointer-events: auto;  /* Re-enable for actual toasts */
    }
    
    @keyframes slideIn {
      from { transform: translateX(100%); opacity: 0; }
      to { transform: translateX(0); opacity: 1; }
    }
    
    .toast.success { border-left: 4px solid var(--accent-success); }
    .toast.error { border-left: 4px solid var(--accent-error); }
    .toast.warning { border-left: 4px solid var(--accent-warning); }
    .toast.info { border-left: 4px solid var(--accent-primary); }
    
    /* ===== DEBUG PANEL STYLES ===== */
    .debug-panel {
      position: fixed;
      bottom: 60px;
      left: 20px;
      width: 450px;
      max-height: 350px;
      background: #0d1117;
      border: 1px solid #f85149;
      border-radius: 8px;
      z-index: 99999;
      font-family: 'JetBrains Mono', 'Consolas', monospace;
      font-size: 11px;
      box-shadow: 0 10px 40px rgba(248, 81, 73, 0.3);
      display: flex;
      flex-direction: column;
      overflow: hidden;
    }
    
    .debug-panel.minimized {
      max-height: 36px;
    }
    
    .debug-panel.minimized .debug-body,
    .debug-panel.minimized .debug-footer {
      display: none;
    }
    
    .debug-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 8px 12px;
      background: #161b22;
      border-bottom: 1px solid #30363d;
      color: #f85149;
      font-weight: 600;
    }
    
    .debug-actions {
      display: flex;
      gap: 4px;
    }
    
    .debug-actions button {
      background: transparent;
      border: none;
      cursor: pointer;
      padding: 4px 8px;
      border-radius: 4px;
      font-size: 12px;
    }
    
    .debug-actions button:hover {
      background: #30363d;
    }
    
    .debug-body {
      flex: 1;
      overflow-y: auto;
      padding: 8px;
      max-height: 250px;
    }
    
    .debug-log-list {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }
    
    .debug-log-entry {
      padding: 4px 8px;
      border-radius: 4px;
      background: #161b22;
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
      word-break: break-word;
    }
    
    .debug-log-entry.debug-click { border-left: 3px solid #a371f7; }
    .debug-log-entry.debug-info { border-left: 3px solid #58a6ff; }
    .debug-log-entry.debug-warn { border-left: 3px solid #d29922; }
    .debug-log-entry.debug-error { border-left: 3px solid #f85149; }
    .debug-log-entry.debug-debug { border-left: 3px solid #484f58; }
    
    .debug-time { color: #484f58; }
    .debug-level { color: #8b949e; font-weight: 600; }
    .debug-cat { color: #7ee787; }
    .debug-msg { color: #c9d1d9; flex: 1; }
    
    .debug-footer {
      display: flex;
      justify-content: space-between;
      padding: 6px 12px;
      background: #161b22;
      border-top: 1px solid #30363d;
      color: #8b949e;
    }
    
    .debug-toggle {
      position: fixed;
      bottom: 20px;
      left: 20px;
      width: 36px;
      height: 36px;
      background: #f85149;
      border: none;
      border-radius: 50%;
      cursor: pointer;
      font-size: 16px;
      z-index: 99998;
      box-shadow: 0 4px 12px rgba(248, 81, 73, 0.4);
      transition: transform 0.2s;
    }
    
    .debug-toggle:hover {
      transform: scale(1.1);
    }
    
    .debug-toggle.hidden {
      display: none;
    }

    /* ===== ENHANCED PLAYGROUND STYLES ===== */
    
    /* Template Picker */
    .playground-templates {
      display: flex;
      gap: 0.5rem;
      flex-wrap: wrap;
      margin-bottom: 1rem;
    }
    
    .template-btn {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.5rem 1rem;
      background: var(--bg-secondary);
      border: 1px solid var(--border-color);
      border-radius: 20px;
      color: var(--text-secondary);
      font-size: 0.85rem;
      cursor: pointer;
      transition: all 0.2s;
    }
    
    .template-btn:hover {
      background: var(--bg-tertiary);
      color: var(--text-primary);
      border-color: var(--accent-primary);
    }
    
    .template-btn.active {
      background: var(--accent-primary);
      color: white;
      border-color: var(--accent-primary);
    }
    
    /* Selection Context Panel */
    .selection-context {
      background: linear-gradient(135deg, rgba(147, 51, 234, 0.15) 0%, rgba(59, 130, 246, 0.1) 100%);
      border: 1px solid var(--accent-primary);
      border-radius: 8px;
      padding: 1rem;
      margin-bottom: 1rem;
    }
    
    .selection-context-header {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      margin-bottom: 0.75rem;
      font-weight: 600;
      color: var(--accent-primary);
    }
    
    .selection-context-content {
      font-size: 0.85rem;
    }
    
    .selection-highlight {
      background: rgba(147, 51, 234, 0.2);
      padding: 0.5rem;
      border-radius: 4px;
      font-family: monospace;
      margin: 0.5rem 0;
      overflow-x: auto;
    }
    
    /* Variable Documentation */
    .var-doc {
      padding: 0.75rem;
      background: var(--bg-primary);
      border-radius: 6px;
      margin-bottom: 0.75rem;
      border-left: 3px solid var(--accent-primary);
    }
    
    .var-doc-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 0.5rem;
    }
    
    .var-doc-name {
      font-family: monospace;
      font-weight: 600;
      color: var(--accent-primary);
    }
    
    .var-doc-type {
      font-size: 0.7rem;
      padding: 0.2rem 0.5rem;
      background: var(--bg-secondary);
      border-radius: 10px;
      color: var(--text-muted);
    }
    
    .var-doc-desc {
      font-size: 0.8rem;
      color: var(--text-secondary);
      margin-bottom: 0.5rem;
      line-height: 1.4;
    }
    
    .var-doc-effect {
      font-size: 0.75rem;
      color: var(--accent-warning);
      background: rgba(245, 158, 11, 0.1);
      padding: 0.4rem 0.6rem;
      border-radius: 4px;
      display: flex;
      align-items: center;
      gap: 0.25rem;
    }
    
    .var-doc-range {
      font-size: 0.7rem;
      color: var(--accent-info);
      background: rgba(59, 130, 246, 0.1);
      padding: 0.35rem 0.6rem;
      border-radius: 4px;
      margin-top: 0.35rem;
      font-family: var(--font-mono);
    }
    
    .var-doc-links {
      display: flex;
      gap: 0.5rem;
      margin-top: 0.5rem;
      flex-wrap: wrap;
    }
    
    .var-doc-link {
      font-size: 0.7rem;
      color: var(--accent-info);
      text-decoration: none;
      padding: 0.2rem 0.4rem;
      background: rgba(59, 130, 246, 0.1);
      border-radius: 4px;
      transition: all 0.2s;
    }
    
    .var-doc-link:hover {
      background: rgba(59, 130, 246, 0.2);
      color: var(--text-primary);
    }
    
    .var-doc-input {
      margin-top: 0.75rem;
      padding-top: 0.75rem;
      border-top: 1px solid var(--border-color);
    }
    
    /* Quick Actions */
    .quick-actions {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 0.5rem;
      margin-bottom: 1rem;
    }
    
    .quick-action {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.5rem 0.75rem;
      background: var(--bg-secondary);
      border: 1px solid var(--border-color);
      border-radius: 6px;
      color: var(--text-secondary);
      font-size: 0.8rem;
      cursor: pointer;
      transition: all 0.2s;
    }
    
    .quick-action:hover {
      background: var(--bg-tertiary);
      border-color: var(--accent-primary);
      color: var(--text-primary);
    }
    
    /* Code Selection Styles */
    .code-editor ::selection {
      background: rgba(147, 51, 234, 0.4);
    }
    
    .code-line.selected {
      background: rgba(147, 51, 234, 0.2) !important;
    }
    
    /* Suggestions Panel */
    .suggestions-panel {
      background: var(--bg-secondary);
      border-radius: 8px;
      padding: 0.75rem;
      margin-bottom: 1rem;
    }
    
    .suggestion-item {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.5rem;
      background: var(--bg-card);
      border-radius: 4px;
      margin-bottom: 0.5rem;
      font-size: 0.8rem;
      cursor: pointer;
      transition: all 0.2s;
    }
    
    .suggestion-item:hover {
      background: var(--bg-tertiary);
      transform: translateX(4px);
    }
    
    .suggestion-item:last-child {
      margin-bottom: 0;
    }
    
    /* Variable Sliders */
    .var-slider-container {
      display: flex;
      align-items: center;
      gap: 0.75rem;
    }
    
    .var-slider {
      flex: 1;
      -webkit-appearance: none;
      height: 6px;
      border-radius: 3px;
      background: var(--bg-secondary);
    }
    
    .var-slider::-webkit-slider-thumb {
      -webkit-appearance: none;
      width: 18px;
      height: 18px;
      border-radius: 50%;
      background: var(--accent-primary);
      cursor: pointer;
      box-shadow: 0 2px 6px rgba(147, 51, 234, 0.4);
    }
    
    .var-slider-value {
      min-width: 60px;
      text-align: right;
      font-family: monospace;
      color: var(--text-primary);
    }
    
    /* Color Preview */
    .color-preview {
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }
    
    .color-swatch {
      width: 32px;
      height: 32px;
      border-radius: 6px;
      border: 2px solid var(--border-color);
    }
    
    /* Vector2 Input Enhanced */
    .vector2-input {
      display: flex;
      gap: 0.5rem;
      align-items: center;
    }
    
    .vector2-input label {
      font-size: 0.7rem;
      color: var(--text-muted);
      min-width: 14px;
    }
    
    .vector2-input input {
      flex: 1;
      padding: 0.4rem;
      background: var(--bg-secondary);
      border: 1px solid var(--border-color);
      border-radius: 4px;
      color: var(--text-primary);
      font-family: monospace;
      font-size: 0.85rem;
    }
    
    /* Rarity Select */
    .rarity-select {
      display: flex;
      gap: 0.25rem;
    }
    
    .rarity-option {
      flex: 1;
      padding: 0.4rem;
      text-align: center;
      border: 1px solid var(--border-color);
      border-radius: 4px;
      cursor: pointer;
      font-size: 0.7rem;
      transition: all 0.2s;
    }
    
    .rarity-option:hover {
      border-color: var(--accent-primary);
    }
    
    .rarity-option.selected {
      border-color: currentColor;
      background: currentColor;
      color: white;
    }
    
    .rarity-common { color: #9ca3af; }
    .rarity-uncommon { color: #10b981; }
    .rarity-rare { color: #3b82f6; }
    .rarity-epic { color: #8b5cf6; }
    .rarity-legendary { color: #f59e0b; }
    
    /* Dropdown Select */
    .var-dropdown {
      width: 100%;
      padding: 0.5rem;
      background: var(--bg-secondary);
      border: 1px solid var(--border-color);
      border-radius: 6px;
      color: var(--text-primary);
      font-size: 0.85rem;
      cursor: pointer;
      transition: all 0.2s;
    }
    
    .var-dropdown:hover {
      border-color: var(--accent-primary);
    }
    
    .var-dropdown:focus {
      outline: none;
      border-color: var(--accent-primary);
      box-shadow: 0 0 0 2px rgba(147, 51, 234, 0.2);
    }
    
    /* Dimension Select (1-4 grid cells) */
    .dimension-select {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 0.25rem;
    }
    
    .dim-option {
      padding: 0.5rem;
      text-align: center;
      border: 1px solid var(--border-color);
      border-radius: 4px;
      cursor: pointer;
      font-size: 0.85rem;
      font-weight: 600;
      transition: all 0.2s;
      background: var(--bg-secondary);
    }
    
    .dim-option:hover {
      border-color: var(--accent-primary);
      background: rgba(147, 51, 234, 0.1);
    }
    
    .dim-option.selected {
      border-color: var(--accent-primary);
      background: var(--accent-primary);
      color: white;
    }
    
    /* Stack Size Select */
    .stack-select {
      display: grid;
      grid-template-columns: repeat(6, 1fr);
      gap: 0.25rem;
    }
    
    .stack-option {
      padding: 0.4rem;
      text-align: center;
      border: 1px solid var(--border-color);
      border-radius: 4px;
      cursor: pointer;
      font-size: 0.75rem;
      transition: all 0.2s;
      background: var(--bg-secondary);
    }
    
    .stack-option:hover {
      border-color: var(--accent-success);
      background: rgba(16, 185, 129, 0.1);
    }
    
    .stack-option.selected {
      border-color: var(--accent-success);
      background: var(--accent-success);
      color: white;
    }
    
    /* Tab System in Sidebar */
    .sidebar-tabs {
      display: flex;
      gap: 0.25rem;
      margin-bottom: 1rem;
      background: var(--bg-secondary);
      border-radius: 8px;
      padding: 0.25rem;
    }
    
    .sidebar-tab {
      flex: 1;
      padding: 0.5rem;
      text-align: center;
      border-radius: 6px;
      cursor: pointer;
      font-size: 0.8rem;
      color: var(--text-muted);
      transition: all 0.2s;
    }
    
    .sidebar-tab:hover {
      color: var(--text-primary);
    }
    
    .sidebar-tab.active {
      background: var(--accent-primary);
      color: white;
    }
    
    .sidebar-tab-content {
      display: none;
    }
    
    .sidebar-tab-content.active {
      display: block;
    }
    
    /* Preview Panel */
    .preview-panel {
      background: var(--bg-primary);
      border-radius: 8px;
      padding: 1rem;
      text-align: center;
    }
    
    .preview-canvas {
      width: 100%;
      height: 150px;
      background: var(--bg-secondary);
      border-radius: 6px;
      display: flex;
      align-items: center;
      justify-content: center;
      margin-bottom: 0.75rem;
      position: relative;
      overflow: hidden;
    }
    
    .preview-ship {
      width: 80px;
      height: 60px;
      background: var(--preview-hull, #555);
      border-radius: 8px;
      position: relative;
      border: 2px solid var(--preview-accent, #888);
    }
    
    .preview-label {
      font-size: 0.8rem;
      color: var(--text-muted);
    }
    
    /* Help Tooltips */
    .help-tooltip {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      width: 16px;
      height: 16px;
      background: var(--bg-secondary);
      border-radius: 50%;
      font-size: 0.65rem;
      color: var(--text-muted);
      cursor: help;
      margin-left: 0.25rem;
    }
    
    .help-tooltip:hover {
      background: var(--accent-primary);
      color: white;
    }
    
    /* ===== ENHANCED SELECTION CONTEXT ===== */
    .selection-context {
      background: linear-gradient(135deg, rgba(147, 51, 234, 0.12) 0%, rgba(59, 130, 246, 0.08) 100%);
      border: 1px solid rgba(147, 51, 234, 0.4);
      border-radius: 10px;
      padding: 1rem;
      margin-bottom: 1rem;
    }
    
    .selection-context-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 0.75rem;
    }
    
    .selection-context-title {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      font-weight: 600;
      color: var(--accent-primary);
      font-size: 0.9rem;
    }
    
    .selection-context-badge {
      font-size: 0.65rem;
      padding: 0.2rem 0.5rem;
      background: var(--accent-primary);
      color: white;
      border-radius: 10px;
    }
    
    .selection-code-block {
      background: var(--bg-primary);
      border: 1px solid var(--border-color);
      border-radius: 6px;
      padding: 0.75rem;
      font-family: 'JetBrains Mono', monospace;
      font-size: 0.8rem;
      overflow-x: auto;
      white-space: pre;
      margin-bottom: 0.75rem;
      max-height: 80px;
    }
    
    .context-section {
      margin-bottom: 0.75rem;
      padding-bottom: 0.75rem;
      border-bottom: 1px solid var(--border-color);
    }
    
    .context-section:last-child {
      margin-bottom: 0;
      padding-bottom: 0;
      border-bottom: none;
    }
    
    .context-section-title {
      font-size: 0.75rem;
      font-weight: 600;
      color: var(--text-muted);
      margin-bottom: 0.5rem;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    
    .context-tags {
      display: flex;
      flex-wrap: wrap;
      gap: 0.35rem;
    }
    
    .context-tag {
      font-size: 0.7rem;
      padding: 0.2rem 0.5rem;
      background: var(--bg-secondary);
      border: 1px solid var(--border-color);
      border-radius: 4px;
      color: var(--text-secondary);
    }
    
    .context-tag.type, .context-tag.tag-type { border-color: #3b82f6; color: #3b82f6; background: rgba(59, 130, 246, 0.1); }
    .context-tag.keyword, .context-tag.tag-keyword { border-color: #c792ea; color: #c792ea; background: rgba(199, 146, 234, 0.1); }
    .context-tag.function, .context-tag.tag-function { border-color: #82aaff; color: #82aaff; background: rgba(130, 170, 255, 0.1); }
    .context-tag.variable, .context-tag.tag-variable { border-color: #f78c6c; color: #f78c6c; background: rgba(247, 140, 108, 0.1); }
    .context-tag.signal, .context-tag.tag-signal { border-color: #10b981; color: #10b981; background: rgba(16, 185, 129, 0.1); }
    
    .selection-context-badge.badge-function { background: #82aaff; }
    .selection-context-badge.badge-signal { background: #10b981; }
    .selection-context-badge.badge-export { background: #f59e0b; }
    .selection-context-badge.badge-class { background: #8b5cf6; }
    .selection-context-badge.badge-resource { background: #3b82f6; }
    
    .selection-highlight {
      background: var(--bg-primary);
      border: 1px solid var(--border-color);
      border-radius: 6px;
      padding: 0.6rem;
      margin-bottom: 0.75rem;
      max-height: 60px;
      overflow: hidden;
    }
    
    .selection-highlight code {
      font-family: 'JetBrains Mono', monospace;
      font-size: 0.75rem;
      color: var(--text-secondary);
      white-space: pre-wrap;
      word-break: break-all;
    }
    
    .context-var {
      background: var(--bg-secondary);
      border-radius: 6px;
      padding: 0.6rem;
      margin-bottom: 0.5rem;
    }
    
    .context-var-header {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      flex-wrap: wrap;
    }
    
    .context-var-name {
      font-family: 'JetBrains Mono', monospace;
      font-weight: 600;
      color: var(--accent-primary);
    }
    
    .context-var-type {
      font-size: 0.7rem;
      padding: 0.15rem 0.4rem;
      background: rgba(59, 130, 246, 0.2);
      color: #60a5fa;
      border-radius: 3px;
      font-family: monospace;
    }
    
    .context-var-scope {
      font-size: 0.65rem;
      padding: 0.1rem 0.3rem;
      background: var(--bg-tertiary);
      color: var(--text-muted);
      border-radius: 3px;
    }
    
    .context-var-desc {
      font-size: 0.8rem;
      color: var(--text-secondary);
      margin-top: 0.35rem;
    }
    
    .context-var-effect {
      font-size: 0.75rem;
      color: var(--accent-warning);
      margin-top: 0.35rem;
    }
    
    .context-func-list {
      display: flex;
      flex-wrap: wrap;
      gap: 0.35rem;
    }
    
    .context-func {
      display: flex;
      align-items: center;
      gap: 0.25rem;
      padding: 0.25rem 0.5rem;
      background: var(--bg-secondary);
      border-radius: 4px;
      font-size: 0.75rem;
    }
    
    .context-func-name {
      font-family: monospace;
      color: #82aaff;
    }
    
    .context-func-link {
      color: var(--text-muted);
      text-decoration: none;
      font-size: 0.7rem;
    }
    
    .context-func-link:hover {
      color: var(--accent-primary);
    }
    
    .context-signal {
      display: flex;
      align-items: center;
      gap: 0.35rem;
      padding: 0.3rem 0.5rem;
      background: rgba(16, 185, 129, 0.1);
      border-radius: 4px;
      margin-bottom: 0.35rem;
    }
    
    .context-signal-icon {
      color: #10b981;
    }
    
    .context-signal-name {
      font-family: monospace;
      font-size: 0.8rem;
      color: #34d399;
    }
    
    .context-type-list {
      display: flex;
      flex-wrap: wrap;
      gap: 0.35rem;
    }
    
    .context-type-link {
      font-size: 0.75rem;
      padding: 0.25rem 0.5rem;
      background: rgba(59, 130, 246, 0.1);
      border: 1px solid rgba(59, 130, 246, 0.3);
      border-radius: 4px;
      color: #60a5fa;
      text-decoration: none;
      font-family: monospace;
      transition: all 0.2s;
    }
    
    .context-type-link:hover {
      background: rgba(59, 130, 246, 0.2);
      border-color: #3b82f6;
    }
    
    .context-actions {
      display: flex;
      gap: 0.5rem;
      margin-top: 0.75rem;
      padding-top: 0.75rem;
      border-top: 1px solid var(--border-color);
    }
    
    .context-action-btn {
      flex: 1;
      padding: 0.4rem 0.5rem;
      font-size: 0.7rem;
      background: var(--bg-secondary);
      border: 1px solid var(--border-color);
      border-radius: 4px;
      cursor: pointer;
      color: var(--text-secondary);
      transition: all 0.2s;
    }
    
    .context-action-btn:hover {
      background: var(--accent-primary);
      border-color: var(--accent-primary);
      color: white;
    }
    
    .context-doc-card {
      background: var(--bg-secondary);
      border-radius: 6px;
      padding: 0.75rem;
      margin-bottom: 0.5rem;
    }
    
    .context-doc-title {
      font-family: monospace;
      font-weight: 600;
      color: var(--accent-primary);
      font-size: 0.85rem;
    }
    
    .context-doc-desc {
      font-size: 0.8rem;
      color: var(--text-secondary);
      margin-top: 0.25rem;
    }
    
    .context-doc-effect {
      font-size: 0.75rem;
      color: var(--accent-warning);
      margin-top: 0.5rem;
      padding: 0.4rem;
      background: rgba(245, 158, 11, 0.1);
      border-radius: 4px;
    }
    
    .context-links {
      display: flex;
      gap: 0.5rem;
      flex-wrap: wrap;
      margin-top: 0.5rem;
    }
    
    .context-link {
      font-size: 0.7rem;
      color: var(--accent-info);
      text-decoration: none;
      padding: 0.25rem 0.5rem;
      background: rgba(59, 130, 246, 0.1);
      border-radius: 4px;
      display: flex;
      align-items: center;
      gap: 0.25rem;
      transition: all 0.2s;
    }
    
    .context-link:hover {
      background: rgba(59, 130, 246, 0.2);
    }
    
    /* ===== STICKY PREVIEW & SCROLLABLE SIDEBAR ===== */
    .preview-sticky {
      position: sticky;
      top: 0;
      z-index: 10;
      background: var(--bg-secondary);
      padding-bottom: 0.5rem;
      margin: -1rem -1rem 0 -1rem;
      padding: 1rem;
      border-bottom: 1px solid var(--border-color);
    }
    
    .sidebar-scrollable {
      overflow-y: auto;
      flex: 1;
      padding-top: 0.5rem;
    }
    
    /* ===== ITEM PREVIEW SYSTEM ===== */
    .preview-container {
      background: var(--bg-card);
      border-radius: 10px;
      padding: 1rem;
      margin-bottom: 0;
    }
    
    .preview-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 1rem;
    }
    
    .preview-title {
      font-weight: 600;
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }
    
    .preview-tabs {
      display: flex;
      gap: 0.25rem;
    }
    
    .preview-tab {
      padding: 0.35rem 0.75rem;
      font-size: 0.75rem;
      border-radius: 4px;
      cursor: pointer;
      background: var(--bg-secondary);
      color: var(--text-muted);
      border: 1px solid transparent;
      transition: all 0.2s;
    }
    
    .preview-tab:hover {
      color: var(--text-primary);
    }
    
    .preview-tab.active {
      background: var(--accent-primary);
      color: white;
    }
    
    /* Inventory Grid Preview */
    .inventory-grid-preview {
      background: var(--bg-primary);
      border: 2px solid var(--border-color);
      border-radius: 8px;
      padding: 0.5rem;
      display: inline-block;
    }
    
    .inventory-grid {
      display: grid;
      grid-template-columns: repeat(8, 40px);
      grid-template-rows: repeat(4, 40px);
      gap: 2px;
      background: var(--border-color);
      padding: 2px;
      border-radius: 4px;
    }
    
    .inventory-cell {
      background: var(--bg-secondary);
      border-radius: 2px;
      position: relative;
    }
    
    .inventory-cell.occupied {
      background: var(--bg-tertiary);
    }
    
    .inventory-item {
      position: absolute;
      background: linear-gradient(135deg, var(--item-bg, #3b3b4f) 0%, var(--item-bg-dark, #2a2a3a) 100%);
      border: 2px solid var(--item-border, #555);
      border-radius: 4px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 1.5rem;
      cursor: pointer;
      transition: all 0.2s;
      z-index: 10;
    }
    
    .inventory-item:hover {
      transform: scale(1.05);
      z-index: 20;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.4);
    }
    
    .inventory-item.rarity-common { --item-border: #9ca3af; --item-bg: #374151; --item-bg-dark: #1f2937; }
    .inventory-item.rarity-uncommon { --item-border: #10b981; --item-bg: #064e3b; --item-bg-dark: #022c22; }
    .inventory-item.rarity-rare { --item-border: #3b82f6; --item-bg: #1e3a5f; --item-bg-dark: #0c1929; }
    .inventory-item.rarity-epic { --item-border: #8b5cf6; --item-bg: #4c1d95; --item-bg-dark: #2e1065; }
    .inventory-item.rarity-legendary { --item-border: #f59e0b; --item-bg: #78350f; --item-bg-dark: #451a03; }
    
    .inventory-item.rarity-legendary::before {
      content: '';
      position: absolute;
      inset: -4px;
      background: linear-gradient(45deg, #f59e0b, #fbbf24, #f59e0b);
      border-radius: 6px;
      z-index: -1;
      animation: legendaryGlow 2s ease-in-out infinite;
    }
    
    @keyframes legendaryGlow {
      0%, 100% { opacity: 0.5; }
      50% { opacity: 1; }
    }
    
    /* Item Tooltip Preview */
    .tooltip-preview {
      background: linear-gradient(180deg, #1a1a2e 0%, #16162a 100%);
      border: 2px solid var(--tooltip-border, #555);
      border-radius: 8px;
      padding: 1rem;
      min-width: 280px;
      max-width: 320px;
      box-shadow: 0 8px 32px rgba(0, 0, 0, 0.5);
    }
    
    .tooltip-preview.rarity-common { --tooltip-border: #9ca3af; }
    .tooltip-preview.rarity-uncommon { --tooltip-border: #10b981; }
    .tooltip-preview.rarity-rare { --tooltip-border: #3b82f6; }
    .tooltip-preview.rarity-epic { --tooltip-border: #8b5cf6; }
    .tooltip-preview.rarity-legendary { --tooltip-border: #f59e0b; }
    
    .tooltip-header {
      display: flex;
      gap: 0.75rem;
      margin-bottom: 0.75rem;
      padding-bottom: 0.75rem;
      border-bottom: 1px solid var(--border-color);
    }
    
    .tooltip-icon {
      width: 48px;
      height: 48px;
      background: var(--bg-secondary);
      border: 2px solid var(--tooltip-border, #555);
      border-radius: 6px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 1.5rem;
    }
    
    .tooltip-title-section {
      flex: 1;
    }
    
    .tooltip-name {
      font-weight: 600;
      font-size: 1rem;
      color: var(--tooltip-border, #fff);
    }
    
    .tooltip-rarity {
      font-size: 0.75rem;
      color: var(--tooltip-border);
      text-transform: uppercase;
      letter-spacing: 1px;
    }
    
    .tooltip-desc {
      font-size: 0.85rem;
      color: var(--text-secondary);
      font-style: italic;
      margin-bottom: 0.75rem;
      line-height: 1.4;
    }
    
    .tooltip-stats {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 0.5rem;
      margin-bottom: 0.75rem;
    }
    
    .tooltip-stat {
      display: flex;
      justify-content: space-between;
      font-size: 0.8rem;
      padding: 0.35rem 0.5rem;
      background: var(--bg-secondary);
      border-radius: 4px;
    }
    
    .tooltip-stat-label {
      color: var(--text-muted);
    }
    
    .tooltip-stat-value {
      color: var(--text-primary);
      font-family: monospace;
    }
    
    .tooltip-tags {
      display: flex;
      flex-wrap: wrap;
      gap: 0.35rem;
      margin-top: 0.75rem;
      padding-top: 0.75rem;
      border-top: 1px solid var(--border-color);
    }
    
    .tooltip-tag {
      font-size: 0.65rem;
      padding: 0.15rem 0.4rem;
      background: var(--bg-tertiary);
      border-radius: 3px;
      color: var(--text-muted);
    }
    
    /* ===== GRID PREVIEW ENHANCEMENTS ===== */
    .grid-preview-wrapper {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 0.75rem;
    }
    
    .size-indicator {
      background: var(--bg-secondary);
      padding: 0.25rem 0.75rem;
      border-radius: 4px;
      font-size: 0.75rem;
    }
    
    .size-label {
      color: var(--text-muted);
      font-size: 0.75rem;
    }
    
    .size-controls {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      margin-bottom: 0.75rem;
      padding: 0.5rem 0.75rem;
      background: var(--bg-secondary);
      border-radius: 8px;
    }
    
    .size-inputs {
      display: flex;
      align-items: center;
      gap: 0.4rem;
    }
    
    .size-input {
      width: 50px;
      padding: 0.4rem 0.5rem;
      font-size: 0.85rem;
      font-family: monospace;
      text-align: center;
      background: var(--bg-tertiary);
      border: 1px solid var(--border-color);
      border-radius: 4px;
      color: var(--text-primary);
    }
    
    .size-input:focus {
      outline: none;
      border-color: var(--accent-primary);
    }
    
    .size-x {
      font-size: 0.9rem;
      color: var(--text-muted);
      font-weight: bold;
    }
    
    .size-hint {
      font-size: 0.7rem;
      color: var(--text-muted);
      margin-left: 0.25rem;
    }
    
    .icon-controls {
      width: 100%;
      background: var(--bg-secondary);
      border-radius: 8px;
      padding: 0.75rem;
      margin-top: 0.5rem;
    }
    
    .icon-control-row {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      margin-bottom: 0.5rem;
    }
    
    .icon-control-row:last-of-type {
      margin-bottom: 0.75rem;
    }
    
    .icon-control-label {
      font-size: 0.7rem;
      color: var(--text-muted);
      width: 50px;
    }
    
    .icon-slider {
      flex: 1;
      height: 4px;
      -webkit-appearance: none;
      appearance: none;
      background: var(--border-color);
      border-radius: 2px;
      cursor: pointer;
    }
    
    .icon-slider::-webkit-slider-thumb {
      -webkit-appearance: none;
      appearance: none;
      width: 14px;
      height: 14px;
      background: var(--accent-primary);
      border-radius: 50%;
      cursor: pointer;
    }
    
    .icon-control-value {
      font-size: 0.7rem;
      color: var(--text-muted);
      width: 35px;
      text-align: right;
      font-family: monospace;
    }
    
    .btn-sm {
      padding: 0.35rem 0.75rem;
      font-size: 0.7rem;
    }
    
    /* ===== EDITABLE TOOLTIP ===== */
    .tooltip-preview.editable {
      padding: 1rem;
    }
    
    .tooltip-preview.floating {
      max-width: 250px;
      padding: 0.75rem;
      box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
    }
    
    .edit-field {
      width: 100%;
      padding: 0.4rem 0.5rem;
      background: var(--bg-secondary);
      border: 1px solid var(--border-color);
      border-radius: 4px;
      color: var(--text-primary);
      font-size: 0.85rem;
      transition: all 0.2s;
    }
    
    .edit-field:focus {
      outline: none;
      border-color: var(--accent-primary);
      box-shadow: 0 0 0 2px rgba(147, 51, 234, 0.2);
    }
    
    .edit-name {
      font-size: 1rem;
      font-weight: 600;
      margin-bottom: 0.35rem;
    }
    
    .edit-rarity {
      font-size: 0.8rem;
      padding: 0.25rem 0.4rem;
      cursor: pointer;
    }
    
    .edit-desc {
      width: 100%;
      min-height: 60px;
      margin: 0.75rem 0;
      resize: vertical;
      font-size: 0.8rem;
      line-height: 1.4;
    }
    
    .edit-stats-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 0.5rem;
      margin-bottom: 0.75rem;
    }
    
    .edit-stat {
      display: flex;
      flex-direction: column;
      gap: 0.25rem;
    }
    
    .edit-stat label {
      font-size: 0.7rem;
      color: var(--text-muted);
    }
    
    .edit-stat input,
    .edit-stat select {
      padding: 0.35rem 0.5rem;
      background: var(--bg-secondary);
      border: 1px solid var(--border-color);
      border-radius: 4px;
      color: var(--text-primary);
      font-size: 0.8rem;
    }
    
    .edit-stat input:focus,
    .edit-stat select:focus {
      outline: none;
      border-color: var(--accent-primary);
    }
    
    .edit-size-row {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      padding-top: 0.5rem;
      border-top: 1px solid var(--border-color);
    }
    
    .edit-size-row label {
      font-size: 0.75rem;
      color: var(--text-muted);
    }
    
    .edit-size-inputs {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      flex: 1;
    }
    
    .edit-size-inputs span {
      font-size: 0.7rem;
      color: var(--text-muted);
    }
    
    .edit-size-inputs input {
      width: 50px;
      padding: 0.3rem;
      background: var(--bg-secondary);
      border: 1px solid var(--border-color);
      border-radius: 4px;
      color: var(--text-primary);
      font-size: 0.8rem;
      text-align: center;
    }
    
    /* ===== ASSET GENERATOR ===== */
    .asset-generator {
      background: var(--bg-card);
      border-radius: 10px;
      padding: 1rem;
      margin-bottom: 1rem;
    }
    
    .asset-generator-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 1rem;
    }
    
    .asset-generator-title {
      font-weight: 600;
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }
    
    .asset-type-select {
      display: flex;
      gap: 0.5rem;
      margin-bottom: 1rem;
    }
    
    .asset-type-btn {
      flex: 1;
      padding: 0.75rem;
      background: var(--bg-secondary);
      border: 1px solid var(--border-color);
      border-radius: 6px;
      text-align: center;
      cursor: pointer;
      transition: all 0.2s;
    }
    
    .asset-type-btn:hover {
      border-color: var(--accent-primary);
    }
    
    .asset-type-btn.active {
      background: var(--accent-primary);
      border-color: var(--accent-primary);
      color: white;
    }
    
    .asset-type-btn .icon {
      font-size: 1.5rem;
      display: block;
      margin-bottom: 0.25rem;
    }
    
    .asset-type-btn .label {
      font-size: 0.75rem;
    }
    
    .asset-options {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 0.75rem;
      margin-bottom: 1rem;
    }
    
    .asset-option {
      display: flex;
      flex-direction: column;
      gap: 0.25rem;
    }
    
    .asset-option label {
      font-size: 0.75rem;
      color: var(--text-muted);
    }
    
    .asset-option input,
    .asset-option select {
      padding: 0.5rem;
      background: var(--bg-primary);
      border: 1px solid var(--border-color);
      border-radius: 4px;
      color: var(--text-primary);
      font-size: 0.85rem;
    }
    
    .asset-preview-area {
      background: var(--bg-primary);
      border: 2px dashed var(--border-color);
      border-radius: 8px;
      padding: 1.5rem;
      text-align: center;
      min-height: 150px;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      margin-bottom: 1rem;
    }
    
    .asset-preview-area svg {
      max-width: 100%;
      max-height: 120px;
    }
    
    .asset-preview-placeholder {
      color: var(--text-muted);
      font-size: 0.85rem;
    }
    
    .asset-actions {
      display: flex;
      gap: 0.5rem;
    }
    
    .asset-actions .btn {
      flex: 1;
    }
    
    /* ========== DAW SOUND STUDIO - CLEAN REDESIGN ========== */
    
    .daw-container {
      display: grid;
      grid-template-rows: 56px 1fr 48px;
      height: calc(100vh - 140px);
      background: #0d1117;
      border-radius: 12px;
      overflow: hidden;
      border: 1px solid #21262d;
    }
    
    /* === TRANSPORT BAR === */
    .daw-transport {
      display: flex;
      align-items: center;
      gap: 1.5rem;
      padding: 0 1.25rem;
      background: linear-gradient(180deg, #161b22 0%, #0d1117 100%);
      border-bottom: 1px solid #21262d;
    }
    
    .transport-brand {
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }
    
    .transport-brand-icon {
      width: 32px;
      height: 32px;
      background: linear-gradient(135deg, #58a6ff 0%, #a371f7 100%);
      border-radius: 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 1rem;
    }
    
    .transport-brand-text {
      font-weight: 600;
      font-size: 1rem;
      color: #e6edf3;
    }
    
    .transport-divider {
      width: 1px;
      height: 28px;
      background: #21262d;
    }
    
    .transport-buttons {
      display: flex;
      align-items: center;
      gap: 0.25rem;
      background: #21262d;
      padding: 4px;
      border-radius: 8px;
    }
    
    .transport-btn {
      width: 36px;
      height: 32px;
      display: flex;
      align-items: center;
      justify-content: center;
      background: transparent;
      border: none;
      border-radius: 6px;
      cursor: pointer;
      font-size: 0.9rem;
      color: #8b949e;
      transition: all 0.15s ease;
    }
    
    .transport-btn:hover {
      background: #30363d;
      color: #e6edf3;
    }
    
    .transport-btn.active {
      background: #238636;
      color: white;
    }
    
    .transport-btn.record:hover {
      background: rgba(248, 81, 73, 0.2);
      color: #f85149;
    }
    
    .transport-btn.record.active {
      background: #f85149;
      color: white;
      animation: pulse-rec 1.5s infinite;
    }
    
    @keyframes pulse-rec {
      0%, 100% { opacity: 1; }
      50% { opacity: 0.7; }
    }
    
    .transport-time {
      font-family: 'SF Mono', 'Consolas', monospace;
      font-size: 1.5rem;
      font-weight: 500;
      color: #3fb950;
      background: #0d1117;
      padding: 0.35rem 0.75rem;
      border-radius: 6px;
      border: 1px solid #21262d;
      min-width: 130px;
      text-align: center;
      letter-spacing: 1px;
    }
    
    .transport-bpm {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      color: #8b949e;
      font-size: 0.85rem;
    }
    
    .transport-bpm input {
      width: 50px;
      background: #21262d;
      border: 1px solid #30363d;
      border-radius: 4px;
      padding: 0.25rem 0.5rem;
      color: #e6edf3;
      font-size: 0.85rem;
      text-align: center;
    }
    
    .transport-spacer { flex: 1; }
    
    .transport-actions {
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }
    
    .transport-select {
      padding: 0.4rem 0.75rem;
      background: #21262d;
      border: 1px solid #30363d;
      border-radius: 6px;
      color: #e6edf3;
      font-size: 0.8rem;
      cursor: pointer;
    }
    
    .transport-action-btn {
      padding: 0.4rem 0.75rem;
      background: #21262d;
      border: 1px solid #30363d;
      border-radius: 6px;
      color: #e6edf3;
      font-size: 0.8rem;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 0.35rem;
      transition: all 0.15s ease;
    }
    
    .transport-action-btn:hover {
      background: #30363d;
      border-color: #8b949e;
    }
    
    .transport-action-btn.primary {
      background: linear-gradient(135deg, #238636, #2ea043);
      border-color: #238636;
    }
    
    .transport-action-btn.primary:hover {
      background: linear-gradient(135deg, #2ea043, #3fb950);
    }
    
    /* === MAIN CONTENT AREA === */
    .daw-main {
      display: grid;
      grid-template-columns: 260px 1fr 300px;
      overflow: hidden;
    }
    
    /* === BROWSER PANEL (Left) === */
    .daw-browser {
      background: #161b22;
      border-right: 1px solid #21262d;
      display: flex;
      flex-direction: column;
      overflow: hidden;
    }
    
    .browser-header {
      padding: 0.75rem;
      border-bottom: 1px solid #21262d;
    }
    
    .browser-search {
      width: 100%;
      padding: 0.5rem 0.75rem;
      padding-left: 2rem;
      background: #0d1117;
      border: 1px solid #21262d;
      border-radius: 6px;
      color: #e6edf3;
      font-size: 0.85rem;
      background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='16' height='16' fill='%238b949e' viewBox='0 0 16 16'%3E%3Cpath d='M11.742 10.344a6.5 6.5 0 1 0-1.397 1.398h-.001c.03.04.062.078.098.115l3.85 3.85a1 1 0 0 0 1.415-1.414l-3.85-3.85a1.007 1.007 0 0 0-.115-.1zM12 6.5a5.5 5.5 0 1 1-11 0 5.5 5.5 0 0 1 11 0z'/%3E%3C/svg%3E");
      background-repeat: no-repeat;
      background-position: 0.6rem center;
    }
    
    .browser-search:focus {
      outline: none;
      border-color: #58a6ff;
      box-shadow: 0 0 0 3px rgba(88, 166, 255, 0.15);
    }
    
    .browser-search::placeholder {
      color: #484f58;
    }
    
    .browser-categories {
      display: flex;
      flex-wrap: wrap;
      gap: 0.35rem;
      padding: 0.75rem;
      border-bottom: 1px solid #21262d;
    }
    
    .cat-btn {
      padding: 0.3rem 0.6rem;
      font-size: 0.7rem;
      font-weight: 500;
      background: #21262d;
      border: 1px solid transparent;
      border-radius: 20px;
      cursor: pointer;
      color: #8b949e;
      transition: all 0.15s ease;
    }
    
    .cat-btn:hover {
      background: #30363d;
      color: #e6edf3;
    }
    
    .cat-btn.active {
      background: #388bfd;
      color: white;
    }
    
    .browser-sounds {
      flex: 1;
      overflow-y: auto;
      padding: 0.5rem;
    }
    
    .browser-sounds::-webkit-scrollbar {
      width: 8px;
    }
    
    .browser-sounds::-webkit-scrollbar-track {
      background: transparent;
    }
    
    .browser-sounds::-webkit-scrollbar-thumb {
      background: #30363d;
      border-radius: 4px;
    }
    
    .sound-item {
      display: flex;
      align-items: center;
      gap: 0.6rem;
      padding: 0.5rem 0.6rem;
      background: #0d1117;
      border-radius: 6px;
      margin-bottom: 0.35rem;
      cursor: grab;
      border: 1px solid transparent;
      transition: all 0.15s ease;
    }
    
    .sound-item:hover {
      background: #21262d;
      border-color: #30363d;
    }
    
    .sound-item:active {
      cursor: grabbing;
    }
    
    .sound-icon {
      width: 28px;
      height: 28px;
      background: linear-gradient(135deg, #21262d, #30363d);
      border-radius: 6px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 0.85rem;
      flex-shrink: 0;
    }
    
    .sound-info {
      flex: 1;
      min-width: 0;
    }
    
    .sound-name {
      font-size: 0.8rem;
      font-weight: 500;
      color: #e6edf3;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    
    .sound-meta {
      font-size: 0.65rem;
      color: #484f58;
      margin-top: 1px;
    }
    
    .sound-preview-btn {
      width: 26px;
      height: 26px;
      background: #238636;
      border: none;
      border-radius: 50%;
      cursor: pointer;
      font-size: 0.7rem;
      color: white;
      opacity: 0;
      transition: all 0.15s ease;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    
    .sound-item:hover .sound-preview-btn {
      opacity: 1;
    }
    
    .sound-preview-btn:hover {
      background: #3fb950;
      transform: scale(1.1);
    }
    
    /* === TIMELINE AREA (Center) === */
    .daw-timeline {
      display: flex;
      flex-direction: column;
      background: #0d1117;
      overflow: hidden;
    }
    
    .timeline-ruler {
      height: 32px;
      background: #161b22;
      border-bottom: 1px solid #21262d;
      position: relative;
      display: flex;
      align-items: flex-end;
      padding-left: 140px;
      overflow: hidden;
    }
    
    .ruler-mark {
      position: absolute;
      font-size: 0.65rem;
      color: #484f58;
      padding-bottom: 4px;
    }
    
    .timeline-content {
      flex: 1;
      overflow: auto;
      position: relative;
    }
    
    .timeline-tracks {
      min-height: 100%;
    }
    
    .track-lane {
      height: 72px;
      display: flex;
      border-bottom: 1px solid #21262d;
      background: #0d1117;
    }
    
    .track-lane:nth-child(even) {
      background: #0a0e14;
    }
    
    .track-header {
      width: 140px;
      flex-shrink: 0;
      background: #161b22;
      border-right: 1px solid #21262d;
      padding: 0.5rem;
      display: flex;
      flex-direction: column;
      justify-content: center;
      gap: 0.35rem;
    }
    
    .track-name {
      font-size: 0.8rem;
      font-weight: 500;
      color: #e6edf3;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    
    .track-controls {
      display: flex;
      gap: 0.25rem;
    }
    
    .track-ctrl-btn {
      width: 24px;
      height: 20px;
      font-size: 0.6rem;
      font-weight: 600;
      background: #21262d;
      border: none;
      border-radius: 3px;
      cursor: pointer;
      color: #484f58;
      transition: all 0.15s ease;
    }
    
    .track-ctrl-btn:hover {
      background: #30363d;
      color: #8b949e;
    }
    
    .track-ctrl-btn.muted {
      background: #9e6a03;
      color: #f0c14b;
    }
    
    .track-ctrl-btn.solo {
      background: #1f6feb;
      color: #79c0ff;
    }
    
    .track-ctrl-btn.delete:hover {
      background: #da3633;
      color: white;
    }
    
    .track-clips-area {
      flex: 1;
      position: relative;
      background: repeating-linear-gradient(
        90deg,
        transparent 0px,
        transparent 99px,
        #21262d 99px,
        #21262d 100px
      );
    }
    
    .clip {
      position: absolute;
      top: 6px;
      height: calc(100% - 12px);
      background: linear-gradient(180deg, #58a6ff 0%, #388bfd 100%);
      border-radius: 6px;
      cursor: pointer;
      overflow: hidden;
      border: 2px solid transparent;
      min-width: 50px;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
      transition: border-color 0.15s ease;
    }
    
    .clip:hover {
      border-color: rgba(255, 255, 255, 0.3);
    }
    
    .clip.selected {
      border-color: #f0c14b;
      box-shadow: 0 0 12px rgba(240, 193, 75, 0.4);
    }
    
    .clip.category-ui { background: linear-gradient(180deg, #58a6ff, #388bfd); }
    .clip.category-combat { background: linear-gradient(180deg, #f85149, #da3633); }
    .clip.category-explosions { background: linear-gradient(180deg, #f0883e, #db6d28); }
    .clip.category-ship { background: linear-gradient(180deg, #a371f7, #8957e5); }
    .clip.category-boarding { background: linear-gradient(180deg, #d29922, #bb8009); }
    .clip.category-loot { background: linear-gradient(180deg, #3fb950, #238636); }
    .clip.category-alerts { background: linear-gradient(180deg, #db6d28, #bd561d); }
    .clip.category-ambient { background: linear-gradient(180deg, #79c0ff, #58a6ff); }
    .clip.category-footsteps { background: linear-gradient(180deg, #8b949e, #6e7681); }
    .clip.category-voices { background: linear-gradient(180deg, #f778ba, #db61a2); }
    .clip.category-impacts { background: linear-gradient(180deg, #ff7b72, #f85149); }
    .clip.category-music { background: linear-gradient(180deg, #d2a8ff, #a371f7); }
    
    .clip-label {
      padding: 4px 8px;
      font-size: 0.7rem;
      font-weight: 500;
      color: white;
      background: rgba(0, 0, 0, 0.25);
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    
    .clip-wave {
      flex: 1;
      margin: 2px 4px 4px 4px;
      background: rgba(255, 255, 255, 0.15);
      border-radius: 3px;
      overflow: hidden;
    }
    
    .clip-wave-inner {
      height: 100%;
      background: repeating-linear-gradient(
        90deg,
        rgba(255,255,255,0.3) 0px,
        rgba(255,255,255,0.5) 1px,
        rgba(255,255,255,0.3) 2px,
        rgba(255,255,255,0.2) 3px
      );
    }
    
    /* Clip drag and resize */
    .clip.dragging {
      opacity: 0.5;
      cursor: grabbing;
    }
    
    .clip-resize-handle {
      position: absolute;
      top: 0;
      bottom: 0;
      width: 8px;
      cursor: ew-resize;
      background: transparent;
      z-index: 10;
    }
    
    .clip-resize-handle.left {
      left: 0;
      border-radius: 6px 0 0 6px;
    }
    
    .clip-resize-handle.right {
      right: 0;
      border-radius: 0 6px 6px 0;
    }
    
    .clip-resize-handle:hover {
      background: rgba(255, 255, 255, 0.2);
    }
    
    /* Track drag feedback */
    .track-lane.drop-target {
      background: rgba(88, 166, 255, 0.1) !important;
    }
    
    .track-lane.drop-target .track-header {
      background: rgba(88, 166, 255, 0.15);
    }
    
    .drop-indicator {
      position: absolute;
      top: 0;
      bottom: 0;
      width: 3px;
      background: #58a6ff;
      z-index: 100;
      pointer-events: none;
      box-shadow: 0 0 10px rgba(88, 166, 255, 0.5);
    }
    
    /* Track name input */
    .track-name-input {
      width: 100%;
      background: transparent;
      border: 1px solid transparent;
      border-radius: 4px;
      padding: 2px 4px;
      font-size: 0.8rem;
      font-weight: 500;
      color: #e6edf3;
      outline: none;
    }
    
    .track-name-input:hover {
      background: rgba(255, 255, 255, 0.05);
    }
    
    .track-name-input:focus {
      background: #21262d;
      border-color: #58a6ff;
    }
    
    /* New track zone */
    .track-lane.new-track-zone {
      height: 48px;
      background: #0a0e14;
      border: 2px dashed #21262d;
      margin: 4px;
      border-radius: 6px;
    }
    
    .track-lane.new-track-zone .track-header {
      background: transparent;
      border: none;
      justify-content: center;
    }
    
    .track-lane.new-track-zone.drop-target {
      background: rgba(88, 166, 255, 0.1);
      border-color: #58a6ff;
    }
    
    .add-track-label {
      color: #484f58;
      font-size: 0.75rem;
    }
    
    /* Empty timeline drop zone */
    .empty-timeline.drop-target {
      background: rgba(88, 166, 255, 0.1);
      border: 2px dashed #58a6ff;
      border-radius: 8px;
    }
    
    /* Transport snap control */
    .transport-snap {
      display: flex;
      align-items: center;
      gap: 0.25rem;
    }
    
    .transport-snap label {
      display: flex;
      align-items: center;
      gap: 0.35rem;
      cursor: pointer;
      font-size: 0.75rem;
      color: #8b949e;
    }
    
    .transport-snap input[type="checkbox"] {
      width: 14px;
      height: 14px;
      cursor: pointer;
    }
    
    /* Ruler beat markers */
    .ruler-mark.major span {
      display: inline-block;
    }
    
    .ruler-mark.minor {
      width: 1px;
      height: 8px;
      background: #30363d;
      bottom: 0;
    }
    
    .playhead {
      position: absolute;
      top: 0;
      bottom: 0;
      left: 140px;
      width: 2px;
      background: #f85149;
      z-index: 50;
      pointer-events: none;
    }
    
    .playhead::before {
      content: '';
      position: absolute;
      top: 0;
      left: -5px;
      width: 0;
      height: 0;
      border-left: 6px solid transparent;
      border-right: 6px solid transparent;
      border-top: 8px solid #f85149;
    }
    
    .empty-timeline {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      height: 250px;
      color: #484f58;
    }
    
    .empty-timeline .icon {
      font-size: 3rem;
      margin-bottom: 1rem;
      opacity: 0.5;
    }
    
    .empty-timeline p {
      margin: 0.25rem 0;
    }
    
    .empty-timeline .hint {
      font-size: 0.8rem;
      color: #30363d;
    }
    
    /* === PROPERTIES PANEL (Right) === */
    .daw-properties {
      background: #161b22;
      border-left: 1px solid #21262d;
      display: flex;
      flex-direction: column;
      overflow: hidden;
    }
    
    .props-tabs {
      display: flex;
      background: #0d1117;
      border-bottom: 1px solid #21262d;
    }
    
    .prop-tab {
      flex: 1;
      padding: 0.75rem 0.5rem;
      background: transparent;
      border: none;
      border-bottom: 2px solid transparent;
      cursor: pointer;
      font-size: 0.75rem;
      font-weight: 500;
      color: #484f58;
      transition: all 0.15s ease;
    }
    
    .prop-tab:hover {
      color: #8b949e;
      background: #161b22;
    }
    
    .prop-tab.active {
      color: #58a6ff;
      border-bottom-color: #58a6ff;
      background: #161b22;
    }
    
    .prop-panel {
      display: none;
      flex: 1;
      overflow-y: auto;
      padding: 1rem;
    }
    
    .prop-panel.active {
      display: block;
    }
    
    .prop-section {
      margin-bottom: 1.25rem;
    }
    
    .prop-section-title {
      font-size: 0.65rem;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      color: #484f58;
      margin-bottom: 0.75rem;
      padding-bottom: 0.5rem;
      border-bottom: 1px solid #21262d;
    }
    
    .empty-props {
      text-align: center;
      padding: 2rem 1rem;
      color: #484f58;
      font-size: 0.85rem;
    }
    
    .prop-row {
      display: flex;
      align-items: center;
      gap: 0.75rem;
      margin-bottom: 0.6rem;
    }
    
    .prop-label {
      flex: 0 0 65px;
      font-size: 0.75rem;
      color: #8b949e;
    }
    
    .prop-input {
      flex: 1;
      padding: 0.4rem 0.6rem;
      background: #0d1117;
      border: 1px solid #21262d;
      border-radius: 6px;
      font-size: 0.8rem;
      color: #e6edf3;
    }
    
    .prop-input:focus {
      outline: none;
      border-color: #58a6ff;
    }
    
    .prop-slider {
      flex: 1;
      height: 6px;
      -webkit-appearance: none;
      background: #21262d;
      border-radius: 3px;
    }
    
    .prop-slider::-webkit-slider-thumb {
      -webkit-appearance: none;
      width: 14px;
      height: 14px;
      border-radius: 50%;
      background: #58a6ff;
      cursor: pointer;
      border: 2px solid #0d1117;
    }
    
    .prop-value {
      flex: 0 0 50px;
      font-size: 0.75rem;
      color: #58a6ff;
      text-align: right;
      font-family: 'SF Mono', monospace;
    }
    
    /* Effects List */
    .fx-list {
      display: flex;
      flex-direction: column;
      gap: 0.5rem;
    }
    
    .fx-item {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.5rem;
      background: #0d1117;
      border-radius: 6px;
      border: 1px solid #21262d;
      cursor: pointer;
      transition: all 0.15s ease;
    }
    
    .fx-item:hover {
      border-color: #30363d;
      background: #21262d;
    }
    
    .fx-item.active {
      border-color: #58a6ff;
    }
    
    .fx-icon {
      font-size: 1rem;
    }
    
    .fx-name {
      flex: 1;
      font-size: 0.8rem;
      color: #e6edf3;
    }
    
    .fx-toggle {
      width: 18px;
      height: 18px;
      background: #21262d;
      border: 1px solid #30363d;
      border-radius: 4px;
      cursor: pointer;
    }
    
    .fx-toggle.on {
      background: #238636;
      border-color: #238636;
    }
    
    /* Mixer */
    .mixer-grid {
      display: flex;
      gap: 0.5rem;
      overflow-x: auto;
      padding-bottom: 0.5rem;
    }
    
    .mixer-channel {
      flex: 0 0 52px;
      background: #0d1117;
      border-radius: 8px;
      padding: 0.5rem;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 0.35rem;
      border: 1px solid #21262d;
    }
    
    .mixer-channel.master {
      border-color: #238636;
      background: rgba(35, 134, 54, 0.1);
    }
    
    .mixer-label {
      font-size: 0.6rem;
      font-weight: 600;
      color: #8b949e;
      text-align: center;
      width: 100%;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    
    .mixer-fader-wrap {
      width: 8px;
      height: 90px;
      background: #21262d;
      border-radius: 4px;
      position: relative;
    }
    
    .mixer-fader {
      position: absolute;
      bottom: 0;
      left: 0;
      width: 100%;
      background: linear-gradient(to top, #238636, #3fb950);
      border-radius: 4px;
      transition: height 0.1s ease;
    }
    
    .mixer-meter {
      width: 4px;
      height: 90px;
      background: #21262d;
      border-radius: 2px;
      overflow: hidden;
      position: relative;
    }
    
    .meter-fill {
      position: absolute;
      bottom: 0;
      left: 0;
      right: 0;
      background: linear-gradient(to top, #238636, #f0c14b 70%, #f85149);
    }
    
    .mixer-btns {
      display: flex;
      gap: 2px;
    }
    
    .mixer-btn {
      width: 20px;
      height: 16px;
      font-size: 0.55rem;
      font-weight: 700;
      background: #21262d;
      border: none;
      border-radius: 3px;
      cursor: pointer;
      color: #484f58;
    }
    
    .mixer-btn.m.active { background: #9e6a03; color: #f0c14b; }
    .mixer-btn.s.active { background: #1f6feb; color: #79c0ff; }
    
    /* Code Output */
    .code-output {
      background: #0d1117;
      border: 1px solid #21262d;
      border-radius: 8px;
      padding: 0.75rem;
      font-family: 'SF Mono', 'Consolas', monospace;
      font-size: 0.7rem;
      color: #8b949e;
      white-space: pre-wrap;
      overflow-x: auto;
      max-height: 300px;
      line-height: 1.5;
    }
    
    /* === FOOTER STATUS BAR === */
    .daw-footer {
      display: flex;
      align-items: center;
      gap: 1rem;
      padding: 0 1rem;
      background: #161b22;
      border-top: 1px solid #21262d;
      font-size: 0.75rem;
      color: #484f58;
    }
    
    .footer-section {
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }
    
    .footer-spacer { flex: 1; }
    
    .zoom-controls {
      display: flex;
      align-items: center;
      gap: 0.25rem;
    }
    
    .zoom-btn {
      width: 24px;
      height: 24px;
      background: #21262d;
      border: none;
      border-radius: 4px;
      cursor: pointer;
      color: #8b949e;
      font-size: 0.8rem;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    
    .zoom-btn:hover {
      background: #30363d;
      color: #e6edf3;
    }
    
    .zoom-level {
      min-width: 45px;
      text-align: center;
      color: #8b949e;
    }
    
    .snap-toggle {
      display: flex;
      align-items: center;
      gap: 0.35rem;
      cursor: pointer;
    }
    
    .snap-toggle input {
      accent-color: #58a6ff;
    }
    
    .footer-select {
      padding: 0.25rem 0.5rem;
      background: #21262d;
      border: 1px solid #30363d;
      border-radius: 4px;
      color: #8b949e;
      font-size: 0.7rem;
    }
    
    /* Responsive */
    @media (max-width: 1200px) {
      .daw-main {
        grid-template-columns: 220px 1fr 260px;
      }
    }
    
    @media (max-width: 900px) {
      .daw-main {
        grid-template-columns: 1fr;
      }
      .daw-browser, .daw-properties {
        display: none;
      }
    }

    .no-selection-msg {
      color: var(--text-muted);
      font-size: 0.8rem;
    }

    /* Code Export Panel - keeping new layout */
    .code-export {
      padding: 0.5rem;
      background: var(--bg-primary);
      border-radius: 6px;
    }
    
    .timeline-toolbar {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.4rem 0.75rem;
      background: var(--bg-secondary);
      border-bottom: 1px solid var(--border-color);
    }

    /* Skip duplicate old timeline CSS - using new CSS above */

    .track-lane {
      height: 60px;
      border-bottom: 1px solid #2a2a35;
      position: relative;
      display: flex;
    }
    
    /* Rest of track/clip CSS - simplified version */
    .track-lane:nth-child(even) {
      background: rgba(255,255,255,0.01);
    }

    /* Clip styles - removed duplicate, using new CSS */
    .mini-waveform {
      width: 100%;
      height: 100%;
      background: repeating-linear-gradient(
        90deg,
        rgba(255,255,255,0.1) 0px,
        rgba(255,255,255,0.3) 2px,
        rgba(255,255,255,0.1) 4px
      );
      border-radius: 2px;
    }

    /* Empty timeline */
    .empty-timeline {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      height: 200px;
      color: var(--text-muted);
    }
    
    .empty-timeline .icon {
      font-size: 3rem;
      margin-bottom: 0.5rem;
      opacity: 0.3;
    }
    
    .empty-timeline .hint {
      font-size: 0.7rem;
      opacity: 0.7;
    }

    /* Playhead */
    .playhead {
      position: absolute;
      top: 0;
      bottom: 0;
      width: 2px;
      background: #ff4444;
      z-index: 100;
      pointer-events: none;
    }
    
    .playhead::before {
      content: '';
      position: absolute;
      top: -8px;
      left: -4px;
      border: 5px solid transparent;
      border-top: 8px solid #ff4444;
    }

    /* Code Export Panel */
    .code-export {
      padding: 0.5rem;
      background: var(--bg-primary);
      border-radius: 6px;
    }

    .code-preview {
      background: #111;
      border-radius: 4px;
      padding: 0.5rem;
      font-family: 'JetBrains Mono', monospace;
      font-size: 0.65rem;
      line-height: 1.5;
      max-height: 200px;
      overflow: auto;
      color: #9cdcfe;
    }

    .code-preview .keyword { color: #c586c0; }
    .code-preview .string { color: #ce9178; }
    .code-preview .number { color: #b5cea8; }
    .code-preview .function { color: #dcdcaa; }
    .code-preview .comment { color: #6a9955; }

    /* DAW Responsive */
    @media (max-width: 1200px) {
      .daw-main {
        grid-template-columns: 200px 1fr;
      }
      
      .daw-properties {
        display: none;
      }
    }

    @media (max-width: 900px) {
      .daw-main {
        grid-template-columns: 1fr;
      }
      
      .daw-browser {
        display: none;
      }
    }
  </style>
</head>
<body>
  <!-- Animated Background -->
  <div class="bg-animation" id="bgAnimation"></div>
  
  <div class="app-container">
    <!-- Header -->
    <header class="header">
      <div class="logo-section">
        <div class="logo">🚀</div>
        <div class="logo-text">
          <h1>Dev Hub</h1>
          <span>Your project tools, all in one place</span>
        </div>
      </div>
      
      <div class="search-bar">
        <input type="text" placeholder="Find something... (Ctrl+K)" id="searchInput">
      </div>
      
      <div class="header-actions">
        <div class="auto-refresh" id="autoRefreshIndicator" onclick="toggleAutoRefresh()">
          <span class="refresh-icon">🔄</span>
          <span id="autoRefreshLabel">Auto</span>
        </div>
        <div class="theme-toggle" onclick="toggleTheme()" title="Toggle theme"></div>
        <button class="notification-btn" onclick="toggleNotifications()" title="Notifications">
          🔔
          <span class="notification-badge" id="notificationBadge" style="display: none;">0</span>
        </button>
        <div class="status-indicator">
          <div class="status-dot"></div>
          <span>Connected</span>
        </div>
        <button class="btn btn-ghost" onclick="showSettings()">⚙️</button>
        <button class="btn btn-ghost" onclick="showShortcuts()">⌨️</button>
        <button class="btn btn-ghost" onclick="showCodeSearch()">🔍</button>
        <button class="btn btn-ghost" onclick="showTerminal()">💻</button>
        <button class="btn btn-primary" onclick="refreshAll()">🔄 Refresh</button>
      </div>
    </header>
    
    <!-- Notification Panel -->
    <div class="notification-panel" id="notificationPanel">
      <div class="notification-panel-header">
        <h3>🔔 Notifications</h3>
        <button class="btn btn-ghost" onclick="clearNotifications()">Clear All</button>
      </div>
      <div class="notification-list" id="notificationList">
        <div style="padding: 2rem; text-align: center; color: var(--text-muted);">
          No notifications
        </div>
      </div>
    </div>
    
    <!-- Sidebar -->
    <aside class="sidebar">
      <!-- Project Selector -->
      <div class="project-selector" onclick="toggleProjectMenu()">
        <div class="current">
          <div class="project-icon">🎮</div>
          <div>
            <div class="project-name">${projectName}</div>
            <div class="project-path">/workspace</div>
          </div>
        </div>
      </div>
      
      <!-- Navigation -->
      <div class="sidebar-section">
        <div class="sidebar-title">Overview</div>
        <div class="nav-item active" data-tab="dashboard" onclick="navClick(this, 'dashboard')">
          <span class="icon">📊</span>
          <span>Dashboard</span>
        </div>
        <div class="nav-item" data-tab="wiki" onclick="navClick(this, 'wiki')">
          <span class="icon">📖</span>
          <span>Project Wiki</span>
        </div>
        <div class="nav-item" data-tab="playground" onclick="navClick(this, 'playground')">
          <span class="icon">🎮</span>
          <span>Playground</span>
          <span class="badge" style="background: var(--accent-warning);">NEW</span>
        </div>
        <div class="nav-item" data-tab="sound-studio" onclick="navClick(this, 'sound-studio')">
          <span class="icon">🎵</span>
          <span>Sound Studio</span>
          <span class="badge" style="background: var(--accent-success);">🔊</span>
        </div>
        <div class="nav-item" data-tab="tools" onclick="navClick(this, 'tools')">
          <span class="icon">🔧</span>
          <span>Tools</span>
          <span class="badge" id="toolCount">0</span>
        </div>
        <div class="nav-item" data-tab="resources" onclick="navClick(this, 'resources')">
          <span class="icon">📦</span>
          <span>Resources</span>
        </div>
        <div class="nav-item" data-tab="prompts" onclick="navClick(this, 'prompts')">
          <span class="icon">💬</span>
          <span>Prompts</span>
        </div>
      </div>
      
      <div class="sidebar-section">
        <div class="sidebar-title">Categories</div>
        <div class="nav-item" data-tab="tools" data-filter="godot" onclick="navClick(this, 'tools', 'godot')">
          <span class="icon">🎮</span>
          <span>Godot Tools</span>
        </div>
        <div class="nav-item" data-tab="tools" data-filter="git" onclick="navClick(this, 'tools', 'git')">
          <span class="icon">📋</span>
          <span>Git Tools</span>
        </div>
        <div class="nav-item" data-tab="tools" data-filter="analysis" onclick="navClick(this, 'tools', 'analysis')">
          <span class="icon">🔍</span>
          <span>Analysis</span>
        </div>
        <div class="nav-item" data-tab="tools" data-filter="quality" onclick="navClick(this, 'tools', 'quality')">
          <span class="icon">✅</span>
          <span>Quality</span>
        </div>
      </div>
      
      <div class="sidebar-section">
        <div class="sidebar-title">System</div>
        <div class="nav-item" data-tab="metrics" onclick="navClick(this, 'metrics')">
          <span class="icon">📈</span>
          <span>Metrics</span>
        </div>
        <div class="nav-item" data-tab="history" onclick="navClick(this, 'history')">
          <span class="icon">🕒</span>
          <span>History</span>
        </div>
        <div class="nav-item" data-tab="learn" onclick="navClick(this, 'learn')">
          <span class="icon">📚</span>
          <span>Learning Hub</span>
        </div>
      </div>
    </aside>
    
    <!-- Main Content -->
    <main class="main-content">
      <!-- Dashboard Tab -->
      <div class="tab-container active" id="tab-dashboard">
        <div class="favorites-bar" id="favoritesBar">
          <button class="favorite-btn" onclick="executeTool('project_stats')">
            <span class="star">⭐</span> Project Stats
          </button>
          <button class="favorite-btn" onclick="executeTool('git_status')">
            <span class="star">⭐</span> Git Status
          </button>
          <button class="favorite-btn" onclick="executeTool('find_todos')">
            <span class="star">⭐</span> Find TODOs
          </button>
        </div>
        
        <div class="dashboard-grid">
          <div class="stats-card" onclick="showStatDetails('scripts')" title="Click to view all GDScript files">
            <div class="card-header">
              <div class="card-icon blue">📁</div>
            </div>
            <div class="card-value" id="statScripts">-</div>
            <div class="card-label">GDScript Files</div>
          </div>
          
          <div class="stats-card" onclick="showStatDetails('scenes')" title="Click to view all scene files">
            <div class="card-header">
              <div class="card-icon purple">🎬</div>
            </div>
            <div class="card-value" id="statScenes">-</div>
            <div class="card-label">Scene Files</div>
          </div>
          
          <div class="stats-card" onclick="showStatDetails('lines')" title="Click to view code breakdown">
            <div class="card-header">
              <div class="card-icon green">💻</div>
            </div>
            <div class="card-value" id="statLines">-</div>
            <div class="card-label">Lines of Code</div>
          </div>
          
          <div class="stats-card" onclick="showStatDetails('todos')" title="Click to view all TODOs/FIXMEs">
            <div class="card-header">
              <div class="card-icon orange">⚠️</div>
            </div>
            <div class="card-value" id="statTodos">-</div>
            <div class="card-label">TODOs/FIXMEs</div>
          </div>
        </div>
        
        <h3 class="section-title">Common Tools</h3>
        <div class="tool-grid" id="quickActions"></div>
        
        <div class="tool-panel" id="toolPanel" style="display: none;">
          <div class="tool-panel-header">
            <div class="tool-panel-title">
              <span id="panelToolIcon">🔧</span>
              <span id="panelToolName">Tool Name</span>
            </div>
            <button class="btn btn-ghost" onclick="closeToolPanel()">✕</button>
          </div>
          <div class="tool-panel-body">
            <div id="toolInputs"></div>
            <button class="btn btn-primary" style="margin-top: 1rem;" onclick="runSelectedTool()">
              ▶️ Execute
            </button>
            <div class="output-display" id="toolOutput" style="margin-top: 1rem; display: none;"></div>
          </div>
        </div>
      </div>
      
      <!-- Wiki Tab - Inline Full Page (No Popups) -->
      <div class="tab-container" id="tab-wiki">
        <div class="wiki-page">
          <div class="wiki-page-header">
            <h3 class="section-title" style="margin: 0;">Project Docs</h3>
            <div style="display: flex; gap: 0.5rem;">
              <button class="btn" onclick="refreshWikiFiles()">🔄 Refresh</button>
            </div>
          </div>
          
          <div class="wiki-page-layout">
            <!-- File Browser Panel -->
            <div class="wiki-file-panel">
              <div class="wiki-file-filters">
                <input type="text" id="wikiSearchInput" class="search-input" placeholder="🔍 Search files..." onkeyup="filterWikiFiles()" style="width: 100%;">
                <div style="display: flex; gap: 0.5rem;">
                  <select id="wikiFolderFilter" onchange="loadWikiFiles()" style="flex: 1;">
                    <option value="">All Folders</option>
                    <option value="scripts">scripts/</option>
                    <option value="scenes">scenes/</option>
                    <option value="resources">resources/</option>
                  </select>
                  <select id="wikiTypeFilter" onchange="loadWikiFiles()" style="flex: 1;">
                    <option value="">All</option>
                    <option value=".gd">.gd</option>
                    <option value=".tscn">.tscn</option>
                    <option value=".tres">.tres</option>
                  </select>
                </div>
              </div>
              <div class="wiki-file-list" id="wikiFileTree">
                <div class="wiki-empty">
                  <div class="icon">📁</div>
                  Loading files...
                </div>
              </div>
            </div>
            
            <!-- Main Wiki Content Panel -->
            <div class="wiki-main-panel" id="wikiMainPanel">
              <div class="wiki-empty">
                <div class="icon">👈</div>
                <p>Select a file to view its documentation</p>
                <p style="font-size: 0.85rem; margin-top: 0.5rem;">Click any file in the list to see detailed wiki documentation with cross-references, Godot docs links, and more.</p>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Playground Tab -->
      <div class="tab-container" id="tab-playground">
        <div class="playground">
          <div class="playground-header">
            <h3 class="section-title" style="margin: 0;">🎮 Interactive Playground</h3>
            <div style="display: flex; gap: 0.5rem; align-items: center;">
              <select id="playgroundFileSelect" onchange="loadPlaygroundFile()" style="min-width: 250px; padding: 0.5rem;">
                <option value="">Select a file to experiment with...</option>
              </select>
              <button class="btn" onclick="resetPlayground()">🔄 Reset</button>
              <button class="btn" onclick="copyPlaygroundCode()">📋 Copy Code</button>
              <button class="btn btn-primary" onclick="exportPlaygroundTodos()">📤 Export Changes</button>
            </div>
          </div>
          
          <!-- Template Buttons -->
          <div class="playground-templates" id="playgroundTemplates">
            <button class="template-btn" onclick="loadTemplate('item')">📦 New Item</button>
            <button class="template-btn" onclick="loadTemplate('ship')">🚀 Ship Type</button>
            <button class="template-btn" onclick="loadTemplate('sound')">🔊 Sound Effect</button>
            <button class="template-btn" onclick="loadTemplate('module')">⚙️ Ship Module</button>
            <button class="template-btn" onclick="loadTemplate('enemy')">👾 Enemy Type</button>
            <button class="template-btn" onclick="loadTemplate('achievement')">🏆 Achievement</button>
            <button class="template-btn" onclick="loadTemplate('station')">🛸 Station Data</button>
          </div>
          
          <div class="playground-layout">
            <!-- Code Editor -->
            <div class="playground-editor">
              <div class="playground-editor-header">
                <span id="playgroundFileName">No file loaded</span>
                <span style="font-size: 0.8rem; color: var(--text-muted);" id="playgroundLineInfo">Select text for context</span>
              </div>
              <div class="playground-editor-content" id="playgroundEditor">
                <div class="wiki-empty">
                  <div class="icon">🎮</div>
                  <h3>Playground</h3>
                  <p style="margin-top: 0.5rem;">Pick a file or template to get started.</p>
                  <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 1rem; margin-top: 1.5rem; text-align: left; max-width: 500px; margin-left: auto; margin-right: auto;">
                    <div style="background: var(--bg-secondary); padding: 1rem; border-radius: 8px;">
                      <h4 style="margin: 0 0 0.5rem 0;">📁 Open a file</h4>
                      <p style="font-size: 0.8rem; color: var(--text-muted); margin: 0;">Use the dropdown above to pick an existing script.</p>
                    </div>
                    <div style="background: var(--bg-secondary); padding: 1rem; border-radius: 8px;">
                      <h4 style="margin: 0 0 0.5rem 0;">📝 Start fresh</h4>
                      <p style="font-size: 0.8rem; color: var(--text-muted); margin: 0;">Click a template button to create something new.</p>
                    </div>
                    <div style="background: var(--bg-secondary); padding: 1rem; border-radius: 8px;">
                      <h4 style="margin: 0 0 0.5rem 0;">✨ Get help</h4>
                      <p style="font-size: 0.8rem; color: var(--text-muted); margin: 0;">Select any code to see what it does.</p>
                    </div>
                    <div style="background: var(--bg-secondary); padding: 1rem; border-radius: 8px;">
                      <h4 style="margin: 0 0 0.5rem 0;">📤 Save work</h4>
                      <p style="font-size: 0.8rem; color: var(--text-muted); margin: 0;">Export your changes when you're done.</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            
            <!-- Interactive Controls Sidebar -->
            <div class="playground-sidebar" id="playgroundSidebar">
              <div class="playground-panel">
                <div class="playground-panel-header">
                  <span>ℹ️</span> <span>Getting Started</span>
                </div>
                <div class="playground-panel-content">
                  <ol style="font-size: 0.85rem; padding-left: 1.25rem; margin: 0;">
                    <li style="margin-bottom: 0.5rem;">Select a file or click a template</li>
                    <li style="margin-bottom: 0.5rem;">Edit variables in the panels</li>
                    <li style="margin-bottom: 0.5rem;">Highlight code for context help</li>
                    <li>Export changes when done</li>
                  </ol>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Tools Tab -->
      <div class="tab-container" id="tab-tools">
        <h3 class="section-title">All Tools</h3>
        <div class="tool-grid" id="allTools"></div>
      </div>
      
      <!-- Sound Studio Tab - DAW Style -->
      <div class="tab-container" id="tab-sound-studio">
        <div class="daw-container">
          <!-- Transport Bar -->
          <div class="daw-transport">
            <div class="transport-brand">
              <div class="transport-brand-icon">🎵</div>
              <span class="transport-brand-text">Sound Studio</span>
            </div>
            
            <div class="transport-divider"></div>
            
            <div class="transport-buttons">
              <button class="transport-btn" onclick="dawRewind()" title="Rewind">⏮</button>
              <button class="transport-btn" id="dawPlayBtn" onclick="dawTogglePlay()" title="Play">▶</button>
              <button class="transport-btn" onclick="dawStop()" title="Stop">⏹</button>
              <button class="transport-btn record" onclick="dawRecord()" title="Record">●</button>
            </div>
            
            <div class="transport-time" id="dawTimeDisplay">00:00.000</div>
            
            <div class="transport-bpm">
              <span>BPM</span>
              <input type="number" value="120" min="30" max="300" id="bpmInput" onchange="updateBpm(this.value)" oninput="updateBpm(this.value)">
            </div>
            
            <div class="transport-snap">
              <label title="Snap to grid">
                <input type="checkbox" id="snapEnabled" checked onchange="toggleSnap(this.checked)">
                <span>Snap</span>
              </label>
            </div>
            
            <div class="transport-spacer"></div>
            
            <div class="transport-actions">
              <select class="transport-select" onchange="loadSoundPreset(this.value); this.value='';">
                <option value="">Load Preset...</option>
                <option value="basic_sfx">Basic SFX</option>
                <option value="combat_pack">Combat Pack</option>
                <option value="ui_complete">UI Complete</option>
                <option value="boarding_pack">Boarding</option>
                <option value="full_game">Full Game</option>
              </select>
              <button class="transport-action-btn" onclick="dawAddTrack()">➕ Track</button>
              <button class="transport-action-btn" onclick="dawClearAll()">🗑️ Clear</button>
              <button class="transport-action-btn primary" onclick="dawExport()">📤 Export</button>
            </div>
          </div>
          
          <!-- Main Content -->
          <div class="daw-main">
            <!-- Sound Browser -->
            <div class="daw-browser">
              <div class="browser-header">
                <input type="text" class="browser-search" id="soundSearch" placeholder="Search sounds..." oninput="filterSounds(this.value)">
              </div>
              
              <div class="browser-categories">
                <button class="cat-btn active" data-cat="all" onclick="selectCategory('all')">All</button>
                <button class="cat-btn" data-cat="ui" onclick="selectCategory('ui')">UI</button>
                <button class="cat-btn" data-cat="combat" onclick="selectCategory('combat')">Combat</button>
                <button class="cat-btn" data-cat="explosions" onclick="selectCategory('explosions')">Explosions</button>
                <button class="cat-btn" data-cat="ship" onclick="selectCategory('ship')">Ship</button>
                <button class="cat-btn" data-cat="boarding" onclick="selectCategory('boarding')">Boarding</button>
                <button class="cat-btn" data-cat="loot" onclick="selectCategory('loot')">Loot</button>
                <button class="cat-btn" data-cat="alerts" onclick="selectCategory('alerts')">Alerts</button>
                <button class="cat-btn" data-cat="ambient" onclick="selectCategory('ambient')">Ambient</button>
                <button class="cat-btn" data-cat="footsteps" onclick="selectCategory('footsteps')">Footsteps</button>
                <button class="cat-btn" data-cat="voices" onclick="selectCategory('voices')">Voices</button>
                <button class="cat-btn" data-cat="impacts" onclick="selectCategory('impacts')">Impacts</button>
                <button class="cat-btn" data-cat="music" onclick="selectCategory('music')">Music</button>
              </div>
              
              <div class="browser-sounds" id="browserSounds">
                <!-- Sounds populated by JS -->
              </div>
            </div>
            
            <!-- Timeline -->
            <div class="daw-timeline">
              <div class="timeline-ruler" id="timelineRuler">
                <!-- Ruler marks populated by JS -->
              </div>
              
              <div class="timeline-content" id="timelineBody" ondragover="event.preventDefault()" ondrop="handleTimelineDrop(event)">
                <div class="timeline-tracks" id="timelineTracks">
                  <!-- Tracks populated by JS -->
                </div>
                <div class="playhead" id="playhead"></div>
              </div>
            </div>
            
            <!-- Properties Panel -->
            <div class="daw-properties">
              <div class="props-tabs">
                <button class="prop-tab active" onclick="switchPropTab('clip')">Clip</button>
                <button class="prop-tab" onclick="switchPropTab('effects')">FX</button>
                <button class="prop-tab" onclick="switchPropTab('mixer')">Mixer</button>
                <button class="prop-tab" onclick="switchPropTab('code')">Code</button>
              </div>
              
              <div class="prop-panel active" id="propClip">
                <div class="prop-section">
                  <div class="prop-section-title">Clip Properties</div>
                  <div id="clipProperties">
                    <div class="empty-props">Select a clip to edit its properties</div>
                  </div>
                </div>
              </div>
              
              <div class="prop-panel" id="propEffects">
                <div class="prop-section">
                  <div class="prop-section-title">Audio Effects</div>
                  <div class="fx-list">
                    <div class="fx-item" onclick="addEffect('reverb')">
                      <span class="fx-icon">🌊</span>
                      <span class="fx-name">Reverb</span>
                      <div class="fx-toggle"></div>
                    </div>
                    <div class="fx-item" onclick="addEffect('delay')">
                      <span class="fx-icon">🔁</span>
                      <span class="fx-name">Delay</span>
                      <div class="fx-toggle"></div>
                    </div>
                    <div class="fx-item" onclick="addEffect('distortion')">
                      <span class="fx-icon">🔥</span>
                      <span class="fx-name">Distortion</span>
                      <div class="fx-toggle"></div>
                    </div>
                    <div class="fx-item" onclick="addEffect('lowpass')">
                      <span class="fx-icon">📉</span>
                      <span class="fx-name">Low Pass Filter</span>
                      <div class="fx-toggle"></div>
                    </div>
                    <div class="fx-item" onclick="addEffect('highpass')">
                      <span class="fx-icon">📈</span>
                      <span class="fx-name">High Pass Filter</span>
                      <div class="fx-toggle"></div>
                    </div>
                    <div class="fx-item" onclick="addEffect('compressor')">
                      <span class="fx-icon">🗜️</span>
                      <span class="fx-name">Compressor</span>
                      <div class="fx-toggle"></div>
                    </div>
                  </div>
                </div>
              </div>
              
              <div class="prop-panel" id="propMixer">
                <div class="prop-section">
                  <div class="prop-section-title">Mixer</div>
                  <div class="mixer-grid" id="mixerContainer">
                    <!-- Mixer populated by JS -->
                  </div>
                </div>
              </div>
              
              <div class="prop-panel" id="propCode">
                <div class="prop-section">
                  <div class="prop-section-title">Generated GDScript</div>
                  <pre class="code-output" id="dawCodeOutput"># Add clips to timeline to generate code</pre>
                  <button class="transport-action-btn primary" onclick="copyDawCode()" style="width: 100%; margin-top: 0.75rem; justify-content: center;">📋 Copy Code</button>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Footer Status Bar -->
          <div class="daw-footer">
            <div class="footer-section">
              <span id="trackCount">0 tracks</span>
              <span>•</span>
              <span id="clipCount">0 clips</span>
            </div>
            
            <div class="footer-spacer"></div>
            
            <div class="zoom-controls">
              <button class="zoom-btn" onclick="dawZoomOut()">−</button>
              <span class="zoom-level" id="zoomLevel">100%</span>
              <button class="zoom-btn" onclick="dawZoomIn()">+</button>
            </div>
            
            <div class="footer-section">
              <label class="snap-toggle">
                <input type="checkbox" id="snapEnabled" checked>
                <span>Snap</span>
              </label>
              <select class="footer-select" id="snapValue">
                <option value="0.1">0.1s</option>
                <option value="0.25" selected>0.25s</option>
                <option value="0.5">0.5s</option>
                <option value="1">1s</option>
              </select>
            </div>
            
            <div class="footer-section">
              <span>Length:</span>
              <select class="footer-select" id="timelineLengthSelect" onchange="dawState.timelineLength = parseInt(this.value); renderTimeline();">
                <option value="15">15s</option>
                <option value="30" selected>30s</option>
                <option value="60">60s</option>
                <option value="120">2min</option>
              </select>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Resources Tab -->
      <div class="tab-container" id="tab-resources">
        <h3 class="section-title">📦 Resources</h3>
        <p style="color: var(--text-secondary); margin-bottom: 1.5rem;">
          Data and context your AI assistant can use when helping with your project.
        </p>
        <div class="tool-grid" id="resourcesList"></div>
      </div>
      
      <!-- Prompts Tab -->
      <div class="tab-container" id="tab-prompts">
        <h3 class="section-title">💬 Prompts</h3>
        <p style="color: var(--text-secondary); margin-bottom: 1.5rem;">
          Ready-to-use prompts for common tasks. Copy and paste into your AI chat.
        </p>
        <div class="tool-grid" id="promptsList"></div>
      </div>
      
      <!-- Metrics Tab -->
      <div class="tab-container" id="tab-metrics">
        <h3 class="section-title">Server Stats</h3>
        <div class="metrics-grid" id="metricsGrid"></div>
      </div>
      
      <!-- History Tab -->
      <div class="tab-container" id="tab-history">
        <h3 class="section-title">Recent Activity</h3>
        <div class="history-list" id="historyList"></div>
      </div>
      
      <!-- Learning Tab -->
      <div class="tab-container" id="tab-learn">
        <h3 class="section-title">Learn More</h3>
        <p style="color: var(--text-secondary); margin-bottom: 1.5rem;">
          Helpful resources to get you started.
        </p>
        <div class="learning-grid">
          <div class="learning-card">
            <div class="card-banner mcp">🔌</div>
            <div class="card-content">
              <div class="card-title">Model Context Protocol</div>
              <div class="card-desc">The tech behind how AI assistants connect to your project and understand your code.</div>
              <div class="card-links">
                <a href="https://modelcontextprotocol.io/docs" target="_blank" class="card-link">📖 Official Docs</a>
                <a href="https://github.com/modelcontextprotocol/specification" target="_blank" class="card-link">📋 Specification</a>
                <a href="https://github.com/modelcontextprotocol/servers" target="_blank" class="card-link">🔧 Example Servers</a>
              </div>
            </div>
          </div>
          
          <div class="learning-card">
            <div class="card-banner docker">🐳</div>
            <div class="card-content">
              <div class="card-title">Docker Basics</div>
              <div class="card-desc">Run your server in a container so it works the same on any machine.</div>
              <div class="card-links">
                <a href="https://docs.docker.com/get-started/" target="_blank" class="card-link">📖 Get Started</a>
                <a href="https://docs.docker.com/compose/" target="_blank" class="card-link">🎼 Compose</a>
                <a href="https://docs.docker.com/build/building/best-practices/" target="_blank" class="card-link">✨ Best Practices</a>
              </div>
            </div>
          </div>
          
          <div class="learning-card">
            <div class="card-banner godot">🎮</div>
            <div class="card-content">
              <div class="card-title">Godot Engine</div>
              <div class="card-desc">The game engine this project uses. Great docs and a friendly community.</div>
              <div class="card-links">
                <a href="https://docs.godotengine.org/en/stable/" target="_blank" class="card-link">📖 Documentation</a>
                <a href="https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html" target="_blank" class="card-link">📝 GDScript</a>
                <a href="https://gdquest.github.io/gdscript-docs-maker/" target="_blank" class="card-link">📚 API Reference</a>
              </div>
            </div>
          </div>
          
          <div class="learning-card">
            <div class="card-banner git">📋</div>
            <div class="card-content">
              <div class="card-title">Git</div>
              <div class="card-desc">Keep track of your changes and undo mistakes. Essential for any project.</div>
              <div class="card-links">
                <a href="https://git-scm.com/book/en/v2" target="_blank" class="card-link">📖 Pro Git Book</a>
                <a href="https://learngitbranching.js.org/" target="_blank" class="card-link">🎮 Interactive</a>
                <a href="https://ohshitgit.com/" target="_blank" class="card-link">🆘 Oh Shit, Git!</a>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
  </div>
  
  <!-- Keyboard Shortcuts Modal -->
  <div class="modal-overlay" id="shortcutsModal">
    <div class="modal">
      <h2>⌨️ Keyboard Shortcuts</h2>
      <div class="shortcut-list">
        <div class="shortcut-item">
          <span>Search</span>
          <span class="shortcut-key">Ctrl + K</span>
        </div>
        <div class="shortcut-item">
          <span>Dashboard</span>
          <span class="shortcut-key">1</span>
        </div>
        <div class="shortcut-item">
          <span>Tools</span>
          <span class="shortcut-key">2</span>
        </div>
        <div class="shortcut-item">
          <span>Resources</span>
          <span class="shortcut-key">3</span>
        </div>
        <div class="shortcut-item">
          <span>Refresh</span>
          <span class="shortcut-key">R</span>
        </div>
        <div class="shortcut-item">
          <span>Close Panel</span>
          <span class="shortcut-key">Escape</span>
        </div>
      </div>
      <button class="btn btn-primary" style="margin-top: 1.5rem; width: 100%;" onclick="hideShortcuts()">Got it!</button>
    </div>
  </div>
  
  <!-- Detail Modal for Stats -->
  <div class="modal-overlay" id="detailModal" onclick="if(event.target === this) hideDetailModal()">
    <div class="modal detail-modal">
      <button class="modal-close" onclick="hideDetailModal()">✕</button>
      <h2 id="detailModalTitle">Details</h2>
      <div class="detail-summary" id="detailSummary"></div>
      <div class="detail-list" id="detailContent">
        <div style="text-align: center; padding: 2rem; color: var(--text-muted);">
          <div style="font-size: 2rem; margin-bottom: 0.5rem;">⏳</div>
          Loading...
        </div>
      </div>
      <div class="export-buttons" id="exportButtons" style="display: none;">
        <button class="export-btn" onclick="exportCurrentView('json')">📥 Export JSON</button>
        <button class="export-btn" onclick="exportCurrentView('csv')">📊 Export CSV</button>
        <button class="copy-btn" onclick="copyCurrentView()">📋 Copy</button>
      </div>
    </div>
  </div>
  
  <!-- Settings Modal -->
  <div class="modal-overlay" id="settingsModal" onclick="if(event.target === this) hideSettings()">
    <div class="modal settings-modal">
      <button class="modal-close" onclick="hideSettings()">✕</button>
      <h2>⚙️ Settings</h2>
      
      <div class="settings-section">
        <h4>🎨 Appearance</h4>
        <div class="setting-row">
          <div class="setting-label">
            <span>Dark Theme</span>
            <span>Use dark color scheme</span>
          </div>
          <div class="toggle-switch active" id="themeToggle" onclick="toggleThemeSetting()"></div>
        </div>
      </div>
      
      <div class="settings-section">
        <h4>🔄 Auto Refresh</h4>
        <div class="setting-row">
          <div class="setting-label">
            <span>Enable Auto Refresh</span>
            <span>Automatically refresh stats</span>
          </div>
          <div class="toggle-switch active" id="autoRefreshToggle" onclick="toggleAutoRefreshSetting()"></div>
        </div>
        <div class="setting-row">
          <div class="setting-label">
            <span>Refresh Interval</span>
            <span>Seconds between refreshes</span>
          </div>
          <select id="refreshInterval" onchange="updateRefreshInterval()" style="padding: 0.5rem; background: var(--bg-primary); border: 1px solid var(--border-color); border-radius: 6px; color: var(--text-primary);">
            <option value="15000">15 seconds</option>
            <option value="30000" selected>30 seconds</option>
            <option value="60000">1 minute</option>
            <option value="300000">5 minutes</option>
          </select>
        </div>
      </div>
      
      <div class="settings-section">
        <h4>🔔 Notifications</h4>
        <div class="setting-row">
          <div class="setting-label">
            <span>Enable Notifications</span>
            <span>Show alerts and warnings</span>
          </div>
          <div class="toggle-switch active" id="notifToggle" onclick="toggleNotifSetting()"></div>
        </div>
        <div class="setting-row">
          <div class="setting-label">
            <span>TODO Threshold</span>
            <span>Alert when TODOs exceed this</span>
          </div>
          <input type="number" id="todoThreshold" value="50" min="1" max="500" style="width: 80px; padding: 0.5rem; background: var(--bg-primary); border: 1px solid var(--border-color); border-radius: 6px; color: var(--text-primary);">
        </div>
      </div>
      
      <div class="settings-section">
        <h4>🗑️ Data</h4>
        <div class="setting-row">
          <div class="setting-label">
            <span>Clear History</span>
            <span>Remove all execution history</span>
          </div>
          <button class="btn btn-ghost" onclick="clearHistory()">Clear</button>
        </div>
        <div class="setting-row">
          <div class="setting-label">
            <span>Clear Cache</span>
            <span>Force fresh data on next load</span>
          </div>
          <button class="btn btn-ghost" onclick="clearServerCache()">Clear</button>
        </div>
      </div>
      
      <button class="btn btn-primary" style="margin-top: 1rem; width: 100%;" onclick="saveAndCloseSettings()">Save Settings</button>
    </div>
  </div>
  
  <!-- Code Search Modal -->
  <div class="modal-overlay" id="searchModal" onclick="if(event.target === this) hideCodeSearch()">
    <div class="modal search-modal">
      <button class="modal-close" onclick="hideCodeSearch()">✕</button>
      <h2>🔍 Code Search</h2>
      <div class="search-input-group">
        <input type="text" id="codeSearchInput" placeholder="Search pattern..." onkeyup="if(event.key === 'Enter') performCodeSearch()">
        <label style="display: flex; align-items: center; gap: 0.5rem; font-size: 0.85rem; color: var(--text-secondary);">
          <input type="checkbox" id="codeSearchRegex"> Regex
        </label>
        <button class="btn btn-primary" onclick="performCodeSearch()">Search</button>
      </div>
      <div class="search-results" id="codeSearchResults">
        <div style="padding: 2rem; text-align: center; color: var(--text-muted);">
          Enter a search pattern to find code across your project
        </div>
      </div>
    </div>
  </div>
  
  <!-- Terminal Modal -->
  <div class="modal-overlay" id="terminalModal" onclick="if(event.target === this) hideTerminal()">
    <div class="modal terminal-modal">
      <button class="modal-close" onclick="hideTerminal()">✕</button>
      <h2>💻 Terminal</h2>
      <div class="terminal-container">
        <div class="terminal-header">
          <span class="terminal-dot red"></span>
          <span class="terminal-dot yellow"></span>
          <span class="terminal-dot green"></span>
          <span style="margin-left: 1rem; color: var(--text-muted); font-size: 0.85rem;">workspace terminal</span>
        </div>
        <div class="terminal-body" id="terminalOutput">
          <div class="terminal-line">
            <span style="color: var(--accent-success);">$</span> Welcome to MCP Terminal
          </div>
          <div class="terminal-line" style="color: var(--text-muted);">
            Available commands: ls, pwd, cat, head, tail, wc, find, grep, du, tree
          </div>
        </div>
        <div class="terminal-input">
          <span class="terminal-prompt">$</span>
          <input type="text" id="terminalInput" placeholder="Enter command..." onkeyup="if(event.key === 'Enter') executeTerminalCommand()">
        </div>
      </div>
    </div>
  </div>
  
  <!-- Health Score Modal -->
  <div class="modal-overlay" id="healthModal" onclick="if(event.target === this) hideHealthModal()">
    <div class="modal">
      <button class="modal-close" onclick="hideHealthModal()">✕</button>
      <h2>🏥 Project Health</h2>
      <div id="healthContent">
        <div style="text-align: center; padding: 2rem; color: var(--text-muted);">
          <div style="font-size: 2rem; margin-bottom: 0.5rem;">⏳</div>
          Analyzing project health...
        </div>
      </div>
    </div>
  </div>
  
  <!-- Toast Container -->
  <div class="toast-container" id="toastContainer"></div>
  
  <!-- Debug Panel -->
  <div id="debugPanel" class="debug-panel">
    <div class="debug-header">
      <span>🔧 Debug Console</span>
      <div class="debug-actions">
        <button onclick="DebugSystem.analyzeSidebar()" title="Analyze Sidebar">🔍</button>
        <button onclick="DebugSystem.clear()" title="Clear Logs">🗑️</button>
        <button onclick="debugExport()" title="Export Logs">📥</button>
        <button onclick="toggleDebugPanel()" title="Minimize">➖</button>
      </div>
    </div>
    <div class="debug-body">
      <div id="debugLogList" class="debug-log-list"></div>
    </div>
    <div class="debug-footer">
      <span id="debugStatus">Ready</span>
      <span id="debugCount">0 events</span>
    </div>
  </div>
  
  <!-- Debug Toggle Button -->
  <button id="debugToggle" class="debug-toggle" onclick="toggleDebugPanel()" title="Toggle Debug Panel">
    🔧
  </button>
  
  <!-- LIVE DEBUG STATUS BAR - Always visible at top -->
  <div id="liveDebugBar" style="position: fixed; top: 0; left: 0; right: 0; background: #1a1a2e; color: #0f0; font-family: monospace; font-size: 12px; padding: 8px 16px; z-index: 999999; border-bottom: 2px solid #0f0; display: flex; gap: 20px; flex-wrap: wrap;">
    <span>🔴 LIVE DEBUG</span>
    <span id="liveClickTarget">Click: --</span>
    <span id="liveNavStatus">Nav: --</span>
    <span id="liveTabStatus">Tab: --</span>
    <span id="liveError" style="color: #f00;">Errors: 0</span>
  </div>
  
  <script>
    // ==================== LIVE DEBUG SYSTEM ====================
    var errorCount = 0;
    var lastClickTarget = '--';
    var lastNavAction = '--';
    var lastTabSwitch = '--';
    
    function updateLiveDebug() {
      var clickEl = document.getElementById('liveClickTarget');
      var navEl = document.getElementById('liveNavStatus');
      var tabEl = document.getElementById('liveTabStatus');
      var errEl = document.getElementById('liveError');
      
      if (clickEl) clickEl.textContent = 'Click: ' + lastClickTarget;
      if (navEl) navEl.textContent = 'Nav: ' + lastNavAction;
      if (tabEl) tabEl.textContent = 'Tab: ' + lastTabSwitch;
      if (errEl) errEl.textContent = 'Errors: ' + errorCount;
    }
    
    // Catch ALL errors
    window.onerror = function(msg, url, line, col, error) {
      errorCount++;
      console.error('CAUGHT ERROR:', msg, 'at', url, line, col);
      lastNavAction = 'ERROR: ' + msg.substring(0, 50);
      updateLiveDebug();
      return false;
    };
    
    // ==================== DIRECT NAV CLICK HANDLER ====================
    // This is called directly from onclick="" attributes - GUARANTEED to work
    function navClick(element, tabName, filter) {
      console.log('navClick called!', tabName, filter);
      lastNavAction = 'navClick: ' + tabName;
      updateLiveDebug();
      
      // Update active state
      var allNavItems = document.querySelectorAll('.nav-item');
      for (var i = 0; i < allNavItems.length; i++) {
        allNavItems[i].classList.remove('active');
      }
      element.classList.add('active');
      
      // Update filter state
      if (typeof state !== 'undefined') {
        state.filter = filter || null;
      }
      
      // Switch tab
      showTab(tabName);
      
      // Re-render tools if filtered
      if (tabName === 'tools' && typeof renderAllTools === 'function') {
        renderAllTools();
      }
    }
    // Make it global
    window.navClick = navClick;
    
    // Track all clicks with immediate feedback
    document.addEventListener('click', function(e) {
      var target = e.target;
      var info = target.tagName;
      if (target.id) info += '#' + target.id;
      if (target.className) info += '.' + String(target.className).split(' ')[0];
      lastClickTarget = info;
      updateLiveDebug();
      
      // Check if it's a nav-item
      var navItem = target.closest('.nav-item');
      if (navItem) {
        var tab = navItem.getAttribute('data-tab');
        lastNavAction = 'CLICKED nav-item, tab=' + tab;
        updateLiveDebug();
      }
    }, true);
    
    // ==================== DEBUG SYSTEM ====================
    const DebugSystem = {
      enabled: true,
      logs: [],
      maxLogs: 500,
      
      // Log levels
      LEVELS: { DEBUG: 0, INFO: 1, WARN: 2, ERROR: 3, CLICK: 4 },
      
      log(level, category, message, data = null) {
        if (!this.enabled) return;
        
        const entry = {
          timestamp: new Date().toISOString(),
          level: Object.keys(this.LEVELS).find(k => this.LEVELS[k] === level) || 'DEBUG',
          category,
          message,
          data
        };
        
        this.logs.push(entry);
        if (this.logs.length > this.maxLogs) this.logs.shift();
        
        // Console output with colors
        const colors = {
          DEBUG: 'color: #888',
          INFO: 'color: #58a6ff',
          WARN: 'color: #d29922',
          ERROR: 'color: #f85149',
          CLICK: 'color: #a371f7'
        };
        
        console.log(
          '%c[' + entry.level + '] [' + category + '] ' + message,
          colors[entry.level] || 'color: #888',
          data || ''
        );
        
        // Update debug panel if visible
        this.updateDebugPanel();
      },
      
      debug(category, message, data) { this.log(this.LEVELS.DEBUG, category, message, data); },
      info(category, message, data) { this.log(this.LEVELS.INFO, category, message, data); },
      warn(category, message, data) { this.log(this.LEVELS.WARN, category, message, data); },
      error(category, message, data) { this.log(this.LEVELS.ERROR, category, message, data); },
      click(message, data) { this.log(this.LEVELS.CLICK, 'CLICK', message, data); },
      
      // Get element info for debugging
      getElementInfo(el) {
        if (!el) return null;
        return {
          tag: el.tagName,
          id: el.id || null,
          classes: Array.from(el.classList),
          text: el.textContent ? el.textContent.substring(0, 50) : '',
          rect: el.getBoundingClientRect(),
          computedStyle: {
            position: getComputedStyle(el).position,
            zIndex: getComputedStyle(el).zIndex,
            pointerEvents: getComputedStyle(el).pointerEvents,
            visibility: getComputedStyle(el).visibility,
            display: getComputedStyle(el).display,
            opacity: getComputedStyle(el).opacity
          }
        };
      },
      
      // Find blocking elements at a point
      findBlockingElements(x, y) {
        const elements = document.elementsFromPoint(x, y);
        const self = this;
        return elements.map(function(el) {
          var info = self.getElementInfo(el);
          info.blocksClicks = getComputedStyle(el).pointerEvents !== 'none';
          return info;
        });
      },
      
      // Analyze sidebar specifically
      analyzeSidebar() {
        const sidebar = document.querySelector('.sidebar');
        const navItems = document.querySelectorAll('.nav-item');
        const self = this;
        
        this.info('ANALYSIS', 'Sidebar Analysis', {
          sidebarFound: !!sidebar,
          sidebarInfo: this.getElementInfo(sidebar),
          navItemCount: navItems.length,
          navItems: Array.from(navItems).map(function(item) {
            var info = self.getElementInfo(item);
            info.hasClickListener = item.onclick !== null || item._hasClickListener;
            return info;
          })
        });
        
        // Check for overlapping elements
        if (navItems.length > 0) {
          const firstNav = navItems[0];
          const rect = firstNav.getBoundingClientRect();
          const centerX = rect.left + rect.width / 2;
          const centerY = rect.top + rect.height / 2;
          
          this.info('ANALYSIS', 'Elements at first nav-item center', 
            this.findBlockingElements(centerX, centerY)
          );
        }
      },
      
      // Get logs for export
      exportLogs() {
        return JSON.stringify(this.logs, null, 2);
      },
      
      // Clear logs
      clear() {
        this.logs = [];
        this.updateDebugPanel();
      },
      
      // Update debug panel UI
      updateDebugPanel() {
        const panel = document.getElementById('debugPanel');
        const logList = document.getElementById('debugLogList');
        if (!panel || !logList) return;
        
        const recentLogs = this.logs.slice(-20).reverse();
        logList.innerHTML = recentLogs.map(function(log) {
          return '<div class="debug-log-entry debug-' + log.level.toLowerCase() + '">' +
            '<span class="debug-time">' + log.timestamp.split('T')[1].split('.')[0] + '</span>' +
            '<span class="debug-level">[' + log.level + ']</span>' +
            '<span class="debug-cat">[' + log.category + ']</span>' +
            '<span class="debug-msg">' + log.message + '</span>' +
          '</div>';
        }).join('');
      }
    };
    
    // Global click tracker
    document.addEventListener('click', function(e) {
      const path = e.composedPath();
      const targetInfo = DebugSystem.getElementInfo(e.target);
      
      DebugSystem.click('Click at (' + e.clientX + ', ' + e.clientY + ')', {
        target: targetInfo,
        pathLength: path.length,
        pathSummary: path.slice(0, 5).map(function(el) {
          if (el.tagName) {
            return el.tagName + (el.id ? '#' + el.id : '') + (el.className ? '.' + String(el.className).split(' ')[0] : '');
          }
          return 'window';
        }),
        defaultPrevented: e.defaultPrevented,
        propagationStopped: e._propagationStopped || false
      });
      
      // Check if click was on nav-item
      const navItem = e.target.closest('.nav-item');
      if (navItem) {
        DebugSystem.info('NAV', 'Nav item clicked!', {
          tab: navItem.dataset.tab,
          filter: navItem.dataset.filter,
          navItemInfo: DebugSystem.getElementInfo(navItem)
        });
      }
      
      // Check what elements are at click point
      const elementsAtPoint = document.elementsFromPoint(e.clientX, e.clientY);
      const blockingElements = elementsAtPoint.filter(function(el) {
        const style = getComputedStyle(el);
        return style.pointerEvents !== 'none' && 
               style.visibility !== 'hidden' && 
               style.display !== 'none';
      });
      
      if (blockingElements.length > 1) {
        DebugSystem.debug('STACK', blockingElements.length + ' elements at click point', 
          blockingElements.slice(0, 5).map(function(el) {
            return {
              tag: el.tagName,
              id: el.id,
              className: el.className ? String(el.className).split(' ')[0] : '',
              zIndex: getComputedStyle(el).zIndex,
              pointerEvents: getComputedStyle(el).pointerEvents
            };
          })
        );
      }
    }, true);  // Capture phase to see all clicks
    
    // Track event listener additions
    const originalAddEventListener = EventTarget.prototype.addEventListener;
    EventTarget.prototype.addEventListener = function(type, listener, options) {
      if (type === 'click' && this.classList && this.classList.contains('nav-item')) {
        this._hasClickListener = true;
        DebugSystem.debug('LISTENER', 'Click listener added to nav-item', {
          element: DebugSystem.getElementInfo(this)
        });
      }
      return originalAddEventListener.call(this, type, listener, options);
    };
    
    // Expose debug functions globally
    window.DebugSystem = DebugSystem;
    window.debugSidebar = function() { DebugSystem.analyzeSidebar(); };
    window.debugLogs = function() { console.table(DebugSystem.logs.slice(-20)); };
    window.debugExport = function() {
      const blob = new Blob([DebugSystem.exportLogs()], {type: 'application/json'});
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'debug-logs.json';
      a.click();
    };
    
    // ==================== STATE ====================
    const state = {
      tools: [],
      resources: [],
      prompts: [],
      history: JSON.parse(localStorage.getItem('mcpHistory') || '[]'),
      favorites: JSON.parse(localStorage.getItem('mcpFavorites') || '["project_stats", "git_status", "find_todos"]'),
      selectedTool: null,
      currentTab: 'dashboard',
      filter: null,
      settings: {
        theme: localStorage.getItem('mcpTheme') || 'dark',
        autoRefresh: localStorage.getItem('mcpAutoRefresh') !== 'false',
        refreshInterval: parseInt(localStorage.getItem('mcpRefreshInterval')) || 30000,
        notifications: localStorage.getItem('mcpNotifications') !== 'false'
      },
      autoRefreshTimer: null,
      currentExportType: null
    };
    
    // ==================== API ====================
    const API_KEY = 'CargoEscapeBigProject';
    
    async function apiCall(endpoint, method = 'GET', body = null) {
      const options = {
        method,
        headers: {
          'Authorization': 'Bearer ' + API_KEY,
          'Content-Type': 'application/json'
        }
      };
      if (body) options.body = JSON.stringify(body);
      
      const response = await fetch(endpoint, options);
      return response.json();
    }
    
    // ==================== DATA LOADING ====================
    async function loadTools() {
      try {
        const data = await apiCall('/api/tools');
        state.tools = data.tools || [];
        document.getElementById('toolCount').textContent = state.tools.length;
        renderQuickActions();
        renderAllTools();
      } catch (error) {
        console.error('Failed to load tools:', error);
      }
    }
    
    async function loadStats() {
      try {
        const stats = await apiCall('/api/stats');
        document.getElementById('statScripts').textContent = stats.scripts || '-';
        document.getElementById('statScenes').textContent = stats.scenes || '-';
        document.getElementById('statLines').textContent = formatNumber(stats.linesOfCode) || '-';
        document.getElementById('statTodos').textContent = stats.todos || '-';
      } catch (error) {
        console.error('Failed to load stats:', error);
      }
    }
    
    async function loadResources() {
      try {
        const data = await apiCall('/api/resources');
        state.resources = data.resources || [];
        renderResources();
      } catch (error) {
        console.error('Failed to load resources:', error);
      }
    }
    
    async function loadPrompts() {
      try {
        const data = await apiCall('/api/prompts');
        state.prompts = data.prompts || [];
        renderPrompts();
      } catch (error) {
        console.error('Failed to load prompts:', error);
      }
    }
    
    async function loadMetrics() {
      try {
        const metrics = await apiCall('/api/metrics');
        renderMetrics(metrics);
      } catch (error) {
        console.error('Failed to load metrics:', error);
      }
    }
    
    // ==================== RENDERING ====================
    function renderQuickActions() {
      const container = document.getElementById('quickActions');
      const quickTools = state.tools
        .filter(t => state.favorites.includes(t.name) || 
                     ['project_stats', 'git_status', 'godot_lint', 'find_todos'].includes(t.name))
        .slice(0, 6);
      
      container.innerHTML = quickTools.map(tool => createToolCard(tool)).join('');
    }
    
    function renderAllTools() {
      const container = document.getElementById('allTools');
      let filteredTools = state.tools;
      
      if (state.filter) {
        filteredTools = state.tools.filter(t => 
          t.category === state.filter || 
          (t.tags && t.tags.includes(state.filter))
        );
      }
      
      container.innerHTML = filteredTools.map(tool => createToolCard(tool)).join('');
    }
    
    function createToolCard(tool) {
      const icons = {
        godot: '🎮',
        git: '📋',
        analysis: '🔍',
        quality: '✅',
        documentation: '📝',
        default: '🔧'
      };
      const icon = icons[tool.category] || icons.default;
      const tags = (tool.tags || []).slice(0, 3).map(t => '<span class="tag">' + t + '</span>').join('');
      
      return \`
        <div class="tool-card" onclick="selectTool('\${tool.name}')">
          <div class="tool-header">
            <span class="tool-icon">\${icon}</span>
            <span class="tool-name">\${formatToolName(tool.name)}</span>
            <span class="tool-category">\${tool.category || 'general'}</span>
          </div>
          <div class="tool-desc">\${tool.description || 'No description'}</div>
          <div class="tool-tags">\${tags}</div>
        </div>
      \`;
    }
    
    function renderResources() {
      const container = document.getElementById('resourcesList');
      container.innerHTML = state.resources.map(resource => \`
        <div class="tool-card" onclick="readResource('\${resource.uri}')">
          <div class="tool-header">
            <span class="tool-icon">📦</span>
            <span class="tool-name">\${resource.name}</span>
          </div>
          <div class="tool-desc">\${resource.description || 'No description'}</div>
          <div class="tool-tags">
            <span class="tag">\${resource.mimeType || 'text/plain'}</span>
          </div>
        </div>
      \`).join('');
    }
    
    function renderPrompts() {
      const container = document.getElementById('promptsList');
      container.innerHTML = state.prompts.map(prompt => \`
        <div class="tool-card" onclick="showPrompt('\${prompt.name}')">
          <div class="tool-header">
            <span class="tool-icon">💬</span>
            <span class="tool-name">\${formatToolName(prompt.name)}</span>
          </div>
          <div class="tool-desc">\${prompt.description || 'No description'}</div>
        </div>
      \`).join('');
    }
    
    function renderMetrics(metrics) {
      const container = document.getElementById('metricsGrid');
      container.innerHTML = \`
        <div class="metric-box">
          <div class="metric-label">Uptime</div>
          <div class="metric-value">\${formatDuration(metrics.uptime || 0)}</div>
        </div>
        <div class="metric-box">
          <div class="metric-label">Total Requests</div>
          <div class="metric-value">\${formatNumber(metrics.totalRequests || 0)}</div>
        </div>
        <div class="metric-box">
          <div class="metric-label">Tool Executions</div>
          <div class="metric-value">\${formatNumber(metrics.toolExecutions || 0)}</div>
        </div>
        <div class="metric-box">
          <div class="metric-label">Cache Hit Rate</div>
          <div class="metric-value">\${((metrics.cacheHitRate || 0) * 100).toFixed(1)}%</div>
        </div>
        <div class="metric-box">
          <div class="metric-label">Avg Response Time</div>
          <div class="metric-value">\${(metrics.avgResponseTime || 0).toFixed(0)}ms</div>
        </div>
        <div class="metric-box">
          <div class="metric-label">Memory Usage</div>
          <div class="metric-value">\${formatBytes(metrics.memoryUsage || 0)}</div>
        </div>
      \`;
    }
    
    function renderHistory() {
      const container = document.getElementById('historyList');
      if (state.history.length === 0) {
        container.innerHTML = '<p style="color: var(--text-muted); text-align: center; padding: 2rem;">No execution history yet</p>';
        return;
      }
      
      container.innerHTML = state.history.slice(0, 50).map(item => \`
        <div class="history-item" onclick="rerunHistory('\${item.tool}', '\${btoa(JSON.stringify(item.args || {}))}')">
          <span class="time">\${formatTime(item.timestamp)}</span>
          <span class="tool-name">\${formatToolName(item.tool)}</span>
          <span class="status \${item.success ? 'success' : 'error'}">\${item.success ? 'Success' : 'Failed'}</span>
        </div>
      \`).join('');
    }
    
    // ==================== TOOL EXECUTION ====================
    function selectTool(toolName) {
      state.selectedTool = state.tools.find(t => t.name === toolName);
      if (!state.selectedTool) return;
      
      const panel = document.getElementById('toolPanel');
      const inputs = document.getElementById('toolInputs');
      const output = document.getElementById('toolOutput');
      
      document.getElementById('panelToolName').textContent = formatToolName(toolName);
      output.style.display = 'none';
      
      // Build input form from schema
      const schema = state.selectedTool.inputSchema;
      if (schema && schema.properties && Object.keys(schema.properties).length > 0) {
        inputs.innerHTML = Object.entries(schema.properties).map(([name, prop]) => \`
          <div class="input-group">
            <label>\${name}\${(schema.required || []).includes(name) ? ' *' : ''}</label>
            \${prop.enum 
              ? \`<select id="input-\${name}">
                  \${prop.enum.map(v => \`<option value="\${v}">\${v}</option>\`).join('')}
                </select>\`
              : \`<input type="text" id="input-\${name}" placeholder="\${prop.description || ''}">\`
            }
          </div>
        \`).join('');
      } else {
        inputs.innerHTML = '<p style="color: var(--text-muted);">No parameters required</p>';
      }
      
      panel.style.display = 'block';
      panel.scrollIntoView({ behavior: 'smooth' });
    }
    
    async function runSelectedTool() {
      if (!state.selectedTool) return;
      
      const output = document.getElementById('toolOutput');
      output.style.display = 'block';
      output.className = 'output-display';
      output.textContent = 'Executing...';
      
      // Gather inputs
      const args = {};
      const schema = state.selectedTool.inputSchema;
      if (schema && schema.properties) {
        for (const name of Object.keys(schema.properties)) {
          const input = document.getElementById('input-' + name);
          if (input && input.value) {
            args[name] = input.value;
          }
        }
      }
      
      try {
        const result = await apiCall('/api/tools/' + state.selectedTool.name, 'POST', args);
        output.className = 'output-display success';
        output.innerHTML = formatToolOutput(state.selectedTool.name, result);
        addToHistory(state.selectedTool.name, args, true);
      } catch (error) {
        output.className = 'output-display error';
        output.textContent = 'Error: ' + error.message;
        addToHistory(state.selectedTool.name, args, false);
      }
    }
    
    async function executeTool(toolName, args = {}) {
      selectTool(toolName);
      await new Promise(r => setTimeout(r, 100));
      await runSelectedTool();
    }
    
    function closeToolPanel() {
      document.getElementById('toolPanel').style.display = 'none';
    }
    
    async function readResource(uri) {
      const output = document.getElementById('toolOutput');
      const panel = document.getElementById('toolPanel');
      
      document.getElementById('panelToolName').textContent = 'Resource: ' + uri;
      document.getElementById('toolInputs').innerHTML = '';
      output.style.display = 'block';
      output.className = 'output-display';
      output.textContent = 'Loading resource...';
      panel.style.display = 'block';
      
      try {
        const result = await apiCall('/api/resources/' + encodeURIComponent(uri));
        output.className = 'output-display success';
        output.textContent = typeof result.content === 'string' 
          ? result.content 
          : JSON.stringify(result.content, null, 2);
      } catch (error) {
        output.className = 'output-display error';
        output.textContent = 'Error: ' + error.message;
      }
    }
    
    function showPrompt(promptName) {
      const prompt = state.prompts.find(p => p.name === promptName);
      if (!prompt) return;
      
      const panel = document.getElementById('toolPanel');
      const inputs = document.getElementById('toolInputs');
      const output = document.getElementById('toolOutput');
      
      document.getElementById('panelToolName').textContent = formatToolName(promptName);
      output.style.display = 'none';
      
      if (prompt.arguments && prompt.arguments.length > 0) {
        inputs.innerHTML = prompt.arguments.map(arg => \`
          <div class="input-group">
            <label>\${arg.name}\${arg.required ? ' *' : ''}</label>
            <input type="text" id="prompt-\${arg.name}" placeholder="\${arg.description || ''}">
          </div>
        \`).join('');
      } else {
        inputs.innerHTML = '<p style="color: var(--text-muted);">No arguments required</p>';
      }
      
      inputs.innerHTML += \`
        <button class="btn btn-primary" style="margin-top: 1rem;" onclick="getPromptContent('\${promptName}')">
          📋 Get Prompt
        </button>
      \`;
      
      panel.style.display = 'block';
    }
    
    async function getPromptContent(promptName) {
      const prompt = state.prompts.find(p => p.name === promptName);
      const output = document.getElementById('toolOutput');
      output.style.display = 'block';
      
      const args = {};
      if (prompt.arguments) {
        for (const arg of prompt.arguments) {
          const input = document.getElementById('prompt-' + arg.name);
          if (input && input.value) {
            args[arg.name] = input.value;
          }
        }
      }
      
      try {
        const result = await apiCall('/api/prompts/' + promptName, 'POST', args);
        output.className = 'output-display success';
        output.textContent = result.messages?.[0]?.content?.text || JSON.stringify(result, null, 2);
      } catch (error) {
        output.className = 'output-display error';
        output.textContent = 'Error: ' + error.message;
      }
    }
    
    // ==================== OUTPUT FORMATTER ====================
    function formatToolOutput(toolName, result) {
      // Handle different tool outputs with custom formatting
      
      // Project Stats
      if (toolName === 'project_stats') {
        return formatProjectStats(result);
      }
      
      // Find TODOs
      if (toolName === 'find_todos') {
        return formatTodos(result);
      }
      
      // List Scripts
      if (toolName === 'godot_list_scripts') {
        return formatFileList(result.scripts || [], 'GDScript Files', '📄');
      }
      
      // List Scenes
      if (toolName === 'godot_list_scenes') {
        return formatFileList(result.scenes || [], 'Scene Files', '🎬');
      }
      
      // Git Status
      if (toolName === 'git_status') {
        return formatGitStatus(result);
      }
      
      // Git Log
      if (toolName === 'git_log') {
        return formatGitLog(result);
      }
      
      // Git Branches
      if (toolName === 'git_branches') {
        return formatGitBranches(result);
      }
      
      // Echo test
      if (toolName === 'echo_test') {
        return '<div class="output-section"><h4>✅ Echo Response</h4><div class="output-stat-grid"><div class="output-stat-item"><div class="stat-value">✓</div><div class="stat-label">Success</div></div><div class="output-stat-item"><div class="stat-value">' + (result.latency || 'N/A') + '</div><div class="stat-label">Latency</div></div></div><div style="margin-top: 1rem; padding: 0.75rem; background: var(--bg-secondary); border-radius: 8px;"><strong>Message:</strong> ' + escapeHtml(result.message || '') + '</div></div>';
      }
      
      // Godot Version
      if (toolName === 'godot_version') {
        return '<div class="output-section"><h4>🎮 Godot Version</h4><div class="output-stat-grid"><div class="output-stat-item"><div class="stat-value">' + escapeHtml(result.version || 'Unknown') + '</div><div class="stat-label">Version</div></div><div class="output-stat-item"><div class="stat-value">' + (result.installed ? '✅' : '❌') + '</div><div class="stat-label">Installed</div></div></div></div>';
      }
      
      // Default: formatted JSON with syntax highlighting
      return formatJsonOutput(result);
    }
    
    function formatProjectStats(result) {
      let html = '<div class="output-section"><h4>📊 Project Statistics</h4>';
      html += '<div class="output-stat-grid">';
      html += '<div class="output-stat-item"><div class="stat-value">' + (result.scripts?.count || 0) + '</div><div class="stat-label">Scripts</div></div>';
      html += '<div class="output-stat-item"><div class="stat-value">' + (result.scenes?.count || 0) + '</div><div class="stat-label">Scenes</div></div>';
      html += '<div class="output-stat-item"><div class="stat-value">' + (result.resources?.count || 0) + '</div><div class="stat-label">Resources</div></div>';
      html += '<div class="output-stat-item"><div class="stat-value">' + (result.shaders?.count || 0) + '</div><div class="stat-label">Shaders</div></div>';
      html += '</div></div>';
      
      html += '<div class="output-section"><h4>💻 Code Metrics</h4>';
      html += '<div class="output-stat-grid">';
      html += '<div class="output-stat-item"><div class="stat-value">' + (result.total?.linesOfCode || 0).toLocaleString() + '</div><div class="stat-label">Lines of Code</div></div>';
      html += '<div class="output-stat-item"><div class="stat-value">' + (result.scripts?.averageLines || 0) + '</div><div class="stat-label">Avg Lines/Script</div></div>';
      html += '<div class="output-stat-item"><div class="stat-value">' + (result.total?.files || 0) + '</div><div class="stat-label">Total Files</div></div>';
      html += '</div></div>';
      
      if (result.scripts?.longestScript) {
        html += '<div class="output-section"><h4>🏆 Longest Script</h4>';
        html += '<div class="output-list-item"><span class="file-path">' + result.scripts.longestScript.path + '</span>';
        html += '<span class="output-badge info">' + result.scripts.longestScript.lines + ' lines</span></div></div>';
      }
      
      return html;
    }
    
    function formatTodos(result) {
      const summary = result.summary || {};
      const details = result.details || {};
      
      let html = '<div class="output-section"><h4>📋 Summary</h4><div style="display: flex; gap: 0.5rem; flex-wrap: wrap;">';
      for (const [type, count] of Object.entries(summary)) {
        if (count > 0) {
          html += '<span class="output-badge ' + type.toLowerCase() + '">' + count + ' ' + type + '</span>';
        }
      }
      html += '</div></div>';
      
      // Flatten and render items
      const allItems = [];
      for (const [type, items] of Object.entries(details)) {
        items.forEach(item => allItems.push({ ...item, type }));
      }
      
      if (allItems.length === 0) {
        html += '<div class="output-section"><h4>✨ No Issues Found</h4><p style="color: var(--text-muted);">Your codebase is clean!</p></div>';
        return html;
      }
      
      // Sort by file then line
      allItems.sort((a, b) => a.file.localeCompare(b.file) || a.line - b.line);
      
      html += '<div class="output-section"><h4>📝 Details</h4><div class="output-list">';
      for (const item of allItems.slice(0, 50)) {
        html += '<div class="output-list-item">';
        html += '<span class="output-badge ' + item.type.toLowerCase() + '">' + item.type + '</span>';
        html += '<span class="file-path">' + escapeHtml(item.file) + '</span>';
        html += '<span class="line-num">:' + item.line + '</span>';
        html += '</div>';
      }
      if (allItems.length > 50) {
        html += '<div style="text-align: center; padding: 0.5rem; color: var(--text-muted);">...and ' + (allItems.length - 50) + ' more</div>';
      }
      html += '</div></div>';
      
      return html;
    }
    
    function formatFileList(files, title, icon) {
      let html = '<div class="output-section"><h4>' + icon + ' ' + title + '</h4>';
      html += '<div class="output-stat-grid"><div class="output-stat-item"><div class="stat-value">' + files.length + '</div><div class="stat-label">Total Files</div></div></div></div>';
      
      if (files.length === 0) {
        html += '<div style="text-align: center; padding: 1rem; color: var(--text-muted);">No files found</div>';
        return html;
      }
      
      // Group by directory
      const grouped = {};
      files.forEach(f => {
        const parts = f.split('/');
        const dir = parts.slice(0, -1).join('/') || 'root';
        if (!grouped[dir]) grouped[dir] = [];
        grouped[dir].push(parts[parts.length - 1]);
      });
      
      html += '<div class="output-section"><h4>📁 By Directory</h4>';
      for (const [dir, dirFiles] of Object.entries(grouped).sort((a, b) => a[0].localeCompare(b[0]))) {
        html += '<div style="margin-bottom: 0.75rem;">';
        html += '<div style="font-size: 0.8rem; color: var(--text-muted); margin-bottom: 0.25rem;">' + dir + '/</div>';
        html += '<div class="output-list">';
        for (const f of dirFiles.sort().slice(0, 20)) {
          html += '<div class="output-list-item"><span>' + icon + '</span><span class="content">' + escapeHtml(f) + '</span></div>';
        }
        if (dirFiles.length > 20) {
          html += '<div style="padding: 0.25rem 0.75rem; color: var(--text-muted); font-size: 0.8rem;">...and ' + (dirFiles.length - 20) + ' more</div>';
        }
        html += '</div></div>';
      }
      html += '</div>';
      
      return html;
    }
    
    function formatGitStatus(result) {
      let html = '<div class="output-section"><h4>🌿 Git Status</h4>';
      html += '<div class="output-stat-grid">';
      html += '<div class="output-stat-item"><div class="stat-value">' + escapeHtml(result.branch || 'N/A') + '</div><div class="stat-label">Current Branch</div></div>';
      html += '<div class="output-stat-item"><div class="stat-value">' + (result.clean ? '✅' : '⚠️') + '</div><div class="stat-label">' + (result.clean ? 'Clean' : 'Changes') + '</div></div>';
      html += '</div></div>';
      
      if (result.staged && result.staged.length > 0) {
        html += '<div class="output-section"><h4>✅ Staged Changes</h4><div class="output-list">';
        for (const f of result.staged.slice(0, 10)) {
          html += '<div class="output-list-item"><span style="color: var(--accent-success);">+</span><span class="content">' + escapeHtml(f) + '</span></div>';
        }
        html += '</div></div>';
      }
      
      if (result.modified && result.modified.length > 0) {
        html += '<div class="output-section"><h4>📝 Modified Files</h4><div class="output-list">';
        for (const f of result.modified.slice(0, 10)) {
          html += '<div class="output-list-item"><span style="color: var(--accent-warning);">M</span><span class="content">' + escapeHtml(f) + '</span></div>';
        }
        html += '</div></div>';
      }
      
      if (result.untracked && result.untracked.length > 0) {
        html += '<div class="output-section"><h4>❓ Untracked Files</h4><div class="output-list">';
        for (const f of result.untracked.slice(0, 10)) {
          html += '<div class="output-list-item"><span style="color: var(--text-muted);">?</span><span class="content">' + escapeHtml(f) + '</span></div>';
        }
        html += '</div></div>';
      }
      
      return html;
    }
    
    function formatGitLog(result) {
      const commits = result.commits || [];
      let html = '<div class="output-section"><h4>📜 Recent Commits</h4>';
      html += '<div class="output-stat-grid"><div class="output-stat-item"><div class="stat-value">' + commits.length + '</div><div class="stat-label">Commits Shown</div></div></div></div>';
      
      if (commits.length === 0) {
        html += '<div style="text-align: center; padding: 1rem; color: var(--text-muted);">No commits found</div>';
        return html;
      }
      
      html += '<div class="output-section"><div class="output-list">';
      for (const c of commits.slice(0, 20)) {
        html += '<div class="output-list-item" style="flex-direction: column; gap: 0.25rem;">';
        html += '<div style="display: flex; gap: 0.5rem; align-items: center;">';
        html += '<span style="font-family: monospace; color: var(--accent-warning); font-size: 0.8rem;">' + (c.hash || c.sha || '').substring(0, 7) + '</span>';
        html += '<span style="color: var(--text-muted); font-size: 0.8rem;">' + escapeHtml(c.date || c.timestamp || '') + '</span>';
        html += '</div>';
        html += '<div style="color: var(--text-primary);">' + escapeHtml(c.message || c.subject || '') + '</div>';
        html += '<div style="color: var(--text-muted); font-size: 0.8rem;">' + escapeHtml(c.author || '') + '</div>';
        html += '</div>';
      }
      html += '</div></div>';
      
      return html;
    }
    
    function formatGitBranches(result) {
      const branches = result.branches || [];
      let html = '<div class="output-section"><h4>🌿 Branches</h4>';
      html += '<div class="output-stat-grid"><div class="output-stat-item"><div class="stat-value">' + branches.length + '</div><div class="stat-label">Total Branches</div></div></div></div>';
      
      html += '<div class="output-section"><div class="output-list">';
      for (const b of branches) {
        const isCurrent = b.current || b.startsWith('* ');
        const name = b.replace(/^\\* /, '').trim();
        html += '<div class="output-list-item">';
        html += '<span style="color: ' + (isCurrent ? 'var(--accent-success)' : 'var(--text-muted)') + ';">' + (isCurrent ? '●' : '○') + '</span>';
        html += '<span class="content" style="' + (isCurrent ? 'color: var(--accent-success); font-weight: 600;' : '') + '">' + escapeHtml(name) + '</span>';
        if (isCurrent) html += '<span class="output-badge success">current</span>';
        html += '</div>';
      }
      html += '</div></div>';
      
      return html;
    }
    
    function formatJsonOutput(result) {
      // Pretty JSON with basic syntax highlighting
      const json = JSON.stringify(result, null, 2);
      const highlighted = json
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"([^"]+)":/g, '<span style="color: var(--accent-primary);">"$1"</span>:')
        .replace(/: "([^"]*)"/g, ': <span style="color: var(--accent-success);">"$1"</span>')
        .replace(/: (\d+)/g, ': <span style="color: var(--accent-warning);">$1</span>')
        .replace(/: (true|false)/g, ': <span style="color: var(--accent-secondary);">$1</span>')
        .replace(/: (null)/g, ': <span style="color: var(--text-muted);">$1</span>');
      
      return '<pre>' + highlighted + '</pre>';
    }

    // ==================== HISTORY ====================
    function addToHistory(tool, args, success) {
      state.history.unshift({
        tool,
        args,
        success,
        timestamp: Date.now()
      });
      state.history = state.history.slice(0, 100);
      localStorage.setItem('mcpHistory', JSON.stringify(state.history));
      renderHistory();
    }
    
    function rerunHistory(tool, argsBase64) {
      const args = JSON.parse(atob(argsBase64));
      selectTool(tool);
      
      // Fill in args
      setTimeout(() => {
        for (const [name, value] of Object.entries(args)) {
          const input = document.getElementById('input-' + name);
          if (input) input.value = value;
        }
      }, 100);
    }
    
    // ==================== DEBUG PANEL CONTROLS ====================
    function toggleDebugPanel() {
      const panel = document.getElementById('debugPanel');
      const toggle = document.getElementById('debugToggle');
      
      if (panel.classList.contains('minimized')) {
        panel.classList.remove('minimized');
        toggle.classList.add('hidden');
      } else {
        panel.classList.add('minimized');
      }
    }
    
    // Update debug counter
    setInterval(function() {
      const countEl = document.getElementById('debugCount');
      if (countEl) {
        countEl.textContent = DebugSystem.logs.length + ' events';
      }
    }, 1000);
    
    // ==================== NAVIGATION ====================
    function setupNavigation() {
      console.log('[setupNavigation] Starting...');
      DebugSystem.info('NAV', 'Setting up navigation...');
      
      var navItems = document.querySelectorAll('.nav-item');
      console.log('[setupNavigation] Found nav items:', navItems.length);
      DebugSystem.info('NAV', 'Found ' + navItems.length + ' nav items');
      
      navItems.forEach(function(item, index) {
        var tabName = item.getAttribute('data-tab');
        console.log('[setupNavigation] Setting up nav item', index, 'tab=', tabName);
        
        // Log each nav item
        var itemInfo = DebugSystem.getElementInfo(item);
        DebugSystem.debug('NAV', 'Nav item ' + index + ': tab=' + tabName, itemInfo);
        
        // Check computed styles that might block clicks
        var style = getComputedStyle(item);
        if (style.pointerEvents === 'none') {
          DebugSystem.error('NAV', 'Nav item ' + index + ' has pointer-events: none!', { tab: tabName });
        }
        if (style.visibility === 'hidden') {
          DebugSystem.error('NAV', 'Nav item ' + index + ' has visibility: hidden!', { tab: tabName });
        }
        
        item.addEventListener('click', function(e) {
          console.log('[NAV CLICK] Clicked! tab=', tabName);
          lastNavAction = 'HANDLER FIRED: ' + tabName;
          updateLiveDebug();
          
          DebugSystem.info('NAV', 'Nav item CLICKED! tab=' + tabName, {
            item: DebugSystem.getElementInfo(item)
          });
          
          var tab = item.getAttribute('data-tab');
          var filter = item.getAttribute('data-filter');
          
          console.log('[NAV CLICK] tab=', tab, 'filter=', filter);
          
          // Update active state
          document.querySelectorAll('.nav-item').forEach(function(i) { i.classList.remove('active'); });
          item.classList.add('active');
          
          // Update filter
          state.filter = filter || null;
          
          // Show tab
          showTab(tab);
          
          // Re-render tools if filtered
          if (tab === 'tools') {
            renderAllTools();
          }
        });
      });
      
      DebugSystem.info('NAV', 'Navigation setup complete');
      
      // Run sidebar analysis after setup
      setTimeout(function() {
        DebugSystem.analyzeSidebar();
      }, 500);
    }
    
    function showTab(tabName) {
      // Update live debug bar
      lastTabSwitch = 'SWITCHING TO: ' + tabName;
      updateLiveDebug();
      
      console.log('[showTab] Called with tabName:', tabName);
      DebugSystem.info('TAB', 'Switching to tab: ' + tabName);
      
      state.currentTab = tabName;
      
      // Hide all tabs
      var allTabs = document.querySelectorAll('.tab-container');
      console.log('[showTab] Found tab containers:', allTabs.length);
      DebugSystem.debug('TAB', 'Found ' + allTabs.length + ' tab containers');
      
      allTabs.forEach(function(tab) {
        tab.classList.remove('active');
        console.log('[showTab] Removed active from:', tab.id);
      });
      
      // Show target tab
      var targetTabId = 'tab-' + tabName;
      var targetTab = document.getElementById(targetTabId);
      console.log('[showTab] Looking for:', targetTabId, 'Found:', !!targetTab);
      DebugSystem.debug('TAB', 'Target tab element: ' + (targetTab ? 'found' : 'NOT FOUND'), { id: targetTabId });
      
      if (targetTab) {
        targetTab.classList.add('active');
        lastTabSwitch = 'ACTIVE: ' + tabName;
        console.log('[showTab] SUCCESS - Tab is now active:', tabName);
        DebugSystem.info('TAB', 'Tab ' + tabName + ' is now active');
      } else {
        lastTabSwitch = 'ERROR: ' + tabName + ' NOT FOUND!';
        console.error('[showTab] FAILED - Tab not found:', targetTabId);
        DebugSystem.error('TAB', 'Tab container not found: ' + targetTabId);
      }
      
      updateLiveDebug();
      
      // Auto-refresh data on tab switch
      switch (tabName) {
        case 'wiki':
          loadWikiFiles();
          break;
        case 'playground':
          loadPlaygroundFiles();
          break;
        case 'dashboard':
          loadStats();
          break;
        case 'metrics':
          loadMetrics();
          break;
        case 'history':
          renderHistory();
          break;
        case 'sound-studio':
          initSoundStudio();
          break;
      }
    }
    
    // ==================== KEYBOARD SHORTCUTS ====================
    function setupKeyboardShortcuts() {
      document.addEventListener('keydown', function(e) {
        // Don't trigger if typing in input
        if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') {
          if (e.key === 'Escape') {
            e.target.blur();
          }
          return;
        }
        
        switch (e.key) {
          case 'k':
            if (e.ctrlKey || e.metaKey) {
              e.preventDefault();
              document.getElementById('searchInput').focus();
            }
            break;
          case '1':
            showTab('dashboard');
            break;
          case '2':
            showTab('tools');
            break;
          case '3':
            showTab('resources');
            break;
          case 'r':
            refreshAll();
            break;
          case 'Escape':
            closeToolPanel();
            hideShortcuts();
            break;
        }
      });
    }
    
    function setupSearch() {
      const input = document.getElementById('searchInput');
      input.addEventListener('input', (e) => {
        const query = e.target.value.toLowerCase();
        if (query.length < 2) {
          renderAllTools();
          return;
        }
        
        const filtered = state.tools.filter(t => 
          t.name.toLowerCase().includes(query) ||
          (t.description && t.description.toLowerCase().includes(query)) ||
          (t.tags && t.tags.some(tag => tag.toLowerCase().includes(query)))
        );
        
        const container = document.getElementById('allTools');
        container.innerHTML = filtered.map(tool => createToolCard(tool)).join('');
        showTab('tools');
      });
    }
    
    // ==================== HELPERS ====================
    function formatToolName(name) {
      return name.replace(/_/g, ' ').replace(/\b\w/g, function(l) { return l.toUpperCase(); });
    }
    
    function formatNumber(num) {
      if (num >= 1000000) return (num / 1000000).toFixed(1) + 'M';
      if (num >= 1000) return (num / 1000).toFixed(1) + 'K';
      return num.toString();
    }
    
    function formatBytes(bytes) {
      if (bytes >= 1073741824) return (bytes / 1073741824).toFixed(1) + ' GB';
      if (bytes >= 1048576) return (bytes / 1048576).toFixed(1) + ' MB';
      if (bytes >= 1024) return (bytes / 1024).toFixed(1) + ' KB';
      return bytes + ' B';
    }
    
    function formatDuration(seconds) {
      if (seconds >= 86400) return Math.floor(seconds / 86400) + 'd';
      if (seconds >= 3600) return Math.floor(seconds / 3600) + 'h';
      if (seconds >= 60) return Math.floor(seconds / 60) + 'm';
      return seconds + 's';
    }
    
    function formatTime(timestamp) {
      const diff = Date.now() - timestamp;
      if (diff < 60000) return 'Just now';
      if (diff < 3600000) return Math.floor(diff / 60000) + 'm ago';
      if (diff < 86400000) return Math.floor(diff / 3600000) + 'h ago';
      return new Date(timestamp).toLocaleDateString();
    }
    
    // ==================== MODAL ====================
    function showShortcuts() {
      document.getElementById('shortcutsModal').classList.add('show');
    }
    
    function hideShortcuts() {
      document.getElementById('shortcutsModal').classList.remove('show');
    }
    
    // ==================== DETAIL MODAL ====================
    function showDetailModal() {
      document.getElementById('detailModal').classList.add('show');
    }
    
    function hideDetailModal() {
      document.getElementById('detailModal').classList.remove('show');
    }
    
    async function showStatDetails(type) {
      showDetailModal();
      const titleEl = document.getElementById('detailModalTitle');
      const summaryEl = document.getElementById('detailSummary');
      const contentEl = document.getElementById('detailContent');
      
      // Show loading
      contentEl.innerHTML = '<div style="text-align: center; padding: 2rem; color: var(--text-muted);"><div style="font-size: 2rem; margin-bottom: 0.5rem;">⏳</div>Loading...</div>';
      summaryEl.innerHTML = '';
      
      try {
        switch(type) {
          case 'todos':
            titleEl.innerHTML = '⚠️ TODOs / FIXMEs / HACKs';
            await loadTodoDetails(contentEl, summaryEl);
            break;
          case 'scripts':
            titleEl.innerHTML = '📁 GDScript Files';
            await loadScriptDetails(contentEl, summaryEl);
            break;
          case 'scenes':
            titleEl.innerHTML = '🎬 Scene Files';
            await loadSceneDetails(contentEl, summaryEl);
            break;
          case 'lines':
            titleEl.innerHTML = '💻 Lines of Code';
            await loadLinesDetails(contentEl, summaryEl);
            break;
        }
      } catch (err) {
        contentEl.innerHTML = '<div style="text-align: center; padding: 2rem; color: var(--accent-error);"><div style="font-size: 2rem; margin-bottom: 0.5rem;">❌</div>Error loading data: ' + err.message + '</div>';
      }
    }
    
    async function loadTodoDetails(contentEl, summaryEl) {
      const result = await apiCall('/api/tools/find_todos', 'POST', { arguments: {} });
      if (result.error) throw new Error(result.error);
      
      const summary = result.summary || {};
      const details = result.details || {};
      
      // Render summary badges
      summaryEl.innerHTML = Object.entries(summary)
        .filter(([_, count]) => count > 0)
        .map(([type, count]) => '<span class="summary-badge ' + type.toLowerCase() + '">' + count + ' ' + type + '</span>')
        .join('');
      
      // Flatten all items from details
      const allItems = [];
      for (const [type, items] of Object.entries(details)) {
        items.forEach(item => allItems.push({ ...item, type }));
      }
      
      if (allItems.length === 0) {
        contentEl.innerHTML = '<div style="text-align: center; padding: 2rem; color: var(--accent-success);"><div style="font-size: 2rem; margin-bottom: 0.5rem;">✨</div>No TODOs found! Your code is clean!</div>';
        return;
      }
      
      // Sort by file, then line
      allItems.sort((a, b) => a.file.localeCompare(b.file) || a.line - b.line);
      
      // Render list
      contentEl.innerHTML = allItems.map(t => {
        const typeClass = t.type.toLowerCase();
        return '<div class="detail-item ' + typeClass + '"><span class="item-type ' + typeClass + '">' + t.type + '</span><div class="item-content"><div class="item-file">' + t.file + ':' + t.line + '</div><div class="item-text">' + escapeHtml(t.content) + '</div></div></div>';
      }).join('');
    }
    
    async function loadScriptDetails(contentEl, summaryEl) {
      const result = await apiCall('/api/tools/godot_list_scripts', 'POST', { arguments: {} });
      if (result.error) throw new Error(result.error);
      
      const scripts = result.scripts || [];
      
      summaryEl.innerHTML = '<span class="summary-badge scripts">' + scripts.length + ' Total Files</span>';
      
      if (scripts.length === 0) {
        contentEl.innerHTML = '<div style="text-align: center; padding: 2rem; color: var(--text-muted);"><div style="font-size: 2rem; margin-bottom: 0.5rem;">📭</div>No GDScript files found</div>';
        return;
      }
      
      // Group by directory
      const grouped = {};
      scripts.forEach(s => {
        const parts = s.split('/');
        const dir = parts.slice(0, -1).join('/') || 'root';
        if (!grouped[dir]) grouped[dir] = [];
        grouped[dir].push(parts[parts.length - 1]);
      });
      
      // Sort directories
      const sortedDirs = Object.keys(grouped).sort();
      
      contentEl.innerHTML = sortedDirs.map(dir => {
        const files = grouped[dir].sort();
        return '<div style="margin-bottom: 1rem;"><div style="font-size: 0.8rem; color: var(--text-muted); margin-bottom: 0.5rem; font-family: monospace;">📁 ' + dir + '/</div>' + 
          files.map(f => '<div class="detail-item" style="margin-bottom: 0.25rem; padding: 0.5rem 0.75rem;"><span style="color: var(--accent-primary);">📄</span><div class="item-content"><div class="item-text" style="font-family: monospace; font-size: 0.85rem;">' + f + '</div></div></div>').join('') + '</div>';
      }).join('');
    }
    
    async function loadSceneDetails(contentEl, summaryEl) {
      const result = await apiCall('/api/tools/godot_list_scenes', 'POST', { arguments: {} });
      if (result.error) throw new Error(result.error);
      
      const scenes = result.scenes || [];
      
      summaryEl.innerHTML = '<span class="summary-badge scenes">' + scenes.length + ' Total Scenes</span>';
      
      if (scenes.length === 0) {
        contentEl.innerHTML = '<div style="text-align: center; padding: 2rem; color: var(--text-muted);"><div style="font-size: 2rem; margin-bottom: 0.5rem;">📭</div>No scene files found</div>';
        return;
      }
      
      // Group by directory
      const grouped = {};
      scenes.forEach(s => {
        const parts = s.split('/');
        const dir = parts.slice(0, -1).join('/') || 'root';
        if (!grouped[dir]) grouped[dir] = [];
        grouped[dir].push(parts[parts.length - 1]);
      });
      
      // Sort directories
      const sortedDirs = Object.keys(grouped).sort();
      
      contentEl.innerHTML = sortedDirs.map(dir => {
        const files = grouped[dir].sort();
        return '<div style="margin-bottom: 1rem;"><div style="font-size: 0.8rem; color: var(--text-muted); margin-bottom: 0.5rem; font-family: monospace;">📁 ' + dir + '/</div>' + 
          files.map(f => '<div class="detail-item" style="margin-bottom: 0.25rem; padding: 0.5rem 0.75rem;"><span style="color: var(--accent-secondary);">🎬</span><div class="item-content"><div class="item-text" style="font-family: monospace; font-size: 0.85rem;">' + f + '</div></div></div>').join('') + '</div>';
      }).join('');
    }
    
    async function loadLinesDetails(contentEl, summaryEl) {
      const result = await apiCall('/api/tools/project_stats', 'POST', { arguments: {} });
      if (result.error) throw new Error(result.error);
      
      const totalLines = result.total?.linesOfCode || result.scripts?.totalLines || 0;
      
      summaryEl.innerHTML = '<span class="summary-badge lines">' + totalLines.toLocaleString() + ' Total Lines</span>';
      
      const breakdown = [
        { label: 'GDScript Files (.gd)', count: result.scripts?.count || 0, icon: '📄', color: 'var(--accent-primary)' },
        { label: 'Scene Files (.tscn)', count: result.scenes?.count || 0, icon: '🎬', color: 'var(--accent-secondary)' },
        { label: 'Resource Files (.tres)', count: result.resources?.count || 0, icon: '📦', color: 'var(--accent-success)' },
        { label: 'Shader Files (.gdshader)', count: result.shaders?.count || 0, icon: '🎨', color: 'var(--accent-warning)' },
      ];
      
      const longestScript = result.scripts?.longestScript;
      
      contentEl.innerHTML = '<div style="display: grid; gap: 1rem;">' +
        breakdown.map(b => {
          return '<div class="detail-item" style="display: flex; justify-content: space-between; align-items: center;"><div style="display: flex; align-items: center; gap: 0.75rem;"><span style="font-size: 1.5rem;">' + b.icon + '</span><span>' + b.label + '</span></div><span style="font-size: 1.25rem; font-weight: 600; color: ' + b.color + ';">' + b.count + '</span></div>';
        }).join('') +
        '<hr style="border: none; border-top: 1px solid var(--border-subtle); margin: 0.5rem 0;">' +
        '<div class="detail-item" style="display: flex; justify-content: space-between; align-items: center;"><div style="display: flex; align-items: center; gap: 0.75rem;"><span style="font-size: 1.5rem;">📊</span><span>Total Files</span></div><span style="font-size: 1.25rem; font-weight: 600; color: var(--text-secondary);">' + (result.total?.files || 0) + '</span></div>' +
        '<div class="detail-item" style="display: flex; justify-content: space-between; align-items: center;"><div style="display: flex; align-items: center; gap: 0.75rem;"><span style="font-size: 1.5rem;">💻</span><span>Total Lines of Code</span></div><span style="font-size: 1.5rem; font-weight: 700; color: var(--accent-success);">' + totalLines.toLocaleString() + '</span></div>' +
        '<div class="detail-item" style="display: flex; justify-content: space-between; align-items: center;"><div style="display: flex; align-items: center; gap: 0.75rem;"><span style="font-size: 1.5rem;">📈</span><span>Avg Lines per Script</span></div><span style="font-size: 1.25rem; font-weight: 600; color: var(--text-secondary);">' + (result.scripts?.averageLines || 0) + '</span></div>' +
        (longestScript ? '<hr style="border: none; border-top: 1px solid var(--border-subtle); margin: 0.5rem 0;"><div class="detail-item" style="flex-direction: column; align-items: stretch; gap: 0.5rem;"><div style="display: flex; align-items: center; gap: 0.75rem;"><span style="font-size: 1.5rem;">🏆</span><span>Longest Script</span></div><div style="padding-left: 2.25rem; font-family: monospace; font-size: 0.85rem;"><div style="color: var(--accent-primary);">' + longestScript.path + '</div><div style="color: var(--text-muted);">' + longestScript.lines.toLocaleString() + ' lines</div></div></div>' : '') +
        '</div>';
    }
    
    function escapeHtml(str) {
      const div = document.createElement('div');
      div.textContent = str;
      return div.innerHTML;
    }

    function toggleProjectMenu() {
      showToast('Project switching will be available in a future update!', 'info');
    }
    
    async function refreshAll() {
      showToast('Refreshing data...', 'info');
      await Promise.all([
        loadTools(),
        loadStats(),
        loadResources(),
        loadPrompts(),
        loadMetrics(),
        loadNotifications()
      ]);
      showToast('Data refreshed!', 'success');
    }
    
    // ==================== THEME ====================
    function toggleTheme() {
      const isLight = document.body.classList.toggle('light-theme');
      state.settings.theme = isLight ? 'light' : 'dark';
      localStorage.setItem('mcpTheme', state.settings.theme);
      document.getElementById('themeToggle')?.classList.toggle('active', !isLight);
    }
    
    function toggleThemeSetting() {
      toggleTheme();
    }
    
    function applyTheme() {
      if (state.settings.theme === 'light') {
        document.body.classList.add('light-theme');
      }
    }
    
    // ==================== AUTO REFRESH ====================
    function toggleAutoRefresh() {
      state.settings.autoRefresh = !state.settings.autoRefresh;
      localStorage.setItem('mcpAutoRefresh', state.settings.autoRefresh);
      updateAutoRefreshUI();
      
      if (state.settings.autoRefresh) {
        startAutoRefresh();
        showToast('Auto-refresh enabled', 'success');
      } else {
        stopAutoRefresh();
        showToast('Auto-refresh disabled', 'info');
      }
    }
    
    function toggleAutoRefreshSetting() {
      toggleAutoRefresh();
      document.getElementById('autoRefreshToggle')?.classList.toggle('active', state.settings.autoRefresh);
    }
    
    function updateRefreshInterval() {
      const interval = parseInt(document.getElementById('refreshInterval')?.value || 30000);
      state.settings.refreshInterval = interval;
      localStorage.setItem('mcpRefreshInterval', interval);
      if (state.settings.autoRefresh) {
        stopAutoRefresh();
        startAutoRefresh();
      }
    }
    
    function startAutoRefresh() {
      if (state.autoRefreshTimer) clearInterval(state.autoRefreshTimer);
      state.autoRefreshTimer = setInterval(async () => {
        await loadStats();
        await loadNotifications();
      }, state.settings.refreshInterval);
      updateAutoRefreshUI();
    }
    
    function stopAutoRefresh() {
      if (state.autoRefreshTimer) {
        clearInterval(state.autoRefreshTimer);
        state.autoRefreshTimer = null;
      }
      updateAutoRefreshUI();
    }
    
    function updateAutoRefreshUI() {
      const indicator = document.getElementById('autoRefreshIndicator');
      const label = document.getElementById('autoRefreshLabel');
      if (indicator) {
        indicator.classList.toggle('active', state.settings.autoRefresh);
      }
      if (label) {
        label.textContent = state.settings.autoRefresh ? 'Auto' : 'Manual';
      }
    }
    
    // ==================== NOTIFICATIONS ====================
    function toggleNotifications() {
      const panel = document.getElementById('notificationPanel');
      panel?.classList.toggle('show');
    }
    
    function toggleNotifSetting() {
      state.settings.notifications = !state.settings.notifications;
      localStorage.setItem('mcpNotifications', state.settings.notifications);
      document.getElementById('notifToggle')?.classList.toggle('active', state.settings.notifications);
    }
    
    async function loadNotifications() {
      if (!state.settings.notifications) return;
      
      try {
        const result = await apiCall('/api/notifications');
        const badge = document.getElementById('notificationBadge');
        const list = document.getElementById('notificationList');
        
        if (result.count > 0 && badge) {
          badge.style.display = 'flex';
          badge.textContent = result.count;
        } else if (badge) {
          badge.style.display = 'none';
        }
        
        if (list && result.notifications?.length > 0) {
          list.innerHTML = result.notifications.map(n => {
            const icons = { warning: '⚠️', error: '❌', info: 'ℹ️', success: '✅' };
            return '<div class="notification-item ' + n.type + '"><span class="icon">' + (icons[n.type] || 'ℹ️') + '</span><div class="notification-content"><h4>' + escapeHtml(n.title) + '</h4><p>' + escapeHtml(n.message) + '</p></div></div>';
          }).join('');
        } else if (list) {
          list.innerHTML = '<div style="padding: 2rem; text-align: center; color: var(--text-muted);">No notifications</div>';
        }
      } catch (e) {
        console.error('Failed to load notifications:', e);
      }
    }
    
    function clearNotifications() {
      document.getElementById('notificationList').innerHTML = '<div style="padding: 2rem; text-align: center; color: var(--text-muted);">No notifications</div>';
      document.getElementById('notificationBadge').style.display = 'none';
      toggleNotifications();
      showToast('Notifications cleared', 'success');
    }
    
    // ==================== SETTINGS ====================
    function showSettings() {
      document.getElementById('settingsModal').classList.add('show');
      // Sync UI with state
      document.getElementById('themeToggle')?.classList.toggle('active', state.settings.theme === 'dark');
      document.getElementById('autoRefreshToggle')?.classList.toggle('active', state.settings.autoRefresh);
      document.getElementById('notifToggle')?.classList.toggle('active', state.settings.notifications);
      
      const intervalSelect = document.getElementById('refreshInterval');
      if (intervalSelect) intervalSelect.value = state.settings.refreshInterval;
    }
    
    function hideSettings() {
      document.getElementById('settingsModal').classList.remove('show');
    }
    
    function saveAndCloseSettings() {
      hideSettings();
      showToast('Settings saved!', 'success');
    }
    
    function clearHistory() {
      state.history = [];
      localStorage.setItem('mcpHistory', '[]');
      renderHistory();
      showToast('History cleared', 'success');
    }
    
    async function clearServerCache() {
      try {
        await apiCall('/api/cache/clear', 'POST');
        showToast('Server cache cleared', 'success');
      } catch (e) {
        showToast('Failed to clear cache', 'error');
      }
    }
    
    // ==================== CODE SEARCH ====================
    function showCodeSearch() {
      document.getElementById('searchModal').classList.add('show');
      document.getElementById('codeSearchInput').focus();
    }
    
    function hideCodeSearch() {
      document.getElementById('searchModal').classList.remove('show');
    }
    
    async function performCodeSearch() {
      const input = document.getElementById('codeSearchInput');
      const useRegex = document.getElementById('codeSearchRegex')?.checked;
      const results = document.getElementById('codeSearchResults');
      
      if (!input?.value.trim()) return;
      
      results.innerHTML = '<div style="padding: 2rem; text-align: center; color: var(--text-muted);">Searching...</div>';
      
      try {
        const result = await apiCall('/api/tools/search_code', 'POST', {
          pattern: input.value,
          useRegex,
          maxResults: 50
        });
        
        if (!result.results?.length) {
          results.innerHTML = '<div style="padding: 2rem; text-align: center; color: var(--text-muted);">No results found</div>';
          return;
        }
        
        results.innerHTML = '<div style="padding: 0.5rem; color: var(--text-muted); font-size: 0.85rem;">' + result.totalMatches + ' matches found' + (result.truncated ? ' (showing first 50)' : '') + '</div>' +
          result.results.map(r => {
            const highlighted = escapeHtml(r.content).replace(new RegExp(escapeHtml(input.value), 'gi'), '<mark>$&</mark>');
            return '<div class="search-result-item" onclick="previewFile(\\'' + r.file.replace(/'/g, "\\\\'") + '\\', ' + r.line + ')"><div class="search-result-file">' + r.file + ':' + r.line + '</div><div class="search-result-line">' + highlighted + '</div></div>';
          }).join('');
      } catch (e) {
        results.innerHTML = '<div style="padding: 2rem; text-align: center; color: var(--accent-error);">Error: ' + e.message + '</div>';
      }
    }
    
    // ==================== WIKI INLINE VIEWER (NO POPUP) ====================
    let currentWikiData = null;
    let currentWikiPath = null;
    let wikiFiles = { scripts: [], scenes: [], resources: [], docs: [] };
    let selectedWikiFile = null;
    
    // Load files for wiki browser
    async function loadWikiFiles() {
      const folderFilter = document.getElementById('wikiFolderFilter')?.value || '';
      const typeFilter = document.getElementById('wikiTypeFilter')?.value || '';
      const fileList = document.getElementById('wikiFileTree');
      
      if (fileList) {
        fileList.innerHTML = '<div class="wiki-empty"><div class="icon">⏳</div>Loading files...</div>';
      }
      
      try {
        // Load scripts
        if (!typeFilter || typeFilter === '.gd') {
          const result = await apiCall('/api/tools/godot_list_scripts', 'POST', {});
          wikiFiles.scripts = result.scripts || [];
        }
        
        // Load scenes  
        if (!typeFilter || typeFilter === '.tscn') {
          const result = await apiCall('/api/tools/godot_list_scenes', 'POST', {});
          wikiFiles.scenes = result.scenes || [];
        }
        
        renderWikiFileList();
      } catch (e) {
        if (fileList) {
          fileList.innerHTML = '<div class="wiki-empty"><div class="icon">❌</div>Error: ' + escapeHtml(e.message) + '</div>';
        }
      }
    }
    
    async function refreshWikiFiles() {
      await loadWikiFiles();
      showToast('Files refreshed!', 'success');
    }
    
    function renderWikiFileList() {
      const container = document.getElementById('wikiFileTree');
      if (!container) return;
      
      const searchTerm = (document.getElementById('wikiSearchInput')?.value || '').toLowerCase();
      const folderFilter = document.getElementById('wikiFolderFilter')?.value || '';
      const typeFilter = document.getElementById('wikiTypeFilter')?.value || '';
      
      // Group files by folder
      const folders = {};
      
      const addFilesToFolder = (files, type) => {
        files.forEach(file => {
          if (searchTerm && !file.toLowerCase().includes(searchTerm)) return;
          if (typeFilter && !file.endsWith(typeFilter)) return;
          
          const parts = file.split('/');
          const fileName = parts.pop();
          const folderPath = parts.join('/') || 'root';
          
          if (folderFilter && !folderPath.startsWith(folderFilter)) return;
          
          if (!folders[folderPath]) {
            folders[folderPath] = [];
          }
          folders[folderPath].push({ name: fileName, path: file, type });
        });
      };
      
      addFilesToFolder(wikiFiles.scripts, 'script');
      addFilesToFolder(wikiFiles.scenes, 'scene');
      addFilesToFolder(wikiFiles.resources, 'resource');
      
      if (Object.keys(folders).length === 0) {
        container.innerHTML = '<div class="wiki-empty"><div class="icon">📭</div>No files found</div>';
        return;
      }
      
      // Sort folders
      const sortedFolders = Object.keys(folders).sort();
      
      let html = '';
      sortedFolders.forEach(folder => {
        const files = folders[folder].sort((a, b) => a.name.localeCompare(b.name));
        const folderIcon = folder === 'root' ? '🏠' : '📁';
        
        html += '<div class="wiki-folder">';
        html += '<div class="wiki-folder-header" onclick="toggleWikiFolder(this)">';
        html += '<span class="folder-icon">▼</span>';
        html += '<span>' + folderIcon + '</span>';
        html += '<span>' + escapeHtml(folder === 'root' ? 'Root' : folder) + '</span>';
        html += '<span style="margin-left: auto; color: var(--text-muted); font-size: 0.7rem;">' + files.length + '</span>';
        html += '</div>';
        html += '<div class="wiki-folder-files">';
        
        files.forEach(file => {
          const icons = { script: '📜', scene: '🎬', resource: '📦', doc: '📄' };
          const isActive = selectedWikiFile === file.path;
          
          html += '<div class="wiki-file-item' + (isActive ? ' active' : '') + '" onclick="selectWikiFile(\\'' + escapeHtml(file.path) + '\\')">';
          html += '<span class="file-icon">' + icons[file.type] + '</span>';
          html += '<span class="file-name">' + escapeHtml(file.name) + '</span>';
          html += '</div>';
        });
        
        html += '</div></div>';
      });
      
      container.innerHTML = html;
    }
    
    function toggleWikiFolder(header) {
      header.parentElement.classList.toggle('collapsed');
    }
    
    function filterWikiFiles() {
      renderWikiFileList();
    }
    
    // Select and load full wiki for a file (inline, no popup)
    async function selectWikiFile(filePath) {
      selectedWikiFile = filePath;
      currentWikiPath = filePath;
      renderWikiFileList(); // Update selection highlight
      
      const mainPanel = document.getElementById('wikiMainPanel');
      mainPanel.innerHTML = '<div class="wiki-empty"><div class="icon">⏳</div>Analyzing file...</div>';
      
      try {
        const result = await apiCall('/api/tools/wiki_analyze', 'POST', {
          filePath,
          includeCode: true,
          includeUsages: true
        });
        
        currentWikiData = result;
        renderWikiInline(result);
      } catch (e) {
        mainPanel.innerHTML = '<div class="wiki-empty"><div class="icon">❌</div>Error: ' + escapeHtml(e.message) + '</div>';
      }
    }
    
    // Render wiki content inline (replaces the modal approach)
    function renderWikiInline(data) {
      const { meta, analysis, sections, content } = data;
      const mainPanel = document.getElementById('wikiMainPanel');
      
      let html = '';
      
      // Header section
      html += '<div class="wiki-main-header">';
      html += '<div class="wiki-title-section">';
      html += '<div class="wiki-title">';
      html += '<h2>' + getFileIcon(meta.extension) + ' ' + escapeHtml(meta.fileName) + '</h2>';
      html += '<span class="wiki-file-type">' + escapeHtml(meta.fileType) + '</span>';
      html += '</div>';
      html += '<div class="wiki-path">';
      html += '<span>' + escapeHtml(meta.filePath) + '</span>';
      html += '<button class="btn" onclick="copyToClipboard(\\'' + escapeHtml(meta.filePath) + '\\')">📋</button>';
      html += '</div>';
      html += '<div class="wiki-quick-stats">';
      html += '<span class="wiki-stat">📏 ' + meta.totalLines + ' lines</span>';
      html += '<span class="wiki-stat">📦 ' + formatBytes(meta.fileSize) + '</span>';
      if (analysis.overview?.extends) {
        html += '<span class="wiki-stat">🔗 extends ' + escapeHtml(analysis.overview.extends) + '</span>';
      }
      html += '</div>';
      html += '</div>';
      html += '<div class="wiki-actions">';
      html += '<button class="btn" onclick="openInPlayground(\\'' + escapeHtml(meta.filePath) + '\\')">🎮 Playground</button>';
      html += '<button class="btn" onclick="refreshCurrentWiki()">🔄 Refresh</button>';
      html += '</div>';
      html += '</div>';
      
      // Main content area with TOC
      html += '<div class="wiki-main-content">';
      
      // TOC sidebar
      html += '<div class="wiki-toc">';
      html += '<nav class="wiki-nav">';
      html += '<div class="wiki-nav-title">Contents</div>';
      sections.forEach(s => {
        html += '<div class="wiki-nav-item" onclick="scrollToWikiSection(\\'' + s.id + '\\')">';
        html += '<span>' + s.icon + '</span>';
        html += '<span>' + s.title + '</span>';
        html += '</div>';
      });
      html += '</nav>';
      html += '</div>';
      
      // Content area
      html += '<div class="wiki-content">';
      
      if (meta.fileType === 'GDScript') {
        html += renderGDScriptWikiContent(analysis, content);
      } else if (meta.fileType === 'Scene') {
        html += renderSceneWikiContent(analysis, content);
      } else if (meta.fileType === 'Resource') {
        html += renderResourceWikiContent(analysis, content);
      } else {
        html += renderGenericWikiContent(meta, content);
      }
      
      html += '</div>'; // wiki-content
      html += '</div>'; // wiki-main-content
      
      mainPanel.innerHTML = html;
    }
    
    // Render GDScript wiki content
    function renderGDScriptWikiContent(analysis, content, highlightLine = null) {
      let html = '';
      
      // Overview Section
      html += '<section class="wiki-section" id="section-overview">';
      html += '<h3 class="wiki-section-title"><span>📄</span> Overview</h3>';
      html += '<div class="wiki-infobox">';
      
      if (analysis.overview.className) {
        html += '<div class="wiki-infobox-row"><span class="wiki-infobox-label">Class Name</span><span class="wiki-infobox-value">' + escapeHtml(analysis.overview.className) + '</span></div>';
      }
      if (analysis.overview.extends) {
        const extClass = analysis.overview.extends;
        const godotLink = analysis.godotLinks.find(l => l.name === extClass && l.type === 'Base Class');
        html += '<div class="wiki-infobox-row"><span class="wiki-infobox-label">Extends</span><span class="wiki-infobox-value">' + 
          (godotLink ? '<a href="' + godotLink.url + '" target="_blank" class="wiki-link-card external">' + extClass + ' 🔗</a>' : extClass) +
          '</span></div>';
      }
      if (analysis.overview.purpose) {
        html += '<div class="wiki-infobox-row"><span class="wiki-infobox-label">Purpose</span><span class="wiki-infobox-value">' + escapeHtml(analysis.overview.purpose) + '</span></div>';
      }
      if (analysis.overview.isTool) {
        html += '<div class="wiki-infobox-row"><span class="wiki-infobox-label">Type</span><span class="wiki-infobox-value">🛠️ Tool Script (runs in editor)</span></div>';
      }
      
      html += '</div>';
      
      // Description
      if (analysis.overview.description.length > 0) {
        html += '<div class="wiki-description">' + 
          analysis.overview.description.slice(0, 5).map(d => escapeHtml(d)).join('<br>') + 
          '</div>';
      }
      html += '</section>';
      
      // Signals Section
      if (analysis.signals.length > 0) {
        html += '<section class="wiki-section" id="section-signals">';
        html += '<h3 class="wiki-section-title"><span>📡</span> Signals</h3>';
        html += '<div class="wiki-item-grid">';
        analysis.signals.forEach(sig => {
          html += '<div class="wiki-item" onclick="scrollToLine(' + sig.line + ')">';
          html += '<span class="wiki-item-line">L' + sig.line + '</span>';
          html += '<div>';
          html += '<div class="wiki-item-name">signal ' + escapeHtml(sig.name) + '(' + escapeHtml(sig.parameters) + ')</div>';
          if (sig.description) {
            html += '<div class="wiki-item-desc">' + escapeHtml(sig.description) + '</div>';
          }
          html += '</div></div>';
        });
        html += '</div></section>';
      }
      
      // Exports Section
      if (analysis.exports.length > 0) {
        html += '<section class="wiki-section" id="section-exports">';
        html += '<h3 class="wiki-section-title"><span>📤</span> Exported Variables</h3>';
        html += '<p style="color: var(--text-secondary); font-size: 0.85rem; margin-bottom: 1rem;">These properties are visible in the Godot Inspector when this script is attached to a node.</p>';
        html += '<div class="wiki-item-grid">';
        analysis.exports.forEach(exp => {
          html += '<div class="wiki-item" onclick="scrollToLine(' + exp.line + ')">';
          html += '<span class="wiki-item-line">L' + exp.line + '</span>';
          html += '<div>';
          html += '<div><span class="wiki-item-name">' + escapeHtml(exp.name) + '</span><span class="wiki-item-type">: ' + escapeHtml(exp.type) + '</span></div>';
          if (exp.description) {
            html += '<div class="wiki-item-desc">' + escapeHtml(exp.description) + '</div>';
          }
          html += '</div></div>';
        });
        html += '</div></section>';
      }
      
      // Constants Section
      if (analysis.constants.length > 0) {
        html += '<section class="wiki-section" id="section-constants">';
        html += '<h3 class="wiki-section-title"><span>🔒</span> Constants</h3>';
        html += '<div class="wiki-item-grid">';
        analysis.constants.forEach(c => {
          html += '<div class="wiki-item" onclick="scrollToLine(' + c.line + ')">';
          html += '<span class="wiki-item-line">L' + c.line + '</span>';
          html += '<div>';
          html += '<div><span class="wiki-item-name">' + escapeHtml(c.name) + '</span> = <code>' + escapeHtml(c.value) + '</code></div>';
          html += '</div></div>';
        });
        html += '</div></section>';
      }
      
      // @onready Variables Section
      if (analysis.onreadyVars.length > 0) {
        html += '<section class="wiki-section" id="section-onready">';
        html += '<h3 class="wiki-section-title"><span>⚡</span> @onready Variables</h3>';
        html += '<p style="color: var(--text-secondary); font-size: 0.85rem; margin-bottom: 1rem;">Initialized after _ready() - typically node references. <a href="https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#onready-annotation" target="_blank">📚 Docs</a></p>';
        html += '<div class="wiki-item-grid">';
        analysis.onreadyVars.forEach(v => {
          html += '<div class="wiki-item" onclick="scrollToLine(' + v.line + ')">';
          html += '<span class="wiki-item-line">L' + v.line + '</span>';
          html += '<div><span class="wiki-item-name">' + escapeHtml(v.name) + '</span><span class="wiki-item-type">: ' + escapeHtml(v.type) + '</span></div>';
          html += '</div>';
        });
        html += '</div></section>';
      }
      
      // Functions Section
      if (analysis.functions.length > 0) {
        html += '<section class="wiki-section" id="section-functions">';
        html += '<h3 class="wiki-section-title"><span>⚙️</span> Functions</h3>';
        
        // Group by category
        const categories = {};
        analysis.functions.forEach(f => {
          const cat = f.category;
          if (!categories[cat]) categories[cat] = [];
          categories[cat].push(f);
        });
        
        for (const [cat, funcs] of Object.entries(categories)) {
          html += '<div style="margin-bottom: 1rem;"><strong style="color: var(--text-muted); font-size: 0.85rem;">' + cat + ' (' + funcs.length + ')</strong></div>';
          html += '<div class="wiki-item-grid">';
          funcs.forEach(f => {
            const badgeClass = f.isOverride ? 'override' : f.isCallback ? 'callback' : f.isPrivate ? 'private' : 'public';
            html += '<div class="wiki-item" onclick="scrollToLine(' + f.line + ')">';
            html += '<span class="wiki-item-line">L' + f.line + '</span>';
            html += '<div>';
            html += '<div style="display: flex; align-items: center; gap: 0.5rem;">';
            html += '<span class="wiki-item-name">' + escapeHtml(f.name) + '</span>';
            html += '<span class="wiki-item-badge ' + badgeClass + '">' + cat + '</span>';
            html += '</div>';
            html += '<div class="wiki-item-type">(' + escapeHtml(f.parameters) + ') → ' + escapeHtml(f.returnType) + '</div>';
            if (f.description) {
              html += '<div class="wiki-item-desc">' + escapeHtml(f.description) + '</div>';
            }
            html += '</div></div>';
          });
          html += '</div>';
        }
        html += '</section>';
      }
      
      // Dependencies Section - Click navigates within wiki
      if (analysis.dependencies.length > 0) {
        html += '<section class="wiki-section" id="section-dependencies">';
        html += '<h3 class="wiki-section-title"><span>🔗</span> Dependencies</h3>';
        html += '<p style="color: var(--text-secondary); font-size: 0.85rem; margin-bottom: 1rem;">Files loaded via preload() or load() - click to view</p>';
        html += '<div class="wiki-item-grid">';
        analysis.dependencies.forEach(dep => {
          const isScript = dep.path.endsWith('.gd');
          const isScene = dep.path.endsWith('.tscn');
          const icon = isScript ? '📜' : isScene ? '🎬' : '📦';
          html += '<div class="wiki-item" onclick="selectWikiFile(\\'' + escapeHtml(dep.path) + '\\')">';
          html += '<span class="wiki-item-line">L' + dep.line + '</span>';
          html += '<div>';
          html += '<div><span>' + icon + '</span> <span class="wiki-item-name">' + escapeHtml(dep.path) + '</span></div>';
          html += '<div class="wiki-item-type">' + dep.type + '</div>';
          html += '</div></div>';
        });
        html += '</div></section>';
      }
      
      // Used In Section - Click navigates within wiki
      if (analysis.usedIn?.length > 0) {
        html += '<section class="wiki-section" id="section-usages">';
        html += '<h3 class="wiki-section-title"><span>📍</span> Used In</h3>';
        html += '<p style="color: var(--text-secondary); font-size: 0.85rem; margin-bottom: 1rem;">Other files that reference this script - click to view</p>';
        html += '<div class="wiki-item-grid">';
        analysis.usedIn.forEach(u => {
          html += '<div class="wiki-item" onclick="selectWikiFile(\\'' + escapeHtml(u.file) + '\\')">';
          html += '<span class="wiki-item-line">L' + u.line + '</span>';
          html += '<div>';
          html += '<div class="wiki-item-name">' + escapeHtml(u.file) + '</div>';
          html += '<div class="wiki-item-desc">' + escapeHtml(u.context) + '</div>';
          html += '</div></div>';
        });
        html += '</div></section>';
      }
      
      // Godot Docs Section
      if (analysis.godotLinks.length > 0) {
        html += '<section class="wiki-section" id="section-godot-docs">';
        html += '<h3 class="wiki-section-title"><span>📚</span> Godot Documentation</h3>';
        html += '<p style="color: var(--text-secondary); font-size: 0.85rem; margin-bottom: 1rem;">Official Godot docs for classes used in this file</p>';
        html += '<div style="display: flex; flex-wrap: wrap;">';
        analysis.godotLinks.forEach(link => {
          html += '<a href="' + link.url + '" target="_blank" class="wiki-link-card external">';
          html += '<span>📖</span> <span>' + escapeHtml(link.name) + '</span>';
          html += '</a>';
        });
        html += '</div></section>';
      }
      
      // Source Code Section
      if (content) {
        html += '<section class="wiki-section" id="section-code">';
        html += '<h3 class="wiki-section-title"><span>💻</span> Source Code</h3>';
        html += '<div class="wiki-code-block">';
        html += '<div class="wiki-code-header"><span class="wiki-code-lang">GDScript</span><button class="btn" onclick="copyWikiCode()">📋 Copy</button></div>';
        html += '<div class="wiki-code-content" id="wikiCodeContent">';
        
        var lines = content.split(String.fromCharCode(10));
        lines.forEach(function(line, i) {
          var lineNum = i + 1;
          html += '<div class="line" id="code-line-' + lineNum + '">';
          html += '<span class="line-num">' + lineNum + '</span>';
          html += '<span class="line-content">' + escapeHtml(line) + '</span>';
          html += '</div>';
        });
        
        html += '</div></div></section>';
      }
      
      return html;
    }
    
    // Render Scene wiki content
    function renderSceneWikiContent(analysis, content) {
      let html = '';
      
      // Overview
      html += '<section class="wiki-section" id="section-overview">';
      html += '<h3 class="wiki-section-title"><span>🎬</span> Scene Overview</h3>';
      html += '<div class="wiki-infobox">';
      html += '<div class="wiki-infobox-row"><span class="wiki-infobox-label">Root Node</span><span class="wiki-infobox-value">' + escapeHtml(analysis.overview.rootNode || 'Unknown') + '</span></div>';
      html += '<div class="wiki-infobox-row"><span class="wiki-infobox-label">Root Type</span><span class="wiki-infobox-value">' + escapeHtml(analysis.overview.rootType || 'Unknown') + '</span></div>';
      html += '<div class="wiki-infobox-row"><span class="wiki-infobox-label">Total Nodes</span><span class="wiki-infobox-value">' + analysis.nodes.length + '</span></div>';
      html += '</div></section>';
      
      // Node Tree
      if (analysis.nodes.length > 0) {
        html += '<section class="wiki-section" id="section-nodes">';
        html += '<h3 class="wiki-section-title"><span>🌳</span> Node Tree</h3>';
        html += '<div class="wiki-item-grid">';
        analysis.nodes.forEach(node => {
          const icon = node.type === 'Instance' ? '📦' : '🔷';
          const godotLink = analysis.godotLinks.find(l => l.name === node.type);
          html += '<div class="wiki-item">';
          html += '<span>' + icon + '</span>';
          html += '<div>';
          html += '<div class="wiki-item-name">' + escapeHtml(node.name) + '</div>';
          if (godotLink) {
            html += '<a href="' + godotLink.url + '" target="_blank" class="wiki-item-type" style="text-decoration: none;">Type: ' + escapeHtml(node.type) + ' 🔗</a>';
          } else {
            html += '<div class="wiki-item-type">Type: ' + escapeHtml(node.type) + '</div>';
          }
          if (node.parent) {
            html += '<div class="wiki-item-desc">Parent: ' + escapeHtml(node.parent) + '</div>';
          }
          html += '</div></div>';
        });
        html += '</div></section>';
      }
      
      // Scripts
      if (analysis.scripts.length > 0) {
        html += '<section class="wiki-section" id="section-scripts">';
        html += '<h3 class="wiki-section-title"><span>📜</span> Attached Scripts</h3>';
        html += '<div class="wiki-item-grid">';
        analysis.scripts.forEach(script => {
          html += '<div class="wiki-item" onclick="openWiki(\\'' + escapeHtml(script.path) + '\\')">';
          html += '<span>📜</span>';
          html += '<div class="wiki-item-name">' + escapeHtml(script.path) + '</div>';
          html += '</div>';
        });
        html += '</div></section>';
      }
      
      // Signal Connections
      if (analysis.signals.length > 0) {
        html += '<section class="wiki-section" id="section-connections">';
        html += '<h3 class="wiki-section-title"><span>🔌</span> Signal Connections</h3>';
        html += '<div class="wiki-item-grid">';
        analysis.signals.forEach(sig => {
          html += '<div class="wiki-item">';
          html += '<span>📡</span>';
          html += '<div>';
          html += '<div class="wiki-item-name">' + escapeHtml(sig.signal) + '</div>';
          html += '<div class="wiki-item-desc">' + escapeHtml(sig.from) + ' → ' + escapeHtml(sig.to) + '.' + escapeHtml(sig.method) + '</div>';
          html += '</div></div>';
        });
        html += '</div></section>';
      }
      
      // Godot Docs
      if (analysis.godotLinks.length > 0) {
        html += '<section class="wiki-section" id="section-godot-docs">';
        html += '<h3 class="wiki-section-title"><span>📚</span> Godot Documentation</h3>';
        html += '<div style="display: flex; flex-wrap: wrap;">';
        analysis.godotLinks.forEach(link => {
          html += '<a href="' + link.url + '" target="_blank" class="wiki-link-card external">';
          html += '<span>📖</span> <span>' + escapeHtml(link.name) + '</span></a>';
        });
        html += '</div></section>';
      }
      
      // Source
      if (content) {
        html += '<section class="wiki-section" id="section-code">';
        html += '<h3 class="wiki-section-title"><span>💻</span> Scene Source</h3>';
        html += '<div class="wiki-code-block">';
        html += '<div class="wiki-code-header"><span class="wiki-code-lang">TSCN</span><button class="btn" onclick="copyWikiCode()">📋 Copy</button></div>';
        html += '<div class="wiki-code-content" id="wikiCodeContent">' + escapeHtml(content) + '</div>';
        html += '</div></section>';
      }
      
      return html;
    }
    
    // Render Resource wiki content
    function renderResourceWikiContent(analysis, content) {
      let html = '';
      
      html += '<section class="wiki-section" id="section-overview">';
      html += '<h3 class="wiki-section-title"><span>📦</span> Resource Overview</h3>';
      html += '<div class="wiki-infobox">';
      html += '<div class="wiki-infobox-row"><span class="wiki-infobox-label">Type</span><span class="wiki-infobox-value">' + escapeHtml(analysis.overview?.resourceType || 'Resource') + '</span></div>';
      if (analysis.overview?.scriptPath) {
        html += '<div class="wiki-infobox-row"><span class="wiki-infobox-label">Script</span><span class="wiki-infobox-value"><a href="#" onclick="selectWikiFile(\\'' + escapeHtml(analysis.overview.scriptPath) + '\\')">' + escapeHtml(analysis.overview.scriptPath) + '</a></span></div>';
      }
      html += '</div>';
      
      if (analysis.properties?.length > 0) {
        html += '<section class="wiki-section" id="section-properties">';
        html += '<h3 class="wiki-section-title"><span>⚙️</span> Properties</h3>';
        html += '<div class="wiki-item-grid">';
        analysis.properties.forEach(p => {
          html += '<div class="wiki-item">';
          html += '<div><span class="wiki-item-name">' + escapeHtml(p.name) + '</span> = <code>' + escapeHtml(p.value) + '</code></div>';
          html += '</div>';
        });
        html += '</div></section>';
      }
      
      // Source
      if (content) {
        html += '<section class="wiki-section" id="section-code">';
        html += '<h3 class="wiki-section-title"><span>💻</span> Source</h3>';
        html += '<div class="wiki-code-block">';
        html += '<div class="wiki-code-header"><span class="wiki-code-lang">TRES</span><button class="btn" onclick="copyWikiCode()">📋 Copy</button></div>';
        html += '<div class="wiki-code-content" id="wikiCodeContent">' + escapeHtml(content) + '</div>';
        html += '</div></section>';
      }
      
      html += '</section>';
      return html;
    }
    
    // Render generic file wiki content
    function renderGenericWikiContent(meta, content) {
      let html = '';
      
      html += '<section class="wiki-section" id="section-overview">';
      html += '<h3 class="wiki-section-title"><span>📄</span> File Overview</h3>';
      html += '<div class="wiki-infobox">';
      html += '<div class="wiki-infobox-row"><span class="wiki-infobox-label">Type</span><span class="wiki-infobox-value">' + escapeHtml(meta.extension || 'Unknown') + '</span></div>';
      html += '<div class="wiki-infobox-row"><span class="wiki-infobox-label">Size</span><span class="wiki-infobox-value">' + formatBytes(meta.fileSize || 0) + '</span></div>';
      html += '</div></section>';
      
      html += '<section class="wiki-section" id="section-code">';
      html += '<h3 class="wiki-section-title"><span>💻</span> File Contents</h3>';
      html += '<div class="wiki-code-block">';
      html += '<div class="wiki-code-header"><span class="wiki-code-lang">' + (meta.extension || '').substring(1).toUpperCase() + '</span><button class="btn" onclick="copyWikiCode()">📋 Copy</button></div>';
      html += '<div class="wiki-code-content" id="wikiCodeContent">' + escapeHtml(content || '') + '</div>';
      html += '</div></section>';
      
      return html;
    }
    
    // Helper functions
    function getFileIcon(ext) {
      const icons = {
        '.gd': '📜',
        '.tscn': '🎬',
        '.tres': '📦',
        '.md': '📝',
        '.json': '📋',
        '.cfg': '⚙️',
        '.import': '📥'
      };
      return icons[ext] || '📄';
    }
    
    function formatBytes(bytes) {
      if (!bytes || bytes < 1024) return (bytes || 0) + ' B';
      if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
      return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
    }
    
    function copyWikiCode() {
      if (currentWikiData?.content) {
        copyToClipboard(currentWikiData.content);
      }
    }
    
    function scrollToWikiSection(sectionId) {
      const el = document.getElementById('section-' + sectionId);
      if (el) {
        el.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    }
    
    function scrollToLine(lineNum) {
      const el = document.getElementById('code-line-' + lineNum);
      if (el) {
        el.scrollIntoView({ behavior: 'smooth', block: 'center' });
        el.classList.add('highlighted');
        setTimeout(() => el.classList.remove('highlighted'), 2000);
      }
    }
    
    async function refreshCurrentWiki() {
      if (currentWikiPath) {
        await selectWikiFile(currentWikiPath);
        showToast('Wiki refreshed!', 'success');
      }
    }
    
    function openInPlayground(filePath) {
      showTab('playground');
      setTimeout(() => {
        const select = document.getElementById('playgroundFileSelect');
        if (select) {
          select.value = filePath;
          loadPlaygroundFile();
        }
      }, 100);
    }

    // ==================== PLAYGROUND ====================
    let playgroundOriginalContent = '';
    let playgroundModifiedContent = '';
    let playgroundTodos = [];
    let playgroundExports = [];
    let playgroundCurrentFile = null;
    let playgroundAnalysis = null;
    let playgroundSelection = { start: null, end: null, text: '' };
    let playgroundActiveTemplate = null;
    let playgroundSidebarTab = 'variables';
    
    // ===== VARIABLE DOCUMENTATION DATABASE =====
    const VARIABLE_DOCS = {
      // Item properties
      'name': {
        description: 'Display name shown in inventory and loot UI',
        effect: 'Changes how the item appears to players in-game',
        range: 'Any text, typically 2-30 characters',
        links: [{ label: 'Godot String', url: 'https://docs.godotengine.org/en/stable/classes/class_string.html' }]
      },
      'id': {
        description: 'Unique identifier for the item in the database',
        effect: 'Must be unique - used for save/load and lookups',
        range: 'Lowercase with underscores (e.g., "plasma_cell")',
        links: []
      },
      'description': {
        description: 'Flavor text describing the item',
        effect: 'Shown in item tooltips and detail views',
        range: 'Keep under 100 characters for best display',
        links: []
      },
      'tags': {
        description: 'Array of classification tags for filtering and search',
        effect: 'Used for inventory filtering, loot tables, and faction affinity',
        range: 'Common tags: scrap, tech, contraband, medical, weapon',
        links: [{ label: 'Array Docs', url: 'https://docs.godotengine.org/en/stable/classes/class_array.html' }]
      },
      'weight': {
        description: 'Item weight in kilograms',
        effect: 'Affects inventory capacity and movement speed when carrying',
        range: '0.1 (tiny) to 50.0 (heavy cargo)',
        links: []
      },
      'base_value': {
        description: 'Standard sell price at legitimate vendors',
        effect: 'Base credits received when selling to stations',
        range: '10 (junk) to 50000 (legendary)',
        links: []
      },
      'black_market_value': {
        description: 'Price at black market dealers',
        effect: 'Usually 20-50% higher than base for contraband items',
        range: 'Set higher than base_value for illegal goods',
        links: []
      },
      'rarity': {
        description: 'Item rarity tier (COMMON=0 to LEGENDARY=4)',
        effect: 'Affects spawn rates, visual effects, and value multipliers',
        range: '0=Common, 1=Uncommon, 2=Rare, 3=Epic, 4=Legendary',
        links: []
      },
      'faction_affinity': {
        description: 'Faction index this item is associated with (-1 = universal)',
        effect: 'Items spawn more often in matching faction territory',
        range: '-1=Any, 0=Pirates, 1=Merchants, 2=Military, 3=Syndicate',
        links: []
      },
      'spawn_weight': {
        description: 'Relative spawn probability in loot tables',
        effect: 'Higher values = more common. Modified by ship tier.',
        range: '0.1 (very rare) to 5.0 (very common), default 1.0',
        links: []
      },
      'stack_size': {
        description: 'Maximum items per inventory slot',
        effect: 'Controls inventory space efficiency',
        range: '1 (unique) to 99 (consumables), typical: 1-20',
        links: []
      },
      'icon_path': {
        description: 'Resource path to item sprite',
        effect: 'Image shown in inventory UI',
        range: 'res://assets/sprites/items/your_icon.svg',
        links: [{ label: 'Godot Resources', url: 'https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html' }]
      },
      'width': {
        description: 'Item width in grid cells',
        effect: 'Tetris-style inventory space requirement',
        range: '1 to 4 cells wide',
        links: []
      },
      'height': {
        description: 'Item height in grid cells',
        effect: 'Tetris-style inventory space requirement',
        range: '1 to 4 cells tall',
        links: []
      },
      'category': {
        description: 'Item category enum (SCRAP=0, COMPONENT=1, etc)',
        effect: 'Used for inventory tabs and sorting',
        range: '0=Scrap, 1=Component, 2=Valuable, 3=Epic, 4=Legendary',
        links: []
      },
      
      // Ship properties
      'tier': {
        description: 'Ship tier determines difficulty and rewards',
        effect: 'Higher tiers unlock later, have better loot, more enemies',
        range: '0=Shuttle, 1=Freighter, 2=Transport, 3=Cruiser, 4=Capital',
        links: []
      },
      'time_limit': {
        description: 'Seconds before ship escape window closes',
        effect: 'Creates urgency - lower = harder missions',
        range: '60 (rush) to 300 (exploration), typical: 90-180',
        links: []
      },
      'size': {
        description: 'Ship dimensions in pixels (Vector2)',
        effect: 'Determines boarding area size and layout complexity',
        range: 'Small: 800x600, Large: 2400x1600',
        links: [{ label: 'Vector2', url: 'https://docs.godotengine.org/en/stable/classes/class_vector2.html' }]
      },
      'min_containers': {
        description: 'Minimum loot containers spawned',
        effect: 'Guarantees minimum loot opportunities',
        range: '2 (small ship) to 12 (capital ship)',
        links: []
      },
      'max_containers': {
        description: 'Maximum loot containers spawned',
        effect: 'Caps potential rewards per boarding',
        range: 'Should be min_containers + 2-6',
        links: []
      },
      'rarity_modifiers': {
        description: 'Multipliers for each rarity tier spawn rate',
        effect: 'Higher tier ships boost rare/epic/legendary drops',
        range: '0.0 (never) to 2.0 (doubled chance)',
        links: [{ label: 'Dictionary', url: 'https://docs.godotengine.org/en/stable/classes/class_dictionary.html' }]
      },
      'hull_color': {
        description: 'Primary ship color (Color)',
        effect: 'Visual identity of ship exterior',
        range: 'RGB values 0.0-1.0, or use Color.hex("FF5500")',
        links: [{ label: 'Color', url: 'https://docs.godotengine.org/en/stable/classes/class_color.html' }]
      },
      'accent_color': {
        description: 'Secondary trim color',
        effect: 'Visual highlights and details',
        range: 'Contrasting color to hull_color works best',
        links: [{ label: 'Color', url: 'https://docs.godotengine.org/en/stable/classes/class_color.html' }]
      },
      'interior_color': {
        description: 'Floor/wall color inside ship',
        effect: 'Atmosphere of boarding environment',
        range: 'Darker colors feel more industrial',
        links: [{ label: 'Color', url: 'https://docs.godotengine.org/en/stable/classes/class_color.html' }]
      },
      'lighting_tint': {
        description: 'Color tint for interior lighting',
        effect: 'Mood lighting - warm/cold/danger',
        range: 'Warm: (1.0, 0.9, 0.8), Cold: (0.8, 0.9, 1.0), Danger: (1.0, 0.7, 0.7)',
        links: [{ label: 'Color', url: 'https://docs.godotengine.org/en/stable/classes/class_color.html' }]
      },
      'danger_level': {
        description: 'Enemy spawn intensity (1-5)',
        effect: 'More enemies, tougher AI at higher levels',
        range: '1=Easy patrol, 3=Standard, 5=Heavy resistance',
        links: []
      },
      
      // Sound properties
      'file_path': {
        description: 'Path to audio file relative to sfx folder',
        effect: 'The actual sound file to play',
        range: 'category/filename.wav (e.g., "ui/click.wav")',
        links: []
      },
      'cooldown': {
        description: 'Minimum seconds between plays',
        effect: 'Prevents audio spam when rapidly triggered',
        range: '0.0 (no limit) to 1.0 (once per second)',
        links: []
      },
      'volume_db': {
        description: 'Volume in decibels (dB)',
        effect: 'Negative values = quieter. 0 = full volume.',
        range: '-40 (barely audible) to 0 (full), typical: -12 to 0',
        links: []
      },
      'pitch_variation': {
        description: 'Random pitch variation range',
        effect: 'Adds variety by slightly changing pitch each play',
        range: '0.0 (none) to 0.2 (noticeable variation)',
        links: []
      },
      
      // Generic GDScript
      'speed': {
        description: 'Movement speed value',
        effect: 'Pixels per second typically',
        range: '50 (slow) to 500 (fast), player default ~200',
        links: []
      },
      'health': {
        description: 'Hit points / damage capacity',
        effect: 'Entity destroyed when depleted',
        range: '10 (weak) to 1000 (boss), player ~100',
        links: []
      },
      'damage': {
        description: 'Damage dealt on hit',
        effect: 'Subtracted from target health',
        range: '5 (weak) to 100 (heavy), balance with health values',
        links: []
      },
      'has_glow': {
        description: 'Whether item has a glow effect',
        effect: 'Makes item visually stand out in inventory',
        range: 'true/false - typically true for Epic+ rarity',
        links: []
      },
      'glow_color': {
        description: 'Color of the glow effect',
        effect: 'Should match rarity: purple=epic, gold=legendary',
        range: 'Color value, often matches rarity theme',
        links: []
      },
      'is_consumable': {
        description: 'Whether item can be used/consumed',
        effect: 'Enables "Use" action, item destroyed on use',
        range: 'true for health packs, boosters, etc.',
        links: []
      }
    };
    
    // ===== TEMPLATE DEFINITIONS =====
    const PLAYGROUND_TEMPLATES = {
      item: {
        name: 'New Item Definition',
        icon: '📦',
        description: 'Create a complete item with all metadata',
        content: \`# ==============================================================================
# NEW ITEM DEFINITION
# ==============================================================================
# Add this to your item database or create as a resource

extends RefCounted

# Unique identifier
@export var id: String = "new_item"

# Display information
@export var name: String = "New Item"
@export var description: String = "A mysterious item found in space."

# Classification
@export var tags: Array[String] = ["misc", "collectible"]
@export var category: int = 0  # 0=SCRAP, 1=COMPONENT, 2=VALUABLE, 3=EPIC, 4=LEGENDARY

# Physical properties
@export var weight: float = 1.0  # kg
@export var width: int = 1  # inventory grid cells
@export var height: int = 1

# Economic values
@export var base_value: int = 100
@export var black_market_value: int = 120
@export var stack_size: int = 10

# Rarity and spawning
@export var rarity: int = 0  # 0=COMMON to 4=LEGENDARY
@export var spawn_weight: float = 1.0

# Faction
@export var faction_affinity: int = -1  # -1 = universal
@export var faction_restricted: Array[int] = []

# Visuals
@export var icon_path: String = "res://assets/sprites/items/placeholder.svg"

# Optional: Special effects
@export var has_glow: bool = false
@export var glow_color: Color = Color.WHITE

# Optional: Consumable
@export var is_consumable: bool = false
@export var effect_on_use: String = ""

# Convert to dictionary for serialization
func to_dict() -> Dictionary:
    return {
        "id": id,
        "name": name,
        "description": description,
        "tags": tags,
        "category": category,
        "weight": weight,
        "width": width,
        "height": height,
        "base_value": base_value,
        "black_market_value": black_market_value,
        "stack_size": stack_size,
        "rarity": rarity,
        "spawn_weight": spawn_weight,
        "faction_affinity": faction_affinity,
        "icon_path": icon_path
    }
\`
      },
      
      ship: {
        name: 'New Ship Type',
        icon: '🚀',
        description: 'Create a new boardable ship with full configuration',
        content: \`# ==============================================================================
# SHIP TYPE RESOURCE
# ==============================================================================
# Save as: resources/ships/my_ship.tres
# Or add directly to scripts/data/ship_types.gd

class_name MyShipType
extends Resource

# === IDENTIFICATION ===
@export var id: String = "cargo_freighter"
@export var name: String = "Cargo Freighter"
@export var description: String = "A medium-sized cargo vessel. Easy pickings."

# === TIER & DIFFICULTY ===
# Tier determines unlock requirements and base rewards
# 0=Shuttle, 1=Freighter, 2=Transport, 3=Cruiser, 4=Capital
@export var tier: int = 1
@export var danger_level: int = 2  # 1-5: enemy count and aggression
@export var time_limit: float = 120.0  # seconds to escape

# === DIMENSIONS ===
# Ship interior size in pixels (affects layout generation)
@export var width: int = 1600
@export var height: int = 1000

# === LOOT CONFIGURATION ===
@export var min_containers: int = 4
@export var max_containers: int = 8
@export var bonus_crate_chance: float = 0.15  # chance for extra loot

# Rarity multipliers (0=Common, 1=Uncommon, 2=Rare, 3=Epic, 4=Legendary)
@export var common_weight: float = 1.5
@export var uncommon_weight: float = 1.0
@export var rare_weight: float = 0.5
@export var epic_weight: float = 0.2
@export var legendary_weight: float = 0.05

# === ENEMY SPAWNS ===
@export var min_enemies: int = 2
@export var max_enemies: int = 5
@export var spawn_turrets: bool = true
@export var spawn_drones: bool = true

# === VISUAL STYLE ===
@export var hull_color: Color = Color(0.35, 0.38, 0.42)
@export var accent_color: Color = Color(0.6, 0.5, 0.3)
@export var interior_color: Color = Color(0.22, 0.2, 0.18)
@export var lighting_tint: Color = Color(1.0, 0.95, 0.9)

# === AUDIO ===
@export var ambient_sound: String = "ship_hum"
@export var alarm_sound: String = "alert_klaxon"

# Helper to get rarity weights as dictionary
func get_rarity_weights() -> Dictionary:
    return {
        0: common_weight,
        1: uncommon_weight,
        2: rare_weight,
        3: epic_weight,
        4: legendary_weight
    }
\`
      },
      
      sound: {
        name: 'New Sound Effect',
        icon: '🔊',
        description: 'Register a sound effect in the audio system',
        content: \`# ==============================================================================
# SOUND EFFECT CONFIGURATION
# ==============================================================================
# Add this entry to SOUNDS dictionary in scripts/audio_manager.gd
# File location: assets/audio/sfx/[category]/[filename].wav

# === SINGLE SOUND EFFECT ===
@export var sound_id: String = "container_open"
@export var file_path: String = "boarding/container_open.wav"
@export var cooldown: float = 0.1  # minimum seconds between plays
@export var volume_db: float = 0.0  # decibels (negative = quieter)
@export var pitch_variation: float = 0.0  # random pitch range +/-

# -----------------------------------------------------------------
# COPY THIS TO audio_manager.gd SOUNDS DICTIONARY:
# -----------------------------------------------------------------
# "container_open": {
#     "file": "boarding/container_open.wav",
#     "cooldown": 0.1,
#     "volume": 0.0,
#     "pitch_variation": 0.0
# },

# === SOUND CATEGORIES ===
# Organize your sounds in these folders:
#
# assets/audio/sfx/
# ├── boarding/     - Door, footstep, container sounds
# ├── combat/       - Weapons, impacts, explosions  
# ├── loot/         - Pickup sounds by rarity
# ├── ui/           - Clicks, confirms, errors
# ├── ship/         - Engine, shields, damage
# ├── alerts/       - Warnings, timers, alarms
# └── ambient/      - Background loops

# === PLAYING SOUNDS IN CODE ===
# Basic play:
#   AudioManager.play_sfx("container_open")
#
# Spatial (3D positioned):
#   AudioManager.play_sfx_at("container_open", global_position)
#
# With volume override:
#   AudioManager.play_sfx("container_open", -6.0)

# === AMBIENT LOOPS ===
# For looping background audio, add to AMBIENT_SOUNDS:
# "ship_interior": {
#     "file": "ambient/ship_hum_loop.wav",
#     "volume": -18.0
# },
#
# Play with: AudioManager.play_ambient("ship_interior")
# Stop with: AudioManager.stop_ambient("ship_interior")

# For ambient sounds (looping), add to AMBIENT_SOUNDS:
"ambient_name": {
    "file": "ambient_file.wav",
    "volume": -12.0  # dB, negative = quieter
},

# For music tracks, add to MUSIC_TRACKS:
"track_name": "folder/music_file.wav",

# Usage:
# AudioManager.play_music("track_name")
# AudioManager.play_ambient("ambient_name")
\`
      },
      
      module: {
        name: 'Ship Module',
        icon: '⚙️',
        description: 'Create a ship upgrade module',
        content: \`# ==============================================================================
# SHIP MODULE DEFINITION
# ==============================================================================
# Ship modules provide upgrades and bonuses

class_name ShipModule
extends Resource

# Identification
@export var id: String = "module_engine_boost"
@export var name: String = "Engine Booster Mk1"
@export var description: String = "Increases maximum speed by 15%."

# Module slot type
enum SlotType { ENGINE, WEAPONS, SHIELDS, UTILITY, SPECIAL }
@export var slot_type: SlotType = SlotType.ENGINE

# Stats and bonuses
@export var speed_bonus: float = 0.15  # 15% increase
@export var shield_bonus: float = 0.0
@export var damage_bonus: float = 0.0
@export var cargo_bonus: int = 0

# Power and requirements
@export var power_draw: float = 10.0  # Power units consumed
@export var required_level: int = 1

# Economic
@export var base_price: int = 5000
@export var rarity: int = 1  # UNCOMMON

# Visual
@export var icon_path: String = "res://assets/sprites/modules/engine_boost.svg"
@export var color_tint: Color = Color(0.2, 0.6, 1.0)

# Activation (for active modules)
@export var is_active: bool = false  # true = has activation ability
@export var cooldown: float = 30.0   # seconds between uses
@export var duration: float = 5.0    # effect duration

func apply_to_ship(ship: Node) -> void:
    if speed_bonus > 0:
        ship.max_speed *= (1.0 + speed_bonus)
    if shield_bonus > 0:
        ship.max_shields *= (1.0 + shield_bonus)
    if damage_bonus > 0:
        ship.weapon_damage *= (1.0 + damage_bonus)
    if cargo_bonus > 0:
        ship.cargo_capacity += cargo_bonus

func remove_from_ship(ship: Node) -> void:
    if speed_bonus > 0:
        ship.max_speed /= (1.0 + speed_bonus)
    if shield_bonus > 0:
        ship.max_shields /= (1.0 + shield_bonus)
    if damage_bonus > 0:
        ship.weapon_damage /= (1.0 + damage_bonus)
    if cargo_bonus > 0:
        ship.cargo_capacity -= cargo_bonus
\`
      },
      
      enemy: {
        name: 'Enemy Type',
        icon: '👾',
        description: 'Define a new enemy class',
        content: \`# ==============================================================================
# ENEMY TYPE DEFINITION
# ==============================================================================

class_name EnemyData
extends Resource

# Identification
@export var id: String = "enemy_patrol_drone"
@export var name: String = "Patrol Drone"
@export var description: String = "Automated security drone."

# Enemy category
enum Category { DRONE, FIGHTER, TURRET, BOSS, SWARM }
@export var category: Category = Category.DRONE

# Combat stats
@export var max_health: float = 50.0
@export var armor: float = 0.0  # Damage reduction
@export var damage: float = 10.0
@export var fire_rate: float = 2.0  # Shots per second

# Movement
@export var speed: float = 150.0
@export var acceleration: float = 300.0
@export var turn_speed: float = 3.0  # Radians per second

# AI behavior
enum AIType { PATROL, CHASE, GUARD, SWARM, SNIPER }
@export var ai_type: AIType = AIType.PATROL
@export var aggro_range: float = 400.0  # Detection distance
@export var attack_range: float = 300.0
@export var flee_health_percent: float = 0.0  # 0 = never flee

# Spawning
@export var spawn_weight: float = 1.0
@export var min_danger_level: int = 1  # Ship danger level required
@export var max_group_size: int = 3

# Rewards
@export var xp_value: int = 25
@export var credit_value: int = 50
@export var drop_table: String = "drone_loot"

# Visual
@export var sprite_path: String = "res://assets/sprites/enemies/patrol_drone.svg"
@export var scale: float = 1.0
@export var color_tint: Color = Color.WHITE

# Audio
@export var spawn_sound: String = "enemy_spawn"
@export var attack_sound: String = "laser_fire"
@export var death_sound: String = "explosion_small"
\`
      },
      
      achievement: {
        name: 'Achievement',
        icon: '🏆',
        description: 'Create a new achievement',
        content: \`# ==============================================================================
# ACHIEVEMENT DEFINITION
# ==============================================================================
# Add to achievement_manager.gd ACHIEVEMENTS dictionary

"achievement_id": {
    "name": "Achievement Name",
    "description": "How to unlock this achievement.",
    "icon": "🏆",  # Emoji or icon path
    "hidden": false,  # Hidden until unlocked?
    "category": "exploration",  # exploration, combat, collection, mastery
    
    # Unlock conditions (pick one or combine)
    "condition_type": "counter",  # counter, flag, multi
    "target_value": 10,  # For counter type
    "counter_id": "enemies_killed",  # What to count
    
    # OR for flag type:
    # "condition_type": "flag",
    # "flag_id": "beat_boss_1",
    
    # OR for multi-condition:
    # "condition_type": "multi",
    # "required_flags": ["flag_1", "flag_2"],
    
    # Rewards
    "reward_credits": 1000,
    "reward_item": null,  # Item ID or null
    "reward_unlock": null,  # Unlocks something (ship, skin, etc)
    
    # Progression
    "tier": 1,  # Bronze=1, Silver=2, Gold=3
    "xp_reward": 100,
    
    # Tracking (set automatically)
    "unlocked": false,
    "unlock_date": null,
    "progress": 0
},

# Example achievements:
"first_blood": {
    "name": "First Blood",
    "description": "Destroy your first enemy ship.",
    "icon": "⚔️",
    "category": "combat",
    "condition_type": "counter",
    "target_value": 1,
    "counter_id": "enemies_destroyed",
    "reward_credits": 100,
    "tier": 1
},

"hoarder": {
    "name": "Hoarder",
    "description": "Collect 100 items total.",
    "icon": "📦",
    "category": "collection",
    "condition_type": "counter",
    "target_value": 100,
    "counter_id": "items_collected",
    "reward_credits": 500,
    "tier": 2
}
\`
      },
      
      station: {
        name: 'Station Data',
        icon: '🛸',
        description: 'Define a space station type',
        content: \`# ==============================================================================
# STATION DATA RESOURCE
# ==============================================================================
# Save as .tres file in resources/stations/

[gd_resource type="Resource" script_class="StationData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/station_data.gd" id="1"]

[resource]
script = ExtResource("1")

# Station identity
station_id = "station_trading_hub"
station_name = "Trading Hub Alpha"
station_description = "A bustling commerce center on the frontier."

# Station type affects available services
# Types: TRADING, MILITARY, MINING, RESEARCH, PIRATE, ABANDONED
station_type = 0  # TRADING

# Services available
has_shop = true
has_repair = true
has_fuel = true
has_missions = true
has_black_market = false
has_storage = true

# Faction control
faction_id = 0  # CCG (Civilian)
reputation_required = 0  # Min reputation to dock

# Economy
price_modifier = 1.0  # 1.0 = normal prices
sell_modifier = 0.9   # 90% of base value when selling

# Visual
sprite_path = "res://assets/sprites/stations/trading_hub.svg"
background_scene = "res://scenes/background/station_interior.tscn"
ambient_track = "station_ambient"

# Ship spawning near station
allowed_ship_types = ["shuttle", "cargo", "fighter"]
ship_spawn_rate = 0.1  # Ships per second (average)

# Docking
docking_fee = 50
auto_repair_rate = 5.0  # HP per second while docked
\`
      }
    };
    
    // ===== FILE LOADING =====
    async function loadPlaygroundFiles() {
      const select = document.getElementById('playgroundFileSelect');
      if (!select) return;
      
      try {
        const scriptsResult = await apiCall('/api/tools/godot_list_scripts', 'POST', {});
        const scripts = scriptsResult.scripts || [];
        
        let html = '<option value="">Select a file to experiment with...</option>';
        
        // Group by folder
        const folders = {};
        scripts.forEach(function(s) {
          const parts = s.split('/');
          const file = parts.pop();
          const folder = parts.join('/') || 'root';
          if (!folders[folder]) folders[folder] = [];
          folders[folder].push({ file: file, path: s });
        });
        
        Object.keys(folders).sort().forEach(function(folder) {
          html += '<optgroup label="📁 ' + escapeHtml(folder) + '">';
          folders[folder].sort(function(a, b) { return a.file.localeCompare(b.file); }).forEach(function(f) {
            html += '<option value="' + escapeHtml(f.path) + '">📜 ' + escapeHtml(f.file) + '</option>';
          });
          html += '</optgroup>';
        });
        
        select.innerHTML = html;
      } catch (e) {
        console.error('Error loading playground files:', e);
      }
    }
    
    async function loadPlaygroundFile() {
      const select = document.getElementById('playgroundFileSelect');
      const filePath = select ? select.value : null;
      if (!filePath) return;
      
      playgroundCurrentFile = filePath;
      playgroundActiveTemplate = null;
      
      // Clear template button states
      document.querySelectorAll('.template-btn').forEach(function(b) { b.classList.remove('active'); });
      
      const editorContainer = document.getElementById('playgroundEditor');
      editorContainer.innerHTML = '<div style="text-align: center; padding: 2rem;"><div style="font-size: 2rem;">⏳</div>Loading file...</div>';
      
      // Update filename display
      var fileNameDisplay = document.getElementById('playgroundFileName');
      if (fileNameDisplay) fileNameDisplay.textContent = filePath;
      
      try {
        const result = await apiCall('/api/tools/wiki_analyze', 'POST', {
          filePath: filePath,
          includeCode: true,
          includeUsages: false
        });
        
        playgroundOriginalContent = result.content || '';
        playgroundModifiedContent = playgroundOriginalContent;
        playgroundExports = result.analysis ? (result.analysis.exports || []) : [];
        playgroundAnalysis = result.analysis;
        
        renderPlaygroundEditor();
        renderPlaygroundSidebar();
        setupSelectionTracking();
      } catch (e) {
        editorContainer.innerHTML = '<div style="text-align: center; padding: 2rem; color: var(--accent-error);"><div style="font-size: 2rem;">❌</div>Error: ' + escapeHtml(e.message) + '</div>';
      }
    }
    
    // ===== TEMPLATE LOADING =====
    function loadTemplate(templateId) {
      const template = PLAYGROUND_TEMPLATES[templateId];
      if (!template) return;
      
      // Update active state
      document.querySelectorAll('.template-btn').forEach(function(b) { b.classList.remove('active'); });
      event.target.classList.add('active');
      
      playgroundActiveTemplate = templateId;
      playgroundCurrentFile = 'template:' + templateId;
      playgroundOriginalContent = template.content;
      playgroundModifiedContent = template.content;
      
      // Parse exports from template
      playgroundExports = parseExportsFromContent(template.content);
      playgroundAnalysis = {
        overview: {
          className: template.name,
          extends: 'Template',
          description: [template.description]
        },
        exports: playgroundExports,
        constants: [],
        functions: []
      };
      
      // Update filename display
      var fileNameDisplay = document.getElementById('playgroundFileName');
      if (fileNameDisplay) fileNameDisplay.textContent = template.icon + ' ' + template.name;
      
      // Clear file selection
      var select = document.getElementById('playgroundFileSelect');
      if (select) select.value = '';
      
      renderPlaygroundEditor();
      renderPlaygroundSidebar();
      setupSelectionTracking();
      
      showToast('Loaded ' + template.name + ' template', 'success');
    }
    
    function parseExportsFromContent(content) {
      var exports = [];
      var lines = content.split(String.fromCharCode(10));
      
      lines.forEach(function(line, i) {
        var match = line.match(/@export[^v]*var[ ]+([a-zA-Z_][a-zA-Z0-9_]*)[ ]*:[ ]*([a-zA-Z0-9_\\[\\]]+)/);
        if (match) {
          var defaultMatch = line.match(/=[ ]*(.+?)(?:[ ]*#|$)/);
          exports.push({
            name: match[1],
            type: match[2],
            line: i + 1,
            default: defaultMatch ? defaultMatch[1].trim() : '',
            currentValue: defaultMatch ? defaultMatch[1].trim() : '',
            originalValue: defaultMatch ? defaultMatch[1].trim() : '',
            modified: false
          });
        }
      });
      
      return exports;
    }
    
    // ===== EDITOR RENDERING =====
    function renderPlaygroundEditor() {
      var editorContainer = document.getElementById('playgroundEditor');
      var lines = playgroundModifiedContent.split(String.fromCharCode(10));
      
      var html = '<div class="code-editor" id="codeEditorContent">';
      lines.forEach(function(line, i) {
        var lineNum = i + 1;
        var isExportLine = playgroundExports.some(function(e) { return e.line === lineNum; });
        var modifiedExport = playgroundExports.find(function(e) { return e.line === lineNum && e.modified; });
        
        html += '<div class="code-line' + (isExportLine ? ' export-line' : '') + (modifiedExport ? ' modified-line' : '') + '" data-line="' + lineNum + '">';
        html += '<span class="line-number">' + lineNum + '</span>';
        html += '<span class="line-content" data-line="' + lineNum + '">' + highlightGDScript(line) + '</span>';
        html += '</div>';
      });
      html += '</div>';
      
      editorContainer.innerHTML = html;
    }
    
    function highlightGDScript(line) {
      var escaped = escapeHtml(line);
      
      // Comments first
      escaped = escaped.replace(/(#.*)$/, '<span class="cmt">$1</span>');
      
      // Strings
      escaped = escaped.replace(/(&quot;[^&]*&quot;|'[^']*')/g, '<span class="str">$1</span>');
      
      // Keywords
      var keywords = ['func', 'var', 'const', 'class', 'extends', 'class_name', 'signal', 'export', '@export', '@export_range', '@export_enum', '@onready', '@tool', 'if', 'else', 'elif', 'for', 'while', 'match', 'return', 'pass', 'continue', 'break', 'in', 'not', 'and', 'or', 'true', 'false', 'null', 'self', 'super', 'await', 'static', 'enum', 'void', 'int', 'float', 'bool', 'String', 'Array', 'Dictionary', 'Vector2', 'Vector3', 'Color', 'Resource', 'Node'];
      keywords.forEach(function(kw) {
        var pattern = new RegExp('(^|[^a-zA-Z0-9_])(' + kw + ')([^a-zA-Z0-9_]|$)', 'g');
        escaped = escaped.replace(pattern, '$1<span class="kw">$2</span>$3');
      });
      
      // Numbers
      escaped = escaped.replace(/([^a-zA-Z0-9_])([0-9]+\\.?[0-9]*)/g, '$1<span class="num">$2</span>');
      
      // Function calls
      escaped = escaped.replace(/([a-zA-Z_][a-zA-Z0-9_]*)[(]/g, '<span class="fn">$1</span>(');
      
      return escaped;
    }
    
    // ===== SELECTION TRACKING =====
    function setupSelectionTracking() {
      var editor = document.getElementById('codeEditorContent');
      if (!editor) return;
      
      editor.addEventListener('mouseup', handleSelectionChange);
      editor.addEventListener('keyup', handleSelectionChange);
    }
    
    function handleSelectionChange() {
      var selection = window.getSelection();
      var selectedText = selection.toString().trim();
      
      if (selectedText.length > 0) {
        playgroundSelection.text = selectedText;
        
        // Find line numbers
        var anchorLine = getLineFromNode(selection.anchorNode);
        var focusLine = getLineFromNode(selection.focusNode);
        playgroundSelection.start = Math.min(anchorLine, focusLine);
        playgroundSelection.end = Math.max(anchorLine, focusLine);
        
        // Update line info
        var lineInfo = document.getElementById('playgroundLineInfo');
        if (lineInfo) {
          if (playgroundSelection.start === playgroundSelection.end) {
            lineInfo.textContent = 'Line ' + playgroundSelection.start + ' selected';
          } else {
            lineInfo.textContent = 'Lines ' + playgroundSelection.start + '-' + playgroundSelection.end + ' selected';
          }
        }
        
        updateContextPanel(selectedText);
      } else {
        playgroundSelection = { start: null, end: null, text: '' };
        var lineInfo = document.getElementById('playgroundLineInfo');
        if (lineInfo) lineInfo.textContent = 'Select text for context';
        clearContextPanel();
      }
    }
    
    function getLineFromNode(node) {
      if (!node) return 1;
      var el = node.nodeType === 3 ? node.parentElement : node;
      while (el && !el.classList.contains('code-line')) {
        el = el.parentElement;
      }
      return el ? parseInt(el.getAttribute('data-line')) || 1 : 1;
    }
    
    // ===== CONTEXT PANEL =====
    function updateContextPanel(selectedText) {
      var sidebar = document.getElementById('playgroundSidebar');
      var contextPanel = document.getElementById('selectionContext');
      
      if (!contextPanel) {
        var panel = document.createElement('div');
        panel.id = 'selectionContext';
        panel.className = 'selection-context';
        sidebar.insertBefore(panel, sidebar.firstChild);
        contextPanel = panel;
      }
      
      var analysis = analyzeSelectionEnhanced(selectedText);
      
      var html = '<div class="selection-context-header">';
      html += '<span class="selection-context-title">✨ Context Analysis</span>';
      if (analysis.category) {
        html += '<span class="selection-context-badge badge-' + analysis.category + '">' + analysis.categoryLabel + '</span>';
      }
      html += '</div>';
      
      html += '<div class="selection-context-content">';
      
      // Selected text preview
      html += '<div class="selection-highlight">';
      html += '<code>' + escapeHtml(selectedText.substring(0, 150)) + (selectedText.length > 150 ? '...' : '') + '</code>';
      html += '</div>';
      
      // Pattern recognition section
      if (analysis.patterns.length > 0) {
        html += '<div class="context-section">';
        html += '<div class="context-section-title">🎯 Detected Patterns</div>';
        html += '<div class="context-tags">';
        analysis.patterns.forEach(function(p) {
          html += '<span class="context-tag ' + p.tagClass + '">' + p.icon + ' ' + p.label + '</span>';
        });
        html += '</div>';
        html += '</div>';
      }
      
      // Variables with smart docs
      if (analysis.variables.length > 0) {
        html += '<div class="context-section">';
        html += '<div class="context-section-title">📝 Variables</div>';
        analysis.variables.forEach(function(v) {
          var doc = VARIABLE_DOCS[v.name] || VARIABLE_DOCS[v.name.toLowerCase()];
          html += '<div class="context-var">';
          html += '<div class="context-var-header">';
          html += '<span class="context-var-name">' + escapeHtml(v.name) + '</span>';
          if (v.type) html += '<span class="context-var-type">' + escapeHtml(v.type) + '</span>';
          if (v.scope) html += '<span class="context-var-scope">' + v.scope + '</span>';
          html += '</div>';
          if (doc) {
            html += '<div class="context-var-desc">' + doc.description + '</div>';
            if (doc.effect) {
              html += '<div class="context-var-effect">⚡ ' + doc.effect + '</div>';
            }
          }
          html += '</div>';
        });
        html += '</div>';
      }
      
      // Functions detected
      if (analysis.functions.length > 0) {
        html += '<div class="context-section">';
        html += '<div class="context-section-title">⚙️ Functions</div>';
        html += '<div class="context-func-list">';
        analysis.functions.forEach(function(f) {
          html += '<div class="context-func">';
          html += '<span class="context-func-name">' + escapeHtml(f.name) + '</span>';
          if (f.builtin) {
            html += '<a href="https://docs.godotengine.org/en/stable/classes/class_' + (f.class || 'node').toLowerCase() + '.html#class-' + (f.class || 'node').toLowerCase() + '-method-' + f.name.toLowerCase() + '" target="_blank" class="context-func-link">📖</a>';
          }
          html += '</div>';
        });
        html += '</div>';
        html += '</div>';
      }
      
      // Signals detected
      if (analysis.signals.length > 0) {
        html += '<div class="context-section">';
        html += '<div class="context-section-title">📡 Signals</div>';
        analysis.signals.forEach(function(s) {
          html += '<div class="context-signal">';
          html += '<span class="context-signal-icon">⚡</span>';
          html += '<span class="context-signal-name">' + escapeHtml(s) + '</span>';
          html += '</div>';
        });
        html += '</div>';
      }
      
      // Godot types with links
      if (analysis.types.length > 0) {
        html += '<div class="context-section">';
        html += '<div class="context-section-title">🔷 Godot Types</div>';
        html += '<div class="context-type-list">';
        analysis.types.forEach(function(t) {
          html += '<a href="https://docs.godotengine.org/en/stable/classes/class_' + t.toLowerCase() + '.html" target="_blank" class="context-type-link">' + t + '</a>';
        });
        html += '</div>';
        html += '</div>';
      }
      
      // Quick actions
      html += '<div class="context-actions">';
      html += '<button class="context-action-btn" onclick="copyToClipboard(playgroundSelection.text)">📋 Copy</button>';
      html += '<button class="context-action-btn" onclick="searchInProject(playgroundSelection.text)">🔍 Search</button>';
      if (analysis.types.length > 0) {
        html += '<button class="context-action-btn" onclick="window.open(\\'https://docs.godotengine.org/en/stable/classes/class_' + analysis.types[0].toLowerCase() + '.html\\', \\'_blank\\')">📚 Docs</button>';
      }
      html += '</div>';
      
      html += '</div>';
      contextPanel.innerHTML = html;
    }
    
    function clearContextPanel() {
      var contextPanel = document.getElementById('selectionContext');
      if (contextPanel) {
        contextPanel.remove();
      }
    }
    
    function analyzeSelectionEnhanced(text) {
      var result = {
        variables: [],
        types: [],
        keywords: [],
        functions: [],
        signals: [],
        patterns: [],
        category: null,
        categoryLabel: ''
      };
      
      // Determine category
      if (text.match(/func[ ]+_?[a-zA-Z]/)) {
        result.category = 'function';
        result.categoryLabel = 'Function';
      } else if (text.match(/signal[ ]+[a-zA-Z]/)) {
        result.category = 'signal';
        result.categoryLabel = 'Signal';
      } else if (text.match(/@export/)) {
        result.category = 'export';
        result.categoryLabel = 'Export';
      } else if (text.match(/class_name[ ]+[A-Z]/)) {
        result.category = 'class';
        result.categoryLabel = 'Class';
      } else if (text.match(/preload|load/)) {
        result.category = 'resource';
        result.categoryLabel = 'Resource';
      }
      
      // Detect patterns
      if (text.match(/@export/)) {
        result.patterns.push({ icon: '📤', label: 'Export Variable', tagClass: 'tag-keyword' });
      }
      if (text.match(/@onready/)) {
        result.patterns.push({ icon: '⏰', label: 'Onready', tagClass: 'tag-keyword' });
      }
      if (text.match(/@tool/)) {
        result.patterns.push({ icon: '🔧', label: 'Tool Script', tagClass: 'tag-keyword' });
      }
      if (text.match(/func[ ]+_ready/)) {
        result.patterns.push({ icon: '🎬', label: 'Ready Callback', tagClass: 'tag-function' });
      }
      if (text.match(/func[ ]+_process/)) {
        result.patterns.push({ icon: '🔄', label: 'Process Loop', tagClass: 'tag-function' });
      }
      if (text.match(/func[ ]+_physics_process/)) {
        result.patterns.push({ icon: '⚡', label: 'Physics Loop', tagClass: 'tag-function' });
      }
      if (text.match(/func[ ]+_input/)) {
        result.patterns.push({ icon: '🎮', label: 'Input Handler', tagClass: 'tag-function' });
      }
      if (text.match(/emit_signal|[.]emit/)) {
        result.patterns.push({ icon: '📡', label: 'Signal Emission', tagClass: 'tag-signal' });
      }
      if (text.match(/[.]connect/)) {
        result.patterns.push({ icon: '🔗', label: 'Signal Connection', tagClass: 'tag-signal' });
      }
      if (text.match(/preload[(]/)) {
        result.patterns.push({ icon: '📦', label: 'Preload Resource', tagClass: 'tag-type' });
      }
      if (text.match(/await/)) {
        result.patterns.push({ icon: '⏳', label: 'Async/Await', tagClass: 'tag-keyword' });
      }
      if (text.match(/queue_free|free/)) {
        result.patterns.push({ icon: '🗑️', label: 'Node Cleanup', tagClass: 'tag-function' });
      }
      if (text.match(/instantiate/)) {
        result.patterns.push({ icon: '✨', label: 'Scene Instance', tagClass: 'tag-function' });
      }
      
      // Find variables with scope detection
      var varMatches = text.match(/(?:var|const)[ ]+([a-zA-Z_][a-zA-Z0-9_]*)(?:[ ]*:[ ]*([a-zA-Z0-9_\\[\\]]+))?/g);
      if (varMatches) {
        varMatches.forEach(function(m) {
          var parts = m.match(/(?:var|const)[ ]+([a-zA-Z_][a-zA-Z0-9_]*)(?:[ ]*:[ ]*([a-zA-Z0-9_\\[\\]]+))?/);
          if (parts) {
            var scope = 'local';
            if (parts[1].startsWith('_')) scope = 'private';
            if (m.includes('const')) scope = 'constant';
            result.variables.push({ name: parts[1], type: parts[2] || 'Variant', scope: scope });
          }
        });
      }
      
      // Find Godot types
      var godotTypes = ['Vector2', 'Vector3', 'Vector2i', 'Vector3i', 'Color', 'Array', 'Dictionary', 'String', 'StringName', 'Resource', 'Node', 'Node2D', 'Node3D', 'Control', 'Area2D', 'Area3D', 'CharacterBody2D', 'CharacterBody3D', 'RigidBody2D', 'RigidBody3D', 'StaticBody2D', 'Sprite2D', 'Sprite3D', 'AnimatedSprite2D', 'AudioStreamPlayer', 'AudioStreamPlayer2D', 'Timer', 'PackedScene', 'Tween', 'Camera2D', 'Camera3D', 'CanvasLayer', 'Label', 'Button', 'TextureRect', 'Panel', 'VBoxContainer', 'HBoxContainer', 'GridContainer', 'MarginContainer', 'LineEdit', 'TextEdit', 'ProgressBar', 'Slider', 'SpinBox', 'ColorRect', 'RichTextLabel', 'Signal', 'Callable'];
      godotTypes.forEach(function(t) {
        if (text.includes(t) && result.types.indexOf(t) === -1) {
          result.types.push(t);
        }
      });
      
      // Find signal definitions
      var signalMatches = text.match(/signal[ ]+([a-zA-Z_][a-zA-Z0-9_]*)/g);
      if (signalMatches) {
        signalMatches.forEach(function(m) {
          var name = m.replace('signal ', '').trim();
          if (result.signals.indexOf(name) === -1) {
            result.signals.push(name);
          }
        });
      }
      
      // Also detect signal emissions
      var emitMatches = text.match(/emit_signal[(]["']([a-zA-Z_][a-zA-Z0-9_]*)["']/g);
      if (emitMatches) {
        emitMatches.forEach(function(m) {
          var name = m.match(/["']([a-zA-Z_][a-zA-Z0-9_]*)["']/);
          if (name && result.signals.indexOf(name[1]) === -1) {
            result.signals.push(name[1]);
          }
        });
      }
      
      // Find function calls with builtin detection
      var builtinFuncs = ['print', 'push_error', 'push_warning', 'get_node', 'get_parent', 'get_tree', 'queue_free', 'add_child', 'remove_child', 'move_child', 'get_child', 'get_children', 'is_instance_of', 'is_instance_valid', 'clamp', 'lerp', 'abs', 'sign', 'floor', 'ceil', 'round', 'min', 'max', 'pow', 'sqrt', 'sin', 'cos', 'tan', 'atan2', 'deg_to_rad', 'rad_to_deg', 'randf', 'randi', 'randf_range', 'randi_range', 'randomize', 'str', 'int', 'float', 'bool', 'range', 'len', 'typeof', 'preload', 'load', 'instantiate', 'duplicate', 'emit_signal', 'connect', 'disconnect', 'call', 'call_deferred', 'set_deferred', 'is_inside_tree', 'set_process', 'set_physics_process', 'await', 'create_tween'];
      
      var funcMatches = text.match(/([a-zA-Z_][a-zA-Z0-9_]*)[(]/g);
      if (funcMatches) {
        funcMatches.forEach(function(m) {
          var name = m.replace('(', '');
          var existing = result.functions.find(function(f) { return f.name === name; });
          if (!existing) {
            var isBuiltin = builtinFuncs.indexOf(name) !== -1;
            result.functions.push({ 
              name: name, 
              builtin: isBuiltin,
              class: isBuiltin ? 'Node' : null
            });
          }
        });
      }
      
      return result;
    }
    
    function searchInProject(text) {
      // Switch to wiki tab and search
      showToast('Search feature coming soon!', 'info');
    }
    
    // ===== SIDEBAR RENDERING =====
    function renderPlaygroundSidebar() {
      var sidebar = document.getElementById('playgroundSidebar');
      if (!sidebar) return;
      
      var html = '';
      
      // Item Preview (shows when item template is active) - STICKY
      if (playgroundActiveTemplate === 'item') {
        html += '<div class="preview-sticky">';
        html += renderItemPreview();
        html += '</div>';
      }
      
      // Scrollable content wrapper
      html += '<div class="sidebar-scrollable">';
      
      // Sidebar tabs
      html += '<div class="sidebar-tabs">';
      html += '<div class="sidebar-tab' + (playgroundSidebarTab === 'variables' ? ' active' : '') + '" onclick="switchPlaygroundTab(\\'variables\\')">📝 Variables</div>';
      html += '<div class="sidebar-tab' + (playgroundSidebarTab === 'info' ? ' active' : '') + '" onclick="switchPlaygroundTab(\\'info\\')">ℹ️ Info</div>';
      html += '<div class="sidebar-tab' + (playgroundSidebarTab === 'changes' ? ' active' : '') + '" onclick="switchPlaygroundTab(\\'changes\\')">📋 Changes</div>';
      html += '</div>';
      
      // Variables Tab
      html += '<div class="sidebar-tab-content' + (playgroundSidebarTab === 'variables' ? ' active' : '') + '" id="tabVariables">';
      
      if (playgroundExports.length > 0) {
        html += '<p style="font-size: 0.75rem; color: var(--text-muted); margin-bottom: 1rem;">Edit values below. Click variable names for documentation.</p>';
        
        playgroundExports.forEach(function(exp, i) {
          var doc = VARIABLE_DOCS[exp.name] || VARIABLE_DOCS[exp.name.toLowerCase()];
          
          html += '<div class="var-doc">';
          html += '<div class="var-doc-header">';
          html += '<span class="var-doc-name" style="cursor: pointer;" onclick="highlightLine(' + exp.line + ')">' + escapeHtml(exp.name) + '</span>';
          html += '<span class="var-doc-type">' + escapeHtml(exp.type) + '</span>';
          html += '</div>';
          
          if (doc) {
            html += '<div class="var-doc-desc">' + doc.description + '</div>';
            if (doc.effect) {
              html += '<div class="var-doc-effect">⚡ ' + doc.effect + '</div>';
            }
            if (doc.range) {
              html += '<div class="var-doc-range">📊 Range: ' + doc.range + '</div>';
            }
            if (doc.links && doc.links.length > 0) {
              html += '<div class="var-doc-links">';
              doc.links.forEach(function(link) {
                html += '<a href="' + link.url + '" target="_blank" class="var-doc-link">📖 ' + link.label + '</a>';
              });
              html += '</div>';
            }
          }
          
          // Input control
          html += '<div class="var-doc-input">';
          html += renderPlaygroundInput(exp, i);
          html += '</div>';
          
          html += '</div>';
        });
      } else {
        html += '<div style="text-align: center; padding: 2rem; color: var(--text-muted);">';
        html += '<div style="font-size: 2rem; margin-bottom: 0.5rem;">📭</div>';
        html += '<p>No @export variables found</p>';
        html += '<p style="font-size: 0.8rem;">Load a file with exported variables or use a template.</p>';
        html += '</div>';
      }
      
      html += '</div>';
      
      html += '</div>'; // Close variables tab
      
      // Info Tab
      html += '<div class="sidebar-tab-content' + (playgroundSidebarTab === 'info' ? ' active' : '') + '" id="tabInfo">';
      
      if (playgroundAnalysis) {
        // File info
        html += '<div class="playground-panel">';
        html += '<div class="playground-panel-header" onclick="togglePlaygroundPanel(this)">';
        html += '<span>📄 File Overview</span><span class="toggle-icon">▼</span>';
        html += '</div>';
        html += '<div class="playground-panel-content">';
        if (playgroundAnalysis.overview) {
          if (playgroundAnalysis.overview.className) {
            html += '<div class="info-row"><span>Class:</span><span>' + escapeHtml(playgroundAnalysis.overview.className) + '</span></div>';
          }
          if (playgroundAnalysis.overview.extends) {
            html += '<div class="info-row"><span>Extends:</span><a href="https://docs.godotengine.org/en/stable/classes/class_' + playgroundAnalysis.overview.extends.toLowerCase() + '.html" target="_blank" class="var-doc-link">' + escapeHtml(playgroundAnalysis.overview.extends) + '</a></div>';
          }
        }
        html += '<div class="info-row"><span>Exports:</span><span>' + playgroundExports.length + '</span></div>';
        if (playgroundAnalysis.constants) {
          html += '<div class="info-row"><span>Constants:</span><span>' + playgroundAnalysis.constants.length + '</span></div>';
        }
        if (playgroundAnalysis.functions) {
          html += '<div class="info-row"><span>Functions:</span><span>' + playgroundAnalysis.functions.length + '</span></div>';
        }
        html += '</div></div>';
        
        // Constants
        if (playgroundAnalysis.constants && playgroundAnalysis.constants.length > 0) {
          html += '<div class="playground-panel">';
          html += '<div class="playground-panel-header" onclick="togglePlaygroundPanel(this)">';
          html += '<span>🔒 Constants</span><span class="toggle-icon">▼</span>';
          html += '</div>';
          html += '<div class="playground-panel-content">';
          playgroundAnalysis.constants.slice(0, 10).forEach(function(c) {
            html += '<div class="info-row" style="cursor: pointer;" onclick="highlightLine(' + c.line + ')"><span>' + escapeHtml(c.name) + '</span><code>' + escapeHtml(String(c.value).substring(0, 30)) + '</code></div>';
          });
          if (playgroundAnalysis.constants.length > 10) {
            html += '<div style="font-size: 0.75rem; color: var(--text-muted); margin-top: 0.5rem;">+ ' + (playgroundAnalysis.constants.length - 10) + ' more...</div>';
          }
          html += '</div></div>';
        }
        
        // Functions
        if (playgroundAnalysis.functions && playgroundAnalysis.functions.length > 0) {
          html += '<div class="playground-panel collapsed">';
          html += '<div class="playground-panel-header" onclick="togglePlaygroundPanel(this)">';
          html += '<span>⚙️ Functions</span><span class="toggle-icon">▼</span>';
          html += '</div>';
          html += '<div class="playground-panel-content">';
          playgroundAnalysis.functions.slice(0, 15).forEach(function(f) {
            html += '<div class="info-row" style="cursor: pointer;" onclick="highlightLine(' + f.line + ')"><span>' + escapeHtml(f.name) + '()</span><span style="font-size: 0.7rem; color: var(--text-muted);">' + escapeHtml(f.category || '') + '</span></div>';
          });
          if (playgroundAnalysis.functions.length > 15) {
            html += '<div style="font-size: 0.75rem; color: var(--text-muted); margin-top: 0.5rem;">+ ' + (playgroundAnalysis.functions.length - 15) + ' more...</div>';
          }
          html += '</div></div>';
        }
      }
      
      html += '</div>';
      
      // Changes Tab
      html += '<div class="sidebar-tab-content' + (playgroundSidebarTab === 'changes' ? ' active' : '') + '" id="tabChanges">';
      html += '<div id="playgroundChanges">';
      html += renderChangesContent();
      html += '</div>';
      
      // Export section
      html += '<div style="margin-top: 1rem; padding-top: 1rem; border-top: 1px solid var(--border-color);">';
      html += '<button class="btn btn-primary" style="width: 100%;" onclick="exportPlaygroundTodos()">📤 Export Changes as TODOs</button>';
      html += '<button class="btn" style="width: 100%; margin-top: 0.5rem;" onclick="downloadModifiedFile()">💾 Download Modified File</button>';
      html += '</div>';
      html += '</div>';
      html += '</div>'; // Close sidebar-scrollable
      
      sidebar.innerHTML = html;
    }
    
    function switchPlaygroundTab(tab) {
      playgroundSidebarTab = tab;
      renderPlaygroundSidebar();
    }
    
    function renderChangesContent() {
      var changes = playgroundExports.filter(function(e) { return e.modified; });
      
      if (changes.length === 0) {
        return '<div style="text-align: center; padding: 1.5rem; color: var(--text-muted);"><div style="font-size: 1.5rem; margin-bottom: 0.5rem;">✨</div><p>No changes yet</p><p style="font-size: 0.8rem;">Edit variables to see changes here.</p></div>';
      }
      
      var html = '<div style="margin-bottom: 0.75rem; font-size: 0.85rem;"><strong>' + changes.length + ' change(s)</strong></div>';
      html += '<div class="changes-list">';
      changes.forEach(function(c) {
        html += '<div class="change-item" style="cursor: pointer;" onclick="highlightLine(' + c.line + ')">';
        html += '<div style="flex: 1;">';
        html += '<div class="change-name">' + escapeHtml(c.name) + '</div>';
        html += '<div style="font-size: 0.75rem; color: var(--text-muted);">';
        html += '<span style="text-decoration: line-through;">' + escapeHtml(String(c.originalValue).substring(0, 20)) + '</span>';
        html += ' → ';
        html += '<span style="color: var(--accent-success);">' + escapeHtml(String(c.currentValue).substring(0, 20)) + '</span>';
        html += '</div>';
        html += '</div>';
        html += '<button class="btn" style="padding: 0.25rem 0.5rem; font-size: 0.7rem;" onclick="event.stopPropagation(); revertChange(' + playgroundExports.indexOf(c) + ')">↩️</button>';
        html += '</div>';
      });
      html += '</div>';
      
      return html;
    }
    
    function highlightLine(lineNum) {
      // Remove previous highlights
      document.querySelectorAll('.code-line.highlighted').forEach(function(el) {
        el.classList.remove('highlighted');
      });
      
      // Add highlight to target line
      var line = document.querySelector('.code-line[data-line="' + lineNum + '"]');
      if (line) {
        line.classList.add('highlighted');
        line.scrollIntoView({ behavior: 'smooth', block: 'center' });
        
        // Flash effect
        line.style.background = 'rgba(147, 51, 234, 0.4)';
        setTimeout(function() {
          line.style.background = '';
        }, 1000);
      }
    }
    
    function revertChange(index) {
      var exp = playgroundExports[index];
      if (!exp) return;
      
      exp.currentValue = exp.originalValue;
      exp.modified = false;
      delete exp.vectorValues;
      
      // Update the code
      var lines = playgroundModifiedContent.split(String.fromCharCode(10));
      var lineIndex = exp.line - 1;
      if (lines[lineIndex]) {
        var varPattern = new RegExp('((?:@export[^v]*)?var[ ]+' + exp.name + '[ ]*[=:][ ]*)([^#]+)');
        lines[lineIndex] = lines[lineIndex].replace(varPattern, '$1' + exp.originalValue + ' ');
        playgroundModifiedContent = lines.join(String.fromCharCode(10));
      }
      
      renderPlaygroundEditor();
      renderPlaygroundSidebar();
      showToast('Reverted ' + exp.name, 'info');
    }
    
    // ===== INPUT RENDERING =====
    function renderPlaygroundInput(exp, index) {
      var value = exp.currentValue || exp.default || '';
      var type = (exp.type || '').toLowerCase();
      var name = (exp.name || '').toLowerCase();
      
      // Boolean
      if (type === 'bool' || type === 'boolean') {
        var isTrue = value === 'true' || value === true;
        return '<div class="rarity-select" style="grid-template-columns: 1fr 1fr;">' +
          '<div class="rarity-option' + (isTrue ? ' selected' : '') + '" style="color: var(--accent-success);" onclick="updatePlaygroundValue(' + index + ', \\'true\\')">✓ true</div>' +
          '<div class="rarity-option' + (!isTrue ? ' selected' : '') + '" style="color: var(--accent-error);" onclick="updatePlaygroundValue(' + index + ', \\'false\\')">✗ false</div>' +
          '</div>';
      }
      
      // Category dropdown (special case for item categories)
      if (name === 'category' && type === 'int') {
        var catVal = parseInt(value) || 0;
        var categories = [
          { value: 0, label: '🔩 Scrap', color: '#6b7280' },
          { value: 1, label: '⚙️ Component', color: '#10b981' },
          { value: 2, label: '💎 Valuable', color: '#3b82f6' },
          { value: 3, label: '✨ Epic', color: '#8b5cf6' },
          { value: 4, label: '👑 Legendary', color: '#f59e0b' }
        ];
        var html = '<select class="var-dropdown" onchange="updatePlaygroundValue(' + index + ', this.value)">';
        categories.forEach(function(cat) {
          html += '<option value="' + cat.value + '"' + (catVal === cat.value ? ' selected' : '') + '>' + cat.label + '</option>';
        });
        html += '</select>';
        return html;
      }
      
      // Rarity selector (special case)
      if (name.includes('rarity') && type === 'int') {
        var rarityVal = parseInt(value) || 0;
        return '<div class="rarity-select">' +
          '<div class="rarity-option rarity-common' + (rarityVal === 0 ? ' selected' : '') + '" onclick="updatePlaygroundValue(' + index + ', \\'0\\')">Common</div>' +
          '<div class="rarity-option rarity-uncommon' + (rarityVal === 1 ? ' selected' : '') + '" onclick="updatePlaygroundValue(' + index + ', \\'1\\')">Uncommon</div>' +
          '<div class="rarity-option rarity-rare' + (rarityVal === 2 ? ' selected' : '') + '" onclick="updatePlaygroundValue(' + index + ', \\'2\\')">Rare</div>' +
          '<div class="rarity-option rarity-epic' + (rarityVal === 3 ? ' selected' : '') + '" onclick="updatePlaygroundValue(' + index + ', \\'3\\')">Epic</div>' +
          '<div class="rarity-option rarity-legendary' + (rarityVal === 4 ? ' selected' : '') + '" onclick="updatePlaygroundValue(' + index + ', \\'4\\')">Legend</div>' +
          '</div>';
      }
      
      // Width/Height for inventory (constrained 1-4 grid cells)
      if ((name === 'width' || name === 'height') && type === 'int') {
        var dimVal = parseInt(value) || 1;
        dimVal = Math.max(1, Math.min(4, dimVal));
        return '<div class="dimension-select">' +
          '<div class="dim-option' + (dimVal === 1 ? ' selected' : '') + '" onclick="updatePlaygroundValue(' + index + ', \\'1\\')">1</div>' +
          '<div class="dim-option' + (dimVal === 2 ? ' selected' : '') + '" onclick="updatePlaygroundValue(' + index + ', \\'2\\')">2</div>' +
          '<div class="dim-option' + (dimVal === 3 ? ' selected' : '') + '" onclick="updatePlaygroundValue(' + index + ', \\'3\\')">3</div>' +
          '<div class="dim-option' + (dimVal === 4 ? ' selected' : '') + '" onclick="updatePlaygroundValue(' + index + ', \\'4\\')">4</div>' +
          '</div>';
      }
      
      // Faction affinity dropdown
      if (name.includes('faction_affinity') && type === 'int') {
        var factionVal = parseInt(value);
        if (isNaN(factionVal)) factionVal = -1;
        var factions = [
          { value: -1, label: '🌐 Universal' },
          { value: 0, label: '🏛️ Federation' },
          { value: 1, label: '🏴‍☠️ Syndicate' },
          { value: 2, label: '💼 Merchants' },
          { value: 3, label: '🔬 Scientists' }
        ];
        var html = '<select class="var-dropdown" onchange="updatePlaygroundValue(' + index + ', this.value)">';
        factions.forEach(function(f) {
          html += '<option value="' + f.value + '"' + (factionVal === f.value ? ' selected' : '') + '>' + f.label + '</option>';
        });
        html += '</select>';
        return html;
      }
      
      // Stack size (common preset buttons)
      if (name === 'stack_size' && type === 'int') {
        var stackVal = parseInt(value) || 1;
        return '<div class="stack-select">' +
          '<div class="stack-option' + (stackVal === 1 ? ' selected' : '') + '" onclick="updatePlaygroundValue(' + index + ', \\'1\\')">1</div>' +
          '<div class="stack-option' + (stackVal === 5 ? ' selected' : '') + '" onclick="updatePlaygroundValue(' + index + ', \\'5\\')">5</div>' +
          '<div class="stack-option' + (stackVal === 10 ? ' selected' : '') + '" onclick="updatePlaygroundValue(' + index + ', \\'10\\')">10</div>' +
          '<div class="stack-option' + (stackVal === 20 ? ' selected' : '') + '" onclick="updatePlaygroundValue(' + index + ', \\'20\\')">20</div>' +
          '<div class="stack-option' + (stackVal === 50 ? ' selected' : '') + '" onclick="updatePlaygroundValue(' + index + ', \\'50\\')">50</div>' +
          '<div class="stack-option' + (stackVal === 99 ? ' selected' : '') + '" onclick="updatePlaygroundValue(' + index + ', \\'99\\')">99</div>' +
          '</div>';
      }
      
      // Integer with slider (default)
      if (type === 'int') {
        var intVal = parseInt(value) || 0;
        var min = 0;
        var max = 100;
        if (name.includes('level') || name.includes('tier')) { min = 0; max = 10; }
        if (name.includes('container')) { min = 1; max = 20; }
        if (name.includes('health') || name.includes('damage')) { min = 0; max = 1000; }
        if (name.includes('value') || name.includes('price')) { min = 0; max = 10000; }
        
        return '<div class="var-slider-container">' +
          '<input type="range" class="var-slider" min="' + min + '" max="' + max + '" value="' + intVal + '" oninput="updatePlaygroundSlider(' + index + ', this.value)">' +
          '<input type="number" class="var-slider-value" value="' + intVal + '" min="' + min + '" style="width: 70px;" onchange="updatePlaygroundValue(' + index + ', this.value)">' +
          '</div>';
      }
      
      // Float with slider
      if (type === 'float') {
        var floatVal = parseFloat(value) || 0;
        var max = 10;
        if (name.includes('time') || name.includes('cooldown') || name.includes('duration')) max = 120;
        if (name.includes('weight')) max = 100;
        if (name.includes('speed')) max = 1000;
        if (name.includes('modifier') || name.includes('bonus') || name.includes('spawn_weight')) max = 5;
        
        return '<div class="var-slider-container">' +
          '<input type="range" class="var-slider" min="0" max="' + max + '" step="0.1" value="' + floatVal + '" oninput="updatePlaygroundSlider(' + index + ', this.value)">' +
          '<input type="number" class="var-slider-value" value="' + floatVal + '" step="0.1" style="width: 70px;" onchange="updatePlaygroundValue(' + index + ', this.value)">' +
          '</div>';
      }
      
      // Color
      if (type === 'color') {
        var colorMatch = value.match(/Color[(]([0-9.]+),[ ]*([0-9.]+),[ ]*([0-9.]+)/);
        var hex = '#888888';
        if (colorMatch) {
          var r = Math.round(parseFloat(colorMatch[1]) * 255);
          var g = Math.round(parseFloat(colorMatch[2]) * 255);
          var b = Math.round(parseFloat(colorMatch[3]) * 255);
          hex = '#' + r.toString(16).padStart(2, '0') + g.toString(16).padStart(2, '0') + b.toString(16).padStart(2, '0');
        }
        return '<div class="color-preview">' +
          '<input type="color" value="' + hex + '" onchange="updatePlaygroundColor(' + index + ', this.value)">' +
          '<span style="font-family: monospace; font-size: 0.8rem;">' + escapeHtml(value) + '</span>' +
          '</div>';
      }
      
      // Vector2
      if (type.includes('vector2')) {
        var vecMatch = value.match(/Vector2[(]([^,]+),[ ]*([^)]+)[)]/);
        var x = vecMatch ? vecMatch[1].trim() : '0';
        var y = vecMatch ? vecMatch[2].trim() : '0';
        return '<div class="vector2-input">' +
          '<label>X</label><input type="number" value="' + x + '" step="1" onchange="updatePlaygroundVector(' + index + ', \\'x\\', this.value)">' +
          '<label>Y</label><input type="number" value="' + y + '" step="1" onchange="updatePlaygroundVector(' + index + ', \\'y\\', this.value)">' +
          '</div>';
      }
      
      // Array
      if (type.includes('array')) {
        return '<textarea style="width: 100%; min-height: 60px; font-family: monospace; font-size: 0.8rem; background: var(--bg-secondary); border: 1px solid var(--border-color); border-radius: 4px; padding: 0.5rem; color: var(--text-primary); resize: vertical;" onchange="updatePlaygroundValue(' + index + ', this.value)">' + escapeHtml(value) + '</textarea>';
      }
      
      // Default text input
      return '<input type="text" value="' + escapeHtml(value) + '" onchange="updatePlaygroundValue(' + index + ', this.value)" style="width: 100%; padding: 0.5rem; background: var(--bg-secondary); border: 1px solid var(--border-color); border-radius: 4px; color: var(--text-primary); font-family: monospace;">';
    }
    
    function updatePlaygroundSlider(index, value) {
      updatePlaygroundValue(index, value);
    }
    
    function updatePlaygroundColor(index, hexValue) {
      // Convert hex to Godot Color
      var r = parseInt(hexValue.substr(1, 2), 16) / 255;
      var g = parseInt(hexValue.substr(3, 2), 16) / 255;
      var b = parseInt(hexValue.substr(5, 2), 16) / 255;
      var godotColor = 'Color(' + r.toFixed(2) + ', ' + g.toFixed(2) + ', ' + b.toFixed(2) + ')';
      updatePlaygroundValue(index, godotColor);
    }
    
    // ===== ITEM PREVIEW RENDERING =====
    var previewMode = 'grid';
    var previewIconScale = 1.0;
    var previewIconOffsetX = 0;
    var previewIconOffsetY = 0;
    
    function renderItemPreview() {
      // Get current values from exports (match template variable names)
      var categoryNames = ['scrap', 'component', 'valuable', 'epic', 'legendary'];
      var rarityNames = ['common', 'uncommon', 'rare', 'epic', 'legendary'];
      
      var catVal = getExportValue('category');
      var rarVal = getExportValue('rarity');
      var widthVal = parseInt(getExportValue('width')) || 1;
      var heightVal = parseInt(getExportValue('height')) || 1;
      
      // Clamp dimensions
      widthVal = Math.max(1, Math.min(4, widthVal));
      heightVal = Math.max(1, Math.min(4, heightVal));
      
      // Convert numeric values to strings
      var category = typeof catVal === 'number' || !isNaN(parseInt(catVal)) ? 
        categoryNames[parseInt(catVal)] || 'scrap' : (catVal || 'scrap');
      var rarity = typeof rarVal === 'number' || !isNaN(parseInt(rarVal)) ? 
        rarityNames[parseInt(rarVal)] || 'common' : (rarVal || 'common');
      
      var itemData = {
        name: getExportValue('name') || 'Unknown Item',
        description: getExportValue('description') || 'An interesting item...',
        category: category,
        rarity: rarity,
        base_value: getExportValue('base_value') || '100',
        weight: getExportValue('weight') || '1.0',
        stack_size: getExportValue('stack_size') || '10',
        width: widthVal,
        height: heightVal,
        icon: getItemIcon(category)
      };
      
      var rarityClass = 'rarity-' + String(itemData.rarity).toLowerCase().replace(/[^a-z]/g, '');
      
      var html = '<div class="preview-container">';
      html += '<div class="preview-header">';
      html += '<span class="preview-title">👁️ Live Preview</span>';
      html += '<div class="preview-tabs">';
      html += '<div class="preview-tab' + (previewMode === 'grid' ? ' active' : '') + '" onclick="setPreviewMode(\\'grid\\')">Grid</div>';
      html += '<div class="preview-tab' + (previewMode === 'tooltip' ? ' active' : '') + '" onclick="setPreviewMode(\\'tooltip\\')">Tooltip</div>';
      html += '<div class="preview-tab' + (previewMode === 'edit' ? ' active' : '') + '" onclick="setPreviewMode(\\'edit\\')">Edit</div>';
      html += '</div>';
      html += '</div>';
      
      if (previewMode === 'grid') {
        // Grid Preview with sizing controls
        html += '<div class="grid-preview-wrapper">';
        
        // Size controls (width x height inputs)
        html += '<div class="size-controls">';
        html += '<span class="size-label">Item Size:</span>';
        html += '<div class="size-inputs">';
        html += '<input type="number" class="size-input" min="1" max="4" value="' + itemData.width + '" onchange="setItemWidth(this.value)" title="Width (1-4)">';
        html += '<span class="size-x">×</span>';
        html += '<input type="number" class="size-input" min="1" max="4" value="' + itemData.height + '" onchange="setItemHeight(this.value)" title="Height (1-4)">';
        html += '<span class="size-hint">cells</span>';
        html += '</div>';
        html += '</div>';
        
        // Inventory Grid Preview
        var cellSize = 40;
        var gapSize = 2;
        html += '<div class="inventory-grid-preview">';
        html += '<div class="inventory-grid">';
        
        // Render 8x4 grid with multi-cell item support
        var itemStartCol = 1;
        var itemStartRow = 0;
        
        for (var row = 0; row < 4; row++) {
          for (var col = 0; col < 8; col++) {
            var isItemCell = col >= itemStartCol && col < itemStartCol + itemData.width &&
                            row >= itemStartRow && row < itemStartRow + itemData.height;
            var isTopLeft = col === itemStartCol && row === itemStartRow;
            
            if (isItemCell) {
              if (isTopLeft) {
                // Render the item spanning multiple cells
                var itemWidth = itemData.width * cellSize + (itemData.width - 1) * gapSize;
                var itemHeight = itemData.height * cellSize + (itemData.height - 1) * gapSize;
                var iconSize = Math.min(itemData.width, itemData.height) * 1.5 * previewIconScale;
                html += '<div class="inventory-cell occupied" style="position: relative;">';
                html += '<div class="inventory-item ' + rarityClass + '" style="';
                html += 'position: absolute; width: ' + itemWidth + 'px; height: ' + itemHeight + 'px;';
                html += 'display: flex; align-items: center; justify-content: center;';
                html += 'font-size: ' + iconSize + 'rem;';
                html += 'z-index: 5;" onmouseenter="showItemTooltip(event)" onmouseleave="hideItemTooltip()">';
                html += '<span style="transform: translate(' + previewIconOffsetX + 'px, ' + previewIconOffsetY + 'px);">' + itemData.icon + '</span>';
                html += '</div>';
                html += '</div>';
              } else {
                // Empty placeholder cells covered by item
                html += '<div class="inventory-cell occupied" style="opacity: 0.3;"></div>';
              }
            } else {
              html += '<div class="inventory-cell"></div>';
            }
          }
        }
        
        html += '</div>';
        html += '</div>';
        
        // Icon customization controls (just for fine-tuning icon position)
        html += '<div class="icon-controls">';
        html += '<div class="icon-control-row">';
        html += '<span class="icon-control-label" title="Scale the icon within the item">Icon Scale</span>';
        html += '<input type="range" min="0.5" max="2" step="0.1" value="' + previewIconScale + '" oninput="updateIconScale(this.value)" class="icon-slider">';
        html += '<span class="icon-control-value">' + previewIconScale.toFixed(1) + 'x</span>';
        html += '</div>';
        html += '<div class="icon-control-row">';
        html += '<span class="icon-control-label" title="Nudge icon horizontally">Offset X</span>';
        html += '<input type="range" min="-10" max="10" step="1" value="' + previewIconOffsetX + '" oninput="updateIconOffset(\\'x\\', this.value)" class="icon-slider">';
        html += '<span class="icon-control-value">' + previewIconOffsetX + 'px</span>';
        html += '</div>';
        html += '<div class="icon-control-row">';
        html += '<span class="icon-control-label" title="Nudge icon vertically">Offset Y</span>';
        html += '<input type="range" min="-10" max="10" step="1" value="' + previewIconOffsetY + '" oninput="updateIconOffset(\\'y\\', this.value)" class="icon-slider">';
        html += '<span class="icon-control-value">' + previewIconOffsetY + 'px</span>';
        html += '</div>';
        html += '<button class="btn btn-sm" onclick="resetIconSettings()">Reset Icon</button>';
        html += '</div>';
        
        html += '</div>';
        
      } else if (previewMode === 'tooltip') {
        // Tooltip Preview (read-only display)
        html += '<div class="tooltip-preview ' + rarityClass + '">';
        html += '<div class="tooltip-header">';
        html += '<div class="tooltip-icon" style="font-size: 2rem;">' + itemData.icon + '</div>';
        html += '<div class="tooltip-title-section">';
        html += '<div class="tooltip-name">' + escapeHtml(cleanString(itemData.name)) + '</div>';
        html += '<div class="tooltip-rarity">' + escapeHtml(cleanString(itemData.rarity)) + '</div>';
        html += '</div>';
        html += '</div>';
        
        html += '<div class="tooltip-desc">' + escapeHtml(cleanString(itemData.description)) + '</div>';
        
        html += '<div class="tooltip-stats">';
        html += '<div class="tooltip-stat"><span class="tooltip-stat-label">Value</span><span class="tooltip-stat-value">💰 ' + escapeHtml(String(itemData.base_value)) + '</span></div>';
        html += '<div class="tooltip-stat"><span class="tooltip-stat-label">Weight</span><span class="tooltip-stat-value">⚖️ ' + escapeHtml(String(itemData.weight)) + '</span></div>';
        html += '<div class="tooltip-stat"><span class="tooltip-stat-label">Stack</span><span class="tooltip-stat-value">📦 ' + escapeHtml(String(itemData.stack_size)) + '</span></div>';
        html += '<div class="tooltip-stat"><span class="tooltip-stat-label">Size</span><span class="tooltip-stat-value">📐 ' + itemData.width + '×' + itemData.height + '</span></div>';
        html += '</div>';
        
        html += '<div class="tooltip-tags">';
        html += '<span class="tooltip-tag">' + escapeHtml(cleanString(itemData.category)) + '</span>';
        if (itemData.rarity !== 'common') {
          html += '<span class="tooltip-tag ' + rarityClass + '">' + escapeHtml(cleanString(itemData.rarity)) + '</span>';
        }
        html += '</div>';
        
        html += '</div>';
        
      } else if (previewMode === 'edit') {
        // Editable Tooltip - click to edit fields directly
        html += '<div class="tooltip-preview editable ' + rarityClass + '">';
        html += '<div class="tooltip-header">';
        html += '<div class="tooltip-icon" style="font-size: 2rem;">' + itemData.icon + '</div>';
        html += '<div class="tooltip-title-section">';
        html += '<input type="text" class="edit-field edit-name" value="' + escapeHtml(cleanString(itemData.name)) + '" onchange="updateNameField(this.value)" placeholder="Item Name">';
        html += '<select class="edit-field edit-rarity" onchange="updateExportByName(\\'rarity\\', this.value)">';
        for (var i = 0; i < rarityNames.length; i++) {
          html += '<option value="' + i + '"' + (parseInt(rarVal) === i ? ' selected' : '') + '>' + rarityNames[i].charAt(0).toUpperCase() + rarityNames[i].slice(1) + '</option>';
        }
        html += '</select>';
        html += '</div>';
        html += '</div>';
        
        html += '<textarea class="edit-field edit-desc" onchange="updateDescriptionField(this.value)" placeholder="Item description...">' + escapeHtml(cleanString(itemData.description)) + '</textarea>';
        
        html += '<div class="edit-stats-grid">';
        html += '<div class="edit-stat">';
        html += '<label>💰 Value</label>';
        html += '<input type="number" value="' + escapeHtml(String(itemData.base_value)) + '" onchange="updateExportByName(\\'base_value\\', this.value)" min="0">';
        html += '</div>';
        html += '<div class="edit-stat">';
        html += '<label>⚖️ Weight</label>';
        html += '<input type="number" value="' + escapeHtml(String(itemData.weight)) + '" step="0.1" onchange="updateExportByName(\\'weight\\', this.value)" min="0">';
        html += '</div>';
        html += '<div class="edit-stat">';
        html += '<label>📦 Stack</label>';
        html += '<input type="number" value="' + escapeHtml(String(itemData.stack_size)) + '" onchange="updateExportByName(\\'stack_size\\', this.value)" min="1" max="999">';
        html += '</div>';
        html += '<div class="edit-stat">';
        html += '<label>🏷️ Category</label>';
        html += '<select onchange="updateExportByName(\\'category\\', this.value)">';
        for (var c = 0; c < categoryNames.length; c++) {
          html += '<option value="' + c + '"' + (parseInt(catVal) === c ? ' selected' : '') + '>' + categoryNames[c].charAt(0).toUpperCase() + categoryNames[c].slice(1) + '</option>';
        }
        html += '</select>';
        html += '</div>';
        html += '</div>';
        
        html += '<div class="edit-size-row">';
        html += '<label>📐 Size</label>';
        html += '<div class="edit-size-inputs">';
        html += '<span>W:</span><input type="number" value="' + itemData.width + '" min="1" max="4" onchange="updateExportByName(\\'width\\', this.value)">';
        html += '<span>H:</span><input type="number" value="' + itemData.height + '" min="1" max="4" onchange="updateExportByName(\\'height\\', this.value)">';
        html += '</div>';
        html += '</div>';
        
        html += '</div>';
      }
      
      html += '</div>';
      return html;
    }
    
    function updateExportByName(name, value) {
      var index = playgroundExports.findIndex(function(e) {
        return e.name.toLowerCase() === name.toLowerCase();
      });
      if (index !== -1) {
        updatePlaygroundValue(index, value);
      }
    }
    
    function updateDescriptionField(value) {
      // Wrap description in quotes for GDScript string
      var quotedValue = '"' + value.replace(/"/g, '\\\\"') + '"';
      updateExportByName('description', quotedValue);
    }
    
    function updateNameField(value) {
      // Wrap name in quotes for GDScript string
      var quotedValue = '"' + value.replace(/"/g, '\\\\"') + '"';
      updateExportByName('name', quotedValue);
    }
    
    function setItemWidth(value) {
      // Clamp to 1-4
      var width = Math.max(1, Math.min(4, parseInt(value) || 1));
      updateExportByName('width', String(width));
      renderPlaygroundSidebar();
    }
    
    function setItemHeight(value) {
      // Clamp to 1-4
      var height = Math.max(1, Math.min(4, parseInt(value) || 1));
      updateExportByName('height', String(height));
      renderPlaygroundSidebar();
    }
    
    function updateIconScale(value) {
      previewIconScale = parseFloat(value);
      updatePreviewOnly();
    }
    
    function updateIconOffset(axis, value) {
      if (axis === 'x') previewIconOffsetX = parseInt(value);
      if (axis === 'y') previewIconOffsetY = parseInt(value);
      updatePreviewOnly();
    }
    
    function resetIconSettings() {
      previewIconScale = 1.0;
      previewIconOffsetX = 0;
      previewIconOffsetY = 0;
      updatePreviewOnly();
    }
    
    function updatePreviewOnly() {
      // Update just the preview without re-rendering entire sidebar
      var previewSticky = document.querySelector('.preview-sticky');
      if (previewSticky) {
        previewSticky.innerHTML = renderItemPreview();
      }
    }
    
    function getExportValue(name) {
      var exp = playgroundExports.find(function(e) { 
        return e.name === name || e.name.toLowerCase() === name.toLowerCase(); 
      });
      return exp ? (exp.currentValue || exp.default) : null;
    }
    
    function cleanString(str) {
      if (!str) return '';
      // Remove quotes and extra whitespace
      return String(str).replace(/^["']|["']$/g, '').trim();
    }
    
    function getItemIcon(category) {
      var icons = {
        scrap: '🔩',
        component: '⚙️',
        valuable: '💎',
        epic: '✨',
        legendary: '👑',
        consumable: '🧪',
        key_item: '🔑',
        cargo: '📦',
        equipment: '🛡️',
        weapon: '⚔️',
        module: '🔧'
      };
      var cat = String(category || 'scrap').toLowerCase().replace(/[^a-z_]/g, '');
      return icons[cat] || '📦';
    }
    
    function setPreviewMode(mode) {
      previewMode = mode;
      updatePreviewOnly();
    }
    
    function showItemTooltip(event) {
      // Create floating tooltip on hover
      var categoryNames = ['scrap', 'component', 'valuable', 'epic', 'legendary'];
      var rarityNames = ['common', 'uncommon', 'rare', 'epic', 'legendary'];
      var rarVal = getExportValue('rarity');
      var rarity = typeof rarVal === 'number' || !isNaN(parseInt(rarVal)) ? 
        rarityNames[parseInt(rarVal)] || 'common' : (rarVal || 'common');
      
      var itemData = {
        name: getExportValue('name') || 'Unknown Item',
        description: getExportValue('description') || 'An interesting item...',
        rarity: rarity,
        base_value: getExportValue('base_value') || '100'
      };
      
      var rarityClass = 'rarity-' + String(itemData.rarity).toLowerCase().replace(/[^a-z]/g, '');
      
      var tooltip = document.createElement('div');
      tooltip.id = 'floatingTooltip';
      tooltip.className = 'tooltip-preview floating ' + rarityClass;
      tooltip.style.cssText = 'position: fixed; z-index: 10000; pointer-events: none;';
      tooltip.innerHTML = '<div class="tooltip-name">' + escapeHtml(cleanString(itemData.name)) + '</div><div class="tooltip-rarity" style="font-size: 0.7rem; opacity: 0.8;">' + escapeHtml(cleanString(itemData.rarity)) + '</div><div class="tooltip-desc" style="margin: 0.25rem 0; font-size: 0.75rem;">' + escapeHtml(cleanString(itemData.description)) + '</div><div style="font-size: 0.75rem; color: var(--accent-warning);">💰 ' + escapeHtml(String(itemData.base_value)) + '</div>';
      
      tooltip.style.left = (event.clientX + 15) + 'px';
      tooltip.style.top = (event.clientY + 15) + 'px';
      
      document.body.appendChild(tooltip);
    }
    
    function hideItemTooltip() {
      var tooltip = document.getElementById('floatingTooltip');
      if (tooltip) tooltip.remove();
    }
    
    // ===== VALUE UPDATES =====
    function togglePlaygroundPanel(header) {
      header.parentElement.classList.toggle('collapsed');
    }
    
    function updatePlaygroundValue(index, newValue) {
      var exp = playgroundExports[index];
      if (!exp) return;
      
      if (!exp.originalValue) {
        exp.originalValue = exp.default;
      }
      exp.currentValue = newValue;
      exp.modified = exp.currentValue !== exp.originalValue;
      
      // Update the code
      var lines = playgroundModifiedContent.split(String.fromCharCode(10));
      var lineIndex = exp.line - 1;
      if (lines[lineIndex]) {
        var varPattern = new RegExp('((?:@export[^v]*)?var[ ]+' + exp.name + '[ ]*[=:][ ]*)([^#]+)');
        lines[lineIndex] = lines[lineIndex].replace(varPattern, '$1' + newValue + ' ');
        playgroundModifiedContent = lines.join(String.fromCharCode(10));
        renderPlaygroundEditor();
      }
      
      // Update changes panel
      var changesContainer = document.getElementById('playgroundChanges');
      if (changesContainer) {
        changesContainer.innerHTML = renderChangesContent();
      }
      
      // Update live preview if active
      if (playgroundActiveTemplate === 'item') {
        updatePreviewOnly();
      }
    }
    
    function updatePlaygroundVector(index, component, value) {
      var exp = playgroundExports[index];
      if (!exp) return;
      
      if (!exp.vectorValues) {
        var match = (exp.default || '').match(/Vector2[(]([^,]+),[ ]*([^)]+)[)]/);
        exp.vectorValues = { x: match ? match[1].trim() : '0', y: match ? match[2].trim() : '0' };
      }
      
      exp.vectorValues[component] = value;
      var newValue = 'Vector2(' + exp.vectorValues.x + ', ' + exp.vectorValues.y + ')';
      updatePlaygroundValue(index, newValue);
    }
    
    // ===== ACTIONS =====
    function resetPlayground() {
      if (!playgroundCurrentFile && !playgroundActiveTemplate) {
        showToast('No file loaded', 'warning');
        return;
      }
      
      playgroundModifiedContent = playgroundOriginalContent;
      playgroundExports.forEach(function(e) {
        e.currentValue = e.default;
        e.originalValue = e.default;
        e.modified = false;
        delete e.vectorValues;
      });
      
      renderPlaygroundEditor();
      renderPlaygroundSidebar();
      showToast('Reset to original values', 'success');
    }
    
    function copyPlaygroundCode() {
      if (!playgroundModifiedContent) {
        showToast('No content to copy', 'warning');
        return;
      }
      copyToClipboard(playgroundModifiedContent);
    }
    
    function downloadModifiedFile() {
      if (!playgroundModifiedContent) {
        showToast('No content to download', 'warning');
        return;
      }
      
      var filename = playgroundActiveTemplate ? playgroundActiveTemplate + '.gd' : playgroundCurrentFile.split('/').pop();
      var blob = new Blob([playgroundModifiedContent], { type: 'text/plain' });
      var url = URL.createObjectURL(blob);
      var a = document.createElement('a');
      a.href = url;
      a.download = filename;
      a.click();
      URL.revokeObjectURL(url);
      showToast('Downloaded ' + filename, 'success');
    }
    
    function exportPlaygroundTodos() {
      var changes = playgroundExports.filter(function(e) { return e.modified; });
      if (changes.length === 0) {
        showToast('No changes to export', 'warning');
        return;
      }
      
      var todoItems = changes.map(function(c) {
        return {
          id: Date.now() + '_' + c.name,
          file: playgroundCurrentFile,
          line: c.line,
          variable: c.name,
          type: c.type,
          oldValue: c.originalValue,
          newValue: c.currentValue,
          timestamp: new Date().toISOString(),
          status: 'pending',
          description: 'Change ' + c.name + ' from ' + c.originalValue + ' to ' + c.currentValue
        };
      });
      
      var existingTodos = JSON.parse(localStorage.getItem('playgroundTodos') || '[]');
      var newTodos = existingTodos.concat(todoItems);
      localStorage.setItem('playgroundTodos', JSON.stringify(newTodos));
      
      apiCall('/api/todos/add', 'POST', {
        source: 'playground',
        items: todoItems
      }).then(function() {
        showToast('Exported ' + todoItems.length + ' changes to TODO list!', 'success');
      }).catch(function(e) {
        showToast('Saved locally. API sync failed.', 'warning');
      });
      
      var nl = String.fromCharCode(10);
      var message = 'Exported changes:' + nl;
      todoItems.forEach(function(t) {
        message += '- ' + t.variable + ': ' + t.oldValue + ' -> ' + t.newValue + nl;
      });
      console.log(message);
    }
    
    function getPlaygroundTodos() {
      return JSON.parse(localStorage.getItem('playgroundTodos') || '[]');
    }
    
    function clearPlaygroundTodos() {
      localStorage.removeItem('playgroundTodos');
      showToast('Cleared all playground TODOs', 'success');
    }

    // ==================== TERMINAL ====================
    function showTerminal() {
      document.getElementById('terminalModal').classList.add('show');
      document.getElementById('terminalInput').focus();
    }
    
    function hideTerminal() {
      document.getElementById('terminalModal').classList.remove('show');
    }
    
    async function executeTerminalCommand() {
      const input = document.getElementById('terminalInput');
      const output = document.getElementById('terminalOutput');
      
      if (!input?.value.trim()) return;
      
      const cmd = input.value.trim();
      const parts = cmd.split(' ');
      const command = parts[0];
      const args = parts.slice(1).join(' ');
      
      // Add command to output
      output.innerHTML += '<div class="terminal-line"><span class="terminal-prompt">$</span> ' + escapeHtml(cmd) + '</div>';
      input.value = '';
      
      try {
        const result = await apiCall('/api/tools/run_command', 'POST', { command, args });
        
        if (result.stdout) {
          output.innerHTML += '<div class="terminal-line" style="white-space: pre-wrap;">' + escapeHtml(result.stdout) + '</div>';
        }
        if (result.stderr) {
          output.innerHTML += '<div class="terminal-line" style="color: var(--accent-error); white-space: pre-wrap;">' + escapeHtml(result.stderr) + '</div>';
        }
      } catch (e) {
        output.innerHTML += '<div class="terminal-line" style="color: var(--accent-error);">Error: ' + e.message + '</div>';
      }
      
      // Scroll to bottom
      output.scrollTop = output.scrollHeight;
    }
    
    // ==================== HEALTH SCORE ====================
    async function showHealthScore() {
      document.getElementById('healthModal').classList.add('show');
      const content = document.getElementById('healthContent');
      
      content.innerHTML = '<div style="text-align: center; padding: 2rem; color: var(--text-muted);"><div style="font-size: 2rem; margin-bottom: 0.5rem;">⏳</div>Analyzing project health...</div>';
      
      try {
        const result = await apiCall('/api/tools/project_health', 'POST', {});
        
        const gradeColors = { A: 'var(--accent-success)', B: '#84cc16', C: 'var(--accent-warning)', D: '#f97316', F: 'var(--accent-error)' };
        
        content.innerHTML = 
          '<div class="health-score ' + result.grade + '">' +
            '<div class="health-score-circle" style="--health-rotation: ' + (result.score * 3.6) + 'deg;">' +
              '<div class="health-score-value">' + result.score + '</div>' +
              '<div class="health-score-grade">Grade: ' + result.grade + '</div>' +
            '</div>' +
          '</div>' +
          '<div style="margin-top: 1.5rem;">' +
            '<h4 style="margin-bottom: 0.75rem;">📊 Breakdown</h4>' +
            '<div class="output-stat-grid">' +
              '<div class="output-stat-item"><div class="stat-value">' + result.metrics.todos + '</div><div class="stat-label">TODOs</div></div>' +
              '<div class="output-stat-item"><div class="stat-value">' + result.metrics.fixmes + '</div><div class="stat-label">FIXMEs</div></div>' +
              '<div class="output-stat-item"><div class="stat-value">' + result.metrics.hacks + '</div><div class="stat-label">HACKs</div></div>' +
              '<div class="output-stat-item"><div class="stat-value">' + result.metrics.largeScripts + '</div><div class="stat-label">Large Scripts</div></div>' +
              '<div class="output-stat-item"><div class="stat-value">' + result.metrics.testFiles + '</div><div class="stat-label">Test Files</div></div>' +
            '</div>' +
          '</div>' +
          (result.recommendations?.length > 0 ? 
            '<div style="margin-top: 1.5rem;"><h4 style="margin-bottom: 0.75rem;">💡 Recommendations</h4>' +
            result.recommendations.map(r => {
              const icons = { high: '🔴', medium: '🟡', low: '🟢' };
              return '<div style="padding: 0.75rem; background: var(--bg-secondary); border-radius: 8px; margin-bottom: 0.5rem; display: flex; gap: 0.75rem;"><span>' + icons[r.priority] + '</span><span>' + escapeHtml(r.message) + '</span></div>';
            }).join('') + '</div>' : '');
      } catch (e) {
        content.innerHTML = '<div style="text-align: center; color: var(--accent-error);">Error: ' + e.message + '</div>';
      }
    }
    
    function hideHealthModal() {
      document.getElementById('healthModal').classList.remove('show');
    }
    
    // ==================== COPY & EXPORT ====================
    function copyToClipboard(text) {
      navigator.clipboard.writeText(text).then(() => {
        showToast('Copied to clipboard!', 'success');
      }).catch(() => {
        showToast('Failed to copy', 'error');
      });
    }
    
    function copyCurrentView() {
      const content = document.getElementById('detailContent').innerText;
      copyToClipboard(content);
    }
    
    async function exportCurrentView(format) {
      const type = state.currentExportType || 'stats';
      const url = format === 'csv' ? '/api/export/csv?type=' + type : '/api/export/json?type=' + type;
      
      try {
        const response = await fetch('http://localhost:3100' + url, {
          headers: { 'Authorization': 'Bearer ' + API_KEY }
        });
        
        const blob = await response.blob();
        const downloadUrl = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = downloadUrl;
        a.download = type + '-export.' + format;
        a.click();
        window.URL.revokeObjectURL(downloadUrl);
        
        showToast('Exported successfully!', 'success');
      } catch (e) {
        showToast('Export failed: ' + e.message, 'error');
      }
    }
    
    // ==================== TOAST NOTIFICATIONS ====================
    function showToast(message, type = 'info') {
      const container = document.getElementById('toastContainer');
      if (!container) return;
      
      const icons = { success: '✅', error: '❌', warning: '⚠️', info: 'ℹ️' };
      
      const toast = document.createElement('div');
      toast.className = 'toast ' + type;
      toast.innerHTML = '<span>' + icons[type] + '</span><span>' + escapeHtml(message) + '</span>';
      
      container.appendChild(toast);
      
      // Remove after 4 seconds
      setTimeout(() => {
        toast.style.animation = 'slideIn 0.3s ease-out reverse';
        setTimeout(() => toast.remove(), 300);
      }, 4000);
    }
    
    // ==================== SOUND STUDIO DAW ====================
    
    // DAW State
    const dawState = {
      tracks: [],
      clips: [],
      selectedClipId: null,
      selectedTrackId: null,
      isPlaying: false,
      isRecording: false,
      currentTime: 0,
      bpm: 120,
      timelineLength: 30,
      zoom: 100,
      snapEnabled: true,
      snapValue: 0.25,
      nextTrackId: 1,
      nextClipId: 1,
      audioContext: null,
      masterVolume: 80,
      activeCategory: 'all',
      effects: [],
      pixelsPerSecond: 100
    };
    
    // Massively Expanded Sound Library - 50+ sounds per category
    const SOUND_LIBRARY = {
      ui: {
        name: 'UI Sounds',
        icon: '🖱️',
        sounds: [
          { id: 'ui_click', name: 'Button Click', path: 'ui/click.wav', duration: 0.1 },
          { id: 'ui_click_soft', name: 'Soft Click', path: 'ui/click_soft.wav', duration: 0.08 },
          { id: 'ui_click_heavy', name: 'Heavy Click', path: 'ui/click_heavy.wav', duration: 0.15 },
          { id: 'ui_hover', name: 'Hover', path: 'ui/hover.wav', duration: 0.05 },
          { id: 'ui_hover_soft', name: 'Soft Hover', path: 'ui/hover_soft.wav', duration: 0.04 },
          { id: 'ui_confirm', name: 'Confirm', path: 'ui/confirm.wav', duration: 0.2 },
          { id: 'ui_confirm_positive', name: 'Positive Confirm', path: 'ui/confirm_positive.wav', duration: 0.25 },
          { id: 'ui_cancel', name: 'Cancel', path: 'ui/cancel.wav', duration: 0.15 },
          { id: 'ui_cancel_soft', name: 'Soft Cancel', path: 'ui/cancel_soft.wav', duration: 0.12 },
          { id: 'ui_back', name: 'Back', path: 'ui/back.wav', duration: 0.1 },
          { id: 'ui_menu_open', name: 'Menu Open', path: 'ui/menu_open.wav', duration: 0.3 },
          { id: 'ui_menu_close', name: 'Menu Close', path: 'ui/menu_close.wav', duration: 0.25 },
          { id: 'ui_tab_switch', name: 'Tab Switch', path: 'ui/tab_switch.wav', duration: 0.1 },
          { id: 'ui_scroll', name: 'Scroll Tick', path: 'ui/scroll.wav', duration: 0.03 },
          { id: 'ui_slider', name: 'Slider Move', path: 'ui/slider.wav', duration: 0.05 },
          { id: 'ui_toggle_on', name: 'Toggle On', path: 'ui/toggle_on.wav', duration: 0.1 },
          { id: 'ui_toggle_off', name: 'Toggle Off', path: 'ui/toggle_off.wav', duration: 0.08 },
          { id: 'ui_dropdown', name: 'Dropdown', path: 'ui/dropdown.wav', duration: 0.15 },
          { id: 'ui_notification', name: 'Notification', path: 'ui/notification.wav', duration: 0.4 },
          { id: 'ui_notification_urgent', name: 'Urgent Notification', path: 'ui/notification_urgent.wav', duration: 0.5 },
          { id: 'ui_notification_subtle', name: 'Subtle Notification', path: 'ui/notification_subtle.wav', duration: 0.3 },
          { id: 'ui_error', name: 'Error', path: 'ui/error.wav', duration: 0.3 },
          { id: 'ui_error_critical', name: 'Critical Error', path: 'ui/error_critical.wav', duration: 0.5 },
          { id: 'ui_warning', name: 'Warning', path: 'ui/warning.wav', duration: 0.35 },
          { id: 'ui_success', name: 'Success', path: 'ui/success.wav', duration: 0.3 },
          { id: 'ui_typing', name: 'Typing', path: 'ui/typing.wav', duration: 0.02 },
          { id: 'ui_text_appear', name: 'Text Appear', path: 'ui/text_appear.wav', duration: 0.05 },
          { id: 'ui_dialog_open', name: 'Dialog Open', path: 'ui/dialog_open.wav', duration: 0.2 },
          { id: 'ui_dialog_close', name: 'Dialog Close', path: 'ui/dialog_close.wav', duration: 0.15 },
          { id: 'ui_tooltip_show', name: 'Tooltip Show', path: 'ui/tooltip_show.wav', duration: 0.08 },
          { id: 'ui_countdown', name: 'Countdown Tick', path: 'ui/countdown.wav', duration: 0.1 },
          { id: 'ui_countdown_final', name: 'Countdown Final', path: 'ui/countdown_final.wav', duration: 0.3 },
          { id: 'ui_highlight', name: 'Highlight', path: 'ui/highlight.wav', duration: 0.1 },
          { id: 'ui_select', name: 'Select', path: 'ui/select.wav', duration: 0.12 },
          { id: 'ui_deselect', name: 'Deselect', path: 'ui/deselect.wav', duration: 0.08 },
          { id: 'ui_lock', name: 'Lock', path: 'ui/lock.wav', duration: 0.15 },
          { id: 'ui_unlock', name: 'Unlock', path: 'ui/unlock.wav', duration: 0.2 },
          { id: 'ui_purchase', name: 'Purchase', path: 'ui/purchase.wav', duration: 0.3 },
          { id: 'ui_sell', name: 'Sell', path: 'ui/sell.wav', duration: 0.25 },
          { id: 'ui_coins', name: 'Coins', path: 'ui/coins.wav', duration: 0.4 },
          { id: 'ui_paper', name: 'Paper Shuffle', path: 'ui/paper.wav', duration: 0.3 },
          { id: 'ui_whoosh', name: 'UI Whoosh', path: 'ui/whoosh.wav', duration: 0.2 },
          { id: 'ui_pop', name: 'Pop', path: 'ui/pop.wav', duration: 0.1 },
          { id: 'ui_bubble', name: 'Bubble', path: 'ui/bubble.wav', duration: 0.15 },
          { id: 'ui_chime', name: 'Chime', path: 'ui/chime.wav', duration: 0.4 },
          { id: 'ui_ding', name: 'Ding', path: 'ui/ding.wav', duration: 0.2 },
          { id: 'ui_blip', name: 'Blip', path: 'ui/blip.wav', duration: 0.05 },
          { id: 'ui_beep', name: 'Beep', path: 'ui/beep.wav', duration: 0.1 },
          { id: 'ui_boop', name: 'Boop', path: 'ui/boop.wav', duration: 0.08 },
          { id: 'ui_swoosh', name: 'Swoosh', path: 'ui/swoosh.wav', duration: 0.25 },
          { id: 'ui_reveal', name: 'Reveal', path: 'ui/reveal.wav', duration: 0.5 },
          { id: 'ui_hide', name: 'Hide', path: 'ui/hide.wav', duration: 0.3 },
          { id: 'ui_minimize', name: 'Minimize', path: 'ui/minimize.wav', duration: 0.15 },
          { id: 'ui_maximize', name: 'Maximize', path: 'ui/maximize.wav', duration: 0.2 }
        ]
      },
      combat: {
        name: 'Combat',
        icon: '⚔️',
        sounds: [
          { id: 'laser_fire_light', name: 'Light Laser', path: 'combat/laser_light.wav', duration: 0.15 },
          { id: 'laser_fire_medium', name: 'Medium Laser', path: 'combat/laser_medium.wav', duration: 0.2 },
          { id: 'laser_fire_heavy', name: 'Heavy Laser', path: 'combat/laser_heavy.wav', duration: 0.3 },
          { id: 'laser_fire_burst', name: 'Laser Burst', path: 'combat/laser_burst.wav', duration: 0.4 },
          { id: 'laser_fire_rapid', name: 'Rapid Laser', path: 'combat/laser_rapid.wav', duration: 0.1 },
          { id: 'laser_hit', name: 'Laser Hit', path: 'combat/laser_hit.wav', duration: 0.1 },
          { id: 'laser_hit_shield', name: 'Laser Shield Hit', path: 'combat/laser_hit_shield.wav', duration: 0.15 },
          { id: 'laser_hit_hull', name: 'Laser Hull Hit', path: 'combat/laser_hit_hull.wav', duration: 0.2 },
          { id: 'laser_miss', name: 'Laser Miss', path: 'combat/laser_miss.wav', duration: 0.3 },
          { id: 'plasma_fire', name: 'Plasma Fire', path: 'combat/plasma_fire.wav', duration: 0.25 },
          { id: 'plasma_charge', name: 'Plasma Charge', path: 'combat/plasma_charge.wav', duration: 0.8 },
          { id: 'plasma_hit', name: 'Plasma Hit', path: 'combat/plasma_hit.wav', duration: 0.3 },
          { id: 'missile_fire', name: 'Missile Launch', path: 'combat/missile_fire.wav', duration: 0.5 },
          { id: 'missile_lock', name: 'Missile Lock', path: 'combat/missile_lock.wav', duration: 0.3 },
          { id: 'missile_tracking', name: 'Missile Tracking', path: 'combat/missile_tracking.wav', duration: 1.0 },
          { id: 'missile_hit', name: 'Missile Impact', path: 'combat/missile_hit.wav', duration: 0.6 },
          { id: 'torpedo_fire', name: 'Torpedo Fire', path: 'combat/torpedo_fire.wav', duration: 0.7 },
          { id: 'torpedo_hit', name: 'Torpedo Impact', path: 'combat/torpedo_hit.wav', duration: 0.8 },
          { id: 'railgun_charge', name: 'Railgun Charge', path: 'combat/railgun_charge.wav', duration: 1.5 },
          { id: 'railgun_fire', name: 'Railgun Fire', path: 'combat/railgun_fire.wav', duration: 0.4 },
          { id: 'railgun_hit', name: 'Railgun Hit', path: 'combat/railgun_hit.wav', duration: 0.3 },
          { id: 'flak_fire', name: 'Flak Fire', path: 'combat/flak_fire.wav', duration: 0.2 },
          { id: 'flak_burst', name: 'Flak Burst', path: 'combat/flak_burst.wav', duration: 0.3 },
          { id: 'gatling_fire', name: 'Gatling Fire', path: 'combat/gatling_fire.wav', duration: 0.5 },
          { id: 'gatling_spinup', name: 'Gatling Spinup', path: 'combat/gatling_spinup.wav', duration: 1.0 },
          { id: 'gatling_spindown', name: 'Gatling Spindown', path: 'combat/gatling_spindown.wav', duration: 0.8 },
          { id: 'cannon_fire', name: 'Cannon Fire', path: 'combat/cannon_fire.wav', duration: 0.4 },
          { id: 'cannon_reload', name: 'Cannon Reload', path: 'combat/cannon_reload.wav', duration: 0.6 },
          { id: 'beam_fire', name: 'Beam Fire', path: 'combat/beam_fire.wav', duration: 2.0 },
          { id: 'beam_hit', name: 'Beam Hit', path: 'combat/beam_hit.wav', duration: 0.5 },
          { id: 'emp_charge', name: 'EMP Charge', path: 'combat/emp_charge.wav', duration: 1.2 },
          { id: 'emp_fire', name: 'EMP Fire', path: 'combat/emp_fire.wav', duration: 0.8 },
          { id: 'emp_hit', name: 'EMP Hit', path: 'combat/emp_hit.wav', duration: 0.5 },
          { id: 'shield_hit_light', name: 'Shield Hit Light', path: 'combat/shield_hit_light.wav', duration: 0.15 },
          { id: 'shield_hit_medium', name: 'Shield Hit Medium', path: 'combat/shield_hit_medium.wav', duration: 0.25 },
          { id: 'shield_hit_heavy', name: 'Shield Hit Heavy', path: 'combat/shield_hit_heavy.wav', duration: 0.4 },
          { id: 'shield_down', name: 'Shield Down', path: 'combat/shield_down.wav', duration: 0.6 },
          { id: 'shield_up', name: 'Shield Up', path: 'combat/shield_up.wav', duration: 0.5 },
          { id: 'shield_recharge', name: 'Shield Recharge', path: 'combat/shield_recharge.wav', duration: 1.5 },
          { id: 'shield_overload', name: 'Shield Overload', path: 'combat/shield_overload.wav', duration: 0.8 },
          { id: 'hull_hit_light', name: 'Hull Hit Light', path: 'combat/hull_hit_light.wav', duration: 0.2 },
          { id: 'hull_hit_medium', name: 'Hull Hit Medium', path: 'combat/hull_hit_medium.wav', duration: 0.3 },
          { id: 'hull_hit_heavy', name: 'Hull Hit Heavy', path: 'combat/hull_hit_heavy.wav', duration: 0.5 },
          { id: 'hull_breach', name: 'Hull Breach', path: 'combat/hull_breach.wav', duration: 0.8 },
          { id: 'critical_hit', name: 'Critical Hit', path: 'combat/critical_hit.wav', duration: 0.4 },
          { id: 'ricochet', name: 'Ricochet', path: 'combat/ricochet.wav', duration: 0.2 },
          { id: 'deflect', name: 'Deflect', path: 'combat/deflect.wav', duration: 0.15 },
          { id: 'weapon_ready', name: 'Weapon Ready', path: 'combat/weapon_ready.wav', duration: 0.2 },
          { id: 'weapon_empty', name: 'Weapon Empty', path: 'combat/weapon_empty.wav', duration: 0.15 },
          { id: 'reload_start', name: 'Reload Start', path: 'combat/reload_start.wav', duration: 0.3 },
          { id: 'reload_finish', name: 'Reload Finish', path: 'combat/reload_finish.wav', duration: 0.2 },
          { id: 'target_lock', name: 'Target Lock', path: 'combat/target_lock.wav', duration: 0.3 },
          { id: 'target_lost', name: 'Target Lost', path: 'combat/target_lost.wav', duration: 0.2 },
          { id: 'countermeasures', name: 'Countermeasures', path: 'combat/countermeasures.wav', duration: 0.5 }
        ]
      },
      explosions: {
        name: 'Explosions',
        icon: '💥',
        sounds: [
          { id: 'explosion_tiny', name: 'Tiny Explosion', path: 'explosions/tiny.wav', duration: 0.3 },
          { id: 'explosion_small', name: 'Small Explosion', path: 'explosions/small.wav', duration: 0.5 },
          { id: 'explosion_medium', name: 'Medium Explosion', path: 'explosions/medium.wav', duration: 0.8 },
          { id: 'explosion_large', name: 'Large Explosion', path: 'explosions/large.wav', duration: 1.2 },
          { id: 'explosion_massive', name: 'Massive Explosion', path: 'explosions/massive.wav', duration: 2.0 },
          { id: 'explosion_nuclear', name: 'Nuclear Explosion', path: 'explosions/nuclear.wav', duration: 3.0 },
          { id: 'explosion_ship_small', name: 'Small Ship Explode', path: 'explosions/ship_small.wav', duration: 1.5 },
          { id: 'explosion_ship_medium', name: 'Medium Ship Explode', path: 'explosions/ship_medium.wav', duration: 2.0 },
          { id: 'explosion_ship_large', name: 'Large Ship Explode', path: 'explosions/ship_large.wav', duration: 3.0 },
          { id: 'explosion_station', name: 'Station Explosion', path: 'explosions/station.wav', duration: 4.0 },
          { id: 'explosion_debris', name: 'Debris Explosion', path: 'explosions/debris.wav', duration: 0.6 },
          { id: 'explosion_electrical', name: 'Electrical Explosion', path: 'explosions/electrical.wav', duration: 0.7 },
          { id: 'explosion_fire', name: 'Fire Explosion', path: 'explosions/fire.wav', duration: 0.8 },
          { id: 'explosion_chemical', name: 'Chemical Explosion', path: 'explosions/chemical.wav', duration: 1.0 },
          { id: 'explosion_fuel', name: 'Fuel Explosion', path: 'explosions/fuel.wav', duration: 1.2 },
          { id: 'explosion_ammo', name: 'Ammo Explosion', path: 'explosions/ammo.wav', duration: 0.9 },
          { id: 'explosion_cascade', name: 'Cascade Explosion', path: 'explosions/cascade.wav', duration: 2.5 },
          { id: 'explosion_muffled', name: 'Muffled Explosion', path: 'explosions/muffled.wav', duration: 0.6 },
          { id: 'explosion_distant', name: 'Distant Explosion', path: 'explosions/distant.wav', duration: 1.5 },
          { id: 'explosion_close', name: 'Close Explosion', path: 'explosions/close.wav', duration: 0.8 },
          { id: 'explosion_rumble', name: 'Explosion Rumble', path: 'explosions/rumble.wav', duration: 2.0 },
          { id: 'explosion_crackle', name: 'Explosion Crackle', path: 'explosions/crackle.wav', duration: 1.0 },
          { id: 'implosion', name: 'Implosion', path: 'explosions/implosion.wav', duration: 0.8 },
          { id: 'detonation', name: 'Detonation', path: 'explosions/detonation.wav', duration: 0.5 },
          { id: 'blast_wave', name: 'Blast Wave', path: 'explosions/blast_wave.wav', duration: 1.5 },
          { id: 'shockwave', name: 'Shockwave', path: 'explosions/shockwave.wav', duration: 1.2 },
          { id: 'debris_scatter', name: 'Debris Scatter', path: 'explosions/debris_scatter.wav', duration: 1.8 },
          { id: 'metal_groan', name: 'Metal Groan', path: 'explosions/metal_groan.wav', duration: 2.0 },
          { id: 'structure_collapse', name: 'Structure Collapse', path: 'explosions/structure_collapse.wav', duration: 3.0 },
          { id: 'chain_reaction', name: 'Chain Reaction', path: 'explosions/chain_reaction.wav', duration: 4.0 },
          { id: 'mine_detonate', name: 'Mine Detonation', path: 'explosions/mine_detonate.wav', duration: 0.6 },
          { id: 'grenade_explode', name: 'Grenade Explosion', path: 'explosions/grenade.wav', duration: 0.5 },
          { id: 'bomb_drop', name: 'Bomb Drop', path: 'explosions/bomb_drop.wav', duration: 1.0 },
          { id: 'depth_charge', name: 'Depth Charge', path: 'explosions/depth_charge.wav', duration: 1.5 },
          { id: 'flash_bang', name: 'Flash Bang', path: 'explosions/flash_bang.wav', duration: 0.4 },
          { id: 'smoke_grenade', name: 'Smoke Deploy', path: 'explosions/smoke_grenade.wav', duration: 0.8 },
          { id: 'core_meltdown', name: 'Core Meltdown', path: 'explosions/core_meltdown.wav', duration: 5.0 },
          { id: 'reactor_breach', name: 'Reactor Breach', path: 'explosions/reactor_breach.wav', duration: 3.5 },
          { id: 'engine_explode', name: 'Engine Explosion', path: 'explosions/engine_explode.wav', duration: 2.0 },
          { id: 'console_spark', name: 'Console Spark', path: 'explosions/console_spark.wav', duration: 0.3 },
          { id: 'panel_burst', name: 'Panel Burst', path: 'explosions/panel_burst.wav', duration: 0.4 },
          { id: 'pipe_burst', name: 'Pipe Burst', path: 'explosions/pipe_burst.wav', duration: 0.6 },
          { id: 'steam_explosion', name: 'Steam Explosion', path: 'explosions/steam_explosion.wav', duration: 0.8 },
          { id: 'gas_explosion', name: 'Gas Explosion', path: 'explosions/gas_explosion.wav', duration: 1.0 },
          { id: 'fireball', name: 'Fireball', path: 'explosions/fireball.wav', duration: 1.2 },
          { id: 'aftershock', name: 'Aftershock', path: 'explosions/aftershock.wav', duration: 1.8 },
          { id: 'secondary_explosion', name: 'Secondary Explosion', path: 'explosions/secondary.wav', duration: 1.0 },
          { id: 'hull_rupture', name: 'Hull Rupture', path: 'explosions/hull_rupture.wav', duration: 1.5 },
          { id: 'compartment_blow', name: 'Compartment Blowout', path: 'explosions/compartment_blow.wav', duration: 1.2 },
          { id: 'catastrophic', name: 'Catastrophic Failure', path: 'explosions/catastrophic.wav', duration: 4.0 }
        ]
      },
      ship: {
        name: 'Ship',
        icon: '🚀',
        sounds: [
          { id: 'engine_start', name: 'Engine Start', path: 'ship/engine_start.wav', duration: 2.0 },
          { id: 'engine_stop', name: 'Engine Stop', path: 'ship/engine_stop.wav', duration: 1.5 },
          { id: 'engine_idle', name: 'Engine Idle', path: 'ship/engine_idle.wav', duration: 3.0 },
          { id: 'engine_boost', name: 'Engine Boost', path: 'ship/engine_boost.wav', duration: 1.0 },
          { id: 'engine_boost_end', name: 'Boost End', path: 'ship/engine_boost_end.wav', duration: 0.5 },
          { id: 'engine_throttle_up', name: 'Throttle Up', path: 'ship/engine_throttle_up.wav', duration: 0.8 },
          { id: 'engine_throttle_down', name: 'Throttle Down', path: 'ship/engine_throttle_down.wav', duration: 0.6 },
          { id: 'engine_strain', name: 'Engine Strain', path: 'ship/engine_strain.wav', duration: 2.0 },
          { id: 'engine_malfunction', name: 'Engine Malfunction', path: 'ship/engine_malfunction.wav', duration: 1.5 },
          { id: 'engine_repair', name: 'Engine Repair', path: 'ship/engine_repair.wav', duration: 3.0 },
          { id: 'thruster_fire', name: 'Thruster Fire', path: 'ship/thruster_fire.wav', duration: 0.4 },
          { id: 'thruster_burst', name: 'Thruster Burst', path: 'ship/thruster_burst.wav', duration: 0.3 },
          { id: 'maneuvering', name: 'Maneuvering', path: 'ship/maneuvering.wav', duration: 0.5 },
          { id: 'roll_left', name: 'Roll Left', path: 'ship/roll_left.wav', duration: 0.4 },
          { id: 'roll_right', name: 'Roll Right', path: 'ship/roll_right.wav', duration: 0.4 },
          { id: 'pitch_up', name: 'Pitch Up', path: 'ship/pitch_up.wav', duration: 0.4 },
          { id: 'pitch_down', name: 'Pitch Down', path: 'ship/pitch_down.wav', duration: 0.4 },
          { id: 'dock_approach', name: 'Docking Approach', path: 'ship/dock_approach.wav', duration: 2.0 },
          { id: 'dock_connect', name: 'Docking Connect', path: 'ship/dock_connect.wav', duration: 0.8 },
          { id: 'dock_clamp', name: 'Docking Clamp', path: 'ship/dock_clamp.wav', duration: 0.5 },
          { id: 'dock_seal', name: 'Docking Seal', path: 'ship/dock_seal.wav', duration: 0.6 },
          { id: 'undock_release', name: 'Undock Release', path: 'ship/undock_release.wav', duration: 0.5 },
          { id: 'undock_push', name: 'Undock Push', path: 'ship/undock_push.wav', duration: 0.7 },
          { id: 'landing_gear_down', name: 'Gear Down', path: 'ship/landing_gear_down.wav', duration: 1.2 },
          { id: 'landing_gear_up', name: 'Gear Up', path: 'ship/landing_gear_up.wav', duration: 1.0 },
          { id: 'touchdown', name: 'Touchdown', path: 'ship/touchdown.wav', duration: 0.8 },
          { id: 'liftoff', name: 'Liftoff', path: 'ship/liftoff.wav', duration: 2.0 },
          { id: 'hyperspace_charge', name: 'Hyperspace Charge', path: 'ship/hyperspace_charge.wav', duration: 3.0 },
          { id: 'hyperspace_enter', name: 'Hyperspace Enter', path: 'ship/hyperspace_enter.wav', duration: 1.5 },
          { id: 'hyperspace_travel', name: 'Hyperspace Travel', path: 'ship/hyperspace_travel.wav', duration: 5.0 },
          { id: 'hyperspace_exit', name: 'Hyperspace Exit', path: 'ship/hyperspace_exit.wav', duration: 1.5 },
          { id: 'warp_charge', name: 'Warp Charge', path: 'ship/warp_charge.wav', duration: 2.5 },
          { id: 'warp_jump', name: 'Warp Jump', path: 'ship/warp_jump.wav', duration: 1.0 },
          { id: 'warp_arrive', name: 'Warp Arrive', path: 'ship/warp_arrive.wav', duration: 1.2 },
          { id: 'cargo_bay_open', name: 'Cargo Bay Open', path: 'ship/cargo_bay_open.wav', duration: 1.5 },
          { id: 'cargo_bay_close', name: 'Cargo Bay Close', path: 'ship/cargo_bay_close.wav', duration: 1.2 },
          { id: 'cargo_load', name: 'Cargo Load', path: 'ship/cargo_load.wav', duration: 0.8 },
          { id: 'cargo_unload', name: 'Cargo Unload', path: 'ship/cargo_unload.wav', duration: 0.7 },
          { id: 'hatch_open', name: 'Hatch Open', path: 'ship/hatch_open.wav', duration: 0.8 },
          { id: 'hatch_close', name: 'Hatch Close', path: 'ship/hatch_close.wav', duration: 0.6 },
          { id: 'cockpit_seal', name: 'Cockpit Seal', path: 'ship/cockpit_seal.wav', duration: 0.5 },
          { id: 'power_up', name: 'Power Up', path: 'ship/power_up.wav', duration: 2.5 },
          { id: 'power_down', name: 'Power Down', path: 'ship/power_down.wav', duration: 2.0 },
          { id: 'system_online', name: 'System Online', path: 'ship/system_online.wav', duration: 0.5 },
          { id: 'system_offline', name: 'System Offline', path: 'ship/system_offline.wav', duration: 0.4 },
          { id: 'repair_weld', name: 'Repair Weld', path: 'ship/repair_weld.wav', duration: 1.5 },
          { id: 'repair_hammer', name: 'Repair Hammer', path: 'ship/repair_hammer.wav', duration: 0.3 },
          { id: 'repair_complete', name: 'Repair Complete', path: 'ship/repair_complete.wav', duration: 0.5 },
          { id: 'cloak_engage', name: 'Cloak Engage', path: 'ship/cloak_engage.wav', duration: 1.0 },
          { id: 'cloak_disengage', name: 'Cloak Disengage', path: 'ship/cloak_disengage.wav', duration: 0.8 },
          { id: 'scanner_ping', name: 'Scanner Ping', path: 'ship/scanner_ping.wav', duration: 0.5 },
          { id: 'scanner_sweep', name: 'Scanner Sweep', path: 'ship/scanner_sweep.wav', duration: 2.0 }
        ]
      },
      boarding: {
        name: 'Boarding',
        icon: '🏴‍☠️',
        sounds: [
          { id: 'grapple_launch', name: 'Grapple Launch', path: 'boarding/grapple_launch.wav', duration: 0.5 },
          { id: 'grapple_fly', name: 'Grapple Flying', path: 'boarding/grapple_fly.wav', duration: 1.0 },
          { id: 'grapple_connect', name: 'Grapple Connect', path: 'boarding/grapple_connect.wav', duration: 0.4 },
          { id: 'grapple_retract', name: 'Grapple Retract', path: 'boarding/grapple_retract.wav', duration: 1.5 },
          { id: 'grapple_disconnect', name: 'Grapple Disconnect', path: 'boarding/grapple_disconnect.wav', duration: 0.3 },
          { id: 'cable_tension', name: 'Cable Tension', path: 'boarding/cable_tension.wav', duration: 0.8 },
          { id: 'zipline', name: 'Zipline', path: 'boarding/zipline.wav', duration: 2.0 },
          { id: 'airlock_cycle_start', name: 'Airlock Cycle Start', path: 'boarding/airlock_cycle_start.wav', duration: 0.5 },
          { id: 'airlock_pressurize', name: 'Airlock Pressurize', path: 'boarding/airlock_pressurize.wav', duration: 2.0 },
          { id: 'airlock_depressurize', name: 'Airlock Depressurize', path: 'boarding/airlock_depressurize.wav', duration: 2.0 },
          { id: 'airlock_open', name: 'Airlock Open', path: 'boarding/airlock_open.wav', duration: 1.0 },
          { id: 'airlock_close', name: 'Airlock Close', path: 'boarding/airlock_close.wav', duration: 0.8 },
          { id: 'airlock_emergency', name: 'Emergency Airlock', path: 'boarding/airlock_emergency.wav', duration: 0.5 },
          { id: 'breach_cut', name: 'Breach Cutting', path: 'boarding/breach_cut.wav', duration: 3.0 },
          { id: 'breach_explosive', name: 'Explosive Breach', path: 'boarding/breach_explosive.wav', duration: 0.8 },
          { id: 'breach_complete', name: 'Breach Complete', path: 'boarding/breach_complete.wav', duration: 0.5 },
          { id: 'hull_saw', name: 'Hull Saw', path: 'boarding/hull_saw.wav', duration: 2.0 },
          { id: 'torch_cut', name: 'Torch Cutting', path: 'boarding/torch_cut.wav', duration: 2.5 },
          { id: 'door_force', name: 'Force Door', path: 'boarding/door_force.wav', duration: 1.0 },
          { id: 'door_hack', name: 'Hack Door', path: 'boarding/door_hack.wav', duration: 1.5 },
          { id: 'door_breach', name: 'Breach Door', path: 'boarding/door_breach.wav', duration: 0.5 },
          { id: 'flashbang_throw', name: 'Flashbang Throw', path: 'boarding/flashbang_throw.wav', duration: 0.3 },
          { id: 'flashbang_detonate', name: 'Flashbang Detonate', path: 'boarding/flashbang_detonate.wav', duration: 0.4 },
          { id: 'smoke_deploy', name: 'Smoke Deploy', path: 'boarding/smoke_deploy.wav', duration: 0.5 },
          { id: 'boots_mag_on', name: 'Mag Boots On', path: 'boarding/boots_mag_on.wav', duration: 0.3 },
          { id: 'boots_mag_off', name: 'Mag Boots Off', path: 'boarding/boots_mag_off.wav', duration: 0.2 },
          { id: 'boots_mag_step', name: 'Mag Boot Step', path: 'boarding/boots_mag_step.wav', duration: 0.4 },
          { id: 'jetpack_burst', name: 'Jetpack Burst', path: 'boarding/jetpack_burst.wav', duration: 0.5 },
          { id: 'jetpack_sustained', name: 'Jetpack Sustained', path: 'boarding/jetpack_sustained.wav', duration: 2.0 },
          { id: 'crew_ready', name: 'Crew Ready', path: 'boarding/crew_ready.wav', duration: 0.3 },
          { id: 'crew_move', name: 'Crew Move', path: 'boarding/crew_move.wav', duration: 0.5 },
          { id: 'crew_fight_melee', name: 'Melee Fight', path: 'boarding/crew_fight_melee.wav', duration: 0.8 },
          { id: 'crew_fight_ranged', name: 'Ranged Fight', path: 'boarding/crew_fight_ranged.wav', duration: 0.5 },
          { id: 'crew_hit', name: 'Crew Hit', path: 'boarding/crew_hit.wav', duration: 0.3 },
          { id: 'crew_down', name: 'Crew Down', path: 'boarding/crew_down.wav', duration: 0.5 },
          { id: 'crew_captured', name: 'Crew Captured', path: 'boarding/crew_captured.wav', duration: 0.4 },
          { id: 'hostage_taken', name: 'Hostage Taken', path: 'boarding/hostage_taken.wav', duration: 0.5 },
          { id: 'hostage_freed', name: 'Hostage Freed', path: 'boarding/hostage_freed.wav', duration: 0.4 },
          { id: 'room_clear', name: 'Room Clear', path: 'boarding/room_clear.wav', duration: 0.3 },
          { id: 'area_secured', name: 'Area Secured', path: 'boarding/area_secured.wav', duration: 0.4 },
          { id: 'boarding_success', name: 'Boarding Success', path: 'boarding/boarding_success.wav', duration: 0.8 },
          { id: 'boarding_failed', name: 'Boarding Failed', path: 'boarding/boarding_failed.wav', duration: 0.6 },
          { id: 'retreat', name: 'Retreat', path: 'boarding/retreat.wav', duration: 0.5 },
          { id: 'surrender', name: 'Surrender', path: 'boarding/surrender.wav', duration: 0.6 },
          { id: 'loot_grab', name: 'Loot Grab', path: 'boarding/loot_grab.wav', duration: 0.3 },
          { id: 'safe_crack', name: 'Safe Crack', path: 'boarding/safe_crack.wav', duration: 2.0 },
          { id: 'data_download', name: 'Data Download', path: 'boarding/data_download.wav', duration: 3.0 },
          { id: 'sabotage', name: 'Sabotage', path: 'boarding/sabotage.wav', duration: 1.0 },
          { id: 'plant_bomb', name: 'Plant Bomb', path: 'boarding/plant_bomb.wav', duration: 1.5 },
          { id: 'disarm_bomb', name: 'Disarm Bomb', path: 'boarding/disarm_bomb.wav', duration: 2.0 }
        ]
      },
      loot: {
        name: 'Loot & Items',
        icon: '💎',
        sounds: [
          { id: 'pickup_common', name: 'Common Pickup', path: 'loot/pickup_common.wav', duration: 0.3 },
          { id: 'pickup_uncommon', name: 'Uncommon Pickup', path: 'loot/pickup_uncommon.wav', duration: 0.35 },
          { id: 'pickup_rare', name: 'Rare Pickup', path: 'loot/pickup_rare.wav', duration: 0.4 },
          { id: 'pickup_epic', name: 'Epic Pickup', path: 'loot/pickup_epic.wav', duration: 0.5 },
          { id: 'pickup_legendary', name: 'Legendary Pickup', path: 'loot/pickup_legendary.wav', duration: 0.7 },
          { id: 'pickup_mythic', name: 'Mythic Pickup', path: 'loot/pickup_mythic.wav', duration: 1.0 },
          { id: 'pickup_money', name: 'Money Pickup', path: 'loot/pickup_money.wav', duration: 0.3 },
          { id: 'pickup_coins', name: 'Coins Pickup', path: 'loot/pickup_coins.wav', duration: 0.4 },
          { id: 'pickup_gems', name: 'Gems Pickup', path: 'loot/pickup_gems.wav', duration: 0.5 },
          { id: 'pickup_crystal', name: 'Crystal Pickup', path: 'loot/pickup_crystal.wav', duration: 0.6 },
          { id: 'pickup_scrap', name: 'Scrap Pickup', path: 'loot/pickup_scrap.wav', duration: 0.25 },
          { id: 'pickup_component', name: 'Component Pickup', path: 'loot/pickup_component.wav', duration: 0.3 },
          { id: 'pickup_ammo', name: 'Ammo Pickup', path: 'loot/pickup_ammo.wav', duration: 0.25 },
          { id: 'pickup_health', name: 'Health Pickup', path: 'loot/pickup_health.wav', duration: 0.4 },
          { id: 'pickup_shield', name: 'Shield Pickup', path: 'loot/pickup_shield.wav', duration: 0.35 },
          { id: 'pickup_energy', name: 'Energy Pickup', path: 'loot/pickup_energy.wav', duration: 0.35 },
          { id: 'pickup_fuel', name: 'Fuel Pickup', path: 'loot/pickup_fuel.wav', duration: 0.4 },
          { id: 'pickup_key', name: 'Key Pickup', path: 'loot/pickup_key.wav', duration: 0.5 },
          { id: 'pickup_card', name: 'Card Pickup', path: 'loot/pickup_card.wav', duration: 0.3 },
          { id: 'pickup_data', name: 'Data Pickup', path: 'loot/pickup_data.wav', duration: 0.4 },
          { id: 'inventory_open', name: 'Inventory Open', path: 'loot/inventory_open.wav', duration: 0.4 },
          { id: 'inventory_close', name: 'Inventory Close', path: 'loot/inventory_close.wav', duration: 0.3 },
          { id: 'item_move', name: 'Item Move', path: 'loot/item_move.wav', duration: 0.15 },
          { id: 'item_drop', name: 'Item Drop', path: 'loot/item_drop.wav', duration: 0.3 },
          { id: 'item_equip', name: 'Item Equip', path: 'loot/item_equip.wav', duration: 0.3 },
          { id: 'item_unequip', name: 'Item Unequip', path: 'loot/item_unequip.wav', duration: 0.25 },
          { id: 'weapon_equip', name: 'Weapon Equip', path: 'loot/weapon_equip.wav', duration: 0.4 },
          { id: 'armor_equip', name: 'Armor Equip', path: 'loot/armor_equip.wav', duration: 0.5 },
          { id: 'module_install', name: 'Module Install', path: 'loot/module_install.wav', duration: 0.6 },
          { id: 'module_remove', name: 'Module Remove', path: 'loot/module_remove.wav', duration: 0.5 },
          { id: 'item_use', name: 'Item Use', path: 'loot/item_use.wav', duration: 0.3 },
          { id: 'consumable_use', name: 'Consumable Use', path: 'loot/consumable_use.wav', duration: 0.4 },
          { id: 'potion_drink', name: 'Potion Drink', path: 'loot/potion_drink.wav', duration: 0.5 },
          { id: 'injection', name: 'Injection', path: 'loot/injection.wav', duration: 0.3 },
          { id: 'medkit_use', name: 'Medkit Use', path: 'loot/medkit_use.wav', duration: 1.0 },
          { id: 'item_sell', name: 'Item Sell', path: 'loot/item_sell.wav', duration: 0.3 },
          { id: 'item_buy', name: 'Item Buy', path: 'loot/item_buy.wav', duration: 0.35 },
          { id: 'item_craft', name: 'Item Craft', path: 'loot/item_craft.wav', duration: 0.8 },
          { id: 'item_upgrade', name: 'Item Upgrade', path: 'loot/item_upgrade.wav', duration: 0.6 },
          { id: 'item_dismantle', name: 'Item Dismantle', path: 'loot/item_dismantle.wav', duration: 0.5 },
          { id: 'item_repair', name: 'Item Repair', path: 'loot/item_repair.wav', duration: 0.7 },
          { id: 'chest_open', name: 'Chest Open', path: 'loot/chest_open.wav', duration: 0.8 },
          { id: 'chest_rare', name: 'Rare Chest Open', path: 'loot/chest_rare.wav', duration: 1.0 },
          { id: 'chest_legendary', name: 'Legendary Chest', path: 'loot/chest_legendary.wav', duration: 1.5 },
          { id: 'container_open', name: 'Container Open', path: 'loot/container_open.wav', duration: 0.5 },
          { id: 'crate_open', name: 'Crate Open', path: 'loot/crate_open.wav', duration: 0.6 },
          { id: 'locker_open', name: 'Locker Open', path: 'loot/locker_open.wav', duration: 0.4 },
          { id: 'safe_open', name: 'Safe Open', path: 'loot/safe_open.wav', duration: 0.8 },
          { id: 'loot_spill', name: 'Loot Spill', path: 'loot/loot_spill.wav', duration: 0.6 },
          { id: 'jackpot', name: 'Jackpot', path: 'loot/jackpot.wav', duration: 1.2 }
        ]
      },
      alerts: {
        name: 'Alerts',
        icon: '🚨',
        sounds: [
          { id: 'alert_info', name: 'Info Alert', path: 'alerts/info.wav', duration: 0.3 },
          { id: 'alert_warning', name: 'Warning Alert', path: 'alerts/warning.wav', duration: 0.4 },
          { id: 'alert_danger', name: 'Danger Alert', path: 'alerts/danger.wav', duration: 0.5 },
          { id: 'alert_critical', name: 'Critical Alert', path: 'alerts/critical.wav', duration: 0.6 },
          { id: 'alert_emergency', name: 'Emergency Alert', path: 'alerts/emergency.wav', duration: 0.8 },
          { id: 'alert_enemy', name: 'Enemy Detected', path: 'alerts/enemy.wav', duration: 0.5 },
          { id: 'alert_enemy_close', name: 'Enemy Close', path: 'alerts/enemy_close.wav', duration: 0.6 },
          { id: 'alert_hostile', name: 'Hostile Contact', path: 'alerts/hostile.wav', duration: 0.5 },
          { id: 'alert_incoming', name: 'Incoming', path: 'alerts/incoming.wav', duration: 0.4 },
          { id: 'alert_missile', name: 'Missile Alert', path: 'alerts/missile.wav', duration: 0.6 },
          { id: 'alert_collision', name: 'Collision Warning', path: 'alerts/collision.wav', duration: 0.5 },
          { id: 'alert_proximity', name: 'Proximity Alert', path: 'alerts/proximity.wav', duration: 0.4 },
          { id: 'alert_boarding', name: 'Boarding Alert', path: 'alerts/boarding.wav', duration: 0.7 },
          { id: 'alert_intruder', name: 'Intruder Alert', path: 'alerts/intruder.wav', duration: 0.6 },
          { id: 'alert_hull', name: 'Hull Breach Alert', path: 'alerts/hull.wav', duration: 0.8 },
          { id: 'alert_shield', name: 'Shield Alert', path: 'alerts/shield.wav', duration: 0.5 },
          { id: 'alert_power', name: 'Power Warning', path: 'alerts/power.wav', duration: 0.6 },
          { id: 'alert_fuel', name: 'Low Fuel', path: 'alerts/fuel.wav', duration: 0.5 },
          { id: 'alert_oxygen', name: 'Low Oxygen', path: 'alerts/oxygen.wav', duration: 0.6 },
          { id: 'alert_system', name: 'System Alert', path: 'alerts/system.wav', duration: 0.4 },
          { id: 'alert_malfunction', name: 'Malfunction', path: 'alerts/malfunction.wav', duration: 0.7 },
          { id: 'alert_fire', name: 'Fire Alert', path: 'alerts/fire.wav', duration: 0.6 },
          { id: 'alert_radiation', name: 'Radiation Warning', path: 'alerts/radiation.wav', duration: 0.8 },
          { id: 'alarm_red', name: 'Red Alert', path: 'alerts/alarm_red.wav', duration: 2.0 },
          { id: 'alarm_yellow', name: 'Yellow Alert', path: 'alerts/alarm_yellow.wav', duration: 1.5 },
          { id: 'alarm_general', name: 'General Quarters', path: 'alerts/alarm_general.wav', duration: 2.0 },
          { id: 'alarm_battle', name: 'Battle Stations', path: 'alerts/alarm_battle.wav', duration: 2.5 },
          { id: 'alarm_evacuation', name: 'Evacuation Alarm', path: 'alerts/alarm_evacuation.wav', duration: 3.0 },
          { id: 'alarm_silent', name: 'Silent Alarm', path: 'alerts/alarm_silent.wav', duration: 0.2 },
          { id: 'siren_loop', name: 'Siren Loop', path: 'alerts/siren_loop.wav', duration: 2.0 },
          { id: 'klaxon', name: 'Klaxon', path: 'alerts/klaxon.wav', duration: 1.5 },
          { id: 'buzzer', name: 'Buzzer', path: 'alerts/buzzer.wav', duration: 0.5 },
          { id: 'beep_rapid', name: 'Rapid Beep', path: 'alerts/beep_rapid.wav', duration: 1.0 },
          { id: 'achievement', name: 'Achievement', path: 'alerts/achievement.wav', duration: 0.8 },
          { id: 'achievement_rare', name: 'Rare Achievement', path: 'alerts/achievement_rare.wav', duration: 1.0 },
          { id: 'level_up', name: 'Level Up', path: 'alerts/level_up.wav', duration: 1.2 },
          { id: 'rank_up', name: 'Rank Up', path: 'alerts/rank_up.wav', duration: 1.5 },
          { id: 'quest_start', name: 'Quest Start', path: 'alerts/quest_start.wav', duration: 0.6 },
          { id: 'quest_update', name: 'Quest Update', path: 'alerts/quest_update.wav', duration: 0.5 },
          { id: 'quest_complete', name: 'Quest Complete', path: 'alerts/quest_complete.wav', duration: 1.0 },
          { id: 'objective_complete', name: 'Objective Complete', path: 'alerts/objective_complete.wav', duration: 0.6 },
          { id: 'mission_start', name: 'Mission Start', path: 'alerts/mission_start.wav', duration: 0.8 },
          { id: 'mission_complete', name: 'Mission Complete', path: 'alerts/mission_complete.wav', duration: 1.2 },
          { id: 'mission_failed', name: 'Mission Failed', path: 'alerts/mission_failed.wav', duration: 1.0 },
          { id: 'new_message', name: 'New Message', path: 'alerts/new_message.wav', duration: 0.4 },
          { id: 'transmission', name: 'Transmission', path: 'alerts/transmission.wav', duration: 0.5 },
          { id: 'scan_complete', name: 'Scan Complete', path: 'alerts/scan_complete.wav', duration: 0.4 },
          { id: 'discovery', name: 'Discovery', path: 'alerts/discovery.wav', duration: 0.8 },
          { id: 'unlock', name: 'Unlock', path: 'alerts/unlock.wav', duration: 0.5 },
          { id: 'timer_tick', name: 'Timer Tick', path: 'alerts/timer_tick.wav', duration: 0.1 }
        ]
      },
      ambient: {
        name: 'Ambient',
        icon: '🌌',
        sounds: [
          { id: 'space_void', name: 'Space Void', path: 'ambient/space_void.wav', duration: 30.0 },
          { id: 'space_nebula', name: 'Nebula', path: 'ambient/space_nebula.wav', duration: 30.0 },
          { id: 'space_asteroid', name: 'Asteroid Field', path: 'ambient/space_asteroid.wav', duration: 30.0 },
          { id: 'space_debris', name: 'Debris Field', path: 'ambient/space_debris.wav', duration: 30.0 },
          { id: 'space_solar', name: 'Solar Wind', path: 'ambient/space_solar.wav', duration: 30.0 },
          { id: 'ship_bridge', name: 'Ship Bridge', path: 'ambient/ship_bridge.wav', duration: 30.0 },
          { id: 'ship_engine_room', name: 'Engine Room', path: 'ambient/ship_engine_room.wav', duration: 30.0 },
          { id: 'ship_cargo_hold', name: 'Cargo Hold', path: 'ambient/ship_cargo_hold.wav', duration: 30.0 },
          { id: 'ship_quarters', name: 'Crew Quarters', path: 'ambient/ship_quarters.wav', duration: 30.0 },
          { id: 'ship_corridor', name: 'Corridor', path: 'ambient/ship_corridor.wav', duration: 30.0 },
          { id: 'ship_med_bay', name: 'Med Bay', path: 'ambient/ship_med_bay.wav', duration: 30.0 },
          { id: 'ship_damaged', name: 'Damaged Ship', path: 'ambient/ship_damaged.wav', duration: 30.0 },
          { id: 'station_hub', name: 'Station Hub', path: 'ambient/station_hub.wav', duration: 30.0 },
          { id: 'station_market', name: 'Station Market', path: 'ambient/station_market.wav', duration: 30.0 },
          { id: 'station_docking', name: 'Docking Bay', path: 'ambient/station_docking.wav', duration: 30.0 },
          { id: 'station_industrial', name: 'Industrial Zone', path: 'ambient/station_industrial.wav', duration: 30.0 },
          { id: 'station_residential', name: 'Residential Area', path: 'ambient/station_residential.wav', duration: 30.0 },
          { id: 'station_bar', name: 'Space Bar', path: 'ambient/station_bar.wav', duration: 30.0 },
          { id: 'station_casino', name: 'Casino', path: 'ambient/station_casino.wav', duration: 30.0 },
          { id: 'hideout_cave', name: 'Hideout Cave', path: 'ambient/hideout_cave.wav', duration: 30.0 },
          { id: 'hideout_bunker', name: 'Bunker', path: 'ambient/hideout_bunker.wav', duration: 30.0 },
          { id: 'derelict_ship', name: 'Derelict Ship', path: 'ambient/derelict_ship.wav', duration: 30.0 },
          { id: 'derelict_station', name: 'Abandoned Station', path: 'ambient/derelict_station.wav', duration: 30.0 },
          { id: 'engine_hum', name: 'Engine Hum', path: 'ambient/engine_hum.wav', duration: 10.0 },
          { id: 'reactor_hum', name: 'Reactor Hum', path: 'ambient/reactor_hum.wav', duration: 10.0 },
          { id: 'ventilation', name: 'Ventilation', path: 'ambient/ventilation.wav', duration: 10.0 },
          { id: 'electrical_hum', name: 'Electrical Hum', path: 'ambient/electrical_hum.wav', duration: 10.0 },
          { id: 'computer_hum', name: 'Computer Hum', path: 'ambient/computer_hum.wav', duration: 10.0 },
          { id: 'life_support', name: 'Life Support', path: 'ambient/life_support.wav', duration: 10.0 },
          { id: 'radiation_crackle', name: 'Radiation Crackle', path: 'ambient/radiation_crackle.wav', duration: 10.0 },
          { id: 'metal_creaks', name: 'Metal Creaks', path: 'ambient/metal_creaks.wav', duration: 10.0 },
          { id: 'pipe_drips', name: 'Pipe Drips', path: 'ambient/pipe_drips.wav', duration: 10.0 },
          { id: 'steam_vents', name: 'Steam Vents', path: 'ambient/steam_vents.wav', duration: 10.0 },
          { id: 'sparks', name: 'Electrical Sparks', path: 'ambient/sparks.wav', duration: 5.0 },
          { id: 'radio_static', name: 'Radio Static', path: 'ambient/radio_static.wav', duration: 10.0 },
          { id: 'radio_chatter', name: 'Radio Chatter', path: 'ambient/radio_chatter.wav', duration: 15.0 },
          { id: 'scanner_sweep', name: 'Scanner Sweep', path: 'ambient/scanner_sweep.wav', duration: 5.0 },
          { id: 'heartbeat', name: 'Heartbeat', path: 'ambient/heartbeat.wav', duration: 2.0 },
          { id: 'breathing', name: 'Breathing', path: 'ambient/breathing.wav', duration: 5.0 },
          { id: 'suit_breathing', name: 'Suit Breathing', path: 'ambient/suit_breathing.wav', duration: 5.0 },
          { id: 'distant_battle', name: 'Distant Battle', path: 'ambient/distant_battle.wav', duration: 20.0 },
          { id: 'danger_drone', name: 'Danger Drone', path: 'ambient/danger_drone.wav', duration: 15.0 },
          { id: 'tension_drone', name: 'Tension Drone', path: 'ambient/tension_drone.wav', duration: 20.0 },
          { id: 'mystery_drone', name: 'Mystery Drone', path: 'ambient/mystery_drone.wav', duration: 15.0 },
          { id: 'alarm_distant', name: 'Distant Alarm', path: 'ambient/alarm_distant.wav', duration: 10.0 },
          { id: 'crowd_murmur', name: 'Crowd Murmur', path: 'ambient/crowd_murmur.wav', duration: 20.0 },
          { id: 'machinery', name: 'Machinery', path: 'ambient/machinery.wav', duration: 15.0 },
          { id: 'wind_howl', name: 'Wind Howl', path: 'ambient/wind_howl.wav', duration: 10.0 },
          { id: 'airlock_pressure', name: 'Airlock Pressure', path: 'ambient/airlock_pressure.wav', duration: 5.0 },
          { id: 'zero_g', name: 'Zero G Ambience', path: 'ambient/zero_g.wav', duration: 20.0 }
        ]
      },
      footsteps: {
        name: 'Footsteps',
        icon: '👣',
        sounds: [
          { id: 'step_metal_1', name: 'Metal Step 1', path: 'footsteps/metal_1.wav', duration: 0.3 },
          { id: 'step_metal_2', name: 'Metal Step 2', path: 'footsteps/metal_2.wav', duration: 0.3 },
          { id: 'step_metal_3', name: 'Metal Step 3', path: 'footsteps/metal_3.wav', duration: 0.3 },
          { id: 'step_metal_run_1', name: 'Metal Run 1', path: 'footsteps/metal_run_1.wav', duration: 0.2 },
          { id: 'step_metal_run_2', name: 'Metal Run 2', path: 'footsteps/metal_run_2.wav', duration: 0.2 },
          { id: 'step_grate_1', name: 'Grate Step 1', path: 'footsteps/grate_1.wav', duration: 0.3 },
          { id: 'step_grate_2', name: 'Grate Step 2', path: 'footsteps/grate_2.wav', duration: 0.3 },
          { id: 'step_concrete_1', name: 'Concrete Step 1', path: 'footsteps/concrete_1.wav', duration: 0.3 },
          { id: 'step_concrete_2', name: 'Concrete Step 2', path: 'footsteps/concrete_2.wav', duration: 0.3 },
          { id: 'step_carpet_1', name: 'Carpet Step 1', path: 'footsteps/carpet_1.wav', duration: 0.25 },
          { id: 'step_carpet_2', name: 'Carpet Step 2', path: 'footsteps/carpet_2.wav', duration: 0.25 },
          { id: 'step_tile_1', name: 'Tile Step 1', path: 'footsteps/tile_1.wav', duration: 0.3 },
          { id: 'step_tile_2', name: 'Tile Step 2', path: 'footsteps/tile_2.wav', duration: 0.3 },
          { id: 'step_mud_1', name: 'Mud Step 1', path: 'footsteps/mud_1.wav', duration: 0.35 },
          { id: 'step_mud_2', name: 'Mud Step 2', path: 'footsteps/mud_2.wav', duration: 0.35 },
          { id: 'step_water_1', name: 'Water Step 1', path: 'footsteps/water_1.wav', duration: 0.3 },
          { id: 'step_water_2', name: 'Water Step 2', path: 'footsteps/water_2.wav', duration: 0.3 },
          { id: 'step_sand_1', name: 'Sand Step 1', path: 'footsteps/sand_1.wav', duration: 0.3 },
          { id: 'step_sand_2', name: 'Sand Step 2', path: 'footsteps/sand_2.wav', duration: 0.3 },
          { id: 'step_debris_1', name: 'Debris Step 1', path: 'footsteps/debris_1.wav', duration: 0.35 },
          { id: 'step_debris_2', name: 'Debris Step 2', path: 'footsteps/debris_2.wav', duration: 0.35 },
          { id: 'step_glass_1', name: 'Glass Step 1', path: 'footsteps/glass_1.wav', duration: 0.3 },
          { id: 'step_glass_2', name: 'Glass Step 2', path: 'footsteps/glass_2.wav', duration: 0.3 },
          { id: 'step_ladder_up', name: 'Ladder Up', path: 'footsteps/ladder_up.wav', duration: 0.4 },
          { id: 'step_ladder_down', name: 'Ladder Down', path: 'footsteps/ladder_down.wav', duration: 0.4 },
          { id: 'step_stairs_up', name: 'Stairs Up', path: 'footsteps/stairs_up.wav', duration: 0.35 },
          { id: 'step_stairs_down', name: 'Stairs Down', path: 'footsteps/stairs_down.wav', duration: 0.35 },
          { id: 'boot_heavy_1', name: 'Heavy Boot 1', path: 'footsteps/boot_heavy_1.wav', duration: 0.4 },
          { id: 'boot_heavy_2', name: 'Heavy Boot 2', path: 'footsteps/boot_heavy_2.wav', duration: 0.4 },
          { id: 'boot_light_1', name: 'Light Boot 1', path: 'footsteps/boot_light_1.wav', duration: 0.25 },
          { id: 'boot_light_2', name: 'Light Boot 2', path: 'footsteps/boot_light_2.wav', duration: 0.25 },
          { id: 'mag_boot_1', name: 'Mag Boot 1', path: 'footsteps/mag_boot_1.wav', duration: 0.4 },
          { id: 'mag_boot_2', name: 'Mag Boot 2', path: 'footsteps/mag_boot_2.wav', duration: 0.4 },
          { id: 'jump_start', name: 'Jump Start', path: 'footsteps/jump_start.wav', duration: 0.2 },
          { id: 'land_soft', name: 'Land Soft', path: 'footsteps/land_soft.wav', duration: 0.3 },
          { id: 'land_hard', name: 'Land Hard', path: 'footsteps/land_hard.wav', duration: 0.4 },
          { id: 'crouch', name: 'Crouch', path: 'footsteps/crouch.wav', duration: 0.25 },
          { id: 'stand', name: 'Stand', path: 'footsteps/stand.wav', duration: 0.25 },
          { id: 'roll', name: 'Roll', path: 'footsteps/roll.wav', duration: 0.5 },
          { id: 'slide', name: 'Slide', path: 'footsteps/slide.wav', duration: 0.6 },
          { id: 'stumble', name: 'Stumble', path: 'footsteps/stumble.wav', duration: 0.4 },
          { id: 'fall', name: 'Fall', path: 'footsteps/fall.wav', duration: 0.5 },
          { id: 'crawl_1', name: 'Crawl 1', path: 'footsteps/crawl_1.wav', duration: 0.5 },
          { id: 'crawl_2', name: 'Crawl 2', path: 'footsteps/crawl_2.wav', duration: 0.5 },
          { id: 'prone_move', name: 'Prone Move', path: 'footsteps/prone_move.wav', duration: 0.6 },
          { id: 'climb', name: 'Climb', path: 'footsteps/climb.wav', duration: 0.4 },
          { id: 'vault', name: 'Vault', path: 'footsteps/vault.wav', duration: 0.5 },
          { id: 'cloth_rustle', name: 'Cloth Rustle', path: 'footsteps/cloth_rustle.wav', duration: 0.3 },
          { id: 'gear_jingle', name: 'Gear Jingle', path: 'footsteps/gear_jingle.wav', duration: 0.25 },
          { id: 'armor_creak', name: 'Armor Creak', path: 'footsteps/armor_creak.wav', duration: 0.3 }
        ]
      },
      voices: {
        name: 'Voices',
        icon: '🗣️',
        sounds: [
          { id: 'grunt_effort_1', name: 'Effort Grunt 1', path: 'voices/grunt_effort_1.wav', duration: 0.3 },
          { id: 'grunt_effort_2', name: 'Effort Grunt 2', path: 'voices/grunt_effort_2.wav', duration: 0.3 },
          { id: 'grunt_pain_1', name: 'Pain Grunt 1', path: 'voices/grunt_pain_1.wav', duration: 0.4 },
          { id: 'grunt_pain_2', name: 'Pain Grunt 2', path: 'voices/grunt_pain_2.wav', duration: 0.4 },
          { id: 'grunt_heavy_1', name: 'Heavy Grunt 1', path: 'voices/grunt_heavy_1.wav', duration: 0.5 },
          { id: 'gasp', name: 'Gasp', path: 'voices/gasp.wav', duration: 0.3 },
          { id: 'cough', name: 'Cough', path: 'voices/cough.wav', duration: 0.4 },
          { id: 'choke', name: 'Choke', path: 'voices/choke.wav', duration: 0.5 },
          { id: 'death_1', name: 'Death 1', path: 'voices/death_1.wav', duration: 0.8 },
          { id: 'death_2', name: 'Death 2', path: 'voices/death_2.wav', duration: 0.6 },
          { id: 'scream', name: 'Scream', path: 'voices/scream.wav', duration: 1.0 },
          { id: 'yell', name: 'Yell', path: 'voices/yell.wav', duration: 0.5 },
          { id: 'battlecry', name: 'Battlecry', path: 'voices/battlecry.wav', duration: 0.8 },
          { id: 'taunt', name: 'Taunt', path: 'voices/taunt.wav', duration: 0.6 },
          { id: 'laugh_evil', name: 'Evil Laugh', path: 'voices/laugh_evil.wav', duration: 1.2 },
          { id: 'laugh_nervous', name: 'Nervous Laugh', path: 'voices/laugh_nervous.wav', duration: 0.8 },
          { id: 'affirmative', name: 'Affirmative', path: 'voices/affirmative.wav', duration: 0.4 },
          { id: 'negative', name: 'Negative', path: 'voices/negative.wav', duration: 0.4 },
          { id: 'roger', name: 'Roger', path: 'voices/roger.wav', duration: 0.3 },
          { id: 'copy_that', name: 'Copy That', path: 'voices/copy_that.wav', duration: 0.4 },
          { id: 'command_attack', name: 'Attack!', path: 'voices/command_attack.wav', duration: 0.5 },
          { id: 'command_retreat', name: 'Retreat!', path: 'voices/command_retreat.wav', duration: 0.5 },
          { id: 'command_hold', name: 'Hold!', path: 'voices/command_hold.wav', duration: 0.4 },
          { id: 'command_go', name: 'Go Go Go!', path: 'voices/command_go.wav', duration: 0.5 },
          { id: 'alert_contact', name: 'Contact!', path: 'voices/alert_contact.wav', duration: 0.4 },
          { id: 'alert_enemy_spotted', name: 'Enemy Spotted', path: 'voices/alert_enemy_spotted.wav', duration: 0.6 },
          { id: 'alert_man_down', name: 'Man Down!', path: 'voices/alert_man_down.wav', duration: 0.5 },
          { id: 'alert_grenade', name: 'Grenade!', path: 'voices/alert_grenade.wav', duration: 0.4 },
          { id: 'alert_sniper', name: 'Sniper!', path: 'voices/alert_sniper.wav', duration: 0.4 },
          { id: 'call_medic', name: 'Medic!', path: 'voices/call_medic.wav', duration: 0.5 },
          { id: 'call_cover', name: 'Cover Me!', path: 'voices/call_cover.wav', duration: 0.5 },
          { id: 'call_help', name: 'Help!', path: 'voices/call_help.wav', duration: 0.5 },
          { id: 'call_backup', name: 'Need Backup!', path: 'voices/call_backup.wav', duration: 0.6 },
          { id: 'reloading', name: 'Reloading!', path: 'voices/reloading.wav', duration: 0.4 },
          { id: 'out_of_ammo', name: 'Out of Ammo!', path: 'voices/out_of_ammo.wav', duration: 0.5 },
          { id: 'clear', name: 'Clear!', path: 'voices/clear.wav', duration: 0.3 },
          { id: 'target_down', name: 'Target Down', path: 'voices/target_down.wav', duration: 0.5 },
          { id: 'nice_shot', name: 'Nice Shot!', path: 'voices/nice_shot.wav', duration: 0.5 },
          { id: 'got_him', name: 'Got Him!', path: 'voices/got_him.wav', duration: 0.4 },
          { id: 'thanks', name: 'Thanks', path: 'voices/thanks.wav', duration: 0.3 },
          { id: 'sorry', name: 'Sorry', path: 'voices/sorry.wav', duration: 0.3 },
          { id: 'understood', name: 'Understood', path: 'voices/understood.wav', duration: 0.4 },
          { id: 'on_my_way', name: 'On My Way', path: 'voices/on_my_way.wav', duration: 0.5 },
          { id: 'i_got_this', name: "I Got This", path: 'voices/i_got_this.wav', duration: 0.5 },
          { id: 'lets_go', name: "Let's Go", path: 'voices/lets_go.wav', duration: 0.4 },
          { id: 'watch_out', name: 'Watch Out!', path: 'voices/watch_out.wav', duration: 0.5 },
          { id: 'behind_you', name: 'Behind You!', path: 'voices/behind_you.wav', duration: 0.6 },
          { id: 'robot_beep', name: 'Robot Beep', path: 'voices/robot_beep.wav', duration: 0.3 },
          { id: 'robot_chirp', name: 'Robot Chirp', path: 'voices/robot_chirp.wav', duration: 0.4 },
          { id: 'robot_confirm', name: 'Robot Confirm', path: 'voices/robot_confirm.wav', duration: 0.3 }
        ]
      },
      impacts: {
        name: 'Impacts',
        icon: '💢',
        sounds: [
          { id: 'impact_metal_light', name: 'Metal Light', path: 'impacts/metal_light.wav', duration: 0.2 },
          { id: 'impact_metal_medium', name: 'Metal Medium', path: 'impacts/metal_medium.wav', duration: 0.3 },
          { id: 'impact_metal_heavy', name: 'Metal Heavy', path: 'impacts/metal_heavy.wav', duration: 0.5 },
          { id: 'impact_metal_clang', name: 'Metal Clang', path: 'impacts/metal_clang.wav', duration: 0.4 },
          { id: 'impact_metal_thud', name: 'Metal Thud', path: 'impacts/metal_thud.wav', duration: 0.3 },
          { id: 'impact_metal_ring', name: 'Metal Ring', path: 'impacts/metal_ring.wav', duration: 0.6 },
          { id: 'impact_concrete', name: 'Concrete Impact', path: 'impacts/concrete.wav', duration: 0.3 },
          { id: 'impact_wood', name: 'Wood Impact', path: 'impacts/wood.wav', duration: 0.25 },
          { id: 'impact_glass', name: 'Glass Impact', path: 'impacts/glass.wav', duration: 0.2 },
          { id: 'impact_glass_break', name: 'Glass Break', path: 'impacts/glass_break.wav', duration: 0.5 },
          { id: 'impact_plastic', name: 'Plastic Impact', path: 'impacts/plastic.wav', duration: 0.2 },
          { id: 'impact_flesh', name: 'Flesh Impact', path: 'impacts/flesh.wav', duration: 0.2 },
          { id: 'impact_punch', name: 'Punch', path: 'impacts/punch.wav', duration: 0.2 },
          { id: 'impact_kick', name: 'Kick', path: 'impacts/kick.wav', duration: 0.25 },
          { id: 'impact_slap', name: 'Slap', path: 'impacts/slap.wav', duration: 0.15 },
          { id: 'impact_body_fall', name: 'Body Fall', path: 'impacts/body_fall.wav', duration: 0.5 },
          { id: 'impact_collision_small', name: 'Small Collision', path: 'impacts/collision_small.wav', duration: 0.3 },
          { id: 'impact_collision_medium', name: 'Medium Collision', path: 'impacts/collision_medium.wav', duration: 0.5 },
          { id: 'impact_collision_large', name: 'Large Collision', path: 'impacts/collision_large.wav', duration: 0.8 },
          { id: 'impact_crash', name: 'Crash', path: 'impacts/crash.wav', duration: 1.0 },
          { id: 'impact_crunch', name: 'Crunch', path: 'impacts/crunch.wav', duration: 0.3 },
          { id: 'impact_squish', name: 'Squish', path: 'impacts/squish.wav', duration: 0.25 },
          { id: 'impact_splat', name: 'Splat', path: 'impacts/splat.wav', duration: 0.3 },
          { id: 'impact_thump', name: 'Thump', path: 'impacts/thump.wav', duration: 0.25 },
          { id: 'impact_boom', name: 'Boom', path: 'impacts/boom.wav', duration: 0.5 },
          { id: 'impact_whomp', name: 'Whomp', path: 'impacts/whomp.wav', duration: 0.4 },
          { id: 'debris_fall_small', name: 'Small Debris', path: 'impacts/debris_fall_small.wav', duration: 0.4 },
          { id: 'debris_fall_large', name: 'Large Debris', path: 'impacts/debris_fall_large.wav', duration: 0.8 },
          { id: 'debris_scatter', name: 'Debris Scatter', path: 'impacts/debris_scatter.wav', duration: 0.6 },
          { id: 'rock_impact', name: 'Rock Impact', path: 'impacts/rock_impact.wav', duration: 0.4 },
          { id: 'bullet_impact', name: 'Bullet Impact', path: 'impacts/bullet_impact.wav', duration: 0.15 },
          { id: 'ricochet_1', name: 'Ricochet 1', path: 'impacts/ricochet_1.wav', duration: 0.3 },
          { id: 'ricochet_2', name: 'Ricochet 2', path: 'impacts/ricochet_2.wav', duration: 0.35 },
          { id: 'ricochet_3', name: 'Ricochet 3', path: 'impacts/ricochet_3.wav', duration: 0.25 },
          { id: 'shatter', name: 'Shatter', path: 'impacts/shatter.wav', duration: 0.6 },
          { id: 'snap', name: 'Snap', path: 'impacts/snap.wav', duration: 0.15 },
          { id: 'crack', name: 'Crack', path: 'impacts/crack.wav', duration: 0.2 },
          { id: 'tear', name: 'Tear', path: 'impacts/tear.wav', duration: 0.3 },
          { id: 'rip', name: 'Rip', path: 'impacts/rip.wav', duration: 0.25 },
          { id: 'cut', name: 'Cut', path: 'impacts/cut.wav', duration: 0.15 },
          { id: 'slash', name: 'Slash', path: 'impacts/slash.wav', duration: 0.2 },
          { id: 'stab', name: 'Stab', path: 'impacts/stab.wav', duration: 0.15 },
          { id: 'bash', name: 'Bash', path: 'impacts/bash.wav', duration: 0.3 },
          { id: 'smash', name: 'Smash', path: 'impacts/smash.wav', duration: 0.5 },
          { id: 'crush', name: 'Crush', path: 'impacts/crush.wav', duration: 0.4 },
          { id: 'stomp', name: 'Stomp', path: 'impacts/stomp.wav', duration: 0.3 },
          { id: 'dropkick', name: 'Dropkick', path: 'impacts/dropkick.wav', duration: 0.4 },
          { id: 'slam', name: 'Slam', path: 'impacts/slam.wav', duration: 0.5 },
          { id: 'wreck', name: 'Wreck', path: 'impacts/wreck.wav', duration: 0.8 },
          { id: 'demolish', name: 'Demolish', path: 'impacts/demolish.wav', duration: 1.0 }
        ]
      },
      music: {
        name: 'Music',
        icon: '🎼',
        sounds: [
          { id: 'music_menu_main', name: 'Main Menu', path: 'music/menu_main.ogg', duration: 120.0 },
          { id: 'music_menu_options', name: 'Options Menu', path: 'music/menu_options.ogg', duration: 60.0 },
          { id: 'music_intro', name: 'Intro Theme', path: 'music/intro.ogg', duration: 90.0 },
          { id: 'music_exploration_calm', name: 'Calm Exploration', path: 'music/exploration_calm.ogg', duration: 180.0 },
          { id: 'music_exploration_wonder', name: 'Wonder', path: 'music/exploration_wonder.ogg', duration: 150.0 },
          { id: 'music_exploration_mystery', name: 'Mystery', path: 'music/exploration_mystery.ogg', duration: 120.0 },
          { id: 'music_exploration_danger', name: 'Danger Zone', path: 'music/exploration_danger.ogg', duration: 120.0 },
          { id: 'music_combat_light', name: 'Light Combat', path: 'music/combat_light.ogg', duration: 120.0 },
          { id: 'music_combat_medium', name: 'Medium Combat', path: 'music/combat_medium.ogg', duration: 150.0 },
          { id: 'music_combat_intense', name: 'Intense Combat', path: 'music/combat_intense.ogg', duration: 180.0 },
          { id: 'music_combat_desperate', name: 'Desperate Fight', path: 'music/combat_desperate.ogg', duration: 120.0 },
          { id: 'music_boss_intro', name: 'Boss Intro', path: 'music/boss_intro.ogg', duration: 30.0 },
          { id: 'music_boss_phase1', name: 'Boss Phase 1', path: 'music/boss_phase1.ogg', duration: 180.0 },
          { id: 'music_boss_phase2', name: 'Boss Phase 2', path: 'music/boss_phase2.ogg', duration: 180.0 },
          { id: 'music_boss_final', name: 'Final Boss', path: 'music/boss_final.ogg', duration: 240.0 },
          { id: 'music_victory_small', name: 'Small Victory', path: 'music/victory_small.ogg', duration: 15.0 },
          { id: 'music_victory_major', name: 'Major Victory', path: 'music/victory_major.ogg', duration: 30.0 },
          { id: 'music_victory_final', name: 'Final Victory', path: 'music/victory_final.ogg', duration: 60.0 },
          { id: 'music_defeat', name: 'Defeat', path: 'music/defeat.ogg', duration: 20.0 },
          { id: 'music_gameover', name: 'Game Over', path: 'music/gameover.ogg', duration: 30.0 },
          { id: 'music_hideout_relaxed', name: 'Hideout Relaxed', path: 'music/hideout_relaxed.ogg', duration: 180.0 },
          { id: 'music_hideout_busy', name: 'Hideout Busy', path: 'music/hideout_busy.ogg', duration: 120.0 },
          { id: 'music_station_hub', name: 'Station Hub', path: 'music/station_hub.ogg', duration: 180.0 },
          { id: 'music_station_market', name: 'Market', path: 'music/station_market.ogg', duration: 150.0 },
          { id: 'music_station_shady', name: 'Shady District', path: 'music/station_shady.ogg', duration: 120.0 },
          { id: 'music_tension_low', name: 'Low Tension', path: 'music/tension_low.ogg', duration: 120.0 },
          { id: 'music_tension_medium', name: 'Medium Tension', path: 'music/tension_medium.ogg', duration: 120.0 },
          { id: 'music_tension_high', name: 'High Tension', path: 'music/tension_high.ogg', duration: 120.0 },
          { id: 'music_suspense', name: 'Suspense', path: 'music/suspense.ogg', duration: 90.0 },
          { id: 'music_chase', name: 'Chase', path: 'music/chase.ogg', duration: 180.0 },
          { id: 'music_escape', name: 'Escape', path: 'music/escape.ogg', duration: 150.0 },
          { id: 'music_stealth', name: 'Stealth', path: 'music/stealth.ogg', duration: 180.0 },
          { id: 'music_boarding_prep', name: 'Boarding Prep', path: 'music/boarding_prep.ogg', duration: 60.0 },
          { id: 'music_boarding_action', name: 'Boarding Action', path: 'music/boarding_action.ogg', duration: 180.0 },
          { id: 'music_pirate', name: 'Pirate Theme', path: 'music/pirate.ogg', duration: 120.0 },
          { id: 'music_empire', name: 'Empire Theme', path: 'music/empire.ogg', duration: 120.0 },
          { id: 'music_rebel', name: 'Rebel Theme', path: 'music/rebel.ogg', duration: 120.0 },
          { id: 'music_alien', name: 'Alien Theme', path: 'music/alien.ogg', duration: 150.0 },
          { id: 'music_derelict', name: 'Derelict Ship', path: 'music/derelict.ogg', duration: 180.0 },
          { id: 'music_horror', name: 'Horror', path: 'music/horror.ogg', duration: 120.0 },
          { id: 'music_sad', name: 'Sad Theme', path: 'music/sad.ogg', duration: 90.0 },
          { id: 'music_emotional', name: 'Emotional', path: 'music/emotional.ogg', duration: 120.0 },
          { id: 'music_heroic', name: 'Heroic', path: 'music/heroic.ogg', duration: 120.0 },
          { id: 'music_credits', name: 'Credits', path: 'music/credits.ogg', duration: 300.0 },
          { id: 'stinger_discovery', name: 'Discovery Stinger', path: 'music/stinger_discovery.ogg', duration: 5.0 },
          { id: 'stinger_danger', name: 'Danger Stinger', path: 'music/stinger_danger.ogg', duration: 3.0 },
          { id: 'stinger_success', name: 'Success Stinger', path: 'music/stinger_success.ogg', duration: 4.0 },
          { id: 'stinger_fail', name: 'Fail Stinger', path: 'music/stinger_fail.ogg', duration: 3.0 },
          { id: 'stinger_reveal', name: 'Reveal Stinger', path: 'music/stinger_reveal.ogg', duration: 5.0 }
        ]
      }
    };
    // Initialize DAW Sound Studio
    function initSoundStudio() {
      if (!dawState.audioContext) {
        dawState.audioContext = new (window.AudioContext || window.webkitAudioContext)();
      }
      renderBrowserSounds();
      renderTimeline();
      renderMixer();
      updateDawCode();
    }
    
    // Find sound by ID across all categories
    function findSoundById(soundId) {
      for (const catKey in SOUND_LIBRARY) {
        const found = SOUND_LIBRARY[catKey].sounds.find(s => s.id === soundId);
        if (found) return { ...found, category: catKey };
      }
      return null;
    }
    
    // Select category in browser
    function selectCategory(category) {
      dawState.activeCategory = category;
      document.querySelectorAll('.cat-btn').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.cat === category);
      });
      renderBrowserSounds();
    }
    
    // Filter sounds by search
    function filterSounds(query) {
      renderBrowserSounds(query.toLowerCase());
    }
    
    // Render sound browser
    function renderBrowserSounds(filter = '') {
      const container = document.getElementById('browserSounds');
      if (!container) return;
      
      let sounds = [];
      if (dawState.activeCategory === 'all') {
        for (const cat in SOUND_LIBRARY) {
          sounds = sounds.concat(SOUND_LIBRARY[cat].sounds.map(s => ({ ...s, category: cat })));
        }
      } else if (SOUND_LIBRARY[dawState.activeCategory]) {
        sounds = SOUND_LIBRARY[dawState.activeCategory].sounds.map(s => ({ ...s, category: dawState.activeCategory }));
      }
      
      if (filter) {
        sounds = sounds.filter(s => s.name.toLowerCase().includes(filter) || s.path.toLowerCase().includes(filter));
      }
      
      const html = sounds.slice(0, 100).map(sound => {
        const icon = SOUND_LIBRARY[sound.category]?.icon || '🎵';
        return '<div class="sound-item" draggable="true" ondragstart="handleSoundDrag(event, \\'' + sound.id + '\\')" ondblclick="addSoundToTimeline(\\'' + sound.id + '\\')">' +
          '<span class="sound-icon">' + icon + '</span>' +
          '<div class="sound-info">' +
            '<div class="sound-name">' + sound.name + '</div>' +
            '<div class="sound-meta">' + (sound.duration ? sound.duration.toFixed(1) + 's' : '') + '</div>' +
          '</div>' +
          '<button class="sound-preview-btn" onclick="previewSound(\\'' + sound.id + '\\')">▶</button>' +
        '</div>';
      }).join('');
      
      container.innerHTML = html || '<div style="padding: 1rem; color: var(--text-muted); text-align: center;">No sounds found</div>';
    }
    
    // Handle drag from browser
    function handleSoundDrag(event, soundId) {
      event.dataTransfer.setData('text/plain', soundId);
      event.dataTransfer.effectAllowed = 'copy';
    }
    
    // Preview a sound - with proper audio context initialization
    function previewSound(soundId) {
      const sound = findSoundById(soundId);
      if (!sound) {
        showToast('Sound not found: ' + soundId, 'error');
        return;
      }
      
      // Always create/resume audio context on user interaction
      if (!dawState.audioContext) {
        dawState.audioContext = new (window.AudioContext || window.webkitAudioContext)();
      }
      
      // Resume if suspended (required by browsers)
      if (dawState.audioContext.state === 'suspended') {
        dawState.audioContext.resume();
      }
      
      const audioCtx = dawState.audioContext;
      
      // Generate unique hash from sound ID for consistent but varied sounds
      const hash = soundId.split('').reduce((a, c) => ((a << 5) - a + c.charCodeAt(0)) | 0, 0);
      const absHash = Math.abs(hash);
      
      // Sound synthesis parameters based on category and unique hash
      const synth = getSynthParams(sound.category, sound.id, absHash);
      
      const now = audioCtx.currentTime;
      const duration = synth.duration;
      
      // Create nodes based on synth type
      if (synth.type === 'noise') {
        // White/pink noise for explosions, impacts, footsteps
        const bufferSize = audioCtx.sampleRate * duration;
        const buffer = audioCtx.createBuffer(1, bufferSize, audioCtx.sampleRate);
        const data = buffer.getChannelData(0);
        
        for (let i = 0; i < bufferSize; i++) {
          data[i] = (Math.random() * 2 - 1) * synth.noiseDecay(i / bufferSize);
        }
        
        const source = audioCtx.createBufferSource();
        source.buffer = buffer;
        
        const filter = audioCtx.createBiquadFilter();
        filter.type = synth.filterType || 'lowpass';
        filter.frequency.value = synth.filterFreq;
        filter.Q.value = synth.filterQ || 1;
        
        const gain = audioCtx.createGain();
        gain.gain.setValueAtTime(synth.volume, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + duration);
        
        source.connect(filter);
        filter.connect(gain);
        gain.connect(audioCtx.destination);
        source.start(now);
        
      } else if (synth.type === 'multi') {
        // Multiple oscillators for complex sounds
        synth.oscillators.forEach(oscParams => {
          const osc = audioCtx.createOscillator();
          const gain = audioCtx.createGain();
          
          osc.type = oscParams.wave;
          osc.frequency.setValueAtTime(oscParams.freq, now);
          
          if (oscParams.freqEnd) {
            osc.frequency.exponentialRampToValueAtTime(oscParams.freqEnd, now + duration * 0.8);
          }
          if (oscParams.vibrato) {
            const lfo = audioCtx.createOscillator();
            const lfoGain = audioCtx.createGain();
            lfo.frequency.value = oscParams.vibrato.rate;
            lfoGain.gain.value = oscParams.vibrato.depth;
            lfo.connect(lfoGain);
            lfoGain.connect(osc.frequency);
            lfo.start(now);
            lfo.stop(now + duration);
          }
          
          gain.gain.setValueAtTime(0, now);
          gain.gain.linearRampToValueAtTime(oscParams.volume * synth.volume, now + (oscParams.attack || 0.01));
          gain.gain.setValueAtTime(oscParams.volume * synth.volume, now + duration * 0.3);
          gain.gain.exponentialRampToValueAtTime(0.001, now + duration);
          
          osc.connect(gain);
          gain.connect(audioCtx.destination);
          osc.start(now + (oscParams.delay || 0));
          osc.stop(now + duration);
        });
        
      } else {
        // Single oscillator with envelope
        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        
        osc.type = synth.wave;
        osc.frequency.setValueAtTime(synth.freq, now);
        
        if (synth.freqEnd) {
          osc.frequency.exponentialRampToValueAtTime(synth.freqEnd, now + duration * 0.7);
        }
        if (synth.freqModulate) {
          osc.frequency.setValueAtTime(synth.freq, now);
          osc.frequency.linearRampToValueAtTime(synth.freqModulate, now + duration * 0.5);
          osc.frequency.linearRampToValueAtTime(synth.freq * 0.8, now + duration);
        }
        
        // ADSR envelope
        gain.gain.setValueAtTime(0, now);
        gain.gain.linearRampToValueAtTime(synth.volume, now + synth.attack);
        gain.gain.setValueAtTime(synth.volume * synth.sustain, now + synth.attack + 0.02);
        gain.gain.exponentialRampToValueAtTime(0.001, now + duration);
        
        // Optional filter
        if (synth.filter) {
          const filter = audioCtx.createBiquadFilter();
          filter.type = synth.filter.type;
          filter.frequency.value = synth.filter.freq;
          filter.Q.value = synth.filter.Q || 1;
          osc.connect(filter);
          filter.connect(gain);
        } else {
          osc.connect(gain);
        }
        
        gain.connect(audioCtx.destination);
        osc.start(now);
        osc.stop(now + duration);
      }
      
      showToast('Preview: ' + sound.name, 'info');
    }
    
    // Get synthesis parameters based on category and sound ID
    function getSynthParams(category, soundId, hash) {
      const variation = (hash % 100) / 100; // 0-1 variation factor
      const pitch = 0.8 + (hash % 50) / 100; // 0.8-1.3 pitch multiplier
      
      // Category-specific sound design
      const params = {
        ui: () => {
          const isClick = soundId.includes('click');
          const isHover = soundId.includes('hover');
          const isConfirm = soundId.includes('confirm') || soundId.includes('success');
          const isCancel = soundId.includes('cancel') || soundId.includes('error') || soundId.includes('fail');
          const isNotify = soundId.includes('notification') || soundId.includes('alert') || soundId.includes('popup');
          const isMenu = soundId.includes('menu') || soundId.includes('open') || soundId.includes('close');
          const isToggle = soundId.includes('toggle') || soundId.includes('switch');
          const isScroll = soundId.includes('scroll') || soundId.includes('slide');
          
          if (isClick) return { type: 'single', wave: 'sine', freq: 800 + hash % 400, freqEnd: 600, duration: 0.08, attack: 0.005, sustain: 0.5, volume: 0.25 };
          if (isHover) return { type: 'single', wave: 'sine', freq: 1200 + hash % 300, duration: 0.05, attack: 0.01, sustain: 0.3, volume: 0.15 };
          if (isConfirm) return { type: 'multi', duration: 0.25, volume: 0.2, oscillators: [
            { wave: 'sine', freq: 523 * pitch, volume: 0.6, attack: 0.01 },
            { wave: 'sine', freq: 659 * pitch, volume: 0.5, attack: 0.01, delay: 0.05 },
            { wave: 'sine', freq: 784 * pitch, volume: 0.4, attack: 0.01, delay: 0.1 }
          ]};
          if (isCancel) return { type: 'multi', duration: 0.2, volume: 0.2, oscillators: [
            { wave: 'sawtooth', freq: 300 * pitch, freqEnd: 150, volume: 0.4, attack: 0.01 },
            { wave: 'square', freq: 200 * pitch, freqEnd: 100, volume: 0.2, attack: 0.01 }
          ]};
          if (isNotify) return { type: 'multi', duration: 0.4, volume: 0.18, oscillators: [
            { wave: 'sine', freq: 880 * pitch, volume: 0.5, attack: 0.02 },
            { wave: 'sine', freq: 1108 * pitch, volume: 0.3, attack: 0.02, delay: 0.1 }
          ]};
          if (isMenu) return { type: 'single', wave: 'sine', freq: soundId.includes('open') ? 400 : 350, freqEnd: soundId.includes('open') ? 600 : 250, duration: 0.12, attack: 0.02, sustain: 0.6, volume: 0.2 };
          if (isToggle) return { type: 'single', wave: 'triangle', freq: 600 + (hash % 2) * 200, duration: 0.1, attack: 0.01, sustain: 0.5, volume: 0.2 };
          if (isScroll) return { type: 'single', wave: 'sine', freq: 1500 + hash % 500, duration: 0.03, attack: 0.005, sustain: 0.3, volume: 0.1 };
          return { type: 'single', wave: 'sine', freq: 700 + hash % 500, duration: 0.1, attack: 0.01, sustain: 0.5, volume: 0.2 };
        },
        
        combat: () => {
          const isLaser = soundId.includes('laser');
          const isPlasma = soundId.includes('plasma');
          const isMissile = soundId.includes('missile') || soundId.includes('torpedo');
          const isRailgun = soundId.includes('railgun') || soundId.includes('cannon');
          const isShield = soundId.includes('shield');
          const isHull = soundId.includes('hull');
          const isCharge = soundId.includes('charge');
          const isHit = soundId.includes('hit');
          
          if (isLaser) {
            const intensity = soundId.includes('heavy') ? 0.8 : soundId.includes('light') ? 0.4 : 0.6;
            return { type: 'single', wave: 'sawtooth', freq: 150 + hash % 100 + intensity * 100, freqEnd: 80, duration: 0.15 + intensity * 0.15, attack: 0.005, sustain: 0.7, volume: 0.2 + intensity * 0.1, filter: { type: 'lowpass', freq: 2000 + intensity * 1000, Q: 2 } };
          }
          if (isPlasma) return { type: 'multi', duration: 0.3, volume: 0.22, oscillators: [
            { wave: 'sawtooth', freq: 100 * pitch, freqEnd: 60, volume: 0.5 },
            { wave: 'sine', freq: 200 * pitch, freqEnd: 80, volume: 0.4, vibrato: { rate: 30, depth: 20 } }
          ]};
          if (isMissile) return { type: 'multi', duration: 0.4, volume: 0.25, oscillators: [
            { wave: 'sawtooth', freq: 80, freqEnd: 200, volume: 0.4, attack: 0.1 },
            { wave: 'square', freq: 60, volume: 0.3, vibrato: { rate: 15, depth: 10 } }
          ]};
          if (isRailgun) return { type: 'noise', duration: 0.25, volume: 0.3, filterType: 'bandpass', filterFreq: 800 + hash % 400, filterQ: 3, noiseDecay: t => Math.exp(-t * 8) };
          if (isShield && isHit) return { type: 'multi', duration: 0.2, volume: 0.2, oscillators: [
            { wave: 'sine', freq: 300 + hash % 200, freqEnd: 150, volume: 0.5 },
            { wave: 'triangle', freq: 600 + hash % 300, freqEnd: 200, volume: 0.3 }
          ]};
          if (isShield) return { type: 'single', wave: 'sine', freq: 200 + hash % 100, freqModulate: 400 + hash % 200, duration: 0.3, attack: 0.05, sustain: 0.6, volume: 0.2 };
          if (isHull) return { type: 'noise', duration: 0.15, volume: 0.25, filterType: 'lowpass', filterFreq: 600 + hash % 400, noiseDecay: t => Math.exp(-t * 12) };
          if (isCharge) return { type: 'single', wave: 'sawtooth', freq: 100, freqEnd: 800, duration: 0.5, attack: 0.4, sustain: 0.8, volume: 0.15, filter: { type: 'lowpass', freq: 1500, Q: 5 } };
          return { type: 'single', wave: 'sawtooth', freq: 200 + hash % 150, freqEnd: 100, duration: 0.2, attack: 0.01, sustain: 0.6, volume: 0.2 };
        },
        
        explosions: () => {
          const size = soundId.includes('tiny') ? 0.3 : soundId.includes('small') ? 0.5 : soundId.includes('medium') ? 0.7 : soundId.includes('large') || soundId.includes('massive') ? 1.0 : soundId.includes('nuclear') ? 1.5 : 0.6;
          return { type: 'noise', duration: 0.3 + size * 0.5, volume: 0.15 + size * 0.15, filterType: 'lowpass', filterFreq: 300 + size * 400 + hash % 200, filterQ: 1 + size, noiseDecay: t => Math.pow(1 - t, 1.5 + size) * (1 + Math.sin(t * 50) * 0.2 * (1 - t)) };
        },
        
        ship: () => {
          const isEngine = soundId.includes('engine') || soundId.includes('thruster');
          const isBoost = soundId.includes('boost') || soundId.includes('afterburner');
          const isDock = soundId.includes('dock') || soundId.includes('undock');
          const isHyper = soundId.includes('hyperspace') || soundId.includes('warp') || soundId.includes('jump');
          const isCargo = soundId.includes('cargo') || soundId.includes('bay');
          const isSystem = soundId.includes('power') || soundId.includes('system');
          
          if (isEngine) return { type: 'multi', duration: 0.4, volume: 0.15, oscillators: [
            { wave: 'sawtooth', freq: 60 + hash % 30, volume: 0.4, vibrato: { rate: 8, depth: 5 } },
            { wave: 'triangle', freq: 120 + hash % 40, volume: 0.3 }
          ]};
          if (isBoost) return { type: 'single', wave: 'sawtooth', freq: 80, freqEnd: 200, duration: 0.35, attack: 0.1, sustain: 0.8, volume: 0.22, filter: { type: 'lowpass', freq: 1200, Q: 3 } };
          if (isDock) return { type: 'multi', duration: 0.5, volume: 0.18, oscillators: [
            { wave: 'sine', freq: 200, freqEnd: soundId.includes('undock') ? 300 : 150, volume: 0.4 },
            { wave: 'square', freq: 100, volume: 0.2, attack: 0.2 }
          ]};
          if (isHyper) return { type: 'single', wave: 'sawtooth', freq: soundId.includes('enter') || soundId.includes('engage') ? 100 : 800, freqEnd: soundId.includes('enter') || soundId.includes('engage') ? 2000 : 100, duration: 0.6, attack: 0.2, sustain: 0.9, volume: 0.2, filter: { type: 'lowpass', freq: 3000, Q: 2 } };
          if (isCargo) return { type: 'noise', duration: 0.25, volume: 0.15, filterType: 'bandpass', filterFreq: 400 + hash % 200, filterQ: 2, noiseDecay: t => 1 - t };
          if (isSystem) return { type: 'multi', duration: 0.3, volume: 0.15, oscillators: [
            { wave: 'sine', freq: 440, volume: 0.3 },
            { wave: 'sine', freq: 554, volume: 0.25, delay: 0.05 },
            { wave: 'sine', freq: 659, volume: 0.2, delay: 0.1 }
          ]};
          return { type: 'single', wave: 'triangle', freq: 150 + hash % 100, duration: 0.25, attack: 0.05, sustain: 0.6, volume: 0.18 };
        },
        
        boarding: () => {
          const isGrapple = soundId.includes('grapple');
          const isAirlock = soundId.includes('airlock');
          const isBreach = soundId.includes('breach');
          const isFight = soundId.includes('fight') || soundId.includes('combat') || soundId.includes('melee');
          const isSuccess = soundId.includes('success') || soundId.includes('victory');
          
          if (isGrapple) return { type: 'multi', duration: 0.35, volume: 0.2, oscillators: [
            { wave: 'sawtooth', freq: 150, freqEnd: soundId.includes('connect') ? 80 : 300, volume: 0.4 },
            { wave: 'square', freq: 80, volume: 0.2, vibrato: { rate: 20, depth: 15 } }
          ]};
          if (isAirlock) return { type: 'noise', duration: 0.4, volume: 0.2, filterType: 'bandpass', filterFreq: soundId.includes('open') ? 600 : 400, filterQ: 2, noiseDecay: t => soundId.includes('open') ? t < 0.5 ? t * 2 : 2 - t * 2 : 1 - t };
          if (isBreach) return { type: 'noise', duration: 0.5, volume: 0.25, filterType: 'highpass', filterFreq: 800 + hash % 400, filterQ: 1, noiseDecay: t => Math.exp(-t * 3) * (1 + Math.sin(t * 100) * 0.3) };
          if (isFight) return { type: 'noise', duration: 0.12, volume: 0.2, filterType: 'bandpass', filterFreq: 1000 + hash % 500, filterQ: 3, noiseDecay: t => Math.exp(-t * 15) };
          if (isSuccess) return { type: 'multi', duration: 0.4, volume: 0.2, oscillators: [
            { wave: 'sine', freq: 392, volume: 0.4 },
            { wave: 'sine', freq: 523, volume: 0.35, delay: 0.08 },
            { wave: 'sine', freq: 659, volume: 0.3, delay: 0.16 },
            { wave: 'sine', freq: 784, volume: 0.25, delay: 0.24 }
          ]};
          return { type: 'single', wave: 'square', freq: 200 + hash % 150, freqEnd: 100, duration: 0.2, attack: 0.02, sustain: 0.5, volume: 0.18 };
        },
        
        loot: () => {
          const rarity = soundId.includes('legendary') ? 5 : soundId.includes('epic') ? 4 : soundId.includes('rare') ? 3 : soundId.includes('uncommon') ? 2 : 1;
          const isPickup = soundId.includes('pickup') || soundId.includes('collect');
          const isInventory = soundId.includes('inventory') || soundId.includes('equip') || soundId.includes('unequip');
          const isCraft = soundId.includes('craft') || soundId.includes('upgrade') || soundId.includes('enchant');
          
          if (isPickup) {
            const baseFreq = 400 + rarity * 100;
            const notes = rarity > 3 ? 4 : rarity > 1 ? 3 : 2;
            return { type: 'multi', duration: 0.15 + rarity * 0.08, volume: 0.15 + rarity * 0.03, oscillators: 
              Array.from({ length: notes }, (_, i) => ({ wave: rarity > 3 ? 'sine' : 'triangle', freq: baseFreq * Math.pow(1.25, i), volume: 0.5 - i * 0.1, delay: i * 0.04, attack: 0.01 }))
            };
          }
          if (isInventory) return { type: 'single', wave: 'sine', freq: 600 + hash % 200, freqEnd: soundId.includes('open') ? 800 : 400, duration: 0.12, attack: 0.01, sustain: 0.5, volume: 0.18 };
          if (isCraft) return { type: 'multi', duration: 0.5, volume: 0.2, oscillators: [
            { wave: 'sine', freq: 300, freqEnd: 600, volume: 0.3, attack: 0.2 },
            { wave: 'triangle', freq: 450, freqEnd: 900, volume: 0.25, delay: 0.1, attack: 0.15 },
            { wave: 'sine', freq: 600, freqEnd: 1200, volume: 0.2, delay: 0.2, attack: 0.1 }
          ]};
          return { type: 'single', wave: 'triangle', freq: 500 + hash % 300, duration: 0.15, attack: 0.01, sustain: 0.6, volume: 0.18 };
        },
        
        alerts: () => {
          const isWarning = soundId.includes('warning');
          const isCritical = soundId.includes('critical') || soundId.includes('danger') || soundId.includes('emergency');
          const isAchievement = soundId.includes('achievement') || soundId.includes('level') || soundId.includes('unlock');
          const isQuest = soundId.includes('quest') || soundId.includes('mission') || soundId.includes('objective');
          const isAlarm = soundId.includes('alarm');
          
          if (isCritical) return { type: 'multi', duration: 0.4, volume: 0.25, oscillators: [
            { wave: 'square', freq: 440, volume: 0.4, vibrato: { rate: 8, depth: 30 } },
            { wave: 'sawtooth', freq: 220, volume: 0.3 }
          ]};
          if (isWarning) return { type: 'multi', duration: 0.3, volume: 0.22, oscillators: [
            { wave: 'triangle', freq: 600, volume: 0.4 },
            { wave: 'triangle', freq: 400, volume: 0.35, delay: 0.1 }
          ]};
          if (isAchievement) return { type: 'multi', duration: 0.5, volume: 0.2, oscillators: [
            { wave: 'sine', freq: 523, volume: 0.4 },
            { wave: 'sine', freq: 659, volume: 0.35, delay: 0.08 },
            { wave: 'sine', freq: 784, volume: 0.3, delay: 0.16 },
            { wave: 'sine', freq: 1047, volume: 0.25, delay: 0.24 }
          ]};
          if (isQuest) return { type: 'multi', duration: 0.35, volume: 0.2, oscillators: [
            { wave: 'sine', freq: 440, volume: 0.4 },
            { wave: 'sine', freq: 554, volume: 0.35, delay: 0.06 },
            { wave: 'sine', freq: 659, volume: 0.3, delay: 0.12 }
          ]};
          if (isAlarm) return { type: 'single', wave: 'square', freq: 800, freqModulate: 400, duration: 0.4, attack: 0.01, sustain: 0.9, volume: 0.2 };
          return { type: 'single', wave: 'triangle', freq: 500 + hash % 200, duration: 0.25, attack: 0.02, sustain: 0.6, volume: 0.2 };
        },
        
        ambient: () => {
          const isSpace = soundId.includes('space') || soundId.includes('void');
          const isShip = soundId.includes('ship') || soundId.includes('bridge') || soundId.includes('engine');
          const isStation = soundId.includes('station') || soundId.includes('hangar');
          const isRadio = soundId.includes('radio') || soundId.includes('static') || soundId.includes('interference');
          
          if (isSpace) return { type: 'multi', duration: 0.6, volume: 0.1, oscillators: [
            { wave: 'sine', freq: 60 + hash % 20, volume: 0.3, vibrato: { rate: 0.5, depth: 5 } },
            { wave: 'sine', freq: 90 + hash % 30, volume: 0.2, vibrato: { rate: 0.3, depth: 3 } }
          ]};
          if (isShip) return { type: 'multi', duration: 0.5, volume: 0.12, oscillators: [
            { wave: 'sawtooth', freq: 50 + hash % 20, volume: 0.25, vibrato: { rate: 4, depth: 3 } },
            { wave: 'triangle', freq: 100 + hash % 30, volume: 0.2 }
          ]};
          if (isStation) return { type: 'multi', duration: 0.5, volume: 0.12, oscillators: [
            { wave: 'sine', freq: 120 + hash % 40, volume: 0.25 },
            { wave: 'square', freq: 60, volume: 0.1, vibrato: { rate: 2, depth: 5 } }
          ]};
          if (isRadio) return { type: 'noise', duration: 0.3, volume: 0.12, filterType: 'bandpass', filterFreq: 2000 + hash % 1000, filterQ: 5, noiseDecay: t => 0.5 + Math.sin(t * 30) * 0.5 };
          return { type: 'single', wave: 'sine', freq: 80 + hash % 60, duration: 0.4, attack: 0.2, sustain: 0.8, volume: 0.1 };
        },
        
        footsteps: () => {
          const isMetal = soundId.includes('metal');
          const isGrate = soundId.includes('grate');
          const isCarpet = soundId.includes('carpet') || soundId.includes('soft');
          const isRun = soundId.includes('run') || soundId.includes('sprint');
          const isLand = soundId.includes('land') || soundId.includes('jump');
          
          const speed = isRun ? 0.08 : isLand ? 0.15 : 0.12;
          
          if (isMetal || isGrate) return { type: 'noise', duration: speed, volume: 0.18, filterType: 'highpass', filterFreq: 1500 + hash % 500, filterQ: 2, noiseDecay: t => Math.exp(-t * 20) };
          if (isCarpet) return { type: 'noise', duration: speed, volume: 0.1, filterType: 'lowpass', filterFreq: 400 + hash % 200, filterQ: 1, noiseDecay: t => Math.exp(-t * 15) };
          return { type: 'noise', duration: speed, volume: 0.15, filterType: 'bandpass', filterFreq: 800 + hash % 400, filterQ: 2, noiseDecay: t => Math.exp(-t * 18) };
        },
        
        voices: () => {
          const isGrunt = soundId.includes('grunt') || soundId.includes('effort');
          const isPain = soundId.includes('pain') || soundId.includes('hurt') || soundId.includes('death');
          const isCommand = soundId.includes('command') || soundId.includes('order') || soundId.includes('callout');
          const isRobot = soundId.includes('robot') || soundId.includes('ai') || soundId.includes('droid');
          
          if (isGrunt) return { type: 'single', wave: 'sawtooth', freq: 120 + hash % 80, freqEnd: 80, duration: 0.15, attack: 0.02, sustain: 0.5, volume: 0.2, filter: { type: 'lowpass', freq: 800, Q: 2 } };
          if (isPain) return { type: 'single', wave: 'sawtooth', freq: 200 + hash % 100, freqEnd: 100, duration: 0.25, attack: 0.01, sustain: 0.6, volume: 0.22, filter: { type: 'lowpass', freq: 1000, Q: 3 } };
          if (isCommand) return { type: 'multi', duration: 0.2, volume: 0.18, oscillators: [
            { wave: 'sawtooth', freq: 150 + hash % 50, volume: 0.4, attack: 0.02 },
            { wave: 'triangle', freq: 300 + hash % 100, volume: 0.2 }
          ]};
          if (isRobot) return { type: 'multi', duration: 0.25, volume: 0.18, oscillators: [
            { wave: 'square', freq: 200 + hash % 100, volume: 0.3, vibrato: { rate: 10, depth: 20 } },
            { wave: 'sawtooth', freq: 400 + hash % 200, volume: 0.2 }
          ]};
          return { type: 'single', wave: 'sawtooth', freq: 150 + hash % 100, duration: 0.2, attack: 0.03, sustain: 0.5, volume: 0.18, filter: { type: 'lowpass', freq: 1200, Q: 2 } };
        },
        
        impacts: () => {
          const isMetal = soundId.includes('metal');
          const isGlass = soundId.includes('glass');
          const isFlesh = soundId.includes('flesh') || soundId.includes('organic');
          const isHeavy = soundId.includes('heavy') || soundId.includes('crash');
          
          const intensity = isHeavy ? 1.0 : 0.6;
          
          if (isMetal) return { type: 'noise', duration: 0.15 + intensity * 0.1, volume: 0.2 + intensity * 0.1, filterType: 'bandpass', filterFreq: 1500 + hash % 500, filterQ: 4, noiseDecay: t => Math.exp(-t * 12) * (1 + Math.sin(t * 80) * 0.3 * (1 - t)) };
          if (isGlass) return { type: 'noise', duration: 0.2, volume: 0.2, filterType: 'highpass', filterFreq: 3000 + hash % 1000, filterQ: 2, noiseDecay: t => Math.exp(-t * 8) };
          if (isFlesh) return { type: 'noise', duration: 0.1, volume: 0.18, filterType: 'lowpass', filterFreq: 500 + hash % 200, filterQ: 1, noiseDecay: t => Math.exp(-t * 20) };
          return { type: 'noise', duration: 0.12 + intensity * 0.08, volume: 0.18 + intensity * 0.08, filterType: 'bandpass', filterFreq: 800 + hash % 400, filterQ: 2, noiseDecay: t => Math.exp(-t * 15) };
        },
        
        music: () => {
          const isStinger = soundId.includes('stinger');
          const isVictory = soundId.includes('victory') || soundId.includes('win');
          const isDefeat = soundId.includes('defeat') || soundId.includes('lose') || soundId.includes('death');
          const isCombat = soundId.includes('combat') || soundId.includes('battle');
          const isTense = soundId.includes('tension') || soundId.includes('suspense');
          
          if (isVictory) return { type: 'multi', duration: 0.6, volume: 0.18, oscillators: [
            { wave: 'sine', freq: 523, volume: 0.4, attack: 0.05 },
            { wave: 'sine', freq: 659, volume: 0.35, delay: 0.1 },
            { wave: 'sine', freq: 784, volume: 0.3, delay: 0.2 },
            { wave: 'sine', freq: 1047, volume: 0.25, delay: 0.3 }
          ]};
          if (isDefeat) return { type: 'multi', duration: 0.5, volume: 0.18, oscillators: [
            { wave: 'sine', freq: 293, volume: 0.4, attack: 0.1 },
            { wave: 'sine', freq: 261, volume: 0.35, delay: 0.15 },
            { wave: 'sine', freq: 220, volume: 0.3, delay: 0.3 }
          ]};
          if (isCombat) return { type: 'multi', duration: 0.4, volume: 0.18, oscillators: [
            { wave: 'sawtooth', freq: 110, volume: 0.3, vibrato: { rate: 6, depth: 5 } },
            { wave: 'square', freq: 220, volume: 0.2 }
          ]};
          if (isTense) return { type: 'multi', duration: 0.5, volume: 0.12, oscillators: [
            { wave: 'sine', freq: 146, volume: 0.3 },
            { wave: 'sine', freq: 155, volume: 0.25, vibrato: { rate: 2, depth: 3 } }
          ]};
          if (isStinger) return { type: 'multi', duration: 0.35, volume: 0.2, oscillators: [
            { wave: 'triangle', freq: 440 + hash % 200, volume: 0.4 },
            { wave: 'sine', freq: 880 + hash % 400, volume: 0.25, delay: 0.05 }
          ]};
          return { type: 'single', wave: 'sine', freq: 220 + hash % 220, duration: 0.4, attack: 0.1, sustain: 0.7, volume: 0.15 };
        }
      };
      
      return params[category] ? params[category]() : { type: 'single', wave: 'sine', freq: 440 + hash % 200, duration: 0.2, attack: 0.02, sustain: 0.5, volume: 0.18 };
    }
    
    // Add sound to timeline
    function addSoundToTimeline(soundId, trackId = null, startTime = 0) {
      const sound = findSoundById(soundId);
      if (!sound) return;
      
      // Create track if needed
      if (!trackId) {
        if (dawState.tracks.length === 0) {
          dawAddTrack();
        }
        trackId = dawState.tracks[dawState.tracks.length - 1]?.id;
      }
      
      if (!trackId) return;
      
      const clip = {
        id: dawState.nextClipId++,
        trackId: trackId,
        soundId: soundId,
        sound: sound,
        startTime: startTime,
        duration: sound.duration || 1.0,
        volume: 0,
        pitch: 1.0,
        fadeIn: 0,
        fadeOut: 0,
        bus: 'SFX'
      };
      
      dawState.clips.push(clip);
      renderTimeline();
      updateDawCode();
      showToast('Added: ' + sound.name, 'success');
    }
    
    // Handle drop on timeline
    function handleTimelineDrop(event) {
      event.preventDefault();
      const soundId = event.dataTransfer.getData('text/plain');
      if (!soundId) return;
      
      const rect = event.currentTarget.getBoundingClientRect();
      const x = event.clientX - rect.left;
      const startTime = dawState.snapEnabled 
        ? Math.round((x / dawState.pixelsPerSecond) / dawState.snapValue) * dawState.snapValue
        : x / dawState.pixelsPerSecond;
      
      addSoundToTimeline(soundId, null, Math.max(0, startTime));
    }
    
    // Add new track
    function dawAddTrack() {
      const track = {
        id: dawState.nextTrackId++,
        name: 'Track ' + dawState.nextTrackId,
        muted: false,
        solo: false,
        volume: 0,
        pan: 0
      };
      dawState.tracks.push(track);
      renderTimeline();
      renderMixer();
    }
    
    // Render timeline with draggable clips
    function renderTimeline() {
      const container = document.getElementById('timelineTracks');
      const ruler = document.getElementById('timelineRuler');
      if (!container) return;
      
      // Update counts in footer
      const trackCountEl = document.getElementById('trackCount');
      const clipCountEl = document.getElementById('clipCount');
      if (trackCountEl) trackCountEl.textContent = dawState.tracks.length + ' track' + (dawState.tracks.length !== 1 ? 's' : '');
      if (clipCountEl) clipCountEl.textContent = dawState.clips.length + ' clip' + (dawState.clips.length !== 1 ? 's' : '');
      
      // Render ruler with BPM-aware markers
      if (ruler) {
        let rulerHtml = '';
        const pps = dawState.pixelsPerSecond * dawState.zoom / 100;
        const beatsPerSecond = dawState.bpm / 60;
        const beatInterval = 1 / beatsPerSecond;
        
        // Show both seconds and beat markers
        for (let i = 0; i <= dawState.timelineLength; i++) {
          rulerHtml += '<div class="ruler-mark major" style="left: ' + (140 + i * pps) + 'px;"><span>' + i + 's</span></div>';
        }
        // Add beat markers
        for (let beat = 0; beat < dawState.timelineLength * beatsPerSecond; beat++) {
          const time = beat * beatInterval;
          if (Math.abs(time - Math.round(time)) > 0.01) { // Skip if too close to second marker
            rulerHtml += '<div class="ruler-mark minor" style="left: ' + (140 + time * pps) + 'px;"></div>';
          }
        }
        ruler.innerHTML = rulerHtml;
      }
      
      if (dawState.tracks.length === 0) {
        container.innerHTML = '<div class="empty-timeline" ondragover="event.preventDefault(); this.classList.add(\\'drop-target\\')" ondragleave="this.classList.remove(\\'drop-target\\')" ondrop="handleTimelineEmptyDrop(event)"><div class="icon">🎼</div><p>Drop sounds here to create tracks</p><p class="hint">Or click "+ Track" to add an empty track</p></div>';
        return;
      }
      
      let html = '';
      dawState.tracks.forEach(track => {
        const trackClips = dawState.clips.filter(c => c.trackId === track.id);
        
        html += '<div class="track-lane" data-track-id="' + track.id + '" ondragover="handleTrackDragOver(event, ' + track.id + ')" ondragleave="handleTrackDragLeave(event)" ondrop="handleTrackDrop(event, ' + track.id + ')">';
        html += '<div class="track-header">';
        html += '<input class="track-name-input" value="' + escapeHtml(track.name) + '" onchange="renameTrack(' + track.id + ', this.value)" onclick="event.stopPropagation()">';
        html += '<div class="track-controls">';
        html += '<button class="track-ctrl-btn' + (track.muted ? ' muted' : '') + '" onclick="toggleTrackMute(' + track.id + ')" title="Mute">M</button>';
        html += '<button class="track-ctrl-btn' + (track.solo ? ' solo' : '') + '" onclick="toggleTrackSolo(' + track.id + ')" title="Solo">S</button>';
        html += '<button class="track-ctrl-btn delete" onclick="deleteTrack(' + track.id + ')" title="Delete Track">×</button>';
        html += '</div></div>';
        html += '<div class="track-clips-area" data-track-id="' + track.id + '">';
        
        trackClips.forEach(clip => {
          const left = clip.startTime * dawState.pixelsPerSecond * dawState.zoom / 100;
          const width = clip.duration * dawState.pixelsPerSecond * dawState.zoom / 100;
          const selected = clip.id === dawState.selectedClipId ? ' selected' : '';
          const categoryClass = clip.sound?.category ? ' category-' + clip.sound.category : '';
          
          html += '<div class="clip' + selected + categoryClass + '" data-clip-id="' + clip.id + '" draggable="true" style="left: ' + left + 'px; width: ' + Math.max(width, 50) + 'px;" onclick="selectClip(' + clip.id + '); event.stopPropagation();" ondragstart="handleClipDragStart(event, ' + clip.id + ')" ondblclick="previewClipSound(' + clip.id + ')">';
          html += '<div class="clip-resize-handle left" onmousedown="startClipResize(event, ' + clip.id + ', \\'left\\')"></div>';
          html += '<div class="clip-label">' + escapeHtml(clip.sound?.name || 'Clip') + '</div>';
          html += '<div class="clip-wave"><div class="clip-wave-inner"></div></div>';
          html += '<div class="clip-resize-handle right" onmousedown="startClipResize(event, ' + clip.id + ', \\'right\\')"></div>';
          html += '</div>';
        });
        
        html += '</div></div>';
      });
      
      // Add "New Track" drop zone at the bottom
      html += '<div class="track-lane new-track-zone" ondragover="event.preventDefault(); this.classList.add(\\'drop-target\\')" ondragleave="this.classList.remove(\\'drop-target\\')" ondrop="handleNewTrackDrop(event)">';
      html += '<div class="track-header"><span class="add-track-label">+ Drop here for new track</span></div>';
      html += '<div class="track-clips-area"></div>';
      html += '</div>';
      
      container.innerHTML = html;
    }
    
    // Handle drag start for clips
    function handleClipDragStart(event, clipId) {
      event.dataTransfer.setData('application/x-clip-id', clipId.toString());
      event.dataTransfer.effectAllowed = 'move';
      dawState.draggedClipId = clipId;
      event.target.classList.add('dragging');
    }
    window.handleClipDragStart = handleClipDragStart;
    
    // Handle drag over track
    function handleTrackDragOver(event, trackId) {
      event.preventDefault();
      event.currentTarget.classList.add('drop-target');
      
      // Show drop indicator
      const rect = event.currentTarget.querySelector('.track-clips-area').getBoundingClientRect();
      const x = event.clientX - rect.left;
      const time = Math.max(0, x / (dawState.pixelsPerSecond * dawState.zoom / 100));
      const snappedTime = dawState.snapEnabled ? Math.round(time / dawState.snapValue) * dawState.snapValue : time;
      
      // Update a visual drop indicator
      let indicator = event.currentTarget.querySelector('.drop-indicator');
      if (!indicator) {
        indicator = document.createElement('div');
        indicator.className = 'drop-indicator';
        event.currentTarget.querySelector('.track-clips-area').appendChild(indicator);
      }
      indicator.style.left = (snappedTime * dawState.pixelsPerSecond * dawState.zoom / 100) + 'px';
    }
    window.handleTrackDragOver = handleTrackDragOver;
    
    // Handle drag leave
    function handleTrackDragLeave(event) {
      event.currentTarget.classList.remove('drop-target');
      const indicator = event.currentTarget.querySelector('.drop-indicator');
      if (indicator) indicator.remove();
    }
    window.handleTrackDragLeave = handleTrackDragLeave;
    
    // Handle drop on track
    function handleTrackDrop(event, trackId) {
      event.preventDefault();
      event.currentTarget.classList.remove('drop-target');
      const indicator = event.currentTarget.querySelector('.drop-indicator');
      if (indicator) indicator.remove();
      
      const clipsArea = event.currentTarget.querySelector('.track-clips-area');
      const rect = clipsArea.getBoundingClientRect();
      const x = event.clientX - rect.left;
      const time = Math.max(0, x / (dawState.pixelsPerSecond * dawState.zoom / 100));
      const snappedTime = dawState.snapEnabled ? Math.round(time / dawState.snapValue) * dawState.snapValue : time;
      
      // Check if this is a clip move or a new sound drop
      const clipIdStr = event.dataTransfer.getData('application/x-clip-id');
      const soundId = event.dataTransfer.getData('text/plain');
      
      if (clipIdStr) {
        // Moving existing clip
        const clipId = parseInt(clipIdStr);
        const clip = dawState.clips.find(c => c.id === clipId);
        if (clip) {
          clip.trackId = trackId;
          clip.startTime = snappedTime;
          renderTimeline();
          updateDawCode();
          showToast('Clip moved', 'info');
        }
      } else if (soundId) {
        // Adding new sound
        addSoundToTimeline(soundId, trackId, snappedTime);
      }
      
      dawState.draggedClipId = null;
    }
    window.handleTrackDrop = handleTrackDrop;
    
    // Handle drop on empty timeline
    function handleTimelineEmptyDrop(event) {
      event.preventDefault();
      event.currentTarget.classList.remove('drop-target');
      
      const soundId = event.dataTransfer.getData('text/plain');
      if (soundId) {
        // Auto-create track and add sound
        dawAddTrack();
        addSoundToTimeline(soundId, dawState.tracks[0]?.id, 0);
      }
    }
    window.handleTimelineEmptyDrop = handleTimelineEmptyDrop;
    
    // Handle drop on new track zone
    function handleNewTrackDrop(event) {
      event.preventDefault();
      event.currentTarget.classList.remove('drop-target');
      
      const soundId = event.dataTransfer.getData('text/plain');
      const clipIdStr = event.dataTransfer.getData('application/x-clip-id');
      
      if (soundId || clipIdStr) {
        dawAddTrack();
        const newTrackId = dawState.tracks[dawState.tracks.length - 1].id;
        
        if (clipIdStr) {
          // Move clip to new track
          const clipId = parseInt(clipIdStr);
          const clip = dawState.clips.find(c => c.id === clipId);
          if (clip) {
            clip.trackId = newTrackId;
            renderTimeline();
            updateDawCode();
          }
        } else {
          addSoundToTimeline(soundId, newTrackId, 0);
        }
      }
    }
    window.handleNewTrackDrop = handleNewTrackDrop;
    
    // Rename track
    function renameTrack(trackId, newName) {
      const track = dawState.tracks.find(t => t.id === trackId);
      if (track) {
        track.name = newName || 'Track ' + trackId;
        renderMixer();
      }
    }
    window.renameTrack = renameTrack;
    
    // Preview sound from clip
    function previewClipSound(clipId) {
      const clip = dawState.clips.find(c => c.id === clipId);
      if (clip && clip.soundId) {
        previewSound(clip.soundId);
      }
    }
    window.previewClipSound = previewClipSound;
    
    // Start clip resize
    function startClipResize(event, clipId, side) {
      event.preventDefault();
      event.stopPropagation();
      
      dawState.resizing = { clipId, side, startX: event.clientX };
      const clip = dawState.clips.find(c => c.id === clipId);
      if (clip) {
        dawState.resizing.originalStart = clip.startTime;
        dawState.resizing.originalDuration = clip.duration;
      }
      
      document.addEventListener('mousemove', handleClipResize);
      document.addEventListener('mouseup', stopClipResize);
    }
    window.startClipResize = startClipResize;
    
    function handleClipResize(event) {
      if (!dawState.resizing) return;
      
      const { clipId, side, startX, originalStart, originalDuration } = dawState.resizing;
      const clip = dawState.clips.find(c => c.id === clipId);
      if (!clip) return;
      
      const deltaX = event.clientX - startX;
      const deltaTime = deltaX / (dawState.pixelsPerSecond * dawState.zoom / 100);
      
      if (side === 'left') {
        const newStart = Math.max(0, originalStart + deltaTime);
        const newDuration = originalDuration - (newStart - originalStart);
        if (newDuration >= 0.1) {
          clip.startTime = dawState.snapEnabled ? Math.round(newStart / dawState.snapValue) * dawState.snapValue : newStart;
          clip.duration = originalDuration - (clip.startTime - originalStart);
        }
      } else {
        const newDuration = Math.max(0.1, originalDuration + deltaTime);
        clip.duration = dawState.snapEnabled ? Math.round(newDuration / dawState.snapValue) * dawState.snapValue : newDuration;
      }
      
      renderTimeline();
    }
    
    function stopClipResize() {
      dawState.resizing = null;
      document.removeEventListener('mousemove', handleClipResize);
      document.removeEventListener('mouseup', stopClipResize);
      updateDawCode();
    }
    
    // Select clip
    function selectClip(clipId) {
      dawState.selectedClipId = clipId;
      renderTimeline();
      renderClipProperties();
    }
    
    // Render clip properties
    function renderClipProperties() {
      const container = document.getElementById('clipProperties');
      if (!container) return;
      
      const clip = dawState.clips.find(c => c.id === dawState.selectedClipId);
      if (!clip) {
        container.innerHTML = '<div class="empty-props">Select a clip to edit its properties</div>';
        return;
      }
      
      container.innerHTML = 
        '<div class="prop-row"><span class="prop-label">Name</span><input class="prop-input" value="' + escapeHtml(clip.sound?.name || '') + '" readonly></div>' +
        '<div class="prop-row"><span class="prop-label">Start</span><input class="prop-input" type="number" value="' + clip.startTime.toFixed(2) + '" step="0.1" onchange="updateClip(' + clip.id + ', \\'startTime\\', parseFloat(this.value))"><span class="prop-value">sec</span></div>' +
        '<div class="prop-row"><span class="prop-label">Duration</span><input class="prop-input" type="number" value="' + clip.duration.toFixed(2) + '" step="0.1" onchange="updateClip(' + clip.id + ', \\'duration\\', parseFloat(this.value))"><span class="prop-value">sec</span></div>' +
        '<div class="prop-row"><span class="prop-label">Volume</span><input class="prop-slider" type="range" min="-40" max="6" value="' + clip.volume + '" oninput="updateClip(' + clip.id + ', \\'volume\\', parseInt(this.value)); this.nextElementSibling.textContent = this.value + \\'dB\\'"><span class="prop-value">' + clip.volume + 'dB</span></div>' +
        '<div class="prop-row"><span class="prop-label">Pitch</span><input class="prop-slider" type="range" min="0.5" max="2" step="0.05" value="' + clip.pitch + '" oninput="updateClip(' + clip.id + ', \\'pitch\\', parseFloat(this.value)); this.nextElementSibling.textContent = parseFloat(this.value).toFixed(2) + \\'x\\'"><span class="prop-value">' + clip.pitch.toFixed(2) + 'x</span></div>' +
        '<div class="prop-row"><span class="prop-label">Fade In</span><input class="prop-input" type="number" value="' + clip.fadeIn.toFixed(2) + '" step="0.05" min="0" onchange="updateClip(' + clip.id + ', \\'fadeIn\\', parseFloat(this.value))"><span class="prop-value">sec</span></div>' +
        '<div class="prop-row"><span class="prop-label">Fade Out</span><input class="prop-input" type="number" value="' + clip.fadeOut.toFixed(2) + '" step="0.05" min="0" onchange="updateClip(' + clip.id + ', \\'fadeOut\\', parseFloat(this.value))"><span class="prop-value">sec</span></div>' +
        '<div class="prop-row"><span class="prop-label">Bus</span><select class="prop-input" onchange="updateClip(' + clip.id + ', \\'bus\\', this.value)">' +
          ['Master', 'SFX', 'Music', 'UI', 'Ambient', 'Voice'].map(b => '<option' + (clip.bus === b ? ' selected' : '') + '>' + b + '</option>').join('') +
        '</select></div>' +
        '<button class="transport-action-btn" style="width: 100%; margin-top: 1rem; justify-content: center; background: #da3633; border-color: #da3633;" onclick="deleteClip(' + clip.id + ')">🗑️ Delete Clip</button>';
    }
    
    // Update clip property
    function updateClip(clipId, prop, value) {
      const clip = dawState.clips.find(c => c.id === clipId);
      if (clip) {
        clip[prop] = value;
        renderTimeline();
        renderClipProperties();
        updateDawCode();
      }
    }
    
    // Delete clip
    function deleteClip(clipId) {
      const idx = dawState.clips.findIndex(c => c.id === clipId);
      if (idx !== -1) {
        dawState.clips.splice(idx, 1);
        if (dawState.selectedClipId === clipId) dawState.selectedClipId = null;
        renderTimeline();
        renderClipProperties();
        updateDawCode();
        showToast('Clip deleted', 'info');
      }
    }
    
    // Toggle track mute
    function toggleTrackMute(trackId) {
      const track = dawState.tracks.find(t => t.id === trackId);
      if (track) {
        track.muted = !track.muted;
        renderTimeline();
        renderMixer();
      }
    }
    
    // Toggle track solo
    function toggleTrackSolo(trackId) {
      const track = dawState.tracks.find(t => t.id === trackId);
      if (track) {
        track.solo = !track.solo;
        renderTimeline();
        renderMixer();
      }
    }
    
    // Delete track
    function deleteTrack(trackId) {
      const idx = dawState.tracks.findIndex(t => t.id === trackId);
      if (idx !== -1) {
        dawState.tracks.splice(idx, 1);
        dawState.clips = dawState.clips.filter(c => c.trackId !== trackId);
        renderTimeline();
        renderMixer();
        updateDawCode();
        showToast('Track deleted', 'info');
      }
    }
    
    // Render mixer
    function renderMixer() {
      const container = document.getElementById('mixerContainer');
      if (!container) return;
      
      let html = '<div class="mixer-channel master">' +
        '<div class="mixer-label">Master</div>' +
        '<div class="mixer-fader-wrap"><div class="mixer-fader" style="height: ' + Math.max(10, (dawState.masterVolume - 80 + 40) / 46 * 100) + '%;"></div></div>' +
        '<div class="mixer-meter"><div class="meter-fill" style="height: 60%;"></div></div>' +
        '<div class="mixer-btns"><button class="mixer-btn">M</button><button class="mixer-btn">S</button></div>' +
        '</div>';
      
      dawState.tracks.forEach(track => {
        const faderHeight = Math.max(10, (track.volume + 40) / 46 * 100);
        const meterHeight = 40 + Math.random() * 40;
        
        html += '<div class="mixer-channel">' +
          '<div class="mixer-label">' + escapeHtml(track.name.substring(0, 8)) + '</div>' +
          '<div class="mixer-fader-wrap" onclick="adjustTrackFader(event, ' + track.id + ')"><div class="mixer-fader" style="height: ' + faderHeight + '%;"></div></div>' +
          '<div class="mixer-meter"><div class="meter-fill" style="height: ' + meterHeight + '%;"></div></div>' +
          '<div class="mixer-btns">' +
          '<button class="mixer-btn' + (track.muted ? ' active' : '') + '" onclick="toggleTrackMute(' + track.id + ')">M</button>' +
          '<button class="mixer-btn' + (track.solo ? ' active' : '') + '" onclick="toggleTrackSolo(' + track.id + ')">S</button>' +
          '</div></div>';
      });
      
      container.innerHTML = html;
    }
    
    // Adjust fader by clicking on fader wrap
    function adjustTrackFader(event, trackId) {
      const rect = event.currentTarget.getBoundingClientRect();
      const clickY = event.clientY - rect.top;
      const percentage = 1 - (clickY / rect.height);
      const volume = Math.round(percentage * 46 - 40);
      const track = dawState.tracks.find(t => t.id === trackId);
      if (track) {
        track.volume = Math.max(-40, Math.min(6, volume));
        renderMixer();
      }
    }
    window.adjustTrackFader = adjustTrackFader;
    
    // Update track volume
    function updateTrackVolume(trackId, value) {
      const track = dawState.tracks.find(t => t.id === trackId);
      if (track) track.volume = parseInt(value);
    }
    
    // Switch property tab
    function switchPropTab(tab) {
      document.querySelectorAll('.prop-tab').forEach(t => t.classList.remove('active'));
      document.querySelectorAll('.prop-panel').forEach(p => p.classList.remove('active'));
      document.querySelector('.prop-tab[onclick*="' + tab + '"]')?.classList.add('active');
      document.getElementById('prop' + tab.charAt(0).toUpperCase() + tab.slice(1))?.classList.add('active');
    }
    
    // Transport controls
    function dawTogglePlay() {
      // Resume audio context if needed
      if (dawState.audioContext && dawState.audioContext.state === 'suspended') {
        dawState.audioContext.resume();
      }
      
      dawState.isPlaying = !dawState.isPlaying;
      const btn = document.getElementById('dawPlayBtn');
      if (btn) {
        btn.classList.toggle('active', dawState.isPlaying);
        btn.textContent = dawState.isPlaying ? '⏸' : '▶';
      }
      if (dawState.isPlaying) {
        dawState.lastPlayTime = performance.now();
        animatePlayhead();
        playClipsAtTime();
      }
      showToast(dawState.isPlaying ? 'Playing' : 'Paused', 'info');
    }
    
    // Play clips that start at current time
    function playClipsAtTime() {
      if (!dawState.isPlaying) return;
      
      dawState.clips.forEach(clip => {
        const track = dawState.tracks.find(t => t.id === clip.trackId);
        if (track && !track.muted) {
          // Check if clip should play at current time
          const clipStart = clip.startTime;
          const clipEnd = clip.startTime + clip.duration;
          
          if (dawState.currentTime >= clipStart && dawState.currentTime < clipEnd && !clip.isPlaying) {
            // Play this clip's sound
            clip.isPlaying = true;
            previewSound(clip.soundId);
            
            // Reset playing flag after duration
            setTimeout(function() {
              clip.isPlaying = false;
            }, clip.duration * 1000);
          }
        }
      });
    }
    
    function dawStop() {
      dawState.isPlaying = false;
      dawState.currentTime = 0;
      // Reset all clip playing states
      dawState.clips.forEach(c => c.isPlaying = false);
      updateTimeDisplay();
      const btn = document.getElementById('dawPlayBtn');
      if (btn) {
        btn.classList.remove('active');
        btn.textContent = '▶';
      }
      updatePlayhead();
    }
    
    function dawRewind() {
      dawState.currentTime = 0;
      dawState.clips.forEach(c => c.isPlaying = false);
      updateTimeDisplay();
      updatePlayhead();
    }
    
    function dawRecord() {
      dawState.isRecording = !dawState.isRecording;
      showToast(dawState.isRecording ? 'Recording...' : 'Recording stopped', dawState.isRecording ? 'warning' : 'info');
    }
    
    function animatePlayhead() {
      if (!dawState.isPlaying) return;
      
      const now = performance.now();
      const deltaMs = now - (dawState.lastPlayTime || now);
      dawState.lastPlayTime = now;
      
      // Advance time based on BPM (if tempo sync desired) or real-time
      // For now we use real-time but could multiply by bpm/60 for tempo-synced playback
      dawState.currentTime += deltaMs / 1000;
      
      if (dawState.currentTime >= dawState.timelineLength) {
        dawState.currentTime = 0;
        dawState.clips.forEach(c => c.isPlaying = false);
      }
      
      // Check if any clips should play
      playClipsAtTime();
      
      updateTimeDisplay();
      updatePlayhead();
      requestAnimationFrame(animatePlayhead);
    }
    
    // Update BPM
    function updateBpm(value) {
      dawState.bpm = Math.max(30, Math.min(300, parseInt(value) || 120));
      document.getElementById('bpmInput').value = dawState.bpm;
      // BPM affects snap grid and beat markers
      renderTimeline();
      showToast('BPM: ' + dawState.bpm, 'info');
    }
    window.updateBpm = updateBpm;
    
    function updateTimeDisplay() {
      const display = document.getElementById('dawTimeDisplay');
      if (display) {
        const mins = Math.floor(dawState.currentTime / 60);
        const secs = Math.floor(dawState.currentTime % 60);
        const ms = Math.floor((dawState.currentTime % 1) * 1000);
        display.textContent = String(mins).padStart(2, '0') + ':' + String(secs).padStart(2, '0') + '.' + String(ms).padStart(3, '0');
      }
    }
    
    function updatePlayhead() {
      const playhead = document.getElementById('playhead');
      if (playhead) {
        playhead.style.left = (120 + dawState.currentTime * dawState.pixelsPerSecond * dawState.zoom / 100) + 'px';
      }
    }
    
    // Zoom controls
    function dawZoomIn() {
      dawState.zoom = Math.min(200, dawState.zoom + 25);
      document.getElementById('zoomLevel').textContent = dawState.zoom + '%';
      renderTimeline();
    }
    
    function dawZoomOut() {
      dawState.zoom = Math.max(25, dawState.zoom - 25);
      document.getElementById('zoomLevel').textContent = dawState.zoom + '%';
      renderTimeline();
    }
    
    // Clear all
    function dawClearAll() {
      if (dawState.tracks.length === 0 && dawState.clips.length === 0) return;
      if (confirm('Clear all tracks and clips?')) {
        dawState.tracks = [];
        dawState.clips = [];
        dawState.selectedClipId = null;
        renderTimeline();
        renderMixer();
        updateDawCode();
        showToast('Cleared all', 'info');
      }
    }
    
    // Generate GDScript code
    function updateDawCode() {
      const output = document.getElementById('dawCodeOutput');
      if (!output) return;
      
      if (dawState.clips.length === 0) {
        output.textContent = '# Add clips to generate code';
        return;
      }
      
      let code = '# Audio Configuration - Generated by Sound Studio\\n';
      code += '# ' + dawState.clips.length + ' clips across ' + dawState.tracks.length + ' tracks\\n\\n';
      code += 'var audio_clips: Array = [\\n';
      
      dawState.clips.forEach((clip, idx) => {
        code += '    {\\n';
        code += '        "name": "' + (clip.sound?.name || 'clip').toLowerCase().replace(/\\s+/g, '_') + '",\\n';
        code += '        "path": "res://assets/audio/' + (clip.sound?.path || '') + '",\\n';
        code += '        "start_time": ' + clip.startTime.toFixed(2) + ',\\n';
        code += '        "duration": ' + clip.duration.toFixed(2) + ',\\n';
        code += '        "volume_db": ' + clip.volume + ',\\n';
        code += '        "pitch_scale": ' + clip.pitch.toFixed(2) + ',\\n';
        code += '        "fade_in": ' + clip.fadeIn.toFixed(2) + ',\\n';
        code += '        "fade_out": ' + clip.fadeOut.toFixed(2) + ',\\n';
        code += '        "bus": "' + clip.bus + '"\\n';
        code += '    }' + (idx < dawState.clips.length - 1 ? ',' : '') + '\\n';
      });
      
      code += ']\\n';
      output.textContent = code.replace(/\\\\n/g, '\\n');
    }
    
    // Copy DAW code
    function copyDawCode() {
      const output = document.getElementById('dawCodeOutput');
      if (output) {
        copyToClipboard(output.textContent);
      }
    }
    
    // Export project
    function dawExport() {
      const data = {
        tracks: dawState.tracks,
        clips: dawState.clips,
        bpm: dawState.bpm,
        timelineLength: dawState.timelineLength
      };
      const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'sound_studio_project.json';
      a.click();
      URL.revokeObjectURL(url);
      showToast('Project exported!', 'success');
    }
    
    // Add effect
    function addEffect(type) {
      if (!type) return;
      showToast('Added ' + type + ' effect', 'success');
    }
    
    // Sound Presets
    const SOUND_PRESETS = {
      basic_sfx: { name: 'Basic SFX Pack', sounds: ['ui_click', 'ui_confirm', 'ui_cancel', 'laser_fire_light', 'explosion_small'] },
      combat_pack: { name: 'Combat Pack', sounds: ['laser_fire_light', 'laser_fire_heavy', 'missile_fire', 'shield_hit_medium', 'explosion_medium', 'hull_hit_medium'] },
      ui_complete: { name: 'UI Complete', sounds: ['ui_click', 'ui_hover', 'ui_confirm', 'ui_cancel', 'ui_menu_open', 'ui_menu_close', 'ui_notification', 'ui_error'] },
      boarding_pack: { name: 'Boarding Pack', sounds: ['grapple_launch', 'grapple_connect', 'airlock_open', 'breach_explosive', 'crew_fight_melee', 'boarding_success'] },
      ambient_pack: { name: 'Ambient Pack', sounds: ['space_void', 'ship_bridge', 'engine_hum', 'radio_static'] },
      full_game: { name: 'Full Game', sounds: ['ui_click', 'laser_fire_medium', 'explosion_small', 'shield_hit_light', 'pickup_common', 'alert_warning', 'achievement'] }
    };
    
    // Load preset
    function loadSoundPreset(presetId) {
      if (!presetId) return;
      const preset = SOUND_PRESETS[presetId];
      if (!preset) return;
      
      if (dawState.tracks.length === 0) dawAddTrack();
      
      let added = 0;
      preset.sounds.forEach((soundId, idx) => {
        const sound = findSoundById(soundId);
        if (sound) {
          addSoundToTimeline(soundId, dawState.tracks[0]?.id, idx * 1.5);
          added++;
        }
      });
      
      showToast('Loaded ' + preset.name + ' (' + added + ' sounds)', 'success');
    }
    
    // Toggle snap to grid
    function toggleSnap(enabled) {
      dawState.snapEnabled = enabled;
      showToast('Snap: ' + (enabled ? 'On' : 'Off'), 'info');
    }
    window.toggleSnap = toggleSnap;
    
    // Toggle snap grid value
    function setSnapValue(value) {
      dawState.snapValue = parseFloat(value);
      showToast('Snap: ' + value + 's', 'info');
    }
    window.setSnapValue = setSnapValue;
    
    // ==================== DAW GLOBAL EXPORTS ====================
    // Make all DAW functions accessible from HTML onclick handlers
    window.dawTogglePlay = dawTogglePlay;
    window.dawStop = dawStop;
    window.dawRewind = dawRewind;
    window.dawRecord = dawRecord;
    window.dawZoomIn = dawZoomIn;
    window.dawZoomOut = dawZoomOut;
    window.dawAddTrack = dawAddTrack;
    window.dawExport = dawExport;
    window.dawClearAll = dawClearAll;
    window.toggleTrackMute = toggleTrackMute;
    window.toggleTrackSolo = toggleTrackSolo;
    window.deleteTrack = deleteTrack;
    window.selectClip = selectClip;
    window.updateClip = updateClip;
    window.deleteClip = deleteClip;
    window.addEffect = addEffect;
    window.switchPropTab = switchPropTab;
    window.copyDawCode = copyDawCode;
    window.loadSoundPreset = loadSoundPreset;
    window.filterSounds = filterSounds;
    window.searchSounds = searchSounds;
    window.previewSound = previewSound;
    window.addSoundToTimeline = addSoundToTimeline;
    window.handleSoundDrag = handleSoundDrag;
    window.selectCategory = selectCategory;
    
    // ==================== BACKGROUND ANIMATION ====================
    function createStarfield() {
      const bg = document.getElementById('bgAnimation');
      if (!bg) return;
      
      for (let i = 0; i < 100; i++) {
        const star = document.createElement('div');
        star.className = 'star';
        star.style.left = Math.random() * 100 + '%';
        star.style.top = Math.random() * 100 + '%';
        star.style.animationDelay = Math.random() * 3 + 's';
        star.style.opacity = Math.random() * 0.5 + 0.3;
        bg.appendChild(star);
      }
    }
    
    // ==================== INITIALIZATION ====================
    async function init() {
      DebugSystem.info('INIT', 'Dashboard initialization starting...');
      
      applyTheme();
      updateAutoRefreshUI();
      
      DebugSystem.info('INIT', 'Setting up navigation...');
      setupNavigation();
      setupSearch();
      setupKeyboardShortcuts();
      createStarfield();
      
      DebugSystem.info('INIT', 'Loading data...');
      await Promise.all([
        loadTools(),
        loadStats(),
        loadResources(),
        loadPrompts(),
        loadNotifications()
      ]);
      
      if (state.settings.autoRefresh) {
        startAutoRefresh();
      }
      
      DebugSystem.info('INIT', 'Dashboard initialization complete!');
      
      // Final sidebar check
      setTimeout(function() {
        const sidebar = document.querySelector('.sidebar');
        const navItems = document.querySelectorAll('.nav-item');
        
        DebugSystem.info('FINAL-CHECK', 'Sidebar verification', {
          sidebarExists: !!sidebar,
          sidebarVisible: sidebar ? getComputedStyle(sidebar).display !== 'none' : false,
          navItemCount: navItems.length,
          sidebarRect: sidebar ? sidebar.getBoundingClientRect() : null
        });
        
        // Check what's at the center of the sidebar
        if (sidebar) {
          const rect = sidebar.getBoundingClientRect();
          const centerX = rect.left + rect.width / 2;
          const centerY = rect.top + 100;  // 100px from top
          
          const elementsAtCenter = document.elementsFromPoint(centerX, centerY);
          DebugSystem.info('FINAL-CHECK', 'Elements at sidebar center (' + centerX + ', ' + centerY + ')', 
            elementsAtCenter.map(function(el) {
              return {
                tag: el.tagName,
                id: el.id,
                className: el.className ? String(el.className).split(' ')[0] : '',
                pointerEvents: getComputedStyle(el).pointerEvents,
                zIndex: getComputedStyle(el).zIndex
              };
            })
          );
        }
      }, 1000);
    }
    
    // Initialize on load
    document.addEventListener('DOMContentLoaded', init);
  </script>
</body>
</html>`;
}

export default { generateDashboardHTML };
