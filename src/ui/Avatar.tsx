import { initials } from '../lib/format';

interface Props {
  name: string;
  color: string;
  imageUrl?: string | null;
  size?: number;
  className?: string;
}

export function Avatar({ name, color, imageUrl, size = 40, className = '' }: Props) {
  const style = { width: size, height: size, fontSize: Math.round(size * 0.4) };
  if (imageUrl) {
    return <img className={`avatar ${className}`} style={style} src={imageUrl} alt="" draggable={false} />;
  }
  return (
    <span className={`avatar ${className}`} style={{ ...style, background: color }} aria-hidden="true">
      {initials(name)}
    </span>
  );
}
