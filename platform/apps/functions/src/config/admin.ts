import { initializeApp, getApps } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import { getStorage } from "firebase-admin/storage";
import { getMessaging } from "firebase-admin/messaging";

if (getApps().length === 0) {
  initializeApp();
}

export const getDb = () => getFirestore();

export const getFirebaseAuth = () => getAuth();

export const getFirebaseStorage = () => getStorage();

export const getFirebaseMessaging = () => getMessaging();
