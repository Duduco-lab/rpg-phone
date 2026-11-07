-- =====================================================================
-- PASSO 1 de 2 — rode SOZINHO antes do 0007b.
-- (O Postgres exige que um novo valor de enum seja confirmado antes de ser usado.)
-- =====================================================================
alter type public.relation_kind add value if not exists 'romance';
