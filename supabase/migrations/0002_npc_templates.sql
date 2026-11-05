-- =====================================================================
-- Modelos de e-mail dos NPCs
-- Marcadores: {jogador} = primeiro nome do personagem do jogador,
--             {npc} = primeiro nome do NPC, {relacao} = relação cadastrada (ex.: "irmão").
-- relation_kind = o que o NPC É para o jogador.
-- Para adicionar mais modelos, basta inserir novas linhas nesta tabela.
-- =====================================================================

insert into public.npc_templates (relation_kind, purpose, subject, body) values
-- ------------------------------------------------------------ pai/mãe
('pai_mae', 'spontaneous', 'Saudades', 'Oi, {jogador}.

Faz dias que você não dá notícias. Está tudo bem por aí? Está se alimentando direito?

Liga quando puder. Um beijo,
{npc}'),
('pai_mae', 'spontaneous', 'Almoço de domingo', '{jogador},

Vou fazer aquele almoço no domingo. Conto com você, sem desculpas desta vez.

Traga sobremesa se puder.
{npc}'),
('pai_mae', 'spontaneous', 'Fiquei preocupado(a)', '{jogador}, sonhei com você esta noite e acordei com o coração apertado.

Me responde só pra eu saber que está tudo bem?

{npc}'),
('pai_mae', 'reply', '', 'Que bom ter notícias suas, {jogador}!

Fico mais tranquilo(a) sabendo disso. Mas cuide-se, viu? E não suma de novo.

Com carinho,
{npc}'),
('pai_mae', 'reply', '', '{jogador},

Li sua mensagem com calma. Você sabe que pode contar comigo pra qualquer coisa, não sabe?

Venha me visitar esta semana.
{npc}'),
('pai_mae', 'reply', '', 'Recebi, {jogador}. Vou pensar no que você disse.

Mas não pense que me engana — conheço essa sua forma de escrever quando está escondendo alguma coisa.

{npc}'),

-- -------------------------------------------------------------- filho
('filho', 'spontaneous', 'Preciso de uma ajuda', 'Oi, {jogador}!

Tudo bem? Então... será que você poderia me ajudar com uma coisinha? Prometo que explico tudo pessoalmente.

{npc}'),
('filho', 'spontaneous', 'Novidade!', '{jogador}, tenho uma novidade e queria que você fosse o primeiro a saber.

Me liga quando tiver um tempinho? Não é nada grave, prometo.

{npc}'),
('filho', 'spontaneous', 'Saudade', 'Só passando pra dizer que estou com saudade.

Quando a gente se vê?

{npc}'),
('filho', 'reply', '', 'Valeu, {jogador}! Você sempre sabe o que dizer.

{npc}'),
('filho', 'reply', '', 'Tá bom, tá bom... vou fazer do jeito que você falou.

Mas depois não diga que eu não avisei!

{npc}'),
('filho', 'reply', '', 'Recebi! Depois a gente conversa melhor sobre isso, ok?

Beijo,
{npc}'),

-- -------------------------------------------------------------- irmão
('irmao', 'spontaneous', 'Você viu isso?', 'E aí, {jogador}.

Você não vai acreditar no que aconteceu hoje. Me liga, é coisa demais pra escrever.

{npc}'),
('irmao', 'spontaneous', 'Sobre a família', '{jogador},

A família anda perguntando de você. Inventei uma desculpa, mas não vou conseguir te cobrir pra sempre.

Aparece.
{npc}'),
('irmao', 'spontaneous', 'Me deve uma', 'Lembra daquele favor que eu te fiz? Pois é. Chegou a hora de cobrar.

Nada demais. Por enquanto.

{npc}'),
('irmao', 'spontaneous', 'Lembra disso?', 'Achei umas fotos antigas nossas arrumando o armário. Que cabelo era aquele, {jogador}?

Saudade dessa época.
{npc}'),
('irmao', 'reply', '', 'Haha, típico de você, {jogador}.

Tá, conta comigo. Mas fica entre nós dois, combinado?

{npc}'),
('irmao', 'reply', '', 'Sério isso? Às vezes eu não sei se você está falando sério ou me provocando.

Me conta direito depois.
{npc}'),
('irmao', 'reply', '', 'Recebido. Vou ver o que consigo fazer.

Mas você vai me dever uma, {jogador}.

{npc}'),

-- ----------------------------------------------------------- parceiro
('parceiro', 'spontaneous', 'Pensando em você', '{jogador},

Só queria dizer que estou pensando em você. O dia ficou mais leve só de lembrar.

{npc}'),
('parceiro', 'spontaneous', 'Hoje à noite?', 'Ei, você.

Que tal a gente sair hoje? Só nós dois. Eu escolho o lugar.

{npc}'),
('parceiro', 'spontaneous', 'Precisamos conversar', '{jogador},

Tem uma coisa me incomodando e prefiro falar pessoalmente. Hoje, quando você chegar?

{npc}'),
('parceiro', 'spontaneous', 'Você esqueceu...', '...a sua chave aqui de novo.

Vou guardar como refém até você vir buscar. 😉
{npc}'),
('parceiro', 'reply', '', 'Adorei receber isso, {jogador}.

Mal posso esperar pra te ver.
{npc}'),
('parceiro', 'reply', '', 'Tudo bem. Eu confio em você, sabe disso.

Só não me deixa no escuro, tá?

{npc}'),
('parceiro', 'reply', '', 'Li tudo. Vamos conversar melhor em casa.

Te amo.
{npc}'),

-- ------------------------------------------------------------------ ex
('ex', 'spontaneous', 'Oi', 'Oi, {jogador}.

Sei que faz tempo. Só queria saber como você está.

Não precisa responder se não quiser.
{npc}'),
('ex', 'spontaneous', 'Suas coisas', '{jogador},

Ainda tenho algumas coisas suas aqui. Quer que eu mande entregar ou prefere buscar?

{npc}'),
('ex', 'spontaneous', 'Vi você ontem', 'Acho que vi você ontem, do outro lado da rua. Ou talvez fosse só alguém parecido.

Enfim. Espero que esteja bem.
{npc}'),
('ex', 'reply', '', 'Não esperava resposta, sinceramente.

Fico feliz que você esteja bem, {jogador}.
{npc}'),
('ex', 'reply', '', 'Você continua igual, {jogador}. Pra bem e pra mal.

{npc}'),
('ex', 'reply', '', 'Ok. Entendi o recado.

{npc}'),

-- --------------------------------------------------------------- amigo
('amigo', 'spontaneous', 'Bora sair?', 'E aí, {jogador}!

Faz séculos que a gente não sai. Esse fim de semana? Sem desculpas.

{npc}'),
('amigo', 'spontaneous', 'Fofoca', 'Você está sentado(a)? Porque eu descobri uma coisa que vai te deixar de queixo caído.

Me liga!
{npc}'),
('amigo', 'spontaneous', 'Tudo certo?', '{jogador}, você anda sumido(a). Está tudo certo mesmo?

Se precisar de qualquer coisa, sabe onde me achar.
{npc}'),
('amigo', 'spontaneous', 'Lembrei de você', 'Passei na frente daquele bar onde a gente costumava ir e lembrei de você.

Ainda está devendo uma rodada, hein.
{npc}'),
('amigo', 'reply', '', 'Hahaha, só você mesmo, {jogador}.

Conta comigo!
{npc}'),
('amigo', 'reply', '', 'Fechado! Depois me passa os detalhes.

{npc}'),
('amigo', 'reply', '', 'Opa, vi agora. Vamos falar disso pessoalmente que é melhor.

Abraço,
{npc}'),

-- -------------------------------------------------------------- colega
('colega', 'spontaneous', 'Reunião de amanhã', 'Olá, {jogador}.

Só lembrando da reunião de amanhã. Você conseguiu revisar o material?

Abs,
{npc}'),
('colega', 'spontaneous', 'Café?', '{jogador}, vou descer pra tomar um café em 10 minutos. Vem?

{npc}'),
('colega', 'spontaneous', 'Você ficou sabendo?', 'Estão dizendo pelos corredores que vai ter mudança na equipe. Você ouviu alguma coisa?

{npc}'),
('colega', 'reply', '', 'Perfeito, obrigado(a), {jogador}. Vou seguir por aqui.

{npc}'),
('colega', 'reply', '', 'Entendi. Vou verificar e te retorno assim que possível.

Abs,
{npc}'),
('colega', 'reply', '', 'Combinado! Falamos melhor amanhã.

{npc}'),

-- --------------------------------------------------------------- chefe
('chefe', 'spontaneous', 'Na minha sala', '{jogador},

Passe na minha sala assim que puder.

{npc}'),
('chefe', 'spontaneous', 'Prazo', '{jogador},

Preciso daquilo até o fim do dia. Sem atrasos desta vez.

{npc}'),
('chefe', 'spontaneous', 'Bom trabalho', '{jogador},

Não costumo dizer isso, mas o último trabalho ficou bom. Continue assim.

{npc}'),
('chefe', 'reply', '', 'Recebido. Vou analisar.

{npc}'),
('chefe', 'reply', '', 'Certo, {jogador}. Mas espero resultados, não explicações.

{npc}'),
('chefe', 'reply', '', 'Ok. Conversamos amanhã cedo.

{npc}'),

-- ---------------------------------------------------------------- rival
('rival', 'spontaneous', 'Parabéns...', '{jogador},

Vi o que você fez. Parabéns. Aproveite enquanto dura.

{npc}'),
('rival', 'spontaneous', 'Um aviso', 'Só um aviso amigável, {jogador}: fique longe dos meus assuntos.

{npc}'),
('rival', 'spontaneous', 'Proposta', 'Talvez a gente tenha mais a ganhar trabalhando juntos do que um contra o outro.

Pense nisso. Por enquanto.
{npc}'),
('rival', 'reply', '', 'Engraçado você dizer isso, {jogador}.

Veremos.
{npc}'),
('rival', 'reply', '', 'Não esperava menos de você.

{npc}'),
('rival', 'reply', '', 'Anotado. E não pense que eu esqueço.

{npc}'),

-- -------------------------------------------------------------- parente
('parente', 'spontaneous', 'Notícias da família', 'Oi, {jogador}!

Aqui está todo mundo bem. Sua tia mandou lembranças e perguntou quando você aparece.

Abraços,
{npc}'),
('parente', 'spontaneous', 'Festa de família', '{jogador},

Vamos fazer uma reunião da família no mês que vem. Você vem, né? Todos estão perguntando.

{npc}'),
('parente', 'spontaneous', 'Lembrei de você', 'Encontrei uma foto sua de criança aqui em casa. Que fofura!

Beijos,
{npc}'),
('parente', 'reply', '', 'Que bom saber, {jogador}! Vou passar o recado pra todo mundo.

{npc}'),
('parente', 'reply', '', 'Obrigado(a) pela resposta! Fica com Deus.

{npc}'),
('parente', 'reply', '', 'Recebi! Depois te ligo pra gente conversar melhor.

{npc}'),

-- ---------------------------------------------------------------- outro
('outro', 'spontaneous', 'Olá', 'Olá, {jogador}.

Tudo bem? Faz tempo que não nos falamos. Lembrei de você hoje.

{npc}'),
('outro', 'spontaneous', 'Uma pergunta', '{jogador}, posso te fazer uma pergunta? Prefiro pessoalmente.

{npc}'),
('outro', 'spontaneous', 'Notícias', 'Oi, {jogador}. Fiquei sabendo de umas coisas que talvez te interessem.

Me procura quando puder.
{npc}'),
('outro', 'reply', '', 'Obrigado pela mensagem, {jogador}.

Respondo com calma em breve.
{npc}'),
('outro', 'reply', '', 'Entendi. Vamos conversando.

{npc}'),
('outro', 'reply', '', 'Recebido! Depois falamos.

{npc}');
