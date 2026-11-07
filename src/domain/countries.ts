/** Países disponíveis no mundo do jogo (espelha a tabela `countries` do banco). */
export const COUNTRIES: { code: string; name: string; flag: string }[] = [
  { code: 'DE', name: 'Alemanha', flag: '🇩🇪' },
  { code: 'AT', name: 'Áustria', flag: '🇦🇹' },
  { code: 'BR', name: 'Brasil', flag: '🇧🇷' },
  { code: 'ES', name: 'Espanha', flag: '🇪🇸' },
  { code: 'US', name: 'Estados Unidos', flag: '🇺🇸' },
  { code: 'FR', name: 'França', flag: '🇫🇷' },
  { code: 'IT', name: 'Itália', flag: '🇮🇹' },
  { code: 'PT', name: 'Portugal', flag: '🇵🇹' },
  { code: 'GB', name: 'Reino Unido', flag: '🇬🇧' },
  { code: 'RU', name: 'Rússia', flag: '🇷🇺' },
];

export function countryName(code: string | null | undefined): string | null {
  return COUNTRIES.find((c) => c.code === code)?.name ?? null;
}
