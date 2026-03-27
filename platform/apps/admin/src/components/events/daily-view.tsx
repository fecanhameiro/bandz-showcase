"use client";

import { isToday, format } from "date-fns";
import { ptBR } from "date-fns/locale/pt-BR";
import { filterEventsInRange, getViewRange } from "@/lib/date-utils";
import { EventCard, type EventRow } from "./event-card";
import { CalendarDays } from "lucide-react";

interface DailyViewProps {
  events: EventRow[];
  currentDay: Date;
  onEventClick: (event: EventRow) => void;
}

export function DailyView({ events, currentDay, onEventClick }: DailyViewProps) {
  const { start, end } = getViewRange("day", currentDay);
  const dayEvents = filterEventsInRange(events, start, end);
  const today = isToday(currentDay);

  return (
    <div>
      {/* Day header */}
      <div className="mb-4 flex items-center gap-3">
        <h3 className="text-lg font-semibold capitalize">
          {format(currentDay, "EEEE, d 'de' MMMM 'de' yyyy", { locale: ptBR })}
        </h3>
        {today && (
          <span className="rounded-full bg-primary px-2.5 py-0.5 text-[11px] font-semibold text-primary-foreground">
            Hoje
          </span>
        )}
      </div>

      {/* Events */}
      {dayEvents.length > 0 ? (
        <div className="space-y-2 stagger-children">
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
        <div className="flex flex-col items-center justify-center py-16 text-center">
          <div className="relative mb-4">
            <div className="absolute inset-0 rounded-full bg-gradient-to-br from-primary/10 to-secondary/10 blur-xl" />
            <div className="relative flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-to-br from-primary/10 to-secondary/10 border border-primary/10">
              <CalendarDays className="h-6 w-6 text-primary/60" />
            </div>
          </div>
          <h4 className="text-sm font-semibold">Nenhum evento neste dia</h4>
          <p className="mt-1 text-xs text-muted-foreground">
            Navegue para outro dia ou crie um novo evento.
          </p>
        </div>
      )}
    </div>
  );
}
