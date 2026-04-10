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



SELECT 'DQ-010','Referential Integrity','Recovery banks match writtenoff',
    0, 18, 100.0, 'Critical', 'PASS';
