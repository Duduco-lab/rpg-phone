# RPG Phone — Decisões de arquitetura

## Visão geral

```
src/
├─ domain/            Tipos do domínio (personagem, e-mail). Sem React, sem I/O.
├─ services/
│  ├─ backend.ts      Contratos de acesso a dados (MailboxClient, DirectoryClient, DataBackend)
│  └─ demo/           Implementação EM MEMÓRIA (somente Fase 1)
├─ data/demo/         Dados demonstrativos (personagens, conversas, rascunho)
├─ session/           Sessão: personagem ativo, diretório, resolução endereço → identidade
├─ features/email/    Lógica de negócio do e-mail (consultas puras, provider, ações, composição)
├─ phone/             "Sistema operacional": moldura, status bar, tela inicial, navegação, notificações, preferências
├─ apps/              Aplicativos (email, contacts, settings, placeholder) + componentes compartilhados
├─ ui/                Componentes visuais genéricos (Avatar, IconButton, Spinner, ConfirmSheet…)
├─ demo/              Painel externo de demonstração (somente Fase 1)
└─ styles/            CSS global e do aparelho
```

Separação em três camadas:

| Camada | Onde | Regra |
| --- | --- | --- |
| Interface | `apps/`, `phone/`, `ui/` | Só renderiza e chama hooks. Nunca acessa armazenamento. |
| Lógica de negócio | `features/`, `domain/` | Funções puras (`mailboxQueries.ts`, `compose.ts`) + hooks de estado. |
| Acesso a dados | `services/` | Implementa os contratos de `services/backend.ts`. |

## Decisões

1. **Contrato único de backend.** A UI conversa com `DataBackend`/`MailboxClient`. Na Fase 2 basta criar
   `services/supabase/` cumprindo o mesmo contrato e trocar a instância em `App.tsx`.
2. **Cliente por personagem, não por parâmetro.** `backend.mailboxFor(id)` devolve um cliente já vinculado.
   No backend real o ID virá da sessão autenticada (Discord → usuário → personagens que ele controla),
   validado no servidor/RLS; um ID enviado pelo frontend nunca será confiado.
3. **Cada e-mail é um registro independente** (`EmailMessage`) ligado a uma conversa (`conversationId`).
   O estado (lido, importante, arquivado, lixeira) é **por personagem** (`MailboxEntry`) — espelha as
   futuras tabelas `emails` e `email_labels`. Arquivar/excluir só afeta a caixa de quem executou.
4. **Pastas são consultas, não colunas.** Entrada, Enviados, Importantes, Arquivados e Lixeira são
   derivados em `mailboxQueries.ts`; Rascunhos é uma lista própria.
5. **Respostas ficam na mesma conversa**; encaminhamentos abrem uma nova (como no Gmail). O backend
   demo já valida que só participantes podem responder numa conversa.
6. **Eventos em tempo real** via `subscribe()` (`changed` / `received`). Hoje é um emissor em memória;
   na Fase 4 será o Supabase Realtime. O `MailboxProvider` recarrega e dispara notificações.
7. **Um aparelho por personagem.** Trocar de personagem remonta `<Phone>` (estado limpo). Preferências
   visuais (papel de parede, tema) ficam no `localStorage`, separadas por personagem — são
   preferências de interface, não dados do jogo.
8. **Tela em tamanho lógico fixo (390×844) escalada** para caber em qualquer janela (inclusive o painel
   da Discord Activity). Abaixo de 500 px de largura, a tela ocupa a janela sem moldura.
9. **Sem recursos externos em tempo de execução** (fontes/CDNs): a Discord Activity aplica CSP e exige
   proxy para domínios externos.
10. **Apps não implementados não fingem funcionar**: exibem "Em desenvolvimento" e a lista do que está
    planejado, sem botões falsos.

## Dados demonstrativos (Fase 1)

- Vivem apenas em memória (`services/demo/demoStore.ts`); recarregar a página restaura o estado inicial.
- Há latência artificial de ~140 ms para exercitar estados de carregamento.
- O painel "Modo demonstração" (fora do telefone) permite trocar o personagem ativo e simular um e-mail
  recebido. Ele substitui provisoriamente a autenticação e será removido na Fase 6.

## Supabase, personagens e círculo (implementado)

- `services/createBackend.ts` escolhe Supabase quando `VITE_SUPABASE_URL`/`VITE_SUPABASE_ANON_KEY`
  existem; senão, modo demonstração. Configuração: [SUPABASE_SETUP.md](SUPABASE_SETUP.md).
- **Toda escrita é uma RPC `SECURITY DEFINER`** que chama `private.require_owner()`: o banco confere
  que `auth.uid()` controla o personagem. Não existem políticas de INSERT/UPDATE/DELETE; leituras
  diretas (usadas pelo Realtime) são filtradas por RLS. Funções internas ficam no schema `private`.
- **Círculo** (`character_relationships`): "fulano É `relation_label` (tipo `relation_kind`) de X".
  A pessoa pode ser um personagem existente ou um **NPC** criado na hora (`characters.kind = 'npc'`).
- **Motor de NPCs, 100% no banco**:
  - jogador escreve para um NPC → `npc_outbox` recebe uma resposta agendada (2–12 min);
  - cada vínculo com NPC tem `next_spontaneous_at` → e-mails espontâneos a cada 10–36 h
    (sem acumular: pula se já houver 2 não lidos daquele NPC);
  - `npc_tick()` entrega o que venceu — via pg_cron (opcional) e chamado pelos clientes abertos
    (idempotente, com advisory lock);
  - textos vêm de `npc_templates` por tipo de vínculo, preferindo os menos usados com aquele jogador.
- **Assumir um NPC**: cada NPC tem um `claim_code`. Quem o usa vira dono do personagem, o histórico
  é mantido, a simulação para e as respostas pendentes são canceladas.
- **Tempo real**: Realtime em `mailbox_entries` (filtrado por personagem e RLS). Um INSERT não lido
  gera notificação; outras mudanças recarregam a caixa.
- **Testes do SQL**: as migrações foram executadas num Postgres local (PGlite) com stubs do Supabase
  e 42 verificações (autorização, RLS, conversas, NPCs, convite) passaram.

## Próximas fases (resumo)

- **Fase 2 — Supabase:** tabelas `users`, `characters`, `phones`, `contacts`, `email_addresses`,
  `email_conversations`, `email_conversation_members`, `emails`, `email_labels`, `email_attachments`,
  `server_settings`, `audit_logs`; RLS baseada em `email_conversation_members` + dono do personagem;
  envio via função no servidor (RPC/Edge Function/Worker) que valida remetente e destinatários.
- **Configuração externa necessária:** projeto Supabase (URL + anon key no frontend; `service_role`
  apenas no servidor), e futuramente aplicação no Discord Developer Portal (Client ID/Secret no servidor).
