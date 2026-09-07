# ADR-0021 — Admin console PDF/QR dependencies for sticker batch preview

**Status:** Accepted · **Date:** 2026-09-06 · **Task:** P4-D-02

## Context

A-13 sticker batch export needs server-side PDF generation with embedded QR codes (doc 14 §6). W-04 must stay ≤ 60 KB and must not pull these libraries into the public pay route bundle.

## Decision

- Add **`pdfkit@0.17.1`** for PDF layout server-side only (`/api/finance/sticker-batch`, `src/lib/finance/sticker-pdf.ts`).
- Add **`qrcode@1.5.4`** to render PNG data URLs embedded in PDF labels (error correction H, ink `#0A0A0A` on white).
- Keep W-04 client bundle free of PDF/QR deps; QR on stickers is ops-preview only, marked **STAGING — not for production vehicles**.

## Alternatives considered

- **Browser print CSS:** no programmatic PDF assertion in Playwright; poor label layout control.
- **@react-pdf/renderer:** heavier React pipeline; pdfkit is sufficient for fixed label templates.
- **Client-side QR in finance console:** would bloat admin bundle and duplicate server export logic.

## Consequences

- PDF export runs on Node runtime (`export const runtime = 'nodejs'`).
- Production sticker print runbook remains P4-E-03; this export is preview-only.
