-- Entirely synthetic educational model. UTC timestamps: YYYY-MM-DD HH:MM:SS.
-- Run once against an empty database; existing objects intentionally cause failure.
PRAGMA foreign_keys = ON;
BEGIN;
CREATE TABLE assets (
 synthetic_asset_id TEXT PRIMARY KEY NOT NULL,
 asset_type TEXT NOT NULL CHECK(asset_type IN ('laptop','monitor','phone')),
 site_code TEXT NOT NULL,
 lifecycle_state TEXT NOT NULL CHECK(lifecycle_state IN ('stock','assigned','retired'))
);
CREATE TABLE assignments (
 assignment_id INTEGER PRIMARY KEY,
 asset_id TEXT NOT NULL REFERENCES assets(synthetic_asset_id),
 synthetic_person_id TEXT NOT NULL,
 assigned_at TEXT NOT NULL,
 returned_at TEXT,
 CHECK(returned_at IS NULL OR returned_at >= assigned_at)
);
CREATE UNIQUE INDEX one_active_assignment ON assignments(asset_id) WHERE returned_at IS NULL;
CREATE TABLE audit_scans (
 scan_id INTEGER PRIMARY KEY,
 audit_id TEXT NOT NULL,
 asset_id TEXT NOT NULL,
 scanned_at TEXT NOT NULL
);
-- No asset FK on scans: unexpected observations must remain representable.
CREATE INDEX scans_by_audit ON audit_scans(audit_id,asset_id);
CREATE TABLE incidents (
 incident_id INTEGER PRIMARY KEY,
 asset_id TEXT NOT NULL REFERENCES assets(synthetic_asset_id),
 category TEXT NOT NULL,
 priority INTEGER NOT NULL CHECK(priority BETWEEN 1 AND 4),
 opened_at TEXT NOT NULL,
 resolved_at TEXT,
 CHECK(resolved_at IS NULL OR resolved_at >= opened_at)
);
CREATE TABLE service_requests (
 request_id INTEGER PRIMARY KEY,
 request_type TEXT NOT NULL CHECK(request_type IN ('return','onboarding')),
 asset_id TEXT NOT NULL REFERENCES assets(synthetic_asset_id),
 due_at TEXT NOT NULL,
 completed_at TEXT,
 approved_exception_until TEXT,
 CHECK(approved_exception_until IS NULL OR approved_exception_until >= due_at)
);
CREATE TABLE preparation_checks (
 check_id INTEGER PRIMARY KEY,
 asset_id TEXT NOT NULL REFERENCES assets(synthetic_asset_id),
 check_type TEXT NOT NULL,
 outcome TEXT NOT NULL CHECK(outcome IN ('pass','fail')),
 checked_at TEXT NOT NULL,
 cohort TEXT NOT NULL CHECK(cohort IN ('before','after')),
 workload TEXT NOT NULL,
 duration_minutes INTEGER NOT NULL CHECK(duration_minutes > 0)
);
COMMIT;
