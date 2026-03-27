import { z } from "zod";

export const eventSchema = z.object({
  eventName: z.string().min(1, "Nome do evento é obrigatório"),
  eventDate: z.coerce.date({ error: "Data do evento é obrigatória" }),
  description: z.string(),
  youtubeURL: z.string().url("URL inválida").optional().or(z.literal("")),
  placeId: z.string().min(1, "Local é obrigatório"),
  genres: z.array(z.string()),
  style: z.string(),
  artistId: z.string().min(1, "Artista é obrigatório"),
  linkEvent: z.string().url("URL inválida").optional().or(z.literal("")),
  styleGroupId: z.string().min(1, "Grupo de estilo é obrigatório"),
  styleGroupName: z.string().min(1, "Nome do grupo é obrigatório"),
  styleGroupColor: z.string().regex(/^#[0-9A-Fa-f]{6}$/, "Cor hex inválida").or(z.literal("")),
  styleGroupGenres: z.array(z.string()).min(1, "Gêneros do grupo são obrigatórios"),
  placeStyleGroupId: z.string().min(1, "Grupo de estilo da casa é obrigatório"),
  placeStyleGroupName: z.string().min(1, "Nome do grupo da casa é obrigatório"),
  placeStyleGroupColor: z.string().regex(/^#[0-9A-Fa-f]{6}$/, "Cor hex inválida").or(z.literal("")),
  placeStyleGroupGenres: z.array(z.string()).min(1, "Gêneros do grupo da casa são obrigatórios"),
  active: z.boolean(),
  eventIsFree: z.boolean().optional(),
});

export type EventFormData = z.infer<typeof eventSchema>;
