'use client';

import { useEffect, useState } from 'react';

type Theme = 'system' | 'light' | 'dark';
const ORDER: Theme[] = ['system', 'light', 'dark'];
const LABEL: Record<Theme, string> = { system: 'Auto', light: 'Light', dark: 'Dark' };

/** Cycles Auto (prefers-color-scheme) → Light → Dark; remembered per browser. */
export function ThemeToggle() {
  const [theme, setTheme] = useState<Theme>('system');

  useEffect(() => {
    const saved = localStorage.getItem('along-theme');
    if (saved === 'light' || saved === 'dark') setTheme(saved);
  }, []);

  function next() {
    const t = ORDER[(ORDER.indexOf(theme) + 1) % ORDER.length]!;
    setTheme(t);
    const root = document.documentElement;
    if (t === 'system') {
      localStorage.removeItem('along-theme');
      delete root.dataset.theme;
    } else {
      localStorage.setItem('along-theme', t);
      root.dataset.theme = t;
    }
  }

  return (
    <button type="button" className="theme-toggle" onClick={next} aria-label={`Theme: ${LABEL[theme]}`}>
      {LABEL[theme]}
    </button>
  );
}

/** Runs before paint so a saved choice never flashes the other theme. */
export const themeBootScript =
  "try{var t=localStorage.getItem('along-theme');if(t==='light'||t==='dark')document.documentElement.dataset.theme=t}catch(e){}";
