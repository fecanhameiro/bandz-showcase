import { z } from "zod";
import { phoneRule } from "./field-rules.js";

export const artistSchema = z.object({
  name: z.string().min(1, "Nome do artista é obrigatório"),
  country: z.string().min(1, "País é obrigatório"),
  state: z.string().min(1, "Estado é obrigatório"),
  city: z.string().min(1, "Cidade é obrigatória"),
  style: z.string(),
  genres: z.array(z.string()).optional(),
  description: z.string().optional(),
  email: z.string().email("Email inválido").optional().or(z.literal("")),
  phone: phoneRule,
  whatsapp: phoneRule,
  website: z.string().url("URL inválida").optional().or(z.literal("")),
  instagramId: z.string().optional(),
  facebookId: z.string().optional(),
  tiktokId: z.string().optional(),
  youtubeId: z.string().optional(),
  spotifyId: z.string().optional(),
  soundcloudId: z.string().optional(),
  styleGroupId: z.string().min(1, "Grupo de estilo é obrigatório"),
  styleGroupName: z.string().min(1, "Nome do grupo é obrigatório"),
  styleGroupColor: z.string().regex(/^#[0-9A-Fa-f]{6}$/, "Cor hex inválida").or(z.literal("")),
  styleGroupGenres: z.array(z.string()).min(1, "Gêneros do grupo são obrigatórios"),
  active: z.boolean(),
});

export type ArtistFormData = z.infer<typeof artistSchema>;
