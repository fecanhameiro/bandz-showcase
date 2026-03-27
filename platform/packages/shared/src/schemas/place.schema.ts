import { z } from "zod";
import { phoneRule, cepRule } from "./field-rules.js";

export const placeSchema = z.object({
  name: z.string().min(1, "Nome do local é obrigatório"),
  placeType: z.string().min(1, "Tipo de local é obrigatório"),
  genres: z.array(z.string()),
  style: z.string(),
  description: z.string(),
  country: z.string().min(1, "País é obrigatório"),
  state: z.string().min(1, "Estado é obrigatório"),
  city: z.string().min(1, "Cidade é obrigatória"),
  address: z.string().min(1, "Endereço é obrigatório"),
  addressNumber: z.string().optional(),
  postalCode: cepRule,
  email: z.string().email("Email inválido").optional().or(z.literal("")),
  phone: phoneRule,
  whatsapp: phoneRule,
  website: z.string().url("URL inválida").optional().or(z.literal("")),
  instagramId: z.string().optional(),
  facebookId: z.string().optional(),
  tiktokId: z.string().optional(),
  googlePlaceId: z.string().optional(),
  styleGroupId: z.string().min(1, "Grupo de estilo é obrigatório"),
  styleGroupName: z.string().min(1, "Nome do grupo é obrigatório"),
  styleGroupColor: z.string().regex(/^#[0-9A-Fa-f]{6}$/, "Cor hex inválida").or(z.literal("")),
  styleGroupGenres: z.array(z.string()).min(1, "Gêneros do grupo são obrigatórios"),
  neighborhood: z.string().optional(),
  active: z.boolean(),
  isPlaceLGBTFriendly: z.boolean(),
});

export type PlaceFormData = z.infer<typeof placeSchema>;
