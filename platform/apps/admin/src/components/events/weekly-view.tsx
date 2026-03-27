"use client";

import { isToday, format } from "date-fns";
import { ptBR } from "date-fns/locale/pt-BR";
import { getWeekDays, groupEventsByDay, filterEventsInRange, getViewRange } from "@/lib/date-utils";
import { EventCard, type EventRow } from "./event-card";
import { cn } from "@/lib/utils";

interface WeeklyViewProps {
  events: EventRow[];
  weekStart: Date;
  onEventClick: (event: EventRow) => void;
}

export function WeeklyView({ events, weekStart, onEventClick }: WeeklyViewProps) {
  const days = getWeekDays(weekStart);
  const { start, end } = getViewRange("week", weekStart);
  const weekEvents = filterEventsInRange(events, start, end);
  const grouped = groupEventsByDay(weekEvents);

  // Events without date
  const noDateEvents = events.filter((e) => !e._resolvedDate);

  return (
    <div className="space-y-3 stagger-children">
      {days.map((day) => {
        const key = format(day, "yyyy-MM-dd");
        const dayEvents = grouped.get(key) ?? [];
        const today = isToday(day);

        return (
          <div key={key}>
            {/* Day header */}
            <div
              className={cn(
                "mb-2 flex items-center gap-3 rounded-lg px-3 py-2",
                today && "bg-primary/5 border-l-2 border-primary",
              )}
            >
              <div className="flex items-baseline gap-2">
                <span className={cn(
                  "text-2xl font-bold tabular-nums",
                  today ? "text-primary" : "text-foreground",
                )}>
                  {format(day, "d")}
                </span>
                <span className={cn(
                  "text-sm font-medium capitalize",
                  today ? "text-primary" : "text-muted-foreground",
                )}>
                  {format(day, "EEEE", { locale: ptBR })}
                </span>
              </div>
              {today && (
                <span className="rounded-full bg-primary px-2 py-0.5 text-[10px] font-semibold text-primary-foreground">
                  Hoje
                </span>
              )}
              <span className="ml-auto text-xs text-muted-foreground">
                {dayEvents.length} {dayEvents.length === 1 ? "evento" : "eventos"}
              </span>
            </div>

            {/* Events */}
            {dayEvents.length > 0 ? (
              <div className="space-y-2 pl-2">
                {dayEvents.map((event) => (
                  <EventCard
                    key={event.id}
                    event={event}
                    variant="full"
                    onClick={() => onEventClick(event)}
                  />
                ))}
              </div>
            ) : (
              <div className="ml-2 rounded-lg border border-dashed border-border/50 px-4 py-3 text-center text-xs text-muted-foreground/60">
                Nenhum evento
              </div>
            )}
          </div>
        );
      })}

      {/* Events without date */}
      {noDateEvents.length > 0 && (
        <div>
          <div className="mb-2 flex items-center gap-3 rounded-lg px-3 py-2">
            <span className="text-sm font-medium text-muted-foreground">Sem data definida</span>
            <span className="ml-auto text-xs text-muted-foreground">
              {noDateEvents.length} {noDateEvents.length === 1 ? "evento" : "eventos"}
            </span>
          </div>
          <div className="space-y-2 pl-2">
            {noDateEvents.map((event) => (
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
