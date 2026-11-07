-- =====================================================================
-- E-mails de NPC: filhos chamam de pai/mãe, cônjuge expandido, romance.
-- Novos marcadores: {pai_mae} / {Pai_mae} → "pai"/"mãe" conforme o gênero
-- do personagem do jogador (neutro → primeiro nome).
-- =====================================================================

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
  v_parent text;
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
    (t.topic = v_topic) desc,
    (t.relation_kind = v_kind) desc,
    (select count(*) from public.npc_outbox o
      where o.template_id = t.id and o.npc_character_id = p_npc and o.to_character_id = p_player),
    random()
  limit 1;
  if v_tpl.id is null then return; end if;

  v_parent := case v_player.gender when 'm' then 'pai' when 'f' then 'mãe' else v_player.first_name end;

  v_body := replace(replace(replace(replace(replace(replace(v_tpl.body,
    '{jogador}', v_player.first_name),
    '{npc}', v_npc.first_name),
    '{relacao}', v_label),
    '{assunto}', coalesce(nullif(v_orig_subject, ''), 'isso')),
    '{Pai_mae}', upper(left(v_parent, 1)) || substr(v_parent, 2)),
    '{pai_mae}', v_parent);

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

revoke all on function private.enqueue_npc_message(uuid, uuid, text, uuid, uuid, timestamptz) from public, anon, authenticated;

-- ------------------------------------------------------------- filhos
delete from public.npc_templates where relation_kind = 'filho';

insert into public.npc_templates (relation_kind, purpose, topic, subject, body) values
('filho', 'spontaneous', 'geral', 'Saudade', 'Oi, {pai_mae}!

Tô com saudade. Quando a gente vai almoçar junto de novo? Só nós dois, como antigamente.

Te amo,
{npc}'),
('filho', 'spontaneous', 'geral', 'Preciso de uma ajuda', '{Pai_mae}, posso te pedir uma coisa?

Prometo que explico direitinho pessoalmente. Não é nada grave, juro!

{npc}'),
('filho', 'spontaneous', 'geral', 'Novidade!', '{Pai_mae}!! Tenho uma novidade e você vai ser a primeira pessoa a saber.

Me liga quando puder?

{npc}'),
('filho', 'spontaneous', 'geral', 'Posso conversar com você?', 'Oi, {pai_mae}.

Posso conversar com você sobre uma coisa que tá me incomodando? Não queria falar por escrito.

{npc}'),
('filho', 'spontaneous', 'geral', 'Achei uma foto nossa', '{Pai_mae}, achei uma foto nossa de quando eu era pequeno(a)…

Você não mudou nada. Já eu, nem se fala. 😅

{npc}'),
('filho', 'spontaneous', 'geral', 'Obrigado(a)', 'Só queria dizer obrigado(a) por tudo, {pai_mae}.

Às vezes eu esqueço de falar, mas sei o quanto você faz por mim.

{npc}'),
('filho', 'spontaneous', 'geral', 'Você viu o que falaram?', '{Pai_mae}, você viu o que andam falando da nossa família no Twixer?

Não liga pra isso, tá? Eu sei quem você é.

{npc}'),
('filho', 'reply', 'geral', '', 'Valeu, {pai_mae}! Você sempre sabe o que dizer. ❤️

{npc}'),
('filho', 'reply', 'geral', '', 'Tá bom, {pai_mae}, vou fazer do jeito que você falou.

Mas depois não diga que eu não avisei! 😄

{npc}'),
('filho', 'reply', 'geral', '', 'Recebi, {pai_mae}! Depois a gente conversa melhor, tá?

Beijo,
{npc}'),
('filho', 'reply', 'saudacao', '', 'Oi, {pai_mae}! Tô bem sim, e você?

Senti sua falta. Vamos nos ver logo?

{npc}'),
('filho', 'reply', 'pergunta', '', 'Ai, {pai_mae}, que pergunta difícil…

Deixa eu pensar e te respondo direito, tá?

{npc}'),
('filho', 'reply', 'pedido', '', 'Claro, {pai_mae}! Pode deixar comigo.

Pra você eu faço qualquer coisa.

{npc}'),
('filho', 'reply', 'convite', '', 'Óbvio que eu vou, {pai_mae}! Já tô contando os dias. 🥰

{npc}'),
('filho', 'reply', 'agradecimento', '', 'Imagina, {pai_mae}! Você que merece. ❤️

{npc}'),
('filho', 'reply', 'desculpa', '', 'Tá tudo bem, {pai_mae}. Eu também errei.

Te amo mesmo assim.

{npc}'),
('filho', 'reply', 'preocupacao', '', '{Pai_mae}, o que aconteceu?! Tô ficando preocupado(a).

Me liga agora, por favor!

{npc}'),
('filho', 'reply', 'afeto', '', 'Também te amo muito, {pai_mae}.

Você é a melhor pessoa do mundo pra mim. ❤️

{npc}');

-- ------------------------------------------------- cônjuge (expansão)
insert into public.npc_templates (relation_kind, purpose, topic, subject, body) values
('parceiro', 'spontaneous', 'geral', 'Bom dia, amor', 'Bom dia, meu amor. ☀️

Acordei e você já tinha saído. Fiquei olhando o seu lado da cama vazio. Volta cedo hoje?

{npc}'),
('parceiro', 'spontaneous', 'geral', 'Hoje à noite', '{jogador}, reservei uma mesa para nós hoje à noite.

Sem compromissos oficiais, sem ninguém olhando. Só a gente.

{npc}'),
('parceiro', 'spontaneous', 'geral', 'Sobre ontem', 'Fiquei pensando na nossa conversa de ontem.

Talvez eu tenha passado do ponto. Podemos conversar com calma hoje?

{npc}'),
('parceiro', 'spontaneous', 'geral', 'Ciúme?', 'Quem era aquela pessoa que não saiu do seu lado no evento?

Não é ciúme… é só curiosidade. Tá bom, é um pouco de ciúme.

{npc}'),
('parceiro', 'spontaneous', 'geral', 'Saudade', 'Você mal chegou e já foi embora de novo.

Sinto sua falta, {jogador}. Até das suas manias.

{npc}'),
('parceiro', 'spontaneous', 'geral', 'Uma surpresa', 'Tenho uma surpresa pra você.

Não adianta perguntar: só conto quando você chegar. 😏

{npc}'),
('parceiro', 'spontaneous', 'geral', 'Nós', 'Pensei muito na gente hoje. Em tudo o que construímos.

Às vezes esqueço de dizer o quanto me orgulho de nós.

{npc}'),
('parceiro', 'spontaneous', 'geral', 'Sua agenda', '{jogador}, você está trabalhando demais.

Há quanto tempo a gente não tem um fim de semana só nosso?

{npc}'),
('parceiro', 'spontaneous', 'geral', 'Ouvi umas coisas', 'Andam falando de nós por aí.

Não ligo pra fofoca… mas prefiro ouvir de você se houver algo que eu precise saber.

{npc}'),
('parceiro', 'spontaneous', 'geral', 'Lembra?', 'Hoje passei pelo lugar onde a gente se conheceu.

Ainda lembro do que você estava vestindo. Bobagem, eu sei. ❤️

{npc}'),
('parceiro', 'spontaneous', 'geral', 'As crianças', 'As crianças perguntaram de você no jantar.

Eu disse que você estava ocupado(a) salvando o mundo. Volta logo pra provar.

{npc}'),
('parceiro', 'spontaneous', 'geral', 'Uma decisão', 'Precisamos decidir juntos aquele assunto que a gente vem adiando.

Não quero decidir sem você.

{npc}'),
('parceiro', 'reply', 'pergunta', '', 'Você me conhece, {jogador}. Já sabe a resposta.

Mas, se precisa ouvir: sim.

{npc}'),
('parceiro', 'reply', 'pergunta', '', 'Hmm… depende.

Me pergunta de novo hoje à noite, olhando nos meus olhos.

{npc}'),
('parceiro', 'reply', 'geral', '', 'Li sua mensagem três vezes.

Você escreve como fala — e eu adoro isso.

{npc}'),
('parceiro', 'reply', 'geral', '', 'Anotado, meu bem.

A gente resolve isso junto, como sempre.

{npc}'),
('parceiro', 'reply', 'geral', '', 'Às vezes acho que você esquece que eu estou do seu lado, {jogador}.

Estou. Sempre.

{npc}'),
('parceiro', 'reply', 'saudacao', '', 'Estou bem, amor. Com saudade, mas bem.

Que horas você volta pra casa?

{npc}'),
('parceiro', 'reply', 'preocupacao', '', '{jogador}, você está me assustando. Onde você está?

Não faça nada sozinho(a). Estou indo.

{npc}'),
('parceiro', 'reply', 'afeto', '', 'Você ainda me faz sorrir como no primeiro dia.

Te amo, {jogador}. ❤️

{npc}'),
('parceiro', 'reply', 'convite', '', 'Aceito.

Mas só se você prometer desligar o resto do mundo por uma noite.

{npc}'),
('parceiro', 'reply', 'desculpa', '', 'Eu te perdoo, {jogador}.

Só não me faça passar por isso de novo, tá?

{npc}'),
('parceiro', 'reply', 'pedido', '', 'Já está resolvido.

Você nem precisava pedir, meu amor.

{npc}');

-- ------------------------------------------------- romance / caso secreto
insert into public.npc_templates (relation_kind, purpose, topic, subject, body) values
('romance', 'spontaneous', 'geral', 'Não consigo parar de pensar', 'Não consigo parar de pensar naquela noite, {jogador}.

Você também pensa? Seja sincero(a).

{npc}'),
('romance', 'spontaneous', 'geral', 'Cuidado', 'Acho que alguém desconfia de nós.

Precisamos ser mais discretos por um tempo. Isso está me matando.

{npc}'),
('romance', 'spontaneous', 'geral', 'Hoje?', 'Mesmo lugar, mesma hora?

Ninguém precisa saber. 🤫

{npc}'),
('romance', 'spontaneous', 'geral', 'Te vi hoje', 'Te vi hoje de longe.

Fingir que não te conheço está ficando cada vez mais difícil.

{npc}'),
('romance', 'spontaneous', 'geral', 'Até quando?', 'Até quando a gente vai viver escondido, {jogador}?

Não é cobrança. É só cansaço.

{npc}'),
('romance', 'spontaneous', 'geral', 'Apague depois de ler', 'Sonhei com você. Só isso.

Apague este e-mail depois de ler.

{npc}'),
('romance', 'spontaneous', 'geral', 'Você viu o Twixer?', 'Viu o que estão dizendo de nós no Twixer?

Rimos disso juntos… ou devíamos estar com medo?

{npc}'),
('romance', 'reply', 'geral', '', 'Li sua mensagem escondido, com o coração na boca.

Você é perigoso(a) para mim, {jogador}.

{npc}'),
('romance', 'reply', 'geral', '', 'Não diga isso por escrito. Diga pessoalmente. 🤫

{npc}'),
('romance', 'reply', 'geral', '', 'Cada mensagem sua é um risco que eu aceito correr.

{npc}'),
('romance', 'reply', 'saudacao', '', 'Estou bem agora que você escreveu.

Ninguém pode saber o quanto isso me faz bem.

{npc}'),
('romance', 'reply', 'pergunta', '', 'Você sabe a resposta, {jogador}.

Só tem medo de ouvir.

{npc}'),
('romance', 'reply', 'pedido', '', 'Para você, eu arrisco.

Mas que fique só entre nós.

{npc}'),
('romance', 'reply', 'convite', '', 'Eu vou.

Mas chegamos separados e saímos separados. Como sempre.

{npc}'),
('romance', 'reply', 'desculpa', '', 'Não precisa pedir desculpas.

A culpa é da situação, não sua.

{npc}'),
('romance', 'reply', 'preocupacao', '', 'O que houve? Se precisar, eu largo tudo e vou até você.

Que se danem as aparências.

{npc}'),
('romance', 'reply', 'afeto', '', 'Eu também, {jogador}.

Mais do que deveria. Mais do que posso.

{npc}');
