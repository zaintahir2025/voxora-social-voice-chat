export const formatTime = (iso: string) =>
  new Intl.DateTimeFormat(undefined, {
    hour: 'numeric',
    minute: '2-digit',
  }).format(new Date(iso));

export const formatDate = (iso: string) =>
  new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
  }).format(new Date(iso));

export const formatNumber = (value: number) =>
  new Intl.NumberFormat(undefined, { notation: value > 9999 ? 'compact' : 'standard' }).format(value);

export const cx = (...classes: Array<string | false | null | undefined>) => classes.filter(Boolean).join(' ');
