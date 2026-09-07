'use client';

import type { ReactNode } from 'react';
import Link from 'next/link';
import type {
  LiveMapActiveTrip,
  LiveMapPresenceVehicle,
  LiveMapSelection,
  LiveMapStaticPayload,
} from '@/lib/map/types';

interface LiveMapSidePanelProps {
  citySlug: string;
  selection: LiveMapSelection;
  staticData: LiveMapStaticPayload;
  presence: LiveMapPresenceVehicle[];
  trips: LiveMapActiveTrip[];
  onClose: () => void;
}

export function LiveMapSidePanel({
  citySlug,
  selection,
  staticData,
  presence,
  trips,
  onClose,
}: LiveMapSidePanelProps) {
  if (!selection) return null;

  let title = 'Details';
  let body: ReactNode = null;

  if (selection.kind === 'presence') {
    const vehicle = presence.find((row) => row.driver_id === selection.driverId);
    if (vehicle) {
      title = 'Driver presence';
      body = (
        <>
          <p>
            <strong>Plate:</strong> {vehicle.plate}
          </p>
          <p>
            <strong>Status:</strong> {vehicle.status.replace(/_/g, ' ')}
          </p>
          <p>
            <strong>Mode:</strong> {vehicle.mode}
          </p>
          <p>
            <strong>Seats:</strong> {vehicle.seats_available}
          </p>
          <p>
            <strong>Position:</strong> {vehicle.lat.toFixed(5)}, {vehicle.lng.toFixed(5)}
          </p>
          <p>
            <strong>Driver id:</strong> <code>{vehicle.driver_id}</code>
          </p>
        </>
      );
    }
  }

  if (selection.kind === 'trip') {
    const trip = trips.find((row) => row.trip_id === selection.tripId);
    if (trip) {
      title = 'Active trip';
      body = (
        <>
          <p>
            <strong>Status:</strong> {trip.status}
          </p>
          <p>
            <strong>Na Me:</strong> {trip.na_me_color} / {trip.na_me_shape}
          </p>
          <p>
            <strong>Rider:</strong> {trip.rider_name ?? trip.rider_id}
          </p>
          <p>
            <strong>Driver:</strong> {trip.driver_name ?? trip.driver_id ?? '—'}
          </p>
          <p>
            <strong>Plate:</strong> {trip.plate ?? '—'}
          </p>
        </>
      );
    }
  }

  if (selection.kind === 'sos') {
    const sos = staticData.sos.find((row) => row.id === selection.sosId);
    if (sos) {
      title = 'Open SOS';
      body = (
        <>
          <p>
            <strong>Status:</strong> {sos.status}
          </p>
          <p>
            <strong>Age:</strong> {Math.floor(sos.age_s)}s
          </p>
          <p>
            <strong>Raiser:</strong> {sos.raiser_name ?? '—'}
          </p>
          <p>
            <strong>Rider:</strong> {sos.rider_name ?? '—'}
          </p>
          <p>
            <strong>Driver:</strong> {sos.driver_name ?? '—'}
          </p>
          <p>
            <strong>Plate:</strong> {sos.vehicle_plate ?? '—'}
          </p>
          <Link href={`/${citySlug}/safety`}>Open safety board →</Link>
        </>
      );
    }
  }

  if (selection.kind === 'park') {
    const park = staticData.parks.find((row) => row.id === selection.parkId);
    if (park) {
      title = park.name;
      body = (
        <>
          <p>
            <strong>Verification:</strong> {park.verification_status.replace(/_/g, ' ')}
          </p>
          <p>
            <strong>Location:</strong> {park.lat.toFixed(5)}, {park.lng.toFixed(5)}
          </p>
        </>
      );
    }
  }

  if (selection.kind === 'stage') {
    const stage = staticData.stages.find((row) => row.id === selection.stageId);
    if (stage) {
      title = stage.name ?? 'Stage';
      body = (
        <>
          <p>
            <strong>Route:</strong> <code>{stage.route_id}</code>
          </p>
          <p>
            <strong>Sequence:</strong> {stage.sequence}
          </p>
          <p>
            <strong>Verification:</strong> {stage.verification_status.replace(/_/g, ' ')}
          </p>
        </>
      );
    }
  }

  if (!body) return null;

  return (
    <aside className="live-map-side-panel card" aria-label="Map selection details">
      <div className="live-map-side-panel-header">
        <h2>{title}</h2>
        <button type="button" className="btn" onClick={onClose} aria-label="Close panel">
          Close
        </button>
      </div>
      <div className="live-map-side-panel-body">{body}</div>
    </aside>
  );
}
