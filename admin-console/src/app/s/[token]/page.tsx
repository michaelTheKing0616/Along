import {
  fetchSharedTripView,
  formatEtaMinutes,
  modeLabel,
} from '@/lib/safety/shared-trip-server';
import './share.css';

interface PageProps {
  params: Promise<{ token: string }>;
}

export default async function SharedTripPage({ params }: PageProps) {
  const { token } = await params;

  let view = null;
  let loadError: string | null = null;

  try {
    view = await fetchSharedTripView(token);
  } catch (err) {
    loadError = err instanceof Error ? err.message : 'Could not load trip';
  }

  if (loadError || !view) {
    return (
      <main className="w01-main w01-state" data-testid="w01-inactive">
        <h1>Link expired</h1>
        <p>{loadError ?? 'This shared trip link is no longer active.'}</p>
      </main>
    );
  }

  return (
    <main className="w01-main" data-testid="w01-shared-trip">
      <p className="w01-brand">Along · Shared trip</p>
      <p className="w01-rider" data-testid="w01-rider-first-name">
        {view.rider_first_name}
      </p>
      <p className="w01-plate" data-testid="w01-plate">
        {view.vehicle.plate}
      </p>
      <div className="w01-meta">
        <span className="w01-chip" data-testid="w01-color">
          {view.vehicle.color}
        </span>
        <span className="w01-chip" data-testid="w01-mode">
          {modeLabel(view.mode.code, view.mode.label)}
        </span>
        <span className="w01-chip w01-chip-live" data-testid="w01-live-marker">
          Live
        </span>
      </div>

      <div className="w01-row">
        <span className="w01-row-label">Destination</span>
        <span className="w01-row-value" data-testid="w01-destination">
          {view.destination_label}
        </span>
      </div>
      <div className="w01-row">
        <span className="w01-row-label">ETA</span>
        <span className="w01-row-value" data-testid="w01-eta">
          {formatEtaMinutes(view.eta_s)}
        </span>
      </div>

      <div className="w01-legs" data-testid="w01-legs">
        {view.legs_progress.map((leg, index) => (
          <div
            key={`${leg.sequence ?? index}-${leg.label ?? 'leg'}`}
            className="w01-leg"
            data-testid={`w01-leg-${index}`}
          >
            {leg.label ?? `Leg ${(leg.sequence ?? index) + 1}`}
          </div>
        ))}
      </div>

      <footer className="w01-footer">Location updates while the trip is active</footer>
    </main>
  );
}
