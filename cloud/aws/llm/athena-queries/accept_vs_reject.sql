SELECT
  action,
  COUNT(*) AS total_requests
FROM vpc_flowlogs_db.vpc_flowlogs
GROUP BY action;
