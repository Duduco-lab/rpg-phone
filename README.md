# RPG Phone

Smartphone virtual para RPG/roleplay, pensado para rodar como Discord Activity.
Cada personagem tem seu próprio aparelho e um endereço `@rpgphone.app`; o principal meio de
comunicação é um cliente de e-mail fictício (sem Gmail/Google reais).

## Estado atual — Fase 1 (interface com dados demonstrativos)

- Moldura de smartphone com câmera, botões laterais, barra de status (hora real) e indicador de início.
- Tela inicial com relógio, widget de e-mail, grade de apps e dock; papel de parede e tema personalizáveis.
- App de E-mail: Entrada, Importantes, Enviados, Rascunhos, Arquivados, Lixeira; conversas agrupadas;
  leitura, responder / responder a todos / encaminhar, arquivar, excluir, restaurar, excluir para sempre,
  marcar como importante / não lida; composição com chips de destinatário e sugestões de personagens,
  salvar rascunho e descartar; busca por remetente, destinatário, assunto ou conteúdo; notificações.
- Contatos: diretório de personagens com busca e atalho para escrever e-mail.
- Ajustes: perfil, papel de parede (predefinidos ou imagem própria), tema claro/escuro/automático.
- Telefone, Mensagens, Galeria e Calendário: telas "Em desenvolvimento" (sem funções falsas).

> **Atenção:** os dados são fictícios e ficam **somente em memória** — recarregar a página restaura o
> estado inicial. Persistência real chega na Fase 2 (Supabase).

## Como executar

Requer Node.js 20.19+.

```bash
npm install
```

```bash
npm run dev
```

Abra http://localhost:5173. Outros comandos: `npm run build` (typecheck + build), `npm run typecheck`.

Use o painel **Modo demonstração** (lateral, ou botão "Demo" em telas estreitas) para trocar o personagem
que está usando o telefone e simular a chegada de e-mails.

## Modo online (Supabase)

Com o Supabase configurado ([docs/SUPABASE_SETUP.md](docs/SUPABASE_SETUP.md)):

- Login de jogador → criação ou escolha de personagem (e-mail `@rpgphone.app` e telefone gerados).
- **Círculo** do personagem (Contatos → Círculo): família, amigos, colegas… com relação livre
  ("irmão", "marido") e tipo de vínculo. Quem não é jogador vira **NPC** que responde e manda
  e-mails espontâneos de acordo com o vínculo.
- Cada NPC tem um **código de convite**: outro jogador pode assumi-lo mantendo o histórico.
- E-mails entre jogadores em **tempo real**, persistentes e protegidos por RLS.

## Documentação

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — organização do código e decisões arquiteturais.
- [docs/SUPABASE_SETUP.md](docs/SUPABASE_SETUP.md) — como criar e conectar o banco.
