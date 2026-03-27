import { z } from "zod";

/** Telefone BR: 10 ou 11 dígitos (com DDD). Aceita raw ou formatado. */
export const phoneRule = z
  .string()
  .refine((v) => !v || /^\d{10,11}$/.test(v.replace(/\D/g, "")), {
    message: "Telefone deve ter 10 ou 11 dígitos",
  })
  .optional()
  .or(z.literal(""));

/** CEP BR: exatamente 8 dígitos. Aceita raw ou formatado. */
export const cepRule = z
  .string()
  .refine((v) => !v || /^\d{8}$/.test(v.replace(/\D/g, "")), {
    message: "CEP deve ter 8 dígitos",
  })
  .optional()
  .or(z.literal(""));
