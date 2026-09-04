'use client';

import { useMemo, useState, useTransition } from 'react';
import type {
  GraphCorridor,
  GraphPark,
  GraphRoute,
  GraphStage,
} from './page';
import { updatePark, updateRoute, updateRouteStage } from './actions';

interface GraphEditorProps {
  citySlug: string;
  graph: {
    corridors: GraphCorridor[];
    routes: GraphRoute[];
    stages: GraphStage[];
    parks: GraphPark[];
  };
}

type Selected =
  | { kind: 'park'; id: string }
  | { kind: 'route'; id: string }
  | { kind: 'stage'; id: string }
  | null;

function TierBadge({ status, confidence }: { status: string; confidence: number }) {
  return (
    <span className={`badge badge-${status.replace('_', '-')}`} title={`confidence ${confidence}`}>
      {status.replace('_', ' ')}
    </span>
  );
}

export function GraphEditor({ citySlug, graph }: GraphEditorProps) {
  const [selected, setSelected] = useState<Selected>(null);
  const [editName, setEditName] = useState('');
  const [editSequence, setEditSequence] = useState('');
  const [editActive, setEditActive] = useState(true);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();

  const parkById = useMemo(
    () => new Map(graph.parks.map((p) => [p.id, p])),
    [graph.parks]
  );

  const routesByCorridor = useMemo(() => {
    const map = new Map<string, GraphRoute[]>();
    for (const route of graph.routes) {
      const key = route.corridor_id ?? 'uncorridor';
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

  function selectPark(park: GraphPark) {
    setSelected({ kind: 'park', id: park.id });
    setEditName(park.name);
    setMessage(null);
    setError(null);
  }

  function selectRoute(route: GraphRoute) {
    setSelected({ kind: 'route', id: route.id });
    setEditName(route.name ?? '');
    setEditActive(route.active);
    setMessage(null);
    setError(null);
  }

  function selectStage(stage: GraphStage) {
    setSelected({ kind: 'stage', id: stage.id });
    setEditName(stage.name ?? '');
    setEditSequence(String(stage.sequence));
    setMessage(null);
    setError(null);
  }

  function saveEdit() {
    if (!selected) return;
    setMessage(null);
    setError(null);

    startTransition(async () => {
      let result;
      if (selected.kind === 'park') {
        result = await updatePark(citySlug, selected.id, { name: editName });
      } else if (selected.kind === 'route') {
        result = await updateRoute(citySlug, selected.id, {
          name: editName || null,
          active: editActive,
        });
      } else {
        const sequence = Number(editSequence);
        if (!Number.isFinite(sequence)) {
          setError('Sequence must be a number.');
          return;
        }
        result = await updateRouteStage(citySlug, selected.id, {
          name: editName || null,
          sequence,
        });
      }

      if (result.ok) {
        setMessage('Saved — graph_revisions recorded by trigger.');
      } else {
        setError(result.error);
      }
    });
  }

  return (
    <div data-testid="graph-editor">
      {error ? <div className="error-banner" role="alert">{error}</div> : null}
      {message ? (
        <div className="card" role="status" style={{ marginBottom: 'var(--space-4)', fontSize: '0.875rem' }}>
          {message}
        </div>
      ) : null}

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--space-6)' }}>
        <section>
          <h2 style={{ fontSize: '1rem', margin: '0 0 var(--space-3)' }}>Corridors → routes → stages</h2>
          {graph.corridors.length === 0 ? (
            <p style={{ color: 'var(--color-text-muted)', fontSize: '0.875rem' }}>No corridors seeded.</p>
          ) : (
            <ul className="tree-list" style={{ listStyle: 'none', padding: 0, margin: 0 }}>
              {graph.corridors.map((corridor) => (
                <li key={corridor.id} style={{ marginBottom: 'var(--space-3)' }}>
                  <strong>{corridor.name}</strong>{' '}
                  <span className="badge">{corridor.status}</span>
                  <ul style={{ listStyle: 'none', paddingLeft: 'var(--space-4)', margin: 'var(--space-2) 0 0' }}>
                    {(routesByCorridor.get(corridor.id) ?? []).map((route) => (
                      <li key={route.id} style={{ marginBottom: 'var(--space-2)' }}>
                        <button
                          type="button"
                          className="tree-button"
                          data-testid={`graph-route-${route.id}`}
                          onClick={() => selectRoute(route)}
                        >
                          {route.name ?? `${route.mode_code} route`}{' '}
                          <TierBadge status={route.verification_status} confidence={route.confidence_score} />
                        </button>
                        <ul style={{ listStyle: 'none', paddingLeft: 'var(--space-4)', margin: 'var(--space-1) 0 0' }}>
                          {(stagesByRoute.get(route.id) ?? []).map((stage) => (
                            <li key={stage.id}>
                              <button
                                type="button"
                                className="tree-button"
                                data-testid={`graph-stage-${stage.id}`}
                                onClick={() => selectStage(stage)}
                              >
                                #{stage.sequence} {stage.name ?? 'stage'}{' '}
                                <TierBadge
                                  status={stage.verification_status}
                                  confidence={stage.confidence_score}
                                />
                              </button>
                            </li>
                          ))}
                        </ul>
                      </li>
                    ))}
                  </ul>
                </li>
              ))}
            </ul>
          )}

          <h2 style={{ fontSize: '1rem', margin: 'var(--space-6) 0 var(--space-3)' }}>Parks</h2>
          {graph.parks.length === 0 ? (
            <p style={{ color: 'var(--color-text-muted)', fontSize: '0.875rem' }}>No parks in graph.</p>
          ) : (
            <ul className="tree-list" style={{ listStyle: 'none', padding: 0, margin: 0 }}>
              {graph.parks.map((park) => (
                <li key={park.id} style={{ marginBottom: 'var(--space-1)' }}>
                  <button
                    type="button"
                    className="tree-button"
                    data-testid={`graph-park-${park.id}`}
                    onClick={() => selectPark(park)}
                  >
                    {park.name}{' '}
                    <TierBadge status={park.verification_status} confidence={park.confidence_score} />
                  </button>
                </li>
              ))}
            </ul>
          )}
        </section>

        <section className="card" data-testid="graph-edit-panel">
          <h2 style={{ fontSize: '1rem', margin: '0 0 var(--space-4)' }}>Edit selected entity</h2>
          {!selected ? (
            <p style={{ color: 'var(--color-text-muted)', fontSize: '0.875rem' }}>
              Select a park, route, or stage from the tree.
            </p>
          ) : (
            <>
              <p style={{ fontSize: '0.8125rem', color: 'var(--color-text-muted)' }}>
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
              {selected.kind === 'stage' ? (
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
              {selected.kind === 'route' ? (
                <label style={{ display: 'flex', gap: 'var(--space-2)', alignItems: 'center', marginBottom: 'var(--space-4)' }}>
                  <input
                    type="checkbox"
                    checked={editActive}
                    onChange={(e) => setEditActive(e.target.checked)}
                  />
                  Active route
                </label>
              ) : null}
              {selected.kind === 'park' ? (
                <p style={{ fontSize: '0.8125rem', color: 'var(--color-text-muted)' }}>
                  Aliases: {(parkById.get(selected.id)?.name_aliases ?? []).join(', ') || '—'}
                </p>
              ) : null}
              <button
                type="button"
                className="btn btn-primary"
                disabled={pending}
                data-testid="graph-save"
                onClick={saveEdit}
              >
                Save changes
              </button>
            </>
          )}
        </section>
      </div>
    </div>
  );
}
