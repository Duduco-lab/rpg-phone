import { useCallback, useState } from 'react';
import type { ConversationId, MailboxEntryPatch } from '../../domain/email';
import { errorMessage } from '../../services/backend';
import { useMailbox } from './MailboxProvider';

/**
 * Ações sobre conversas com tratamento de erro padronizado.
 * Retorna `true` em caso de sucesso para que a tela decida o que fazer.
 */
export function useMailActions(toast: (message: string) => void) {
  const { client } = useMailbox();
  const [busy, setBusy] = useState(false);

  const run = useCallback(
    async (action: () => Promise<void>, success?: string): Promise<boolean> => {
      setBusy(true);
      try {
        await action();
        if (success) toast(success);
        return true;
      } catch (e) {
        toast(errorMessage(e));
        return false;
      } finally {
        setBusy(false);
      }
    },
    [toast],
  );

  const update = useCallback(
    (id: ConversationId, patch: MailboxEntryPatch, success?: string) =>
      run(() => client.updateConversation(id, patch), success),
    [client, run],
  );

  return {
    busy,
    markRead: (id: ConversationId) => update(id, { isRead: true }),
    markUnread: (id: ConversationId) => update(id, { isRead: false }, 'Marcada como não lida'),
    setImportant: (id: ConversationId, value: boolean) =>
      update(id, { isImportant: value }, value ? 'Marcada como importante' : 'Removida de Importantes'),
    archive: (id: ConversationId) => update(id, { isArchived: true }, 'Conversa arquivada'),
    unarchive: (id: ConversationId) => update(id, { isArchived: false }, 'Movida para a Caixa de entrada'),
    trash: (id: ConversationId) => update(id, { isTrashed: true }, 'Movida para a Lixeira'),
    restore: (id: ConversationId) => update(id, { isTrashed: false }, 'Conversa restaurada'),
    deleteForever: (id: ConversationId) =>
      run(() => client.deleteConversationForever(id), 'Excluída definitivamente'),
    deleteDraft: (draftId: string) => run(() => client.deleteDraft(draftId), 'Rascunho descartado'),
  };
}
