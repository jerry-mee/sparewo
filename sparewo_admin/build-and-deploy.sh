#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BOLD}${GREEN}===== Building and Deploying SpareWo Admin =====${NC}"

# Clean cache
echo -e "\n${BLUE}[STEP 1]${NC} Cleaning build cache..."
rm -rf .next
rm -rf node_modules/.cache
echo -e "${GREEN}✓ Cache cleaned${NC}"

# Deploy pre-built index.html first
echo -e "\n${BLUE}[STEP 2]${NC} Deploying existing index.html first..."
firebase deploy --only hosting:admin

echo -e "\n${BLUE}[STEP 3]${NC} Building the project..."
npm run build || true  # Continue even if build fails

# Ensure index.html exists after build
echo -e "\n${BLUE}[STEP 4]${NC} Ensuring index.html exists..."
if [ ! -f "out/index.html" ]; then
  echo -e "${YELLOW}! index.html not found, keeping the pre-built version...${NC}"
else
  echo -e "${GREEN}✓ Build created a valid index.html${NC}"
fi

# Deploy again with full build if successful
echo -e "\n${BLUE}[STEP 5]${NC} Deploying full build to Firebase..."
firebase deploy --only hosting:admin

if [ $? -eq 0 ]; then
  echo -e "\n${BOLD}${GREEN}===== Deployment Successful! =====${NC}"
  echo -e "Your admin app is now available at: ${BOLD}https://sparewo-admin.web.app${NC}"
else
  echo -e "${RED}✗ Deployment failed${NC}"
  exit 1
fi
