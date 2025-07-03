--This is for PART 2: BI ENGINEERING

USE APS_Assignment;
GO

--First query is for myself to test, get all the data and see all columns working together.
SELECT *
FROM DM.FactsTransaction FT
FULL JOIN DM.DimAccount DA
ON DA.ACCOUNT_NUMBER = FT.ACCOUNT_NUMBER
FULL JOIN DM.DimCustomer DC
ON DC.CUSTOMER_PROFILE = FT.CUSTOMER_PROFILE
FULL JOIN DM.DimDateTime DDT
ON DDT.DATEKEY = FT.DATEKEY
GO




--Create a report that shows the balances of each account per month assuming
--that the accounts where all opened on the 1st January 2023 (0 balance at that date)
CREATE OR ALTER PROC MonthlyAccountBalance
	@START_DATE DATE,
	@END_DATE DATE
AS
BEGIN
	SELECT
		DA.ACCOUNT_NUMBER AS 'Account Number',
		DC.CUSTOMER_NAME AS 'Full Name',
		SUM(FT.TRANSACTION_AMOUNT) AS 'Monthly C/D',

		SUM(SUM(FT.TRANSACTION_AMOUNT)) OVER (		--This needed help of AI as I had not used OVER PARTITION BY as much, checked how it works and that id does of course :)
        PARTITION BY DA.ACCOUNT_NUMBER
        ORDER BY DT.TRANSACTION_DATE
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
		) AS 'Running Balance',

		DT.TRANSACTION_DATE AS 'Full Date',
		DT.MONTH AS 'Month',
		DC.SALUTATION AS 'Salutation',
		DA.CUSTOMER_GROUP AS 'Customer Group',
		DA.PROFILE_NUMBER AS 'Profile Number',
		FT.PRODUCT_CODE AS 'Product Code',
		DC.CUSTOMER_TYPE AS 'Customer Type'
	FROM DM.FactsTransaction FT
	JOIN DM.DimAccount DA
	ON DA.ACCOUNT_NUMBER = FT.ACCOUNT_NUMBER
	JOIN DM.DimCustomer DC
	ON DC.CUSTOMER_PROFILE = FT.CUSTOMER_PROFILE
	JOIN DM.DimDateTime DT
	ON DT.DATEKEY = FT.DATEKEY
	WHERE DT.TRANSACTION_DATE BETWEEN @START_DATE AND @END_DATE
	GROUP BY
		DA.ACCOUNT_NUMBER,
		DC.CUSTOMER_NAME,
		DT.TRANSACTION_DATE,
		DT.[MONTH],
		DC.SALUTATION,
		DA.CUSTOMER_GROUP,
		DA.PROFILE_NUMBER,
		FT.PRODUCT_CODE,
		DC.CUSTOMER_TYPE
	ORDER BY
		DA.ACCOUNT_NUMBER
END;
GO

--Tested with first 2 quarters of 2023 (January - June)
EXEC MonthlyAccountBalance '2023-01-01', '2023-06-30';
GO







--Create a report showing all transactions of a customer for a specific date range
CREATE OR ALTER PROC AllCustomerTransactions
	@START_DATE DATE,
	@END_DATE DATE,
	@CUSTOMER VARCHAR(40)
AS
BEGIN
	SELECT 
	FT.TRANSACTION_NUMBER AS 'Transaction Number',
	FT.TRANSACTION_AMOUNT AS 'Transaction Amount',
	DT.TRANSACTION_DATE AS 'Transaction Date',
	DA.ACCOUNT_NUMBER AS 'Account Number',
	DC.CUSTOMER_NAME AS 'Customer Name',
	DC.SALUTATION AS 'Salutation',
	DA.CUSTOMER_GROUP AS 'Customer Group',
	DC.CUSTOMER_PROFILE,
	DA.PROFILE_NUMBER AS 'Profile Number',
	DA.ACCOUNT_DESIGNATION,
	FT.CUSTOMER_PROFILE AS 'Customer Profile',
	FT.PRODUCT_CODE AS 'Product Code'
	FROM DM.FactsTransaction FT
	JOIN DM.DimAccount DA
	ON DA.ACCOUNT_NUMBER = FT.ACCOUNT_NUMBER
	JOIN DM.DimCustomer DC
	ON DC.CUSTOMER_PROFILE = FT.CUSTOMER_PROFILE
	JOIN DM.DimDateTime DT
	ON DT.DATEKEY = FT.DATEKEY
	WHERE DA.ACCOUNT_NUMBER = @CUSTOMER AND DT.TRANSACTION_DATE BETWEEN @START_DATE AND @END_DATE
END
GO


--Works as intended, I executed the previous proc to get data on this Account number as it contains 6 transactions 
--within the specified date. Hence, I got the same account number with a much smaller date range (1 day) where 
--4 of those 6 transactions took place.
EXEC AllCustomerTransactions '2023-02-19' , '2023-03-19' , '0232DC75F95C04A3FBD5F34B1858DEB3'







--Find the month with the most deposits sum for the entire year.
--I don't see the point of making a procedure for this one, no parameters make sense here.
SELECT 
    DT.YEAR,	--Confirms that my data is only 2023 , no need to filter
    DT.MONTH,
    SUM(FT.TRANSACTION_AMOUNT) AS 'Total Deposits'
FROM DM.FactsTransaction FT
JOIN DM.DimDateTime DT
ON FT.DATEKEY = DT.DATEKEY
WHERE FT.TRANSACTION_AMOUNT > 0  --Only deposits, my data only consisted of 5 instances
GROUP BY DT.YEAR, DT.MONTH
ORDER BY 'Total Deposits' DESC
