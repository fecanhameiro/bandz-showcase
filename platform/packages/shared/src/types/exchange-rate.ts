export enum Recommendation {
  EXCELLENT = "EXCELENTE",
  GOOD = "BOM",
  NEUTRAL = "NEUTRO",
  WAIT = "ESPERAR",
  AVOID = "EVITAR",
}

export interface ExchangeRateAnalysis {
  currentRate: number;
  average6m: number;
  average3m: number;
  median6m: number;
  min6m: number;
  max6m: number;
  percentile: number;
  deviationFromAvg6m: number;
  rateDate: string;
  recommendation: Recommendation;
}
