-- Online upgrade SQL for existing user_credits table.
-- Target schema:
--   balance      -> remain_credit
--   add used_credit
--   add status
--   backfill used_credit from credit_logs(type='consume')
--
-- Recommended steps:
-- 1. Back up production database first.
-- 2. Stop backend application instances before running.
-- 3. Execute this file in the target database.
--
-- Example:
--   mysql -h <host> -P <port> -u <user> -p <database> < user_credits_online_upgrade.sql

SELECT DATABASE() AS current_database;

SHOW TABLES LIKE 'user_credits';

SELECT COLUMN_NAME
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'user_credits'
  AND COLUMN_NAME IN ('balance', 'remain_credit', 'used_credit', 'status')
ORDER BY COLUMN_NAME;

SET @has_user_credits := (
  SELECT COUNT(*)
  FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'user_credits'
);

SET @has_balance := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'user_credits'
    AND COLUMN_NAME = 'balance'
);

SET @has_remain_credit := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'user_credits'
    AND COLUMN_NAME = 'remain_credit'
);

SET @has_used_credit := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'user_credits'
    AND COLUMN_NAME = 'used_credit'
);

SET @has_status := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'user_credits'
    AND COLUMN_NAME = 'status'
);

SET @rename_balance_sql := IF(
  @has_user_credits = 0,
  'SELECT ''user_credits table not found'' AS info',
  IF(
    @has_remain_credit = 0 AND @has_balance > 0,
    'ALTER TABLE user_credits CHANGE COLUMN balance remain_credit INT NOT NULL DEFAULT 0',
    'SELECT ''skip rename balance -> remain_credit'' AS info'
  )
);

PREPARE stmt_rename_balance FROM @rename_balance_sql;
EXECUTE stmt_rename_balance;
DEALLOCATE PREPARE stmt_rename_balance;

SET @add_used_credit_sql := IF(
  @has_user_credits = 0,
  'SELECT ''user_credits table not found'' AS info',
  IF(
    @has_used_credit = 0,
    'ALTER TABLE user_credits ADD COLUMN used_credit INT NOT NULL DEFAULT 0 AFTER remain_credit',
    'SELECT ''skip add used_credit'' AS info'
  )
);

PREPARE stmt_add_used_credit FROM @add_used_credit_sql;
EXECUTE stmt_add_used_credit;
DEALLOCATE PREPARE stmt_add_used_credit;

SET @add_status_sql := IF(
  @has_user_credits = 0,
  'SELECT ''user_credits table not found'' AS info',
  IF(
    @has_status = 0,
    'ALTER TABLE user_credits ADD COLUMN status TINYINT(1) NOT NULL DEFAULT 1 AFTER used_credit',
    'SELECT ''skip add status'' AS info'
  )
);

PREPARE stmt_add_status FROM @add_status_sql;
EXECUTE stmt_add_status;
DEALLOCATE PREPARE stmt_add_status;

UPDATE user_credits
LEFT JOIN (
  SELECT user_id, COALESCE(SUM(ABS(amount)), 0) AS total_used_credit
  FROM credit_logs
  WHERE type = 'consume'
  GROUP BY user_id
) cl ON cl.user_id = user_credits.user_id
SET user_credits.used_credit = COALESCE(cl.total_used_credit, 0)
WHERE user_credits.type = 0;

UPDATE user_credits
SET status = 1
WHERE status IS NULL;

SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'user_credits'
  AND COLUMN_NAME IN ('remain_credit', 'used_credit', 'status')
ORDER BY ORDINAL_POSITION;

SELECT
  id,
  user_id,
  type,
  remain_credit,
  used_credit,
  status
FROM user_credits
ORDER BY id ASC
LIMIT 20;

SELECT
  uc.user_id,
  uc.remain_credit,
  uc.used_credit,
  COALESCE(cl.total_used_credit, 0) AS credit_logs_used_credit
FROM user_credits uc
LEFT JOIN (
  SELECT user_id, COALESCE(SUM(ABS(amount)), 0) AS total_used_credit
  FROM credit_logs
  WHERE type = 'consume'
  GROUP BY user_id
) cl ON cl.user_id = uc.user_id
WHERE uc.type = 0
ORDER BY uc.user_id ASC
LIMIT 20;

SELECT
  status,
  COUNT(*) AS account_count
FROM user_credits
GROUP BY status
ORDER BY account_count DESC;
