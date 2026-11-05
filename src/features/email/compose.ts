import type { ConversationId, EmailAddress, EmailDraft, EmailMessage, MessageId } from '../../domain/email';
import { formatFullDate } from '../../lib/format';

export type ComposeMode = 'new' | 'reply' | 'replyAll' | 'forward' | 'draft';

/** Estado inicial da tela de composição. */
export interface ComposeInit {
  mode: ComposeMode;
  draftId: string | null;
  to: EmailAddress[];
  subject: string;
  body: string;
  conversationId: ConversationId | null;
  inReplyToId: MessageId | null;
}

export const COMPOSE_TITLES: Record<ComposeMode, string> = {
  new: 'Escrever',
  reply: 'Responder',
  replyAll: 'Responder a todos',
  forward: 'Encaminhar',
  draft: 'Rascunho',
};

const stripPrefix = (subject: string) => subject.replace(/^((re|fwd?|enc)\s*:\s*)+/i, '');

export function newCompose(to: EmailAddress[] = []): ComposeInit {
  return { mode: 'new', draftId: null, to, subject: '', body: '', conversationId: null, inReplyToId: null };
}

export function composeFromDraft(d: EmailDraft): ComposeInit {
  return {
    mode: 'draft',
    draftId: d.id,
    to: d.to,
    subject: d.subject,
    body: d.body,
    conversationId: d.conversationId,
    inReplyToId: d.inReplyToId,
  };
}

/** Resposta: permanece na mesma conversa, preservando o histórico. */
export function composeReply(message: EmailMessage, owner: EmailAddress, all: boolean): ComposeInit {
  let to: EmailAddress[];
  if (message.from === owner) {
    // Respondendo a algo que eu mesmo enviei: volta para os destinatários originais.
    to = message.to.filter((a) => a !== owner);
  } else if (all) {
    to = [message.from, ...message.to.filter((a) => a !== owner && a !== message.from)];
  } else {
    to = [message.from];
  }
  return {
    mode: all ? 'replyAll' : 'reply',
    draftId: null,
    to: to.length ? to : [message.from],
    subject: `Re: ${stripPrefix(message.subject)}`,
    body: '',
    conversationId: message.conversationId,
    inReplyToId: message.id,
  };
}

/** Encaminhamento: inicia uma nova conversa com o conteúdo citado. */
export function composeForward(message: EmailMessage, nameOf: (a: EmailAddress) => string): ComposeInit {
  const label = (a: EmailAddress) => `${nameOf(a)} <${a}>`;
  const quoted = [
    '',
    '',
    '---------- Mensagem encaminhada ----------',
    `De: ${label(message.from)}`,
    `Data: ${formatFullDate(message.sentAt)}`,
    `Assunto: ${message.subject}`,
    `Para: ${message.to.map(label).join(', ')}`,
    '',
    message.body,
  ].join('\n');
  return {
    mode: 'forward',
    draftId: null,
    to: [],
    subject: `Fwd: ${stripPrefix(message.subject)}`,
    body: quoted,
    conversationId: null,
    inReplyToId: null,
  };
}
