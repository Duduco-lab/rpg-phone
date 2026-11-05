/**
 * DADOS DEMONSTRATIVOS — Fase 1.
 * Conversas fictícias geradas em relação ao horário atual para que a
 * caixa de entrada pareça "viva". Nada aqui é persistido.
 */

export type SeedKey = 'helena' | 'rafael' | 'iris' | 'augusto' | 'clara' | 'duarte';

export interface SeedMessage {
  from: SeedKey;
  to: SeedKey[];
  minutesAgo: number;
  body: string;
  unreadFor?: SeedKey[];
  importantFor?: SeedKey[];
  archivedFor?: SeedKey[];
  trashedFor?: SeedKey[];
}

export interface SeedThread {
  subject: string;
  messages: SeedMessage[];
}

export interface SeedDraft {
  owner: SeedKey;
  to: SeedKey[];
  subject: string;
  body: string;
  minutesAgo: number;
}

export const seedCharacterId = (key: SeedKey): string => `demo-${key}`;

const H = 60;
const D = 24 * H;

export const DEMO_THREADS: SeedThread[] = [
  {
    subject: 'O caso do Farol Velho',
    messages: [
      {
        from: 'duarte',
        to: ['helena'],
        minutesAgo: 95,
        body: 'Vasconcelos,\n\nO corpo encontrado no Farol Velho não é de um pescador, como o jornal anda dizendo. Preciso de alguém de fora da corporação olhando isso. Discretamente.\n\nPasse na delegacia antes das 18h.\n\n— Duarte',
        importantFor: ['helena'],
      },
      {
        from: 'helena',
        to: ['duarte'],
        minutesAgo: 70,
        body: 'Comissário,\n\nEstarei aí às 17h. Quero ver as fotos da cena e a lista de quem tinha a chave do farol.\n\nE o preço de sempre, claro.\n\nH.',
      },
      {
        from: 'duarte',
        to: ['helena'],
        minutesAgo: 12,
        body: 'Mudança de planos. Alguém da imprensa já está farejando. Me encontre no cais, armazém 7, às 21h. Venha sozinha.\n\nApague este e-mail depois de ler.',
        unreadFor: ['helena'],
        importantFor: ['helena'],
      },
    ],
  },
  {
    subject: 'Fotos da noite de sábado',
    messages: [
      {
        from: 'rafael',
        to: ['helena'],
        minutesAgo: 38,
        body: 'Helena,\n\nRevelei o filme de sábado. Tem uma pessoa no fundo da foto 14 que você vai querer ver — casaco vermelho, perto do portão da Fundação Lins.\n\nPosso te mostrar amanhã cedo no café da Rua do Porto?\n\nAbraço,\nRafael',
        unreadFor: ['helena'],
      },
    ],
  },
  {
    subject: 'Resultado da autópsia — confidencial',
    messages: [
      {
        from: 'augusto',
        to: ['helena', 'duarte'],
        minutesAgo: 5 * H,
        body: 'Prezados,\n\nO laudo preliminar aponta afogamento, mas há marcas nos pulsos incompatíveis com uma queda acidental. Também encontrei resíduos de tinta náutica azul sob as unhas.\n\nO relatório oficial sai na sexta. Até lá, isto não existe.\n\nDr. Augusto Brandão\nInstituto Médico de Porto Sereno',
        importantFor: ['helena', 'duarte'],
        unreadFor: ['duarte'],
      },
    ],
  },
  {
    subject: 'Convite: baile de gala da Fundação Lins',
    messages: [
      {
        from: 'clara',
        to: ['helena', 'rafael'],
        minutesAgo: D + 3 * H,
        body: 'Queridos,\n\nÉ com prazer que convido vocês para o baile anual da Fundação Lins, neste sábado, às 20h, no Palacete da Avenida Atlântica.\n\nTraje a rigor. Haverá leilão beneficente — e algumas surpresas.\n\nCom carinho,\nClara Lins',
        unreadFor: ['rafael'],
      },
    ],
  },
  {
    subject: 'Consegui acesso aos registros',
    messages: [
      {
        from: 'iris',
        to: ['helena'],
        minutesAgo: 2 * D + 4 * H,
        body: 'Entrei no sistema da capitania dos portos. Os registros de entrada de embarcações das últimas três semanas estão comigo.\n\nUma delas não aparece em lugar nenhum depois do dia 12.',
      },
      {
        from: 'helena',
        to: ['iris'],
        minutesAgo: 2 * D + 2 * H,
        body: 'Ótimo trabalho. Qual o nome da embarcação? E quem é o proprietário registrado?',
      },
      {
        from: 'iris',
        to: ['helena'],
        minutesAgo: D + 20 * H,
        body: '"Maré Alta". Registrada em nome de uma empresa de fachada — Atlântica Comércio e Representações Ltda.\n\nAdivinha quem é a sócia majoritária? Te conto pessoalmente.',
      },
    ],
  },
  {
    subject: 'Honorários — investigação de outubro',
    messages: [
      {
        from: 'helena',
        to: ['clara'],
        minutesAgo: 4 * D,
        body: 'Sra. Lins,\n\nSegue lembrete sobre os honorários referentes à investigação concluída em outubro. O valor combinado permanece o mesmo.\n\nAtenciosamente,\nHelena Vasconcelos',
        archivedFor: ['helena'],
      },
      {
        from: 'clara',
        to: ['helena'],
        minutesAgo: 3 * D + 6 * H,
        body: 'Helena, querida, o depósito foi feito hoje pela manhã. Foi um prazer, como sempre.\n\nC.',
        archivedFor: ['helena'],
      },
    ],
  },
  {
    subject: 'Pauta da semana — Gazeta de Porto Sereno',
    messages: [
      {
        from: 'rafael',
        to: ['helena', 'iris', 'augusto'],
        minutesAgo: 5 * D,
        body: 'Pessoal, estou fechando a pauta da semana. Se alguém tiver uma dica (anônima, claro), me escreva até quinta.\n\nRafael',
        trashedFor: ['helena'],
      },
    ],
  },
  {
    subject: 'Sobre a Helena',
    messages: [
      {
        from: 'rafael',
        to: ['iris'],
        minutesAgo: 6 * H,
        body: 'Íris, você sabe o que a Helena está investigando? Ela anda evasiva comigo.',
      },
      {
        from: 'iris',
        to: ['rafael'],
        minutesAgo: 4 * H,
        body: 'Sei. E não vou te contar. Pergunta pra ela.',
        unreadFor: ['rafael'],
      },
    ],
  },
];

export const DEMO_DRAFTS: SeedDraft[] = [
  {
    owner: 'helena',
    to: ['iris'],
    subject: 'Pedido urgente',
    body: 'Íris, preciso que você descubra tudo sobre a Atlântica Comércio — sócios, endereços, contas. E',
    minutesAgo: 25,
  },
];

/** Textos usados pela ferramenta "Simular e-mail recebido" do painel de demonstração. */
export const DEMO_INCOMING_TEMPLATES: { subject: string; body: string }[] = [
  {
    subject: 'Você está sendo seguida',
    body: 'Não olhe agora, mas há um carro preto parado na sua rua desde as 19h. Placa parcialmente coberta.\n\nTome cuidado.',
  },
  {
    subject: 'Novidades sobre o Maré Alta',
    body: 'A embarcação foi vista ancorada perto da Ilha do Sino ontem à noite. Sem luzes acesas.',
  },
  {
    subject: 'Reunião amanhã?',
    body: 'Consegue me encontrar amanhã às 10h? Tenho algo que não posso dizer por escrito.',
  },
  {
    subject: 'Um favor',
    body: 'Preciso de um favor, e você me deve um. Me ligue assim que puder.',
  },
];
