import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import type { AdminRole, AdminClaims } from "@bandz/shared/types";
import { hasMinimumRole } from "@bandz/shared/constants";

/**
 * Validates that the caller is authenticated and has the minimum required admin role.
 * Returns the caller's admin claims.
 */
export function requireAdminRole(
  request: CallableRequest,
  minimumRole: AdminRole,
): AdminClaims {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Autenticação necessária");
  }

  const role = request.auth.token.role as AdminRole | undefined;

  if (!role) {
    throw new HttpsError(
      "permission-denied",
      "Usuário não possui role de admin",
    );
  }

  if (!hasMinimumRole(role, minimumRole)) {
    throw new HttpsError(
      "permission-denied",
      `Role "${role}" insuficiente. Mínimo: "${minimumRole}"`,
    );
  }

  return {
    role,
    clientId: request.auth.token.clientId as string | undefined,
  };
}
