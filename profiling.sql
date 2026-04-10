SELECT COUNT(*) AS rows FROM npa_writtenoff;
SELECT COUNT(*) AS rows FROM npa_recovery;
-- What columns exist in each table?
PRAGMA table_info(npa_writtenoff);
PRAGMA table_info(npa_recovery);

-- Query 1 — Row Count & Basic Shape
SELECT 
    COUNT(*)           AS total_rows,
    COUNT(DISTINCT Bank) AS unique_banks
FROM npa_writtenoff;
SELECT 
    COUNT(*)           AS total_rows,
    COUNT(DISTINCT Bank) AS unique_banks
FROM npa_recovery;

-- Query 2 — NULL Check (Completeness)
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN Bank IS NULL OR Bank = '' OR Bank = 'NA' THEN 1 ELSE 0 END) AS null_bank,
    SUM(CASE WHEN "2019-20" IS NULL OR "2019-20" = 'NA' THEN 1 ELSE 0 END) AS null_2019,
    SUM(CASE WHEN "2020-21" IS NULL OR "2020-21" = 'NA' THEN 1 ELSE 0 END) AS null_2020,
    SUM(CASE WHEN "2021-22" IS NULL OR "2021-22" = 'NA' THEN 1 ELSE 0 END) AS null_2021,
    SUM(CASE WHEN "2022-23" IS NULL OR "2022-23" = 'NA' THEN 1 ELSE 0 END) AS null_2022,
    SUM(CASE WHEN "2023-24" IS NULL OR "2023-24" = 'NA' THEN 1 ELSE 0 END) AS null_2023
FROM npa_writtenoff;

SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN Bank IS NULL OR Bank = '' OR Bank = 'NA' THEN 1 ELSE 0 END) AS null_bank,
    SUM(CASE WHEN "2019-20" IS NULL OR "2019-20" = 'NA' THEN 1 ELSE 0 END) AS null_2019,
    SUM(CASE WHEN "2020-21" IS NULL OR "2020-21" = 'NA' THEN 1 ELSE 0 END) AS null_2020,
    SUM(CASE WHEN "2021-22" IS NULL OR "2021-22" = 'NA' THEN 1 ELSE 0 END) AS null_2021,
    SUM(CASE WHEN "2022-23" IS NULL OR "2022-23" = 'NA' THEN 1 ELSE 0 END) AS null_2022,
    SUM(CASE WHEN "2023-24" IS NULL OR "2023-24" = 'NA' THEN 1 ELSE 0 END) AS null_2023
FROM npa_recovery;


-- Query 3 — Duplicate Check (Uniqueness)
SELECT 
    Bank,
    COUNT(*) AS occurrences
FROM npa_writtenoff
GROUP BY Bank
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


-- Query 4 — List All Distinct Banks (Validity Check)

SELECT 
    Bank,
    LENGTH(Bank) AS name_length
FROM npa_writtenoff
ORDER BY Bank;

-- Query 5 — Cross-dataset Bank Match (Referential Integrity)

SELECT 
    w.Bank AS in_writtenoff,
    r.Bank AS in_recovery
FROM npa_writtenoff w
LEFT JOIN npa_recovery r ON w.Bank = r.Bank
WHERE r.Bank IS NULL;

-- Query 6 — Reverse Integrity Check
SELECT 
    r.Bank AS in_recovery,
    w.Bank AS in_writtenoff
FROM npa_recovery r
LEFT JOIN npa_writtenoff w ON r.Bank = w.Bank
WHERE w.Bank IS NULL;

-- Query 7 — Data Consistency Check (Same bank, both datasets)

SELECT 
    w.Bank,
    w."2021-22" AS writtenoff_2122,
    r."2021-22" AS recovery_2122
FROM npa_writtenoff w
JOIN npa_recovery r ON w.Bank = r.Bank
ORDER BY w.Bank;

-- Query 8 — Profiling Summary View 

SELECT
    'npa_writtenoff'          AS table_name,
    COUNT(*)                  AS total_rows,
    COUNT(DISTINCT Bank)      AS unique_banks,
    SUM(CASE WHEN Bank IS NULL OR Bank='NA' THEN 1 ELSE 0 END) AS null_bank_count,
    SUM(CASE WHEN "2021-22" IS NULL OR "2021-22"='NA' THEN 1 ELSE 0 END) AS null_values_2122
FROM npa_writtenoff

UNION ALL

SELECT
    'npa_recovery'            AS table_name,
    COUNT(*)                  AS total_rows,
    COUNT(DISTINCT Bank)      AS unique_banks,
    SUM(CASE WHEN Bank IS NULL OR Bank='NA' THEN 1 ELSE 0 END) AS null_bank_count,
    SUM(CASE WHEN "2021-22" IS NULL OR "2021-22"='NA' THEN 1 ELSE 0 END) AS null_values_2122
FROM npa_recovery;


-- DQ Rule 1 — Completeness: NPA Written-off amount not null
-- DQ-001: No missing NPA written-off values
SELECT 
    Bank,
    "2019-20", "2020-21", "2021-22", "2022-23", "2023-24"
FROM npa_writtenoff
WHERE 
    "2019-20" IN ('NA', '') OR "2019-20" IS NULL OR
    "2020-21" IN ('NA', '') OR "2020-21" IS NULL OR
    "2021-22" IN ('NA', '') OR "2021-22" IS NULL
ORDER BY Bank;

-- DQ-002: Each bank must appear exactly once
SELECT 
    Bank,
    COUNT(*) AS duplicate_count,
    'FAIL - Duplicate bank record' AS dq_status
FROM npa_writtenoff
GROUP BY Bank
HAVING COUNT(*) > 1;

-- DQ-003: NPA amounts must be numeric, not text garbage
SELECT 
    Bank,
    "2021-22" AS value_2122,
    CASE 
        WHEN CAST("2021-22" AS REAL) IS NULL 
         AND "2021-22" NOT IN ('NA','') 
        THEN 'FAIL - Non-numeric value'
        ELSE 'PASS'
    END AS dq_status
FROM npa_writtenoff
WHERE "2021-22" NOT IN ('NA','') 
  AND "2021-22" IS NOT NULL
ORDER BY dq_status DESC;


-- DQ-004: NPA written-off cannot be negative or zero
SELECT 
    Bank,
    "2022-23" AS npa_amount,
    CASE 
        WHEN CAST("2022-23" AS REAL) <= 0 
        THEN 'FAIL - Zero or negative NPA'
        ELSE 'PASS'
    END AS dq_status
FROM npa_writtenoff
WHERE "2022-23" NOT IN ('NA','') 
  AND "2022-23" IS NOT NULL;
  
  
  -- DQ-005: Banks with NPA write-off must have recovery records
SELECT 
    w.Bank,
    'FAIL - No recovery record found' AS dq_status
FROM npa_writtenoff w
LEFT JOIN npa_recovery r ON TRIM(LOWER(w.Bank)) = TRIM(LOWER(r.Bank))
WHERE r.Bank IS NULL
ORDER BY w.Bank;

-- DQ-006: Column name consistency issue
SELECT 
    'npa_writtenoff' AS table_name,
    '2024-25 (as on 31-12-2024)' AS actual_column_name,
    '2024-25' AS expected_column_name,
    'FAIL - Column name inconsistent with npa_recovery' AS dq_status
UNION ALL
SELECT 
    'npa_recovery',
    '2024-25',
    '2024-25',
    'PASS - Column name matches expected';
	
-- DQ-007: What % of recovery records have data each year
SELECT
    COUNT(*) AS total_banks,
    SUM(CASE WHEN "2020-21" NOT IN ('NA','') AND "2020-21" IS NOT NULL THEN 1 ELSE 0 END) AS filled_2021,
    ROUND(100.0 * SUM(CASE WHEN "2020-21" NOT IN ('NA','') AND "2020-21" IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_complete_2021,
    SUM(CASE WHEN "2022-23" NOT IN ('NA','') AND "2022-23" IS NOT NULL THEN 1 ELSE 0 END) AS filled_2023,
    ROUND(100.0 * SUM(CASE WHEN "2022-23" NOT IN ('NA','') AND "2022-23" IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_complete_2023
FROM npa_recovery;

-- DQ-008: 2024-25 data must be present (timeliness check)
SELECT
    Bank,
    "2024-25" AS latest_year_value,
    CASE 
        WHEN "2024-25" IN ('NA','') OR "2024-25" IS NULL 
        THEN 'FAIL - Latest year missing'
        ELSE 'PASS'
    END AS dq_status
FROM npa_recovery
ORDER BY dq_status DESC;

-- DQ-009: Recovery <= Written-off for same bank and year (business rule)
SELECT 
    w.Bank,
    CAST(w."2021-22" AS REAL) AS writtenoff_amt,
    CAST(r."2021-22" AS REAL) AS recovery_amt,
    CASE 
        WHEN CAST(r."2021-22" AS REAL) > CAST(w."2021-22" AS REAL) 
        THEN 'FAIL - Recovery exceeds written-off'
        ELSE 'PASS'
    END AS dq_status
FROM npa_writtenoff w
JOIN npa_recovery r ON TRIM(LOWER(w.Bank)) = TRIM(LOWER(r.Bank))
WHERE w."2021-22" NOT IN ('NA','') AND r."2021-22" NOT IN ('NA','');

------------------
SELECT 'DQ-001' AS rule_id, 'Completeness' AS dq_dimension,
    'NPA values not null' AS rule_name,
    29 AS failures, 79 AS total_records,
    ROUND((100.0 - (100.0 * 29 / 79)), 1) AS dq_score_pct,
    'High' AS severity, 'FAIL' AS status

UNION ALL 
SELECT 'DQ-002','Uniqueness','No duplicate banks',
    1, 79, ROUND((100.0 - (100.0*1/79)),1),'Critical','FAIL'

UNION ALL 
SELECT 'DQ-003','Validity','NPA values are numeric',
    0, 57, 100.0, 'High', 'PASS'

UNION ALL 
SELECT 'DQ-004','Validity','NPA values are positive',
    0, 57, 100.0, 'Medium', 'PASS'

UNION ALL 
SELECT 'DQ-005','Referential Integrity','Every bank has recovery record',
    61, 79, ROUND((100.0 - (100.0*61/79)),1),'Critical','FAIL'

UNION ALL 
SELECT 'DQ-006','Consistency','Column names match across tables',
    1, 2, 50.0, 'Medium', 'FAIL'

UNION ALL 
SELECT 'DQ-007','Completeness','Recovery data 80pct complete per year',
    6, 18, 66.7, 'High', 'FAIL'

UNION ALL 
SELECT 'DQ-008','Timeliness','Latest year data present',
    6, 18, ROUND((100.0 - (100.0*6/18)),1), 'Medium', 'FAIL'

UNION ALL 
SELECT 'DQ-009','Business Rule','Recovery not exceed written-off',
    4, 12, ROUND((100.0 - (100.0*4/12)),1), 'Critical', 'FAIL'

UNION ALL 
SELECT 'DQ-010','Referential Integrity','Recovery banks match writtenoff',
    0, 18, 100.0, 'Critical', 'PASS';