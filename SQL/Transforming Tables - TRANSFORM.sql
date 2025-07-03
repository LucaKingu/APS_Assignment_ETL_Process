--This is where the TRANSFORMATION will take place via Views.

USE APS_Assignment;

CREATE SCHEMA [DW]; --DataWarehouse
GO

--SQL SERVER
--First Helper view to transform NULL values and add customer_type column
CREATE OR ALTER VIEW DW.CUSTOMER_TRANSFORM
AS
SELECT BC.CUSTOMER_PROFILE,
	   BC.CUSTOMER_PK,
	   PC.CUSTOMER_NAME,
	   PC.CUSTOMER_SURNAME,
	   NULL AS COMPANY_TITLE,
	   'Physical' AS CUSTOMER_TYPE,
	   NULLIF(bc.SALUTATION, 'NULL') AS SALUTATION	--Cater for NULL string
	FROM STG.BANKING_CUSTOMERS BC
	JOIN STG.PHYSICAL_CUSTOMERS PC ON BC.CUSTOMER_PK = PC.CUSTOMER_PK

	UNION ALL

SELECT 
	BC.CUSTOMER_PROFILE,
	BC.CUSTOMER_PK,
	NULL AS CUSTOMER_FIRSTNAME,
	NULL AS CUSTOMER_LASTNAME,
	CC.COMPANY_TITLE,
	'Corporate' AS CUSTOMER_TYPE,
	BC.SALUTATION
	FROM STG.BANKING_CUSTOMERS BC
	JOIN STG.CORPORATE_CUSTOMERS CC
	ON BC.CUSTOMER_PK = CC.CUSTOMER_PK
GO
--Other columns could be catered for null, but since I could go through such a small data I confirmed that it is only as salutation

SELECT * FROM DW.CUSTOMER_TRANSFORM
GO







--Second view to transform and normalize name + surname, as well as to get rid of unecessary columns
CREATE OR ALTER VIEW DW.CUSTOMER_DATA
AS
SELECT CUSTOMER_PK,
	   CUSTOMER_PROFILE,
	   SALUTATION,
	CASE
		WHEN CUSTOMER_TYPE = 'physical' THEN CUSTOMER_NAME + ' ' + CUSTOMER_SURNAME
		ELSE COMPANY_TITLE
	END AS CUSTOMER_NAME,
		   CUSTOMER_TYPE
	FROM DW.CUSTOMER_TRANSFORM
GO

SELECT * FROM DW.CUSTOMER_DATA --Just realised that the NULL values for Salutation are the corporate accounts.
GO;



--Oracle Data
--Only 1 view needed for transformation - Joins, adding detail to transaction_amount(+/-)
CREATE OR ALTER VIEW DW.TRANSACTIONS
AS
SELECT ACC.ACCOUNT_NUMBER AS 'Account Number',
	   ACC.ACCOUNT_DESIGNATION AS 'Account Designation',
	   ACC.CUSTOMER_GROUP_ID AS 'Customer Group',
	   PG.PROFILE_NUMBER AS 'Profile Number',
	   ACC.PRODUCT_CODE AS 'Product Code',
	   TR.TRANSACTION_NUMBER AS 'Transaction Number',
	   TR.TRANSACTION_DATE AS 'Transaction Date',
	   CASE WHEN TR.DEBIT_CREDIT = 'C' THEN TR.TRANSACTION_AMOUNT	--This allows the removal of debit_credit column
	   ELSE -TR.TRANSACTION_AMOUNT END AS 'Transaction Amount'	FROM STG.TRANSACTIONS TR
	JOIN STG.ACCOUNTS ACC
	ON TR.TRANSACTION_ACCOUNT_NUMBER = ACC.ACCOUNT_NUMBER
	LEFT JOIN STG.PROFILE_GROUPS PG
	ON PG.CUSTOMER_GROUP_ID = ACC.CUSTOMER_GROUP_ID


SELECT * FROM DW.TRANSACTIONS
ORDER BY [Transaction Amount] DESC	--Since only 6 are credited they can be hard to miss.