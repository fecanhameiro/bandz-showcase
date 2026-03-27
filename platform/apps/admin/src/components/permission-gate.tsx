"use client";

import type { ReactNode } from "react";
import { useAbility } from "./ability-provider";

interface PermissionGateProps {
  action: "view" | "create" | "edit" | "delete" | "manage";
  resource: "artists" | "places" | "events" | "users" | "clients" | "settings" | "feedbacks" | "style-groups";
  fallback?: ReactNode;
  children: ReactNode;
}

export function PermissionGate({ action, resource, fallback = null, children }: PermissionGateProps) {
  const ability = useAbility();
  if (!ability.can(action, resource)) return <>{fallback}</>;
  return <>{children}</>;
}
