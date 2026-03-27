import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirebaseAuth, getDb } from "../../config/admin.js";
import { requireAdminRole } from "../../lib/admin-auth-guard.js";
import { Collections } from "@bandz/shared/constants";
import type { AdminUser, AuditLogEntry } from "@bandz/shared/types";

export const createAdminUser = onCall(
  { invoker: "public", cors: true, region: "southamerica-east1" },
  async (request) => {
    const callerClaims = requireAdminRole(request, "admin");

    const { email, displayName, role, clientId, password } = request.data;

    if (!email || !displayName || !role || !password) {
      throw new HttpsError(
        "invalid-argument",
        "email, displayName, role e password são obrigatórios",
      );
    }

    // Only superadmin can create admins/superadmins
    if (
      (role === "superadmin" || role === "admin") &&
      callerClaims.role !== "superadmin"
    ) {
      throw new HttpsError(
        "permission-denied",
        "Apenas superadmin pode criar usuários admin ou superadmin",
      );
    }

    // Non-superadmin can only create users within their own client
    if (
      callerClaims.role !== "superadmin" &&
      clientId !== callerClaims.clientId
    ) {
      throw new HttpsError(
        "permission-denied",
        "Você só pode criar usuários para seu próprio cliente",
      );
    }

    try {
      const userRecord = await getFirebaseAuth().createUser({
        email,
        displayName,
        password,
      });

      const claims: Record<string, unknown> = { role };
      if (clientId) claims.clientId = clientId;
      await getFirebaseAuth().setCustomUserClaims(userRecord.uid, claims);

      const adminUser: AdminUser = {
        uid: userRecord.uid,
        email,
        displayName,
        role,
        clientId: clientId || undefined,
        disabled: false,
        createdAt: new Date(),
        updatedAt: new Date(),
        createdByUid: request.auth!.uid,
        createdByEmail: request.auth!.token.email || "",
      };

      await getDb()
        .collection(Collections.ADMIN_USERS)
        .doc(userRecord.uid)
        .set(adminUser);

      const auditEntry: AuditLogEntry = {
        action: "create",
        resource: "admin_user",
        resourceId: userRecord.uid,
        performedByUid: request.auth!.uid,
        performedByEmail: request.auth!.token.email || "",
        details: { email, role, clientId },
        timestamp: new Date(),
      };
      await getDb().collection(Collections.AUDIT_LOG).add(auditEntry);

      return { uid: userRecord.uid, email, role };
    } catch (error: unknown) {
      if (error instanceof HttpsError) throw error;
      const msg = error instanceof Error ? error.message : "Unknown error";
      console.error("Error creating admin user:", msg);

      if (msg.includes("already in use") || msg.includes("EMAIL_EXISTS")) {
        throw new HttpsError("already-exists", "Este email já está em uso");
      }
      if (msg.includes("invalid email") || msg.includes("INVALID_EMAIL")) {
        throw new HttpsError("invalid-argument", "Email inválido");
      }
      if (msg.includes("weak password") || msg.includes("WEAK_PASSWORD")) {
        throw new HttpsError(
          "invalid-argument",
          "Senha muito fraca (mínimo 6 caracteres)",
        );
      }
      throw new HttpsError("internal", "Falha ao criar usuário admin");
    }
  },
);
