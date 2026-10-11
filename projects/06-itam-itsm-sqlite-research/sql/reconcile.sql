-- Bind :audit_id to one audit. Counts are scoped before category calculation.
-- Matched means present in both sets; duplicates are a separate quality flag.
WITH scanned AS (
    SELECT asset_id, COUNT(*) AS scan_count
    FROM audit_scans
    WHERE audit_id = :audit_id
    GROUP BY asset_id
), findings AS (
    SELECT 'matched' AS category, e.asset_id, s.scan_count
    FROM expected_assets AS e JOIN scanned AS s USING (asset_id)
    UNION ALL
    SELECT 'missing', e.asset_id, 0
    FROM expected_assets AS e
    WHERE NOT EXISTS (SELECT 1 FROM scanned AS s WHERE s.asset_id = e.asset_id)
    UNION ALL
    SELECT 'unexpected', s.asset_id, s.scan_count
    FROM scanned AS s
    WHERE NOT EXISTS (
        SELECT 1 FROM expected_assets AS e WHERE e.asset_id = s.asset_id
    )
    UNION ALL
    SELECT 'duplicate', asset_id, scan_count FROM scanned WHERE scan_count > 1
)
SELECT category, asset_id, scan_count FROM findings ORDER BY category, asset_id;
