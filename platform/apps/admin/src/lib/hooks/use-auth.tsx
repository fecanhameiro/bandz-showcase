"use client";

import { createContext, useContext, useEffect, useState, useCallback, type ReactNode } from "react";
import {
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut as firebaseSignOut,
  sendPasswordResetEmail,
  updateProfile,
  updatePassword,
  type User,
} from "firebase/auth";
import { getFirebaseAuth } from "@/lib/firebase";
import type { AdminRole } from "@bandz/shared/types";

export interface AdminClaims {
  role: AdminRole;
  clientId?: string;
}

interface AuthState {
  user: User | null;
  claims: AdminClaims | null;
  loading: boolean;
}

interface AuthContextValue extends AuthState {
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
  resetPassword: (email: string) => Promise<void>;
  updateDisplayName: (name: string) => Promise<void>;
  updateUserPassword: (newPassword: string) => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<AuthState>({
    user: null,
    claims: null,
    loading: true,
  });

  useEffect(() => {
    const auth = getFirebaseAuth();
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      if (user) {
        const tokenResult = await user.getIdTokenResult(true);
        const claims: AdminClaims = {
          role: (tokenResult.claims.role as AdminRole) ?? "viewer",
          clientId: tokenResult.claims.clientId as string | undefined,
        };
        setState({ user, claims, loading: false });
      } else {
        setState({ user: null, claims: null, loading: false });
      }
    });
    return unsubscribe;
  }, []);

  const signIn = useCallback(async (email: string, password: string) => {
    const auth = getFirebaseAuth();
    await signInWithEmailAndPassword(auth, email, password);
  }, []);

  const signOut = useCallback(async () => {
    const auth = getFirebaseAuth();
    await firebaseSignOut(auth);
  }, []);

  const resetPassword = useCallback(async (email: string) => {
    const auth = getFirebaseAuth();
    await sendPasswordResetEmail(auth, email);
  }, []);

  const updateDisplayName = useCallback(async (name: string) => {
    const auth = getFirebaseAuth();
    if (auth.currentUser) {
      await updateProfile(auth.currentUser, { displayName: name });
    }
  }, []);

  const updateUserPassword = useCallback(async (newPassword: string) => {
    const auth = getFirebaseAuth();
    if (auth.currentUser) {
      await updatePassword(auth.currentUser, newPassword);
    }
  }, []);

  return (
    <AuthContext value={{
      ...state,
      signIn,
      signOut,
      resetPassword,
      updateDisplayName,
      updateUserPassword,
    }}>
      {children}
    </AuthContext>
  );
}

export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext);
  if (!context) throw new Error("useAuth must be used within AuthProvider");
  return context;
}
