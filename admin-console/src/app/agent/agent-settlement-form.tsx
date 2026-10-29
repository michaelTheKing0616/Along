'use client';

import { FormEvent, useState, useTransition } from 'react';
import { formatMoney } from '@/lib/drivers/format';
import { confirmAgentSettlement } from './actions';

interface AgentSettlementFormProps {
  businessName: string;
}

export function AgentSettlementForm({ businessName }: AgentSettlementFormProps) {
  const [agentCode, setAgentCode] = useState('');
  const [amount, setAmount] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<{ ledgerEntryId: string; balanceAfter: number } | null>(
    null
  );
  const [pending, startTransition] = useTransition();

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setSuccess(null);

    const parsedAmount = Number.parseFloat(amount);
    startTransition(async () => {
      const result = await confirmAgentSettlement(agentCode, parsedAmount);
      if (result.ok) {
        setSuccess({
          ledgerEntryId: result.ledgerEntryId,
          balanceAfter: result.balanceAfter,
        });
        setAgentCode('');
        setAmount('');
      } else {
        setError(result.error);
      }
    });
  }

  return (
    <div data-testid="agent-settlement-form">
      <p style={{ color: 'var(--color-text-muted)', marginBottom: 'var(--space-6)' }}>
        Signed in as <strong>{businessName}</strong>. Enter the driver&apos;s settlement code and
        cash amount received.
      </p>

      {error ? (
        <div className="error-banner" role="alert" data-testid="agent-error">
          {error}
        </div>
      ) : null}

      {success ? (
        <div
          className="card agent-success-banner"
          role="status"
          data-testid="agent-success"
          style={{ marginBottom: 'var(--space-4)' }}
        >
          <strong>Credit posted.</strong>
          <p style={{ margin: 'var(--space-2) 0 0' }}>
            Ledger entry #{success.ledgerEntryId}. Driver balance after:{' '}
            {formatMoney(success.balanceAfter)}
          </p>
        </div>
      ) : null}

      <form onSubmit={handleSubmit}>
        <div className="field">
          <label htmlFor="agent-code">Agent code</label>
          <input
            id="agent-code"
            data-testid="agent-code-input"
            type="text"
            autoComplete="off"
            autoCapitalize="characters"
            required
            value={agentCode}
            onChange={(e) => setAgentCode(e.target.value.toUpperCase())}
            placeholder="6-character code from driver"
          />
        </div>
        <div className="field">
          <label htmlFor="agent-amount">Amount (NGN)</label>
          <input
            id="agent-amount"
            data-testid="agent-amount-input"
            type="number"
            inputMode="decimal"
            min="0.01"
            step="0.01"
            required
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="e.g. 5000"
          />
        </div>
        <button
          className="btn btn-agent"
          type="submit"
          disabled={pending}
          data-testid="agent-submit"
          style={{ width: '100%' }}
        >
          {pending ? 'Confirming…' : 'Confirm settlement'}
        </button>
      </form>
    </div>
  );
}
