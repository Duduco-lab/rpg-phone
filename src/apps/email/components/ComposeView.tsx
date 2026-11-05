import { ArrowLeft, Save, SendHorizontal, Trash2 } from 'lucide-react';
import { useState } from 'react';
import { COMPOSE_TITLES, type ComposeInit } from '../../../features/email/compose';
import { useMailbox } from '../../../features/email/MailboxProvider';
import { normalizeAddress } from '../../../domain/email';
import { errorMessage } from '../../../services/backend';
import { useSession } from '../../../session/SessionContext';
import { ConfirmSheet } from '../../../ui/ConfirmSheet';
import { IconButton } from '../../../ui/IconButton';
import { Spinner } from '../../../ui/Spinner';
import { RecipientField } from './RecipientField';

interface Props {
  init: ComposeInit;
  /** Fecha a tela; a mensagem opcional é exibida como aviso. */
  onClose: (message?: string) => void;
}

type Busy = null | 'send' | 'save' | 'discard';
type Sheet = null | 'leave' | 'discard';

export function ComposeView({ init, onClose }: Props) {
  const { client, snapshot } = useMailbox();
  const { activeCharacter } = useSession();
  const [to, setTo] = useState(init.to);
  const [pending, setPending] = useState('');
  const [subject, setSubject] = useState(init.subject);
  const [body, setBody] = useState(init.body);
  const [draftId, setDraftId] = useState(init.draftId);
  const [busy, setBusy] = useState<Busy>(null);
  const [error, setError] = useState<string | null>(null);
  const [sheet, setSheet] = useState<Sheet>(null);

  /** Inclui o texto ainda não convertido em chip. */
  const recipients = () => {
    const extra = pending.trim() ? [normalizeAddress(pending)] : [];
    return [...new Set([...to, ...extra])];
  };

  const dirty =
    pending.trim() !== '' ||
    subject !== init.subject ||
    body !== init.body ||
    to.join(',') !== init.to.join(',');
  const hasContent = recipients().length > 0 || subject.trim() !== '' || body.trim() !== '';

  const send = async () => {
    setError(null);
    const list = recipients();
    if (list.length === 0) {
      setError('Adicione pelo menos um destinatário.');
      return;
    }
    setBusy('send');
    try {
      await client.send({
        to: list,
        subject,
        body,
        conversationId: init.conversationId,
        inReplyToId: init.inReplyToId,
        draftId,
      });
      onClose('Mensagem enviada');
    } catch (e) {
      setError(errorMessage(e));
      setBusy(null);
    }
  };

  const saveDraft = async () => {
    setError(null);
    setSheet(null);
    setBusy('save');
    try {
      const saved = await client.saveDraft({
        id: draftId,
        to: recipients(),
        subject,
        body,
        conversationId: init.conversationId,
        inReplyToId: init.inReplyToId,
      });
      setDraftId(saved.id);
      onClose('Rascunho salvo');
    } catch (e) {
      setError(errorMessage(e));
      setBusy(null);
    }
  };

  const discard = async () => {
    setSheet(null);
    if (!draftId) {
      onClose(hasContent ? 'Mensagem descartada' : undefined);
      return;
    }
    setBusy('discard');
    try {
      await client.deleteDraft(draftId);
      onClose('Rascunho descartado');
    } catch (e) {
      setError(errorMessage(e));
      setBusy(null);
    }
  };

  const back = () => {
    if (dirty && hasContent) setSheet('leave');
    else onClose();
  };

  const replyingTo =
    init.inReplyToId && snapshot ? snapshot.messages.find((m) => m.id === init.inReplyToId) : undefined;

  return (
    <form
      className="compose"
      onSubmit={(e) => {
        e.preventDefault();
        void send();
      }}
    >
      <header className="mail-toolbar">
        <IconButton label="Voltar" onClick={back} disabled={busy !== null}>
          <ArrowLeft size={22} />
        </IconButton>
        <span className="mail-toolbar-title">{COMPOSE_TITLES[init.mode]}</span>
        <div className="mail-toolbar-actions">
          <IconButton label="Salvar como rascunho" onClick={() => void saveDraft()} disabled={busy !== null || !hasContent}>
            {busy === 'save' ? <Spinner size={18} /> : <Save size={20} />}
          </IconButton>
          <IconButton
            label={draftId ? 'Descartar rascunho' : 'Descartar'}
            onClick={() => (draftId || (dirty && hasContent) ? setSheet('discard') : onClose())}
            disabled={busy !== null}
          >
            <Trash2 size={20} />
          </IconButton>
          <IconButton label="Enviar" type="submit" className="send-btn" disabled={busy !== null}>
            {busy === 'send' ? <Spinner size={18} /> : <SendHorizontal size={21} />}
          </IconButton>
        </div>
      </header>

      {error && (
        <div className="compose-error" role="alert">
          {error}
        </div>
      )}

      <div className="mail-scroll compose-scroll">
        <div className="compose-row">
          <span className="compose-label">De</span>
          <span className="compose-from">{activeCharacter?.email}</span>
        </div>
        <div className="compose-row compose-row--to">
          <span className="compose-label">Para</span>
          <RecipientField
            value={to}
            onChange={setTo}
            pending={pending}
            onPendingChange={setPending}
            autoFocus={init.to.length === 0}
          />
        </div>
        <div className="compose-row">
          <input
            className="compose-subject"
            placeholder="Assunto"
            aria-label="Assunto"
            value={subject}
            maxLength={200}
            onChange={(e) => setSubject(e.target.value)}
          />
        </div>
        {replyingTo && (
          <div className="compose-context">
            Respondendo na conversa <strong>“{replyingTo.subject.replace(/^Re:\s*/i, '')}”</strong>
          </div>
        )}
        <textarea
          className="compose-body"
          placeholder="Escrever e-mail"
          aria-label="Mensagem"
          value={body}
          autoFocus={init.to.length > 0 && init.mode !== 'forward'}
          maxLength={20000}
          onChange={(e) => setBody(e.target.value)}
        />
      </div>

      {sheet === 'leave' && (
        <ConfirmSheet
          title="Sair sem enviar?"
          message="Você pode guardar esta mensagem nos Rascunhos para terminar depois."
          onCancel={() => setSheet(null)}
          cancelLabel="Continuar editando"
          actions={[
            { label: 'Salvar rascunho', tone: 'primary', onSelect: () => void saveDraft() },
            { label: 'Descartar', tone: 'danger', onSelect: () => void discard() },
          ]}
        />
      )}
      {sheet === 'discard' && (
        <ConfirmSheet
          title={draftId ? 'Descartar rascunho?' : 'Descartar mensagem?'}
          message={draftId ? 'O rascunho salvo será excluído.' : 'O que você escreveu será perdido.'}
          onCancel={() => setSheet(null)}
          actions={[{ label: 'Descartar', tone: 'danger', onSelect: () => void discard() }]}
        />
      )}
    </form>
  );
}
