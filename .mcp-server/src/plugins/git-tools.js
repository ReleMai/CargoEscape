/**
 * Git Integration Plugin
 * Git status, branch info, commit history, and more
 */

import { exec } from 'child_process';
import { promisify } from 'util';
import path from 'path';

const execAsync = promisify(exec);
const WORKSPACE = process.env.WORKSPACE_PATH || '/workspace';

// ==================== UTILITY FUNCTIONS ====================

async function runGit(command, cwd = WORKSPACE) {
  try {
    const { stdout, stderr } = await execAsync(`git ${command}`, { 
      cwd,
      maxBuffer: 1024 * 1024 // 1MB buffer
    });
    return { success: true, output: stdout.trim(), error: stderr.trim() };
  } catch (error) {
    return { success: false, output: '', error: error.message };
  }
}

// ==================== TOOL DEFINITIONS ====================

const tools = [
  // Git Status
  {
    definition: {
      name: 'git_status',
      description: 'Get current git status including branch, staged, and modified files',
      category: 'git',
      tags: ['git', 'status', 'changes'],
      inputSchema: { type: 'object', properties: {} }
    },
    handler: async () => {
      const [status, branch, remote] = await Promise.all([
        runGit('status --porcelain=v1'),
        runGit('branch --show-current'),
        runGit('remote -v')
      ]);
      
      if (!status.success) {
        throw new Error('Not a git repository or git not available');
      }
      
      const files = {
        staged: [],
        modified: [],
        untracked: [],
        deleted: []
      };
      
      for (const line of status.output.split('\n').filter(l => l)) {
        const code = line.substring(0, 2);
        const file = line.substring(3);
        
        if (code[0] === 'A' || code[0] === 'M' || code[0] === 'R') {
          files.staged.push(file);
        }
        if (code[1] === 'M') {
          files.modified.push(file);
        }
        if (code === '??') {
          files.untracked.push(file);
        }
        if (code[0] === 'D' || code[1] === 'D') {
          files.deleted.push(file);
        }
      }
      
      // Parse remote
      const remotes = [];
      for (const line of remote.output.split('\n').filter(l => l)) {
        const match = line.match(/^(\w+)\s+(.+)\s+\((fetch|push)\)$/);
        if (match && match[3] === 'fetch') {
          remotes.push({ name: match[1], url: match[2] });
        }
      }
      
      return {
        branch: branch.output || 'HEAD detached',
        remotes,
        files,
        summary: {
          staged: files.staged.length,
          modified: files.modified.length,
          untracked: files.untracked.length,
          deleted: files.deleted.length,
          total: files.staged.length + files.modified.length + files.untracked.length + files.deleted.length
        },
        clean: status.output.length === 0
      };
    }
  },
  
  // Git Branches
  {
    definition: {
      name: 'git_branches',
      description: 'List all git branches with current branch highlighted',
      category: 'git',
      tags: ['git', 'branches'],
      inputSchema: {
        type: 'object',
        properties: {
          all: { type: 'boolean', description: 'Include remote branches', default: false }
        }
      }
    },
    handler: async (args) => {
      const flag = args.all ? '-a' : '';
      const result = await runGit(`branch ${flag} --format="%(refname:short)|%(objectname:short)|%(committerdate:relative)|%(HEAD)"`);
      
      if (!result.success) {
        throw new Error('Failed to list branches');
      }
      
      const branches = result.output.split('\n').filter(l => l).map(line => {
        const [name, commit, date, isCurrent] = line.split('|');
        return {
          name,
          commit,
          date,
          current: isCurrent === '*'
        };
      });
      
      return {
        current: branches.find(b => b.current)?.name || 'unknown',
        count: branches.length,
        branches
      };
    }
  },
  
  // Git Log
  {
    definition: {
      name: 'git_log',
      description: 'Get recent commit history',
      category: 'git',
      tags: ['git', 'history', 'commits'],
      inputSchema: {
        type: 'object',
        properties: {
          count: { type: 'number', description: 'Number of commits to show', default: 10 },
          author: { type: 'string', description: 'Filter by author' },
          since: { type: 'string', description: 'Show commits since date (e.g., "1 week ago")' }
        }
      }
    },
    handler: async (args) => {
      const count = args.count || 10;
      let cmd = `log -${count} --format="%H|%h|%an|%ae|%ar|%s"`;
      
      if (args.author) {
        cmd += ` --author="${args.author}"`;
      }
      if (args.since) {
        cmd += ` --since="${args.since}"`;
      }
      
      const result = await runGit(cmd);
      
      if (!result.success) {
        throw new Error('Failed to get git log');
      }
      
      const commits = result.output.split('\n').filter(l => l).map(line => {
        const [hash, shortHash, author, email, date, message] = line.split('|');
        return { hash, shortHash, author, email, date, message };
      });
      
      return {
        count: commits.length,
        commits
      };
    }
  },
  
  // Git Diff
  {
    definition: {
      name: 'git_diff',
      description: 'Show changes in working directory or between commits',
      category: 'git',
      tags: ['git', 'diff', 'changes'],
      inputSchema: {
        type: 'object',
        properties: {
          file: { type: 'string', description: 'Specific file to diff' },
          staged: { type: 'boolean', description: 'Show staged changes', default: false },
          commit: { type: 'string', description: 'Compare with specific commit' }
        }
      }
    },
    handler: async (args) => {
      let cmd = 'diff';
      
      if (args.staged) {
        cmd += ' --staged';
      }
      if (args.commit) {
        cmd += ` ${args.commit}`;
      }
      if (args.file) {
        cmd += ` -- "${args.file}"`;
      }
      
      // Add stats
      const statsResult = await runGit(`${cmd} --stat`);
      const diffResult = await runGit(`${cmd} --no-color`);
      
      if (!diffResult.success) {
        return { hasChanges: false, message: 'No changes or invalid arguments' };
      }
      
      // Parse stats
      const statsLines = statsResult.output.split('\n');
      const summaryLine = statsLines.find(l => l.includes('insertion') || l.includes('deletion'));
      
      return {
        hasChanges: diffResult.output.length > 0,
        stats: statsResult.output,
        summary: summaryLine || 'No changes',
        diff: diffResult.output.substring(0, 5000) + (diffResult.output.length > 5000 ? '\n... (truncated)' : '')
      };
    }
  },
  
  // Git Blame
  {
    definition: {
      name: 'git_blame',
      description: 'Show who last modified each line of a file',
      category: 'git',
      tags: ['git', 'blame', 'history'],
      inputSchema: {
        type: 'object',
        properties: {
          file: { type: 'string', description: 'File to blame' },
          startLine: { type: 'number', description: 'Start line number' },
          endLine: { type: 'number', description: 'End line number' }
        },
        required: ['file']
      }
    },
    handler: async (args) => {
      let cmd = `blame --line-porcelain "${args.file}"`;
      
      if (args.startLine && args.endLine) {
        cmd = `blame -L ${args.startLine},${args.endLine} --line-porcelain "${args.file}"`;
      }
      
      const result = await runGit(cmd);
      
      if (!result.success) {
        throw new Error(`Failed to blame file: ${result.error}`);
      }
      
      // Parse blame output
      const lines = result.output.split('\n');
      const blameData = [];
      let current = {};
      
      for (const line of lines) {
        if (line.match(/^[0-9a-f]{40}/)) {
          if (current.commit) {
            blameData.push(current);
          }
          const parts = line.split(' ');
          current = {
            commit: parts[0].substring(0, 8),
            line: parseInt(parts[2])
          };
        } else if (line.startsWith('author ')) {
          current.author = line.substring(7);
        } else if (line.startsWith('author-time ')) {
          const timestamp = parseInt(line.substring(12));
          current.date = new Date(timestamp * 1000).toISOString().split('T')[0];
        } else if (line.startsWith('\t')) {
          current.code = line.substring(1);
        }
      }
      
      if (current.commit) {
        blameData.push(current);
      }
      
      // Get unique authors
      const authors = [...new Set(blameData.map(b => b.author))];
      
      return {
        file: args.file,
        lineCount: blameData.length,
        authors,
        blame: blameData.slice(0, 100) // Limit output
      };
    }
  },
  
  // Git Stash
  {
    definition: {
      name: 'git_stash',
      description: 'List, show, or manage git stashes',
      category: 'git',
      tags: ['git', 'stash'],
      inputSchema: {
        type: 'object',
        properties: {
          action: {
            type: 'string',
            enum: ['list', 'show'],
            default: 'list'
          },
          index: { type: 'number', description: 'Stash index for show action' }
        }
      }
    },
    handler: async (args) => {
      if (args.action === 'show' && args.index !== undefined) {
        const result = await runGit(`stash show -p stash@{${args.index}}`);
        return {
          index: args.index,
          diff: result.output.substring(0, 3000) + (result.output.length > 3000 ? '\n... (truncated)' : '')
        };
      }
      
      // List stashes
      const result = await runGit('stash list --format="%gd|%gs|%cr"');
      
      const stashes = result.output.split('\n').filter(l => l).map(line => {
        const [ref, message, date] = line.split('|');
        return { ref, message, date };
      });
      
      return {
        count: stashes.length,
        stashes
      };
    }
  },
  
  // Git Tags
  {
    definition: {
      name: 'git_tags',
      description: 'List all git tags with their associated commits',
      category: 'git',
      tags: ['git', 'tags', 'releases'],
      inputSchema: { type: 'object', properties: {} }
    },
    handler: async () => {
      const result = await runGit('tag -l --format="%(refname:short)|%(objectname:short)|%(creatordate:relative)|%(subject)"');
      
      const tags = result.output.split('\n').filter(l => l).map(line => {
        const [name, commit, date, message] = line.split('|');
        return { name, commit, date, message: message || '' };
      });
      
      // Sort by version if they look like semver
      tags.sort((a, b) => {
        const aVer = a.name.match(/v?(\d+)\.(\d+)\.(\d+)/);
        const bVer = b.name.match(/v?(\d+)\.(\d+)\.(\d+)/);
        
        if (aVer && bVer) {
          for (let i = 1; i <= 3; i++) {
            const diff = parseInt(bVer[i]) - parseInt(aVer[i]);
            if (diff !== 0) return diff;
          }
        }
        return b.name.localeCompare(a.name);
      });
      
      return {
        count: tags.length,
        tags
      };
    }
  },
  
  // Git Contributors
  {
    definition: {
      name: 'git_contributors',
      description: 'List project contributors by commit count',
      category: 'git',
      tags: ['git', 'contributors', 'team'],
      inputSchema: { type: 'object', properties: {} }
    },
    handler: async () => {
      const result = await runGit('shortlog -sne HEAD');
      
      const contributors = result.output.split('\n').filter(l => l).map(line => {
        const match = line.match(/^\s*(\d+)\s+(.+)\s+<(.+)>$/);
        if (match) {
          return {
            commits: parseInt(match[1]),
            name: match[2].trim(),
            email: match[3]
          };
        }
        return null;
      }).filter(Boolean);
      
      // Get total commits
      const totalResult = await runGit('rev-list --count HEAD');
      const totalCommits = parseInt(totalResult.output) || 0;
      
      return {
        totalCommits,
        contributorCount: contributors.length,
        contributors: contributors.map(c => ({
          ...c,
          percentage: totalCommits > 0 ? Math.round((c.commits / totalCommits) * 100) : 0
        }))
      };
    }
  },
  
  // Git File History
  {
    definition: {
      name: 'git_file_history',
      description: 'Show commit history for a specific file',
      category: 'git',
      tags: ['git', 'history', 'file'],
      inputSchema: {
        type: 'object',
        properties: {
          file: { type: 'string', description: 'Path to the file' },
          count: { type: 'number', description: 'Number of commits to show', default: 10 }
        },
        required: ['file']
      }
    },
    handler: async (args) => {
      const count = args.count || 10;
      const result = await runGit(`log -${count} --follow --format="%H|%h|%an|%ar|%s" -- "${args.file}"`);
      
      if (!result.success || !result.output) {
        throw new Error(`No history found for file: ${args.file}`);
      }
      
      const commits = result.output.split('\n').filter(l => l).map(line => {
        const [hash, shortHash, author, date, message] = line.split('|');
        return { hash, shortHash, author, date, message };
      });
      
      return {
        file: args.file,
        commitCount: commits.length,
        commits
      };
    }
  }
];

// ==================== PLUGIN EXPORT ====================

export function register(pluginManager) {
  pluginManager.registerTools(tools);
}

export default { register };
