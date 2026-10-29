"use client";

import React from "react";
import Link from "next/link";
import {
  CONVERSION_DIAGNOSTIC_NOTE,
  formatCount,
  formatRate,
  formatSeconds,
} from "@/lib/analytics/format";
import type {
  OpsDashboardCounts,
  OpsDashboardKpis,
} from "@/lib/analytics/types";

interface OpsDashboardProps {
  citySlug: string;
  windowLabel: string;
  kpis: OpsDashboardKpis;
  counts: OpsDashboardCounts;
}

type Tile = {
  testId: string;
  label: string;
  value: string;
  href?: string;
  hint?: string;
};

export function OpsDashboard({
  citySlug,
  windowLabel,
  kpis,
  counts,
}: OpsDashboardProps) {
  const tiles: Tile[] = [
    {
      testId: "kpi-searches",
      label: "Searches",
      value: formatCount(kpis.searches),
      href: `/${citySlug}/analytics`,
    },
    {
      testId: "kpi-conversion",
      label: "Ambient→commit",
      value: formatRate(kpis.ambient_to_commit_rate),
      href: `/${citySlug}/analytics`,
    },
    {
      testId: "kpi-requests",
      label: "Requests",
      value: formatCount(kpis.requests),
      href: `/${citySlug}/integrity`,
    },
    {
      testId: "kpi-accept-rate",
      label: "Accept rate",
      value: formatRate(kpis.accept_rate),
    },
    {
      testId: "kpi-completed",
      label: "Completed trips",
      value: formatCount(kpis.completed_trips),
    },
    {
      testId: "kpi-wait",
      label: "Median wait",
      value: formatSeconds(kpis.median_wait_s),
    },
    {
      testId: "kpi-fare-discrepancy",
      label: "Fare discrepancy",
      value: formatRate(kpis.fare_discrepancy_rate),
      href: `/${citySlug}/corrections`,
    },
    {
      testId: "kpi-open-sos",
      label: "Open SOS",
      value: formatCount(counts.openSos),
      href: `/${citySlug}/safety`,
    },
    {
      testId: "kpi-open-flags",
      label: "Open flags",
      value: formatCount(counts.openFlags),
      href: `/${citySlug}/integrity`,
    },
    {
      testId: "kpi-verification-queue",
      label: "Verification queue",
      value: formatCount(counts.verificationQueue),
      href: `/${citySlug}/verification`,
    },
    {
      testId: "kpi-drivers-online",
      label: "Drivers online",
      value: formatCount(counts.driversOnline),
      hint: `${counts.driversAtPark} at park · ${counts.driversRoaming} roaming`,
    },
  ];

  const byId = new Map(tiles.map((t) => [t.testId, t]));
  const sections: { title: string; ids: string[]; attention?: boolean }[] = [
    {
      title: "Right now",
      ids: [
        "kpi-open-sos",
        "kpi-open-flags",
        "kpi-verification-queue",
        "kpi-drivers-online",
      ],
      attention: true,
    },
    {
      title: `Demand, last ${windowLabel} across ${kpis.corridors} corridor${kpis.corridors === 1 ? "" : "s"}`,
      ids: [
        "kpi-searches",
        "kpi-requests",
        "kpi-accept-rate",
        "kpi-completed",
        "kpi-wait",
        "kpi-fare-discrepancy",
      ],
    },
    { title: "Diagnostic", ids: ["kpi-conversion"] },
  ];

  const renderTile = (tile: Tile, attention: boolean) => {
    const hot =
      attention &&
      tile.testId !== "kpi-drivers-online" &&
      tile.value !== "0" &&
      tile.value !== "—";
    const body = (
      <div
        className={`kpi${tile.href ? " kpi-link" : ""}${hot ? " kpi-hot" : ""}`}
        data-testid={tile.testId}
      >
        <div className="kpi-label">{tile.label}</div>
        <div className="kpi-value">{tile.value}</div>
        {tile.hint ? <div className="kpi-sub">{tile.hint}</div> : null}
      </div>
    );
    return tile.href ? (
      <Link
        key={tile.testId}
        href={tile.href}
        className="kpi-anchor"
        aria-label={`${tile.label}: ${tile.value}`}
      >
        {body}
      </Link>
    ) : (
      <div key={tile.testId}>{body}</div>
    );
  };

  const attention = [
    {
      text: "SOS alerts to triage",
      count: counts.openSos,
      href: `/${citySlug}/safety`,
    },
    {
      text: "Fare and trip flags",
      count: counts.openFlags,
      href: `/${citySlug}/integrity`,
    },
    {
      text: "Drivers awaiting verification",
      count: counts.verificationQueue,
      href: `/${citySlug}/verification`,
    },
  ];

  return (
    <div data-testid="ops-dashboard" className="dash-layout">
      <div className="dash-main">
        {sections.map((section) => (
          <section
            key={section.title}
            className="kpi-section"
            aria-label={section.title}
          >
            <h2 className="section-label">{section.title}</h2>
            <div
              className={`kpi-grid${section.ids.length === 1 ? " kpi-grid-single" : ""}`}
            >
              {section.ids.map((id) =>
                renderTile(byId.get(id)!, Boolean(section.attention)),
              )}
              {section.title === "Diagnostic" ? (
                <p className="note" data-testid="conversion-diagnostic-note">
                  {CONVERSION_DIAGNOSTIC_NOTE}
                </p>
              ) : null}
            </div>
          </section>
        ))}
      </div>
      <aside className="card dash-side" aria-label="Needs attention">
        <h2 className="section-title">Needs attention</h2>
        <ul className="dash-todo">
          {attention.map((item) => (
            <li key={item.href}>
              <Link
                href={item.href}
                className={item.count > 0 ? "dash-todo-hot" : undefined}
              >
                <span>{item.text}</span>
                <span className="dash-todo-count">
                  {item.count > 0 ? `${item.count} open` : "Clear"}
                </span>
              </Link>
            </li>
          ))}
        </ul>
        <h3 className="section-label" style={{ marginTop: "var(--space-4)" }}>
          Fleet split
        </h3>
        <div
          className="dash-bar"
          role="img"
          aria-label={`${counts.driversAtPark} at park, ${counts.driversRoaming} roaming`}
        >
          <span style={{ flexGrow: Math.max(counts.driversAtPark, 0.0001) }} />
          <span style={{ flexGrow: Math.max(counts.driversRoaming, 0.0001) }} />
        </div>
        <p className="note">
          Parked drivers hold queue position; roaming drivers pick up on
          corridor.
        </p>
      </aside>
    </div>
  );
}
