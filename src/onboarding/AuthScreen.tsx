import { Smartphone } from 'lucide-react';
import { useState } from 'react';
import { errorMessage, type AccountClient } from '../services/backend';
import { Spinner } from '../ui/Spinner';
import '../circle/circle.css';

type Mode = 'signin' | 'signup';

/**
 * Login provisório por e-mail e senha (Supabase Auth).
 * Na Fase 6 o jogador será identificado pelo Discord.
 */
export function AuthScreen({ account }: { account: AccountClient }) {
  const [mode, setMode] = useState<Mode>('signin');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [info, setInfo] = useState<string | null>(null);

  const submit = async () => {
    setError(null);
    setInfo(null);
    if (!email.trim() || !password) return setError('Preencha e-mail e senha.');
    if (mode === 'signup' && password.length < 6) return setError('A senha precisa ter pelo menos 6 caracteres.');
    setBusy(true);
    try {
      if (mode === 'signin') {
        await account.signIn(email, password);
      } else {
        const active = await account.signUp(email, password, name);
        if (!active) {
          setInfo('Conta criada! Confirme pelo link enviado ao seu e-mail e depois entre.');
          setMode('signin');
        }
      }
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setBusy(false);
    }
  };

  return (
    <form
      className="setup-form"
      onSubmit={(e) => {
        e.preventDefault();
        void submit();
      }}
    >
      <div className="setup-logo">
        <Smartphone size={28} />
      </div>
      <h1>RPG Phone</h1>
      <p className="setup-sub">
        {mode === 'signin' ? 'Entre na sua conta de jogador.' : 'Crie sua conta de jogador.'}
      </p>

      {mode === 'signup' && (
        <label className="field">
          <span>Seu nome (jogador)</span>
          <input value={name} onChange={(e) => setName(e.target.value)} maxLength={60} autoComplete="nickname" />
        </label>
      )}
      <label className="field">
        <span>E-mail</span>
        <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} autoComplete="email" />
      </label>
      <label className="field">
        <span>Senha</span>
        <input
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          autoComplete={mode === 'signin' ? 'current-password' : 'new-password'}
        />
      </label>

      {error && (
        <p className="form-error" role="alert">
          {error}
        </p>
      )}
      {info && <p className="setup-info">{info}</p>}

      <button type="submit" className="btn-primary setup-submit" disabled={busy}>
        {busy && <Spinner size={16} />} {mode === 'signin' ? 'Entrar' : 'Criar conta'}
      </button>
      <button
        type="button"
        className="btn-ghost"
        onClick={() => {
          setMode(mode === 'signin' ? 'signup' : 'signin');
          setError(null);
        }}
      >
        {mode === 'signin' ? 'Não tenho conta' : 'Já tenho conta'}
      </button>
      <p className="setup-foot">Esta conta identifica você, jogador. Seu e-mail real nunca aparece no jogo.</p>
    </form>
  );
}
