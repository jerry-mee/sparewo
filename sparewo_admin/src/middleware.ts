import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

// Define public paths that do not require authentication
const PUBLIC_PATHS = new Set([
  '/auth/sign-in',
  '/auth/sign-up',
  '/auth/forgot-password',
]);

// Define paths related to authentication
const AUTH_PATHS = new Set([
  '/auth/sign-in',
  '/auth/sign-up',
  '/auth/forgot-password',
]);

const ROOT_PATH = '/';
const SIGN_IN_PATH = '/auth/sign-in';

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const authToken = request.cookies.get('auth_token')?.value;

  const isPublicPath = PUBLIC_PATHS.has(pathname);
  const isAuthPath = AUTH_PATHS.has(pathname);

  // Case 1: User is authenticated
  if (authToken) {
    if (isAuthPath) {
      const url = request.nextUrl.clone();
      url.pathname = ROOT_PATH;
      return NextResponse.redirect(url);
    }
    return NextResponse.next();
  }

  // Case 2: User is not authenticated
  if (!authToken) {
    if (!isPublicPath) {
      const url = request.nextUrl.clone();
      url.pathname = SIGN_IN_PATH;
      url.searchParams.set('redirectedFrom', pathname);
      return NextResponse.redirect(url);
    }
    return NextResponse.next();
  }

  return NextResponse.next();
}

// Update the matcher to be more specific for App Router
export const config = {
  matcher: [
    /*
     * Match all request paths except:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public folder
     */
    '/((?!api|_next/static|_next/image|favicon.ico|public).*)',
  ],
};