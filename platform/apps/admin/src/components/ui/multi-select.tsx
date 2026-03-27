"use client";

import * as React from "react";
import { X } from "lucide-react";
import { cn, getGenreColor } from "@/lib/utils";

interface MultiSelectProps {
  value: string[];
  onChange: (value: string[]) => void;
  options: string[];
  placeholder?: string;
  className?: string;
  colorize?: boolean;
}

export function MultiSelect({ value, onChange, options, placeholder = "Adicionar...", className, colorize }: MultiSelectProps) {
  const [input, setInput] = React.useState("");
  const [open, setOpen] = React.useState(false);
  const inputRef = React.useRef<HTMLInputElement>(null);

  const filtered = options.filter(
    (opt) => !value.includes(opt) && opt.toLowerCase().includes(input.toLowerCase()),
  );

  function addItem(item: string) {
    onChange([...value, item]);
    setInput("");
    setOpen(false);
    inputRef.current?.focus();
  }

  function removeItem(item: string) {
    onChange(value.filter((v) => v !== item));
  }

  return (
    <div className="relative">
      <div
        className={cn(
          "flex min-h-[38px] flex-wrap gap-1.5 rounded-lg border border-border px-2.5 py-1.5 text-sm transition-all duration-200 focus-within:border-primary focus-within:ring-2 focus-within:ring-primary/20 cursor-text",
          className,
        )}
        onClick={() => inputRef.current?.focus()}
      >
        {value.map((v) => (
          <span
            key={v}
            className="inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-semibold text-white"
            style={{ backgroundColor: colorize ? getGenreColor(v) : "var(--accent-indigo)" }}
          >
            {v}
            <button type="button" onClick={() => removeItem(v)} className="opacity-70 hover:opacity-100">
              <X className="h-3 w-3" />
            </button>
          </span>
        ))}
        <input
          ref={inputRef}
          value={input}
          onChange={(e) => { setInput(e.target.value); setOpen(true); }}
          onFocus={() => setOpen(true)}
          onBlur={() => setTimeout(() => setOpen(false), 200)}
          placeholder={value.length === 0 ? placeholder : ""}
          className="flex-1 min-w-[80px] bg-transparent outline-none text-sm placeholder:text-muted-foreground"
        />
      </div>
      {open && filtered.length > 0 && (
        <div className="absolute z-50 mt-1 max-h-48 w-full overflow-auto rounded-lg border border-border bg-popover p-1 shadow-xl">
          {filtered.map((opt) => (
            <button
              key={opt}
              type="button"
              onMouseDown={(e) => e.preventDefault()}
              onClick={() => addItem(opt)}
              className="flex w-full items-center gap-2 rounded-md px-2 py-1.5 text-sm hover:bg-accent transition-colors text-left"
            >
              {colorize && (
                <span className="h-2.5 w-2.5 rounded-full" style={{ backgroundColor: getGenreColor(opt) }} />
              )}
              {opt}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
