#!/bin/bash

# File: start-dev.sh
# Description: Script to run backend and frontend dev servers in parallel for the ProjectMonitor_Pro monorepo.
# Usage: Save this file, make it executable with `chmod +x start-dev.sh`, then run `./start-dev.sh`.
# This script runs the commands in the background and waits for them, with cleanup on exit.

# Function to handle cleanup on exit or interrupt
cleanup() {
    echo "Shutting down dev servers..."
    # Kill the background processes if they are still running
    if [ -n "$backend_pid" ]; then
        kill $backend_pid 2>/dev/null
    fi
    if [ -n "$frontend_pid" ]; then
        kill $frontend_pid 2>/dev/null
    fi
    exit 0
}

# Trap signals for cleanup (e.g., Ctrl+C)
trap cleanup SIGINT SIGTERM EXIT

# Run backend in background and capture PID
npm run dev:backend &
backend_pid=$!

# Run frontend in background and capture PID
npm run dev:frontend &
frontend_pid=$!

# Wait for both processes to finish
wait $backend_pid
wait $frontend_pid

# Cleanup (though wait should mean they're done)
cleanup