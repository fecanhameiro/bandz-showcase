"use client";

import { useState, useEffect, useCallback } from "react";
import {
  collection,
  query,
  orderBy,
  limit as firestoreLimit,
  onSnapshot,
  doc,
  getDoc,
  addDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  serverTimestamp,
  type DocumentData,
  type QueryConstraint,
} from "firebase/firestore";
import { getFirebaseDb } from "@/lib/firebase";
import { useAuth } from "./use-auth";

interface UseCollectionOptions {
  orderByField?: string;
  orderDirection?: "asc" | "desc";
  maxItems?: number;
  /** When false, skips the Firestore subscription entirely and returns empty data. */
  enabled?: boolean;
}

export function useCollection<T extends DocumentData>(
  collectionName: string,
  options: UseCollectionOptions = {},
) {
  const { orderByField = "name", orderDirection = "asc", maxItems, enabled = true } = options;
  const [data, setData] = useState<(T & { id: string })[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const { claims } = useAuth();

  // Use primitive deps to avoid re-subscribing on claims object reference change
  const role = claims?.role;
  const clientId = claims?.clientId;

  useEffect(() => {
    if (!enabled) {
      setData([]);
      setLoading(false);
      return;
    }

    const db = getFirebaseDb();
    const constraints: QueryConstraint[] = [orderBy(orderByField, orderDirection)];
    if (maxItems) constraints.push(firestoreLimit(maxItems));
    const q = query(collection(db, collectionName), ...constraints);

    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const items = snapshot.docs
          .map((d) => ({ id: d.id, ...d.data() } as T & { id: string }))
          .filter((item) => {
            if (role === "superadmin") return true;
            if (clientId && "clientId" in item) {
              return (item as Record<string, unknown>).clientId === clientId;
            }
            return false;
          });
        setData(items);
        setLoading(false);
        setError(null);
      },
      (err) => {
        console.error(`Firestore snapshot error [${collectionName}]:`, err);
        setError(err);
        setLoading(false);
      },
    );

    return unsubscribe;
  }, [collectionName, orderByField, orderDirection, role, clientId, maxItems, enabled]);

  return { data, loading, error };
}

export function useDocument<T extends DocumentData>(
  collectionName: string,
  docId: string | null,
) {
  const [data, setData] = useState<(T & { id: string }) | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    if (!docId) {
      setLoading(false);
      return;
    }

    const db = getFirebaseDb();
    getDoc(doc(db, collectionName, docId))
      .then((snap) => {
        if (snap.exists()) {
          setData({ id: snap.id, ...snap.data() } as T & { id: string });
        }
        setLoading(false);
      })
      .catch((err) => {
        console.error(`Firestore getDoc error [${collectionName}/${docId}]:`, err);
        setError(err);
        setLoading(false);
      });
  }, [collectionName, docId]);

  return { data, loading, error };
}

/** Pre-generate a Firestore document ID (useful for uploading images before creating the doc). */
export function generateDocId(collectionName: string): string {
  const db = getFirebaseDb();
  return doc(collection(db, collectionName)).id;
}

export function useFirestoreMutations(collectionName: string) {
  const { user } = useAuth();

  const create = useCallback(
    async (data: Record<string, unknown>) => {
      const db = getFirebaseDb();
      return addDoc(collection(db, collectionName), {
        ...data,
        createdDate: serverTimestamp(),
        lastUpdate: serverTimestamp(),
        ...(user && {
          userCreatedUid: user.uid,
          userCreatedName: user.displayName,
          userCreatedEmail: user.email,
        }),
      });
    },
    [collectionName, user],
  );

  const createWithId = useCallback(
    async (id: string, data: Record<string, unknown>) => {
      const db = getFirebaseDb();
      const docRef = doc(db, collectionName, id);
      await setDoc(docRef, {
        ...data,
        id,
        createdDate: serverTimestamp(),
        lastUpdate: serverTimestamp(),
        ...(user && {
          userCreatedUid: user.uid,
          userCreatedName: user.displayName,
          userCreatedEmail: user.email,
        }),
      });
      return docRef;
    },
    [collectionName, user],
  );

  const update = useCallback(
    async (docId: string, data: Record<string, unknown>) => {
      const db = getFirebaseDb();
      return updateDoc(doc(db, collectionName, docId), {
        ...data,
        lastUpdate: serverTimestamp(),
        ...(user && {
          userUpdatedUid: user.uid,
          userUpdatedName: user.displayName,
          userUpdatedEmail: user.email,
        }),
      });
    },
    [collectionName, user],
  );

  const remove = useCallback(
    async (docId: string) => {
      const db = getFirebaseDb();
      return deleteDoc(doc(db, collectionName, docId));
    },
    [collectionName],
  );

  return { create, createWithId, update, remove };
}
