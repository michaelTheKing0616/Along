'use server';

import { revalidatePath } from 'next/cache';
import { createClient } from '@/lib/supabase/server';
import { rpcUntyped } from '@/lib/supabase/untyped';

export type RevenueActionResult =
  | { ok: true; message: string; payload?: Record<string, unknown> }
  | { ok: false; error: string };

function rpcError(error: { message: string }): RevenueActionResult {
  return { ok: false, error: error.message };
}

export async function createSponsoredPlacement(
  citySlug: string,
  input: {
    deploymentId: string;
    contextType: 'destination' | 'park' | 'corridor';
    targetReference: string;
    advertiser: string;
    contentJson: string;
    activeFrom: string;
    activeTo: string;
  }
): Promise<RevenueActionResult> {
  let content: Record<string, unknown> = {};
  if (input.contentJson.trim()) {
    try {
      content = JSON.parse(input.contentJson) as Record<string, unknown>;
    } catch {
      return { ok: false, error: 'Content must be valid JSON.' };
    }
  }

  const supabase = await createClient();
  const { data, error } = await rpcUntyped(supabase, 'admin_create_sponsored_placement', {
    p_deployment_id: input.deploymentId,
    p_context_type: input.contextType,
    p_target_reference: input.targetReference,
    p_advertiser: input.advertiser,
    p_content: content,
    p_active_from: input.activeFrom,
    p_active_to: input.activeTo,
  });

  if (error) return rpcError(error);

  revalidatePath(`/${citySlug}/revenue`);
  return {
    ok: true,
    message: 'Sponsored placement created.',
    payload: (data ?? {}) as Record<string, unknown>,
  };
}

export async function createApiKey(
  citySlug: string,
  input: {
    ownerOrganization: string;
    scope: string[];
    rateLimitPerMin?: number;
  }
): Promise<RevenueActionResult> {
  const supabase = await createClient();
  const { data, error } = await rpcUntyped(supabase, 'admin_create_api_key', {
    p_owner_organization: input.ownerOrganization,
    p_scope: input.scope,
    p_rate_limit_per_min: input.rateLimitPerMin ?? null,
  });

  if (error) return rpcError(error);

  revalidatePath(`/${citySlug}/revenue`);
  return {
    ok: true,
    message: 'API key created — copy the plaintext key now.',
    payload: (data ?? {}) as Record<string, unknown>,
  };
}

export async function revokeApiKey(citySlug: string, apiKeyId: string): Promise<RevenueActionResult> {
  const supabase = await createClient();
  const { data, error } = await rpcUntyped(supabase, 'admin_revoke_api_key', {
    p_api_key_id: apiKeyId,
  });

  if (error) return rpcError(error);

  revalidatePath(`/${citySlug}/revenue`);
  return {
    ok: true,
    message: 'API key revoked.',
    payload: (data ?? {}) as Record<string, unknown>,
  };
}

export async function createCorporateAccount(
  citySlug: string,
  input: {
    deploymentId: string;
    name: string;
    billingEmail: string;
    monthlyBudget?: number;
    currency?: string;
  }
): Promise<RevenueActionResult> {
  const supabase = await createClient();
  const { data, error } = await rpcUntyped(supabase, 'admin_create_corporate_account', {
    p_deployment_id: input.deploymentId,
    p_name: input.name,
    p_billing_email: input.billingEmail,
    p_monthly_budget: input.monthlyBudget ?? null,
    p_currency: input.currency ?? 'NGN',
  });

  if (error) return rpcError(error);

  revalidatePath(`/${citySlug}/revenue`);
  return {
    ok: true,
    message: 'Corporate account created.',
    payload: (data ?? {}) as Record<string, unknown>,
  };
}

export async function createOperatorAccount(
  citySlug: string,
  input: {
    deploymentId: string;
    type: 'park' | 'union' | 'vehicle_owner' | 'corporate';
    name: string;
    subscriptionTier?: string;
  }
): Promise<RevenueActionResult> {
  const supabase = await createClient();
  const { data, error } = await rpcUntyped(supabase, 'admin_create_operator_account', {
    p_deployment_id: input.deploymentId,
    p_type: input.type,
    p_name: input.name,
    p_subscription_tier: input.subscriptionTier ?? 'basic',
  });

  if (error) return rpcError(error);

  revalidatePath(`/${citySlug}/revenue`);
  return {
    ok: true,
    message: 'Operator account created.',
    payload: (data ?? {}) as Record<string, unknown>,
  };
}
