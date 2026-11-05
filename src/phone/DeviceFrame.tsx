import { useLayoutEffect, useRef, useState, type ReactNode } from 'react';

/** Dimensões lógicas da tela (pontos), semelhantes às de um smartphone moderno. */
export const SCREEN_W = 390;
export const SCREEN_H = 844;
const BEZEL = 12;
const FRAME_W = SCREEN_W + BEZEL * 2;
const FRAME_H = SCREEN_H + BEZEL * 2;
/** Abaixo desta largura (ex.: celular real), a tela ocupa a janela inteira sem moldura. */
const BARE_BREAKPOINT = 500;
const STAGE_PADDING = 24;

interface Fit {
  scale: number;
  bare: boolean;
}

function useFit(ref: React.RefObject<HTMLDivElement | null>): Fit {
  const [fit, setFit] = useState<Fit>({ scale: 1, bare: false });
  useLayoutEffect(() => {
    const el = ref.current;
    if (!el) return;
    const measure = () => {
      const { width, height } = el.getBoundingClientRect();
      if (width < BARE_BREAKPOINT) {
        setFit({ scale: 1, bare: true });
        return;
      }
      const scale = Math.min(1, (width - STAGE_PADDING * 2) / FRAME_W, (height - STAGE_PADDING * 2) / FRAME_H);
      setFit({ scale: Math.max(0.35, scale), bare: false });
    };
    measure();
    const ro = new ResizeObserver(measure);
    ro.observe(el);
    return () => ro.disconnect();
  }, [ref]);
  return fit;
}

/**
 * Moldura física do aparelho. A tela é renderizada em tamanho lógico fixo e
 * escalada para caber na janela (inclusive no painel da Discord Activity),
 * preservando proporções e nitidez do layout interno.
 */
export function DeviceFrame({ children }: { children: ReactNode }) {
  const stageRef = useRef<HTMLDivElement>(null);
  const { scale, bare } = useFit(stageRef);

  return (
    <div ref={stageRef} className={`device-stage ${bare ? 'is-bare' : ''}`}>
      {bare ? (
        <div className="device-bare">{children}</div>
      ) : (
        <div className="device-slot" style={{ width: FRAME_W * scale, height: FRAME_H * scale }}>
          <div
            className="device"
            style={{ width: FRAME_W, height: FRAME_H, transform: `scale(${scale})` }}
          >
            <span className="device-btn device-btn--action" aria-hidden="true" />
            <span className="device-btn device-btn--vol-up" aria-hidden="true" />
            <span className="device-btn device-btn--vol-down" aria-hidden="true" />
            <span className="device-btn device-btn--power" aria-hidden="true" />
            <div className="device-screen" style={{ width: SCREEN_W, height: SCREEN_H }}>
              {children}
              <span className="device-camera" aria-hidden="true" />
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
