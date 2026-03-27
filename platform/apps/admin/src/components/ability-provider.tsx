"use client";

import { createContext, useContext, useMemo, type ReactNode } from "react";
import { createMongoAbility, type MongoAbility } from "@casl/ability";
import { createContextualCan } from "@casl/react";
import { RolePermissions } from "@bandz/shared/constants";
import { useAuth } from "@/lib/hooks/use-auth";

type Actions = "view" | "create" | "edit" | "delete" | "manage";
type Subjects = "artists" | "places" | "events" | "users" | "clients" | "settings" | "feedbacks" | "style-groups";
export type AppAbility = MongoAbility<[Actions, Subjects]>;

const AbilityContext = createContext<AppAbility>(createMongoAbility<[Actions, Subjects]>());
export const Can = createContextualCan(AbilityContext.Consumer);

export function AbilityProvider({ children }: { children: ReactNode }) {
  const { claims } = useAuth();

  const ability = useMemo(() => {
    if (!claims?.role) return createMongoAbility<[Actions, Subjects]>();

    const permissions = RolePermissions[claims.role] ?? [];
    const rules = permissions.flatMap((p) =>
      p.actions.map((action) => ({
        action: action as Actions,
        subject: p.resource as Subjects,
      })),
    );
    return createMongoAbility<[Actions, Subjects]>(rules);
  }, [claims]);

  return <AbilityContext value={ability}>{children}</AbilityContext>;
}

export function useAbility(): AppAbility {
  return useContext(AbilityContext);
}
