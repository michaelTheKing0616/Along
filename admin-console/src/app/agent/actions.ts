'use server';

import { revalidatePath } from 'next/cache';
import { getActiveSettlementAgent } from '@/lib/authz/agent';
import { isAdmin } from '@/lib/supabase/server';
import { createClient } from '@/lib/supabase/server';

export type AgentSettlementResult =
  | { ok: true; ledgerEntryId: string; balanceAfter: number }
  | { ok: false; error: string; code?: string };

export async function confirmAgentSettlement(
  agentCode: string,
  amount: number
): Promise<AgentSettlementResult> {
  if (await isAdmin()) {
    return { ok: false, error: 'Admin accounts cannot redeem agent codes.', code: 'FORBIDDEN' };
  }

  const agent = await getActiveSettlementAgent();
  if (!agent) {
    return { ok: false, error: 'You are not an active settlement agent.', code: 'FORBIDDEN' };
  }

  const code = agentCode.trim().toUpperCase();
  if (!code) {
    return { ok: false, error: 'Enter the driver agent code.', code: 'VALIDATION' };
  }

  if (!Number.isFinite(amount) || amount <= 0) {
    return { ok: false, error: 'Enter a valid amount greater than zero.', code: 'VALIDATION' };
  }

  const supabase = await createClient();
  const { data, error } = await supabase.rpc('confirm_agent_settlement', {
    p_agent_code: code,
    p_amount: amount,
  });

  if (error) {
    const message = error.message ?? 'Settlement failed.';
    const codeMatch = message.match(
      /^(UNAUTHENTICATED|FORBIDDEN|NOT_FOUND|VALIDATION|STATE_INVALID|IDEMPOTENT_REPLAY)/
    );
    return {
      ok: false,
      error: humanizeAgentError(codeMatch?.[1] ?? message, message),
      code: codeMatch?.[1] ?? 'ERROR',
    };
  }

  const payload = data as {
    ledger_entry_id?: string | number;
    balance_after?: number;
  };

  revalidatePath('/agent');
  return {
    ok: true,
    ledgerEntryId: String(payload.ledger_entry_id ?? ''),
    balanceAfter: Number(payload.balance_after ?? 0),
  };
}

function humanizeAgentError(code: string, raw: string): string {
  switch (code) {
    case 'IDEMPOTENT_REPLAY':
      return 'This code was already redeemed. Each agent code can only be used once.';
    case 'FORBIDDEN':
      return 'You cannot redeem this code (wrong city or inactive agent).';
    case 'NOT_FOUND':
      return 'Agent code not found. Check the code and try again.';
    case 'VALIDATION':
      return raw.includes('amount mismatch')
        ? 'Amount does not match the driver request.'
        : 'Invalid code or amount.';
    case 'STATE_INVALID':
      return raw.includes('expired') ? 'This agent code has expired.' : 'This code is no longer valid.';
    default:
      return raw;
  }
}
