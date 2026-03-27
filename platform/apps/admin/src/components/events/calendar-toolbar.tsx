"use client";

import { ChevronLeft, ChevronRight, CalendarDays, CalendarRange, Clock, LayoutList, Search } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { cn } from "@/lib/utils";
import type { CalendarView } from "@/lib/date-utils";

const VIEW_OPTIONS: { value: CalendarView; label: string; icon: React.ElementType }[] = [
  { value: "week", label: "Semana", icon: CalendarRange },
  { value: "month", label: "Mês", icon: CalendarDays },
  { value: "day", label: "Dia", icon: Clock },
  { value: "list", label: "Lista", icon: LayoutList },
];

interface CalendarToolbarProps {
  view: CalendarView;
  onViewChange: (view: CalendarView) => void;
  currentDate: Date;
  onNavigate: (direction: "prev" | "next" | "today") => void;
  dateLabel: string;
  search: string;
  onSearchChange: (value: string) => void;
  eventCount: number;
}

export function CalendarToolbar({
  view,
  onViewChange,
  onNavigate,
  dateLabel,
  search,
  onSearchChange,
  eventCount,
}: CalendarToolbarProps) {
  return (
    <div className="mb-4 space-y-3">
      {/* Row 1: Search + view switcher */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        {/* Search */}
        <div className="relative w-full sm:max-w-[260px]">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder="Buscar eventos..."
            value={search}
            onChange={(e) => onSearchChange(e.target.value)}
            className="pl-9"
          />
        </div>

        {/* View switcher */}
        <div className="flex items-center gap-1 rounded-lg bg-muted p-1">
          {VIEW_OPTIONS.map(({ value, label, icon: Icon }) => (
            <button
              key={value}
              type="button"
              onClick={() => onViewChange(value)}
              className={cn(
                "flex items-center gap-1.5 rounded-md px-3 py-1.5 text-xs font-medium transition-all duration-200",
                view === value
                  ? "bg-card text-foreground shadow-sm"
                  : "text-muted-foreground hover:text-foreground",
              )}
            >
              <Icon className="h-3.5 w-3.5" />
              <span className="hidden sm:inline">{label}</span>
            </button>
          ))}
        </div>
      </div>

      {/* Row 2: Navigation + date label + count (only for calendar views) */}
      {view !== "list" && (
        <div className="flex items-center gap-2">
          <div className="flex items-center gap-1">
            <Button
              variant="outline"
              size="icon"
              className="h-8 w-8"
              onClick={() => onNavigate("prev")}
            >
              <ChevronLeft className="h-4 w-4" />
            </Button>
            <Button
              variant="outline"
              size="icon"
              className="h-8 w-8"
              onClick={() => onNavigate("next")}
            >
              <ChevronRight className="h-4 w-4" />
            </Button>
          </div>

          <span className="text-sm font-semibold capitalize">{dateLabel}</span>

          <Button
            variant="ghost"
            size="sm"
            className="ml-1 text-xs"
            onClick={() => onNavigate("today")}
          >
            Hoje
          </Button>

          <span className="ml-auto text-xs text-muted-foreground">
            {eventCount} {eventCount === 1 ? "evento" : "eventos"}
          </span>
        </div>
      )}
    </div>
  );
}
