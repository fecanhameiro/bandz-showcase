import { z } from "zod";

const translationSchema = z.object({
  name: z.string().optional().or(z.literal("")),
  description: z.string().max(200, "Máximo de 200 caracteres").optional().or(z.literal("")),
});

export const styleGroupSchema = z.object({
  name: z.string().min(1, "Nome do grupo é obrigatório"),
  mainGenre: z.string().min(1, "Gênero principal é obrigatório"),
  color: z
    .string()
    .regex(/^#[0-9A-Fa-f]{6}$/, "Cor deve ser um hex válido (ex: #D4634B)"),
  icon: z.string().optional().or(z.literal("")),
  description: z.string().max(200, "Máximo de 200 caracteres").optional().or(z.literal("")),
  imageUrl: z.string().url("URL inválida").optional().or(z.literal("")),
  genres: z.array(z.string().min(1)).min(1, "Adicione pelo menos um gênero"),
  active: z.boolean(),
  order: z.coerce.number().int().min(0, "Ordem deve ser >= 0").optional(),
  translations: z.object({
    "pt-BR": translationSchema.optional(),
    en: translationSchema.optional(),
    es: translationSchema.optional(),
  }).optional(),
});

export type StyleGroupFormData = z.infer<typeof styleGroupSchema>;
