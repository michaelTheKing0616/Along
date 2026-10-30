"use client";

import Link from "next/link";
import { useMemo, useState, useTransition } from "react";
import {
  formatCoordinates,
  geometryStatusLabel,
  graphMapLink,
  parkStatusLabel,
  routeInferenceStatusLabel,
} from "@/lib/intelligence/format";
import type {
  CandidateParkRow,
  GeometryCorrectionRow,
  IntelligenceTab,
  RouteInferenceRow,
} from "@/lib/intelligence/types";
import {
  reviewCandidatePark,
  reviewGeometryCorrection,
  reviewRouteInference,
} from "./actions";

interface IntelligenceConsoleProps {
  citySlug: string;
  candidateParks: CandidateParkRow[];
  routeInferences: RouteInferenceRow[];
  geometryCorrections: GeometryCorrectionRow[];
}

const TABS: { id: IntelligenceTab; label: string }[] = [
  { id: "parks", label: "Candidate parks" },
  { id: "routes", label: "Route inference" },
  { id: "geometry", label: "Geometry corrections" },
];

export function IntelligenceConsole({
  citySlug,
  candidateParks,
  routeInferences,
  geometryCorrections,
}: IntelligenceConsoleProps) {
  const [tab, setTab] = useState<IntelligenceTab>("parks");
  const [parks, setParks] = useState(candidateParks);
  const [routes, setRoutes] = useState(routeInferences);
  const [geometry, setGeometry] = useState(geometryCorrections);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();

  const pendingCounts = useMemo(
    () => ({
      parks: parks.filter((r) => r.status === "new").length,
      routes: routes.filter((r) => r.status === "new").length,
      geometry: geometry.filter((r) => r.status === "candidate").length,
    }),
    [parks, routes, geometry],
  );

  function runAction(
    action: () => Promise<{ ok: boolean; message?: string; error?: string }>,
  ) {
    setMessage(null);
    setError(null);
    startTransition(async () => {
      const result = await action();
      if (result.ok) {
        setMessage(result.message ?? "Done.");
      } else {
        setError(result.error ?? "Action failed.");
      }
    });
  }

  function patchPark(id: string, status: CandidateParkRow["status"]) {
    setParks((prev) => prev.map((r) => (r.id === id ? { ...r, status } : r)));
  }

  function patchRoute(
    id: string,
    status: RouteInferenceRow["status"],
    routeId?: string | null,
  ) {
    setRoutes((prev) =>
      prev.map((r) =>
        r.id === id ? { ...r, status, route_id: routeId ?? r.route_id } : r,
      ),
    );
  }

  function patchGeometry(id: string, status: GeometryCorrectionRow["status"]) {
    setGeometry((prev) =>
      prev.map((r) => (r.id === id ? { ...r, status } : r)),
    );
  }

  return (
    <div data-testid="intelligence-console">
      {error ? (
        <div
          className="error-banner"
          role="alert"
          data-testid="intelligence-error"
        >
          {error}
        </div>
      ) : null}
      {message ? (
        <div
          className="card"
          role="status"
          data-testid="intelligence-success"
          style={{
            marginBottom: "var(--space-4)",
            borderColor: "var(--color-primary)",
            fontSize: "0.875rem",
          }}
        >
          {message}
        </div>
      ) : null}

      <div
        className="seg"
        role="tablist"
        aria-label="Intelligence review tabs"
        style={{ marginBottom: "var(--space-4)" }}
      >
        {TABS.map(({ id, label }) => (
          <button
            key={id}
            type="button"
            role="tab"
            aria-selected={tab === id}
            className={tab === id ? "nav-link-active" : undefined}
            onClick={() => setTab(id)}
            data-testid={`intelligence-tab-${id}`}
          >
            {label}
            {pendingCounts[id] > 0 ? ` (${pendingCounts[id]})` : ""}
          </button>
        ))}
      </div>

      {tab === "parks" ? (
        <section aria-label="Candidate parks" data-testid="intelligence-parks">
          {parks.length === 0 ? (
            <p className="empty-inline">
              No candidate park clusters for this city.
            </p>
          ) : (
            <table className="data-table">
              <thead>
                <tr>
                  <th className="num">Drivers</th>
                  <th className="num">Days</th>
                  <th className="num">Samples</th>
                  <th>Centroid</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {parks.map((row) => (
                  <tr key={row.id} data-testid={`park-row-${row.id}`}>
                    <td className="num">{row.distinct_driver_count}</td>
                    <td className="num">{row.distinct_day_count}</td>
                    <td className="num">{row.sample_count}</td>
                    <td>
                      <span className="mono">
                        {formatCoordinates(row.lat, row.lng)}
                      </span>
                      <Link
                        className="cell-sub"
                        style={{ display: "block" }}
                        href={graphMapLink(citySlug, row.lat, row.lng)}
                      >
                        Open in graph map
                      </Link>
                    </td>
                    <td>
                      <span className={`badge badge-${row.status}`}>
                        {parkStatusLabel(row.status)}
                      </span>
                    </td>
                    <td>
                      {row.status === "new" ? (
                        <>
                          <button
                            type="button"
                            disabled={pending}
                            data-testid={`promote-park-${row.id}`}
                            onClick={() =>
                              runAction(async () => {
                                const result = await reviewCandidatePark(
                                  citySlug,
                                  row.id,
                                  "promote",
                                );
                                if (result.ok)
                                  patchPark(row.id, "promoted_to_stage");
                                return result;
                              })
                            }
                          >
                            Promote
                          </button>{" "}
                          <button
                            type="button"
                            disabled={pending}
                            data-testid={`dismiss-park-${row.id}`}
                            onClick={() =>
                              runAction(async () => {
                                const result = await reviewCandidatePark(
                                  citySlug,
                                  row.id,
                                  "dismiss",
                                );
                                if (result.ok) patchPark(row.id, "dismissed");
                                return result;
                              })
                            }
                          >
                            Dismiss
                          </button>
                        </>
                      ) : (
                        <span className="cell-muted">Reviewed</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </section>
      ) : null}

      {tab === "routes" ? (
        <section aria-label="Route inference" data-testid="intelligence-routes">
          {routes.length === 0 ? (
            <p className="empty-inline">
              No route inference candidates for this city.
            </p>
          ) : (
            <table className="data-table">
              <thead>
                <tr>
                  <th>Mode</th>
                  <th>Trips</th>
                  <th>Origin</th>
                  <th>Destination</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {routes.map((row) => (
                  <tr key={row.id} data-testid={`route-row-${row.id}`}>
                    <td>{row.mode_code ?? "—"}</td>
                    <td>{row.supporting_trip_count}</td>
                    <td>
                      {formatCoordinates(row.origin_lat, row.origin_lng)}
                      {row.origin_lat != null && row.origin_lng != null ? (
                        <>
                          {" "}
                          <Link
                            href={graphMapLink(
                              citySlug,
                              row.origin_lat,
                              row.origin_lng,
                            )}
                          >
                            Map
                          </Link>
                        </>
                      ) : null}
                    </td>
                    <td>
                      {formatCoordinates(
                        row.destination_lat,
                        row.destination_lng,
                      )}
                      {row.destination_lat != null &&
                      row.destination_lng != null ? (
                        <>
                          {" "}
                          <Link
                            href={graphMapLink(
                              citySlug,
                              row.destination_lat,
                              row.destination_lng,
                            )}
                          >
                            Map
                          </Link>
                        </>
                      ) : null}
                    </td>
                    <td>
                      {routeInferenceStatusLabel(row.status)}
                      {row.route_id ? (
                        <>
                          {" "}
                          <Link href={`/${citySlug}/graph`}>
                            route {row.route_id.slice(0, 8)}…
                          </Link>
                        </>
                      ) : null}
                    </td>
                    <td>
                      {row.status === "new" ? (
                        <>
                          <button
                            type="button"
                            disabled={pending}
                            data-testid={`promote-route-${row.id}`}
                            onClick={() =>
                              runAction(async () => {
                                const result = await reviewRouteInference(
                                  citySlug,
                                  row.id,
                                  "promote",
                                );
                                if (result.ok) {
                                  const routeId =
                                    typeof result.payload?.route_id === "string"
                                      ? result.payload.route_id
                                      : null;
                                  patchRoute(
                                    row.id,
                                    "promoted_to_route",
                                    routeId,
                                  );
                                }
                                return result;
                              })
                            }
                          >
                            Promote
                          </button>{" "}
                          <button
                            type="button"
                            disabled={pending}
                            data-testid={`dismiss-route-${row.id}`}
                            onClick={() =>
                              runAction(async () => {
                                const result = await reviewRouteInference(
                                  citySlug,
                                  row.id,
                                  "dismiss",
                                );
                                if (result.ok) patchRoute(row.id, "dismissed");
                                return result;
                              })
                            }
                          >
                            Dismiss
                          </button>
                        </>
                      ) : (
                        <span className="cell-muted">Reviewed</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </section>
      ) : null}

      {tab === "geometry" ? (
        <section
          aria-label="Geometry corrections"
          data-testid="intelligence-geometry"
        >
          <p
            style={{
              margin: "0 0 var(--space-4)",
              fontSize: "0.875rem",
              color: "var(--color-text-muted)",
            }}
          >
            Promote marks a correction as reviewed for manual OSM contribution.
            Nothing is written to OpenStreetMap automatically.
          </p>
          {geometry.length === 0 ? (
            <p className="empty-inline">
              No geometry correction candidates for this city.
            </p>
          ) : (
            <table className="data-table">
              <thead>
                <tr>
                  <th>Supporting traces</th>
                  <th>Created</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {geometry.map((row) => (
                  <tr key={row.id} data-testid={`geometry-row-${row.id}`}>
                    <td>{row.supporting_trace_count}</td>
                    <td>{new Date(row.created_at).toLocaleString()}</td>
                    <td>{geometryStatusLabel(row.status)}</td>
                    <td>
                      {row.status === "candidate" ? (
                        <>
                          <button
                            type="button"
                            disabled={pending}
                            data-testid={`promote-geometry-${row.id}`}
                            onClick={() =>
                              runAction(async () => {
                                const result = await reviewGeometryCorrection(
                                  citySlug,
                                  row.id,
                                  "promote",
                                );
                                if (result.ok)
                                  patchGeometry(row.id, "reviewed_for_osm");
                                return result;
                              })
                            }
                          >
                            Promote
                          </button>{" "}
                          <button
                            type="button"
                            disabled={pending}
                            data-testid={`dismiss-geometry-${row.id}`}
                            onClick={() =>
                              runAction(async () => {
                                const result = await reviewGeometryCorrection(
                                  citySlug,
                                  row.id,
                                  "dismiss",
                                );
                                if (result.ok)
                                  patchGeometry(row.id, "rejected");
                                return result;
                              })
                            }
                          >
                            Dismiss
                          </button>
                        </>
                      ) : (
                        <span className="cell-muted">Reviewed</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </section>
      ) : null}
    </div>
  );
}
