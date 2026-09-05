import { ConsoleNav } from '@/components/along/ConsoleNav';
import { AuditDrawer } from '@/components/along/AuditDrawer';
import { getCityBySlug } from '@/lib/city/resolve';
import { maskPhoneE164, sortVerificationQueue } from '@/lib/verification/format';
import type { DuplicateCheck, VerificationQueueRow } from '@/lib/verification/types';
import { createClient } from '@/lib/supabase/server';
import { VerificationQueue } from './verification-queue';

interface PageProps {
  params: Promise<{ city: string }>;
}

type DriverProfileRow = {
  id: string;
  profiles: {
    display_name: string | null;
    gender: string | null;
    phone_e164: string | null;
  } | null;
};

type RawVerificationRow = {
  id: string;
  driver_id: string;
  document_type: string;
  status: VerificationQueueRow['status'];
  submitted_at: string;
  storage_path: string | null;
  ocr_extract: Record<string, unknown> | null;
  face_match_score: number | null;
  vehicle_id: string | null;
  vehicles: {
    plate_number: string;
    color: string | null;
    make_model: string | null;
    seat_capacity: number;
  } | null;
};

async function loadDuplicateFlags(
  supabase: Awaited<ReturnType<typeof createClient>>,
  ids: string[]
): Promise<Map<string, DuplicateCheck>> {
  const map = new Map<string, DuplicateCheck>();
  await Promise.all(
    ids.map(async (id) => {
      const { data } = await supabase.rpc('admin_check_identity_duplicate', {
        p_verification_id: id,
      });
      if (data) {
        map.set(id, data as DuplicateCheck);
      }
    })
  );
  return map;
}

async function loadVerificationQueue(cityId: string): Promise<VerificationQueueRow[]> {
  const supabase = await createClient();

  const { data: driverRows, error: driverError } = await supabase
    .from('drivers')
    .select('id, profiles(display_name, gender, phone_e164)')
    .eq('city_id', cityId);

  if (driverError || !driverRows?.length) {
    if (driverError) console.error('[loadVerificationQueue] drivers', driverError.message);
    return [];
  }

  const drivers = driverRows as unknown as DriverProfileRow[];
  const driverMap = new Map(drivers.map((d) => [d.id, d.profiles]));
  const driverIds = drivers.map((d) => d.id);

  const { data, error } = await supabase
    .from('driver_verifications')
    .select(
      `
      id,
      driver_id,
      document_type,
      status,
      submitted_at,
      storage_path,
      ocr_extract,
      face_match_score,
      vehicle_id,
      vehicles (
        plate_number,
        color,
        make_model,
        seat_capacity
      )
    `
    )
    .in('driver_id', driverIds)
    .order('submitted_at', { ascending: true });

  if (error || !data) {
    console.error('[loadVerificationQueue] verifications', error?.message);
    return [];
  }

  const rows = data as unknown as RawVerificationRow[];
  const duplicateFlags = await loadDuplicateFlags(
    supabase,
    rows.filter((r) => r.status === 'pending').map((r) => r.id)
  );

  const mapped: VerificationQueueRow[] = rows.map((row) => {
    const dup = duplicateFlags.get(row.id);
    const profile = driverMap.get(row.driver_id);
    return {
      id: row.id,
      driver_id: row.driver_id,
      document_type: row.document_type,
      status: row.status,
      submitted_at: row.submitted_at,
      storage_path: row.storage_path,
      ocr_extract: row.ocr_extract,
      face_match_score: row.face_match_score,
      vehicle_id: row.vehicle_id,
      driver_display_name: profile?.display_name ?? null,
      driver_gender: profile?.gender ?? null,
      driver_phone_masked: maskPhoneE164(profile?.phone_e164),
      vehicle_plate: row.vehicles?.plate_number ?? null,
      vehicle_color: row.vehicles?.color ?? null,
      vehicle_make_model: row.vehicles?.make_model ?? null,
      vehicle_seat_capacity: row.vehicles?.seat_capacity ?? null,
      duplicate: Boolean(dup?.duplicate),
      other_driver_masked: dup?.other_driver_masked ?? null,
    };
  });

  return sortVerificationQueue(mapped);
}

export default async function VerificationPage({ params }: PageProps) {
  const { city: citySlug } = await params;
  const city = await getCityBySlug(citySlug);
  const queue = city ? await loadVerificationQueue(city.id) : [];
  const selectedId = queue.find((r) => r.status === 'pending')?.id ?? queue[0]?.id ?? null;

  return (
    <>
      <div className="page-header">
        <h1>Verification</h1>
        <p>
          Driver document review queue for <strong>{city?.name ?? citySlug}</strong> — pending
          first, oldest age.
        </p>
      </div>
      {!city ? (
        <div className="error-banner" role="alert">
          City &quot;{citySlug}&quot; was not found in the database.
        </div>
      ) : null}
      <ConsoleNav city={citySlug} />
      <VerificationQueue
        citySlug={citySlug}
        initialRows={queue}
        initialSelectedId={selectedId}
      />
      {selectedId ? <AuditDrawer targetId={selectedId} targetLabel="verification" /> : null}
    </>
  );
}
