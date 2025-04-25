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
