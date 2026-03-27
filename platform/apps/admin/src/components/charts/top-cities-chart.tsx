"use client";

import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell } from "recharts";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";

export interface TopCitiesChartProps {
  places: { city: string }[];
}

export function TopCitiesChart({ places }: TopCitiesChartProps) {
  const cityCounts: Record<string, number> = {};
  places.forEach((p) => {
    if (p.city) cityCounts[p.city] = (cityCounts[p.city] || 0) + 1;
  });

  const data = Object.entries(cityCounts)
    .sort(([, a], [, b]) => b - a)
    .slice(0, 5)
    .map(([city, count]) => ({ city, count }));

  if (data.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Top Cidades</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="py-8 text-center text-sm text-muted-foreground">Sem dados</p>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Top Cidades</CardTitle>
      </CardHeader>
      <CardContent>
        <ResponsiveContainer width="100%" height={240}>
          <BarChart data={data} layout="vertical" margin={{ top: 5, right: 5, left: 0, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="var(--color-border)" horizontal={false} />
            <XAxis type="number" allowDecimals={false} tick={{ fontSize: 12, fill: "var(--color-muted-foreground)" }} />
            <YAxis
              type="category"
              dataKey="city"
              tick={{ fontSize: 12, fill: "var(--color-muted-foreground)" }}
              width={100}
            />
            <Tooltip
              contentStyle={{
                backgroundColor: "var(--color-card)",
                borderColor: "var(--color-border)",
                borderRadius: 12,
                fontSize: 13,
              }}
            />
            <Bar dataKey="count" name="Casas" radius={[0, 6, 6, 0]} maxBarSize={24} animationBegin={200} animationDuration={1000}>
              {data.map((_, i) => (
                <Cell key={i} fill="var(--color-teal)" fillOpacity={1 - i * 0.15} />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
}
