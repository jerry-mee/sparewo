import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

// This function can be marked `async` if using `await` inside
export function middleware(request: NextRequest) {
  // Get the pathname of the request
  const path = request.nextUrl.pathname;
  
  // Define public paths that don't require authentication
  const isPublicPath = path === '/login' || path === '/forgot-password';
  
  // Get the Firebase auth session cookie
  const session = request.cookies.get('__session')?.value;
  
  // For debugging - visible in server logs, not client
  console.log(`Middleware: Path ${path}, Public: ${isPublicPath}, Session: ${!!session}`);
  
  // Redirect logic
  if (isPublicPath && session) {
    // If user is authenticated and tries to access login page,
    // redirect to dashboard
    console.log('Redirecting authenticated user to dashboard');
    return NextResponse.redirect(new URL('/dashboard', request.url));
  }
  
  if (!isPublicPath && !session) {
    // If user is not authenticated and tries to access protected route,
    // redirect to login page
    console.log('Redirecting unauthenticated user to login');
    return NextResponse.redirect(new URL('/login', request.url));
  }
  
  return NextResponse.next();
}
 
// See "Matching Paths" below to learn more
export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico|images).*)'],
};