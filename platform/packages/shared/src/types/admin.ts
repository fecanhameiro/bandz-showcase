import type { FirestoreTimestamp } from "./common.js";

export const AdminRoles = ["superadmin", "admin", "editor", "viewer"] as const;
export type AdminRole = (typeof AdminRoles)[number];

export interface AdminClaims {
  role: AdminRole;
  clientId?: string;
}

export interface AdminUser {
  uid: string;
  email: string;
  displayName: string;
  role: AdminRole;
  clientId?: string;
  disabled: boolean;
  createdAt?: FirestoreTimestamp | Date;
  updatedAt?: FirestoreTimestamp | Date;
  createdByUid?: string;
  createdByEmail?: string;
}

export interface Client {
  id?: string;
  name: string;
  slug: string;
  placeIds: string[];
  active: boolean;
  contactEmail?: string;
  contactPhone?: string;
  createdAt?: FirestoreTimestamp | Date;
  updatedAt?: FirestoreTimestamp | Date;
  createdByUid?: string;
  createdByEmail?: string;
}

export type AuditAction =
  | "create"
  | "update"
  | "delete"
  | "enable"
  | "disable"
  | "login"
  | "set_claims";

export interface AuditLogEntry {
  action: AuditAction;
  resource: string;
  resourceId?: string;
  performedByUid: string;
  performedByEmail: string;
  details?: Record<string, unknown>;
  timestamp?: FirestoreTimestamp | Date;
}
