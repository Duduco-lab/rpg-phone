# Publicação: GitHub Pages + Discord Activity

O app é só front-end (arquivos estáticos). O banco e o login ficam no Supabase.
Cada jogador cria a conta **dentro do app** — não há login pelo Discord.

## 1. GitHub Pages

1. Crie um repositório **público** no GitHub (ex.: `rpg-phone`) — vazio, sem README.
2. Envie o código (feito pelo Claude neste projeto: `git push`).
3. No repositório: **Settings → Pages → Build and deployment → Source: GitHub Actions**.
4. A cada envio para `main`, o workflow `.github/workflows/deploy.yml` publica em
   `https://SEU-USUARIO.github.io/rpg-phone/`.

O workflow só contém valores **públicos** (URL do Supabase e chave publishable).
Segredos nunca vão para o repositório.

## 2. Aplicação no Discord

1. <https://discord.com/developers/applications> → **New Application** → "RPG Phone".
2. O **Application ID** (público) fica em `VITE_DISCORD_CLIENT_ID` no workflow
   `.github/workflows/deploy.yml` — atual: `1567739574522871808`.
3. **Activities → Settings → Enable Activities**.
4. **Activities → URL Mappings**:

   | Prefix | Target |
   | --- | --- |
   | `/` | `SEU-USUARIO.github.io/rpg-phone` |
   | `/supabase` | `jggjelbdjhamnpqgclmk.supabase.co` |

5. **Installation**: marque *Guild Install*; use o link de instalação para adicionar o app ao servidor.

## 3. No servidor

- A Activity abre pelo botão de Activities (foguete) em canais de voz, texto ou DMs.
- Para limitar a um canal: desative **Usar Atividades** para @everyone no servidor e ative só no canal desejado.

## Supabase

- **Authentication → URL Configuration → Site URL**: `https://SEU-USUARIO.github.io/rpg-phone/`
  (usado em e-mails de recuperação de senha, se forem ativados).
