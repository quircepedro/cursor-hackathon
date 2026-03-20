#!/bin/bash

# Environment variable validation script
# Checks that required environment variables are set for a given environment

set -e

ENV=${1:-.env}

if [ ! -f "$ENV" ]; then
  echo "❌ Error: $ENV file not found"
  echo "Copy from the corresponding example file:"
  echo "  cp environments/local/.env.local.example .env"
  exit 1
fi

echo "📋 Checking environment variables in $ENV..."

REQUIRED_VARS=(
  "NODE_ENV"
  "PORT"
  "DATABASE_URL"
  "REDIS_URL"
  "JWT_SECRET"
  "JWT_REFRESH_SECRET"
  "STORAGE_PROVIDER"
)

MISSING=0

for var in "${REQUIRED_VARS[@]}"; do
  if grep -q "^$var=" "$ENV"; then
    VALUE=$(grep "^$var=" "$ENV" | cut -d'=' -f2)
    if [ -z "$VALUE" ]; then
      echo "⚠️  $var is set but empty"
      ((MISSING++))
    else
      echo "✅ $var is set"
    fi
  else
    echo "❌ $var is missing"
    ((MISSING++))
  fi
done

if [ $MISSING -eq 0 ]; then
  echo ""
  echo "✅ All required environment variables are set!"
  exit 0
else
  echo ""
  echo "❌ $MISSING environment variable(s) missing or empty"
  exit 1
fi
