import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import type { CharacterId } from '../domain/character';
import { readJson, writeJson } from '../lib/storage';

/**
 * Preferências visuais do aparelho (papel de parede e tema).
 * São preferências de interface — ficam no navegador do jogador, por
 * personagem. Não são dados do jogo e não precisam ir para o banco.
 */

export interface Wallpaper {
  id: string;
  name: string;
  css: string;
}

export const WALLPAPERS: Wallpaper[] = [
  {
    id: 'aurora',
    name: 'Aurora',
    css: 'radial-gradient(120% 80% at 10% 0%, #6d5dfc 0%, transparent 55%), radial-gradient(110% 70% at 100% 30%, #ff5fa2 0%, transparent 50%), radial-gradient(120% 90% at 30% 100%, #12c2c2 0%, transparent 55%), #14102b',
  },
  {
    id: 'porto',
    name: 'Porto à noite',
    css: 'radial-gradient(90% 60% at 80% 10%, #f6b05e55 0%, transparent 60%), linear-gradient(180deg, #0b1a33 0%, #17345c 45%, #0a1120 100%)',
  },
  {
    id: 'crepusculo',
    name: 'Crepúsculo',
    css: 'linear-gradient(170deg, #ffb36b 0%, #f5677a 38%, #8a3fa8 70%, #2b1849 100%)',
  },
  {
    id: 'oceano',
    name: 'Oceano',
    css: 'radial-gradient(120% 70% at 50% 0%, #4ee6d6 0%, transparent 60%), linear-gradient(180deg, #0e7c9b 0%, #0a3d62 60%, #071d33 100%)',
  },
  {
    id: 'floresta',
    name: 'Floresta',
    css: 'radial-gradient(100% 60% at 20% 10%, #b8e986 0%, transparent 55%), linear-gradient(180deg, #2f7a4f 0%, #174a37 55%, #0c2620 100%)',
  },
  {
    id: 'noir',
    name: 'Noir',
    css: 'radial-gradient(80% 50% at 50% 20%, #3a3d46 0%, transparent 70%), linear-gradient(180deg, #1b1c21 0%, #0b0b0e 100%)',
  },
];

export type ThemePreference = 'light' | 'dark' | 'system';

export interface PhonePreferences {
  wallpaperId: string;
  /** Imagem enviada pelo jogador (data URL). Tem prioridade sobre wallpaperId. */
  customWallpaper: string | null;
  theme: ThemePreference;
}

const DEFAULTS: PhonePreferences = { wallpaperId: 'aurora', customWallpaper: null, theme: 'light' };

interface PreferencesValue {
  prefs: PhonePreferences;
  resolvedTheme: 'light' | 'dark';
  wallpaperCss: string;
  update: (patch: Partial<PhonePreferences>) => boolean;
}

const PreferencesContext = createContext<PreferencesValue | null>(null);

function useSystemDark(): boolean {
  const query = '(prefers-color-scheme: dark)';
  const [dark, setDark] = useState(() => window.matchMedia?.(query).matches ?? false);
  useEffect(() => {
    const mq = window.matchMedia?.(query);
    if (!mq) return;
    const onChange = () => setDark(mq.matches);
    mq.addEventListener('change', onChange);
    return () => mq.removeEventListener('change', onChange);
  }, []);
  return dark;
}

export function PreferencesProvider({ characterId, children }: { characterId: CharacterId; children: ReactNode }) {
  const key = `rpgphone:prefs:${characterId}`;
  const [prefs, setPrefs] = useState<PhonePreferences>(() => readJson(key, DEFAULTS));
  const systemDark = useSystemDark();

  useEffect(() => setPrefs(readJson(key, DEFAULTS)), [key]);

  const update = useCallback(
    (patch: Partial<PhonePreferences>) => {
      const next = { ...prefs, ...patch };
      setPrefs(next);
      return writeJson(key, next);
    },
    [key, prefs],
  );

  const value = useMemo<PreferencesValue>(() => {
    const preset = WALLPAPERS.find((w) => w.id === prefs.wallpaperId) ?? WALLPAPERS[0]!;
    return {
      prefs,
      update,
      resolvedTheme: prefs.theme === 'system' ? (systemDark ? 'dark' : 'light') : prefs.theme,
      wallpaperCss: prefs.customWallpaper
        ? `center / cover no-repeat url("${prefs.customWallpaper}")`
        : preset.css,
    };
  }, [prefs, update, systemDark]);

  return <PreferencesContext.Provider value={value}>{children}</PreferencesContext.Provider>;
}

export function usePreferences(): PreferencesValue {
  const ctx = useContext(PreferencesContext);
  if (!ctx) throw new Error('usePreferences deve ser usado dentro de <PreferencesProvider>.');
  return ctx;
}
