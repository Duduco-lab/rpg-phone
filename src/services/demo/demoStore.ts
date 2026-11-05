import type { CharacterId, CharacterProfile } from '../../domain/character';
import {
  isValidAddress,
  normalizeAddress,
  type DraftInput,
  type EmailDraft,
  type EmailMessage,
  type MailboxEntry,
  type MailboxEntryPatch,
  type MailboxEvent,
  type MailboxSnapshot,
  type MessageId,
  type SendEmailInput,
} from '../../domain/email';
import { DEMO_CHARACTERS } from '../../data/demo/characters';
import { DEMO_DRAFTS, DEMO_THREADS, seedCharacterId } from '../../data/demo/emails';
import { createId } from '../../lib/id';
import { BackendError } from '../backend';

type Listener = (event: MailboxEvent) => void;

const minutesAgo = (now: number, minutes: number) => new Date(now - minutes * 60_000).toISOString();

/**
 * Armazenamento EM MEMÓRIA usado somente na Fase 1 (demonstração).
 * Reproduz as regras que o backend real deverá impor (validação de
 * destinatários, participação na conversa, estado por personagem),
 * mas nada é persistido: recarregar a página restaura os dados iniciais.
 */
export class DemoStore {
  private characters: CharacterProfile[] = [];
  private messages: EmailMessage[] = [];
  private entries = new Map<CharacterId, Map<MessageId, MailboxEntry>>();
  private drafts = new Map<CharacterId, EmailDraft[]>();
  private listeners = new Map<CharacterId, Set<Listener>>();

  constructor() {
    this.seed();
  }

  // ---------------------------------------------------------------- seed

  reset(): void {
    this.seed();
    for (const id of this.listeners.keys()) this.emit(id, { type: 'changed' });
  }

  private seed(): void {
    const now = Date.now();
    this.characters = DEMO_CHARACTERS.map((c) => ({ ...c }));
    this.messages = [];
    this.entries = new Map();
    this.drafts = new Map();

    for (const thread of DEMO_THREADS) {
      const conversationId = createId('conv');
      let previous: MessageId | null = null;
      thread.messages.forEach((m, index) => {
        const message: EmailMessage = {
          id: createId('msg'),
          conversationId,
          from: this.requireCharacter(seedCharacterId(m.from)).email,
          to: m.to.map((k) => this.requireCharacter(seedCharacterId(k)).email),
          subject: index === 0 ? thread.subject : `Re: ${thread.subject}`,
          body: m.body,
          sentAt: minutesAgo(now, m.minutesAgo),
          inReplyToId: previous,
        };
        previous = message.id;
        this.messages.push(message);

        const participants = new Set([m.from, ...m.to]);
        for (const key of participants) {
          this.entryMap(seedCharacterId(key)).set(message.id, {
            messageId: message.id,
            isRead: key === m.from || !(m.unreadFor ?? []).includes(key),
            isImportant: (m.importantFor ?? []).includes(key),
            isArchived: (m.archivedFor ?? []).includes(key),
            isTrashed: (m.trashedFor ?? []).includes(key),
          });
        }
      });
    }

    for (const d of DEMO_DRAFTS) {
      const owner = seedCharacterId(d.owner);
      this.draftList(owner).push({
        id: createId('draft'),
        conversationId: null,
        inReplyToId: null,
        to: d.to.map((k) => this.requireCharacter(seedCharacterId(k)).email),
        subject: d.subject,
        body: d.body,
        updatedAt: minutesAgo(now, d.minutesAgo),
      });
    }
  }

  // ------------------------------------------------------------- helpers

  private requireCharacter(id: CharacterId): CharacterProfile {
    const c = this.characters.find((x) => x.id === id);
    if (!c) throw new BackendError('character_not_found', 'Personagem não encontrado.');
    return c;
  }

  private requireActiveCharacter(id: CharacterId): CharacterProfile {
    const c = this.requireCharacter(id);
    if (!c.active) throw new BackendError('character_inactive', 'Esta conta está desativada.');
    return c;
  }

  private byAddress(address: string): CharacterProfile | undefined {
    const a = normalizeAddress(address);
    return this.characters.find((c) => c.email === a);
  }

  private entryMap(id: CharacterId): Map<MessageId, MailboxEntry> {
    let map = this.entries.get(id);
    if (!map) {
      map = new Map();
      this.entries.set(id, map);
    }
    return map;
  }

  private draftList(id: CharacterId): EmailDraft[] {
    let list = this.drafts.get(id);
    if (!list) {
      list = [];
      this.drafts.set(id, list);
    }
    return list;
  }

  private emit(id: CharacterId, event: MailboxEvent): void {
    this.listeners.get(id)?.forEach((l) => l(event));
  }

  // ----------------------------------------------------------- directory

  listCharacters(): CharacterProfile[] {
    return this.characters.filter((c) => c.active).map((c) => ({ ...c }));
  }

  // ------------------------------------------------------------- mailbox

  snapshot(characterId: CharacterId): MailboxSnapshot {
    const owner = this.requireActiveCharacter(characterId);
    const own = this.entryMap(characterId);
    const messages = this.messages.filter((m) => own.has(m.id));
    const entries: Record<MessageId, MailboxEntry> = {};
    for (const [id, e] of own) entries[id] = { ...e };
    return structuredClone({
      ownerId: owner.id,
      ownerAddress: owner.email,
      messages,
      entries,
      drafts: this.draftList(characterId),
    });
  }

  send(characterId: CharacterId, input: SendEmailInput): EmailMessage {
    const sender = this.requireActiveCharacter(characterId);

    const recipients = [...new Set(input.to.map(normalizeAddress).filter(Boolean))];
    if (recipients.length === 0) throw new BackendError('no_recipients', 'Adicione pelo menos um destinatário.');
    const invalid = recipients.filter((r) => !isValidAddress(r));
    if (invalid.length) throw new BackendError('invalid_address', `Endereço inválido: ${invalid.join(', ')}`);
    const unknown = recipients.filter((r) => !this.byAddress(r)?.active);
    if (unknown.length) {
      throw new BackendError('unknown_address', `Endereço não encontrado: ${unknown.join(', ')}`);
    }
    if (!input.subject.trim() && !input.body.trim()) {
      throw new BackendError('empty_message', 'Escreva um assunto ou uma mensagem antes de enviar.');
    }

    let conversationId = input.conversationId;
    let inReplyToId = input.inReplyToId;
    if (conversationId) {
      // O remetente precisa participar da conversa para responder nela.
      const own = this.entryMap(characterId);
      const participates = this.messages.some((m) => m.conversationId === conversationId && own.has(m.id));
      if (!participates) throw new BackendError('forbidden', 'Você não participa desta conversa.');
      if (inReplyToId && !this.messages.some((m) => m.id === inReplyToId && m.conversationId === conversationId)) {
        inReplyToId = null;
      }
    } else {
      conversationId = createId('conv');
      inReplyToId = null;
    }

    const message: EmailMessage = {
      id: createId('msg'),
      conversationId,
      from: sender.email,
      to: recipients,
      subject: input.subject.trim() || '(sem assunto)',
      body: input.body.replace(/\s+$/, ''),
      sentAt: new Date().toISOString(),
      inReplyToId,
    };
    this.messages.push(message);

    this.entryMap(sender.id).set(message.id, {
      messageId: message.id,
      isRead: true,
      isImportant: false,
      isArchived: false,
      isTrashed: false,
    });
    const recipientChars = recipients.map((r) => this.byAddress(r)!).filter((c) => c.id !== sender.id);
    for (const rc of recipientChars) {
      this.entryMap(rc.id).set(message.id, {
        messageId: message.id,
        isRead: false,
        isImportant: false,
        isArchived: false,
        isTrashed: false,
      });
    }

    if (input.draftId) {
      const list = this.draftList(sender.id);
      this.drafts.set(
        sender.id,
        list.filter((d) => d.id !== input.draftId),
      );
    }

    this.emit(sender.id, { type: 'changed' });
    for (const rc of recipientChars) this.emit(rc.id, { type: 'received', messageId: message.id });
    return structuredClone(message);
  }

  saveDraft(characterId: CharacterId, input: DraftInput): EmailDraft {
    this.requireActiveCharacter(characterId);
    const list = this.draftList(characterId);
    const draft: EmailDraft = {
      id: input.id ?? createId('draft'),
      conversationId: input.conversationId,
      inReplyToId: input.inReplyToId,
      to: input.to.map(normalizeAddress).filter(Boolean),
      subject: input.subject,
      body: input.body,
      updatedAt: new Date().toISOString(),
    };
    const index = list.findIndex((d) => d.id === draft.id);
    if (input.id && index === -1) throw new BackendError('draft_not_found', 'Rascunho não encontrado.');
    if (index === -1) list.push(draft);
    else list[index] = draft;
    this.emit(characterId, { type: 'changed' });
    return { ...draft };
  }

  deleteDraft(characterId: CharacterId, draftId: string): void {
    this.requireActiveCharacter(characterId);
    this.drafts.set(
      characterId,
      this.draftList(characterId).filter((d) => d.id !== draftId),
    );
    this.emit(characterId, { type: 'changed' });
  }

  updateConversation(characterId: CharacterId, conversationId: string, patch: MailboxEntryPatch): void {
    this.requireActiveCharacter(characterId);
    const own = this.entryMap(characterId);
    let touched = 0;
    for (const m of this.messages) {
      if (m.conversationId !== conversationId) continue;
      const entry = own.get(m.id);
      if (!entry) continue;
      Object.assign(entry, patch);
      touched++;
    }
    if (touched === 0) throw new BackendError('not_found', 'Conversa não encontrada.');
    this.emit(characterId, { type: 'changed' });
  }

  deleteConversationForever(characterId: CharacterId, conversationId: string): void {
    this.requireActiveCharacter(characterId);
    const own = this.entryMap(characterId);
    for (const m of this.messages) {
      if (m.conversationId === conversationId && own.get(m.id)?.isTrashed) own.delete(m.id);
    }
    this.emit(characterId, { type: 'changed' });
  }

  subscribe(characterId: CharacterId, listener: Listener): () => void {
    let set = this.listeners.get(characterId);
    if (!set) {
      set = new Set();
      this.listeners.set(characterId, set);
    }
    set.add(listener);
    return () => set.delete(listener);
  }
}
