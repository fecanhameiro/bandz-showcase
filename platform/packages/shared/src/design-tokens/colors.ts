/**
 * Bandz brand colors — consumed by Tailwind configs in landing and admin.
 * Update here → changes propagate to all apps.
 *
 * Palette: Indigo + Hot Pink with warm gradients.
 */
export const colors = {
  brand: {
    primary: { light: "#4F46E5", dark: "#818CF8" },
    secondary: { light: "#EF2D82", dark: "#FF459B" },
    gold: "#C9A55A",
    primarySoft: { light: "#6366F1", dark: "#818CF8" },
    teal: { light: "#14B8A6", dark: "#2DD4BF" },
  },
  gradients: {
    /** "Festival Day" — 3-stop diagonal */
    primary: {
      light: ["#93C5FD", "#FED7AA", "#FDE68A"],
      dark: ["#253540", "#2A3A42", "#2E3D44", "#2A3840", "#1E2A30"],
    },
    /** Onboarding — softer variant */
    onboarding: {
      light: ["#BFDBFE", "#FECDD3", "#FEF3C7"],
      dark: ["#253540", "#2A3A42", "#2E3D44", "#2A3840", "#1E2A30"],
    },
    /** Secondary — Indigo → Pink */
    secondary: {
      light: ["#4F46E5", "#EF2D82"],
      dark: ["#818CF8", "#FF459B"],
    },
  },
  surface: {
    light: "#F5F5F5",
    dark: {
      base: "#1A1A1A",
      1: "#212121",
      2: "#2A2A2A",
      3: "#333333",
    },
  },
  neutral: {
    50: "#FAFAFA",
    100: "#F5F5F5",
    200: "#E5E5E5",
    300: "#D4D4D4",
    400: "#A3A3A3",
    500: "#737373",
    600: "#525252",
    700: "#404040",
    800: "#262626",
    900: "#171717",
    950: "#0A0A0A",
  },
  semantic: {
    success: "#12B886",
    warning: "#F59E0B",
    error: "#E5484D",
    info: "#3B82F6",
  },
  genres: {
    rock: "#D4634B",
    pop: "#E8A94E",
    jazz: "#5B9E8F",
    eletronica: "#22C7F0",
    hiphop: "#6366B5",
    rnb: "#9B5DA5",
    latin: "#D4708A",
    folk: "#7B8C5D",
  },
} as const;
