"use client";

import { useMemo, useState, useTransition } from "react";
import type {
  FieldReconciliationRow,
  FieldSubmissionPayload,
} from "@/lib/field/types";
import { publishFieldEntity, reconcileFieldEntity } from "./actions";
import { humanize, shortId } from "@/lib/ui/label";

interface FieldQueueProps {
  citySlug: string;
  initialRows: FieldReconciliationRow[];
}

function formatPayload(payload: FieldSubmissionPayload | undefined): string {
  if (!payload) return "—";
  const parts: string[] = [];
  if (payload.name) parts.push(`name: ${payload.name}`);
  if (payload.lat != null && payload.lng != null) {
    parts.push(`loc: ${payload.lat}, ${payload.lng}`);
  }
  if (payload.fare_amount != null) parts.push(`fare: ${payload.fare_amount}`);
  return parts.length > 0 ? parts.join(" · ") : JSON.stringify(payload);
}

function ScoutPanel({
  label,
  scoutId,
  payload,
  submittedAt,
}: {
  label: string;
  scoutId: string;
  payload: FieldSubmissionPayload;
  submittedAt: string;
}) {
  return (
    <div className="card" style={{ flex: 1 }}>
      <h3 className="sub-title">{label}</h3>
      <p
        style={{
          margin: "0 0 var(--space-2)",
          fontSize: "0.8125rem",
          color: "var(--color-text-muted)",
        }}
      >
        Scout {scoutId.slice(0, 8)}… · {new Date(submittedAt).toLocaleString()}
      </p>
      <pre
        style={{
          margin: 0,
          fontSize: "0.8125rem",
          fontFamily: "var(--font-mono)",
          whiteSpace: "pre-wrap",
        }}
      >
        {formatPayload(payload)}
      </pre>
    </div>
  );
}

export function FieldQueue({ citySlug, initialRows }: FieldQueueProps) {
  const [rows, setRows] = useState(initialRows);
  const [selectedId, setSelectedId] = useState<string | null>(
    initialRows[0]?.id ?? null,
  );
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [resolveName, setResolveName] = useState("");
  const [resolveLat, setResolveLat] = useState("");
  const [resolveLng, setResolveLng] = useState("");
  const [pending, startTransition] = useTransition();

  const selected = useMemo(
    () => rows.find((r) => r.id === selectedId) ?? null,
    [rows, selectedId],
  );

  function refreshLocal(id: string, patch: Partial<FieldReconciliationRow>) {
    setRows((prev) => prev.map((r) => (r.id === id ? { ...r, ...patch } : r)));
  }

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

  const canPublish =
    selected &&
    (selected.status === "matched" || selected.status === "resolved") &&
    !selected.published_target_id;

  return (
    <div data-testid="field-queue">
      {error ? (
        <div className="error-banner" role="alert" data-testid="field-error">
          {error}
        </div>
      ) : null}
      {message ? (
        <div
          className="card"
          role="status"
          data-testid="field-success"
          style={{
            marginBottom: "var(--space-4)",
            borderColor: "var(--color-primary)",
            fontSize: "0.875rem",
          }}
        >
          {message}
        </div>
      ) : null}

      {rows.length === 0 ? (
        <p className="empty-inline">No field reconciliations for this city.</p>
      ) : (
        <div className="split field-split">
          <table
            className="data-table"
            data-testid="field-reconciliation-table"
          >
            <thead>
              <tr>
                <th>Entity key</th>
                <th>Type</th>
                <th>Status</th>
                <th>Variance</th>
                <th>Published</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr
                  key={row.id}
                  data-testid={`field-row-${row.entity_key}`}
                  onClick={() => setSelectedId(row.id)}
                  style={{
                    cursor: "pointer",
                    background:
                      row.id === selectedId ? "var(--color-bg)" : undefined,
                  }}
                >
                  <td>{row.entity_key}</td>
                  <td>{row.entity_type}</td>
                  <td>
                    <span className={`badge badge-${row.status}`}>
                      {humanize(row.status)}
                    </span>
                  </td>
                  <td>
                    {row.variance?.location_m != null
                      ? `${row.variance.location_m} m`
                      : row.variance?.fare_pct != null
                        ? `${(row.variance.fare_pct * 100).toFixed(1)}%`
                        : "—"}
                  </td>
                  <td>
                    {row.published_target_id ? row.published_target_type : "—"}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          {selected ? (
            <section className="split-detail" data-testid="field-detail">
              <h2 className="section-title">{selected.entity_key}</h2>

              <div
                style={{
                  display: "flex",
                  gap: "var(--space-4)",
                  flexWrap: "wrap",
                }}
              >
                {selected.sub_a ? (
                  <ScoutPanel
                    label="Scout A"
                    scoutId={selected.sub_a.scout_profile_id}
                    payload={selected.sub_a.payload}
                    submittedAt={selected.sub_a.submitted_at}
                  />
                ) : null}
                {selected.sub_b ? (
                  <ScoutPanel
                    label="Scout B"
                    scoutId={selected.sub_b.scout_profile_id}
                    payload={selected.sub_b.payload}
                    submittedAt={selected.sub_b.submitted_at}
                  />
                ) : null}
              </div>

              <div
                style={{
                  display: "flex",
                  flexWrap: "wrap",
                  gap: "var(--space-2)",
                  marginTop: "var(--space-4)",
                }}
              >
                {selected.status === "discrepant" ? (
                  <>
                    <button
                      type="button"
                      className="btn btn-primary"
                      disabled={pending || !selected.sub_b}
                      onClick={() =>
                        runAction(async () => {
                          const result = await reconcileFieldEntity(
                            citySlug,
                            selected.id,
                            "match",
                          );
                          if (result.ok)
                            refreshLocal(selected.id, { status: "matched" });
                          return result;
                        })
                      }
                    >
                      Merge (match)
                    </button>
                    <button
                      type="button"
                      className="btn"
                      disabled={pending}
                      onClick={() =>
                        runAction(async () => {
                          const result = await reconcileFieldEntity(
                            citySlug,
                            selected.id,
                            "discrepant",
                          );
                          return result;
                        })
                      }
                    >
                      Mark discrepant
                    </button>
                  </>
                ) : null}

                {selected.status === "matched" ||
                selected.status === "discrepant" ? (
                  <button
                    type="button"
                    className="btn"
                    disabled={pending}
                    onClick={() =>
                      runAction(async () => {
                        const result = await reconcileFieldEntity(
                          citySlug,
                          selected.id,
                          "reject",
                        );
                        if (result.ok)
                          refreshLocal(selected.id, { status: "rejected" });
                        return result;
                      })
                    }
                  >
                    Reject
                  </button>
                ) : null}

                {canPublish ? (
                  <button
                    type="button"
                    className="btn btn-primary"
                    disabled={pending}
                    data-testid="publish-field-entity"
                    onClick={() =>
                      runAction(async () => {
                        const result = await publishFieldEntity(
                          citySlug,
                          selected.id,
                        );
                        if (result.ok) {
                          refreshLocal(selected.id, {
                            published_target_type: selected.entity_type,
                            published_target_id: "published",
                          });
                        }
                        return result;
                      })
                    }
                  >
                    Publish to field_verified
                  </button>
                ) : null}
              </div>

              {selected.status === "discrepant" ? (
                <div className="card" style={{ marginTop: "var(--space-4)" }}>
                  <h3 className="sub-title">Resolve with chosen values</h3>
                  <div className="field">
                    <label htmlFor="resolve-name">Name</label>
                    <input
                      id="resolve-name"
                      value={resolveName}
                      onChange={(e) => setResolveName(e.target.value)}
                      placeholder={selected.sub_a?.payload.name ?? "Park name"}
                    />
                  </div>
                  <div style={{ display: "flex", gap: "var(--space-4)" }}>
                    <div className="field" style={{ flex: 1 }}>
                      <label htmlFor="resolve-lat">Lat</label>
                      <input
                        id="resolve-lat"
                        value={resolveLat}
                        onChange={(e) => setResolveLat(e.target.value)}
                        placeholder={String(selected.sub_a?.payload.lat ?? "")}
                      />
                    </div>
                    <div className="field" style={{ flex: 1 }}>
                      <label htmlFor="resolve-lng">Lng</label>
                      <input
                        id="resolve-lng"
                        value={resolveLng}
                        onChange={(e) => setResolveLng(e.target.value)}
                        placeholder={String(selected.sub_a?.payload.lng ?? "")}
                      />
                    </div>
                  </div>
                  <button
                    type="button"
                    className="btn btn-primary"
                    disabled={pending}
                    data-testid="resolve-field-entity"
                    onClick={() =>
                      runAction(async () => {
                        const payload = {
                          name: resolveName || selected.sub_a?.payload.name,
                          lat: Number(
                            resolveLat || selected.sub_a?.payload.lat,
                          ),
                          lng: Number(
                            resolveLng || selected.sub_a?.payload.lng,
                          ),
                          name_aliases:
                            selected.sub_a?.payload.name_aliases ?? [],
                        };
                        const result = await reconcileFieldEntity(
                          citySlug,
                          selected.id,
                          "resolve",
                          { payload },
                        );
                        if (result.ok)
                          refreshLocal(selected.id, { status: "resolved" });
                        return result;
                      })
                    }
                  >
                    Resolve &amp; mark resolved
                  </button>
                </div>
              ) : null}

              {selected.published_target_id ? (
                <p
                  data-testid="field-published-status"
                  className="note"
                  style={{ marginTop: "var(--space-4)" }}
                >
                  Published as <strong>{selected.published_target_type}</strong>{" "}
                  <code title={selected.published_target_id ?? undefined}>
                    {shortId(selected.published_target_id)}
                  </code>
                </p>
              ) : null}
            </section>
          ) : null}
        </div>
      )}
    </div>
  );
}
