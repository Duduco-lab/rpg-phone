import {
  CalendarDays,
  Contact,
  Image,
  Mail,
  MessageCircle,
  Phone,
  Settings,
  type LucideIcon,
} from 'lucide-react';

export type AppId = 'email' | 'contacts' | 'phone' | 'messages' | 'gallery' | 'calendar' | 'settings';

export type AppStatus = 'available' | 'planned';

export interface AppDefinition {
  id: AppId;
  name: string;
  icon: LucideIcon;
  /** Gradiente do ícone. */
  background: string;
  status: AppStatus;
  /** Para apps planejados: o que o app fará quando for implementado. */
  plannedFeatures?: string[];
}

/** Registro central de aplicativos do telefone. */
export const APPS: Record<AppId, AppDefinition> = {
  email: {
    id: 'email',
    name: 'E-mail',
    icon: Mail,
    background: 'linear-gradient(145deg, #ff6a55 0%, #e5304f 100%)',
    status: 'available',
  },
  contacts: {
    id: 'contacts',
    name: 'Contatos',
    icon: Contact,
    background: 'linear-gradient(145deg, #a3acb9 0%, #6b7584 100%)',
    status: 'available',
  },
  phone: {
    id: 'phone',
    name: 'Telefone',
    icon: Phone,
    background: 'linear-gradient(145deg, #5ee37b 0%, #1fb350 100%)',
    status: 'planned',
    plannedFeatures: [
      'Discagem para os números fictícios dos personagens',
      'Histórico de chamadas',
      'Integração com a agenda de contatos',
    ],
  },
  messages: {
    id: 'messages',
    name: 'Mensagens',
    icon: MessageCircle,
    background: 'linear-gradient(145deg, #4fc3ff 0%, #1d7cf2 100%)',
    status: 'planned',
    plannedFeatures: ['Conversas instantâneas entre personagens', 'Grupos', 'Atualização em tempo real'],
  },
  gallery: {
    id: 'gallery',
    name: 'Galeria',
    icon: Image,
    background: 'linear-gradient(145deg, #ffd25e 0%, #ff8a3d 55%, #f0477b 100%)',
    status: 'planned',
    plannedFeatures: ['Álbum de imagens do personagem', 'Envio de imagens como anexo de e-mail'],
  },
  calendar: {
    id: 'calendar',
    name: 'Calendário',
    icon: CalendarDays,
    background: 'linear-gradient(145deg, #ffffff 0%, #e9ecf2 100%)',
    status: 'planned',
    plannedFeatures: ['Agenda do personagem', 'Eventos da campanha definidos pelo mestre', 'Lembretes'],
  },
  settings: {
    id: 'settings',
    name: 'Ajustes',
    icon: Settings,
    background: 'linear-gradient(145deg, #8e96a3 0%, #4c535e 100%)',
    status: 'available',
  },
};

export const HOME_GRID: AppId[] = ['gallery', 'calendar', 'settings'];
export const DOCK: AppId[] = ['phone', 'messages', 'email', 'contacts'];
