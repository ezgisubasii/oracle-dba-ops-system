-- 1. Which full is each tablespace?
SELECT tablespace_name, ROUND(used_percent, 1) AS used_pct
  FROM dba_tablespace_usage_metrics
 ORDER BY used_percent DESC;

-- 2. Can the one that is full expand?
SELECT tablespace_name, ROUND(bytes / 1024 / 1024) AS size_mb, autoextensible
  FROM dba_data_files
 WHERE tablespace_name = 'LAB_SMALL';

-- 3. Which one use the space?
SELECT owner, segment_name, ROUND(bytes / 1024 / 1024, 1) AS mb
  FROM dba_segments
 WHERE tablespace_name = 'LAB_SMALL';

