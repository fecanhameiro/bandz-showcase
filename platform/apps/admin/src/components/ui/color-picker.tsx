"use client";

import * as React from "react";
import { Check } from "lucide-react";
import { cn } from "@/lib/utils";
import { Input } from "./input";

const PRESET_COLORS = [
  { hex: "#D4634B", label: "Rock" },
  { hex: "#E8A94E", label: "Pop" },
  { hex: "#5B9E8F", label: "Jazz" },
  { hex: "#22C7F0", label: "Eletronica" },
  { hex: "#6366B5", label: "Hip Hop" },
  { hex: "#9B5DA5", label: "R&B" },
  { hex: "#D4708A", label: "Latin" },
  { hex: "#7B8C5D", label: "Folk" },
  { hex: "#C9A55A", label: "Gold" },
  { hex: "#14B8A6", label: "Teal" },
  { hex: "#EF4444", label: "Red" },
  { hex: "#F97316", label: "Orange" },
  { hex: "#8B5CF6", label: "Violet" },
  { hex: "#EC4899", label: "Pink" },
  { hex: "#3B82F6", label: "Blue" },
  { hex: "#10B981", label: "Emerald" },
];

interface ColorPickerProps {
  value: string;
  onChange: (hex: string) => void;
}

export function ColorPicker({ value, onChange }: ColorPickerProps) {
  const [hexInput, setHexInput] = React.useState(value);
  const isValidHex = /^#[0-9A-Fa-f]{6}$/.test(hexInput);

  React.useEffect(() => {
    setHexInput(value);
  }, [value]);

  function handleHexChange(val: string) {
    // Allow user to type with or without #
    const cleaned = val.replace(/^#+/, "");
    const hex = "#" + cleaned;
    setHexInput(hex);
    if (/^#[0-9A-Fa-f]{6}$/.test(hex)) {
      onChange(hex);
    }
  }

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap gap-2">
        {PRESET_COLORS.map((preset) => {
          const isSelected = value.toLowerCase() === preset.hex.toLowerCase();
          return (
            <button
              key={preset.hex}
              type="button"
              onClick={() => { onChange(preset.hex); setHexInput(preset.hex); }}
              className={cn(
                "relative h-8 w-8 rounded-full border-2 transition-all duration-150 hover:scale-110",
                isSelected ? "border-foreground scale-110 shadow-md" : "border-transparent",
              )}
              style={{ backgroundColor: preset.hex }}
              title={preset.label}
            >
              {isSelected && (
                <Check className="absolute inset-0 m-auto h-4 w-4 text-white drop-shadow-md" />
              )}
            </button>
          );
        })}
      </div>
      <div className="flex items-center gap-3">
        <div
          className="h-9 w-9 shrink-0 rounded-lg border border-border shadow-inner"
          style={{ backgroundColor: isValidHex ? hexInput : "#888" }}
        />
        <Input
          value={hexInput}
          onChange={(e) => handleHexChange(e.target.value)}
          placeholder="#D4634B"
          className="font-mono text-sm"
          maxLength={7}
        />
      </div>
    </div>
  );
}
