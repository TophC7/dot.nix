export const TIME_ZONE = "America/Puerto_Rico";

const calendar = new Intl.DateTimeFormat("en-US", {
  timeZone: TIME_ZONE,
  year: "numeric", month: "2-digit", day: "2-digit",
  hour: "2-digit", minute: "2-digit", second: "2-digit", hourCycle: "h23",
});
const DAY_MS = 86_400_000;

function calendarParts(timestamp: number): Record<string, string> {
  const parts = Object.fromEntries(calendar.formatToParts(timestamp).map(({ type, value }) => [type, value]));
  parts.year = parts.year.padStart(4, "0");
  return parts;
}

export function botTime(timestamp: number): { day: string; time: string } {
  const parts = calendarParts(timestamp);
  return { day: `${parts.year}-${parts.month}-${parts.day}`, time: `${parts.hour}:${parts.minute}` };
}

/** Calendar-day age, not elapsed 24-hour periods; weeks retain exact age. */
export function dayAge(day: string, now: number): string {
  const days = Math.round((Date.parse(`${botTime(now).day}T00:00:00Z`) - Date.parse(`${day}T00:00:00Z`)) / DAY_MS);
  if (days === 0) return "Today";
  if (days === 1) return "Yesterday";
  if (days === -1) return "Tomorrow";
  const count = Math.abs(days);
  const weeks = count % 7 === 0;
  const amount = weeks ? count / 7 : count;
  const unit = `${weeks ? "week" : "day"}${amount === 1 ? "" : "s"}`;
  return days > 0 ? `${amount} ${unit} ago` : `in ${amount} ${unit}`;
}

/** Parse a calendar date at Puerto Rico midnight; NaN means invalid date. */
export function calendarMidnight(day: string): number {
  const utc = /^\d{4}-\d{2}-\d{2}$/.test(day) ? Date.parse(`${day}T00:00:00Z`) : NaN;
  if (Number.isNaN(utc) || new Date(utc).toISOString().slice(0, 10) !== day) return NaN;
  const parts = calendarParts(utc);
  const localAsUtc = Date.parse(`${parts.year}-${parts.month}-${parts.day}T${parts.hour}:${parts.minute}:${parts.second}Z`);
  if (Number.isNaN(localAsUtc)) return NaN;
  const timestamp = utc - (localAsUtc - utc);
  const clock = botTime(timestamp);
  return clock.day === day && clock.time === "00:00" ? timestamp : NaN;
}
