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

const CLIENT_ID = import.meta.env.VITE_DISCORD_CLIENT_ID as string | undefined;

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

  if (!CLIENT_ID) {
    console.warn('VITE_DISCORD_CLIENT_ID ausente: a Activity pode não concluir a inicialização.');
    return;
  }
  const sdk = new DiscordSDK(CLIENT_ID);
  await sdk.ready();
}
