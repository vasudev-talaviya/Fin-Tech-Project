CREATE DATABASE Digital_Payments_India_Analysis;

USE Digital_Payments_India_Analysis;

-- show the table names
SELECT name FROM sys.tables;

-- Problem statement:

-- 1).Find the top 10 States/UTs by UPI transaction volume.
SELECT TOP(10) * FROM digital_payments_upi_transactions_state_2024
ORDER BY UPI_Transaction_Volume_Million DESC;

-- 2).Identify States/UTs where Average Transaction Value is higher than the overall average.
SELECT AVG(Average_Transaction_Value_Rupees) FROM digital_payments_upi_transactions_state_2024 -- AVERAGE 1620

SELECT * FROM digital_payments_upi_transactions_state_2024
WHERE Average_Transaction_Value_Rupees > (SELECT AVG(Average_Transaction_Value_Rupees) 
                                            FROM digital_payments_upi_transactions_state_2024);

-- 3).Find States/UTs having Digital Acceptance Points lower than the overall average.
SELECT AVG(Digital_Acceptance_Points) FROM digital_payments_infrastructure_state_2024; -- AVERAGE 2101677

SELECT * FROM digital_payments_infrastructure_state_2024
WHERE Digital_Acceptance_Points < (SELECT AVG(Digital_Acceptance_Points) 
                                        FROM digital_payments_infrastructure_state_2024);

-- 4). Classify States/UTs as High, Moderate, or Low Digital Payment Adoption based on UPI transactions per lakh population.

WITH Percentiles AS
(
    SELECT DISTINCT
        PERCENTILE_CONT(0.33)
            WITHIN GROUP (
                ORDER BY UPI_Transactions_per_Lakh_Population_Million
            ) OVER () AS P33,

        PERCENTILE_CONT(0.67)
            WITHIN GROUP (
                ORDER BY UPI_Transactions_per_Lakh_Population_Million
            ) OVER () AS P67
    FROM digital_payments_upi_transactions_state_2024
)
SELECT
    U.State_UT,
    U.UPI_Transactions_per_Lakh_Population_Million,
    CASE
        WHEN U.UPI_Transactions_per_Lakh_Population_Million < P.P33
            THEN 'Low'
        WHEN U.UPI_Transactions_per_Lakh_Population_Million < P.P67
            THEN 'Moderate'
        ELSE 'High'
    END AS Adoption_Level
FROM digital_payments_upi_transactions_state_2024 AS U
CROSS JOIN Percentiles AS P
ORDER BY U.UPI_Transactions_per_Lakh_Population_Million DESC;

-- percentaile number 0.33 => below 0.962 ==> Low
--                    0.962 to below 1.792 ==> Moderate
--                    1.792 or above ==> High

-- percentaile clean data-driven thresholds.

-- This data is right skew so that not possiable to standard deviation base calculation through classify


-- 5).Calculate Digital Acceptance Points per 1 lakh population and find the top 5 States/UTs.

SELECT TOP (5) WITH TIES
       i.State_UT,
       i.Digital_Acceptance_Points,
       p.Population_Lakh,
       CAST(i.Digital_Acceptance_Points * 1.0 / p.Population_Lakh AS DECIMAL(12,2)) AS Points_per_Lakh
FROM digital_payments_infrastructure_state_2024  i
JOIN digital_payments_population_banking_state_2024 p ON i.State_UT = p.State_UT
ORDER BY Points_per_Lakh DESC;


-- 6).Join all three tables and prepare a combined State/UT-wise digital payments report

SELECT 
    a.State_UT,
    a.POS_Terminals,
    a.QR_Acceptance_Points,
    a.ATMs,
    a.Digital_Acceptance_Points,
    a.Acceptance_Points_per_Lakh_Population,

    b.Population_Lakh,
    b.Bank_Accounts_Lakh,
    b.Internet_Users_Lakh,
    b.Smartphone_Users_Lakh,
    b.Bank_Accounts_per_Lakh_Population,

    c.UPI_Transaction_Volume_Million,
    c.UPI_Transaction_Value_Crore,
    c.Average_Transaction_Value_Rupees,
    c.UPI_Transactions_per_Lakh_Population_Million

FROM digital_payments_infrastructure_state_2024 AS a

INNER JOIN digital_payments_population_banking_state_2024 AS b
ON a.State_UT = b.State_UT

INNER JOIN digital_payments_upi_transactions_state_2024 AS c
ON a.State_UT = c.State_UT;

-- 7).Identify States/UTs with above-average UPI transactions per lakh population but below-average digital infrastructure per 1 lakh population.

SELECT 
upi.State_UT,
upi.UPI_Transactions_per_Lakh_Population_Million,

infra.Acceptance_Points_per_Lakh_Population

from digital_payments_upi_transactions_state_2024 as upi
INNER JOIN digital_payments_infrastructure_state_2024 as infra
ON upi.State_UT = infra.State_UT

WHERE upi.UPI_Transactions_per_Lakh_Population_Million > (SELECT AVG(UPI_Transactions_per_Lakh_Population_Million) FROM digital_payments_upi_transactions_state_2024)
AND
infra.Acceptance_Points_per_Lakh_Population < (SELECT AVG(Acceptance_Points_per_Lakh_Population) FROM digital_payments_infrastructure_state_2024);