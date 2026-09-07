export type AuditLogRow = {
  id: number;
  actor_id: string | null;
  actor_role: string | null;
  action: string;
  target_type: string;
  target_id: string;
  before: Record<string, unknown> | null;
  after: Record<string, unknown> | null;
  created_at: string;
};

export type AuditLogFilters = {
  action?: string;
  targetType?: string;
  actorRole?: string;
  targetId?: string;
};

export type AuditLogPage = {
  rows: AuditLogRow[];
  nextCursor: number | null;
  pageSize: number;
};
