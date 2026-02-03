# Cargo Escape MCP Server Dockerfile
# 
# Multi-stage build to minimize vulnerabilities:
# 1. Build stage: Install dependencies
# 2. Production stage: Copy only what's needed (no npm cache)

#=============================================================================
# STAGE 1: Build
#=============================================================================
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Install all dependencies (including dev for potential build steps)
RUN npm ci --ignore-scripts

# Copy source code
COPY src/ ./src/

# Prune dev dependencies and clean npm cache
RUN npm prune --production && \
    npm cache clean --force

#=============================================================================
# STAGE 2: Production (minimal image)
#=============================================================================
FROM node:20-alpine AS production

# Install wget for healthcheck (smaller than curl)
RUN apk add --no-cache wget && \
    rm -rf /var/cache/apk/*

WORKDIR /app

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs

# Copy only production node_modules and source from builder
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/src ./src
COPY --from=builder --chown=nodejs:nodejs /app/package.json ./package.json

# Remove npm entirely from production image (not needed at runtime)
RUN rm -rf /usr/local/lib/node_modules/npm \
    /usr/local/bin/npm \
    /usr/local/bin/npx \
    /root/.npm \
    /tmp/*

# Switch to non-root user
USER nodejs

# Set the workspace path (will be mounted as volume)
ENV WORKSPACE_PATH=/workspace
ENV PORT=3100
ENV NODE_ENV=production

# Expose the HTTP port
EXPOSE 3100

# Healthcheck using wget
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3100/health || exit 1

# Run the Ultimate MCP Server (uses dashboard-hub.js for UI)
CMD ["node", "src/server.js"]
