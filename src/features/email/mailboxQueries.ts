import type {
  ConversationId,
  EmailAddress,
  EmailMessage,
  MailboxEntry,
  MailboxSnapshot,
  MailFolder,
} from '../../domain/email';

/**
 * Regras puras de organização da caixa postal (sem React, sem I/O).
 * Funcionam igual com dados demonstrativos ou vindos do Supabase.
 */

export interface ThreadSummary {
  conversationId: ConversationId;
  subject: string;
  /** Mensagens visíveis da conversa, em ordem cronológica. */
  messages: EmailMessage[];
  latest: EmailMessage;
  /** Participantes da conversa, exceto o dono da caixa. */
  participants: EmailAddress[];
  /** Quantidade total de mensagens visíveis. */
  count: number;
  unread: boolean;
  important: boolean;
  hasDraft: boolean;
}

export const FOLDER_LABELS: Record<MailFolder, string> = {
  inbox: 'Caixa de entrada',
  important: 'Importantes',
  sent: 'Enviados',
  drafts: 'Rascunhos',
  archived: 'Arquivados',
  trash: 'Lixeira',
};

const isReceived = (m: EmailMessage, owner: EmailAddress) => m.to.includes(owner);
const isSent = (m: EmailMessage, owner: EmailAddress) => m.from === owner;

export function messageInFolder(m: EmailMessage, e: MailboxEntry, owner: EmailAddress, folder: MailFolder): boolean {
  if (folder === 'trash') return e.isTrashed;
  if (e.isTrashed) return false;
  switch (folder) {
    case 'inbox':
      return isReceived(m, owner) && !e.isArchived;
    case 'sent':
      return isSent(m, owner);
    case 'important':
      return e.isImportant;
    case 'archived':
      return e.isArchived;
    case 'drafts':
      return false;
  }
}

function groupByConversation(messages: EmailMessage[]): Map<ConversationId, EmailMessage[]> {
  const groups = new Map<ConversationId, EmailMessage[]>();
  for (const m of messages) {
    const list = groups.get(m.conversationId);
    if (list) list.push(m);
    else groups.set(m.conversationId, [m]);
  }
  return groups;
}

const byDateAsc = (a: EmailMessage, b: EmailMessage) => a.sentAt.localeCompare(b.sentAt);

/** Mensagens exibidas ao abrir a conversa (na lixeira, só as excluídas). */
export function visibleConversationMessages(
  snapshot: MailboxSnapshot,
  conversationId: ConversationId,
  inTrash: boolean,
): EmailMessage[] {
  return snapshot.messages
    .filter((m) => {
      if (m.conversationId !== conversationId) return false;
      const e = snapshot.entries[m.id];
      return !!e && e.isTrashed === inTrash;
    })
    .sort(byDateAsc);
}

function summarize(snapshot: MailboxSnapshot, conversationId: ConversationId, inTrash: boolean): ThreadSummary | null {
  const owner = snapshot.ownerAddress;
  const messages = visibleConversationMessages(snapshot, conversationId, inTrash);
  const first = messages[0];
  const latest = messages[messages.length - 1];
  if (!first || !latest) return null;

  const participants = new Set<EmailAddress>();
  for (const m of messages) {
    participants.add(m.from);
    m.to.forEach((t) => participants.add(t));
  }
  participants.delete(owner);

  return {
    conversationId,
    subject: first.subject,
    messages,
    latest,
    participants: [...participants],
    count: messages.length,
    unread: messages.some((m) => isReceived(m, owner) && !snapshot.entries[m.id]?.isRead),
    important: messages.some((m) => snapshot.entries[m.id]?.isImportant),
    hasDraft: snapshot.drafts.some((d) => d.conversationId === conversationId),
  };
}

export function threadsForFolder(snapshot: MailboxSnapshot, folder: MailFolder): ThreadSummary[] {
  if (folder === 'drafts') return [];
  const owner = snapshot.ownerAddress;
  const matching = snapshot.messages.filter((m) => {
    const e = snapshot.entries[m.id];
    return !!e && messageInFolder(m, e, owner, folder);
  });
  const ids = [...groupByConversation(matching).keys()];
  return ids
    .map((id) => summarize(snapshot, id, folder === 'trash'))
    .filter((t): t is ThreadSummary => t !== null)
    .sort((a, b) => b.latest.sentAt.localeCompare(a.latest.sentAt));
}

export function findThread(
  snapshot: MailboxSnapshot,
  conversationId: ConversationId,
  inTrash: boolean,
): ThreadSummary | null {
  return summarize(snapshot, conversationId, inTrash);
}

/** Pasta "natural" de uma conversa (para rótulos e ações contextuais). */
export function conversationLocation(snapshot: MailboxSnapshot, conversationId: ConversationId): MailFolder {
  const owner = snapshot.ownerAddress;
  const mine = snapshot.messages.filter((m) => m.conversationId === conversationId);
  const entries = mine.map((m) => ({ m, e: snapshot.entries[m.id] })).filter((x) => x.e);
  if (entries.length > 0 && entries.every((x) => x.e!.isTrashed)) return 'trash';
  const live = entries.filter((x) => !x.e!.isTrashed);
  if (live.some((x) => isReceived(x.m, owner) && !x.e!.isArchived)) return 'inbox';
  if (live.some((x) => x.e!.isArchived)) return 'archived';
  return 'sent';
}

export interface FolderCounts {
  inbox: number;
  important: number;
  drafts: number;
}

export function folderCounts(snapshot: MailboxSnapshot): FolderCounts {
  return {
    inbox: threadsForFolder(snapshot, 'inbox').filter((t) => t.unread).length,
    important: threadsForFolder(snapshot, 'important').filter((t) => t.unread).length,
    drafts: snapshot.drafts.length,
  };
}

export type SearchScope = 'all' | 'from' | 'to' | 'subject' | 'body';

export const SEARCH_SCOPE_LABELS: Record<SearchScope, string> = {
  all: 'Tudo',
  from: 'Remetente',
  to: 'Destinatário',
  subject: 'Assunto',
  body: 'Conteúdo',
};

const fold = (s: string) =>
  s
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase();

/**
 * Pesquisa nas mensagens não excluídas. `nameOf` permite buscar
 * remetente/destinatário pelo nome do personagem, não só pelo endereço.
 */
export function searchThreads(
  snapshot: MailboxSnapshot,
  query: string,
  scope: SearchScope,
  nameOf: (address: EmailAddress) => string,
): ThreadSummary[] {
  const q = fold(query.trim());
  if (!q) return [];
  const person = (a: EmailAddress) => fold(`${nameOf(a)} ${a}`).includes(q);

  const hits = snapshot.messages.filter((m) => {
    const e = snapshot.entries[m.id];
    if (!e || e.isTrashed) return false;
    const fromHit = scope === 'all' || scope === 'from' ? person(m.from) : false;
    const toHit = scope === 'all' || scope === 'to' ? m.to.some(person) : false;
    const subjectHit = scope === 'all' || scope === 'subject' ? fold(m.subject).includes(q) : false;
    const bodyHit = scope === 'all' || scope === 'body' ? fold(m.body).includes(q) : false;
    return fromHit || toHit || subjectHit || bodyHit;
  });

  return [...groupByConversation(hits).keys()]
    .map((id) => summarize(snapshot, id, false))
    .filter((t): t is ThreadSummary => t !== null)
    .sort((a, b) => b.latest.sentAt.localeCompare(a.latest.sentAt));
}
