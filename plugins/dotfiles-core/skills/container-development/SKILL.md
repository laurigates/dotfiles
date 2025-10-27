---
name: Container Development
description: Container development with Docker, Dockerfiles, 12-factor principles, multi-stage builds, and Skaffold workflows. Automatically assists with containerization, orchestration, and secure image construction.
allowed-tools: Glob, Grep, Read, Bash, Edit, Write, TodoWrite
---

# Container Development

Expert knowledge for containerization and orchestration with focus on lean, secure container images and 12-factor app methodology.

## Core Expertise

**Container Image Construction**
- **Dockerfile/Containerfile Authoring**: Clear, efficient, and maintainable container build instructions
- **Multi-Stage Builds**: Creating minimal, production-ready images
- **Image Optimization**: Reducing image size, minimizing layer count, optimizing build cache
- **Security Hardening**: Non-root users, minimal base images, vulnerability scanning

**Container Orchestration**
- **Service Architecture**: Microservices with proper service discovery
- **Resource Management**: CPU/memory limits, auto-scaling policies, resource quotas
- **Health & Monitoring**: Health checks, readiness probes, observability patterns
- **Configuration Management**: Environment variables, secrets, configuration management

## Key Capabilities

- **12-Factor Adherence**: Ensures containerized applications follow 12-factor principles, especially configuration and statelessness
- **Health & Reliability**: Implements proper health checks, readiness probes, and restart policies
- **Skaffold Workflows**: Structures containerized applications for efficient development loops
- **Orchestration Patterns**: Designs service meshes, load balancing, and container communication
- **Performance Tuning**: Optimizes container resource usage, startup times, and runtime performance

## Image Crafting Process

1. **Analyze**: Understand application dependencies and build process
2. **Structure**: Design multi-stage Dockerfile, separating build-time from runtime needs
3. **Ignore**: Create comprehensive `.dockerignore` file
4. **Build & Scan**: Build image and scan for vulnerabilities
5. **Refine**: Iterate to optimize layer caching, reduce size, address security
6. **Validate**: Ensure image runs correctly and adheres to 12-factor principles

## Best Practices

**Multi-Stage Dockerfile Pattern**
```dockerfile
# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# Production stage
FROM node:20-alpine
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001
WORKDIR /app
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
USER nodejs
EXPOSE 3000
CMD ["node", "dist/main.js"]
```

**Security Best Practices**
- Use minimal base images (alpine, distroless)
- Run containers as non-root user
- Implement health checks for container reliability
- Scan images for vulnerabilities regularly
- Keep base images updated

**12-Factor App Principles**
- Configuration via environment variables
- Stateless processes
- Explicit dependencies
- Port binding for services
- Graceful shutdown handling

**Skaffold Preference**
- Favor Skaffold over Docker Compose for local development
- Continuous development loop with hot reload
- Production-like local environment

For detailed Dockerfile optimization techniques, orchestration patterns, security hardening, and Skaffold configuration, see REFERENCE.md.
