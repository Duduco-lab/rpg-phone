-- =====================================================================
-- Respostas de NPC coerentes com a mensagem recebida.
-- O banco identifica o ASSUNTO do e-mail do jogador (saudação, pergunta,
-- pedido, convite, agradecimento, desculpa, preocupação, carinho) e
-- escolhe um modelo daquele assunto, no tom do vínculo.
-- Marcadores: {jogador}, {npc}, {relacao}, {assunto} (assunto original).
-- =====================================================================

alter table public.npc_templates add column if not exists topic text not null default 'geral'
  check (topic in ('geral','saudacao','pergunta','pedido','convite','agradecimento','desculpa','preocupacao','afeto'));

-- Modelos antigos que já tinham cara de um assunto específico.
update public.npc_templates set topic = 'pedido'
  where purpose = 'reply' and (body like 'Recebido. Vou ver o que consigo fazer.%' or body like 'Tá bom, tá bom...%');
update public.npc_templates set topic = 'convite'
  where purpose = 'reply' and body like 'Fechado! Depois me passa os detalhes.%';

create index if not exists npc_templates_topic_idx on public.npc_templates (purpose, topic, relation_kind);

-- Identifica o assunto de uma mensagem (regras simples, em português).
create or replace function private.detect_topic(p_subject text, p_body text) returns text
language plpgsql immutable as $$
declare
  t text := lower(translate(coalesce(p_subject, '') || ' ' || coalesce(p_body, ''),
    'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
    'aaaaaeeeeiiiiooooouuuucaaaaaeeeeiiiiooooouuuuc'));
begin
  if t ~ '(urgente|socorro|perigo|hospital|morreu|morte|preso|policia|medo|assustad|ameaca|sumiu|desapareceu|acidente|problema serio)' then
    return 'preocupacao';
  elsif t ~ '(desculp|perdao|me perdoa|foi mal|me arrependo)' then
    return 'desculpa';
  elsif t ~ '(obrigad|valeu|agradec)' then
    return 'agradecimento';
  elsif t ~ '(vamos |bora|convite|convido|jantar|almoc|festa|aniversario|encontrar|nos ver|a gente se ve|sair hoje|sair amanha|tomar um cafe|cafe\?)' then
    return 'convite';
  elsif t ~ '(preciso|poderia|pode me|podia me|por favor|favor|me ajud|empresta|consegue)' then
    return 'pedido';
  elsif t ~ '(como (voce )?(esta|vai|anda)|tudo bem|tudo certo|quanto tempo|faz tempo|sumid|saudade|novidades)' then
    return 'saudacao';
  elsif t ~ '(te amo|amo voce|meu amor|beijo|carinho|apaixon|querid)' then
    return 'afeto';
  elsif t ~ '\?' then
    return 'pergunta';
  end if;
  return 'geral';
end $$;

-- Mesma assinatura de antes: agora considera o assunto da mensagem respondida.
create or replace function private.enqueue_npc_message(
  p_npc uuid, p_player uuid, p_purpose text,
  p_conversation uuid, p_in_reply_to uuid, p_deliver_at timestamptz
) returns void
language plpgsql volatile security definer set search_path = public as $$
declare
  v_kind public.relation_kind := 'outro';
  v_label text := 'conhecido(a)';
  v_npc public.characters;
  v_player public.characters;
  v_tpl public.npc_templates;
  v_topic text := 'geral';
  v_orig_subject text := '';
  v_subject text;
  v_body text;
begin
  select * into v_npc from public.characters where id = p_npc;
  select * into v_player from public.characters where id = p_player;
  if v_npc.id is null or v_player.id is null then return; end if;

  select relation_kind, relation_label into v_kind, v_label
  from public.character_relationships
  where character_id = p_player and related_character_id = p_npc;
  v_kind := coalesce(v_kind, 'outro');
  v_label := coalesce(v_label, 'conhecido(a)');

  if p_purpose = 'reply' and p_in_reply_to is not null then
    select private.detect_topic(subject, body), regexp_replace(subject, '^((re|fwd?|enc)\s*:\s*)+', '', 'i')
      into v_topic, v_orig_subject
    from public.emails where id = p_in_reply_to;
    v_topic := coalesce(v_topic, 'geral');
  end if;

  select t.* into v_tpl
  from public.npc_templates t
  where t.purpose = p_purpose
    and t.relation_kind in (v_kind, 'outro')
    and (p_purpose <> 'reply' or t.topic in (v_topic, 'geral'))
  order by
    (t.topic = v_topic) desc,            -- 1º: responde ao que foi dito
    (t.relation_kind = v_kind) desc,     -- 2º: no tom do vínculo
    (select count(*) from public.npc_outbox o
      where o.template_id = t.id and o.npc_character_id = p_npc and o.to_character_id = p_player),
    random()
  limit 1;
  if v_tpl.id is null then return; end if;

  v_body := replace(replace(replace(replace(v_tpl.body,
    '{jogador}', v_player.first_name),
    '{npc}', v_npc.first_name),
    '{relacao}', v_label),
    '{assunto}', coalesce(nullif(v_orig_subject, ''), 'isso'));

  if p_purpose = 'reply' and p_conversation is not null then
    select 'Re: ' || regexp_replace(subject, '^((re|fwd?|enc)\s*:\s*)+', '', 'i') into v_subject
    from public.email_conversations where id = p_conversation;
  else
    v_subject := replace(replace(v_tpl.subject, '{jogador}', v_player.first_name), '{npc}', v_npc.first_name);
  end if;

  insert into public.npc_outbox (npc_character_id, to_character_id, conversation_id, in_reply_to_id,
    template_id, purpose, subject, body, deliver_at)
  values (p_npc, p_player, p_conversation, p_in_reply_to, v_tpl.id, p_purpose,
    left(coalesce(v_subject, '(sem assunto)'), 200), v_body, p_deliver_at);
end $$;

revoke all on function private.detect_topic(text, text) from public, anon, authenticated;
revoke all on function private.enqueue_npc_message(uuid, uuid, text, uuid, uuid, timestamptz) from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- Novos modelos de resposta por assunto.
-- 'outro' serve para qualquer vínculo; os específicos dão o tom.
-- ---------------------------------------------------------------------
insert into public.npc_templates (relation_kind, purpose, topic, body) values
-- saudação / "como você está?"
('outro', 'reply', 'saudacao', 'Oi, {jogador}! Pois é, faz um tempinho mesmo.

Por aqui está tudo bem, dentro do possível. E você, como tem passado?

{npc}'),
('outro', 'reply', 'saudacao', 'Que bom receber notícias suas, {jogador}.

Estou bem, obrigado(a) por perguntar. Me conta as novidades daí!

{npc}'),
('irmao', 'reply', 'saudacao', 'Oi, {jogador}! Saudade também, viu?

Por aqui vai tudo bem, na correria de sempre. E você, como anda? A gente precisa se ver logo — tô sentindo falta das nossas conversas.

{npc}'),
('irmao', 'reply', 'saudacao', 'Olha só quem lembrou que tem família! 😄

Brincadeira. Tô bem, e você? Faz tempo mesmo… vamos marcar alguma coisa essa semana?

{npc}'),
('pai_mae', 'reply', 'saudacao', 'Ah, {jogador}, que alegria ler isso!

Eu estou bem, com as dores de sempre, mas bem. E você? Está se cuidando? Está comendo direito?

Venha me ver quando puder.
{npc}'),
('filho', 'reply', 'saudacao', 'Oi! Tô bem sim, e você?

Senti sua falta também. Vamos nos ver logo?

{npc}'),
('parente', 'reply', 'saudacao', 'Oi, {jogador}! Que bom ter notícias suas.

Por aqui todos bem, graças a Deus. E por aí, como estão as coisas?

{npc}'),
('parceiro', 'reply', 'saudacao', 'Oi, você. Estou bem — melhor agora, lendo sua mensagem.

E você? Como foi o seu dia?

{npc}'),
('amigo', 'reply', 'saudacao', 'E aí, {jogador}! Tudo certo por aqui.

Faz tempo mesmo, hein? Bora marcar alguma coisa pra colocar o papo em dia.

{npc}'),
('colega', 'reply', 'saudacao', 'Oi, {jogador}! Tudo bem por aqui, bastante trabalho, como sempre.

E com você?

{npc}'),
('chefe', 'reply', 'saudacao', '{jogador}, estou bem. Ocupado(a), como sempre.

Se for algo de trabalho, seja direto(a).

{npc}'),
('ex', 'reply', 'saudacao', 'Oi, {jogador}. Estou bem… melhor do que antes, acho.

Não esperava ter notícias suas. E você, como está?

{npc}'),
('rival', 'reply', 'saudacao', 'Preocupado(a) comigo, {jogador}? Que comovente.

Estou ótimo(a). Melhor do que você gostaria.

{npc}'),

-- pergunta
('outro', 'reply', 'pergunta', 'Boa pergunta, {jogador}.

Deixa eu pensar com calma e te respondo direito — não quero falar besteira.

{npc}'),
('outro', 'reply', 'pergunta', 'Sobre "{assunto}": não tenho certeza, {jogador}. Prefiro te explicar pessoalmente.

{npc}'),
('irmao', 'reply', 'pergunta', 'Sério que você tá me perguntando isso? 😅

Tá, eu te conto, mas pessoalmente. Por escrito não dá.

{npc}'),
('pai_mae', 'reply', 'pergunta', '{jogador}, isso é coisa pra gente conversar olhando no olho.

Passa aqui em casa que eu te explico tudo.

{npc}'),
('amigo', 'reply', 'pergunta', 'Olha, sinceramente? Não sei te dizer.

Mas posso descobrir. Me dá um tempinho.

{npc}'),
('chefe', 'reply', 'pergunta', '{jogador}, a resposta é a de sempre: depende dos resultados.

Conversamos na próxima reunião.

{npc}'),
('rival', 'reply', 'pergunta', 'E por que eu responderia isso a você, {jogador}?

{npc}'),

-- pedido / favor
('outro', 'reply', 'pedido', 'Entendi o que você precisa, {jogador}.

Vou ver o que consigo fazer e te aviso.

{npc}'),
('irmao', 'reply', 'pedido', 'Tá bom, eu te ajudo. Como sempre, né?

Mas essa vai pra conta, {jogador}. 😏

{npc}'),
('pai_mae', 'reply', 'pedido', 'Claro que eu ajudo, {jogador}. Para que serve família?

Só me diga quando e como.

{npc}'),
('parceiro', 'reply', 'pedido', 'Pode deixar comigo.

Pra você, eu dou um jeito.
{npc}'),
('amigo', 'reply', 'pedido', 'Pode contar comigo, {jogador}! É pra isso que servem os amigos.

Me passa os detalhes.

{npc}'),
('colega', 'reply', 'pedido', 'Consigo sim, {jogador}. Só preciso de um prazo — até amanhã serve?

{npc}'),
('chefe', 'reply', 'pedido', 'Vou avaliar o seu pedido, {jogador}.

Não prometo nada.

{npc}'),
('ex', 'reply', 'pedido', 'Você tem coragem de me pedir isso, {jogador}.

…Vou pensar.

{npc}'),
('rival', 'reply', 'pedido', 'Interessante. Você me pedindo um favor.

Tudo tem um preço, {jogador}. Vamos conversar.

{npc}'),

-- convite
('outro', 'reply', 'convite', 'Aceito, {jogador}! Me diz dia e hora.

{npc}'),
('outro', 'reply', 'convite', 'Vou tentar, {jogador}. Essa semana está corrida, mas confirmo até amanhã.

{npc}'),
('irmao', 'reply', 'convite', 'Bora! Tava precisando mesmo.

Só não vale furar dessa vez, {jogador}.

{npc}'),
('pai_mae', 'reply', 'convite', 'Mas é claro que eu vou, {jogador}!

Quer que eu leve alguma coisa?

{npc}'),
('parceiro', 'reply', 'convite', 'É um encontro, então. 😊

Mal posso esperar.
{npc}'),
('chefe', 'reply', 'convite', 'Agradeço o convite, {jogador}, mas minha agenda está cheia.

Quem sabe outra hora.

{npc}'),
('ex', 'reply', 'convite', 'Não sei se é uma boa ideia, {jogador}.

…Mas talvez um café não faça mal.

{npc}'),
('rival', 'reply', 'convite', 'Um convite seu? Agora fiquei curioso(a).

Estarei lá. Mas não pense que baixei a guarda.

{npc}'),

-- agradecimento
('outro', 'reply', 'agradecimento', 'Imagina, {jogador}! Não precisa agradecer.

{npc}'),
('irmao', 'reply', 'agradecimento', 'De nada, {jogador}. Mas não se acostuma, hein! 😄

{npc}'),
('pai_mae', 'reply', 'agradecimento', 'Não precisa agradecer, {jogador}. Faço tudo por você.

{npc}'),
('parceiro', 'reply', 'agradecimento', 'Sempre, meu bem.

{npc}'),
('chefe', 'reply', 'agradecimento', 'Não agradeça. Trabalhe.

{npc}'),

-- desculpa
('outro', 'reply', 'desculpa', 'Tudo bem, {jogador}. Já passou.

{npc}'),
('irmao', 'reply', 'desculpa', 'Tá desculpado(a), {jogador}. Família é isso, né?

Mas me deve um almoço.

{npc}'),
('pai_mae', 'reply', 'desculpa', 'Ah, {jogador}… eu nunca consigo ficar bravo(a) com você por muito tempo.

Está tudo bem.

{npc}'),
('parceiro', 'reply', 'desculpa', 'Obrigado(a) por dizer isso.

A gente conversa melhor em casa, tá? Eu também errei.

{npc}'),
('ex', 'reply', 'desculpa', 'Desculpas aceitas, {jogador}.

Mas isso não muda o que aconteceu.

{npc}'),
('rival', 'reply', 'desculpa', 'Um pedido de desculpas seu? Vou guardar este e-mail de recordação.

{npc}'),

-- preocupação / urgência
('outro', 'reply', 'preocupacao', '{jogador}, fiquei preocupado(a) com o que você escreveu.

Onde você está? Me diz como posso ajudar.

{npc}'),
('irmao', 'reply', 'preocupacao', '{jogador}, o que aconteceu?! Me liga AGORA.

Se precisar, eu vou aí.

{npc}'),
('pai_mae', 'reply', 'preocupacao', 'Meu Deus, {jogador}! Você está bem?

Me responde, por favor. Estou indo aí se for preciso.

{npc}'),
('parceiro', 'reply', 'preocupacao', 'Estou indo até você. Fica onde está.

Vai ficar tudo bem, eu prometo.

{npc}'),
('amigo', 'reply', 'preocupacao', 'Calma, {jogador}. Me conta exatamente o que aconteceu.

Seja o que for, a gente resolve junto.

{npc}'),
('rival', 'reply', 'preocupacao', 'Problemas, {jogador}? Não diga que eu não avisei.

…Se precisar de ajuda de verdade, me procure. Só desta vez.

{npc}'),

-- carinho / afeto
('outro', 'reply', 'afeto', 'Que mensagem bonita, {jogador}. Obrigado(a) por isso.

{npc}'),
('irmao', 'reply', 'afeto', 'Para com isso que eu fico sem graça. 😅

Mas eu também gosto muito de você, {jogador}.

{npc}'),
('pai_mae', 'reply', 'afeto', 'Ai, {jogador}, você me fez chorar.

Eu te amo muito. Nunca se esqueça disso.

{npc}'),
('parceiro', 'reply', 'afeto', 'Eu também te amo, {jogador}.

Mais do que consigo escrever.
{npc}'),
('ex', 'reply', 'afeto', 'Não faz isso, {jogador}.

Não depois de tudo.

{npc}');
