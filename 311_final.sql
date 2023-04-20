-- EXPLORATORY DATA ANALYSIS PROJECT ANALYZING TRENDS IN NYC 311 DATABASE IN THE YEAR 2019

-- BEGINNER & INTEMEDIATE QUERIES 
-- purpose: get familiar with the data

-- What is the count of service requests per agency?
-- What agencies responded to the most requests?
SELECT agency, agency_name, COUNT(*) AS num_requests
FROM general
GROUP BY agency, agency_name
ORDER BY num_requests DESC;
--Answer: Top agencies: NYPD (839,260), HPD (466,139), DSNY (457,677)

--How many agencies had only 1 SR?
SELECT agency, agency_name, COUNT(*) AS num_requests
FROM general
GROUP BY agency, agency_name
HAVING COUNT(*) = 1;
--Answer: returns over 200 records for DOE (Dept of Education), as agency_name lists unique schools

--Show all complaint types related to a dog, and the total SR per type
SELECT complaint_type, COUNT(*) AS total_complaints
FROM general
GROUP BY complaint_type
HAVING complaint_type ILIKE '%dog%'
--ILIKE instead of LIKE for case insensitive
--Answer: returns 'Unleased Dog', 642 and 'Unlicensed Dog', 38

--What are the 5 most frequent complaint types?
SELECT complaint_type, COUNT(*) AS total_complaints
FROM general
GROUP BY complaint_type
ORDER BY total_complaints DESC
LIMIT 5;
/*Answer: 'Noise- Residential', 'Request Large Bulky Item Collection', 'HEAT/HOT WATER', 'Illegal Parking',
'Blocked Driveway'*/

--JOINING DATA

--Show the count of each type of noise complaint in each borough 
SELECT borough, complaint_type, COUNT(*) AS num_complaints
FROM general 
INNER JOIN locations
USING(unique_key)
GROUP BY borough, complaint_type
HAVING complaint_type LIKE 'Noise%' AND borough <> 'Unspecified'
ORDER BY borough, num_complaints DESC;

--ADVANCED QUERIES
--purpose: exploratory data analysis

--SUBQUERIES

--SUBQUERY IN SELECT
--Create a query that returns 3 numbers: 1) total SRs 2) total SRs resolved 3) total SRs in progress
SELECT COUNT(*) AS total_sr,
	(SELECT COUNT(*) FROM general WHERE status = 'Closed') AS total_resolved,
	(SELECT COUNT(*) FROM general WHERE status = 'In Progress') AS total_in_progress
FROM general;
--Answer: total_sr 2,630,685; total_resolved 2,549,981; total_in_progress 45,306

--SUBQUERY IN FROM
--Show the complaint type and number for DOHMH and DSNY. What is the top complaint for each agency?
SELECT agency, complaint_type, COUNT(*) AS num_complaints
FROM (
	SELECT agency, complaint_type
	FROM general
	WHERE agency = 'DOHMH' OR agency = 'DSNY') AS subquery
GROUP BY agency, complaint_type
ORDER BY agency, num_complaints DESC;
--Answer: DOHMH: 'Rodent'; DSNY: 'Request Large Bulky Item Collection'

--SUBQUERRY IN WHERE
--Show complaint types & descriptors that took place in 'Subway' or 'Subway Station' without use of JOINs
SELECT unique_key, complaint_type, descriptor
FROM general 
WHERE unique_key IN (
	SELECT unique_key
	FROM locations
	WHERE location_type LIKE 'Subway%');
	
--COMPLEX SUBQUERIES

--CORRELATED SUBQUERY
--How many srs were resolved on time vs. late?
SELECT resolution_status, COUNT(*) AS total_SRs_resolved
FROM(
	SELECT unique_key, created_date, deadline, closed_date,
	CASE WHEN closed_date <= deadline THEN 'On Time' ELSE 'Late' END AS resolution_status
	FROM (
		SELECT unique_key, created_date, (CAST(created_date AS date) + 9) AS deadline, closed_date
		FROM general
		WHERE (closed_date IS NOT NULL) AND (closed_date >= created_date)
) AS sq1
) AS sq2
GROUP BY resolution_status;
--Answer: On Time, 2,059,170; Late, 493,542

--NESTED SUBQUERY
--Percentages
--What percent of calls has each agency responded to?
SELECT agency, ROUND((COUNT(*) / (SELECT SUM(total_srs) 
				FROM (
					SELECT agency, COUNT(*) AS total_srs 
					FROM general 
					GROUP BY agency) AS sq)) * 100) AS percentage
FROM general
GROUP BY agency
ORDER BY percentage DESC
LIMIT 10;
--Answer: NYPD 32%, HPD 18%, DSNY 17%, DOT 11%, DEP 7%, DOB 5%, DPR 4%, DOHMH 2%, DCA 1%, DHS 1%

--CASE WHEN

--Let's say the city of NY wants to ensure all SRs are completed within a 10 day period: 
--1) Add a column 'deadline' showing the date by which each SR must be resolved
--2) Add a column that specifies whether the SR was completed on time or late
SELECT unique_key, created_date, deadline, closed_date,
CASE WHEN closed_date <= deadline THEN 'On Time' ELSE 'Late' END AS resolution_status
FROM (
	SELECT unique_key, created_date, (CAST(created_date AS date) + 9) AS deadline, closed_date
	FROM general
	WHERE (closed_date IS NOT NULL) AND (closed_date >= created_date)
) AS subquery;

--CASE WHEN in WHERE
--Assign a label to each city depending on the volume of service requests that city receives
--Show only the cities with Medium Volume
SELECT city, total_srs,
	CASE WHEN total_srs >= 100000 THEN 'Large Volume'
	WHEN total_srs >= 10000 THEN 'Medium Volume'
	WHEN total_srs >= 1000 THEN 'Small Volume'
	ELSE 'Miniscule Volume' END AS volume_of_srs
FROM (
	SELECT city, COUNT(*) AS total_srs
	FROM locations 
	GROUP BY city
	HAVING city IS NOT NULL
	ORDER BY total_srs DESC
	) AS subquery
WHERE CASE WHEN total_srs < 100000 AND total_srs >= 10000 THEN 'Medium Volume' END IS NOT NULL
ORDER BY total_srs DESC;

--CASE WHEN with Aggregates
--How many SRs were opened in Brooklyn in the summer of 2019 (months June-August)?
SELECT
	COUNT(
		CASE WHEN borough = 'BROOKLYN' AND 
		EXTRACT(MONTH from created_date) IN (6, 7, 8) THEN unique_key
		END) AS BK_summer_srs
FROM general
INNER JOIN locations
USING(unique_key)
--Answer: 218,761

--DATE AND TIME OPERATIONS
--Create new column that shows the interval between created_date and closed_date
SELECT unique_key, created_date, closed_date, 
EXTRACT(days FROM (AGE(created_date, closed_date)* -1)) AS days_to_complete
FROM general
WHERE (closed_date IS NOT NULL) AND (closed_date >= created_date)
ORDER BY days_to_complete;
/* filtering out null values, 
and values where the closed_date comes before created_date as that does not make sense */

--CTE or TEMP TABLE
-- Using above query as 1) CTE and then 2) FROM Subquery
--Question: Whats's the AVG, MAX, and MIN amt of time that it takes for a SR to be completed?
--1) 
WITH CTE AS (
	SELECT unique_key, created_date, closed_date, 
EXTRACT(days FROM (AGE(created_date, closed_date)* -1)) AS days_to_complete
FROM general
WHERE (closed_date IS NOT NULL) AND (closed_date >= created_date)
) -- removed ORDER BY clause to improve run time

SELECT ROUND(AVG(days_to_complete)) AS avg_interval, 
	MAX(days_to_complete) AS max_interval,
	MIN(days_to_complete) AS min_interval
FROM CTE;
--Answer: it takes an avg of 4 days to fulfill a SR, a maximum of 30, and a minimum of 0

-- 2) same query but using subquery in FROM instead
SELECT ROUND(AVG(days_to_complete)) AS avg_interval, 
	MAX(days_to_complete) AS max_interval,
	MIN(days_to_complete) AS min_interval
FROM (
	SELECT unique_key, created_date, closed_date, 
	EXTRACT(days FROM (AGE(created_date, closed_date)* -1)) AS days_to_complete
	FROM general
	WHERE (closed_date IS NOT NULL) AND (closed_date >= created_date)
) AS subquery;

--WINDOW FUNCTIONS

--RANK
--rank zipcodes w highest volume of 311 calls per borough
WITH CTE AS (SELECT borough, incident_zip, COUNT(*) AS total_srs
FROM locations
GROUP BY borough, incident_zip
HAVING borough <> 'Unspecified' 
ORDER BY borough, total_srs DESC)

SELECT borough, incident_zip, total_srs,
RANK() OVER(PARTITION BY borough
			ORDER BY total_srs DESC) AS rank_borough
FROM CTE;
--RANK assigns the same number to rows w identical values, skipping over the next number
--use DENSE_RANK in cases where the next number should not be skipped

--AGGRGATES & NTILE IN WINDOW FUNCTIONS

--Show the quarterly average SRs
With CTE AS (SELECT EXTRACT(MONTH from created_date) AS month, COUNT(*) AS total_srs,
NTILE(4) OVER() AS quartile
FROM general
GROUP BY month
ORDER BY month)

SELECT month, total_srs, ROUND(AVG(total_srs) OVER(PARTITION BY quartile)) AS quarterly_avg
FROM CTE;

--SLIDING WINDOWS
--Show the sliding average of the past 3 months
WITH CTE AS (SELECT EXTRACT(MONTH from created_date) AS month, COUNT(*) AS total_srs
FROM general
GROUP BY month
ORDER BY month)

SELECT month, total_srs,
ROUND(AVG(total_srs) OVER(ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)) AS sliding_avg
FROM CTE;

--ROLLUP
--What if I want to know the total noise complaints per borough?
--1. use CTE to show the count of each type of noise complaint in each borough 
--2. use ROLLUP to show group-level totals
With CTE AS (
SELECT borough, complaint_type, COUNT(*) AS num_complaints
FROM general 
INNER JOIN locations
USING(unique_key)
GROUP BY borough, complaint_type
HAVING complaint_type LIKE 'Noise%' AND borough <> 'Unspecified'
ORDER BY borough, num_complaints DESC)

SELECT borough, COALESCE(complaint_type, 'TOTAL') AS complaint_type,
	SUM(num_complaints) AS total_complaints
FROM CTE
GROUP BY borough, ROLLUP(complaint_type)
ORDER BY borough, total_complaints DESC;
--Answer: Bronx 97,887; Brooklyn 135,058; Manhattan 137,824; Queens 94,044, Staten Island 13091
--COALESCE to replace '[null]' with 'TOTAL'

--PROJECT END!