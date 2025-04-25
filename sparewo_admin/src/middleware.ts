import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

// Define public paths that do not require authentication
// Use a Set for efficient lookup
const PUBLIC_PATHS = new Set([
  '/auth/sign-in',
  '/auth/sign-up',
  '/auth/forgot-password',
  // Add other public paths like '/about', '/contact' if needed
]);

// Define paths related to authentication
const AUTH_PATHS = new Set([
  '/auth/sign-in',
  '/auth/sign-up',
  '/auth/forgot-password',
]);

// Define the root path (usually the dashboard)
const ROOT_PATH = '/';
const SIGN_IN_PATH = '/auth/sign-in';

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const authToken = request.cookies.get('auth_token')?.value; // Get token value

  const isPublicPath = PUBLIC_PATHS.has(pathname);
  const isAuthPath = AUTH_PATHS.has(pathname);

  // Case 1: User is authenticated
  if (authToken) {
    // If trying to access an authentication page (like sign-in) while logged in,
    // redirect to the dashboard (root path).
    if (isAuthPath) {
      const url = request.nextUrl.clone();
      url.pathname = ROOT_PATH;
      return NextResponse.redirect(url);
    }
    // Otherwise, allow access to the requested page (could be dashboard or other protected route)
    return NextResponse.next();
  }

  // Case 2: User is not authenticated
  if (!authToken) {
    // If trying to access a protected route (not public), redirect to sign-in.
    if (!isPublicPath) {
      const url = request.nextUrl.clone();
      url.pathname = SIGN_IN_PATH;
      // Optionally, add the intended destination as a query parameter for redirect after login
      url.searchParams.set('redirectedFrom', pathname);
      return NextResponse.redirect(url);
    }
    // Otherwise, allow access to the requested public page.
    return NextResponse.next();
  }

  // Default case (should ideally not be reached with the logic above)
  return NextResponse.next();
}

// Configure the matcher to apply the middleware
export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - Any paths with a file extension (e.g., .png, .jpg)
     *
     * This ensures the middleware runs on page navigations but not static assets.
     */
    '/((?!api|_next/static|_next/image|favicon.ico|.*\\.\\w+).*)',
  ],
};
