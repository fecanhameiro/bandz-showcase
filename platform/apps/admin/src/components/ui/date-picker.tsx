"use client";

import * as React from "react";
import { useState, useMemo } from "react";
import * as Popover from "@radix-ui/react-popover";
import {
  format,
  startOfMonth,
  endOfMonth,
  eachDayOfInterval,
  isSameDay,
  isSameMonth,
  isToday,
  addMonths,
  subMonths,
  getDay,
  startOfWeek,
} from "date-fns";
import { ptBR } from "date-fns/locale/pt-BR";
import { CalendarDays, ChevronLeft, ChevronRight } from "lucide-react";
import { cn } from "@/lib/utils";

interface DatePickerProps {
  value: Date | null;
  onChange: (date: Date | null) => void;
  placeholder?: string;
  showTime?: boolean;
  disabled?: boolean;
  className?: string;
}

const WEEKDAY_LABELS = ["Seg", "Ter", "Qua", "Qui", "Sex", "Sab", "Dom"];

export function DatePicker({
  value,
  onChange,
  placeholder = "Selecionar data...",
  showTime = true,
  disabled,
  className,
}: DatePickerProps) {
  const [open, setOpen] = useState(false);
  const [viewMonth, setViewMonth] = useState(() => value ?? new Date());

  const calendarDays = useMemo(() => {
    const monthStart = startOfMonth(viewMonth);
    const monthEnd = endOfMonth(viewMonth);
    const days = eachDayOfInterval({ start: monthStart, end: monthEnd });

    // Pad beginning: getDay returns 0=Sun. We want Mon=0, so adjust.
    const firstDayOfWeek = (getDay(monthStart) + 6) % 7; // Mon=0, Tue=1, ...
    const prevDays: Date[] = [];
    if (firstDayOfWeek > 0) {
      const weekStart = startOfWeek(monthStart, { weekStartsOn: 1 });
      prevDays.push(...eachDayOfInterval({ start: weekStart, end: new Date(monthStart.getTime() - 86400000) }));
    }

    // Pad end to fill last row
    const totalCells = prevDays.length + days.length;
    const remaining = totalCells % 7 === 0 ? 0 : 7 - (totalCells % 7);
    const nextDays: Date[] = [];
    for (let i = 1; i <= remaining; i++) {
      nextDays.push(new Date(monthEnd.getTime() + i * 86400000));
    }

    return [...prevDays, ...days, ...nextDays];
  }, [viewMonth]);

  function handleDayClick(day: Date) {
    let next: Date;
    if (value) {
      // Preserve time from current value
      next = new Date(day);
      next.setHours(value.getHours(), value.getMinutes(), 0, 0);
    } else {
      next = new Date(day);
      next.setHours(21, 0, 0, 0);
    }
    onChange(next);
    if (!showTime) setOpen(false);
  }

  function handleTimeChange(e: React.ChangeEvent<HTMLInputElement>) {
    const [h, m] = e.target.value.split(":").map(Number);
    const next = new Date(value ?? new Date());
    next.setHours(h, m, 0, 0);
    onChange(next);
  }

  const timeValue = value
    ? `${String(value.getHours()).padStart(2, "0")}:${String(value.getMinutes()).padStart(2, "0")}`
    : "21:00";

  return (
    <Popover.Root open={open} onOpenChange={setOpen}>
      <Popover.Trigger asChild disabled={disabled}>
        <button
          type="button"
          className={cn(
            "flex h-9 w-full items-center gap-2 rounded-lg border border-border bg-transparent px-3 py-1 text-sm transition-all duration-200 focus-visible:outline-none focus-visible:border-primary focus-visible:ring-2 focus-visible:ring-primary/20 focus-visible:shadow-[0_0_0_3px_var(--focus-glow)] disabled:cursor-not-allowed disabled:opacity-50",
            !value && "text-muted-foreground",
            className,
          )}
        >
          <CalendarDays className="h-4 w-4 shrink-0 text-muted-foreground" />
          <span className="flex-1 text-left truncate">
            {value
              ? format(value, showTime ? "dd MMM yyyy 'às' HH:mm" : "dd MMM yyyy", { locale: ptBR })
              : placeholder}
          </span>
        </button>
      </Popover.Trigger>

      <Popover.Portal>
        <Popover.Content
          sideOffset={6}
          align="start"
          className="z-50 w-[280px] rounded-xl border border-border bg-card p-3 shadow-xl animate-in"
        >
          {/* Month navigation */}
          <div className="mb-2 flex items-center justify-between">
            <button
              type="button"
              onClick={() => setViewMonth((d) => subMonths(d, 1))}
              className="flex h-7 w-7 items-center justify-center rounded-lg text-muted-foreground hover:bg-muted hover:text-foreground transition-colors"
            >
              <ChevronLeft className="h-4 w-4" />
            </button>
            <span className="text-sm font-semibold capitalize">
              {format(viewMonth, "MMMM yyyy", { locale: ptBR })}
            </span>
            <button
              type="button"
              onClick={() => setViewMonth((d) => addMonths(d, 1))}
              className="flex h-7 w-7 items-center justify-center rounded-lg text-muted-foreground hover:bg-muted hover:text-foreground transition-colors"
            >
              <ChevronRight className="h-4 w-4" />
            </button>
          </div>

          {/* Weekday headers */}
          <div className="grid grid-cols-7 mb-1">
            {WEEKDAY_LABELS.map((d) => (
              <div key={d} className="text-center text-[10px] font-semibold uppercase tracking-wider text-muted-foreground py-1">
                {d}
              </div>
            ))}
          </div>

          {/* Day grid */}
          <div className="grid grid-cols-7">
            {calendarDays.map((day, i) => {
              const inMonth = isSameMonth(day, viewMonth);
              const selected = value && isSameDay(day, value);
              const today = isToday(day);

              return (
                <button
                  key={i}
                  type="button"
                  onClick={() => handleDayClick(day)}
                  className={cn(
                    "flex h-8 w-full items-center justify-center rounded-lg text-sm transition-all duration-150",
                    !inMonth && "text-muted-foreground/40",
                    inMonth && !selected && "hover:bg-muted",
                    today && !selected && "font-bold text-primary",
                    selected && "bg-primary text-primary-foreground font-semibold shadow-sm",
                  )}
                >
                  {day.getDate()}
                </button>
              );
            })}
          </div>

          {/* Time picker */}
          {showTime && (
            <div className="mt-3 flex items-center gap-2 border-t border-border pt-3">
              <label className="text-xs font-medium text-muted-foreground">Horário</label>
              <input
                type="time"
                value={timeValue}
                onChange={handleTimeChange}
                className="flex-1 rounded-lg border border-border bg-transparent px-2 py-1 text-sm focus-visible:outline-none focus-visible:border-primary focus-visible:ring-2 focus-visible:ring-primary/20"
              />
            </div>
          )}

          {/* Today shortcut */}
          <button
            type="button"
            onClick={() => {
              const now = new Date();
              setViewMonth(now);
              handleDayClick(now);
            }}
            className="mt-2 w-full rounded-lg py-1.5 text-xs font-medium text-primary hover:bg-primary/5 transition-colors"
          >
            Hoje
          </button>
        </Popover.Content>
      </Popover.Portal>
    </Popover.Root>
  );
}
