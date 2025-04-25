import { FirebaseError } from 'firebase/app';

/**
 * Converts Firebase error codes to user-friendly messages
 * @param error - Firebase error or any other error object
 * @returns User-friendly error message
 */
export const handleFirebaseError = (error: unknown): string => {
  // For Firebase Auth errors
  if (error instanceof FirebaseError) {
    switch (error.code) {
      // Authentication errors
      case 'auth/email-already-in-use':
        return 'This email address is already associated with an account.';
      case 'auth/invalid-email':
        return 'Please provide a valid email address.';
      case 'auth/user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'auth/user-not-found':
      case 'auth/wrong-password':
        return 'Invalid email or password. Please try again.';
      case 'auth/too-many-requests':
        return 'Too many failed login attempts. Please try again later or reset your password.';
      case 'auth/account-exists-with-different-credential':
        return 'An account already exists with the same email address but different sign-in credentials.';
      case 'auth/requires-recent-login':
        return 'This operation requires a recent login. Please sign in again and retry.';
      case 'auth/user-mismatch':
        return 'The supplied credentials do not match the previously signed in user.';
      case 'auth/weak-password':
        return 'Password is too weak. Please use a stronger password.';

      // Firestore errors
      case 'permission-denied':
        return 'You do not have permission to perform this action.';
      case 'unavailable':
        return 'The service is currently unavailable. Please try again later.';
      case 'not-found':
        return 'The requested document was not found.';
      
      // Default case for other Firebase errors
      default:
        console.error('Firebase error:', error);
        return error.message || 'An unknown error occurred. Please try again.';
    }
  }
  
  // Handle non-Firebase errors
  if (error instanceof Error) {
    console.error('Application error:', error);
    return error.message || 'An error occurred. Please try again.';
  }

  // Fallback for unknown error types
  console.error('Unknown error:', error);
  return 'An unknown error occurred. Please try again.';
};

export default handleFirebaseError;