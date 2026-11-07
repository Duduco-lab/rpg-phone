import { BadgeCheck, Bird, ChevronLeft, Heart, MessageCircle, Newspaper, Repeat2, RotateCw } from 'lucide-react';
import { Fragment, useCallback, useEffect, useState, type ReactNode } from 'react';
import { countryName } from '../../domain/countries';
import { useNow } from '../../hooks/useNow';
import { colorFromString, initials } from '../../lib/format';
import { usePhone } from '../../phone/PhoneContext';
import { errorMessage, type FeedTab, type SocialFeed, type SocialPost } from '../../services/backend';
import { useSession } from '../../session/SessionContext';
import { CenteredSpinner } from '../../ui/Spinner';
import { ErrorState } from '../../ui/ErrorState';
import { IconButton } from '../../ui/IconButton';
import './rumor.css';

const TABS: { id: FeedTab; label: string }[] = [
  { id: 'para_voce', label: 'Para você' },
  { id: 'noticias', label: 'Notícias' },
];

function relativeTime(iso: string, now: Date): string {
  const s = Math.max(0, (now.getTime() - new Date(iso).getTime()) / 1000);
  if (s < 60) return 'agora';
  if (s < 3600) return `${Math.floor(s / 60)} min`;
  if (s < 86400) return `${Math.floor(s / 3600)} h`;
  return `${Math.floor(s / 86400)} d`;
}

function compact(n: number): string {
  if (n < 1000) return String(n);
  if (n < 1_000_000) return `${(n / 1000).toFixed(n < 10_000 ? 1 : 0).replace('.', ',').replace(',0', '')} mil`;
  return `${(n / 1_000_000).toFixed(1).replace('.', ',')} mi`;
}

/** Destaca #hashtags e @menções. */
function richText(text: string): ReactNode {
  return text.split(/(#[\p{L}\p{N}_]+|@[\w.]+)/u).map((part, i) =>
    /^[#@]/.test(part) ? (
      <span key={i} className="rumor-tag">
        {part}
      </span>
    ) : (
      <Fragment key={i}>{part}</Fragment>
    ),
  );
}

function PostCard({ post, now }: { post: SocialPost; now: Date }) {
  const isPress = post.authorKind === 'imprensa';
  const verified = isPress || post.authorKind === 'fofoca';
  return (
    <article className={`rumor-post ${post.aboutMe ? 'is-about-me' : ''}`}>
      <span
        className={`rumor-avatar ${isPress ? 'is-press' : ''}`}
        style={{ background: isPress ? undefined : colorFromString(post.authorHandle) }}
        aria-hidden="true"
      >
        {isPress ? <Newspaper size={18} /> : initials(post.authorName)}
      </span>
      <div className="rumor-post-main">
        <div className="rumor-post-head">
          <strong>{post.authorName}</strong>
          {verified && <BadgeCheck size={14} className="rumor-verified" aria-label="Conta verificada" />}
          <span className="rumor-handle">@{post.authorHandle}</span>
          <span className="rumor-dot">·</span>
          <span className="rumor-time">{relativeTime(post.createdAt, now)}</span>
        </div>
        <p className="rumor-body">{richText(post.body)}</p>
        <div className="rumor-stats" aria-label="Engajamento">
          <span>
            <MessageCircle size={15} /> {compact(post.replies)}
          </span>
          <span>
            <Repeat2 size={16} /> {compact(post.reposts)}
          </span>
          <span>
            <Heart size={15} /> {compact(post.likes)}
          </span>
        </div>
      </div>
    </article>
  );
}

/** Twixer — a rede social do mundo do jogo. Somente leitura nesta versão. */
export function RumorApp() {
  const { goHome } = usePhone();
  const { backend, activeCharacter } = useSession();
  const now = useNow();
  const [tab, setTab] = useState<FeedTab>('para_voce');
  const [feed, setFeed] = useState<SocialFeed | null>(null);
  const [status, setStatus] = useState<'loading' | 'ready' | 'error'>('loading');
  const [error, setError] = useState<string | null>(null);
  const [refreshing, setRefreshing] = useState(false);

  const load = useCallback(
    async (silent: boolean) => {
      if (!backend.social || !activeCharacter) return;
      if (silent) setRefreshing(true);
      else setStatus('loading');
      try {
        setFeed(await backend.social.feed(activeCharacter.id, tab));
        setStatus('ready');
        setError(null);
      } catch (e) {
        setError(errorMessage(e));
        setStatus('error');
      } finally {
        setRefreshing(false);
      }
    },
    [backend.social, activeCharacter, tab],
  );

  useEffect(() => {
    void load(false);
  }, [load]);

  const country = countryName(feed?.countryCode);

  return (
    <div className="rumor">
      <header className="rumor-header">
        <div className="rumor-bar">
          <IconButton label="Voltar ao início" onClick={goHome}>
            <ChevronLeft size={22} />
          </IconButton>
          <span className="rumor-logo" aria-label="Twixer">
            <Bird size={26} strokeWidth={2.2} />
          </span>
          <IconButton label="Atualizar" onClick={() => void load(true)} disabled={refreshing || status === 'loading'}>
            <RotateCw size={18} className={refreshing ? 'spin' : ''} />
          </IconButton>
        </div>
        <nav className="rumor-tabs" role="tablist">
          {TABS.map((t) => (
            <button
              key={t.id}
              type="button"
              role="tab"
              aria-selected={tab === t.id}
              className={tab === t.id ? 'is-on' : ''}
              onClick={() => setTab(t.id)}
            >
              {t.label}
            </button>
          ))}
        </nav>
      </header>

      <div className="rumor-scroll">
        {status === 'loading' && <CenteredSpinner label="Carregando o Twixer" />}
        {status === 'error' && <ErrorState message={error ?? 'Erro ao carregar o feed.'} onRetry={() => void load(false)} />}
        {status === 'ready' && feed && !feed.countryCode && (
          <div className="rumor-empty">
            <p>
              Defina sua <b>nacionalidade</b> em <b>Ajustes → Editar perfil</b> para começar a aparecer no Twixer e
              receber as notícias do seu país.
            </p>
          </div>
        )}
        {status === 'ready' && feed && feed.countryCode && (
          <>
            {tab === 'noticias' && country && <div className="rumor-section">Notícias · {country}</div>}
            {feed.posts.length === 0 ? (
              <div className="rumor-empty">
                <p>Nada por aqui ainda. Volte daqui a pouco — o povo adora comentar.</p>
              </div>
            ) : (
              feed.posts.map((p) => <PostCard key={p.id} post={p} now={now} />)
            )}
          </>
        )}
      </div>
    </div>
  );
}
