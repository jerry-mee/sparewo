#!/bin/bash

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BOLD}${GREEN}===== SpareWo Admin: Dynamic Routes Fix (3/3) =====${NC}"
echo -e "This script will fix dynamic routes for static export and add client-side navigation."

# Print progress function
print_progress() {
  local width=50
  local percent=$1
  local completed=$((width * percent / 100))
  local remaining=$((width - completed))
  
  printf "[${GREEN}"
  printf "%${completed}s" | tr ' ' '='
  printf ">${NC}"
  printf "%${remaining}s" | tr ' ' ' '
  printf "] %d%%\n" "$percent"
}

# Function to update dynamic route pages
update_dynamic_route_page() {
  local file_path="$1"
  
  if [ -f "$file_path" ]; then
    echo -e "${BLUE}Processing${NC} $file_path"
    
    # Make a backup
    cp "$file_path" "${file_path}.bak"
    
    # If the file already has generateStaticParams, don't modify it
    if grep -q "generateStaticParams" "$file_path"; then
      echo -e "${YELLOW}File already has generateStaticParams, skipping...${NC}"
      return 0
    fi
    
    # Add the export const dynamic = 'force-static' line if it doesn't exist
    if ! grep -q "export const dynamic" "$file_path"; then
      # If the file starts with 'use client', add the line after it
      if grep -q "^'use client'" "$file_path" || grep -q '^"use client"' "$file_path"; then
        sed -i.tmp "s/^'use client'/&\n\nexport const dynamic = 'force-static';/" "$file_path" || \
        sed -i.tmp 's/^"use client"/&\n\nexport const dynamic = "force-static";/' "$file_path"
      else
        # Otherwise add it at the beginning of the file
        echo -e "export const dynamic = 'force-static';\n\n$(cat "$file_path")" > "$file_path"
      fi
    fi
    
    # Add generateStaticParams function if it doesn't exist
    if ! grep -q "export function generateStaticParams" "$file_path"; then
      # Find the position of the default export
      local default_export_line=$(grep -n "export default function" "$file_path" | head -n 1 | cut -d ":" -f 1)
      
      if [ -n "$default_export_line" ]; then
        # Insert the generateStaticParams function before the default export
        sed -i.tmp "${default_export_line}i\\
export function generateStaticParams() {\\
  return [];\\
}\\
" "$file_path"
      fi
    fi
    
    # Clean up temporary files
    rm -f "${file_path}.tmp"
    echo -e "${GREEN}✓ Updated${NC} $file_path with generateStaticParams"
  else
    echo -e "${YELLOW}! File $file_path not found, skipping...${NC}"
  fi
}

# Step 1: Add ClientSideNavigator component for client-side navigation
echo -e "\n${PURPLE}[STEP 1]${NC} Creating ClientSideNavigator component..."

mkdir -p src/app/_components
cat > src/app/_components/ClientSideNavigator.tsx << 'EOL'
'use client';

import { useEffect } from 'react';
import { useRouter, usePathname } from 'next/navigation';

export default function ClientSideNavigator() {
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    // Add event listener for clicks on links
    const handleClick = (e: MouseEvent) => {
      const target = e.target as HTMLElement;
      const link = target.closest('a');
      
      if (link && link.href && link.href.startsWith(window.location.origin) && 
          !link.target && !link.download && !link.rel?.includes('external')) {
        e.preventDefault();
        const href = link.href.replace(window.location.origin, '');
        router.push(href);
      }
    };

    document.addEventListener('click', handleClick);
    
    return () => {
      document.removeEventListener('click', handleClick);
    };
  }, [router]);

  return null;
}
EOL

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ Successfully created ClientSideNavigator component${NC}"
  print_progress 20
else
  echo -e "${RED}✗ Failed to create ClientSideNavigator component${NC}"
  exit 1
fi

# Step 2: Create script helper for dynamic routes
echo -e "\n${PURPLE}[STEP 2]${NC} Creating script helper for dynamic routes..."

cat > src/app/layout-script-helper.tsx << 'EOL'
// This helper ensures client.js scripts get automatically included
// where needed for dynamic route pages

export function ScriptHelper({ pathname }: { pathname: string }) {
  let scriptSrc = '';
  
  if (pathname.startsWith('/products/') && !pathname.startsWith('/products/client/')) {
    scriptSrc = '/products/[id]/client.js';
  } else if (pathname.startsWith('/vendors/') && !pathname.startsWith('/vendors/client/')) {
    scriptSrc = '/vendors/[id]/client.js';
  }
  
  if (!scriptSrc) return null;
  
  return (
    <script
      src={scriptSrc}
      async
      defer
    />
  );
}
EOL

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ Successfully created script helper${NC}"
  print_progress 40
else
  echo -e "${RED}✗ Failed to create script helper${NC}"
  exit 1
fi

# Step 3: Update layout to include the ClientSideNavigator
echo -e "\n${PURPLE}[STEP 3]${NC} Updating layout.tsx with ClientSideNavigator..."

if [ -f "src/app/layout.tsx" ]; then
  # Make a backup
  cp src/app/layout.tsx src/app/layout.tsx.bak
  
  # Check if we need to add the ClientSideNavigator import
  if ! grep -q "ClientSideNavigator" src/app/layout.tsx; then
    # Check if we need to add the ScriptHelper import
    if ! grep -q "ScriptHelper" src/app/layout.tsx; then
      # Find the imports section
      first_import_line=$(grep -n "import" src/app/layout.tsx | head -n 1 | cut -d ":" -f 1)
      
      if [ -n "$first_import_line" ]; then
        # Add both imports at the top
        sed -i.tmp "${first_import_line}i\\
import ClientSideNavigator from './_components/ClientSideNavigator';\\
import { ScriptHelper } from './layout-script-helper';\\
" src/app/layout.tsx
      fi
    else
      # Add just the ClientSideNavigator import
      first_import_line=$(grep -n "import" src/app/layout.tsx | head -n 1 | cut -d ":" -f 1)
      
      if [ -n "$first_import_line" ]; then
        sed -i.tmp "${first_import_line}i\\
import ClientSideNavigator from './_components/ClientSideNavigator';\\
" src/app/layout.tsx
      fi
    fi
    
    # Find the body tag
    body_line=$(grep -n "<body" src/app/layout.tsx | head -n 1 | cut -d ":" -f 1)
    
    # Find the closing body tag
    closing_body_line=$(grep -n "</body>" src/app/layout.tsx | head -n 1 | cut -d ":" -f 1)
    
    if [ -n "$closing_body_line" ]; then
      # Add the ClientSideNavigator and ScriptHelper before the closing body tag
      sed -i.tmp "${closing_body_line}i\\
          <ClientSideNavigator />\\
          <ScriptHelper pathname={typeof window !== 'undefined' ? window.location.pathname : ''} />\\
" src/app/layout.tsx
    fi
    
    rm -f src/app/layout.tsx.tmp
    echo -e "${GREEN}✓ Updated layout.tsx with ClientSideNavigator and ScriptHelper${NC}"
  else
    echo -e "${YELLOW}! ClientSideNavigator already in layout.tsx${NC}"
  fi
else
  echo -e "${YELLOW}! src/app/layout.tsx not found, checking alternative locations...${NC}"
  
  # Try finding layout.tsx in other locations
  layout_files=$(find src -name "layout.tsx")
  
  if [ -n "$layout_files" ]; then
    echo -e "${GREEN}Found the following layout files:${NC}"
    echo "$layout_files"
    
    # Update the first layout file found
    first_layout=$(echo "$layout_files" | head -n 1)
    echo -e "Updating $first_layout"
    
    # Make a backup
    cp "$first_layout" "${first_layout}.bak"
    
    # Check if we need to add the ClientSideNavigator import
    if ! grep -q "ClientSideNavigator" "$first_layout"; then
      # Find the imports section
      first_import_line=$(grep -n "import" "$first_layout" | head -n 1 | cut -d ":" -f 1)
      
      if [ -n "$first_import_line" ]; then
        # Add both imports at the top
        sed -i.tmp "${first_import_line}i\\
import ClientSideNavigator from '../_components/ClientSideNavigator';\\
import { ScriptHelper } from '../layout-script-helper';\\
" "$first_layout"
      fi
      
      # Find the closing body tag
      closing_body_line=$(grep -n "</body>" "$first_layout" | head -n 1 | cut -d ":" -f 1)
      
      if [ -n "$closing_body_line" ]; then
        # Add the ClientSideNavigator and ScriptHelper before the closing body tag
        sed -i.tmp "${closing_body_line}i\\
          <ClientSideNavigator />\\
          <ScriptHelper pathname={typeof window !== 'undefined' ? window.location.pathname : ''} />\\
" "$first_layout"
      fi
      
      rm -f "${first_layout}.tmp"
      echo -e "${GREEN}✓ Updated $first_layout with ClientSideNavigator and ScriptHelper${NC}"
    else
      echo -e "${YELLOW}! ClientSideNavigator already in $first_layout${NC}"
    fi
  else
    echo -e "${RED}✗ No layout.tsx files found in the project${NC}"
    echo -e "${YELLOW}Continuing with other fixes...${NC}"
  fi
fi

print_progress 60

# Step 4: Fix dynamic route pages
echo -e "\n${PURPLE}[STEP 4]${NC} Fixing dynamic route pages..."

# Find and update all dynamic route pages (files in directories with square brackets)
dynamic_routes=()

# Find all potential dynamic route page files
find src -type f -path "*/\[*\]/*" -name "page.tsx" | while read -r file; do
  dynamic_routes+=("$file")
  update_dynamic_route_page "$file"
done

# Find specific known dynamic routes
for route in "src/app/products/[id]/page.tsx" "src/app/vendors/[id]/page.tsx"; do
  if [ -f "$route" ] && [[ ! " ${dynamic_routes[@]} " =~ " $route " ]]; then
    update_dynamic_route_page "$route"
  fi
done

print_progress 80

# Step 5: Add a build and cleanup script
echo -e "\n${PURPLE}[STEP 5]${NC} Creating build script..."

cat > build-sparewo-admin.sh << 'EOL'
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
EOL

chmod +x build-sparewo-admin.sh

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ Created build script${NC}"
  print_progress 100
else
  echo -e "${RED}✗ Failed to create build script${NC}"
  exit 1
fi

echo -e "\n${BOLD}${GREEN}All fixes have been applied successfully!${NC}"
echo -e "\nTo build your project, run the build script:"
echo -e "  ${BOLD}./build-sparewo-admin.sh${NC}"
echo -e "\nThis should build your project successfully without webpack or undici errors."
echo -e "After building, you can deploy the 'out' directory to Firebase Hosting or any static hosting service."