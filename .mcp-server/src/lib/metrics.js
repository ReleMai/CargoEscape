/**
 * Metrics Collector
 * Collects server metrics in Prometheus-compatible format
 */

class MetricsCollector {
  constructor() {
    this.counters = new Map();
    this.gauges = new Map();
    this.histograms = new Map();
    this.startTime = Date.now();
  }
  
  // Counter - only goes up
  incrementCounter(name, labels = {}, value = 1) {
    const key = this.labelKey(name, labels);
    const current = this.counters.get(key) || { value: 0, labels };
    current.value += value;
    this.counters.set(key, current);
  }
  
  // Gauge - can go up or down
  setGauge(name, value, labels = {}) {
    const key = this.labelKey(name, labels);
    this.gauges.set(key, { value, labels, timestamp: Date.now() });
  }
  
  // Histogram - track distributions
  observeHistogram(name, value, labels = {}) {
    const key = this.labelKey(name, labels);
    let histogram = this.histograms.get(key);
    
    if (!histogram) {
      histogram = {
        labels,
        count: 0,
        sum: 0,
        buckets: [5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000],
        observations: new Array(12).fill(0) // +Inf bucket
      };
      this.histograms.set(key, histogram);
    }
    
    histogram.count++;
    histogram.sum += value;
    
    for (let i = 0; i < histogram.buckets.length; i++) {
      if (value <= histogram.buckets[i]) {
        histogram.observations[i]++;
      }
    }
    histogram.observations[histogram.buckets.length]++; // +Inf
  }
  
  labelKey(name, labels) {
    const labelStr = Object.entries(labels)
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([k, v]) => `${k}="${v}"`)
      .join(',');
    return labelStr ? `${name}{${labelStr}}` : name;
  }
  
  // Get all metrics in Prometheus format
  toPrometheus() {
    const lines = [];
    
    // Uptime
    lines.push('# HELP mcp_server_uptime_seconds Server uptime in seconds');
    lines.push('# TYPE mcp_server_uptime_seconds gauge');
    lines.push(`mcp_server_uptime_seconds ${(Date.now() - this.startTime) / 1000}`);
    
    // Counters
    for (const [key, data] of this.counters) {
      lines.push(`mcp_${key} ${data.value}`);
    }
    
    // Gauges
    for (const [key, data] of this.gauges) {
      lines.push(`mcp_${key} ${data.value}`);
    }
    
    // Histograms
    for (const [key, data] of this.histograms) {
      const baseName = key.split('{')[0];
      const labelPart = key.includes('{') ? key.split('{')[1].replace('}', ',') : '';
      
      for (let i = 0; i < data.buckets.length; i++) {
        const le = data.buckets[i];
        lines.push(`mcp_${baseName}_bucket{${labelPart}le="${le}"} ${data.observations[i]}`);
      }
      lines.push(`mcp_${baseName}_bucket{${labelPart}le="+Inf"} ${data.observations[data.buckets.length]}`);
      lines.push(`mcp_${baseName}_sum ${data.sum}`);
      lines.push(`mcp_${baseName}_count ${data.count}`);
    }
    
    return lines.join('\n');
  }
  
  // Get metrics as JSON for dashboard
  toJSON() {
    return {
      uptime: Date.now() - this.startTime,
      uptimeFormatted: this.formatUptime(),
      counters: Object.fromEntries(
        Array.from(this.counters).map(([k, v]) => [k, v.value])
      ),
      gauges: Object.fromEntries(
        Array.from(this.gauges).map(([k, v]) => [k, v.value])
      ),
      histograms: Object.fromEntries(
        Array.from(this.histograms).map(([k, v]) => [k, {
          count: v.count,
          sum: v.sum,
          avg: v.count > 0 ? (v.sum / v.count).toFixed(2) : 0
        }])
      )
    };
  }
  
  formatUptime() {
    const seconds = Math.floor((Date.now() - this.startTime) / 1000);
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    
    const parts = [];
    if (days > 0) parts.push(`${days}d`);
    if (hours > 0) parts.push(`${hours}h`);
    if (minutes > 0) parts.push(`${minutes}m`);
    parts.push(`${secs}s`);
    
    return parts.join(' ');
  }
  
  // Pre-built metric helpers
  trackRequest(method, path, status, duration) {
    this.incrementCounter('http_requests_total', { method, path, status });
    this.observeHistogram('http_request_duration_ms', duration, { method, path });
  }
  
  trackToolExecution(tool, success, duration) {
    this.incrementCounter('tool_executions_total', { tool, success: String(success) });
    this.observeHistogram('tool_duration_ms', duration, { tool });
  }
  
  trackCacheHit(cache, hit) {
    this.incrementCounter('cache_operations_total', { cache, result: hit ? 'hit' : 'miss' });
  }
  
  trackError(type, code) {
    this.incrementCounter('errors_total', { type, code: String(code) });
  }
  
  // Alias for compatibility
  getMetrics() {
    return this.toJSON();
  }
}

export const metrics = new MetricsCollector();
export default metrics;
