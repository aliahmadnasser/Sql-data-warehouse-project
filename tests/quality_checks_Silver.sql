/* ============================================================
   SILVER LAYER — DATA QUALITY CHECKS
   ------------------------------------------------------------
   Purpose : Ad-hoc validation queries used to verify the
             transformations applied in Silver.load_Silver.
   Usage   : Run after EXEC Silver.load_Silver;
             Every query should return ZERO (or expected) rows.
   ============================================================ */


/* ------------------------------------------------------------
   1. CRM — Product Info
   ------------------------------------------------------------ */

-- 1.1 Check source: how LEAD() derives prd_end_dt for a sample of keys
SELECT
    prd_id,
    prd_key,
    prd_nm,
    prd_start_dt,
    prd_end_dt,
    LEAD(prd_start_dt) OVER (
        PARTITION BY prd_key ORDER BY prd_start_dt
    ) - 1 AS prd_end_dt_test
FROM Bronze.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509-R', 'AC-HE-GL-U509');

-- 1.2 Uniqueness: prd_id must be unique and non-null
SELECT prd_id, COUNT(*) AS cnt
FROM Silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- 1.3 Validity: prd_cost must be >= 0 and not null
SELECT prd_cost
FROM Silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- 1.4 Consistency: prd_line should only contain mapped values
SELECT DISTINCT prd_line
FROM Silver.crm_prd_info;

-- 1.5 Logic: prd_end_dt must be >= prd_start_dt
SELECT *
FROM Silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;


/* ------------------------------------------------------------
   2. CRM — Customer Info
   ------------------------------------------------------------ */

-- 2.1 Source: check duplicate or null cst_id in Bronze
SELECT cst_id, COUNT(*) AS cnt
FROM Bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- 2.2 Source: check first/last name whitespace anomalies
SELECT cst_lastname
FROM Bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_lastname);

-- 2.3 Distinct gender values (should only be MALE / FEMALE / n/a)
SELECT DISTINCT cst_gndr
FROM Bronze.crm_cust_info;

-- 2.4 Distinct marital status values (should only be MARRIED / SINGLE / n/a)
SELECT DISTINCT cst_material_status
FROM Bronze.crm_cust_info;


/* ------------------------------------------------------------
   3. CRM — Sales Details
   ------------------------------------------------------------ */

-- 3.1 Source: invalid ship dates (0, wrong length, out of range)
SELECT NULLIF(sls_ship_dt, 0) AS sls_ship_dt
FROM Bronze.crm_sales_details
WHERE sls_ship_dt <= 0
   OR LEN(CAST(sls_ship_dt AS VARCHAR)) != 8
   OR sls_ship_dt > 20500101
   OR sls_ship_dt < 19000101;

-- 3.2 Logic: order date must not be after ship/due date
SELECT *
FROM Bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
   OR sls_order_dt > sls_due_dt;

-- 3.3 Consistency: recalculate sales & price where source is inconsistent
SELECT DISTINCT
    sls_sales  AS old_sls_sales,
    sls_quantity,
    sls_price  AS old_sls_price,
    CASE
        WHEN sls_sales IS NULL OR sls_sales <= 0
             OR sls_sales != sls_quantity * ABS(sls_price)
            THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales,
    CASE
        WHEN sls_price IS NULL OR sls_price <= 0
            THEN sls_sales / NULLIF(sls_quantity, 0)
        ELSE sls_price
    END AS sls_price
FROM Bronze.crm_sales_details
WHERE sls_sales  != sls_quantity * sls_price
   OR sls_sales  IS NULL
   OR sls_quantity IS NULL
   OR sls_price  IS NULL
   OR sls_sales  <= 0
   OR sls_quantity <= 0
   OR sls_price  <= 0;

-- 3.4 Post-load sanity check on Silver
SELECT * FROM Silver.crm_sales_details;
