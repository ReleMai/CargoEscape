/**
 * Result Cache with TTL
 * Caches expensive operations to improve response times
 */

class Cache {
  constructor(defaultTTL = 60000) { // 1 minute default
    this.store = new Map();
    this.defaultTTL = defaultTTL;
    this.hits = 0;
    this.misses = 0;
    
    // Cleanup expired entries every minute
    setInterval(() => this.cleanup(), 60000);
  }
  
  generateKey(prefix, args) {
    return `${prefix}:${JSON.stringify(args)}`;
  }
  
  get(key) {
    const entry = this.store.get(key);
    
    if (!entry) {
      this.misses++;
      return null;
    }
    
    if (Date.now() > entry.expiresAt) {
      this.store.delete(key);
      this.misses++;
      return null;
    }
    
    this.hits++;
    return entry.value;
  }
  
  set(key, value, ttl = this.defaultTTL) {
    this.store.set(key, {
      value,
      expiresAt: Date.now() + ttl,
      createdAt: Date.now()
    });
  }
  
  async getOrCompute(key, computeFn, ttl = this.defaultTTL) {
    const cached = this.get(key);
    if (cached !== null) {
      return { value: cached, fromCache: true };
    }
    
    const value = await computeFn();
    this.set(key, value, ttl);
    return { value, fromCache: false };
  }
  
  invalidate(pattern) {
    if (typeof pattern === 'string') {
      // Invalidate keys matching prefix
      for (const key of this.store.keys()) {
        if (key.startsWith(pattern)) {
          this.store.delete(key);
        }
      }
    } else {
      // Invalidate single key
      this.store.delete(pattern);
    }
  }
  
  clear() {
    this.store.clear();
    this.hits = 0;
    this.misses = 0;
  }
  
  cleanup() {
    const now = Date.now();
    let cleaned = 0;
    
    for (const [key, entry] of this.store) {
      if (now > entry.expiresAt) {
        this.store.delete(key);
        cleaned++;
      }
    }
    
    return cleaned;
  }
  
  getStats() {
    const total = this.hits + this.misses;
    return {
      entries: this.store.size,
      hits: this.hits,
      misses: this.misses,
      hitRate: total > 0 ? ((this.hits / total) * 100).toFixed(2) + '%' : '0%',
      memoryEstimate: this.estimateMemory()
    };
  }
  
  estimateMemory() {
    let size = 0;
    for (const [key, entry] of this.store) {
      size += key.length * 2; // UTF-16
      size += JSON.stringify(entry.value).length * 2;
    }
    
    if (size < 1024) return `${size} bytes`;
    if (size < 1024 * 1024) return `${(size / 1024).toFixed(2)} KB`;
    return `${(size / (1024 * 1024)).toFixed(2)} MB`;
  }
}

// Cache instances for different purposes
export const toolCache = new Cache(120000);  // 2 minutes for tool results
export const statsCache = new Cache(120000); // 2 minutes for stats
export const fileCache = new Cache(300000);  // 5 minutes for file contents

// Export class for custom instances
export { Cache };

export default Cache;
