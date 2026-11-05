import type { DataBackend } from './backend';
import { createDemoBackend, type DemoBackend } from './demo/demoBackend';
import { createSupabaseBackend } from './supabase/supabaseBackend';

export type AppBackend = { kind: 'demo'; backend: DemoBackend } | { kind: 'supabase'; backend: DataBackend };

/**
 * Escolhe a fonte de dados: Supabase quando configurado em `.env.local`,
 * caso contrário o modo demonstração em memória.
 */
export function createBackend(): AppBackend {
  const url = import.meta.env.VITE_SUPABASE_URL as string | undefined;
  const key = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined;
  if (url && key) return { kind: 'supabase', backend: createSupabaseBackend(url, key) };
  return { kind: 'demo', backend: createDemoBackend() };
}
