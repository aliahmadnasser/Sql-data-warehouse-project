/* ============================================================
   SILVER LAYER — LOAD PROCEDURE
   ------------------------------------------------------------
   Procedure : Silver.load_Silver
   Purpose   : Truncate each Silver table and reload it from
               the Bronze layer with cleaning / standardization.
   Pattern   : TRUNCATE + INSERT (full refresh, idempotent)
   Audit     : dwh_create_date auto-filled via DEFAULT
   Logging   : Per-table duration + batch total + CATCH handler
   ============================================================ */



CREATE OR ALTER PROCEDURE Silver.load_Silver AS
BEGIN

DECLARE @start_time DATETIME , @end_time DATETIME , @batch_start_time DATETIME , @batch_end_time DATETIME;
	BEGIN TRY
		SET @batch_start_time =GETDATE();
		 PRINT '=================================' ;
		 PRINT 'LOADING BRONZE LAYER ';
		 PRINT '=================================' ;	

		 PRINT '---------------------------------------------';
		 PRINT 'LOADING  CRM TABLES ';
		 PRINT '---------------------------------------------';

		 SET @start_time =GETDATE();



        PRINT '>> TRUNCATING TABLE : Silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;
        PRINT '>> INSERTING DATA INTO: Silver.crm_cust_info';

        INSERT INTO Silver.crm_cust_info (
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_material_status,
        cst_gndr,
        cst_create_date
        )


        SELECT 
        cst_id,
        cst_key,
        TRIM (cst_firstname) AS cst_firstname,
        TRIM (cst_lastname) AS cst_lastname,
        CASE WHEN UPPER(TRIM (cst_material_status))='M' THEN 'MARRIED'
        WHEN UPPER(TRIM (cst_material_status)) ='S' THEN 'SINGLE'
        ELSE 'n/a'
        END cst_material_status,
        CASE WHEN UPPER(TRIM (cst_gndr))='F' THEN 'FEMALE'
        WHEN UPPER(TRIM (cst_gndr)) ='M' THEN 'MALE'
        ELSE 'n/a'
        END cst_gndr,
        cst_create_date
        FROM (
        SELECT *,
        ROW_NUMBER () OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC ) as flag_last
        FROM bronze.crm_cust_info
        WHERE cst_id IS NOT NULL) AS t 
        WHERE flag_last =1;

        SET @end_time = GETDATE();

        SET @start_time = GETDATE();
        PRINT '>> TRUNCATING TABLE : Silver.crm_prd_info'
        TRUNCATE TABLE Silver.crm_prd_info;
        PRINT '>> INSERTING DATA INTO: Silver.crm_prd_info';

        INSERT INTO Silver.crm_prd_info(
        prd_id,
        cat_id,
        prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt
        )

        SELECT 
        prd_id,
        REPLACE (SUBSTRING(prd_key,1, 5),'-','_') AS cat_id,
        SUBSTRING (prd_key,7,LEN(prd_key))AS prd_key,
        prd_nm,
        ISNULL(prd_cost,0) AS prd_cost,
        CASE UPPER(TRIM(prd_line)) 
	        WHEN'M' THEN 'MOUNTAIN'
	        WHEN 'R' THEN  'ROAD'
	        WHEN 'S' THEN 'OTHER SALES'
	        WHEN 'T' THEN 'TOURING'
	        ELSE 'n/a'
        END prd_line,
        CAST (prd_start_dt AS DATE)AS prd_start_dt,
        CAST (
        LEAD (prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE 
        ) AS prd_end_dt
        FROM bronze.crm_prd_info

         SET @end_time = GETDATE();

         SET @start_time = GETDATE();



        PRINT '>> TRUNCATING TABLE : Silver.crm_sales_details'
        TRUNCATE TABLE Silver.crm_sales_details;
        PRINT '>> INSERTING DATA INTO: Silver.crm_sales_details';

        INSERT INTO Silver.crm_sales_details
        (
            sls_ord_num,   
            sls_prd_key,   
            sls_cust_id,           
            sls_order_dt,          
            sls_ship_dt,          
            sls_due_dt,          
            sls_sales,           
            sls_quantity,           
            sls_price
        )



        SELECT 
            sls_ord_num,   
            sls_prd_key,   
            sls_cust_id,           
            CASE WHEN sls_order_dt =0 OR LEN(sls_order_dt) !=8 THEN NULL
            ELSE CAST(CAST(sls_order_dt AS VARCHAR)AS DATE)
            END AS sls_order_dt,
              CASE WHEN sls_ship_dt =0 OR LEN(sls_ship_dt) !=8 THEN NULL
            ELSE CAST(CAST(sls_ship_dt AS VARCHAR)AS DATE)
            END AS sls_ship_dt,   
            CASE WHEN sls_due_dt =0 OR LEN(sls_due_dt) !=8 THEN NULL
            ELSE CAST(CAST(sls_due_dt AS VARCHAR)AS DATE)
            END AS sls_due_dt,
            CASE WHEN sls_sales IS NULL OR sls_sales<=0 OR sls_sales != sls_quantity * ABS (sls_price)
                    THEN sls_quantity * ABS (sls_price)
                ELSE sls_sales
                END AS sls_sales,
            sls_quantity,           
            CASE WHEN sls_price IS NULL OR sls_price <=0
                THEN sls_sales / NULLIF (sls_quantity,0)
                ELSE sls_price
                END AS sls_price
            FROM bronze.crm_sales_details
    
        SET @end_time = GETDATE();


        SET @start_time = GETDATE();

            PRINT '>> TRUNCATING TABLE : Silver.erp_cust_az12'
        TRUNCATE TABLE Silver.erp_cust_az12;
        PRINT '>> INSERTING DATA INTO: Silver.erp_cust_az12';

        INSERT INTO Silver.erp_cust_az12(
        cid,
        bdate,
        gen
        )




        SELECT 
        CASE WHEN cid LIKE 'NAS%' THEN  SUBSTRING(cid,4,LEN(cid))
	        ELSE cid 
        END AS cid,
        CASE WHEN bdate > GETDATE() THEN NULL
        ELSE bdate
        END AS bdate,
        CASE WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'FEMALE'
	         WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'MALE'
	         ELSE 'n/a'
        END AS gen

        FROM bronze.erp_cust_az12
        SET @end_time = GETDATE();


        SET @start_time =GETDATE();

        PRINT '>> TRUNCATING TABLE : Silver.erp_loc_a101'
        TRUNCATE TABLE Silver.erp_loc_a101;
        PRINT '>> INSERTING DATA INTO: Silver.erp_loc_a101';

        INSERT INTO Silver.erp_loc_a101(
        cid,
        cntry
        )


        SELECT 
        REPLACE (cid,'-','') cid,
        CASE WHEN TRIM (cntry) = 'DE' THEN 'GERMANY'
	         WHEN TRIM (cntry) IN ('US','USA') THEN 'UNITED SATATES'
	         WHEN TRIM (cntry) ='' OR cntry IS NULL THEN 'n/a'
	         ELSE TRIM (cntry)
        END AS cntry
        FROM bronze.erp_loc_a101 

        SET @end_time = GETDATE();

        SET @start_time =GETDATE();

        PRINT '>> TRUNCATING TABLE : Silver.erp_px_cat_g1v2'
        TRUNCATE TABLE Silver.erp_px_cat_g1v2;
        PRINT '>> INSERTING DATA INTO: Silver.erp_px_cat_g1v2';

        INSERT Silver.erp_px_cat_g1v2(
        id,
        cat,
        subact,
        maintenance
        )


        SELECT 
        id,
        cat,
        subact,
        maintenance
        FROM bronze.erp_px_cat_g1v2
        SET @end_time = GETDATE();
        PRINT 'LOAD DURATION : '+CAST(DATEDIFF(SECOND,@start_time,@end_time)AS NVARCHAR)+'SECONDS';

		SET @batch_end_time =GETDATE();
		PRINT '====================================================';
		PRINT 'LOADING BRONZE LAYER IS COMPLETED ';
		PRINT 'TOTAL LOAD DURATION: '+ CAST(DATEDIFF(SECOND,@batch_start_time , @batch_end_time) AS NVARCHAR)+'SECONDS';
		PRINT '====================================================';

	END TRY 
	BEGIN CATCH 
	PRINT '================================';
	PRINT 'ERROR OCCURED DURING LOADING TBRONZE LAYER ';
	PRINT 'ERROR MESSAGE '+ ERROR_MESSAGE();
	PRINT 'ERROR MESSAGE '+CAST (ERROR_NUMBER() AS NVARCHAR);
	PRINT 'ERROR MESSAGE '+CAST (ERROR_STATE() AS NVARCHAR);
	PRINT '================================';

	END CATCH 
END 
