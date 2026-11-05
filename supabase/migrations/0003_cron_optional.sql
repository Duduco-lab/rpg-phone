-- =====================================================================
-- OPCIONAL (recomendado): relógio dos NPCs rodando no servidor.
--
-- Sem isto, os e-mails dos NPCs são entregues quando algum jogador está
-- com o telefone aberto (o app chama npc_tick() periodicamente).
-- Com isto, o banco entrega a cada minuto, mesmo sem ninguém online.
--
-- No Supabase: Database → Extensions → habilite "pg_cron", depois rode:
-- =====================================================================

create extension if not exists pg_cron;

select cron.schedule('rpgphone-npc-tick', '* * * * *', $$select public.npc_tick()$$);

-- Para remover: select cron.unschedule('rpgphone-npc-tick');
