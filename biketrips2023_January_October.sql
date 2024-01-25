  -------------------- Preparation to create a table that includes months from January to October -------------

--As we have our data in different datasets for each month we will need to create a single table to merge all the datasets together
--We need to change the type of some columns to be the same for all the tables in order to merge all the datasets

ALTER TABLE Biketrips202301
DROP COLUMN duration, week_day, bike_type, user_type;

ALTER TABLE Biketrips202303
ALTER COLUMN start_station_id nvarchar(255);

ALTER TABLE Biketrips202305
ALTER COLUMN start_station_id nvarchar(255);

ALTER TABLE Biketrips202305
ALTER COLUMN end_station_id nvarchar(255);

-- Create the table
CREATE TABLE biketrips2023 (
	[ride_id] [nvarchar](255) NULL,
	[rideable_type] [nvarchar](255) NULL,
	[started_at] [datetime] NULL,
	[ended_at] [datetime] NULL,
	[start_station_name] [nvarchar](255) NULL,
	[start_station_id] [nvarchar](255) NULL,
	[end_station_name] [nvarchar](255) NULL,
	[end_station_id] [nvarchar](255) NULL,
	[start_lat] [float] NULL,
	[start_lng] [float] NULL,
	[end_lat] [float] NULL,
	[end_lng] [float] NULL,
	[member_casual] [nvarchar](255) NULL
) 


-- Insert the data into the table
INSERT INTO biketrips2023
SELECT * 
FROM Biketrips202301
UNION ALL 
SELECT *
FROM Biketrips202302
UNION ALL
SELECT *
FROM Biketrips202303
UNION ALL
SELECT *
FROM Biketrips202304
UNION ALL
SELECT *
FROM Biketrips202305
UNION ALL
SELECT*
FROM Biketrips202306
UNION ALL
SELECT *
FROM Biketrips202307
UNION ALL
SELECT *
FROM Biketrips202308
UNION ALL 
SELECT *
FROM Biketrips202309
UNION ALL 
SELECT *
FROM Biketrips202310

--See the table
SELECT *
FROM biketrips2023;

          ------------------------------------ Data Cleaning and Data Preparation ------------------------------------------

--Check for duplicates

WITH duplicates AS (
SELECT * ,
        ROW_NUMBER() OVER (PARTITION BY ride_id, start_station_id, end_station_id ORDER BY ride_id) AS row_num
FROM biketrips2023
)

SELECT *
FROM duplicates
WHERE row_num > 1 
-- No duplicates


-- Calculate the duration of the rides and then create a column to insert the result

SELECT CAST(ended_at - started_at AS TIME) AS duration
FROM biketrips2023

--Create a column for duration and insert the data
ALTER TABLE biketrips2023
ADD duration TIME;

UPDATE  biketrips2023
SET duration = CAST(ended_at - started_at AS TIME);

--It is also useful to create a column for the weekdays

SELECT started_at,
        CHOOSE(DATEPART(dw, started_at), 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday') AS week_day 
FROM biketrips2023

--Create the column and insert the data
ALTER TABLE biketrips2023
ADD week_day nvarchar(255);

UPDATE biketrips2023
SET week_day = CHOOSE(DATEPART(dw, started_at), 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')  

--We also need to change the naming of the rideable types and create a new column bike_type 
SELECT  rideable_type, (
             CASE WHEN rideable_type = 'electric_bike' THEN 'Electric'
			      WHEN rideable_type = 'classic_bike' THEN 'Classic'
				  WHEN rideable_type = 'docked_bike' THEN 'Docked' ELSE rideable_type
				  END ) AS bike_type
FROM biketrips2023

ALTER TABLE biketrips2023
ADD bike_type nvarchar(255);

UPDATE biketrips2023
SET bike_type =  CASE WHEN rideable_type = 'electric_bike' THEN 'Electric'
			      WHEN rideable_type = 'classic_bike' THEN 'Classic'
				  WHEN rideable_type = 'docked_bike' THEN 'Docked' ELSE rideable_type
				  END


				  
-- Change the members column with a new naming 
SELECT distinct member_casual
FROM biketrips2023

ALTER TABLE biketrips2023
ADD user_type nvarchar(255);

UPDATE biketrips2023
SET user_type = CASE WHEN member_casual = 'member' THEN 'Member'
                     WHEN member_casual = 'casual' THEN 'Casual'
					 ELSE member_casual
					 END;


-- Create also a column for the months

ALTER TABLE biketrips2023
ADD month NVARCHAR(255);

UPDATE biketrips2023
SET month = 
    CHOOSE(MONTH(started_at),
        'January', 'February', 'March', 'April', 'May', 'June', 
        'July', 'August', 'September', 'October', 'November', 'December')
FROM biketrips2023;


------------------------------------------------- Data exploration ------------------------------------------------------------
SELECT *
FROM biketrips2023;

-- Find the total rides for each user
SELECT user_type, 
        COUNT(*) AS total_rides
FROM biketrips2023
GROUP BY user_type 
-- We see that the Annual Members dominate with much more rides than the Casual Riders

-- Calculate the average ride duration for each user type
SELECT user_type, 
   CAST(DATEADD( ms,AVG(CAST(DATEDIFF( ms, '00:00:00', ISNULL(duration, '00:00:00')) as bigint)), '00:00:00' )  as TIME) as 'avg_duration'
FROM biketrips2023
GROUP BY user_type
-- Although Casual Riders tend to take longer trips with approximately 21mins when Members have an average of 12mins 

--And we can calculate the average duration per user and day of the week

SELECT user_type, week_day , 
   CAST(DATEADD( ms,AVG(CAST(DATEDIFF( ms, '00:00:00', ISNULL(duration, '00:00:00')) as bigint)), '00:00:00' )  as TIME) as 'avg_duration'
FROM biketrips2023
GROUP BY user_type, week_day
ORDER BY 2,1
-- Casual riders average duration increases during the weekend, the same goes for Members but not as much as Casuals 

-- Calculate the trip duration for each month and user type
SELECT user_type, month , 
   CAST(DATEADD( ms,AVG(CAST(DATEDIFF( ms, '00:00:00', ISNULL(duration, '00:00:00')) as bigint)), '00:00:00' )  as TIME) as 'avg_duration'
FROM biketrips2023
GROUP BY user_type, month
ORDER BY 3,1

--Calculate the total trips by day of the week, and also discover the most famous day of the week

SELECT  user_type, week_day, COUNT(*) AS total_rides
FROM biketrips2023
GROUP BY week_day, user_type
ORDER BY 3 DESC
-- So here we see that the most poplular day of the week for the period January-October is Saturday
-- Although when we run the same query grouping by the two types of users we see that the most popular day for Members is Tuesday 
-- and for Casual Riders is Saturday, and finally Casual's Saturday has more rides than Member's Sunday

--Let's calculate the percentage of users rides relative to the total number of rides
 WITH perc_of_rides AS (
 SELECT COUNT(*) AS total_rides,
        SUM(CASE WHEN user_type = 'Member' THEN 1 ELSE 0 END) AS member_rides,
		SUM(CASE WHEN user_type = 'Casual' THEN 1 ELSE 0 END) AS casual_rides
 FROM biketrips2023
 )
 SELECT 
         CONCAT(ROUND((member_rides*100 / total_rides), 1),'%') as member_perc_rides,
		 CONCAT(ROUND((casual_rides*100 / total_rides), 1),'%') AS casual_perc_rides
 FROM perc_of_rides;
 -- One more time we notice that Annual Members have the most rides during our period
 -- Members have 62% and Casual Riders have 38% of the total rides


 -- Now let's gain some insights about the progression of the number of rides from month to month
 WITH ride_progr AS (
 SELECT month, 
        COUNT(*) AS total_trips,
		LAG(COUNT(*),1) OVER (ORDER BY CASE month
         WHEN 'January' THEN 1
        WHEN 'February' THEN 2
        WHEN 'March' THEN 3
        WHEN 'April' THEN 4
        WHEN 'May' THEN 5
        WHEN 'June' THEN 6
        WHEN 'July' THEN 7
        WHEN 'August' THEN 8
        WHEN 'September' THEN 9
        WHEN 'October' THEN 10
		END) AS prev_month
 FROM biketrips2023
 GROUP BY month)

 SELECT month, total_trips,
  CONCAT(ROUND(((total_trips - prev_month)*1.0 / prev_month)*100,2), '%') AS perc_diff
 FROM ride_progr;


 --Find out the peak hours for the users
 -- We use a cte in which break the day into 2-hour segments using a Case

 WITH peak_times AS (
SELECT ride_id, user_type, week_day, CASE
  WHEN TRY_CAST(FORMAT(started_at, 'HH:mm:ss') AS TIME) BETWEEN '00:00:00.0000000' AND '02:00:00.0000000' THEN '00:00 - 02:00' 
  WHEN TRY_CAST(FORMAT(started_at, 'HH:mm:ss') AS TIME) BETWEEN '02:00:00.0000000' AND '04:00:00.0000000' THEN '02:00 - 04:00'
  WHEN TRY_CAST(FORMAT(started_at, 'HH:mm:ss') AS TIME) BETWEEN '04:00:00.0000000' AND '06:00:00.0000000' THEN '04:00 - 06:00'
  WHEN TRY_CAST(FORMAT(started_at, 'HH:mm:ss') AS TIME) BETWEEN '06:00:00.0000000' AND '08:00:00.0000000' THEN '06:00 - 08:00'
  WHEN TRY_CAST(FORMAT(started_at, 'HH:mm:ss') AS TIME) BETWEEN '08:00:00.0000000' AND '10:00:00.0000000' THEN '08:00 - 10:00'
  WHEN TRY_CAST(FORMAT(started_at, 'HH:mm:ss') AS TIME) BETWEEN '10:00:00.0000000' AND '12:00:00.0000000' THEN '10:00 - 12:00'
  WHEN TRY_CAST(FORMAT(started_at, 'HH:mm:ss') AS TIME) BETWEEN '12:00:00.0000000' AND '14:00:00.0000000' THEN '12:00 - 14:00'
  WHEN TRY_CAST(FORMAT(started_at, 'HH:mm:ss') AS TIME) BETWEEN '14:00:00.0000000' AND '16:00:00.0000000' THEN '14:00 - 16:00'
  WHEN TRY_CAST(FORMAT(started_at, 'HH:mm:ss') AS TIME) BETWEEN '16:00:00.0000000' AND '18:00:00.0000000' THEN '16:00 - 18:00'
  WHEN TRY_CAST(FORMAT(started_at, 'HH:mm:ss') AS TIME) BETWEEN '18:00:00.0000000' AND '20:00:00.0000000' THEN '18:00 - 20:00'
  WHEN TRY_CAST(FORMAT(started_at, 'HH:mm:ss') AS TIME) BETWEEN '20:00:00.0000000' AND '22:00:00.0000000' THEN '20:00 - 22:00'
  WHEN TRY_CAST(FORMAT(started_at, 'HH:mm:ss') AS TIME) BETWEEN '22:00:00.0000000' AND '23:59:59.0000000' THEN '22:00 - 00:00'
  ELSE FORMAT(started_at, 'HH:mm:ss')
  END AS time_period
FROM biketrips2023
 
)

SELECT user_type,
         time_period,
          COUNT(*) AS total_trips, --count the total trips per time segment
		 CONCAT(100* COUNT(*)/ SUM(COUNT(*)) OVER (PARTITION BY time_period),'%') AS perc_of_rides  -- percentage of trips relative to the total trips of each segment
  FROM peak_times
  GROUP BY user_type, time_period
  ORDER BY 2 ASC, 1 DESC

-- In this specific query with can observe the the hours of the day where the two types of users are more active
-- The Members have peak hours between 08:00 and 10:00 in the morning and 16:00 to 18:00
-- which indicates that they mostly use bikes to commute to work 
-- On the other hand Casual Riders have different peak hours that the Members which are between 14:00 and 20:00

--Top 5 starting stations for each type of user

SELECT * FROM (
SELECT user_type,
	   start_station_name,
	   COUNT(*) AS total_rides,
	   ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS total_trips_rank, --find the rank for both users
	   ROW_NUMBER() OVER (PARTITION BY user_type ORDER BY COUNT(*) DESC) AS rank_by_user_type, --define the rank for each user
	   CASE WHEN  ROW_NUMBER() OVER (PARTITION BY user_type ORDER BY COUNT(*) DESC) <=5 THEN 'Top5' --categorize the stations
	   ELSE 'No' 
	   END AS Top_stations
FROM biketrips2023
WHERE start_station_name IS NOT NULL 
GROUP BY user_type,
	   start_station_name ) a
WHERE Top_stations = 'Top5' 
 --The Top5 starting stations are  different for each user


 -- Let's also explore the most common routes for each type of user, and the average duration for each route

 SELECT user_type,
         CONCAT(start_station_name, ' to ', end_station_name) AS route,
		 COUNT(*) AS number_of_trips,
   CAST(DATEADD( ms,AVG(CAST(DATEDIFF( ms, '00:00:00', ISNULL(duration, '00:00:00')) as bigint)), '00:00:00' )  as TIME) as avg_duration
 FROM biketrips2023
 GROUP BY user_type, start_station_name, end_station_name
 ORDER BY 3 DESC


 -- Find the cases where the user returned to the same station and compare them to the total rides for each user type

WITH cte AS (
 SELECT user_type,
        CASE WHEN start_station_name = end_station_name THEN 'Same station'
		     ELSE 'Other station'
			 END AS path_definition
 FROM biketrips2023) 

  SELECT user_type, 
           path_definition,
		   COUNT(*)  as total,
			CONCAT((100*COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY user_type)),'%') AS percent_per_user
 FROM cte
 GROUP BY user_type, path_definition ;

 -- Find the most used bike type 

SELECT bike_type,
        COUNT(*) AS total_rides, 
		CONCAT(ROUND(COUNT(*)*100 / SUM(COUNT(*)*1.0) OVER(),2),'%')  AS percentage 
FROM biketrips2023
GROUP BY bike_type
-- Electric bike is the most popular type with 51.4% and Classic comes second with 45.5%

-- Which bike type prefer each user type
SELECT bike_type,
        user_type,
        COUNT(*) AS total_rides, 
		CONCAT(ROUND(COUNT(*)*100 / SUM(COUNT(*)*1.0) OVER(PARTITION BY user_type),2),'%')  AS percentage 
FROM biketrips2023
GROUP BY bike_type, user_type
ORDER BY user_type
-- Casual riders clearly prefer electric bikes over classic, however members are balanced between classic and electric   


-- And the usage of bikes by rides and also by day of the week  
SELECT bike_type,
       week_day,
        COUNT(*) AS total_rides, 
		CONCAT(ROUND(COUNT(*)*100 / SUM(COUNT(*)*1.0) OVER(PARTITION BY week_day),2),'%')  AS percentage 
FROM biketrips2023
GROUP BY bike_type, week_day
ORDER BY 2,1
-- Electric bike has on Fridays the most rides


--Percentage of rides by user type, bike type and day of the week
SELECT bike_type, user_type,
       week_day,
        COUNT(*) AS total_rides, 
		CONCAT(ROUND(COUNT(*)*100 / SUM(COUNT(*)*1.0) OVER(PARTITION BY week_day),2),'%')  AS percentage 
FROM biketrips2023
GROUP BY bike_type, week_day, user_type
ORDER BY 4 ASC


-- Calculate the distance traveled and the average speed of the rides during different days of the week, bike types selected and user type

-- First we are going to create a temporary table to store the data that we need about the users and the geography data of the stations
DROP TABLE IF EXISTS #tripdata
CREATE TABLE #tripdata (
ride_id nvarchar(255),
user_type nvarchar(255),
week_day nvarchar(255),
bike_type nvarchar(255),
duration time(7),
start_lat float,
start_lng float, 
end_lat float,
end_lng float
);

-- Insert the needed data into the temp table from the original dataset
INSERT INTO #tripdata
SELECT  ride_id, user_type,week_day, bike_type, duration ,start_lat, start_lng,
				   end_lat, end_lng 
FROM biketrips2023;
-- WHERE start_station_name is not null and end_station_name is not null 

-- Explore the data
-- We want to find the averages of distance traveled for each type of user, day of the week and bike type
-- and also calculate the speed of each ride based of the distance traveled and the duration of the ride in km/h
-- use a cte to get the results, and calculate the distance with the STDistance function in the select statement of the cte
WITH cte AS (
SELECT *,
           distance_in_meters = ROUND(geography::Point(start_lat, start_lng, 4326).STDistance(geography::Point(end_lat, end_lng, 4326)),2)
FROM #tripdata
WHERE start_lat is not null and start_lng is not null and end_lat is not null and end_lng is not null) 
-- we are going to use a subquery in the from statement where we make some calculations for the averages we mentioned
SELECT DISTINCT week_day, average_dist_by_day, 
                 user_type, average_dist_by_user,
				 bike_type, average_dist_by_bike, 
				 ROUND(AVG(kilometers_per_hour) OVER (PARTITION BY user_type, bike_type, week_day),2) AS 'avg_speed(km/h)'
				 
FROM (
SELECT *,
         ROUND(AVG(distance_in_meters) OVER (PARTITION BY user_type),1) AS average_dist_by_user ,
		 ROUND(AVG(distance_in_meters) OVER (PARTITION BY bike_type),1) AS average_dist_by_bike,
		 ROUND(AVG(distance_in_meters) OVER (PARTITION BY week_day),1) AS average_dist_by_day,
		( 3600*(distance_in_meters  / DATEDIFF(SECOND , 0, duration)) ) / 1000 AS kilometers_per_hour
FROM cte
WHERE DATEDIFF(SECOND , 0, duration) > 0 AND distance_in_meters > 0) a
--WHERE user_type = 'Member'

-- When we calculated the distance traveled we found out something very interesting, 
-- that many rides have the same starting and ending station, which means that the rider returned to the initial station
-- This fact it is natural to affect our calculations of the averages, so we need to take it into consideration in our work
-- It is wise to treat the cases where the distance is 0 as missing values 
-- and replace them with the average distance for each user and 
-- use conditional logic to handle them separately. This way, they won't overly influence our average calculations.
-- This is why I used the where statement earlier to exclude distances that are 0

--Whole data
SELECT *,
           distance_in_meters = ROUND(geography::Point(start_lat, start_lng, 4326).STDistance(geography::Point(end_lat, end_lng, 4326)),2)
FROM #tripdata
WHERE start_lat is not null and start_lng is not null and end_lat is not null and end_lng is not null --3,897,594 rows

-- Only cases where the distance is 0 
SELECT *,
           distance_in_meters = ROUND(geography::Point(start_lat, start_lng, 4326).STDistance(geography::Point(end_lat, end_lng, 4326)),2)
FROM #tripdata
WHERE start_lat is not null and start_lng is not null and end_lat is not null and end_lng is not null
 and ROUND(geography::Point(start_lat, start_lng, 4326).STDistance(geography::Point(end_lat, end_lng, 4326)),2) = 0
 -- 244,123 cases where the distance traveled 
 -- That means that in 6.2% of our cases the rider returned to the initial station

 -- Lets's explore if there is something special in this case between Members and Casual Riders
 
 SELECT  --week_day,
           user_type,
		   COUNT(*) AS total_rides_returned,
           distance_in_meters = ROUND(geography::Point(start_lat, start_lng, 4326).STDistance(geography::Point(end_lat, end_lng, 4326)),2)
FROM #tripdata
WHERE start_lat is not null and start_lng is not null and end_lat is not null and end_lng is not null
 and ROUND(geography::Point(start_lat, start_lng, 4326).STDistance(geography::Point(end_lat, end_lng, 4326)),2) = 0
 GROUP BY user_type, ROUND(geography::Point(start_lat, start_lng, 4326).STDistance(geography::Point(end_lat, end_lng, 4326)),2)--, week_day

 /* user_type	total_rides_returned	
 Casual	            136218	              
 Member	            107905    */ 
/*
   Casual Riders exhibit a notable trend of concluding their rides at the same station where they initiated.
   Upon introducing the consideration of weekdays, it becomes evident that a substantial portion of these rides occurs on weekends, particularly among Casual Riders.
   This observation strongly suggests that Casual Riders predominantly utilize the bikes for leisure purposes.
   
   Members also demonstrate a noteworthy occurrence of rides returning to the starting station. However, it's essential to contextualize this against the backdrop of their significantly higher total ride count compared to Casual Riders.
*/


/*
   In summary, our in-depth exploration of the dataset reveals distinct usage patterns and preferences between the two categories of bike users.
   Members significantly outnumber Casual riders in the total number of rides, while Casual riders tend to embark on longer journeys.

   Furthermore, divergent temporal trends emerge, with Members exhibiting higher activity on weekdays, particularly during commuting hours (08:00-10:00, 15:00-18:00),
   whereas Casual riders showcase heightened activity during weekends and later afternoon to evening hours (14:00-20:00), indicative of recreational usage.

   Additionally, peak hours reveal a disparity, suggesting that Members utilize the service for commuting during typical work hours, whereas Casual riders engage
   more during off-peak hours associated with leisure.

   The analysis also highlights variations in preferred starting stations for each user type. Annual Members show a balanced preference between electric and classic bikes,
   while Casual riders distinctly favor electric bikes. Docked bikes emerge as the least popular choice, with Members showing no usage of this option.


   Altogether, these insights underscore the diverse behaviors and preferences of bike users, shedding light on how distinct user segments engage with the bike-sharing service.
*/




















----------------------------------------- Choose data we will need for Tableau-----------------------------------------------




DROP TABLE IF EXISTS #distance_speed
CREATE TABLE #distance_speed (
ride_id nvarchar(255),
user_type nvarchar(255),
week_day nvarchar(255),
bike_type nvarchar(255),
duration time(7),
start_lat float,
start_lng float, 
end_lat float,
end_lng float,
distance_in_meters float,
kilometers_per_hour float );



INSERT INTO #distance_speed
SELECT *, 
          ( 3600*(distance_in_meters  / DATEDIFF(SECOND , 0, duration)) ) / 1000 AS kilometers_per_hour
FROM (
SELECT *,
           distance_in_meters = ROUND(geography::Point(start_lat, start_lng, 4326).STDistance(geography::Point(end_lat, end_lng, 4326)),2)
FROM #tripdata
 ) D
 WHERE start_lat is not null and start_lng is not null and end_lat is not null and end_lng is not null
		  AND DATEDIFF(SECOND , 0, duration) > 0;


		  


SELECT a.ride_id, a.started_at, a.ended_at, a.start_station_name, 
       a.end_station_name,  a.start_lat, a.start_lng, a.end_lat, a.end_lng,
	   a.duration, a.week_day, a.bike_type, a.user_type, 
	   b.distance_in_meters, ROUND(b.kilometers_per_hour,2) AS kilometers_per_hour
FROM biketrips2023 AS a
INNER JOIN #distance_speed AS b 
ON a.ride_id = b.ride_id 
WHERE started_at between '2023-04-01 00:00:00' and '2023-06-30 23:59:59' and a.start_lat is not null and a.start_lng is not null and a.end_lat is not null and 
started_at is not null and ended_at is not null 
and a.end_lng is not null and a.start_station_name is not null and a.end_station_name is not null
ORDER BY a.started_at ASC;



-- Choose data for the top starting stations

WITH StationCounts AS (
    SELECT user_type,
        start_station_name,
        start_lat,
        start_lng,
        COUNT(*) AS total_rides,
        ROW_NUMBER() OVER (PARTITION BY user_type ORDER BY COUNT(*) DESC) AS station_rank
    FROM
        biketrips2023
    WHERE
        start_station_name IS NOT NULL
        AND start_lat IS NOT NULL
        AND start_lng IS NOT NULL
    GROUP BY user_type,
        start_station_name,
        start_lat,
        start_lng,started_at
)

SELECT   user_type,
    start_station_name,
    start_lat,
    start_lng,
    total_rides
FROM
    StationCounts
WHERE
    station_rank <= 100 



	-- Average duration for Q1 
	SELECT user_type, 
   CAST(DATEADD( ms,AVG(CAST(DATEDIFF( ms, '00:00:00', ISNULL(duration, '00:00:00')) as bigint)), '00:00:00' )  as TIME) as 'avg_duration'
FROM biketrips2023
WHERE started_at between '2023-01-01' and '2023-03-31'
GROUP BY user_type


SELECT    a.start_station_name, a.start_lat, a.start_lng,
          b.start_station_name, b.start_lat, b.start_lng
FROM biketrips2023 a
JOIN biketrips2023 b
ON a.start_station_id = b. start_station_id
   AND a.ride_id <> b.ride_id
WHERE a.start_station_name IS NULL --AND b.start_station_name IS NOT NULL



