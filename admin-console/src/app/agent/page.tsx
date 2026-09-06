import { getActiveSettlementAgent } from '@/lib/authz/agent';
import { isAdmin } from '@/lib/supabase/server';
import { AgentSettlementForm } from './agent-settlement-form';

export default async function AgentPage() {
  if (await isAdmin()) {
    return <AgentForbidden reason="Admin accounts cannot use the agent settlement surface." />;
  }

  const agent = await getActiveSettlementAgent();
  if (!agent) {
    return (
      <AgentForbidden reason="Your account is not registered as an active settlement agent." />
    );
  }

  return (
    <main>
      <div className="page-header">
        <h1>Redeem settlement code</h1>
        <p>Confirm cash received from a driver and post their ledger credit.</p>
      </div>
      <div className="card agent-card">
        <AgentSettlementForm businessName={agent.business_name} />
      </div>
    </main>
  );
}

function AgentForbidden({ reason }: { reason: string }) {
  return (
    <main className="page-center" style={{ minHeight: '60vh' }}>
      <div className="card" style={{ maxWidth: '28rem', textAlign: 'center' }} data-testid="agent-forbidden">
        <h1 style={{ marginTop: 0 }}>Forbidden</h1>
        <p style={{ color: 'var(--color-text-muted)' }}>{reason}</p>
      </div>
    </main>
  );
}
