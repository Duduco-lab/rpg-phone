const LOCALE = 'pt-BR';

const timeFmt = new Intl.DateTimeFormat(LOCALE, { hour: '2-digit', minute: '2-digit' });
const shortDayFmt = new Intl.DateTimeFormat(LOCALE, { day: 'numeric', month: 'short' });
const numericFmt = new Intl.DateTimeFormat(LOCALE, { day: '2-digit', month: '2-digit', year: '2-digit' });
const fullFmt = new Intl.DateTimeFormat(LOCALE, {
  day: 'numeric',
  month: 'short',
  year: 'numeric',
  hour: '2-digit',
  minute: '2-digit',
});
const longDateFmt = new Intl.DateTimeFormat(LOCALE, { weekday: 'long', day: 'numeric', month: 'long' });

function sameDay(a: Date, b: Date): boolean {
  return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
}

export function formatClock(date: Date): string {
  return timeFmt.format(date);
}

export function formatLongDate(date: Date): string {
  const s = longDateFmt.format(date);
  return s.charAt(0).toUpperCase() + s.slice(1);
}

/** Data compacta para listas: hora (hoje), "3 de nov." (ano corrente) ou dd/mm/aa. */
export function formatListDate(iso: string, now: Date = new Date()): string {
  const d = new Date(iso);
  if (sameDay(d, now)) return timeFmt.format(d);
  if (d.getFullYear() === now.getFullYear()) return shortDayFmt.format(d).replace(/\.$/, '');
  return numericFmt.format(d);
}

export function formatFullDate(iso: string): string {
  return fullFmt.format(new Date(iso));
}

export function initials(name: string): string {
  const parts = name.replace(/@.*/, '').split(/[\s._-]+/).filter(Boolean);
  const first = parts[0]?.[0] ?? '?';
  const last = parts.length > 1 ? (parts[parts.length - 1]?.[0] ?? '') : '';
  return (first + last).toUpperCase();
}

export function snippet(text: string, max = 140): string {
  const flat = text.replace(/\s+/g, ' ').trim();
  return flat.length > max ? `${flat.slice(0, max - 1)}…` : flat;
}

const FALLBACK_COLORS = ['#5b6ee1', '#d35d6e', '#2e9e8f', '#c47f1a', '#8a5cd6', '#3a86c8', '#b8577f'];

export function colorFromString(value: string): string {
  let hash = 0;
  for (let i = 0; i < value.length; i++) hash = (hash * 31 + value.charCodeAt(i)) | 0;
  return FALLBACK_COLORS[Math.abs(hash) % FALLBACK_COLORS.length] ?? '#5b6ee1';
}
