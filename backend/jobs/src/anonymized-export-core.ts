export type OdObservation = {
  originGeohash: string;
  destinationGeohash: string;
  modeCode: string;
  dowBucket: 0 | 1;
  hourBucket: number;
};

export type OdAggregateCell = OdObservation & {
  tripCount: number;
};

export type OdCellKey = string;

export const EXPORT_ALLOWED_COLUMNS = [
  'originGeohash',
  'destinationGeohash',
  'modeCode',
  'dowBucket',
  'hourBucket',
  'tripCount',
  'cityId',
  'exportId',
] as const;

export const EXPORT_FORBIDDEN_COLUMNS = [
  'riderId',
  'rider_id',
  'driverId',
  'driver_id',
  'phone',
  'phone_e164',
  'plate',
  'plate_number',
  'vehicleId',
  'vehicle_id',
  'origin',
  'destination',
  'boarding_location',
  'alighting_location',
  'lat',
  'lng',
  'location',
  'geometry',
] as const;

export function odCellKey(observation: OdObservation): OdCellKey {
  return [
    observation.originGeohash,
    observation.destinationGeohash,
    observation.modeCode,
    observation.dowBucket,
    observation.hourBucket,
  ].join('|');
}

export function aggregateOdObservations(observations: OdObservation[]): OdAggregateCell[] {
  const counts = new Map<OdCellKey, { observation: OdObservation; tripCount: number }>();

  for (const observation of observations) {
    const key = odCellKey(observation);
    const existing = counts.get(key);
    if (existing) {
      existing.tripCount += 1;
    } else {
      counts.set(key, { observation, tripCount: 1 });
    }
  }

  return [...counts.values()].map(({ observation, tripCount }) => ({
    ...observation,
    tripCount,
  }));
}

export function suppressCellsBelowK(cells: OdAggregateCell[], k: number): OdAggregateCell[] {
  if (!Number.isFinite(k) || k < 1) {
    throw new RangeError('k must be a positive finite number');
  }
  return cells.filter((cell) => cell.tripCount >= k);
}

export function partitionCellsByK(
  cells: OdAggregateCell[],
  k: number,
): { emitted: OdAggregateCell[]; suppressed: OdAggregateCell[] } {
  const emitted: OdAggregateCell[] = [];
  const suppressed: OdAggregateCell[] = [];
  for (const cell of cells) {
    if (cell.tripCount >= k) {
      emitted.push(cell);
    } else {
      suppressed.push(cell);
    }
  }
  return { emitted, suppressed };
}

export function assertExportRowIsPiiFree(row: Record<string, unknown>): void {
  for (const forbidden of EXPORT_FORBIDDEN_COLUMNS) {
    if (Object.prototype.hasOwnProperty.call(row, forbidden)) {
      throw new Error(`export row contains forbidden column: ${forbidden}`);
    }
  }
}

export function sanitizeExportRow(
  cell: OdAggregateCell,
  meta: { cityId: string; exportId: string },
): Record<string, unknown> {
  const row = {
    originGeohash: cell.originGeohash,
    destinationGeohash: cell.destinationGeohash,
    modeCode: cell.modeCode,
    dowBucket: cell.dowBucket,
    hourBucket: cell.hourBucket,
    tripCount: cell.tripCount,
    cityId: meta.cityId,
    exportId: meta.exportId,
  };
  assertExportRowIsPiiFree(row);
  return row;
}
