import dynamic from "next/dynamic";

export const RegistrationsChart = dynamic(
  () => import("./registrations-chart").then((m) => m.RegistrationsChart),
  { ssr: false },
);

export const TopCitiesChart = dynamic(
  () => import("./top-cities-chart").then((m) => m.TopCitiesChart),
  { ssr: false },
);

export const DistributionChart = dynamic(
  () => import("./distribution-chart").then((m) => m.DistributionChart),
  { ssr: false },
);
