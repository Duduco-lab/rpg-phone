import type { CharacterProfile } from '../../domain/character';

/**
 * DADOS DEMONSTRATIVOS — Fase 1.
 * Personagens fictícios usados apenas para demonstrar a interface.
 * Vivem em memória e são descartados ao recarregar a página.
 */
export const DEMO_CHARACTERS: CharacterProfile[] = [
  {
    id: 'demo-helena',
    kind: 'player',
    firstName: 'Helena',
    lastName: 'Vasconcelos',
    email: 'helena.vasconcelos@rpgphone.app',
    phoneNumber: '+55 (21) 97412-0381',
    description: 'Detetive particular em Porto Sereno. Desconfia de todos — principalmente de quem parece inocente.',
    avatarUrl: null,
    avatarColor: '#7b5cd6',
    active: true,
  },
  {
    id: 'demo-rafael',
    kind: 'player',
    firstName: 'Rafael',
    lastName: 'Moreau',
    email: 'rafael.moreau@rpgphone.app',
    phoneNumber: '+55 (21) 98823-1147',
    description: 'Jornalista investigativo da Gazeta de Porto Sereno. Sempre com uma câmera e uma pergunta a mais.',
    avatarUrl: null,
    avatarColor: '#d1683c',
    active: true,
  },
  {
    id: 'demo-iris',
    kind: 'player',
    firstName: 'Íris',
    lastName: 'Tanaka',
    email: 'iris.tanaka@rpgphone.app',
    phoneNumber: '+55 (21) 99104-5520',
    description: 'Analista de sistemas freelancer. Encontra qualquer coisa em qualquer servidor — por um preço.',
    avatarUrl: null,
    avatarColor: '#1f9b8a',
    active: true,
  },
  {
    id: 'demo-augusto',
    kind: 'player',
    firstName: 'Augusto',
    lastName: 'Brandão',
    email: 'augusto.brandao@rpgphone.app',
    phoneNumber: '+55 (21) 97330-8862',
    description: 'Médico legista do Instituto Médico de Porto Sereno. Metódico, discreto e insone.',
    avatarUrl: null,
    avatarColor: '#3a78c9',
    active: true,
  },
  {
    id: 'demo-clara',
    kind: 'player',
    firstName: 'Clara',
    lastName: 'Lins',
    email: 'clara.lins@rpgphone.app',
    phoneNumber: '+55 (21) 99977-0012',
    description: 'Herdeira da Fundação Lins. Encantadora em público, implacável nos negócios.',
    avatarUrl: null,
    avatarColor: '#c2457a',
    active: true,
  },
  {
    id: 'demo-duarte',
    kind: 'player',
    firstName: 'Otávio',
    lastName: 'Duarte',
    email: 'otavio.duarte@rpgphone.app',
    phoneNumber: '+55 (21) 98150-4409',
    description: 'Comissário da 3ª Delegacia. Faltam dois anos para a aposentadoria e ele pretende chegar lá.',
    avatarUrl: null,
    avatarColor: '#5f6b7a',
    active: true,
  },
];

export const DEFAULT_DEMO_CHARACTER_ID = 'demo-helena';
