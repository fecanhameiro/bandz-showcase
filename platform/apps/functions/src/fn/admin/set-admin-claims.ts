import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirebaseAuth, getDb } from "../../config/admin.js";
import { requireAdminRole } from "../../lib/admin-auth-guard.js";
import { Collections } from "@bandz/shared/constants";
import type { AuditLogEntry } from "@bandz/shared/types";

export const setAdminClaims = onCall({ invoker: "public", cors: true, region: "southamerica-east1" }, async (request) => {
  const callerClaims = requireAdminRole(request, "admin");

  const { uid, role, clientId } = request.data;

  if (!uid || !role) {
    throw new HttpsError("invalid-argument", "uid e role são obrigatórios");
  }

  // Only superadmin can set admin/superadmin roles
  if (
    (role === "superadmin" || role === "admin") &&
    callerClaims.role !== "superadmin"
  ) {
    throw new HttpsError(
      "permission-denied",
      "Apenas superadmin pode definir roles admin ou superadmin",
    );
  }

  // Prevent self-demotion
  if (uid === request.auth!.uid) {
    throw new HttpsError(
      "invalid-argument",
      "Você não pode alterar seu próprio role",
    );
  }

  try {
    const claims: Record<string, unknown> = { role };
    if (clientId) claims.clientId = clientId;
    await getFirebaseAuth().setCustomUserClaims(uid, claims);

    await getDb()
      .collection(Collections.ADMIN_USERS)
      .doc(uid)
      .update({ role, clientId: clientId || null, updatedAt: new Date() });

    const auditEntry: AuditLogEntry = {
      action: "set_claims",
      resource: "admin_user",
      resourceId: uid,
      performedByUid: request.auth!.uid,
      performedByEmail: request.auth!.token.email || "",
      details: { role, clientId },
      timestamp: new Date(),
    };
    await getDb().collection(Collections.AUDIT_LOG).add(auditEntry);

    return { success: true };
  } catch (error: unknown) {
    if (error instanceof HttpsError) throw error;
    console.error("Error setting claims:", error);
    throw new HttpsError("internal", "Falha ao atualizar claims");
  }
});
