'use client';

import { Suspense } from 'react';
import MfaForm from './mfa-form';

export default function MfaPage() {
  return (
    <Suspense fallback={<main className="page-center">Loading…</main>}>
      <MfaForm />
    </Suspense>
  );
}
