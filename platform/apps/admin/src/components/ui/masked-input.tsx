"use client";

import * as React from "react";
import { cn } from "@/lib/utils";
import { formatBrazilPhone, formatBrazilCep } from "@/lib/format-utils";

type MaskType = "phone" | "cep";

interface MaskedInputProps extends Omit<React.ComponentProps<"input">, "value" | "onChange"> {
  mask: MaskType;
  value: string;
  onChange: (raw: string) => void;
}

const maskConfig: Record<MaskType, { maxDigits: number; format: (v: string) => string; placeholder: string }> = {
  phone: { maxDigits: 11, format: formatBrazilPhone, placeholder: "(11) 99999-9999" },
  cep: { maxDigits: 8, format: formatBrazilCep, placeholder: "00000-000" },
};

const MaskedInput = React.forwardRef<HTMLInputElement, MaskedInputProps>(
  ({ mask, value, onChange, className, placeholder, ...props }, ref) => {
    const config = maskConfig[mask];
    const digits = (value ?? "").replace(/\D/g, "").slice(0, config.maxDigits);
    const displayed = digits.length > 0 ? config.format(digits) : "";

    function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
      const raw = e.target.value.replace(/\D/g, "").slice(0, config.maxDigits);
      onChange(raw);
    }

    return (
      <input
        ref={ref}
        type="text"
        inputMode="numeric"
        value={displayed}
        onChange={handleChange}
        placeholder={placeholder ?? config.placeholder}
        className={cn(
          "flex h-9 w-full rounded-lg border border-border bg-transparent px-3 py-1 text-sm transition-all duration-200 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:border-primary focus-visible:ring-2 focus-visible:ring-primary/20 focus-visible:shadow-[0_0_0_3px_var(--focus-glow)] disabled:cursor-not-allowed disabled:opacity-50",
          className,
        )}
        {...props}
      />
    );
  },
);
MaskedInput.displayName = "MaskedInput";

export { MaskedInput };
