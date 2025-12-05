#!/bin/sh

# Start Python backend in background
echo "Starting Python backend on port 8001..."
cd /app && python -m backend.main &
BACKEND_PID=$!

# Wait a moment for backend to start
sleep 2

# Start NGINX in foreground
echo "Starting NGINX on port 80..."
nginx -g "daemon off;" &
NGINX_PID=$!

# Wait for either process to exit
wait $BACKEND_PID $NGINX_PID
