"use client";

import { usePathname } from "next/navigation";
import Link from "next/link";
import { LayoutGrid, Music, Store, CalendarDays, Building2, Users, Settings, Bell, MessageSquare, Palette, ChevronsLeft, ChevronsRight, X, LogOut } from "lucide-react";
import { cn } from "@/lib/utils";
import { useAuth } from "@/lib/hooks/use-auth";
import { useSidebar } from "@/lib/hooks/use-sidebar";
import { RoleNavAccess, type NavItem } from "@bandz/shared/constants";
import { Tooltip, TooltipContent, TooltipTrigger, TooltipProvider } from "@/components/ui/tooltip";

interface NavEntry {
  key: NavItem;
  label: string;
  icon: React.ElementType;
  href: string;
  group: "overview" | "content" | "management" | "system";
}

const NAV_ITEMS: NavEntry[] = [
  { key: "dashboard", label: "Dashboard", icon: LayoutGrid, href: "/dashboard", group: "overview" },
  { key: "artists", label: "Artistas", icon: Music, href: "/artists", group: "content" },
  { key: "places", label: "Casas", icon: Store, href: "/places", group: "content" },
  { key: "events", label: "Eventos", icon: CalendarDays, href: "/events", group: "content" },
  { key: "clients", label: "Clientes", icon: Building2, href: "/clients", group: "management" },
  { key: "users", label: "Usuários", icon: Users, href: "/users", group: "management" },
  { key: "style-groups", label: "Style Groups", icon: Palette, href: "/style-groups", group: "system" },
  { key: "feedbacks", label: "Feedbacks", icon: MessageSquare, href: "/feedbacks", group: "system" },
  { key: "test-notification", label: "Testar Push", icon: Bell, href: "/test-notification", group: "system" },
  { key: "settings", label: "Configurações", icon: Settings, href: "/settings", group: "system" },
];

const GROUP_LABELS: Record<string, string> = {
  overview: "Overview",
  content: "Conteúdo",
  management: "Gestão",
  system: "Sistema",
};

export function AppSidebar() {
  const pathname = usePathname();
  const { user, claims, signOut } = useAuth();
  const { collapsed, mobileOpen, setMobileOpen, toggleCollapsed } = useSidebar();

  const accessibleItems = NAV_ITEMS.filter((item) => {
    if (!claims?.role) return false;
    return (RoleNavAccess[claims.role] ?? []).includes(item.key);
  });

  const groups = ["overview", "content", "management", "system"].filter((g) =>
    accessibleItems.some((i) => i.group === g),
  );

  const initials = user?.displayName
    ? user.displayName.split(" ").map((n) => n[0]).join("").toUpperCase().slice(0, 2)
    : "?";

  return (
    <TooltipProvider delayDuration={0}>
      <aside
        className={cn(
          "fixed top-0 left-0 z-40 flex h-screen flex-col border-r border-[rgba(255,255,255,0.06)] transition-all duration-200",
          // Mobile: slide in/out
          mobileOpen ? "translate-x-0" : "-translate-x-full",
          "w-[260px]",
          // Desktop: always visible, respect collapsed state
          "lg:translate-x-0",
          collapsed ? "lg:w-[68px]" : "lg:w-[260px]",
        )}
        style={{ background: "linear-gradient(180deg, #0D0B1A, #13112A)" }}
      >
        {/* Logo + Mobile Close */}
        <div className={cn("flex items-center px-5 pt-8 pb-5", collapsed && "lg:justify-center lg:px-0")}>
          <span className={cn(
            "font-black tracking-[0.25em] lowercase gradient-text transition-all",
            collapsed ? "lg:text-base text-lg" : "text-lg",
          )}>
            <span className="lg:hidden">bandz</span>
            <span className="hidden lg:inline">{collapsed ? "b" : "bandz"}</span>
          </span>
          {/* Mobile close button */}
          <button
            onClick={() => setMobileOpen(false)}
            aria-label="Fechar menu"
            className="ml-auto flex h-8 w-8 items-center justify-center rounded-lg text-[rgba(255,255,255,0.5)] hover:text-[rgba(255,255,255,0.8)] transition-colors lg:hidden"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Nav */}
        <nav className="flex-1 overflow-y-auto px-3 space-y-1">
          {groups.map((group) => (
            <div key={group}>
              {!collapsed && (
                <div className="px-3 pt-5 pb-2 text-[10px] font-bold uppercase tracking-[1.5px] text-[rgba(255,255,255,0.25)] hidden lg:block">
                  {GROUP_LABELS[group]}
                </div>
              )}
              {/* Mobile: always show group labels */}
              <div className="px-3 pt-5 pb-2 text-[10px] font-bold uppercase tracking-[1.5px] text-[rgba(255,255,255,0.25)] lg:hidden">
                {GROUP_LABELS[group]}
              </div>
              {collapsed && <div className="pt-3 hidden lg:block" />}
              {accessibleItems
                .filter((i) => i.group === group)
                .map((item) => {
                  const isActive = pathname === item.href || pathname.startsWith(item.href + "/");
                  const Icon = item.icon;

                  const linkContent = (
                    <>
                      {isActive && (
                        <span className="absolute left-0 top-1/2 -translate-y-1/2 w-[3px] h-5 rounded-r-sm bg-[#6366F1] sidebar-glow" />
                      )}
                      <Icon className="h-5 w-5 shrink-0" strokeWidth={1.5} />
                      <span className="lg:hidden">{item.label}</span>
                      {!collapsed && <span className="hidden lg:inline">{item.label}</span>}
                    </>
                  );

                  const linkClassName = cn(
                    "relative flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-all duration-150",
                    collapsed && "lg:justify-center lg:px-0",
                    isActive
                      ? "text-white bg-[rgba(79,70,229,0.12)]"
                      : "text-[rgba(255,255,255,0.55)] hover:text-[rgba(255,255,255,0.85)] hover:bg-[rgba(255,255,255,0.04)]",
                  );

                  if (collapsed) {
                    return (
                      <div key={item.key}>
                        {/* Desktop: collapsed icon with tooltip */}
                        <Tooltip>
                          <TooltipTrigger asChild>
                            <Link href={item.href} onClick={() => setMobileOpen(false)} className={cn(linkClassName, "hidden lg:flex")}>
                              {linkContent}
                            </Link>
                          </TooltipTrigger>
                          <TooltipContent side="right">{item.label}</TooltipContent>
                        </Tooltip>
                        {/* Mobile: full link without tooltip */}
                        <Link href={item.href} onClick={() => setMobileOpen(false)} className={cn(linkClassName, "lg:hidden")}>
                          {linkContent}
                        </Link>
                      </div>
                    );
                  }

                  return (
                    <Link key={item.key} href={item.href} onClick={() => setMobileOpen(false)} className={linkClassName}>
                      {linkContent}
                    </Link>
                  );
                })}
            </div>
          ))}
        </nav>

        {/* Collapse Toggle — desktop only */}
        <div className="hidden lg:block px-3 py-2">
          <button
            onClick={toggleCollapsed}
            className="flex w-full items-center justify-center rounded-lg py-2 text-[rgba(255,255,255,0.3)] hover:text-[rgba(255,255,255,0.6)] transition-colors"
          >
            {collapsed ? <ChevronsRight className="h-4 w-4" /> : <ChevronsLeft className="h-4 w-4" />}
          </button>
        </div>

        {/* User Card */}
        <div className="border-t border-[rgba(255,255,255,0.06)] p-3">
          <div className={cn(
            "flex items-center gap-3 rounded-lg bg-[rgba(255,255,255,0.04)] px-3 py-2.5",
            collapsed && "lg:justify-center lg:px-0",
          )}>
            <Link href="/settings" onClick={() => setMobileOpen(false)} className="flex items-center gap-3 min-w-0 flex-1">
              <div className="relative flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-[#4F46E5] to-[#EF2D82] text-xs font-bold text-white">
                {initials}
                <div className="absolute -bottom-0.5 -right-0.5 h-2.5 w-2.5 rounded-full border-2 border-[#0D0B1A] bg-emerald-500" />
              </div>
              {/* Mobile: always show user info */}
              <div className="min-w-0 lg:hidden">
                <div className="truncate text-[13px] font-semibold text-[rgba(255,255,255,0.85)]">
                  {user?.displayName ?? "Usuário"}
                </div>
                <div className="text-[11px] text-[rgba(255,255,255,0.4)]">{claims?.role ?? ""}</div>
              </div>
              {/* Desktop: hide when collapsed */}
              {!collapsed && (
                <div className="min-w-0 hidden lg:block">
                  <div className="truncate text-[13px] font-semibold text-[rgba(255,255,255,0.85)]">
                    {user?.displayName ?? "Usuário"}
                  </div>
                  <div className="text-[11px] text-[rgba(255,255,255,0.4)]">{claims?.role ?? ""}</div>
                </div>
              )}
            </Link>
            {/* Sign-out button */}
            {!collapsed && (
              <Tooltip>
                <TooltipTrigger asChild>
                  <button
                    onClick={signOut}
                    className="hidden lg:flex h-7 w-7 shrink-0 items-center justify-center rounded-md text-[rgba(255,255,255,0.3)] hover:text-[rgba(255,255,255,0.7)] hover:bg-[rgba(255,255,255,0.06)] transition-colors"
                    aria-label="Sair"
                  >
                    <LogOut className="h-3.5 w-3.5" />
                  </button>
                </TooltipTrigger>
                <TooltipContent side="top">Sair</TooltipContent>
              </Tooltip>
            )}
            {/* Mobile sign-out */}
            <button
              onClick={signOut}
              className="flex lg:hidden h-7 w-7 shrink-0 items-center justify-center rounded-md text-[rgba(255,255,255,0.3)] hover:text-[rgba(255,255,255,0.7)] hover:bg-[rgba(255,255,255,0.06)] transition-colors"
              aria-label="Sair"
            >
              <LogOut className="h-3.5 w-3.5" />
            </button>
          </div>
        </div>
      </aside>
    </TooltipProvider>
  );
}
