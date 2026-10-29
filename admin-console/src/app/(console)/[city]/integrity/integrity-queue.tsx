"use client";

import Link from "next/link";
import { useMemo, useState, useTransition } from "react";
import {
  evidenceBullets,
  flagTypeLabel,
  scorePct,
} from "@/lib/integrity/format";
import type { IntegrityFlagRow } from "@/lib/integrity/types";
import { STANDING_OPTIONS } from "@/lib/integrity/types";
import { clearIntegrityFlag, transitionStandingAndActionFlag } from "./actions";
import { humanize } from "@/lib/ui/label";

interface IntegrityQueueProps {
  citySlug: string;
  initialRows: IntegrityFlagRow[];
  initialSelectedId: string | null;
  canActionFlag: boolean;
}

export function IntegrityQueue({
  citySlug,
  initialRows,
  initialSelectedId,
  canActionFlag,
}: IntegrityQueueProps) {
  const [rows, setRows] = useState(initialRows);
  const [selectedId, setSelectedId] = useState<string | null>(
    initialSelectedId,
  );
  const [note, setNote] = useState("");
  const [showStandingDialog, setShowStandingDialog] = useState(false);
  const [toStanding, setToStanding] = useState<string>(
    STANDING_OPTIONS[0].value,
  );
  const [reason, setReason] = useState("");
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();

  const selected = useMemo(
    () => rows.find((r) => r.id === selectedId) ?? null,
    [rows, selectedId],
  );

  function refreshLocal(id: string, status: IntegrityFlagRow["status"]) {
    setRows((prev) => prev.map((r) => (r.id === id ? { ...r, status } : r)));
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
        setShowStandingDialog(false);
      } else {
        setError(result.error ?? "Action failed.");
      }
    });
  }

  return (
    <div data-testid="integrity-queue">
      {error ? (
        <div
          className="error-banner"
          role="alert"
          data-testid="integrity-error"
        >
          {error}
        </div>
      ) : null}
      {message ? (
        <div
          className="card"
          role="status"
          data-testid="integrity-success"
          style={{ marginBottom: "var(--space-4)", fontSize: "0.875rem" }}
        >
          {message}
        </div>
      ) : null}

      {rows.length === 0 ? (
        <p className="empty-inline">No integrity flags for this city.</p>
      ) : (
        <div className="split">
          <table className="data-table" data-testid="integrity-table">
            <thead>
              <tr>
                <th>Score</th>
                <th>Type</th>
                <th>Driver</th>
                <th>Corroborating</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr
                  key={row.id}
                  data-testid={`integrity-row-${row.id}`}
                  onClick={() => {
                    setSelectedId(row.id);
                    setShowStandingDialog(false);
                    setReason("");
                  }}
                  style={{
                    cursor: "pointer",
                    background:
                      row.id === selectedId ? "var(--color-bg)" : undefined,
                  }}
                >
                  <td>{scorePct(row.score)}</td>
                  <td>{flagTypeLabel(row.flag_type)}</td>
                  <td>
                    {row.driver_name ??
                      row.driver_code ??
                      row.driver_id.slice(0, 8)}
                  </td>
                  <td data-testid={`corroborating-${row.id}`}>
                    {row.corroborating_rider_count}
                  </td>
                  <td>
                    <span className={`badge badge-${row.status}`}>
                      {humanize(row.status)}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          {selected ? (
            <section className="split-detail" data-testid="integrity-detail">
              <h2 className="section-title">Flag detail</h2>

              <div className="card" style={{ marginBottom: "var(--space-4)" }}>
                <dl
                  style={{
                    margin: 0,
                    display: "grid",
                    gridTemplateColumns: "max-content 1fr",
                    gap: "var(--space-2) var(--space-4)",
                    fontSize: "0.875rem",
                  }}
                >
                  <dt>Trip</dt>
                  <dd>
                    <code>{selected.trip_id}</code>
                  </dd>
                  <dt>Driver</dt>
                  <dd>
                    <Link href={`/${citySlug}/drivers/${selected.driver_id}`}>
                      {selected.driver_name ??
                        selected.driver_code ??
                        selected.driver_id}
                    </Link>
                  </dd>
                  <dt>Rider trace</dt>
                  <dd>{selected.rider_trace_quality}</dd>
                  <dt>Corroborating riders</dt>
                  <dd data-testid="corroborating-count">
                    {selected.corroborating_rider_count}
                  </dd>
                  {selected.risk_cancel_rate != null ? (
                    <>
                      <dt>30d cancel rate</dt>
                      <dd>
                        {(selected.risk_cancel_rate * 100).toFixed(1)}% · open
                        flags {selected.risk_open_flags ?? 0}
                      </dd>
                    </>
                  ) : null}
                </dl>

                <h3 className="sub-title">Evidence</h3>
                <ul
                  data-testid="evidence-list"
                  style={{
                    margin: 0,
                    paddingLeft: "var(--space-5)",
                    fontSize: "0.875rem",
                  }}
                >
                  {evidenceBullets(selected.evidence).map((item) => (
                    <li key={item}>{item}</li>
                  ))}
                </ul>

                <p
                  style={{
                    margin: "var(--space-4) 0 0",
                    fontSize: "0.8125rem",
                    color: "var(--color-text-muted)",
                  }}
                >
                  Review the evidence and the trip timeline before acting.
                </p>
              </div>

              {selected.status === "open" ? (
                <>
                  <div className="decision-row">
                    <button
                      type="button"
                      className="btn"
                      disabled={pending}
                      data-testid="clear-flag"
                      onClick={() =>
                        runAction(async () => {
                          const result = await clearIntegrityFlag(
                            citySlug,
                            selected.id,
                            note,
                          );
                          if (result.ok) refreshLocal(selected.id, "cleared");
                          return result;
                        })
                      }
                    >
                      Clear
                    </button>
                    {canActionFlag ? (
                      <button
                        type="button"
                        className="btn btn-primary"
                        disabled={pending}
                        data-testid="action-flag"
                        onClick={() => {
                          setShowStandingDialog(true);
                          setReason(
                            `Integrity review: ${flagTypeLabel(selected.flag_type)} (score ${scorePct(selected.score)})`,
                          );
                        }}
                      >
                        Action
                      </button>
                    ) : (
                      <button
                        type="button"
                        className="btn btn-primary"
                        disabled
                        data-testid="action-flag"
                        title="Standing action requires ops lead or finance role"
                      >
                        Action
                      </button>
                    )}
                    <div className="field" style={{ marginBottom: 0 }}>
                      <label htmlFor="integrity-note">Note</label>
                      <input
                        id="integrity-note"
                        value={note}
                        onChange={(e) => setNote(e.target.value)}
                        placeholder="Review note"
                        data-testid="integrity-note"
                      />
                    </div>
                  </div>

                  {canActionFlag && showStandingDialog ? (
                    <div
                      className="card"
                      data-testid="standing-dialog"
                      style={{ marginTop: "var(--space-4)" }}
                    >
                      <h3 className="sub-title">Standing transition</h3>
                      <p
                        style={{
                          fontSize: "0.875rem",
                          color: "var(--color-text-muted)",
                        }}
                      >
                        Human confirmation required. Standing will not change
                        until you submit.
                      </p>
                      <div className="field">
                        <label htmlFor="standing-to">To standing</label>
                        <select
                          id="standing-to"
                          value={toStanding}
                          onChange={(e) => setToStanding(e.target.value)}
                          data-testid="standing-to"
                        >
                          {STANDING_OPTIONS.map((opt) => (
                            <option key={opt.value} value={opt.value}>
                              {opt.label}
                            </option>
                          ))}
                        </select>
                      </div>
                      <div className="field">
                        <label htmlFor="standing-reason">Reason</label>
                        <textarea
                          id="standing-reason"
                          value={reason}
                          onChange={(e) => setReason(e.target.value)}
                          rows={3}
                          data-testid="standing-reason"
                        />
                      </div>
                      <button
                        type="button"
                        className="btn btn-primary"
                        disabled={pending || !reason.trim()}
                        data-testid="confirm-standing-action"
                        onClick={() =>
                          runAction(async () => {
                            const result =
                              await transitionStandingAndActionFlag(
                                citySlug,
                                selected.id,
                                selected.driver_id,
                                toStanding,
                                reason,
                                note,
                              );
                            if (result.ok)
                              refreshLocal(selected.id, "actioned");
                            return result;
                          })
                        }
                      >
                        Apply standing &amp; mark actioned
                      </button>
                    </div>
                  ) : null}
                </>
              ) : null}
            </section>
          ) : null}
        </div>
      )}
    </div>
  );
}
