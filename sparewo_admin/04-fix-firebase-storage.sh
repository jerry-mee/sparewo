#!/bin/bash

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BOLD}${GREEN}===== SpareWo Admin: Firebase Storage Type Fix =====${NC}"
echo -e "This script will fix the Storage type error in firebase.service.ts"

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
cp "$firebase_path" "${firebase_path}.bak"
echo -e "${GREEN}✓ Backup created at ${firebase_path}.bak${NC}"

echo -e "${BLUE}[Step 2]${NC} Fixing Storage type import..."
# Replace the incorrect import line
sed -i.tmp "s/import { getStorage, Storage } from 'firebase\/storage';/import { getStorage } from 'firebase\/storage';/" "$firebase_path"

# Replace other Storage type references
sed -i.tmp "s/let firebaseStorage: Storage | null/let firebaseStorage: any | null/" "$firebase_path"
sed -i.tmp "s/export function ref(storage: FirebaseStorage | null, path?: string): StorageReference {/export function ref(storage: any | null, path?: string): StorageReference {/" "$firebase_path"

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ Fixed Storage type import in ${firebase_path}${NC}"
else
  echo -e "${RED}✗ Failed to fix Storage type import${NC}"
  exit 1
fi

# Clean up temporary files
rm -f "${firebase_path}.tmp"

echo -e "\n${BOLD}${GREEN}Firebase Storage type fixed successfully!${NC}"
echo -e "Now run the build script again:"
echo -e "  ${BOLD}./build-sparewo-admin.sh${NC}"