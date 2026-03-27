"use client";

import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from "recharts";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";

export interface RegistrationsChartProps {
  artists: { createdDate?: unknown }[];
  places: { createdDate?: unknown }[];
  events: { createdDate?: unknown }[];
  monthsBack?: number;
}

function getMonthKey(date: unknown): string | null {
  if (!date) return null;
  let d: Date;
  if (date instanceof Date) {
    d = date;
  } else if (typeof date === "object" && date !== null && "seconds" in date) {
    d = new Date((date as { seconds: number }).seconds * 1000);
  } else {
    return null;
  }
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
}

function formatMonth(key: string): string {
  const [year, month] = key.split("-");
  const months = ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"];
  return `${months[parseInt(month) - 1]} ${year.slice(2)}`;
}

export function RegistrationsChart({ artists, places, events, monthsBack = 6 }: RegistrationsChartProps) {
  const now = new Date();
  const months: string[] = [];
  for (let i = monthsBack - 1; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    months.push(`${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`);
  }

  const countByMonth = (items: { createdDate?: unknown }[]) => {
    const counts: Record<string, number> = {};
    items.forEach((item) => {
      const key = getMonthKey(item.createdDate);
      if (key) counts[key] = (counts[key] || 0) + 1;
    });
    return counts;
  };

  const artistCounts = countByMonth(artists);
  const placeCounts = countByMonth(places);
  const eventCounts = countByMonth(events);

  const data = months.map((month) => ({
    month: formatMonth(month),
    Artistas: artistCounts[month] || 0,
    Casas: placeCounts[month] || 0,
    Eventos: eventCounts[month] || 0,
  }));

  return (
    <Card>
      <CardHeader>
        <CardTitle>Cadastros por Mês</CardTitle>
      </CardHeader>
      <CardContent>
        <ResponsiveContainer width="100%" height={240}>
          <AreaChart data={data} margin={{ top: 5, right: 5, left: -20, bottom: 0 }}>
            <defs>
              <linearGradient id="colorArtistas" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="var(--color-primary)" stopOpacity={0.3} />
                <stop offset="95%" stopColor="var(--color-primary)" stopOpacity={0} />
              </linearGradient>
              <linearGradient id="colorCasas" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="var(--color-teal)" stopOpacity={0.3} />
                <stop offset="95%" stopColor="var(--color-teal)" stopOpacity={0} />
              </linearGradient>
              <linearGradient id="colorEventos" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="var(--color-secondary)" stopOpacity={0.3} />
                <stop offset="95%" stopColor="var(--color-secondary)" stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" stroke="var(--color-border)" />
            <XAxis dataKey="month" tick={{ fontSize: 12, fill: "var(--color-muted-foreground)" }} />
            <YAxis allowDecimals={false} tick={{ fontSize: 12, fill: "var(--color-muted-foreground)" }} />
            <Tooltip
              contentStyle={{
                backgroundColor: "var(--color-card)",
                borderColor: "var(--color-border)",
                borderRadius: 12,
                fontSize: 13,
              }}
            />
            <Legend
              verticalAlign="top"
              align="right"
              iconType="circle"
              iconSize={8}
              wrapperStyle={{ fontSize: 12, paddingBottom: 8 }}
            />
            <Area type="monotone" dataKey="Artistas" stroke="var(--color-primary)" fill="url(#colorArtistas)" strokeWidth={2} animationBegin={200} animationDuration={1200} animationEasing="ease-out" />
            <Area type="monotone" dataKey="Casas" stroke="var(--color-teal)" fill="url(#colorCasas)" strokeWidth={2} animationBegin={400} animationDuration={1200} animationEasing="ease-out" />
            <Area type="monotone" dataKey="Eventos" stroke="var(--color-secondary)" fill="url(#colorEventos)" strokeWidth={2} animationBegin={600} animationDuration={1200} animationEasing="ease-out" />
          </AreaChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
}
