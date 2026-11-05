import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { App } from './App';
import { setupDiscord } from './discord/discord';
import './styles/global.css';
import './styles/phone.css';

const root = document.getElementById('root');
if (!root) throw new Error('Elemento #root não encontrado.');

// Dentro do Discord: proxy do Supabase + aperto de mão com o SDK (antes de criar o cliente).
void setupDiscord(import.meta.env.VITE_SUPABASE_URL as string | undefined)
  .catch((e: unknown) => console.error('Falha ao iniciar no Discord', e))
  .finally(() => {
    createRoot(root).render(
      <StrictMode>
        <App />
      </StrictMode>,
    );
  });
