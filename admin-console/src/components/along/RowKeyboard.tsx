'use client';

import { useEffect } from 'react';

/**
 * Makes clickable table rows (rows styled with cursor: pointer) reachable by keyboard:
 * Tab focuses them and Enter or Space activates them, mirroring the mouse click.
 * Also gives every tablist arrow-key navigation between its tabs.
 */
export function RowKeyboard() {
  useEffect(() => {
    const mark = () => {
      document.querySelectorAll<HTMLTableRowElement>('.data-table tbody tr').forEach((row) => {
        if (row.style.cursor === 'pointer' && !row.hasAttribute('tabindex')) {
          row.tabIndex = 0;
        }
      });
    };
    const onKey = (event: KeyboardEvent) => {
      const target = event.target as HTMLElement | null;
      const tablist = target?.closest('[role="tablist"]');
      if (tablist && (event.key === 'ArrowRight' || event.key === 'ArrowLeft')) {
        const tabs = Array.from(tablist.querySelectorAll<HTMLElement>('[role="tab"]'));
        const index = tabs.indexOf(target as HTMLElement);
        if (index >= 0) {
          event.preventDefault();
          const next = tabs[(index + (event.key === 'ArrowRight' ? 1 : tabs.length - 1)) % tabs.length];
          next.focus();
          next.click();
        }
        return;
      }
      if (!target || target.tagName !== 'TR' || !target.closest('.data-table')) return;
      if (event.key === 'Enter' || event.key === ' ') {
        event.preventDefault();
        target.click();
      }
    };
    mark();
    const observer = new MutationObserver(mark);
    observer.observe(document.body, { childList: true, subtree: true });
    document.addEventListener('keydown', onKey);
    return () => {
      observer.disconnect();
      document.removeEventListener('keydown', onKey);
    };
  }, []);
  return null;
}
