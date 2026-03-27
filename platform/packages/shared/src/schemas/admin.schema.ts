import { z } from "zod";
import { phoneRule } from "./field-rules.js";

const adminRoleEnum = z.enum(["superadmin", "admin", "editor", "viewer"]);

export const adminUserCreateSchema = z.object({
  email: z.string().email("Email inválido"),
  displayName: z.string().min(1, "Nome é obrigatório"),
  role: adminRoleEnum,
  clientId: z.string().optional(),
  password: z.string().min(8, "Senha deve ter no mínimo 8 caracteres"),
});

export type AdminUserCreateFormData = z.infer<typeof adminUserCreateSchema>;

export const adminUserUpdateSchema = z.object({
  displayName: z.string().min(1, "Nome é obrigatório").optional(),
  role: adminRoleEnum.optional(),
  clientId: z.string().optional(),
});

export type AdminUserUpdateFormData = z.infer<typeof adminUserUpdateSchema>;

export const clientSchema = z.object({
  name: z.string().min(1, "Nome do cliente é obrigatório"),
  slug: z
    .string()
    .min(1, "Slug é obrigatório")
    .regex(
      /^[a-z0-9-]+$/,
      "Slug deve conter apenas letras minúsculas, números e hífens",
    ),
  placeIds: z.array(z.string()),
  active: z.boolean(),
  contactEmail: z.string().email("Email inválido").optional().or(z.literal("")),
  contactPhone: phoneRule,
});

export type ClientFormData = z.infer<typeof clientSchema>;
