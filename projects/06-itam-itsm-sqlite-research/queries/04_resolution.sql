-- February opening cohort, resolution snapshot 2026-03-01 UTC.
-- Elapsed calendar hours, including nights/weekends; unresolved counted separately.
WITH cohort AS (
 SELECT *,CASE WHEN resolved_at <= '2026-03-01 00:00:00'
 THEN (julianday(resolved_at)-julianday(opened_at))*24 END AS hours
 FROM incidents WHERE opened_at >= '2026-02-01 00:00:00'
 AND opened_at < '2026-03-01 00:00:00'
)
SELECT COUNT(hours) AS resolved_count,COUNT(*)-COUNT(hours) AS open_count,
 ROUND(AVG(hours),4) AS mean_elapsed_hours FROM cohort;
