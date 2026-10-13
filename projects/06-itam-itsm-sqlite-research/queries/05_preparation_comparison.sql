-- Same workload/check definition in both cohorts. Failed attempts remain included.
-- One row is one preparation attempt. Fixture durations differ from professional metrics.
SELECT workload,check_type,cohort,COUNT(*) AS attempts,
 ROUND(AVG(duration_minutes),2) AS mean_minutes,
 ROUND(100.0*SUM(outcome='pass')/COUNT(*),2) AS pass_percent,
 ROUND(60.0/AVG(duration_minutes),2) AS serial_attempts_per_hour
FROM preparation_checks GROUP BY workload,check_type,cohort
ORDER BY workload,check_type,cohort;
