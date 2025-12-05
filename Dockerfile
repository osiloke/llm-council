# Multi-stage Dockerfile for LLM Council
# Stage 1: Build frontend
FROM node:18-alpine AS frontend-builder

WORKDIR /app/frontend

# Copy frontend package files
COPY frontend/package*.json ./
COPY frontend/vite.config.js ./

# Install dependencies
RUN npm ci

# Copy frontend source and build
COPY frontend/src ./src
RUN npm run build

# Stage 2: Build backend
FROM python:3.11-slim AS backend-builder

WORKDIR /app

# Install uv package manager
RUN pip install uv

# Copy pyproject.toml and install dependencies
COPY pyproject.toml ./
RUN uv venv --python 3.11 && \
    uv pip install -e .

# Copy backend source
COPY backend ./backend

# Stage 3: Production image with NGINX
FROM nginx:alpine

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Copy built frontend to NGINX html directory
COPY --from=frontend-builder /app/frontend/dist /usr/share/nginx/html

# Copy NGINX configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy backend application
COPY --from=backend-builder /app /app

# Create data directory for conversations
RUN mkdir -p /app/data/conversations && \
    chown -R nginx:nginx /app/data

# Copy startup script
COPY start-docker.sh /start-docker.sh
RUN chmod +x /start-docker.sh

# Expose port 80
EXPOSE 80

# Use dumb-init to manage processes
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# Start both NGINX and backend
CMD ["/start-docker.sh"]
