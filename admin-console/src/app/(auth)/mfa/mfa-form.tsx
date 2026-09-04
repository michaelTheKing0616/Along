'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { FormEvent, useEffect, useState } from 'react';
import { createClient } from '@/lib/supabase/client';

export default function MfaForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const next = searchParams.get('next') ?? '/abuja/dashboard';
  const [code, setCode] = useState('');
  const [factorId, setFactorId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    async function loadFactors() {
      const supabase = createClient();
      const { data, error: listError } = await supabase.auth.mfa.listFactors();
      if (listError) {
        setError('Unable to load MFA factors.');
        return;
      }
      const totp = data.totp.find((f) => f.status === 'verified');
      if (totp) {
        setFactorId(totp.id);
      } else {
        setError('No verified TOTP factor found for this account.');
      }
    }
    void loadFactors();
  }, []);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    if (!factorId) return;

    setError(null);
    setLoading(true);
    const supabase = createClient();

    const { data: challenge, error: challengeError } = await supabase.auth.mfa.challenge({
      factorId,
    });
    if (challengeError || !challenge) {
      setLoading(false);
      setError('MFA challenge failed.');
      return;
    }

    const { error: verifyError } = await supabase.auth.mfa.verify({
      factorId,
      challengeId: challenge.id,
      code,
    });

    setLoading(false);

    if (verifyError) {
      setError('Invalid authentication code.');
      return;
    }

    router.push(next);
    router.refresh();
  }

  return (
    <main className="page-center">
      <div className="card" style={{ width: '100%', maxWidth: '24rem' }}>
        <h1 style={{ marginTop: 0 }}>Two-factor authentication</h1>
        <p style={{ color: 'var(--color-text-muted)', marginBottom: 'var(--space-6)' }}>
          Enter the 6-digit code from your authenticator app.
        </p>
        {error ? <div className="error-banner">{error}</div> : null}
        <form onSubmit={handleSubmit}>
          <div className="field">
            <label htmlFor="code">Authentication code</label>
            <input
              id="code"
              type="text"
              inputMode="numeric"
              autoComplete="one-time-code"
              pattern="[0-9]{6}"
              maxLength={6}
              required
              value={code}
              onChange={(e) => setCode(e.target.value.replace(/\D/g, ''))}
            />
          </div>
          <button
            className="btn btn-primary"
            type="submit"
            disabled={loading || !factorId}
            style={{ width: '100%' }}
          >
            {loading ? 'Verifying…' : 'Verify'}
          </button>
        </form>
      </div>
    </main>
  );
}
