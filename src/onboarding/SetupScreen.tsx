import type { ReactNode } from 'react';
import { DeviceFrame } from '../phone/DeviceFrame';
import { WALLPAPERS } from '../phone/preferences';
import { StatusBar } from '../phone/StatusBar';
import './onboarding.css';

/** Tela de configuração do aparelho (login, escolha de personagem) dentro da moldura. */
export function SetupScreen({ children }: { children: ReactNode }) {
  return (
    <DeviceFrame>
      <div className="screen" data-theme="light">
        <div className="wallpaper" style={{ background: WALLPAPERS[0]!.css }} />
        <div className="setup">
          <div className="setup-card">{children}</div>
        </div>
        <StatusBar tone="light" />
      </div>
    </DeviceFrame>
  );
}
