import { 
  Firestore, 
  DocumentReference, 
  CollectionReference, 
  collection as firestoreCollection,
  doc as firestoreDoc,
  DocumentData,
} from "firebase/firestore";
import { Auth } from "firebase/auth";
import { FirebaseStorage, StorageReference, ref as storageRef } from "firebase/storage";
import { Functions } from "firebase/functions";

/**
 * Safely create a collection reference, ensuring db is not null
 */
export function collection(db: Firestore | null, path: string, ...pathSegments: string[]): CollectionReference<DocumentData> {
  if (!db) {
    throw new Error("Firestore is not initialized");
  }
  return firestoreCollection(db, path, ...pathSegments);
}

/**
 * Safely create a document reference, ensuring db is not null
 */
export function doc(db: Firestore | null, path: string, ...pathSegments: string[]): DocumentReference<DocumentData> {
  if (!db) {
    throw new Error("Firestore is not initialized");
  }
  return firestoreDoc(db, path, ...pathSegments);
}

/**
 * Safely create a storage reference, ensuring storage is not null
 */
export function ref(storage: FirebaseStorage | null, path?: string): StorageReference {
  if (!storage) {
    throw new Error("Firebase Storage is not initialized");
  }
  return storageRef(storage, path);
}

/**
 * Verify auth is initialized
 */
export function verifyAuth(auth: Auth | null): Auth {
  if (!auth) {
    throw new Error("Firebase Auth is not initialized");
  }
  return auth;
}

/**
 * Verify functions is initialized
 */
export function verifyFunctions(functions: Functions | null): Functions {
  if (!functions) {
    throw new Error("Firebase Functions is not initialized");
  }
  return functions;
}

/**
 * Handles safe Firebase function calls with better error messages for static export
 */
export async function safelyCallFunction<T>(
  functionName: string, 
  callback: () => Promise<T>, 
  fallbackValue?: T
): Promise<T> {
  // Skip actual function calls during build or SSR
  if (typeof window === 'undefined') {
    console.log(`Firebase function ${functionName} skipped during build/SSR`);
    return fallbackValue as T;
  }
  
  try {
    return await callback();
  } catch (error) {
    console.error(`Error in Firebase function ${functionName}:`, error);
    
    // Check if it's a network error which is common in static exports
    const isNetworkError = error instanceof Error && 
      (error.message.includes('network') || error.message.includes('connection'));
    
    if (isNetworkError) {
      console.warn(`Network error in ${functionName}. This is expected in static exports.`);
    }
    
    // Return fallback if provided, otherwise re-throw
    if (fallbackValue !== undefined) {
      return fallbackValue;
    }
    throw error;
  }
}
