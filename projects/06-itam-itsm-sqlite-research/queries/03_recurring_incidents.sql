-- Half-open UTC window [2026-02-01, 2026-03-01); recurrence threshold 2.
SELECT asset_id,category,COUNT(*) AS incident_count FROM incidents
WHERE opened_at >= '2026-02-01 00:00:00' AND opened_at < '2026-03-01 00:00:00'
GROUP BY asset_id,category HAVING COUNT(*) >= 2 ORDER BY asset_id,category;
