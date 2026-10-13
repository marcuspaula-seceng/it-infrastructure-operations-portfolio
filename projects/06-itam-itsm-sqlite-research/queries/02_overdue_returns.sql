-- Snapshot as of 2026-02-10 00:00:00 UTC. Due exactly at cutoff is not overdue.
-- A completion after cutoff remains outstanding at this historical snapshot.
SELECT request_id,asset_id,due_at,approved_exception_until,
 CASE WHEN approved_exception_until >= '2026-02-10 00:00:00'
 THEN 'approved_exception' ELSE 'overdue' END AS finding
FROM service_requests
WHERE request_type='return' AND due_at < '2026-02-10 00:00:00'
AND (completed_at IS NULL OR completed_at > '2026-02-10 00:00:00')
ORDER BY request_id;
