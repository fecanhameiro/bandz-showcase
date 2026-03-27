"use client";

import { SmartImage } from "@/components/smart-image";
import { Badge } from "@/components/ui/badge";
import { cn, getGenreColor } from "@/lib/utils";
import { formatTime, formatDayShort } from "@/lib/date-utils";
import { Music, MapPin, Calendar } from "lucide-react";
import type { Event } from "@bandz/shared/types";

export type EventRow = Event & {
  id: string;
  bannerImageUrl?: string;
  _artistFallbackUrl?: string;
  _resolvedDate?: Date | null;
};

interface EventCardProps {
  event: EventRow;
  variant: "full" | "compact";
  onClick?: () => void;
}

export function EventCard({ event, variant, onClick }: EventCardProps) {
  const time = event._resolvedDate ? formatTime(event._resolvedDate) : null;

  if (variant === "compact") {
    return (
      <button
        type="button"
        onClick={onClick}
        className="flex w-full items-center gap-2 rounded-lg px-2 py-1 text-left text-xs transition-all duration-150 hover:bg-muted"
      >
        <span
          className="h-2 w-2 shrink-0 rounded-full"
          style={{ backgroundColor: event.active ? "var(--color-primary)" : "var(--color-muted-foreground)" }}
        />
        <span className="flex-1 truncate font-medium">{event.eventName}</span>
        {time && <span className="shrink-0 text-muted-foreground">{time}</span>}
      </button>
    );
  }

  // variant === "full"
  const genres = event.genres ?? [];
  const dateLabel = event._resolvedDate ? formatDayShort(event._resolvedDate) : null;

  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        "flex w-full items-center gap-3 rounded-xl border border-border bg-card p-3 text-left transition-all duration-200",
        "hover:-translate-y-px hover:shadow-lg hover:border-primary/30",
      )}
    >
      <SmartImage
        src={event.bannerImageUrl}
        fallbackSrc={event._artistFallbackUrl}
        alt={event.eventName}
        className="h-10 w-10 rounded-lg"
        fallbackClassName="h-10 w-10 rounded-lg"
      />
      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-2">
          <span className="truncate text-sm font-medium">{event.eventName}</span>
          <span
            className="h-2 w-2 shrink-0 rounded-full"
            style={{ backgroundColor: event.active ? "var(--color-success)" : "var(--color-muted-foreground)" }}
          />
        </div>
        {/* Info capsules row */}
        <div className="mt-1.5 flex flex-wrap items-center gap-1.5">
          {event.artistName && (
            <span className="inline-flex items-center gap-1 rounded-full bg-primary/10 px-2 py-0.5 text-[11px] font-medium text-primary">
              <Music className="h-3 w-3" />
              {event.artistName}
            </span>
          )}
          {event.placeName && (
            <span className="inline-flex items-center gap-1 rounded-full bg-secondary/10 px-2 py-0.5 text-[11px] font-medium text-secondary">
              <MapPin className="h-3 w-3" />
              {event.placeName}
            </span>
          )}
          {dateLabel && (
            <span className="inline-flex items-center gap-1 rounded-full bg-muted px-2 py-0.5 text-[11px] font-medium text-muted-foreground">
              <Calendar className="h-3 w-3" />
              {dateLabel}{time ? ` · ${time}` : ""}
            </span>
          )}
          {!dateLabel && time && (
            <span className="inline-flex items-center gap-1 rounded-full bg-muted px-2 py-0.5 text-[11px] font-medium text-muted-foreground">
              <Calendar className="h-3 w-3" />
              {time}
            </span>
          )}
          {genres.slice(0, 2).map((g) => (
            <span
              key={g}
              className="inline-flex items-center rounded-full px-1.5 py-0.5 text-[10px] font-semibold text-white"
              style={{ backgroundColor: getGenreColor(g) }}
            >
              {g}
            </span>
          ))}
          {genres.length > 2 && (
            <Badge variant="secondary" className="text-[10px]">+{genres.length - 2}</Badge>
          )}
        </div>
      </div>
    </button>
  );
}
