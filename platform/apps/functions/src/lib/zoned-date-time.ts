import { Timestamp } from "firebase-admin/firestore";

interface LocalDateComponents {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
  second: number;
  millisecond: number;
}

export class ZonedDateTime {
  private constructor(private readonly timezone: string, private readonly utcDate: Date) {}

  static now(timezone: string): ZonedDateTime {
    return new ZonedDateTime(timezone, new Date());
  }

  static fromTimestamp(timezone: string, timestamp: Timestamp): ZonedDateTime {
    return new ZonedDateTime(timezone, timestamp.toDate());
  }

  static fromMillis(timezone: string, millis: number): ZonedDateTime {
    return new ZonedDateTime(timezone, new Date(millis));
  }

  static fromLocalComponents(timezone: string, components: LocalDateComponents): ZonedDateTime {
    const localDate = new Date(Date.UTC(
      components.year,
      components.month - 1,
      components.day,
      components.hour,
      components.minute,
      components.second,
      components.millisecond,
    ));
    return new ZonedDateTime(timezone, convertLocalDateToUtc(localDate, timezone));
  }

  toTimestamp(): Timestamp {
    return Timestamp.fromDate(this.utcDate);
  }

  toDate(): Date {
    return new Date(this.utcDate.getTime());
  }

  toISOString(): string {
    return this.utcDate.toISOString();
  }

  getUtcMillis(): number {
    return this.utcDate.getTime();
  }

  get zone(): string {
    return this.timezone;
  }

  get hour(): number {
    return this.getLocalDate().getUTCHours();
  }

  get minute(): number {
    return this.getLocalDate().getUTCMinutes();
  }

  get second(): number {
    return this.getLocalDate().getUTCSeconds();
  }

  get millisecond(): number {
    return this.getLocalDate().getUTCMilliseconds();
  }

  get day(): number {
    return this.getLocalDate().getUTCDate();
  }

  get month(): number {
    return this.getLocalDate().getUTCMonth() + 1;
  }

  get year(): number {
    return this.getLocalDate().getUTCFullYear();
  }

  plusMinutes(minutes: number): ZonedDateTime {
    const local = this.getLocalDate();
    const updatedLocal = new Date(local.getTime() + minutes * 60000);
    return new ZonedDateTime(this.timezone, convertLocalDateToUtc(updatedLocal, this.timezone));
  }

  plusHours(hours: number): ZonedDateTime {
    return this.plusMinutes(hours * 60);
  }

  plusDays(days: number): ZonedDateTime {
    const local = this.getLocalDate();
    const updatedLocal = new Date(Date.UTC(
      local.getUTCFullYear(),
      local.getUTCMonth(),
      local.getUTCDate() + days,
      local.getUTCHours(),
      local.getUTCMinutes(),
      local.getUTCSeconds(),
      local.getUTCMilliseconds(),
    ));
    return new ZonedDateTime(this.timezone, convertLocalDateToUtc(updatedLocal, this.timezone));
  }

  startOfDay(): ZonedDateTime {
    const local = this.getLocalDate();
    const startLocal = new Date(Date.UTC(local.getUTCFullYear(), local.getUTCMonth(), local.getUTCDate(), 0, 0, 0, 0));
    return new ZonedDateTime(this.timezone, convertLocalDateToUtc(startLocal, this.timezone));
  }

  setTime(hour: number, minute = 0, second = 0, millisecond = 0): ZonedDateTime {
    const local = this.getLocalDate();
    const updatedLocal = new Date(Date.UTC(
      local.getUTCFullYear(),
      local.getUTCMonth(),
      local.getUTCDate(),
      hour,
      minute,
      second,
      millisecond,
    ));
    return new ZonedDateTime(this.timezone, convertLocalDateToUtc(updatedLocal, this.timezone));
  }

  withDate(year: number, month: number, day: number): ZonedDateTime {
    const local = this.getLocalDate();
    const updatedLocal = new Date(Date.UTC(
      year,
      month - 1,
      day,
      local.getUTCHours(),
      local.getUTCMinutes(),
      local.getUTCSeconds(),
      local.getUTCMilliseconds(),
    ));
    return new ZonedDateTime(this.timezone, convertLocalDateToUtc(updatedLocal, this.timezone));
  }

  diffHours(other: ZonedDateTime): number {
    return (this.utcDate.getTime() - other.utcDate.getTime()) / 3600000;
  }

  isBefore(other: ZonedDateTime): boolean {
    return this.utcDate.getTime() < other.utcDate.getTime();
  }

  isAfter(other: ZonedDateTime): boolean {
    return this.utcDate.getTime() > other.utcDate.getTime();
  }

  private getLocalDate(): Date {
    const offsetMinutes = getTimezoneOffsetMinutes(this.timezone, this.utcDate);
    const localMillis = this.utcDate.getTime() + offsetMinutes * 60000;
    return new Date(localMillis);
  }
}

function getTimezoneOffsetMinutes(timezone: string, date: Date): number {
  const formatter = new Intl.DateTimeFormat("en-US", {
    timeZone: timezone,
    hour12: false,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });

  const parts = formatter.formatToParts(date);
  const values: Record<string, string> = {};

  for (const part of parts) {
    if (part.type !== "literal") {
      values[part.type] = part.value;
    }
  }

  const iso = `${values.year}-${values.month}-${values.day}T${values.hour}:${values.minute}:${values.second}.000Z`;
  const localAsUtc = new Date(iso);
  return Math.round((localAsUtc.getTime() - date.getTime()) / 60000);
}

function convertLocalDateToUtc(localDate: Date, timezone: string): Date {
  let approximateUtc = new Date(localDate.getTime());

  for (let i = 0; i < 2; i++) {
    const offset = getTimezoneOffsetMinutes(timezone, approximateUtc);
    const utcMillis = localDate.getTime() - offset * 60000;
    const recalculated = new Date(utcMillis);

    if (Math.abs(recalculated.getTime() - approximateUtc.getTime()) < 60000) {
      return recalculated;
    }

    approximateUtc = recalculated;
  }

  return approximateUtc;
}
