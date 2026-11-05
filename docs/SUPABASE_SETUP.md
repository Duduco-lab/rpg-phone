# Configurando o Supabase

O plano gratuito é suficiente. Projetos gratuitos **pausam após ~1 semana sem uso**
(reative com um clique no painel; os dados são mantidos).

## 1. Criar o projeto

1. Em <https://supabase.com>, clique em **New project** (região: *South America (São Paulo)*).
2. **Authentication → Sign In / Providers → Email**: para testes, desative **Confirm email**.
   (Com a confirmação ativada também funciona: o jogador recebe um link antes do primeiro login.)

## 2. Criar o banco

No **SQL Editor**, execute **na ordem** o conteúdo de:

1. `supabase/migrations/0001_schema.sql` — tabelas, segurança (RLS) e funções.
2. `supabase/migrations/0002_npc_templates.sql` — modelos de e-mail dos NPCs.
3. *(opcional, recomendado)* `supabase/migrations/0003_cron_optional.sql` — antes, habilite a
   extensão **pg_cron** em *Database → Extensions*. Assim os NPCs mandam e-mails mesmo com
   ninguém online. Sem isso, os e-mails dos NPCs chegam quando algum jogador está com o telefone aberto.

## 3. Conectar o app

1. Em **Project Settings → API**, copie a **Project URL** e a chave **anon public**.
2. Copie `.env.example` para `.env.local` e preencha:

   ```
   VITE_SUPABASE_URL=https://xxxx.supabase.co
   VITE_SUPABASE_ANON_KEY=eyJ...
   ```

3. Reinicie `npm run dev`. Sem essas variáveis o app volta ao modo demonstração.

> A chave **service_role** nunca deve ir para o `.env.local`, para o frontend ou para o repositório.
> O app não precisa dela.

## Ajustes do jogo (tabela `server_settings`)

| chave | padrão | efeito |
| --- | --- | --- |
| `npc_reply_delay_minutes` | `{"min": 2, "max": 12}` | tempo até o NPC responder |
| `npc_spontaneous_interval_hours` | `{"min": 10, "max": 36}` | intervalo entre e-mails espontâneos de cada NPC |
| `max_characters_per_user` | `5` | personagens por jogador |
| `max_circle_size` | `30` | pessoas por círculo |

Para testar rápido, por exemplo:

```sql
update server_settings set value = '{"min": 0.2, "max": 0.5}' where key = 'npc_reply_delay_minutes';
update server_settings set value = '{"min": 0.05, "max": 0.1}' where key = 'npc_spontaneous_interval_hours';
```

Novos modelos de e-mail podem ser inseridos em `npc_templates` (marcadores `{jogador}`, `{npc}`, `{relacao}`).
