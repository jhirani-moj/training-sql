/* Training: SQL - Exercises */
-- DESCRIPTION: The purpose of this script is to provide exercises for the trainee to practice what 
--				was covered in the accompanying `training_sql_mediumuser.ipynb` notebook.

USE [AdventureWorks];

/* Question 1: Subquerying vs. temporary tables */
-- Q.		Can you rewrite the query below in (2.) to use subquerying instead?
WITH table_cte AS
(
    SELECT [ProductID]
        ,[Name]
        ,[ProductNumber]
        ,[Color]
        ,[StandardCost]
        ,[ListPrice]
        ,[DaysToManufacture]
        ,[DailyCostOfManufacture] = CASE 
            WHEN [DaysToManufacture] = 0 THEN 0
            ELSE [StandardCost]/[DaysToManufacture]
            END
        ,[SellStartDate]
        ,[SellEndDate]
        ,[DailyUnitRevenue] = CASE
            WHEN [SellStartDate] = [SellEndDate] THEN 0
            ELSE [ListPrice]/CAST(([SellEndDate] - [SellStartDate]) AS FLOAT)
            END
        ,[DiscontinuedDate]
    FROM [Production].[Product]
)

SELECT [ProductID]
    ,[Name]
    ,[ProductNumber]
    ,[Color]
    ,[StandardCost]
    ,[ListPrice]
    ,[DaysToManufacture]
    ,[DailyCostOfManufacture]
    ,[DailyUnitProfit] = [DailyUnitRevenue] - [DailyCostOfManufacture]
    ,[SellStartDate]
    ,[SellEndDate]
    ,[DiscontinuedDate]
FROM table_cte
WHERE [DailyCostOfManufacture] > 0
    AND [DailyUnitRevenue] > 0;
-- A.		Please write your query below here.
SELECT [ProductID]
    ,[Name]
    ,[ProductNumber]
    ,[Color]
    ,[StandardCost]
    ,[ListPrice]
    ,[DaysToManufacture]
    ,[DailyCostOfManufacture]
    ,[DailyUnitProfit] = [DailyUnitRevenue] - [DailyCostOfManufacture]
    ,[SellStartDate]
    ,[SellEndDate]
    ,[DiscontinuedDate]
FROM
(
	SELECT [ProductID]
        ,[Name]
        ,[ProductNumber]
        ,[Color]
        ,[StandardCost]
        ,[ListPrice]
        ,[DaysToManufacture]
        ,[DailyCostOfManufacture] = CASE 
            WHEN [DaysToManufacture] = 0 THEN 0
            ELSE [StandardCost]/[DaysToManufacture]
            END
        ,[SellStartDate]
        ,[SellEndDate]
        ,[DailyUnitRevenue] = CASE
            WHEN [SellStartDate] = [SellEndDate] THEN 0
            ELSE [ListPrice]/CAST(([SellEndDate] - [SellStartDate]) AS FLOAT)
            END
        ,[DiscontinuedDate]
    FROM [Production].[Product]
) AS table_intermediate
WHERE [DailyCostOfManufacture] > 0
    AND [DailyUnitRevenue] > 0;


/* Question 2: Ranking groups of variables by a counter with subquerying */
-- Q.		Can you rewrite the above query below in (4.) using either a local temporary table 
--			or CTE instead of subquerying?
SELECT [AddressID]
      ,[AddressLine1]
      ,[AddressLine2]
      ,[City]
      ,[StateProvinceID]
	  ,[PostalCode]
FROM
(
	SELECT [AddressID]
		,[AddressLine1]
		,[AddressLine2]
		,[City]
		,[StateProvinceID]
		,[RowNumber] = ROW_NUMBER() OVER (PARTITION BY [AddressLine1], [City], [StateProvinceID], [ModifiedDate] ORDER BY [AddressLine1], [City], [StateProvinceID], [ModifiedDate] ASC)
		,[PostalCode]
	FROM [Person].[Address]
) AS table_intermediate
-- remove duplicates
WHERE [RowNumber] = 1;
-- A.		Please write your query below here.
WITH cte_address AS
(
	SELECT [AddressID]
		,[AddressLine1]
		,[AddressLine2]
		,[City]
		,[StateProvinceID]
		,[RowNumber] = ROW_NUMBER() OVER 
		(
			PARTITION BY [AddressLine1], [City], [StateProvinceID] 
			ORDER BY [AddressLine1], [City], [StateProvinceID], [ModifiedDate] ASC
		)
		,[PostalCode]
	FROM [Person].[Address]
)
SELECT [AddressID]
      ,[AddressLine1]
      ,[AddressLine2]
      ,[City]
      ,[StateProvinceID]
	  ,[PostalCode]
FROM cte_address
WHERE [RowNumber] = 1;


/* Question 3: Pivoting */
-- Q.		In the [HumanResources].[Employee], pivot across `[MaritalStatus]` on `[VacationHours]`.
-- A.		Please write your query below.

-- check unique values for [Gender] as pivoting across this
SELECT DISTINCT [MaritalStatus] FROM [HumanResources].[Employee];

-- pivot across [Gender] on [VacationHours]
SELECT [BusinessEntityID]
      ,[NationalIDNumber]
      ,[LoginID]
      ,[JobTitle]
      ,[BirthDate]
      ,[Gender]
      ,[VacationHours_Married] = [M]
      ,[VacationHours_Single] = [S]
FROM
(
	SELECT [BusinessEntityID]
            ,[NationalIDNumber]
            ,[LoginID]
            ,[JobTitle]
            ,[BirthDate]
            ,[MaritalStatus]
            ,[Gender]
            ,[VacationHours]
	FROM [HumanResources].[Employee]
) AS table_intermediate
PIVOT
(
	AVG([VacationHours]) 
	FOR [MaritalStatus] IN ([M], [S])
) AS table_end;


/* Question 4: Tidy data principles */
-- Q.		Is the [Sales].[SpecialOffer] table in a tidy data format? 
--			If it is not in tidy data format, how can you manipulate the dataset so that it is? 
-- A.		Please write your query below.
WITH cte_quantity AS
(
	SELECT [SpecialOfferID]
		,[Description]
		,[DiscountPercent] = [DiscountPct]
		,[DiscountType] = [Type]
		,[Category]
		,[StartDate]
		,[EndDate]
		,[QuantityType]
		,[QuantityValue]
	FROM [Sales].[SpecialOffer]
	UNPIVOT
	(
		[QuantityValue]
		FOR [QuantityType] IN ([MinQty], [MaxQty])
	) AS table_unpivot
),

cte_date AS 
(
	SELECT [SpecialOfferID]
		,[Description]
		,[DiscountPercent]
		,[DiscountType]
		,[Category]
		,[DateType]
		,[DateValue]
		,[QuantityType]
		,[QuantityValue]
	FROM cte_quantity
	UNPIVOT
	(
		[DateValue]
		FOR [DateType] IN ([StartDate], [EndDate])
	) AS table_unpivot
)

SELECT [SpecialOfferID]
		,[Description]
		,[DiscountPercent]
		,[DiscountType]
		,[Category]
		,[DateType]
		,[DateValue]
		,[QuantityType]
		,[QuantityValue] 
FROM cte_date;