/**
 * Integração com a Discord Activity.
 *
 * O RPG Phone NÃO usa a conta do Discord para login: cada jogador cria a
 * conta dentro do próprio app. Do Discord usamos apenas:
 *  - o "aperto de mão" do Embedded App SDK (obrigatório para a Activity abrir);
 *  - o proxy de URLs, porque dentro do Discord o app só acessa outros domínios
 *    pelos mapeamentos cadastrados no Developer Portal (Activities → URL Mappings).
 *
 * O SDK é carregado sob demanda: no navegador comum ele nem é baixado.
 */

/**
 * ID da aplicação do Discord. O Discord abre a Activity em <ID>.discordsays.com,
 * então o mesmo site serve qualquer aplicação; a variável de ambiente é só reserva.
 */
function resolveClientId(): string | undefined {
  const fromHost = /^(\d{15,25})\.discordsays\.com$/.exec(window.location.hostname)?.[1];
  return fromHost ?? (import.meta.env.VITE_DISCORD_CLIENT_ID as string | undefined);
}

/** O Discord abre a Activity com `frame_id` na URL. */
export function isInDiscord(): boolean {
  return new URLSearchParams(window.location.search).has('frame_id');
}

/**
 * Prepara o app dentro do Discord: redireciona o Supabase (HTTP e WebSocket)
 * pelo proxy e conclui o aperto de mão com o cliente do Discord.
 * Deve rodar antes de criar o cliente do Supabase.
 */
export async function setupDiscord(supabaseUrl: string | undefined): Promise<void> {
  if (!isInDiscord()) return;
  const { DiscordSDK, patchUrlMappings } = await import('@discord/embedded-app-sdk');

  if (supabaseUrl) {
    const host = new URL(supabaseUrl).host;
    patchUrlMappings([{ prefix: '/supabase', target: host }], { patchFetch: true, patchWebSocket: true, patchXhr: true });
  }

  const clientId = resolveClientId();
  if (!clientId) {
    console.warn('ID da aplicação do Discord não encontrado: a Activity pode não concluir a inicialização.');
    return;
  }
  const sdk = new DiscordSDK(clientId);
  await sdk.ready();
}
