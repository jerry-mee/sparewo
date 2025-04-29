import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  where,
  orderBy,
  limit,
  updateDoc,
  serverTimestamp,
  DocumentData,
  QueryConstraint,
  startAfter
} from 'firebase/firestore';
import { db } from '../config';

// Generic function to get a document by ID
export const getDocumentById = async <T>(collectionName: string, id: string): Promise<T | null> => {
  try {
    const docRef = doc(db, collectionName, id);
    const docSnap = await getDoc(docRef);

    if (docSnap.exists()) {
      return { id: docSnap.id, ...docSnap.data() } as T;
    }

    return null;
  } catch (error) {
    console.error(`Error getting document from ${collectionName}:`, error);
    throw error;
  }
};

// Generic function to get documents with pagination
export const getDocuments = async <T>(
  collectionName: string,
  constraints: QueryConstraint[] = [],
  pageSize: number = 10,
  lastDoc?: DocumentData
): Promise<{ data: T[], lastDoc: DocumentData | undefined }> => {
  try {
    let q = query(
      collection(db, collectionName),
      ...constraints,
      limit(pageSize)
    );

    if (lastDoc) {
      q = query(q, startAfter(lastDoc));
    }

    const querySnapshot = await getDocs(q);

    const data: T[] = [];
    let lastVisible: DocumentData | undefined = undefined;

    querySnapshot.forEach((doc) => {
      data.push({ id: doc.id, ...doc.data() } as T);
      lastVisible = doc;
    });

    return { data, lastDoc: lastVisible };
  } catch (error) {
    console.error(`Error getting documents from ${collectionName}:`, error);
    throw error;
  }
};

// Generic function to update a document
export const updateDocument = async (
  collectionName: string,
  id: string,
  data: Partial<any>
): Promise<void> => {
  try {
    const docRef = doc(db, collectionName, id);
    await updateDoc(docRef, {
      ...data,
      updatedAt: serverTimestamp(),
    });
  } catch (error) {
    console.error(`Error updating document in ${collectionName}:`, error);
    throw error;
  }
};

// Get documents by field equality
export const getDocumentsByField = async <T>(
  collectionName: string,
  field: string,
  value: any,
  orderByField: string = 'createdAt',
  orderDirection: 'asc' | 'desc' = 'desc',
  pageSize: number = 10
): Promise<T[]> => {
  try {
    const q = query(
      collection(db, collectionName),
      where(field, '==', value),
      orderBy(orderByField, orderDirection),
      limit(pageSize)
    );

    const querySnapshot = await getDocs(q);

    const data: T[] = [];
    querySnapshot.forEach((doc) => {
      data.push({ id: doc.id, ...doc.data() } as T);
    });

    return data;
  } catch (error) {
    console.error(`Error getting documents from ${collectionName} by field:`, error);
    throw error;
  }
};

// Count documents in a collection with optional filtering
export const countDocuments = async (
  collectionName: string,
  constraints: QueryConstraint[] = []
): Promise<number> => {
  try {
    const q = query(
      collection(db, collectionName),
      ...constraints
    );

    const querySnapshot = await getDocs(q);
    return querySnapshot.size;
  } catch (error) {
    console.error(`Error counting documents in ${collectionName}:`, error);
    throw error;
  }
};
