SELECT
  hour(from_unixtime(start)) AS hour_of_day,
  COUNT(*) AS request_count
FROM vpc_flowlogs_db.vpc_flowlogs
GROUP BY hour(from_unixtime(start))
ORDER BY hour_of_day;
