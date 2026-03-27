"use client";

import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip } from "recharts";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";

export interface DistributionChartProps {
  artists: unknown[];
  places: unknown[];
  events: unknown[];
}

const COLORS = [
  "var(--color-primary)",
  "var(--color-teal)",
  "var(--color-secondary)",
];

const LABELS = ["Artistas", "Casas", "Eventos"];

export function DistributionChart({ artists, places, events }: DistributionChartProps) {
  const data = [
    { name: "Artistas", value: artists.length },
    { name: "Casas", value: places.length },
    { name: "Eventos", value: events.length },
  ];

  const total = data.reduce((acc, d) => acc + d.value, 0);

  if (total === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Distribuição</CardTitle>
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
        <CardTitle>Distribuição</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="flex items-center gap-6">
          <ResponsiveContainer width={140} height={140}>
            <PieChart>
              <Pie
                data={data}
                cx="50%"
                cy="50%"
                innerRadius={40}
                outerRadius={65}
                paddingAngle={3}
                dataKey="value"
                strokeWidth={0}
                animationBegin={200}
                animationDuration={1000}
              >
                {data.map((_, i) => (
                  <Cell key={i} fill={COLORS[i]} />
                ))}
              </Pie>
              <Tooltip
                contentStyle={{
                  backgroundColor: "var(--color-card)",
                  borderColor: "var(--color-border)",
                  borderRadius: 12,
                  fontSize: 13,
                }}
              />
            </PieChart>
          </ResponsiveContainer>
          <div className="space-y-2.5">
            {data.map((d, i) => (
              <div key={d.name} className="flex items-center gap-2.5">
                <span className="h-3 w-3 rounded-full" style={{ backgroundColor: COLORS[i] }} />
                <span className="text-sm font-medium">{LABELS[i]}</span>
                <span className="text-sm text-muted-foreground">
                  {d.value} ({total > 0 ? Math.round((d.value / total) * 100) : 0}%)
                </span>
              </div>
            ))}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
