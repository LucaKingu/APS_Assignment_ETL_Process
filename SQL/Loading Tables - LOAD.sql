--This is where the LOAD will take place, the transformed views will be loaded into 
--a data mart via dimensions and a fact table.

USE APS_Assignment;

CREATE SCHEMA [DM] -- Data Mart


--First I need to create the Dimension/Fact tables
CREATE TABLE DM.DimCustomer
(
	CUSTOMER_PROFILE INT PRIMARY KEY,
	CUSTOMER_NAME VARCHAR(80) NOT NULL,	-- size of 80 since I concatenated Name and Surname in the concat
	CUSTOMER_TYPE VARCHAR(20) NOT NULL,
	SALUTATION VARCHAR(10) NULL
);
GO




CREATE TABLE DM.DimAccount
(
	ACCOUNT_NUMBER VARCHAR(40) PRIMARY KEY,
	ACCOUNT_DESIGNATION VARCHAR(40) NOT NULL,
	CUSTOMER_GROUP INT,
	PROFILE_NUMBER INT NOT NULL
);
GO



CREATE TABLE DM.DimDateTime
(
	DATEKEY INT PRIMARY KEY,
	TRANSACTION_DATE DATE,
	DAY INT,
	MONTH INT,
	YEAR INT
);
GO




CREATE TABLE DM.FactsTransaction
(
	FACTS_TRANSACTION_ID INT PRIMARY KEY IDENTITY(1,1),	--Surrogate key, since TRANSACTION_NUMBER can show up multiple times.
	TRANSACTION_NUMBER INT NOT NULL,
	TRANSACTION_AMOUNT DECIMAL(10,2) NOT NULL,
	PRODUCT_CODE INT NOT NULL,
	ACCOUNT_NUMBER VARCHAR(40),
    CUSTOMER_PROFILE INT,
    DATEKEY INT,

	CONSTRAINT FK_FactsTransaction_Profile
    FOREIGN KEY (CUSTOMER_PROFILE) REFERENCES DM.DimCustomer(CUSTOMER_PROFILE),

	CONSTRAINT FK_FactsTransaction_Account
    FOREIGN KEY (ACCOUNT_NUMBER) REFERENCES DM.DimAccount(ACCOUNT_NUMBER),

	CONSTRAINT FK_FactsTransaction_Date
    FOREIGN KEY (DATEKEY) REFERENCES DM.DimDateTime(DATEKEY)
);
GO



--Now I need to insert the Dimension/Fact tables with the transformed data from the views.
INSERT INTO DM.DimCustomer(CUSTOMER_PROFILE, CUSTOMER_NAME, CUSTOMER_TYPE, SALUTATION)
SELECT CD.CUSTOMER_PROFILE,
	   CD.CUSTOMER_NAME,
	   CD.CUSTOMER_TYPE,
	   CD.SALUTATION
FROM DW.CUSTOMER_DATA CD

SELECT * FROM DM.DimCustomer





INSERT INTO DM.DimAccount(ACCOUNT_NUMBER, ACCOUNT_DESIGNATION, CUSTOMER_GROUP, PROFILE_NUMBER)
SELECT
	TR.[Account Number],
	MIN(TR.[Account Designation]),	--I Don't need all instances of account numbers, hence the first one that comes up is saved into the dimension
	MIN(TR.[Customer Group]),
	MIN(TR.[Profile Number])
FROM DW.TRANSACTIONS TR
WHERE TR.[Account Number] NOT IN (
	SELECT ACCOUNT_NUMBER FROM DM.DimAccount
)
GROUP BY TR.[Account Number];

SELECT * FROM DM.DimAccount





INSERT INTO DM.DimDateTime (DATEKEY, TRANSACTION_DATE, DAY, MONTH, YEAR)
SELECT 
    CONVERT(INT, FORMAT([Transaction Date], 'yyyyMMdd')) AS DATEKEY, --Will be converted to INT for DM.DateTime primary key, also in yyyyMMdd format to be in chronological order
    [Transaction Date] AS TRANSACTION_DATE,
    DAY([Transaction Date]),
    MONTH([Transaction Date]),
    YEAR([Transaction Date])
FROM (
    SELECT DISTINCT [Transaction Date] FROM DW.TRANSACTIONS
) AS UniqueDates;
GO

SELECT * FROM DM.[DimDateTime]
GO




--Star Schema on to FactsTransaction
INSERT INTO DM.FactsTransaction (TRANSACTION_NUMBER, TRANSACTION_AMOUNT, PRODUCT_CODE, ACCOUNT_NUMBER, CUSTOMER_PROFILE, DATEKEY)
SELECT 
    TR.[Transaction Number],
    TR.[Transaction Amount],
    TR.[Product Code],
    TR.[Account Number],
    TR.[Profile Number],
    CONVERT(INT, FORMAT(TR.[Transaction Date], 'yyyyMMdd')) AS DATEKEY
FROM DW.TRANSACTIONS TR

GO

SELECT * FROM DM.FactsTransaction
GO


drop table dm.FactsTransaction

SELECT [Transaction Number], COUNT(*) AS cnt
FROM DW.TRANSACTIONS
GROUP BY [Transaction Number]
HAVING COUNT(*) > 1;