import type { AdminRole } from "../types/admin.js";

type Action = "view" | "create" | "edit" | "delete" | "manage";
type Resource =
  | "artists"
  | "places"
  | "events"
  | "users"
  | "clients"
  | "settings"
  | "feedbacks"
  | "style-groups";

export interface RolePermission {
  resource: Resource;
  actions: Action[];
}

export const RolePermissions: Record<AdminRole, RolePermission[]> = {
  superadmin: [
    { resource: "artists", actions: ["view", "create", "edit", "delete"] },
    { resource: "places", actions: ["view", "create", "edit", "delete"] },
    { resource: "events", actions: ["view", "create", "edit", "delete"] },
    { resource: "users", actions: ["view", "create", "edit", "delete"] },
    { resource: "clients", actions: ["view", "create", "edit", "delete"] },
    {
      resource: "settings",
      actions: ["view", "edit", "manage"],
    },
    { resource: "feedbacks", actions: ["view", "edit", "delete"] },
    { resource: "style-groups", actions: ["view", "create", "edit", "delete"] },
  ],
  admin: [
    { resource: "artists", actions: ["view", "create", "edit", "delete"] },
    { resource: "places", actions: ["view", "create", "edit", "delete"] },
    { resource: "events", actions: ["view", "create", "edit", "delete"] },
    { resource: "users", actions: ["view", "create", "edit"] },
    { resource: "clients", actions: ["view"] },
    { resource: "settings", actions: ["view", "edit"] },
  ],
  editor: [
    { resource: "artists", actions: ["view", "create", "edit"] },
    { resource: "places", actions: ["view", "create", "edit"] },
    { resource: "events", actions: ["view", "create", "edit"] },
    { resource: "settings", actions: ["view"] },
  ],
  viewer: [
    { resource: "artists", actions: ["view"] },
    { resource: "places", actions: ["view"] },
    { resource: "events", actions: ["view"] },
    { resource: "settings", actions: ["view"] },
  ],
};

export type NavItem =
  | "dashboard"
  | "artists"
  | "places"
  | "events"
  | "users"
  | "clients"
  | "settings"
  | "feedbacks"
  | "style-groups"
  | "test-notification";

export const RoleNavAccess: Record<AdminRole, NavItem[]> = {
  superadmin: [
    "dashboard",
    "artists",
    "places",
    "events",
    "users",
    "clients",
    "settings",
    "feedbacks",
    "style-groups",
    "test-notification",
  ],
  admin: ["dashboard", "artists", "places", "events", "users", "settings", "test-notification"],
  editor: ["dashboard", "artists", "places", "events", "settings"],
  viewer: ["dashboard", "artists", "places", "events", "settings"],
};

/** Role hierarchy — higher index = more privileges */
export const RoleHierarchy: AdminRole[] = [
  "viewer",
  "editor",
  "admin",
  "superadmin",
];

export function hasMinimumRole(
  userRole: AdminRole,
  requiredRole: AdminRole,
): boolean {
  return RoleHierarchy.indexOf(userRole) >= RoleHierarchy.indexOf(requiredRole);
}
