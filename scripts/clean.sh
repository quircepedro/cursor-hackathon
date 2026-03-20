#!/bin/bash

# Clean script to remove all build artifacts and caches

echo "🧹 Cleaning build artifacts..."

# Node
rm -rf node_modules
rm -rf apps/backend/node_modules
rm -rf apps/backend/dist
rm -rf packages/*/node_modules
rm -rf packages/*/dist

# Flutter
rm -rf apps/mobile/build
rm -rf apps/mobile/.dart_tool
rm -rf apps/mobile/coverage
rm -rf apps/mobile/.packages

# Cache
rm -rf .next
rm -rf out

# Logs
rm -f *.log
rm -f npm-debug.log*
rm -f yarn-debug.log*
rm -f yarn-error.log*

echo "✅ Clean complete!"
