-- O app de rede social passou a se chamar Twixer: atualiza os e-mails de NPC que o mencionam.
update public.npc_templates set body = replace(body, 'no Rumor', 'no Twixer') where body like '%no Rumor%';
update public.npc_templates set subject = replace(subject, 'Rumor', 'Twixer') where subject like '%Rumor%';
