-- Invented data only; never load employer exports into this public exercise.
INSERT INTO expected_assets (asset_id, asset_type) VALUES
    ('DEMO-ASSET-001', 'laptop'),
    ('DEMO-ASSET-002', 'monitor'),
    ('DEMO-ASSET-003', 'phone');

INSERT INTO audit_scans (audit_id, asset_id) VALUES
    ('DEMO-AUDIT-001', 'DEMO-ASSET-001'),
    ('DEMO-AUDIT-001', 'DEMO-ASSET-002'),
    ('DEMO-AUDIT-001', 'DEMO-ASSET-002'),
    ('DEMO-AUDIT-001', 'DEMO-ASSET-999'),
    ('DEMO-AUDIT-002', 'DEMO-ASSET-003');
