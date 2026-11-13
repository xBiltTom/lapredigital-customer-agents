import { useEffect, useRef, useState, type ReactNode } from 'react';

export function Chatbot({
  title,
  subtitle,
  children,
}: {
  title: string;
  subtitle: string;
  children: ReactNode;
}) {
  const [open, setOpen] = useState(false);
  const launcher = useRef<HTMLButtonElement | null>(null);
  const closeButton = useRef<HTMLButtonElement | null>(null);
  const panel = useRef<HTMLElement | null>(null);
  const wasOpen = useRef(false);

  useEffect(() => {
    if (open) {
      wasOpen.current = true;
      closeButton.current?.focus();
      requestAnimationFrame(() => {
        const log = panel.current?.querySelector<HTMLElement>('[data-chat-log]');
        if (log) log.scrollTop = log.scrollHeight;
      });
    } else if (wasOpen.current) {
      wasOpen.current = false;
      launcher.current?.focus();
    }
  }, [open]);

  useEffect(() => {
    if (!open) return;
    function closeOnEscape(event: KeyboardEvent) {
      if (event.key === 'Escape') setOpen(false);
    }
    window.addEventListener('keydown', closeOnEscape);
    return () => window.removeEventListener('keydown', closeOnEscape);
  }, [open]);

  return (
    <>
      {open && (
        <section
          ref={panel}
          id="chatbot-panel"
          className="chatbot-panel"
          role="dialog"
          aria-modal="false"
          aria-labelledby="chatbot-title"
        >
          <header className="chatbot-header">
            <span className="chatbot-avatar" aria-hidden="true">
              ✦
            </span>
            <div className="chatbot-heading">
              <h2 id="chatbot-title">{title}</h2>
              <small>{subtitle}</small>
            </div>
            <button
              ref={closeButton}
              className="chatbot-close"
              type="button"
              aria-label="Cerrar chat"
              onClick={() => setOpen(false)}
            >
              ×
            </button>
          </header>
          <div className="chatbot-body">{children}</div>
        </section>
      )}
      <button
        ref={launcher}
        className={`chatbot-launcher ${open ? 'is-open' : ''}`}
        type="button"
        aria-label={open ? 'Cerrar chat' : `Abrir chat: ${title}`}
        aria-expanded={open}
        aria-controls={open ? 'chatbot-panel' : undefined}
        onClick={() => setOpen((value) => !value)}
      >
        {open ? (
          <span aria-hidden="true">×</span>
        ) : (
          <svg viewBox="0 0 24 24" aria-hidden="true">
            <path d="M5 18.2 3.8 21l4.1-1.2a8.8 8.8 0 1 0-2.9-1.6Z" />
            <path d="M8 10.5h8M8 14h5" />
          </svg>
        )}
      </button>
    </>
  );
}
