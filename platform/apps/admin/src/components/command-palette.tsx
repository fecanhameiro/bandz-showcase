"use client";

import { useEffect, useMemo } from "react";
import { useRouter } from "next/navigation";
import {
  LayoutGrid, Music, Store, CalendarDays, Building2, Users, Settings, MessageSquare,
  Plus,
} from "lucide-react";
import {
  CommandDialog, CommandInput, CommandList, CommandEmpty,
  CommandGroup, CommandItem, CommandShortcut,
} from "@/components/ui/command";
import { useAuth } from "@/lib/hooks/use-auth";
import { useCommandPalette } from "@/lib/hooks/use-command-palette";
import { useCollection } from "@/lib/hooks/use-collection";
import { Collections, RoleNavAccess, type NavItem } from "@bandz/shared/constants";
import type { Artist, Place, Event } from "@bandz/shared/types";

interface CommandEntry {
  label: string;
  icon: React.ElementType;
  href: string;
  group: "navigate" | "create";
  keywords?: string;
  navKey?: NavItem;
}

const COMMANDS: CommandEntry[] = [
  // Navigation
  { label: "Dashboard", icon: LayoutGrid, href: "/dashboard", group: "navigate", navKey: "dashboard" },
  { label: "Artistas", icon: Music, href: "/artists", group: "navigate", keywords: "artists", navKey: "artists" },
  { label: "Casas", icon: Store, href: "/places", group: "navigate", keywords: "places venues", navKey: "places" },
  { label: "Eventos", icon: CalendarDays, href: "/events", group: "navigate", keywords: "events", navKey: "events" },
  { label: "Clientes", icon: Building2, href: "/clients", group: "navigate", keywords: "clients", navKey: "clients" },
  { label: "Usuários", icon: Users, href: "/users", group: "navigate", keywords: "users", navKey: "users" },
  { label: "Configurações", icon: Settings, href: "/settings", group: "navigate", keywords: "settings config", navKey: "settings" },
  { label: "Feedbacks", icon: MessageSquare, href: "/feedbacks", group: "navigate", keywords: "feedbacks comentarios", navKey: "feedbacks" },
  // Create
  { label: "Novo Artista", icon: Plus, href: "/artists/new", group: "create", keywords: "criar artista create artist", navKey: "artists" },
  { label: "Nova Casa", icon: Plus, href: "/places/new", group: "create", keywords: "criar casa create place venue", navKey: "places" },
  { label: "Novo Evento", icon: Plus, href: "/events/new", group: "create", keywords: "criar evento create event", navKey: "events" },
  { label: "Novo Cliente", icon: Plus, href: "/clients/new", group: "create", keywords: "criar cliente create client", navKey: "clients" },
];

export function CommandPalette() {
  const { open, setOpen, toggle } = useCommandPalette();
  const router = useRouter();
  const { claims } = useAuth();

  const { data: artists } = useCollection<Artist>(Collections.ARTISTS);
  const { data: places } = useCollection<Place>(Collections.PLACES);
  const { data: events } = useCollection<Event>(Collections.EVENTS);

  const entityItems = useMemo(() => {
    const items: { label: string; subtitle: string; icon: React.ElementType; href: string; value: string }[] = [];
    artists.slice(0, 50).forEach((a) =>
      items.push({ label: a.name, subtitle: "Artista", icon: Music, href: `/artists/view?id=${a.id}`, value: `${a.name} artista artist` }),
    );
    places.slice(0, 50).forEach((p) =>
      items.push({ label: p.name, subtitle: "Casa", icon: Store, href: `/places/view?id=${p.id}`, value: `${p.name} casa place ${p.city ?? ""}` }),
    );
    events.slice(0, 50).forEach((e) =>
      items.push({ label: e.eventName, subtitle: "Evento", icon: CalendarDays, href: `/events/view?id=${e.id}`, value: `${e.eventName} evento event ${e.artistName ?? ""}` }),
    );
    return items;
  }, [artists, places, events]);

  useEffect(() => {
    function onKeyDown(e: KeyboardEvent) {
      if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault();
        toggle();
      }
    }
    document.addEventListener("keydown", onKeyDown);
    return () => document.removeEventListener("keydown", onKeyDown);
  }, [toggle]);

  const accessibleNavKeys = claims?.role
    ? (RoleNavAccess[claims.role] ?? [])
    : [];

  const commands = COMMANDS.filter(
    (cmd) => !cmd.navKey || accessibleNavKeys.includes(cmd.navKey),
  );

  const navCommands = commands.filter((c) => c.group === "navigate");
  const createCommands = commands.filter((c) => c.group === "create");

  function handleSelect(href: string) {
    setOpen(false);
    router.push(href);
  }

  return (
    <CommandDialog open={open} onOpenChange={setOpen}>
      <CommandInput placeholder="Buscar páginas, entidades, ações..." />
      <CommandList>
        <CommandEmpty>Nenhum resultado encontrado.</CommandEmpty>
        <CommandGroup heading="Navegar">
          {navCommands.map((cmd) => (
            <CommandItem
              key={cmd.href}
              value={cmd.label + " " + (cmd.keywords ?? "")}
              onSelect={() => handleSelect(cmd.href)}
            >
              <cmd.icon className="h-4 w-4 text-muted-foreground" />
              <span>{cmd.label}</span>
              {cmd.label === "Dashboard" && <CommandShortcut>⌘D</CommandShortcut>}
            </CommandItem>
          ))}
        </CommandGroup>
        {createCommands.length > 0 && (
          <CommandGroup heading="Criar">
            {createCommands.map((cmd) => (
              <CommandItem
                key={cmd.href}
                value={cmd.label + " " + (cmd.keywords ?? "")}
                onSelect={() => handleSelect(cmd.href)}
              >
                <cmd.icon className="h-4 w-4 text-primary" />
                <span>{cmd.label}</span>
              </CommandItem>
            ))}
          </CommandGroup>
        )}
        {entityItems.length > 0 && (
          <CommandGroup heading="Entidades">
            {entityItems.map((item) => (
              <CommandItem
                key={item.href}
                value={item.value}
                onSelect={() => handleSelect(item.href)}
              >
                <item.icon className="h-4 w-4 text-muted-foreground" />
                <span>{item.label}</span>
                <span className="ml-auto text-[11px] text-muted-foreground">{item.subtitle}</span>
              </CommandItem>
            ))}
          </CommandGroup>
        )}
      </CommandList>
    </CommandDialog>
  );
}
