// src/lib/firebase-utils.ts
import type {
  Firestore,
  DocumentReference,
  CollectionReference,
  DocumentData
} from "firebase/firestore";
import type { FirebaseStorage, StorageReference } from "firebase/storage";
import type { Auth } from "firebase/auth";
import type { Functions } from "firebase/functions";

/**
 * Safely create a collection reference, ensuring db is not null
 */
export function collection(
  db: Firestore | null, 
  path: string, 
  ...pathSegments: string[]
): CollectionReference<DocumentData> {
  if (typeof window === 'undefined') {
    throw new Error("Cannot use Firestore in server-side context");
  }

  if (!db) {
    throw new Error("Firestore is not initialized");
  }
  
  try {
    // Dynamic import of firestore module
    const firestoreModule = require('firebase/firestore');
    return firestoreModule.collection(db, path, ...pathSegments);
  } catch (error) {
    console.error("Error creating collection reference:", error);
    throw new Error("Failed to create collection reference");
  }
}

/**
 * Safely create a document reference, ensuring db is not null
 */
export function doc(
  db: Firestore | null, 
  path: string, 
  ...pathSegments: string[]
): DocumentReference<DocumentData> {
  if (typeof window === 'undefined') {
    throw new Error("Cannot use Firestore in server-side context");
  }

  if (!db) {
    throw new Error("Firestore is not initialized");
  }
  
  try {
    // Dynamic import of firestore module
    const firestoreModule = require('firebase/firestore');
    return firestoreModule.doc(db, path, ...pathSegments);
  } catch (error) {
    console.error("Error creating document reference:", error);
    throw new Error("Failed to create document reference");
  }
}

/**
 * Safely create a storage reference, ensuring storage is not null
 */
export function ref(
  storage: FirebaseStorage | null, 
  path?: string
): StorageReference {
  if (typeof window === 'undefined') {
    throw new Error("Cannot use Firebase Storage in server-side context");
  }

  if (!storage) {
    throw new Error("Firebase Storage is not initialized");
  }
  
  try {
    // Dynamic import of storage module
    const storageModule = require('firebase/storage');
    return storageModule.ref(storage, path);
  } catch (error) {
    console.error("Error creating storage reference:", error);
    throw new Error("Failed to create storage reference");
  }
}

/**
 * Verify auth is initialized
 */
export function verifyAuth(auth: Auth | null): Auth {
  if (typeof window === 'undefined') {
    throw new Error("Cannot use Firebase Auth in server-side context");
  }

  if (!auth) {
    throw new Error("Firebase Auth is not initialized");
  }
  
  return auth;
}

/**
 * Verify functions is initialized
 */
export function verifyFunctions(functions: Functions | null): Functions {
  if (typeof window === 'undefined') {
    throw new Error("Cannot use Firebase Functions in server-side context");
  }

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

// Create safe versions of the collection, doc, and ref functions
export const safeCollection = collection;
export const safeDoc = doc;
export const safeRef = ref;