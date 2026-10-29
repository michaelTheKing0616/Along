"use client";

import { useMemo, useState, useTransition } from "react";
import { GraphMapClient } from "./graph-map-client";
import type { PendingGraphChange } from "@/lib/graph/types";
import { pendingChangeKey } from "@/lib/graph/types";
import type { GraphCorridor, GraphPark, GraphRoute, GraphStage } from "./page";
import {
  applyGraphImport,
  dryRunGraphImport,
  saveGraphEntity,
} from "./actions";

interface GraphEditorProps {
  citySlug: string;
  cityId: string;
  parkNames: string[];
  graph: {
    corridors: GraphCorridor[];
    routes: GraphRoute[];
    stages: GraphStage[];
    parks: GraphPark[];
    mapRoutes: import("@/lib/graph/types").GraphMapRoute[];
    mapParks: import("@/lib/graph/types").GraphMapPoint[];
    mapStages: import("@/lib/graph/types").GraphMapPoint[];
    mapCenter: { lat: number; lng: number };
  };
}

type Selected =
  | { kind: "park"; id: string }
  | { kind: "route"; id: string }
  | { kind: "stage"; id: string }
  | null;

function TierBadge({
  status,
  confidence,
}: {
  status: string;
  confidence: number;
}) {
  return (
    <span
      className={`badge badge-${status.replace("_", "-")}`}
      title={`confidence ${confidence}`}
    >
      {status.replace("_", " ")}
    </span>
  );
}

function validateStageSequence(
  stage: GraphStage,
  nextSequence: number,
  stagesOnRoute: GraphStage[],
): string | null {
  if (!Number.isFinite(nextSequence) || nextSequence < 1) {
    return "Sequence must be a positive integer.";
  }
  const duplicate = stagesOnRoute.some(
    (s) => s.id !== stage.id && s.sequence === nextSequence,
  );
  if (duplicate) {
    return "Another stage on this route already uses that sequence (adjacency/order conflict).";
  }
  return null;
}

export function GraphEditor({
  citySlug,
  cityId,
  parkNames,
  graph,
}: GraphEditorProps) {
  const [selected, setSelected] = useState<Selected>(null);
  const [treeQuery, setTreeQuery] = useState("");
  const [openRoutes, setOpenRoutes] = useState<Set<string>>(new Set());
  const q = treeQuery.trim().toLowerCase();
  const hit = (name: string | null | undefined) =>
    !q || (name ?? "").toLowerCase().includes(q);
  const toggleRoute = (id: string) =>
    setOpenRoutes((current) => {
      const next = new Set(current);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  const [editName, setEditName] = useState("");
  const [editSequence, setEditSequence] = useState("");
  const [editActive, setEditActive] = useState(true);
  const [pending, setPending] = useState<Record<string, PendingGraphChange>>(
    {},
  );
  const [pendingStagePositions, setPendingStagePositions] = useState<
    Record<string, { lat: number; lng: number }>
  >({});
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [csvText, setCsvText] = useState("");
  const [importDiff, setImportDiff] = useState<Array<
    Record<string, unknown>
  > | null>(null);
  const [isPending, startTransition] = useTransition();

  const parkById = useMemo(
    () => new Map(graph.parks.map((p) => [p.id, p])),
    [graph.parks],
  );
  const stageById = useMemo(
    () => new Map(graph.stages.map((s) => [s.id, s])),
    [graph.stages],
  );
  const routeById = useMemo(
    () => new Map(graph.routes.map((r) => [r.id, r])),
    [graph.routes],
  );

  const routesByCorridor = useMemo(() => {
    const map = new Map<string, GraphRoute[]>();
    for (const route of graph.routes) {
      const key = route.corridor_id ?? "uncorridor";
      const list = map.get(key) ?? [];
      list.push(route);
      map.set(key, list);
    }
    return map;
  }, [graph.routes]);

  const stagesByRoute = useMemo(() => {
    const map = new Map<string, GraphStage[]>();
    for (const stage of graph.stages) {
      const list = map.get(stage.route_id) ?? [];
      list.push(stage);
      map.set(stage.route_id, list);
    }
    for (const [, list] of map) {
      list.sort((a, b) => a.sequence - b.sequence);
    }
    return map;
  }, [graph.stages]);

  const pendingList = useMemo(() => Object.values(pending), [pending]);

  function queueChange(change: PendingGraphChange) {
    setPending((prev) => ({ ...prev, [pendingChangeKey(change)]: change }));
    setMessage(null);
    setError(null);
  }

  function selectPark(park: GraphPark) {
    setSelected({ kind: "park", id: park.id });
    setEditName(park.name);
    setMessage(null);
    setError(null);
  }

  function selectRoute(route: GraphRoute) {
    setSelected({ kind: "route", id: route.id });
    setEditName(route.name ?? "");
    setEditActive(route.active);
    setMessage(null);
    setError(null);
  }

  function selectStage(stage: GraphStage) {
    setSelected({ kind: "stage", id: stage.id });
    setEditName(stage.name ?? "");
    setEditSequence(String(stage.sequence));
    setMessage(null);
    setError(null);
  }

  function queueCurrentEdit() {
    if (!selected) return;

    if (selected.kind === "park") {
      const park = parkById.get(selected.id);
      if (!park) return;
      queueChange({
        kind: "park",
        id: park.id,
        label: park.name,
        payload: {
          name: editName,
          ...(pendingStagePositions[park.id]
            ? {
                lat: pendingStagePositions[park.id]?.lat,
                lng: pendingStagePositions[park.id]?.lng,
              }
            : {}),
        },
      });
      return;
    }

    if (selected.kind === "route") {
      const route = routeById.get(selected.id);
      if (!route) return;
      queueChange({
        kind: "route",
        id: route.id,
        label: route.name ?? route.mode_code,
        payload: { name: editName || null, active: editActive },
      });
      return;
    }

    const stage = stageById.get(selected.id);
    if (!stage) return;
    const sequence = Number(editSequence);
    const validation = validateStageSequence(
      stage,
      sequence,
      stagesByRoute.get(stage.route_id) ?? [],
    );
    if (validation) {
      setError(validation);
      return;
    }

    const dragged = pendingStagePositions[stage.id];
    queueChange({
      kind: "route_stage",
      id: stage.id,
      label: stage.name ?? `#${stage.sequence}`,
      payload: {
        name: editName || null,
        sequence,
        ...(dragged ? { lat: dragged.lat, lng: dragged.lng } : {}),
      },
    });
  }

  function savePending(change: PendingGraphChange) {
    setMessage(null);
    setError(null);
    startTransition(async () => {
      const result = await saveGraphEntity(citySlug, change);
      if (result.ok) {
        setMessage(result.message);
        setPending((prev) => {
          const next = { ...prev };
          delete next[pendingChangeKey(change)];
          return next;
        });
        if (change.kind === "route_stage" && change.payload.lat != null) {
          setPendingStagePositions((prev) => {
            const next = { ...prev };
            delete next[change.id];
            return next;
          });
        }
      } else {
        setError(result.error);
      }
    });
  }

  function onStageDrag(stageId: string, lat: number, lng: number) {
    setPendingStagePositions((prev) => ({ ...prev, [stageId]: { lat, lng } }));
    const stage = stageById.get(stageId);
    if (!stage) return;
    setSelected({ kind: "stage", id: stageId });
    setEditName(stage.name ?? "");
    setEditSequence(String(stage.sequence));
    queueChange({
      kind: "route_stage",
      id: stageId,
      label: stage.name ?? `#${stage.sequence}`,
      payload: {
        name: stage.name,
        sequence: stage.sequence,
        lat,
        lng,
      },
    });
  }

  function runImportDryRun() {
    setMessage(null);
    setError(null);
    startTransition(async () => {
      const result = await dryRunGraphImport(cityId, csvText);
      if (result.ok) {
        setImportDiff(result.diff);
      } else {
        setError(result.error);
        setImportDiff(null);
      }
    });
  }

  function runImportApply() {
    if (!importDiff) return;
    setMessage(null);
    setError(null);
    startTransition(async () => {
      const result = await applyGraphImport(citySlug, cityId, importDiff);
      if (result.ok) {
        setMessage(
          `CSV import applied: ${result.created} created, ${result.skipped} skipped.`,
        );
        setImportDiff(null);
        setCsvText("");
      } else {
        setError(result.error);
      }
    });
  }

  return (
    <div data-testid="graph-editor">
      {error ? (
        <div className="error-banner" role="alert">
          {error}
        </div>
      ) : null}
      {message ? (
        <div
          className="card"
          role="status"
          data-testid="graph-success"
          style={{ marginBottom: "var(--space-4)", fontSize: "0.875rem" }}
        >
          {message}
        </div>
      ) : null}

      <section style={{ marginBottom: "var(--space-6)" }}>
        <GraphMapClient
          center={graph.mapCenter}
          parks={graph.mapParks}
          stages={graph.mapStages}
          routes={graph.mapRoutes}
          pendingStagePositions={pendingStagePositions}
          onStageDrag={onStageDrag}
          onSelectStage={(stageId) => {
            const stage = stageById.get(stageId);
            if (stage) selectStage(stage);
          }}
          onSelectPark={(parkId) => {
            const park = parkById.get(parkId);
            if (park) selectPark(park);
          }}
        />
        <p
          style={{
            fontSize: "0.8125rem",
            color: "var(--color-text-muted)",
            marginTop: "var(--space-2)",
          }}
        >
          Drag a stage marker to adjust location (saved through the pending
          changes tray).
        </p>
      </section>

      <div className="split">
        <section>
          <div className="tree-head">
            <h2 className="section-title">Corridors, routes and stages</h2>
            <input
              type="search"
              className="tree-search"
              placeholder="Search by name"
              aria-label="Search corridors, routes, stages and parks"
              value={treeQuery}
              onChange={(event) => setTreeQuery(event.target.value)}
            />
          </div>
          {graph.corridors.length === 0 ? (
            <p
              style={{ color: "var(--color-text-muted)", fontSize: "0.875rem" }}
            >
              No corridors seeded.
            </p>
          ) : (
            <ul
              className="tree-list"
              style={{ listStyle: "none", padding: 0, margin: 0 }}
            >
              {graph.corridors.map((corridor) => {
                const routes = (routesByCorridor.get(corridor.id) ?? []).filter(
                  (route) =>
                    hit(corridor.name) ||
                    hit(route.name ?? route.mode_code) ||
                    (stagesByRoute.get(route.id) ?? []).some((stage) =>
                      hit(stage.name),
                    ),
                );
                if (q && routes.length === 0 && !hit(corridor.name))
                  return null;
                return (
                  <li key={corridor.id} className="tree-corridor">
                    <strong>{corridor.name}</strong>{" "}
                    <span className="badge">
                      {corridor.status.replace(/_/g, " ")}
                    </span>
                    <ul
                      style={{
                        listStyle: "none",
                        paddingLeft: "var(--space-4)",
                        margin: "var(--space-2) 0 0",
                      }}
                    >
                      {routes.map((route) => {
                        const stages = (
                          stagesByRoute.get(route.id) ?? []
                        ).filter(
                          (stage) =>
                            !q ||
                            hit(stage.name) ||
                            hit(route.name) ||
                            hit(corridor.name),
                        );
                        const open =
                          openRoutes.has(route.id) ||
                          (q !== "" && stages.length > 0);
                        return (
                          <li
                            key={route.id}
                            style={{ marginBottom: "var(--space-2)" }}
                          >
                            <div className="tree-row">
                              <button
                                type="button"
                                className="tree-toggle"
                                aria-expanded={open}
                                aria-label={`${open ? "Hide" : "Show"} stages`}
                                onClick={() => toggleRoute(route.id)}
                              >
                                {open ? "▾" : "▸"}
                              </button>
                              <button
                                type="button"
                                className="tree-button"
                                data-testid={`graph-route-${route.id}`}
                                onClick={() => selectRoute(route)}
                              >
                                {route.name ?? `${route.mode_code} route`}{" "}
                                <TierBadge
                                  status={route.verification_status}
                                  confidence={route.confidence_score}
                                />
                              </button>
                              <span className="tree-count">
                                {stages.length} stages
                              </span>
                            </div>
                            {open ? (
                              <ul
                                style={{
                                  listStyle: "none",
                                  paddingLeft: "var(--space-4)",
                                  margin: "var(--space-1) 0 0",
                                }}
                              >
                                {stages.map((stage) => (
                                  <li key={stage.id}>
                                    <button
                                      type="button"
                                      className="tree-button"
                                      data-testid={`graph-stage-${stage.id}`}
                                      onClick={() => selectStage(stage)}
                                    >
                                      #{stage.sequence} {stage.name ?? "stage"}{" "}
                                      <TierBadge
                                        status={stage.verification_status}
                                        confidence={stage.confidence_score}
                                      />
                                    </button>
                                  </li>
                                ))}
                              </ul>
                            ) : null}
                          </li>
                        );
                      })}
                    </ul>
                  </li>
                );
              })}
            </ul>
          )}

          <h2 className="section-title section-gap">Parks</h2>
          <ul
            className="tree-list"
            style={{ listStyle: "none", padding: 0, margin: 0 }}
          >
            {graph.parks
              .filter((park) => hit(park.name))
              .map((park) => (
                <li key={park.id} style={{ marginBottom: "var(--space-1)" }}>
                  <button
                    type="button"
                    className="tree-button"
                    data-testid={`graph-park-${park.id}`}
                    onClick={() => selectPark(park)}
                  >
                    {park.name}{" "}
                    <TierBadge
                      status={park.verification_status}
                      confidence={park.confidence_score}
                    />
                  </button>
                </li>
              ))}
          </ul>
        </section>

        <section className="card split-detail" data-testid="graph-edit-panel">
          <h2 className="section-title">Edit selected entity</h2>
          {!selected ? (
            <p
              style={{ color: "var(--color-text-muted)", fontSize: "0.875rem" }}
            >
              Select a park, route, or stage from the tree or map.
            </p>
          ) : (
            <>
              <p
                style={{
                  fontSize: "0.8125rem",
                  color: "var(--color-text-muted)",
                }}
              >
                Editing {selected.kind} <code>{selected.id}</code>
              </p>
              <div className="field">
                <label htmlFor="graph-edit-name">Name</label>
                <input
                  id="graph-edit-name"
                  value={editName}
                  onChange={(e) => setEditName(e.target.value)}
                  data-testid="graph-edit-name"
                />
              </div>
              {selected.kind === "stage" ? (
                <div className="field">
                  <label htmlFor="graph-edit-sequence">Sequence</label>
                  <input
                    id="graph-edit-sequence"
                    value={editSequence}
                    onChange={(e) => setEditSequence(e.target.value)}
                    data-testid="graph-edit-sequence"
                  />
                </div>
              ) : null}
              {selected.kind === "route" ? (
                <label
                  style={{
                    display: "flex",
                    gap: "var(--space-2)",
                    alignItems: "center",
                    marginBottom: "var(--space-4)",
                  }}
                >
                  <input
                    type="checkbox"
                    checked={editActive}
                    onChange={(e) => setEditActive(e.target.checked)}
                  />
                  Active route
                </label>
              ) : null}
              {selected.kind === "park" ? (
                <p
                  style={{
                    fontSize: "0.8125rem",
                    color: "var(--color-text-muted)",
                  }}
                >
                  Aliases:{" "}
                  {(parkById.get(selected.id)?.name_aliases ?? []).join(", ") ||
                    "—"}
                </p>
              ) : null}
              <button
                type="button"
                className="btn btn-secondary"
                data-testid="graph-queue-change"
                onClick={queueCurrentEdit}
              >
                Add to pending changes
              </button>
            </>
          )}
        </section>
      </div>

      <section
        className="card"
        style={{ marginTop: "var(--space-6)" }}
        data-testid="graph-pending-tray"
      >
        <h2 className="section-title">Pending changes</h2>
        {pendingList.length === 0 ? (
          <p style={{ color: "var(--color-text-muted)", fontSize: "0.875rem" }}>
            No pending edits.
          </p>
        ) : (
          <ul style={{ listStyle: "none", padding: 0, margin: 0 }}>
            {pendingList.map((change) => (
              <li
                key={pendingChangeKey(change)}
                style={{
                  display: "flex",
                  gap: "var(--space-3)",
                  alignItems: "center",
                  marginBottom: "var(--space-2)",
                  fontSize: "0.875rem",
                }}
              >
                <span>
                  {change.kind} <strong>{change.label}</strong>
                </span>
                <button
                  type="button"
                  className="btn btn-primary"
                  data-testid={`graph-save-${change.kind}-${change.id}`}
                  disabled={isPending}
                  onClick={() => savePending(change)}
                >
                  Save (RPC)
                </button>
              </li>
            ))}
          </ul>
        )}
      </section>

      <section className="card" style={{ marginTop: "var(--space-6)" }}>
        <h2 className="section-title">Bulk parks CSV import</h2>
        <p
          style={{
            margin: "0 0 var(--space-3)",
            fontSize: "0.875rem",
            color: "var(--color-text-muted)",
          }}
        >
          Format: <code>name,lat,lng</code>. Runs{" "}
          <code>admin_import_dry_run</code> then <code>admin_import_apply</code>
          .
        </p>
        <textarea
          value={csvText}
          onChange={(e) => setCsvText(e.target.value)}
          rows={4}
          style={{ width: "100%", marginBottom: "var(--space-3)" }}
          data-testid="graph-csv-input"
          placeholder="name,lat,lng"
        />
        <div style={{ display: "flex", gap: "var(--space-3)" }}>
          <button
            type="button"
            className="btn btn-secondary"
            data-testid="graph-import-dry-run"
            disabled={isPending}
            onClick={runImportDryRun}
          >
            Dry-run diff
          </button>
          <button
            type="button"
            className="btn btn-primary"
            data-testid="graph-import-apply"
            disabled={
              isPending || !importDiff?.some((row) => row.action === "create")
            }
            onClick={runImportApply}
          >
            Apply import
          </button>
        </div>
        {importDiff ? (
          <table
            style={{
              width: "100%",
              marginTop: "var(--space-4)",
              fontSize: "0.8125rem",
            }}
            data-testid="graph-import-diff"
          >
            <thead>
              <tr>
                <th align="left">Name</th>
                <th align="left">Action</th>
                <th align="left">Reason</th>
              </tr>
            </thead>
            <tbody>
              {importDiff.map((row) => (
                <tr
                  key={String(row.name)}
                  data-testid={`graph-import-row-${String(row.name)}`}
                >
                  <td>{String(row.name)}</td>
                  <td>{String(row.action)}</td>
                  <td>{String(row.reason ?? "—")}</td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : null}
        <p
          style={{
            marginTop: "var(--space-3)",
            fontSize: "0.8125rem",
            color: "var(--color-text-muted)",
          }}
        >
          Existing parks in city: {parkNames.length}
        </p>
      </section>
    </div>
  );
}
