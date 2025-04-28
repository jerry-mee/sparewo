// src/services/user.service.ts
import { safeCollection, safeDoc, safeRef, verifyAuth } from "@/lib/firebase-utils";
import type { User } from "firebase/auth";
import type { DocumentData, DocumentSnapshot, QueryDocumentSnapshot } from "firebase/firestore";
import { NOW, Timestamp } from "./firebase.service";

// Firebase modules will be loaded dynamically
let firebaseModules: {
  auth?: any;
  firestore?: any;
  storage?: any;
  initialized: boolean;
} = { initialized: false };

// Initialize Firebase modules when needed
async function loadFirebaseModules() {
  if (typeof window === 'undefined') {
    throw new Error("Firebase cannot be used on the server side");
  }
  
  if (firebaseModules.initialized) {
    return firebaseModules;
  }
  
  try {
    // Dynamically import modules
    const authModule = await import('firebase/auth');
    const firestoreModule = await import('firebase/firestore');
    const storageModule = await import('firebase/storage');
    
    firebaseModules = {
      auth: authModule,
      firestore: firestoreModule,
      storage: storageModule,
      initialized: true
    };
    
    return firebaseModules;
  } catch (error) {
    console.error("Failed to import Firebase modules:", error);
    throw new Error("Failed to load Firebase modules");
  }
}

// Get Firebase service instances
async function getFirebaseInstances() {
  if (typeof window === 'undefined') {
    throw new Error("Firebase cannot be used on the server side");
  }
  
  // Import our firebase service module to get instances
  const firebaseService = await import('./firebase.service');
  return firebaseService;
}

export enum UserRole {
  ADMIN = "admin",
  VENDOR = "vendor",
  CUSTOMER = "customer"
}

export enum UserStatus {
  ACTIVE = "active",
  INACTIVE = "inactive",
  SUSPENDED = "suspended"
}

export interface UserData {
  id?: string;
  email: string;
  displayName?: string;
  phoneNumber?: string;
  role: UserRole;
  status: UserStatus;
  photoURL?: string;
  createdAt?: any;
  updatedAt?: any;
  lastLoginAt?: any;
  // Additional fields depending on role
  vendorId?: string;  // If role is VENDOR
  customerId?: string; // If role is CUSTOMER
}

const userService = {
  /**
   * Create a new admin user
   */
  createAdminUser: async (email: string, password: string, userData: Partial<UserData>): Promise<UserData> => {
    try {
      if (typeof window === 'undefined') {
        throw new Error("This function cannot be called on the server side");
      }

      // Load Firebase modules
      const firebase = await loadFirebaseModules();
      
      // Get Firebase instances from our service
      const firebaseService = await import('./firebase.service');
      const authInstance = await firebase.auth.getAuth();
      
      if (!authInstance) {
        throw new Error("Firebase Auth is not initialized");
      }

      // Create Firebase Auth user
      const userCredential = await firebase.auth.createUserWithEmailAndPassword(
        authInstance, 
        email, 
        password
      );
      const user = userCredential.user;
      
      // Update profile if display name provided
      if (userData.displayName) {
        await firebase.auth.updateProfile(user, {
          displayName: userData.displayName,
          photoURL: userData.photoURL || null
        });
      }
      
      // Get Firestore instance
      const firestoreInstance = await firebase.firestore.getFirestore();
      
      if (!firestoreInstance) {
        throw new Error("Firestore is not initialized");
      }
      
      // Prepare user data with required fields
      const completeUserData: UserData = {
        email: user.email || email,
        role: UserRole.ADMIN,
        status: UserStatus.ACTIVE, // Ensure status is set
        ...userData,
      };
      
      // Add user data to Firestore
      const userDocRef = firebase.firestore.doc(firestoreInstance, "users", user.uid);
      await firebase.firestore.setDoc(userDocRef, {
        ...completeUserData,
        createdAt: firebase.firestore.Timestamp.now(),
        updatedAt: firebase.firestore.Timestamp.now()
      });
      
      return {
        id: user.uid,
        ...completeUserData
      };
    } catch (error) {
      console.error("Error creating admin user:", error);
      throw error;
    }
  },
  
  /**
   * Get all users
   */
  getAllUsers: async (): Promise<UserData[]> => {
    try {
      if (typeof window === 'undefined') {
        throw new Error("This function cannot be called on the server side");
      }

      // Load Firebase modules
      const firebase = await loadFirebaseModules();
      
      // Get Firestore instance
      const firestoreInstance = await firebase.firestore.getFirestore();
      
      if (!firestoreInstance) {
        throw new Error("Firestore is not initialized");
      }

      const usersRef = firebase.firestore.collection(firestoreInstance, "users");
      const snapshot = await firebase.firestore.getDocs(usersRef);
      
      return snapshot.docs.map((doc: QueryDocumentSnapshot<DocumentData>) => ({
        id: doc.id,
        ...doc.data()
      } as UserData));
    } catch (error) {
      console.error("Error getting users:", error);
      throw error;
    }
  },
  
  /**
   * Get users by role
   */
  getUsersByRole: async (role: UserRole): Promise<UserData[]> => {
    try {
      if (typeof window === 'undefined') {
        throw new Error("This function cannot be called on the server side");
      }

      // Load Firebase modules
      const firebase = await loadFirebaseModules();
      
      // Get Firestore instance
      const firestoreInstance = await firebase.firestore.getFirestore();
      
      if (!firestoreInstance) {
        throw new Error("Firestore is not initialized");
      }

      const usersRef = firebase.firestore.collection(firestoreInstance, "users");
      const q = firebase.firestore.query(
        usersRef,
        firebase.firestore.where("role", "==", role),
        firebase.firestore.orderBy("createdAt", "desc")
      );
      
      const snapshot = await firebase.firestore.getDocs(q);
      
      return snapshot.docs.map((doc: QueryDocumentSnapshot<DocumentData>) => ({
        id: doc.id,
        ...doc.data()
      } as UserData));
    } catch (error) {
      console.error(`Error getting ${role} users:`, error);
      throw error;
    }
  },
  
  /**
   * Get a single user by ID
   */
  getUserById: async (userId: string): Promise<UserData> => {
    try {
      if (typeof window === 'undefined') {
        throw new Error("This function cannot be called on the server side");
      }

      // Load Firebase modules
      const firebase = await loadFirebaseModules();
      
      // Get Firestore instance
      const firestoreInstance = await firebase.firestore.getFirestore();
      
      if (!firestoreInstance) {
        throw new Error("Firestore is not initialized");
      }

      const userRef = firebase.firestore.doc(firestoreInstance, "users", userId);
      const snapshot = await firebase.firestore.getDoc(userRef);
      
      if (!snapshot.exists()) {
        throw new Error(`User with ID ${userId} not found`);
      }
      
      return {
        id: snapshot.id,
        ...snapshot.data()
      } as UserData;
    } catch (error) {
      console.error("Error getting user:", error);
      throw error;
    }
  },
  
  /**
   * Update a user
   */
  updateUser: async (userId: string, userData: Partial<UserData>): Promise<UserData> => {
    try {
      if (typeof window === 'undefined') {
        throw new Error("This function cannot be called on the server side");
      }

      // Load Firebase modules
      const firebase = await loadFirebaseModules();
      
      // Get Firestore instance
      const firestoreInstance = await firebase.firestore.getFirestore();
      
      if (!firestoreInstance) {
        throw new Error("Firestore is not initialized");
      }

      const userRef = firebase.firestore.doc(firestoreInstance, "users", userId);
      
      // Update the user in Firestore
      await firebase.firestore.updateDoc(userRef, {
        ...userData,
        updatedAt: firebase.firestore.Timestamp.now()
      });
      
      // Return the updated user data
      const updatedSnapshot = await firebase.firestore.getDoc(userRef);
      
      if (!updatedSnapshot.exists()) {
        throw new Error(`User with ID ${userId} not found after update`);
      }
      
      return {
        id: updatedSnapshot.id,
        ...updatedSnapshot.data()
      } as UserData;
    } catch (error) {
      console.error("Error updating user:", error);
      throw error;
    }
  },
  
  /**
   * Change user status
   */
  updateUserStatus: async (userId: string, status: UserStatus): Promise<UserData> => {
    try {
      return await userService.updateUser(userId, { status });
    } catch (error) {
      console.error("Error updating user status:", error);
      throw error;
    }
  },
  
  /**
   * Upload a profile image for a user
   */
  uploadProfileImage: async (userId: string, file: File): Promise<string> => {
    try {
      if (typeof window === 'undefined') {
        throw new Error("This function cannot be called on the server side");
      }

      // Load Firebase modules
      const firebase = await loadFirebaseModules();
      
      // Get Storage instance
      const storageInstance = await firebase.storage.getStorage();
      
      if (!storageInstance) {
        throw new Error("Firebase Storage is not initialized");
      }

      const fileExtension = file.name.split(".").pop();
      const storageRef = firebase.storage.ref(storageInstance, `profileImages/${userId}.${fileExtension}`);
      
      // Upload the file
      await firebase.storage.uploadBytes(storageRef, file);
      
      // Get the download URL
      const photoURL = await firebase.storage.getDownloadURL(storageRef);
      
      // Update the user's photoURL
      await userService.updateUser(userId, { photoURL });
      
      return photoURL;
    } catch (error) {
      console.error("Error uploading profile image:", error);
      throw error;
    }
  },
  
  /**
   * Send password reset email
   */
  sendPasswordReset: async (email: string): Promise<boolean> => {
    try {
      if (typeof window === 'undefined') {
        throw new Error("This function cannot be called on the server side");
      }

      // Load Firebase modules
      const firebase = await loadFirebaseModules();
      
      // Get Auth instance
      const authInstance = await firebase.auth.getAuth();
      
      if (!authInstance) {
        throw new Error("Firebase Auth is not initialized");
      }

      await firebase.auth.sendPasswordResetEmail(authInstance, email);
      return true;
    } catch (error) {
      console.error("Error sending password reset:", error);
      throw error;
    }
  }
};

export default userService;