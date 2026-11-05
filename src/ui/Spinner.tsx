export function Spinner({ size = 28, label = 'Carregando' }: { size?: number; label?: string }) {
  return <span className="spinner" style={{ width: size, height: size }} role="status" aria-label={label} />;
}

export function CenteredSpinner({ label }: { label?: string }) {
  return (
    <div className="centered-state">
      <Spinner label={label} />
    </div>
  );
}
