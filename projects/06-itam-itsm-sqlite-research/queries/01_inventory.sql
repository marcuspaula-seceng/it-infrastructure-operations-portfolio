-- Expected scope: non-retired assets in DEMO-SITE-A, audit DEMO-AUDIT-001.
WITH expected AS (
 SELECT synthetic_asset_id AS asset_id FROM assets
 WHERE site_code='DEMO-SITE-A' AND lifecycle_state <> 'retired'
), observed AS (
 SELECT asset_id, COUNT(*) AS scans FROM audit_scans
 WHERE audit_id='DEMO-AUDIT-001' GROUP BY asset_id
)
SELECT 'missing' AS finding,e.asset_id,0 AS scan_count FROM expected e
LEFT JOIN observed o USING(asset_id) WHERE o.asset_id IS NULL
UNION ALL
SELECT 'unexpected',o.asset_id,o.scans FROM observed o
LEFT JOIN expected e USING(asset_id) WHERE e.asset_id IS NULL
UNION ALL
SELECT 'duplicate',asset_id,scans FROM observed WHERE scans > 1
ORDER BY finding,asset_id;
