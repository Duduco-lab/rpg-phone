import type { CharacterId } from './character';

export type EmailAddress = string;
export type ConversationId = string;
export type MessageId = string;

export const EMAIL_DOMAIN = 'rpgphone.app';

/** Um e-mail é sempre um registro independente (espelha a futura tabela `emails`). */
export interface EmailMessage {
  id: MessageId;
  conversationId: ConversationId;
  from: EmailAddress;
  to: EmailAddress[];
  subject: string;
  body: string;
  /** ISO-8601 */
  sentAt: string;
  inReplyToId: MessageId | null;
}

/**
 * Estado de uma mensagem na caixa postal de UM personagem
 * (espelha a futura tabela `email_labels`). Cada participante tem o seu.
 */
export interface MailboxEntry {
  messageId: MessageId;
  isRead: boolean;
  isImportant: boolean;
  isArchived: boolean;
  isTrashed: boolean;
}

export type MailboxEntryPatch = Partial<Omit<MailboxEntry, 'messageId'>>;

export interface EmailDraft {
  id: string;
  conversationId: ConversationId | null;
  inReplyToId: MessageId | null;
  to: EmailAddress[];
  subject: string;
  body: string;
  updatedAt: string;
}

export interface DraftInput {
  id: string | null;
  conversationId: ConversationId | null;
  inReplyToId: MessageId | null;
  to: EmailAddress[];
  subject: string;
  body: string;
}

export interface SendEmailInput {
  to: EmailAddress[];
  subject: string;
  body: string;
  /** Preenchido em respostas: a mensagem entra na mesma conversa. */
  conversationId: ConversationId | null;
  inReplyToId: MessageId | null;
  /** Rascunho de origem, removido após o envio. */
  draftId: string | null;
}

/** Tudo o que o personagem autenticado pode ver da própria caixa postal. */
export interface MailboxSnapshot {
  ownerId: CharacterId;
  ownerAddress: EmailAddress;
  messages: EmailMessage[];
  entries: Record<MessageId, MailboxEntry>;
  drafts: EmailDraft[];
}

export type MailFolder = 'inbox' | 'sent' | 'drafts' | 'important' | 'archived' | 'trash';

/** Eventos em tempo real da caixa postal. `received` traz só o ID: a caixa é recarregada antes de notificar. */
export type MailboxEvent = { type: 'changed' } | { type: 'received'; messageId: MessageId };

export function normalizeAddress(address: string): EmailAddress {
  return address.trim().toLowerCase();
}

export function isValidAddress(address: string): boolean {
  return /^[a-z0-9._-]+@[a-z0-9-]+(\.[a-z0-9-]+)*\.[a-z]{2,}$/i.test(address.trim());
}
