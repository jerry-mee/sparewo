import { 
  getAuth, 
  createUserWithEmailAndPassword,
  updateProfile,
  sendPasswordResetEmail,
  User
} from "firebase/auth";
import { 
  collection, 
  doc,
  addDoc,
  setDoc,
  updateDoc, 
  deleteDoc, 
  getDocs,
  getDoc,
  query,
  where,
  orderBy,
  Timestamp 
} from "firebase/firestore";
import { getStorage, ref, uploadBytes, getDownloadURL } from "firebase/storage";
import { db, auth, storage } from "./firebase.service";
import { collection as safeCollection, doc as safeDoc, ref as safeRef, verifyAuth } from "@/lib/firebase-utils";

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
  createAdminUser: async (email: string, password: string, userData: Partial<UserData>) => {
    try {
      // Create Firebase Auth user
      const verifiedAuth = verifyAuth(auth);
      const userCredential = await createUserWithEmailAndPassword(verifiedAuth, email, password);
      const user = userCredential.user;
      
      // Update profile if display name provided
      if (userData.displayName) {
        await updateProfile(user, {
          displayName: userData.displayName,
          photoURL: userData.photoURL || null
        });
      }
      
      // Add user data to Firestore
      const userDocRef = safeDoc(db, "users", user.uid);
      await setDoc(userDocRef, {
        ...userData,
        email: user.email,
        role: UserRole.ADMIN,
        status: UserStatus.ACTIVE,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now()
      });
      
      return {
        id: user.uid,
        email: user.email,
        ...userData,
        role: UserRole.ADMIN
      };
    } catch (error) {
      console.error("Error creating admin user:", error);
      throw error;
    }
  },
  
  /**
   * Get all users
   */
  getAllUsers: async () => {
    try {
      const usersRef = safeCollection(db, "users");
      const snapshot = await getDocs(usersRef);
      
      return snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      console.error("Error getting users:", error);
      throw error;
    }
  },
  
  /**
   * Get users by role
   */
  getUsersByRole: async (role: UserRole) => {
    try {
      const usersRef = safeCollection(db, "users");
      const q = query(
        usersRef,
        where("role", "==", role),
        orderBy("createdAt", "desc")
      );
      
      const snapshot = await getDocs(q);
      
      return snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      console.error(`Error getting ${role} users:`, error);
      throw error;
    }
  },
  
  /**
   * Get a single user by ID
   */
  getUserById: async (userId: string) => {
    try {
      const userRef = safeDoc(db, "users", userId);
      const snapshot = await getDoc(userRef);
      
      if (!snapshot.exists()) {
        throw new Error(`User with ID ${userId} not found`);
      }
      
      return {
        id: snapshot.id,
        ...snapshot.data()
      };
    } catch (error) {
      console.error("Error getting user:", error);
      throw error;
    }
  },
  
  /**
   * Update a user
   */
  updateUser: async (userId: string, userData: Partial<UserData>) => {
    try {
      const userRef = safeDoc(db, "users", userId);
      
      // Update the user in Firestore
      await updateDoc(userRef, {
        ...userData,
        updatedAt: Timestamp.now()
      });
      
      // Return the updated user data
      const updatedSnapshot = await getDoc(userRef);
      
      if (!updatedSnapshot.exists()) {
        throw new Error(`User with ID ${userId} not found after update`);
      }
      
      return {
        id: updatedSnapshot.id,
        ...updatedSnapshot.data()
      };
    } catch (error) {
      console.error("Error updating user:", error);
      throw error;
    }
  },
  
  /**
   * Change user status
   */
  updateUserStatus: async (userId: string, status: UserStatus) => {
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
  uploadProfileImage: async (userId: string, file: File) => {
    try {
      const fileExtension = file.name.split(".").pop();
      const storageRef = safeRef(storage, `profileImages/${userId}.${fileExtension}`);
      
      // Upload the file
      await uploadBytes(storageRef, file);
      
      // Get the download URL
      const photoURL = await getDownloadURL(storageRef);
      
      // Update the user"s photoURL
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
  sendPasswordReset: async (email: string) => {
    try {
      const verifiedAuth = verifyAuth(auth);
      await sendPasswordResetEmail(verifiedAuth, email);
      return true;
    } catch (error) {
      console.error("Error sending password reset:", error);
      throw error;
    }
  }
};

export default userService;
