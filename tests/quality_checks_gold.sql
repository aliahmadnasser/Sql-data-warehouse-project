/* ============================================================
   GOLD LAYER — DATA INTEGRITY CHECKS (POST-LOAD VALIDATION)
   ------------------------------------------------------------
   Purpose : Final health checks to ensure the Star Schema is 
             mathematically sound and ready for BI tools.
   Expected: ALL queries must return 0 rows (empty result sets).
   ============================================================ */


/* ------------------------------------------------------------
   1. DIMENSION UNIQUENESS CHECKS
   ------------------------------------------------------------
   What it does : Verifies no duplicate Surrogate Keys exist.
   Why it matters: If duplicates exist, the ROW_NUMBER() logic 
                   failed. This would multiply sales in reports.
   ------------------------------------------------------------ */

-- 1.1 Check for duplicate Customer Keys
SELECT 
    customer_key,
    COUNT(*) AS duplicate_count
FROM Gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;


-- 1.2 Check for duplicate Product Keys
SELECT 
    product_key,
    COUNT(*) AS duplicate_count
FROM Gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;


/* ------------------------------------------------------------
   2. FACT TABLE REFERENTIAL INTEGRITY CHECK
   ------------------------------------------------------------
   What it does : Verifies every sale links to a valid Customer 
                  and Product (checks for "orphaned" records).
   Why it matters: If a key is missing, the LEFT JOIN in 
                   fact_sales failed, causing blank/unknown 
                   items in dashboards.
   ------------------------------------------------------------ */

-- 2.1 Check for orphaned records in the Fact Table
SELECT *
FROM Gold.fact_sales f
LEFT JOIN Gold.dim_customers c
    ON c.customer_key = f.customer_key
LEFT JOIN Gold.dim_products p
    ON p.product_key = f.product_key
WHERE p.product_key IS NULL 
   OR c.customer_key IS NULL;


/* ============================================================
   END OF CHECKS
   ============================================================ */
