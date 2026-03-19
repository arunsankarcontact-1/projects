SELECT
  srcaddr AS source_ip,
  COUNT(*) AS denied_count
FROM vpc_flowlogs_db.vpc_flowlogs
WHERE action = 'REJECT'
GROUP BY srcaddr
ORDER BY denied_count DESC
LIMIT 10;
