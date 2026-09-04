import { ConsoleNav } from '@/components/along/ConsoleNav';
import { getCityBySlug } from '@/lib/city/resolve';
import type {
  FieldReconciliationRow,
  FieldSubmissionPayload,
  FieldVariance,
} from '@/lib/field/types';
import { createClient } from '@/lib/supabase/server';
import { FieldQueue } from './field-queue';

interface PageProps {
  params: Promise<{ city: string }>;
}

async function loadReconciliations(cityId: string): Promise<FieldReconciliationRow[]> {
  const supabase = await createClient();

  const { data: submissions } = await supabase
    .from('field_submissions')
    .select('id')
    .eq('city_id', cityId);

  const submissionIds = (submissions ?? []).map((s) => s.id);
  if (submissionIds.length === 0) return [];

  const { data, error } = await supabase
    .from('field_reconciliations')
    .select(
      `
      id,
      entity_type,
      entity_key,
      status,
      variance,
      published_target_type,
      published_target_id,
      resolution,
      sub_a:field_submissions!field_reconciliations_submission_a_fkey(
        id, payload, scout_profile_id, submitted_at, status
      ),
      sub_b:field_submissions!field_reconciliations_submission_b_fkey(
        id, payload, scout_profile_id, submitted_at, status
      )
    `
    )
    .in('submission_a', submissionIds)
    .order('updated_at', { ascending: false });

  if (error || !data) return [];

  return data.map((row) => ({
    id: row.id,
    entity_type: row.entity_type,
    entity_key: row.entity_key,
    status: row.status,
    variance: row.variance as FieldVariance | null,
    published_target_type: row.published_target_type,
    published_target_id: row.published_target_id,
    resolution: row.resolution as FieldReconciliationRow['resolution'],
    sub_a: row.sub_a
      ? {
          id: row.sub_a.id,
          payload: row.sub_a.payload as FieldSubmissionPayload,
          scout_profile_id: row.sub_a.scout_profile_id,
          submitted_at: row.sub_a.submitted_at,
          status: row.sub_a.status,
        }
      : null,
    sub_b: row.sub_b
      ? {
          id: row.sub_b.id,
          payload: row.sub_b.payload as FieldSubmissionPayload,
          scout_profile_id: row.sub_b.scout_profile_id,
          submitted_at: row.sub_b.submitted_at,
          status: row.sub_b.status,
        }
      : null,
  }));
}

export default async function FieldReconciliationPage({ params }: PageProps) {
  const { city: citySlug } = await params;
  const city = await getCityBySlug(citySlug);
  const reconciliations = city ? await loadReconciliations(city.id) : [];

  return (
    <>
      <div className="page-header">
        <h1>Field reconciliation</h1>
        <p>
          Two-scout queue for <strong>{city?.name ?? citySlug}</strong> — merge, resolve, or publish
          to <code>field_verified</code>.
        </p>
      </div>
      {!city ? (
        <div className="error-banner" role="alert">
          City &quot;{citySlug}&quot; was not found in the database.
        </div>
      ) : null}
      <ConsoleNav city={citySlug} />
      <FieldQueue citySlug={citySlug} initialRows={reconciliations} />
    </>
  );
}
