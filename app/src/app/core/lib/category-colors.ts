export const CATEGORY_COLORS: Record<string, [string, string]> = {
  makanan:   ['var(--bw-amber-soft)',   'var(--bw-amber)'],
  minuman:   ['var(--bw-emerald-soft)', 'var(--bw-emerald)'],
  transport: ['var(--bw-lime-alpha)',   'var(--bw-lime)'],
  belanja:   ['var(--bw-red-soft)',     'var(--bw-red)'],
  hiburan:   ['var(--bw-purple-soft)',  'var(--bw-purple)'],
  tagihan:   ['var(--bw-sunken)',       'var(--bw-ink-3)'],
  kesehatan: ['var(--bw-green-soft)',   'var(--bw-green)'],
  gaji:      ['var(--bw-green-soft)',   'var(--bw-green)'],
  hadiah:    ['var(--bw-amber-soft)',   'var(--bw-amber)'],
};

export const DEFAULT_CATEGORY_COLORS: [string, string] = [
  'var(--bw-sunken)',
  'var(--bw-ink-3)',
];

export function getCategoryColors(name: string): [string, string] {
  return CATEGORY_COLORS[name] ?? DEFAULT_CATEGORY_COLORS;
}
