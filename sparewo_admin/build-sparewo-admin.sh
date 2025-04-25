#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BOLD}${GREEN}===== Building SpareWo Admin =====${NC}"

# Clean cache
echo -e "\n${BLUE}[STEP 1]${NC} Cleaning build cache..."
rm -rf .next
rm -rf node_modules/.cache
rm -rf out
echo -e "${GREEN}✓ Cache cleaned${NC}"

# Install dependencies if node_modules is missing or package.json was modified
if [ ! -d "node_modules" ] || [ "package.json" -nt "node_modules" ]; then
  echo -e "\n${BLUE}[STEP 2]${NC} Installing dependencies..."
  npm install
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Dependencies installed${NC}"
  else
    echo -e "${RED}✗ Failed to install dependencies${NC}"
    exit 1
  fi
else
  echo -e "\n${BLUE}[STEP 2]${NC} Dependencies already installed, skipping..."
fi

# Build the project
echo -e "\n${BLUE}[STEP 3]${NC} Building the project..."
npm run build

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ Build completed successfully${NC}"
  echo -e "\n${BOLD}${GREEN}===== Build Successful! =====${NC}"
  echo -e "The static files are in the ${BOLD}out${NC} directory."
  echo -e "You can deploy these files to any static hosting service like Firebase."
  echo -e "\nTo test locally, you can use:"
  echo -e "  ${BOLD}npx serve out${NC}"
else
  echo -e "${RED}✗ Build failed${NC}"
  exit 1
fi
