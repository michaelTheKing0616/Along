-- OSRM car profile (doc 09 §4): shared-taxi tuned — motorways not penalised off by default.
-- Pinned to OSRM v5.27.1 (ADR-0013). Replace with project-specific tuning in a later task.

profiles = {
  car = {
    parent = "car",
  },
}
