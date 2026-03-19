SELECT
  dstaddr AS destination_ip,
  COUNT(*) AS hit_count
FROM vpc_flowlogs_db.vpc_flowlogs
GROUP BY dstaddr
ORDER BY hit_count DESC
LIMIT 10;
