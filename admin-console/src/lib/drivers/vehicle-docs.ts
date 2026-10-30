export interface DriverVehicleCard {
  plate_number: string;
  make_model: string | null;
  color: string | null;
  seat_capacity: number;
  mode_code: string;
  verification_status: string;
  since: string;
}

export interface DriverDocumentCard {
  id: string;
  document_type: string;
  status: string;
  submitted_at: string;
  expires_at: string | null;
  rejection_reason: string | null;
}

type VehicleJoinRow = {
  since: string;
  vehicles:
    | Omit<DriverVehicleCard, "since">
    | Omit<DriverVehicleCard, "since">[]
    | null;
};

/** Active vehicle from a driver_vehicles → vehicles join; RLS hides rows outside the admin's cities. */
export function toVehicleCard(
  row: VehicleJoinRow | null | undefined,
): DriverVehicleCard | null {
  if (!row?.vehicles) return null;
  const v = Array.isArray(row.vehicles) ? row.vehicles[0] : row.vehicles;
  if (!v) return null;
  return { ...v, seat_capacity: Number(v.seat_capacity), since: row.since };
}

/** Latest submission per document type, newest first. */
export function latestDocuments(
  rows: DriverDocumentCard[] | null | undefined,
): DriverDocumentCard[] {
  const seen = new Map<string, DriverDocumentCard>();
  for (const r of [...(rows ?? [])].sort((a, b) =>
    b.submitted_at.localeCompare(a.submitted_at),
  )) {
    if (!seen.has(r.document_type)) seen.set(r.document_type, r);
  }
  return [...seen.values()];
}

/** Expired or expiring within 30 days. */
export function documentExpiry(
  expiresAt: string | null,
  now = new Date(),
): "expired" | "soon" | null {
  if (!expiresAt) return null;
  const ms = new Date(expiresAt).getTime() - now.getTime();
  if (ms < 0) return "expired";
  return ms < 30 * 86_400_000 ? "soon" : null;
}

const DOC_LABELS: Record<string, string> = {
  nin: "NIN",
  bvn: "BVN",
  drivers_licence: "Driver's licence",
  vehicle_registration: "Vehicle registration",
  insurance: "Insurance",
};

export function documentLabel(type: string): string {
  return (
    DOC_LABELS[type] ??
    type.replace(/_/g, " ").replace(/^./, (c) => c.toUpperCase())
  );
}
