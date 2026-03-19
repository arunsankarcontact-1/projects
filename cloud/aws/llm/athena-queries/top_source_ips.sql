SELECT
  srcaddr AS source_ip,
  COUNT(*) AS request_count
FROM vpc_flowlogs_db.vpc_flowlogs
WHERE action = 'ACCEPT'
GROUP BY srcaddr
ORDER BY request_count DESC
LIMIT 10;
