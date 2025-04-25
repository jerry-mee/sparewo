#!/bin/bash

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BOLD}${GREEN}===== SpareWo Admin: Firebase Error Code Fix =====${NC}"
echo -e "This script will fix the Firebase error code type mismatch"

# Check if firebase.service.ts exists
if [ -f "services/firebase.service.ts" ]; then
  firebase_path="services/firebase.service.ts"
elif [ -f "src/services/firebase.service.ts" ]; then
  firebase_path="src/services/firebase.service.ts"
else
  echo -e "${RED}✗ Could not find firebase.service.ts${NC}"
  exit 1
fi

echo -e "${BLUE}[Step 1]${NC} Backing up original firebase.service.ts..."
cp "$firebase_path" "${firebase_path}.error-bak"
echo -e "${GREEN}✓ Backup created at ${firebase_path}.error-bak${NC}"

echo -e "${BLUE}[Step 2]${NC} Fixing Firebase error code comparisons..."

# Replace all error code comparisons with a more type-safe approach
sed -i.tmp "s/if (error.code === 'unavailable' || error.code === 'network-request-failed')/if (error.code === 'unavailable' || error.message?.includes('network') || error.message?.includes('connection'))/" "$firebase_path"

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ Fixed error code comparisons in ${firebase_path}${NC}"
else
  echo -e "${RED}✗ Failed to fix error code comparisons${NC}"
  exit 1
fi

# Fix all instances of the same pattern
sed -i.tmp "s/if (error.code === 'unavailable' || error.code === 'network-request-failed')/if (error.code === 'unavailable' || error.message?.includes('network') || error.message?.includes('connection'))/" "$firebase_path"

# Clean up temporary files
rm -f "${firebase_path}.tmp"

echo -e "\n${BOLD}${GREEN}Firebase error code comparisons fixed successfully!${NC}"
echo -e "Now run the build script again:"
echo -e "  ${BOLD}./build-sparewo-admin.sh${NC}"