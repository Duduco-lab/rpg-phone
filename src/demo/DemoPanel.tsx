import { FlaskConical, MailPlus, RotateCcw, X } from 'lucide-react';
import { useState } from 'react';
import { fullName } from '../domain/character';
import { errorMessage } from '../services/backend';
import type { DemoBackend } from '../services/demo/demoBackend';
import { useSession } from '../session/SessionContext';

/**
 * Painel EXTERNO ao telefone, existente apenas na Fase 1.
 * Permite testar o fluxo entre personagens sem autenticação:
 * trocar o personagem em uso e simular a chegada de um e-mail.
 * Será removido quando a identidade vier do Discord (Fase 6).
 */
export function DemoPanel({ backend }: { backend: DemoBackend }) {
  const { characters, activeCharacter, setActiveCharacterId } = useSession();
  // Em janelas estreitas (ex.: Discord) começa recolhido para não cobrir o telefone.
  const [open, setOpen] = useState(() => window.matchMedia('(min-width: 900px)').matches);
  const [senderId, setSenderId] = useState('');
  const [feedback, setFeedback] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const others = characters.filter((c) => c.id !== activeCharacter?.id);
  const sender = others.find((c) => c.id === senderId) ?? others[0];

  if (!open) {
    return (
      <button type="button" className="demo-fab" onClick={() => setOpen(true)} title="Ferramentas de demonstração">
        <FlaskConical size={18} />
        Demo
      </button>
    );
  }

  return (
    <aside className="demo-panel" aria-label="Ferramentas de demonstração">
      <div className="demo-head">
        <FlaskConical size={16} />
        <strong>Modo demonstração</strong>
        <button type="button" className="demo-close" aria-label="Recolher painel" onClick={() => setOpen(false)}>
          <X size={16} />
        </button>
      </div>
      <p className="demo-note">
        Fase 1: dados fictícios <b>em memória</b>. Tudo volta ao estado inicial ao recarregar a página.
      </p>

      <label className="demo-field">
        <span>Personagem usando o telefone</span>
        <select value={activeCharacter?.id ?? ''} onChange={(e) => setActiveCharacterId(e.target.value)}>
          {characters.map((c) => (
            <option key={c.id} value={c.id}>
              {fullName(c)}
            </option>
          ))}
        </select>
      </label>

      <label className="demo-field">
        <span>Simular e-mail recebido de</span>
        <select value={sender?.id ?? ''} onChange={(e) => setSenderId(e.target.value)}>
          {others.map((c) => (
            <option key={c.id} value={c.id}>
              {fullName(c)}
            </option>
          ))}
        </select>
      </label>
      <button
        type="button"
        className="demo-btn demo-btn--primary"
        disabled={busy || !sender || !activeCharacter}
        onClick={async () => {
          if (!sender || !activeCharacter) return;
          setBusy(true);
          setFeedback(null);
          try {
            await backend.tools.simulateIncoming(activeCharacter.id, sender.id);
            setFeedback(`E-mail de ${fullName(sender)} entregue.`);
          } catch (e) {
            setFeedback(errorMessage(e));
          } finally {
            setBusy(false);
          }
        }}
      >
        <MailPlus size={16} /> Enviar e-mail de teste
      </button>

      <button
        type="button"
        className="demo-btn"
        onClick={() => {
          backend.tools.reset();
          setFeedback('Dados demonstrativos restaurados.');
        }}
      >
        <RotateCcw size={16} /> Restaurar dados iniciais
      </button>

      {feedback && <p className="demo-feedback">{feedback}</p>}
      <p className="demo-tip">
        Dica: envie um e-mail de um personagem para outro, depois troque de personagem para ver a mensagem chegar.
      </p>
    </aside>
  );
}
