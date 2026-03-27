"use client";

import { useState, useMemo, useEffect } from "react";
import {
  format,
  startOfMonth,
  endOfMonth,
  eachDayOfInterval,
  isSameDay,
  isSameMonth,
  isToday,
  startOfWeek,
  endOfWeek,
} from "date-fns";
import { ptBR } from "date-fns/locale/pt-BR";
import { groupEventsByDay } from "@/lib/date-utils";
import { EventCard, type EventRow } from "./event-card";
import { cn } from "@/lib/utils";

const WEEKDAY_LABELS = ["Seg", "Ter", "Qua", "Qui", "Sex", "Sab", "Dom"];

interface MonthlyViewProps {
  events: EventRow[];
  currentMonth: Date;
  onEventClick: (event: EventRow) => void;
}

export function MonthlyView({ events, currentMonth, onEventClick }: MonthlyViewProps) {
  const [selectedDay, setSelectedDay] = useState<Date | null>(null);

  // Reset selected day when month changes
  useEffect(() => setSelectedDay(null), [currentMonth]);

  // Get all visible days (padding prev/next months to fill grid)
  const calendarDays = useMemo(() => {
    const monthStart = startOfMonth(currentMonth);
    const monthEnd = endOfMonth(currentMonth);
    const gridStart = startOfWeek(monthStart, { weekStartsOn: 1 });
    const gridEnd = endOfWeek(monthEnd, { weekStartsOn: 1 });
    return eachDayOfInterval({ start: gridStart, end: gridEnd });
  }, [currentMonth]);

  // Only group events that have dates
  const datedEvents = useMemo(() => events.filter((e) => e._resolvedDate), [events]);
  const grouped = useMemo(() => groupEventsByDay(datedEvents), [datedEvents]);

  const selectedDayKey = selectedDay ? format(selectedDay, "yyyy-MM-dd") : null;
  const selectedDayEvents = selectedDayKey ? grouped.get(selectedDayKey) ?? [] : [];

  return (
    <div>
      {/* Calendar grid */}
      <div className="rounded-xl border border-border overflow-hidden">
        {/* Weekday headers */}
        <div className="grid grid-cols-7 border-b border-border bg-muted/50">
          {WEEKDAY_LABELS.map((d) => (
            <div key={d} className="py-2 text-center text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
              {d}
            </div>
          ))}
        </div>

        {/* Day cells */}
        <div className="grid grid-cols-7">
          {calendarDays.map((day, i) => {
            const key = format(day, "yyyy-MM-dd");
            const inMonth = isSameMonth(day, currentMonth);
            const today = isToday(day);
            const selected = selectedDay && isSameDay(day, selectedDay);
            const dayEvents = grouped.get(key) ?? [];
            const hasEvents = dayEvents.length > 0;

            return (
              <button
                key={i}
                type="button"
                onClick={() => setSelectedDay(hasEvents ? (selected ? null : day) : null)}
                className={cn(
                  "relative flex min-h-[80px] flex-col border-b border-r border-border p-1.5 text-left transition-colors",
                  !inMonth && "bg-muted/30",
                  inMonth && hasEvents && "cursor-pointer hover:bg-muted/50",
                  !hasEvents && "cursor-default",
                  selected && "bg-primary/5",
                  // Remove right border on last column
                  (i + 1) % 7 === 0 && "border-r-0",
                )}
              >
                {/* Day number */}
                <span
                  className={cn(
                    "flex h-6 w-6 items-center justify-center rounded-full text-xs",
                    !inMonth && "text-muted-foreground/40",
                    today && "bg-primary font-bold text-primary-foreground",
                    !today && inMonth && "font-medium",
                  )}
                >
                  {day.getDate()}
                </span>

                {/* Event indicators */}
                {dayEvents.length > 0 && (
                  <div className="mt-0.5 flex-1 space-y-0.5 overflow-hidden">
                    {dayEvents.slice(0, 2).map((ev) => (
                      <EventCard
                        key={ev.id}
                        event={ev}
                        variant="compact"
                        onClick={() => onEventClick(ev)}
                      />
                    ))}
                    {dayEvents.length > 2 && (
                      <span className="block pl-2 text-[10px] font-medium text-primary">
                        +{dayEvents.length - 2} mais
                      </span>
                    )}
                  </div>
                )}
              </button>
            );
          })}
        </div>
      </div>

      {/* Selected day detail panel */}
      {selectedDay && selectedDayEvents.length > 0 && (
        <div className="mt-4 animate-in">
          <div className="mb-3 flex items-center justify-between">
            <h3 className="text-sm font-semibold capitalize">
              {format(selectedDay, "EEEE, d 'de' MMMM", { locale: ptBR })}
            </h3>
            <button
              type="button"
              onClick={() => setSelectedDay(null)}
              className="text-xs text-muted-foreground hover:text-foreground transition-colors"
            >
              Fechar
            </button>
          </div>
          <div className="space-y-2">
            {selectedDayEvents.map((event) => (
              <EventCard
                key={event.id}
                event={event}
                variant="full"
                onClick={() => onEventClick(event)}
              />
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
