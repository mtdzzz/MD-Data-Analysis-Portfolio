WITH customer_base AS (
    SELECT
        CustomerKey,
        CONCAT(FirstName, ' ', LastName) AS Name
    FROM [AdventureWorksDW2019].[dbo].[DimCustomer]
),

RFM_base AS (
SELECT 
    c.Name AS Name,
    DATEDIFF(
        day, 
        MAX(CONVERT(datetime, CAST(d.DateKey AS CHAR(8)), 112)), 
        CONVERT(date, GETDATE())
    ) AS Recency_value,
    COUNT(*) AS Frequency_value,
    SUM(s.SalesAmount) AS Monetary_value
FROM [AdventureWorksDW2019].[dbo].[FactInternetSales] AS s
JOIN [AdventureWorksDW2019].[dbo].[DimDate] AS d 
    ON CONVERT(datetime, CAST(d.DateKey AS CHAR(8)), 112) = s.OrderDate
JOIN customer_base AS c 
    ON c.CustomerKey = s.CustomerKey
WHERE d.CalendarYear = 2024
GROUP BY c.Name
),

RFM_score as (
select 
	*,
	NTILE(5) OVER (ORDER BY Recency_value) as R_score,
	NTILE(5) OVER (ORDER BY Frequency_value) as F_score,
	NTILE(5) OVER (ORDER BY Monetary_value) as M_score
from RFM_base
),

RFM_final AS (
select 
	*,
	CONCAT(R_score, F_score, M_score) as RFM_score
from RFM_score
)

select 
	r.*,
	s.Segment as Customer_segment
from RFM_final as r 
join [AdventureWorksDW2019].[dbo].[segment_scores] as s on r.RFM_score = s.Scores