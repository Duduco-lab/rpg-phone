import type { AppDefinition } from './apps';

interface Props {
  app: AppDefinition;
  badge?: number;
  showLabel?: boolean;
  onOpen: () => void;
}

export function AppIcon({ app, badge = 0, showLabel = true, onOpen }: Props) {
  const Icon = app.icon;
  const darkGlyph = app.id === 'calendar';
  return (
    <button
      type="button"
      className="app-icon"
      onClick={onOpen}
      aria-label={badge > 0 ? `${app.name}, ${badge} não lidas` : app.name}
    >
      <span className="app-icon-tile" style={{ background: app.background }}>
        <Icon size={30} strokeWidth={1.9} color={darkGlyph ? '#e5304f' : '#fff'} />
        {badge > 0 && <span className="app-badge">{badge > 99 ? '99+' : badge}</span>}
      </span>
      {showLabel && <span className="app-icon-label">{app.name}</span>}
    </button>
  );
}
