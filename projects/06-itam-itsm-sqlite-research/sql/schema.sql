-- Independent educational schema. All fixture identifiers are synthetic.
PRAGMA foreign_keys = ON;

CREATE TABLE expected_assets (
    asset_id TEXT PRIMARY KEY NOT NULL CHECK (length(trim(asset_id)) > 0),
    asset_type TEXT NOT NULL
);

-- Deliberately no asset foreign key: scans must preserve unexpected assets.
-- Deliberately no uniqueness on asset_id: repeated scans are audit evidence.
CREATE TABLE audit_scans (
    scan_id INTEGER PRIMARY KEY,
    audit_id TEXT NOT NULL CHECK (length(trim(audit_id)) > 0),
    asset_id TEXT NOT NULL CHECK (length(trim(asset_id)) > 0)
);
