import type { CharacterId } from '../../domain/character';
import type { DataBackend, MailboxClient } from '../backend';
import { DEMO_INCOMING_TEMPLATES } from '../../data/demo/emails';
import { DemoStore } from './demoStore';

/** Latência artificial para exercitar estados de carregamento como num backend real. */
const LATENCY_MS = 140;
const delay = <T>(fn: () => T): Promise<T> =>
  new Promise((resolve, reject) =>
    window.setTimeout(() => {
      try {
        resolve(fn());
      } catch (e) {
        reject(e);
      }
    }, LATENCY_MS),
  );

export interface DemoBackend extends DataBackend {
  /** Ferramentas do painel de demonstração (não existem no backend real). */
  tools: {
    reset(): void;
    simulateIncoming(toCharacterId: CharacterId, fromCharacterId: CharacterId): Promise<void>;
  };
}

export function createDemoBackend(): DemoBackend {
  const store = new DemoStore();
  const clients = new Map<CharacterId, MailboxClient>();

  const mailboxFor = (characterId: CharacterId): MailboxClient => {
    const cached = clients.get(characterId);
    if (cached) return cached;
    const client: MailboxClient = {
      characterId,
      load: () => delay(() => store.snapshot(characterId)),
      send: (input) => delay(() => store.send(characterId, input)),
      saveDraft: (input) => delay(() => store.saveDraft(characterId, input)),
      deleteDraft: (id) => delay(() => store.deleteDraft(characterId, id)),
      updateConversation: (conv, patch) => delay(() => store.updateConversation(characterId, conv, patch)),
      deleteConversationForever: (conv) => delay(() => store.deleteConversationForever(characterId, conv)),
      subscribe: (listener) => store.subscribe(characterId, listener),
    };
    clients.set(characterId, client);
    return client;
  };

  let templateIndex = 0;

  return {
    kind: 'demo',
    label: 'Demonstração — dados em memória',
    directory: { listCharacters: () => delay(() => store.listCharacters()) },
    mailboxFor,
    tools: {
      reset: () => store.reset(),
      async simulateIncoming(toId, fromId) {
        const recipient = store.listCharacters().find((c) => c.id === toId);
        if (!recipient) throw new Error('Destinatário inválido.');
        const template = DEMO_INCOMING_TEMPLATES[templateIndex++ % DEMO_INCOMING_TEMPLATES.length]!;
        // Passa pelas mesmas validações de um envio normal.
        await mailboxFor(fromId).send({
          to: [recipient.email],
          subject: template.subject,
          body: template.body,
          conversationId: null,
          inReplyToId: null,
          draftId: null,
        });
      },
    },
  };
}
