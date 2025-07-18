create database projects;

use projects;

create table Airline_Routes
(
FlightID varchar(20),
RouteCode varchar(20),
Origin varchar(15),
Destination varchar(15),
FlightDate varchar(20),
FlightDurationMins int,
AircraftType varchar(30),
SeatsAvailable int,
SeatsSold int,
Revenue int,
OperationalCost int
);

-- load your dataset into the table
load data local infile 'C:\Users\mihir\OneDrive\Desktop\New folder\SQL\AirlineRoutesData.csv' into table Airline_Routes fields terminated by ','  enclosed by '"' ignore 1 rows;

--- if the path isnot working you can use [\\ or /] instead of this \.
-- if this is not working also, then you can use table data import wizard in mysql server.


-- 1. Top 10 most frequant routes based on number of flights.
SELECT RouteCode as Most_Frequant_Routes, COUNT(*) AS flight_count
FROM Airline_Routes
GROUP BY RouteCode
ORDER BY flight_count DESC
LIMIT 10;


-- 2. Average Revenue, Cost, and Profit
-- Average Revenue, Cost, and Profit Per Route
SELECT 
    RouteCode,
    AVG(Revenue) AS avg_revenue,
    AVG(OperationalCost) AS avg_cost,
    AVG(Revenue - OperationalCost) AS avg_profit
FROM Airline_Routes
GROUP BY RouteCode
ORDER BY avg_profit DESC;

-- Average Revenue, Cost, and Profit Per Origin.
SELECT 
    Origin,
    AVG(Revenue) AS avg_revenue,
    AVG(OperationalCost) AS avg_cost,
    AVG(Revenue - OperationalCost) AS avg_profit
FROM Airline_Routes
GROUP BY Origin
ORDER BY avg_profit DESC;


 -- 3. Underperforming Routes (Negative Average Profit)
SELECT 
    RouteCode,
    AVG(Revenue - OperationalCost) AS avg_profit
FROM Airline_Routes
GROUP BY RouteCode
HAVING AVG(Revenue - OperationalCost) < 0
ORDER BY avg_profit;
-- this query returns a Empty set...

-- Underperforming Routes (lowest Average Profit)
SELECT 
    RouteCode,
    AVG(Revenue - OperationalCost) AS avg_profit
FROM Airline_Routes
GROUP BY RouteCode
ORDER BY avg_profit Asc
limit 10;

-- 4. Seat Occupancy % for Each Route
SELECT 
    RouteCode,
    ROUND(AVG(SeatsSold * 100.0 / NULLIF(SeatsAvailable, 0)), 2) AS avg_occupancy_pct
FROM Airline_Routes
GROUP BY RouteCode
ORDER BY avg_occupancy_pct DESC;

-- 5. Monthly Profit Trend Per Route
WITH flight_cte AS (
    SELECT 
        RouteCode,
        DATE_FORMAT(FlightDate, '%Y-%m-01') AS FlightMonth,
        (Revenue - OperationalCost) AS Profit
    FROM Airline_Routes
)
SELECT 
    RouteCode,
    FlightMonth,
    SUM(Profit) AS monthly_profit
FROM flight_cte
GROUP BY RouteCode, FlightMonth
ORDER BY RouteCode, FlightMonth;

-- 6. Domestic vs International Routes (Assuming Airport Info). 
WITH AirportCountry AS (
    SELECT 'DEL' AS AirportCode, 'India' AS Country UNION ALL
    SELECT 'BOM', 'India' UNION ALL
    SELECT 'BLR', 'India' UNION ALL
    SELECT 'HYD', 'India' UNION ALL
    SELECT 'MAA', 'India' UNION ALL
    SELECT 'GOI', 'India' UNION ALL
    SELECT 'CCU', 'India' UNION ALL
    SELECT 'DXB', 'UAE' UNION ALL
    SELECT 'JFK', 'USA' UNION ALL
    SELECT 'LHR', 'UK'
),
FlightCountry AS ( 
    SELECT 
        f.RouteCode,
        f.Origin,
        f.Destination,
        f.Revenue,
        f.OperationalCost,
        origin.Country AS OriginCountry,
        dest.Country AS DestinationCountry
    FROM Airline_Routes AS f 
    LEFT JOIN AirportCountry AS origin ON f.Origin = origin.AirportCode
    LEFT JOIN AirportCountry AS dest ON f.Destination = dest.AirportCode
),
LabeledFlights AS (
    SELECT 
        RouteCode,
        CASE
            WHEN OriginCountry IS NOT NULL 
             AND DestinationCountry IS NOT NULL 
             AND OriginCountry = DestinationCountry
            THEN 'Domestic'
            ELSE 'International'
        END AS RouteType,
        (Revenue - OperationalCost) AS Profit
    FROM FlightCountry 
)
SELECT 
    RouteType,
    COUNT(*) AS TotalFlights,
    SUM(Profit) AS TotalProfit,
    ROUND(AVG(Profit), 2) AS AvgProfitPerFlight
FROM LabeledFlights
GROUP BY RouteType;

-- 7. Rank Routes by Revenue Per Minute.
SELECT 
    RouteCode,
    ROUND(SUM(Revenue) / NULLIF(SUM(FlightDurationMins), 0), 2) AS RevenuePerMinute,
    RANK() OVER (ORDER BY SUM(Revenue) / NULLIF(SUM(FlightDurationMins), 0) DESC) AS RouteRank
FROM Airline_Routes
GROUP BY RouteCode
ORDER BY RouteRank
LIMIT 25;

