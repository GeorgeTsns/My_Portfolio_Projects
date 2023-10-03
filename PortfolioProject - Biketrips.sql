-- Goal: Find out how annual members and casual riders differ


-- To begin with, we need to do some data cleaning to better understand the data
-- We have already checked that there are no duplicates in excel
-- We refer to annual members as Subscribers and to casual riders simply as Customers

SELECT *
FROM biketripsQ1

-- Data cleaning and understanding

-- Firstly, let's create a column to define the days of the week as names and not as number as it is in the original dataset
-- We already know that Monday = 1 etc. 

ALTER TABLE biketripsQ1
ADD day_of_the_week varchar(25); 

UPDATE biketripsQ1
SET day_of_the_week = CASE 
  WHEN CAST(day_of_week AS varchar) = 1 THEN '1.Monday'
  WHEN CAST(day_of_week AS varchar) = 2 THEN '2.Tuesday'
  WHEN CAST(day_of_week AS varchar) = 3 THEN '3.Wednesday'
  WHEN CAST(day_of_week AS varchar) = 4 THEN '4.Thursday'
  WHEN CAST(day_of_week AS varchar) = 5 THEN '5.Friday'
  WHEN CAST(day_of_week AS varchar) = 6 THEN '6.Saturday'
  WHEN CAST(day_of_week AS varchar) = 7 THEN '7.Sunday'
  ELSE CAST(day_of_week AS varchar) 
  END;  
-- I have added numbers infront of the days in order to order properly by days of week in following queries
-- It was also necessary to CAST the day_of_week column because it is in float format

-- And convert the ride_length column into time format, specifically we add a new column to replace the old one

SELECT ride_length, CONVERT(TIME,ride_length)
FROM biketripsQ1 

ALTER TABLE biketripsQ1
ADD ride_duration TIME;

UPDATE biketripsQ1
SET ride_duration = CONVERT(TIME,ride_length)


-- We check out which type of user made the most trips during the 1st quarter of the year

SELECT usertype, COUNT(trip_id) as total_trips
FROM biketripsQ1
WHERE usertype <> 'dependent' 
GROUP BY usertype 
-- We found out that Subscribers made the most trips
-- Now let's see the amount of trips per user for each day of the week 

SELECT usertype, COUNT(trip_id) AS total_trips, day_of_the_week 
FROM biketripsQ1
WHERE usertype <> 'dependent'
GROUP BY usertype, day_of_the_week	
ORDER BY 3 ASC  

-- So now we are going to find out which day of the week is the busiest:

SELECT day_of_the_week, COUNT(trip_id) total_trips 
FROM biketripsQ1
WHERE usertype <> 'dependent'
GROUP BY day_of_the_week
ORDER BY 2 desc
-- Friday seems to be the busiest day of the week 

-- Now we're going to calculate the average ride duration for each type of user: 

SELECT usertype, CAST(DATEADD( ms,AVG(CAST(DATEDIFF( ms, '00:00:00', ISNULL(ride_duration, '00:00:00')) as bigint)), '00:00:00' )  as TIME) as 'avg_time'
FROM biketripsQ1
WHERE usertype <> 'Dependent'
GROUP BY usertype
-- Despite the fact that Subscribers do the most trips, we see that Casual Riders tend to take longer trips.
-- This can be explained because Subscribers mainly use bikes to commute to work rather than Casual Riders that use them for leisure

-- And to get it a little bit further let's find out the average ride duration by user type and day of the week 

SELECT usertype, day_of_the_week, CAST(DATEADD( ms,AVG(CAST(DATEDIFF( ms, '00:00:00', ISNULL(ride_duration, '00:00:00')) as bigint)), '00:00:00' )  as TIME) as 'avg_time'
FROM biketripsQ1
WHERE usertype <> 'Dependent'
GROUP BY usertype, day_of_the_week
ORDER BY 2,1


-- Here we are going to calculate the percentage of casual rider and subscriber trips relative to the total number of trips 


WITH cte_rides AS ( SELECT
 COUNT(*) AS total_trips,
 SUM(CASE WHEN usertype = 'Customer' THEN 1 ELSE 0 END) AS customer_total_trips,
 SUM(CASE WHEN usertype = 'Subscriber' THEN 1 ELSE 0 END) AS subscriber_total_trips
FROM biketripsQ1
WHERE usertype <> 'Dependent'
)

SELECT
    ROUND((customer_total_trips * 100.0 / total_trips),1) AS customer_percentage,
    ROUND((subscriber_total_trips * 100.0 / total_trips),1) AS subscriber_percentage
FROM cte_rides;

-- Here we see again that Subscribers take much more rides than Casual Riders, with Subscibers having 87.9% of the rides
-- And Casual Riders having 12.1%

-- Busiest Hours by User Type: We want to analyze the busiest hours of the day for subscribers and casual riders. 
-- Do they have different peak usage times? 
-- In this case I'll split the day into 2 hour periods starting from 12am




WITH peak_times AS (
SELECT trip_id, usertype, day_of_the_week, CASE
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '00:00:00.0000000' AND '01:59:00.0000000' THEN '00:00 - 02:00' 
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '02:00:00.0000000' AND '03:59:00.0000000' THEN '02:01 - 04:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '04:00:00.0000000' AND '05:59:00.0000000' THEN '04:01 - 06:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '06:00:00.0000000' AND '07:59:00.0000000' THEN '06:01 - 08:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '08:00:00.0000000' AND '09:59:00.0000000' THEN '08:01 - 10:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '10:00:00.0000000' AND '11:59:00.0000000' THEN '10:01 - 12:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '12:00:00.0000000' AND '13:59:00.0000000' THEN '12:01 - 14:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '14:00:00.0000000' AND '15:59:00.0000000' THEN '14:01 - 16:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '16:00:00.0000000' AND '17:59:00.0000000' THEN '16:01 - 18:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '18:00:00.0000000' AND '19:59:00.0000000' THEN '18:01 - 20:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '20:00:00.0000000' AND '21:59:00.0000000' THEN '20:01 - 22:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '22:00:00.0000000' AND '23:59:00.0000000' THEN '22:01 - 00:00'
  ELSE FORMAT(starttime, 'HH:mm:ss')
  END AS time_period
FROM biketripsQ1
 
)

SELECT usertype, COUNT(*) AS total_trips, time_period
  FROM peak_times
  WHERE usertype <> 'Dependent' 
  GROUP BY usertype, time_period
  ORDER BY 3 ASC, 1 ASC
 
 -- In this table we see the bike usage for each type of user, during the time periods we created 
 -- Next we would like to know which are the busiest time periods for each user type throughout the day
 -- As we can see in the results table, Subscribers have the most action during 8:00 - 10:00 and 16:00pm - 18:00pm(commute to work and returning from work)
 -- On the other hand we notice that Casual Riders have different peak times which are between 12:00 and 18:00 in the afternoon
 

 -- Now we should also like to know which are the most popular starting stations for each type of user. Let's take a look at the top 5 of them.


 SELECT TOP 5 usertype, from_station_name, COUNT(*) AS total_ride_startings
 FROM biketripsQ1 
 WHERE usertype = 'Customer'
 GROUP BY from_station_name, usertype
 ORDER BY 3 DESC 
 
 SELECT TOP 5 usertype, from_station_name, COUNT(*) AS total_ride_startings
 FROM biketripsQ1
 WHERE usertype = 'Subscriber'
 GROUP BY from_station_name, usertype
 ORDER BY 3 DESC 

 -- And secondly the most popular ending stations

 SELECT TOP 5 usertype, to_station_name, COUNT(*) AS total_ride_endings
 FROM biketripsQ1 
 WHERE usertype = 'Customer'
 GROUP BY to_station_name, usertype
 ORDER BY 3 DESC 
 
 SELECT TOP 5 usertype, to_station_name, COUNT(*) AS total_ride_endings
 FROM biketripsQ1
 WHERE usertype = 'Subscriber'
 GROUP BY to_station_name, usertype
 ORDER BY 3 DESC 

 -- As we observe from these queries Subscribers and and Casual Riders differ at their popular starting stations 
 -- Also the most popular ending stations are the same for each category with their starting stations 



-- Now we joined the first 2 quarters of the year to gain new insights
-- We used the UNION operator 
 
 SELECT trip_id, bikeid, from_station_name, to_station_name, usertype, gender,birthyear, ride_duration, day_of_the_week
 FROM biketripsQ1
 UNION ALL
 SELECT  trip_id, bikeid, from_station_name, to_station_name, usertype, gender,birthyear, ride_duration, day_of_the_week
 FROM biketripsQ2
 
 -- And created a Temp Table to save the joined tables in one table
 
 DROP TABLE IF EXISTS #tempq1q2
 CREATE TABLE #tempq1q2 (
 trip_id float,
 starttime datetime,
 bikeid float,
 from_station_name nvarchar(255),
 to_station_name nvarchar(255),
 usertype nvarchar(255),
 gender  nvarchar(255),
 birthyear float,
 ride_duration time(7),
 day_of_the_week varchar(25)
 )
 
 -- Inserted data from the joined tables into the temporary table
 INSERT INTO #tempq1q2 
 SELECT trip_id, starttime, bikeid, from_station_name, to_station_name, usertype, gender,birthyear, ride_duration, day_of_the_week
 FROM biketripsQ1
 UNION ALL
 SELECT  trip_id, starttime, bikeid, from_station_name, to_station_name, usertype, gender,birthyear, ride_duration, day_of_the_week
 FROM biketripsQ2

 SELECT *
 FROM #tempq1q2

 -- Total trips per user
 SELECT usertype, COUNT(trip_id) AS total_trips
 FROM #tempq1q2
 WHERE usertype <> 'Dependent'
 GROUP BY usertype

 -- Total trips per user by day of the week
 SELECT usertype, COUNT(trip_id) AS total_trips, day_of_the_week
 FROM #tempq1q2
 WHERE usertype <> 'Dependent'
 GROUP BY usertype, day_of_the_week 
 ORDER BY 3 ASC

 -- The busiest day of the week 
 SELECT day_of_the_week, COUNT(trip_id) AS total_trips
 FROM #tempq1q2
 WHERE usertype <> 'Dependent'
 GROUP BY day_of_the_week
 ORDER BY 2 DESC
 -- Saturday is the busiest day of the week, now that we joined the two quarters 
 -- We calculate the average ride duration for each user
 SELECT usertype, CAST(DATEADD( ms,AVG(CAST(DATEDIFF( ms, '00:00:00', ISNULL(ride_duration, '00:00:00')) as bigint)), '00:00:00' )  as TIME) as 'avg_time'
FROM #tempq1q2
WHERE usertype <> 'Dependent'
GROUP BY usertype


-- Calculated the percentage of casual rider and subscriber trips relative to the total number of trips

WITH cte_q1q2 AS (
  SELECT 
     COUNT(*) AS total_trips,
	 SUM(CASE WHEN usertype = 'Customer' THEN 1 ELSE 0 END) AS customer_total_trips,  
	 SUM(CASE WHEN usertype = 'Subscriber' THEN 1 ELSE 0 END) AS subscriber_total_trips
FROM #tempq1q2
WHERE usertype <> 'Dependent'
)

SELECT 
   ROUND((customer_total_trips *100/ total_trips),2) AS customer_percentage,
   ROUND((subscriber_total_trips *100/ total_trips),2) AS subscriber_percentage
FROM cte_q1q2


-- Busiest Hours by User Type: We want to analyze the busiest hours of the day for subscribers and casual riders. 
-- Do they have different peak usage times? 
-- In this case I'll split the day into 2 hour periods starting from 12am




WITH peak_times AS (
SELECT trip_id, usertype, day_of_the_week, CASE
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '00:00:00.0000000' AND '01:59:00.0000000' THEN '00:00 - 02:00' 
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '02:00:00.0000000' AND '03:59:00.0000000' THEN '02:01 - 04:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '04:00:00.0000000' AND '05:59:00.0000000' THEN '04:01 - 06:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '06:00:00.0000000' AND '07:59:00.0000000' THEN '06:01 - 08:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '08:00:00.0000000' AND '09:59:00.0000000' THEN '08:01 - 10:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '10:00:00.0000000' AND '11:59:00.0000000' THEN '10:01 - 12:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '12:00:00.0000000' AND '13:59:00.0000000' THEN '12:01 - 14:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '14:00:00.0000000' AND '15:59:00.0000000' THEN '14:01 - 16:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '16:00:00.0000000' AND '17:59:00.0000000' THEN '16:01 - 18:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '18:00:00.0000000' AND '19:59:00.0000000' THEN '18:01 - 20:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '20:00:00.0000000' AND '21:59:00.0000000' THEN '20:01 - 22:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '22:00:00.0000000' AND '23:59:00.0000000' THEN '22:01 - 00:00'
  ELSE FORMAT(starttime, 'HH:mm:ss')
  END AS time_period
FROM #tempq1q2
 
)

SELECT usertype, COUNT(*) AS total_trips, time_period
  FROM peak_times
  WHERE usertype <> 'Dependent' 
  GROUP BY usertype, time_period
  ORDER BY 3 ASC, 1 ASC

-- Finding the Top 5 starting stations for each type of user

SELECT TOP 5 usertype, from_station_name, COUNT(*) AS total_ride_startings
 FROM #tempq1q2 
 WHERE usertype = 'Customer' --and day_of_the_week = '7.Sunday' 
 GROUP BY from_station_name, usertype
 ORDER BY 3 DESC 
 
 SELECT TOP 5 usertype, from_station_name, COUNT(*) AS total_ride_startings
 FROM #tempq1q2
 WHERE usertype = 'Subscriber' --and day_of_the_week = '7.Sunday'
 GROUP BY from_station_name, usertype
 ORDER BY 3 DESC  --Of course we can experiment with the where statement and filter by different days of the week

 -- Calculate the percentage change of rides from month to month
 -- We need to create another temporary table to perform the calculations
 DROP TABLE IF EXISTS #temp_diff_perc
 CREATE TABLE #temp_diff_perc (
 usertype nvarchar(255), 
 month_of_year int, 
 total_rides int,
 previous_month int 
 ) 

 INSERT INTO #temp_diff_perc 
  SELECT 
    usertype,
	MONTH(starttime) AS month_of_year, 
	COUNT(*) AS total_rides, LAG(COUNT(*),1) OVER (PARTITION BY usertype ORDER BY MONTH(starttime)) previous_month
 FROM #tempq1q2
 WHERE usertype <> 'Dependent'
 GROUP BY MONTH(starttime), usertype
 
 SELECT *,
   ROUND(
     (total_rides - previous_month)*1.0 / previous_month
	 ,2)*100 AS percentage_diff
 FROM #temp_diff_perc

 -- The demand for bikes soar in March especially for Customers, as February is the weakest month


 -- We gained useful insights for the different user types using data from quarters of the year
 -- Now we gathered all the data and put it in a new table that we created for the entire year
 -- We followed the same of process of data cleaning for each table that we created
 -- Join July, August and September in one table using Union All and then insert the data in a new table 

 CREATE TABLE biketripsQ3(
 trip_id float,
 starttime datetime,
 stoptime datetime,
 bikeid float,
 tripduration float,
 from_station_id float,
 from_station_name nvarchar(255),
 to_station_id float,
 to_station_name nvarchar(255),
 usertype nvarchar(255),
 gender nvarchar(255),
 birthyear float,
 ride_length datetime,
 day_of_week float,
 ride_duration time(7), 
 day_of_the_week varchar(25) )


INSERT INTO biketripsQ3 
SELECT *
 FROM biketrips07
 UNION ALL
 SELECT  *
 FROM biketrips08
 UNION ALL
 SELECT  *
 FROM biketrips09


 -- Create a table for the entire year 

 CREATE TABLE biketrips2015 (
 trip_id float,
 starttime datetime,
 stoptime datetime,
 bikeid float,
 tripduration float,
 from_station_id float,
 from_station_name nvarchar(255),
 to_station_id float,
 to_station_name nvarchar(255),
 usertype nvarchar(255),
 gender nvarchar(255),
 birthyear float,
 ride_length datetime,
 day_of_week float,
 ride_duration time(7), 
 day_of_the_week varchar(25) )

 INSERT INTO biketrips2015
 SELECT *
 FROM biketripsQ1
 UNION ALL
 SELECT *
 FROM biketripsQ2
 UNION ALL
 SELECT * 
 FROM biketripsQ3
 UNION ALL
 SELECT *
 FROM biketripsQ4



 -- Finally we could follow the same process to observe the bahavioral differencies of the company's users, this time with data about the whole year
 -- Later on we will visualize the tables from the queries to better undrestand them in a final dashboard in Tableau

 -- Calculate the number of trips per user by day of the week
 SELECT usertype, 
        COUNT(*) AS total_rides, 
		day_of_the_week AS day
 FROM biketrips2015
 WHERE usertype <> 'Dependent'
 GROUP BY usertype, day_of_the_week
 ORDER BY 3 ASC, 1 DESC

 -- Only on Saturday overcome the total rides of customers those from subscribers
 
 -- Calculate the total trips per user
 SELECT usertype, 
        COUNT(*) AS total_rides
 FROM biketrips2015
 WHERE usertype <> 'Dependent'
 GROUP BY usertype

 -- Calculate the average trip duration for each user through the week 

 SELECT usertype, 
        day_of_the_week,
        CAST(DATEADD(ms, AVG(CAST(DATEDIFF(ms, '00:00:00', ISNULL(ride_duration, '00:00:00')) AS bigint)), '00:00:00') AS TIME) AS avg_duration
 FROM biketrips2015
 WHERE usertype <> 'Dependent'
 GROUP BY usertype, day_of_the_week
 ORDER BY 2 ASC, 1 DESC

 -- Now we would like to find out which day of the week is the busiest during the year

 SELECT day_of_the_week, COUNT(*) AS total_rides
 FROM biketrips2015
 WHERE usertype <> 'Dependent'
 GROUP BY day_of_the_week
 ORDER BY COUNT(*) DESC
 -- That's Wednesday!!!
 -- And we can also find the busiest month

 SELECT MONTH(starttime) AS month,
        COUNT(*) AS total_rides
 FROM biketrips2015
 WHERE usertype <> 'Dependent'
 GROUP BY MONTH(starttime)
 --ORDER BY 1
 ORDER BY COUNT(*) DESC 
 -- And that is July followed by August and September


 -- Calculate the average duration for each type of user

 SELECT usertype, 
        CAST(DATEADD(ms, AVG(CAST(DATEDIFF(ms, '00:00:00', ISNULL(ride_duration, '00:00:00')) AS bigint)), '00:00:00') AS TIME) AS avg_duration
 FROM biketrips2015
 WHERE usertype <> 'Dependent'
 GROUP BY usertype 

-- Calculated percentage of casual rider and subscriber trips relative to the total number of trips

WITH cte_perc_of_total_rides AS 
( SELECT COUNT(*) AS total_trips,
SUM(CASE WHEN usertype = 'Customer' THEN 1 ELSE 0 END) AS total_customer_trips,
SUM(CASE WHEN usertype = 'Subscriber' THEN 1 ELSE 0 END) AS total_subscriber_trips
  FROM biketrips2015 
  WHERE usertype <> 'Dependent' 
  )
SELECT ROUND((total_customer_trips *100 / total_trips),1) AS customers_perc,
       ROUND((total_subscriber_trips *100 / total_trips),1) AS subscribers_perc
FROM cte_perc_of_total_rides


-- Discover the peak hours for each type of user


WITH peak_times AS (
SELECT trip_id, usertype, day_of_the_week, CASE
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '00:00:00.0000000' AND '01:59:00.0000000' THEN '00:00 - 02:00' 
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '02:00:00.0000000' AND '03:59:00.0000000' THEN '02:01 - 04:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '04:00:00.0000000' AND '05:59:00.0000000' THEN '04:01 - 06:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '06:00:00.0000000' AND '07:59:00.0000000' THEN '06:01 - 08:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '08:00:00.0000000' AND '09:59:00.0000000' THEN '08:01 - 10:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '10:00:00.0000000' AND '11:59:00.0000000' THEN '10:01 - 12:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '12:00:00.0000000' AND '13:59:00.0000000' THEN '12:01 - 14:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '14:00:00.0000000' AND '15:59:00.0000000' THEN '14:01 - 16:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '16:00:00.0000000' AND '17:59:00.0000000' THEN '16:01 - 18:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '18:00:00.0000000' AND '19:59:00.0000000' THEN '18:01 - 20:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '20:00:00.0000000' AND '21:59:00.0000000' THEN '20:01 - 22:00'
  WHEN TRY_CAST(FORMAT(starttime, 'HH:mm:ss') AS TIME) BETWEEN '22:00:00.0000000' AND '23:59:00.0000000' THEN '22:01 - 00:00'
  ELSE FORMAT(starttime, 'HH:mm:ss')
  END AS time_period
FROM biketrips2015
 
)

SELECT usertype, COUNT(*) AS total_trips, time_period
  FROM peak_times
  WHERE usertype <> 'Dependent' 
  GROUP BY usertype, time_period
  ORDER BY 3 ASC, 1 ASC


 -- Calculate the percentage change of rides from month to month
 -- We need to create another temporary table to perform the calculations
 DROP TABLE IF EXISTS #temp_percentage_change
 CREATE TABLE #temp_percentage_change (
 usertype nvarchar(255),
 month int,
 total_rides int,
 prev_total_rides int 
 )


INSERT INTO #temp_percentage_change
 SELECT usertype,
        MONTH(starttime) AS month,
        COUNT(*) AS total_rides,
		LAG(COUNT(*),1) OVER(PARTITION BY usertype ORDER BY MONTH(starttime)) AS prev_total_rides
 FROM biketrips2015
 WHERE usertype <> 'Dependent'
 GROUP BY MONTH(starttime), usertype

 SELECT *,
 ROUND(((total_rides - prev_total_rides)*1.0 / prev_total_rides)*100,2) AS perc_diff
 FROM #temp_percentage_change

 -- Let's find out the most popular starting stations for each type of user

 SELECT TOP 5
     usertype, RANK() OVER (ORDER BY COUNT(*) DESC) AS ranking, 
	  from_station_name, 
	  COUNT(*) AS rides
 FROM biketrips2015
 WHERE usertype = 'Subscriber' 
 GROUP BY from_station_name, usertype
 UNION ALL 
 SELECT TOP 5
   usertype, RANK() OVER (ORDER BY COUNT(*) DESC) AS ranking, 
	  from_station_name, 
	  COUNT(*) AS rides
 FROM biketrips2015
 WHERE usertype = 'Customer' 
 GROUP BY from_station_name, usertype

 -- The top 5 most popular starting stations are completly different for the two different types of users

 /*                            Insights and Findings                  /*

User Analysis: 1)Subscribers make by far the most trips in generall 
               2)On the other hand, Customers tend to take longer trips
			   3)They have different peak hours which shows variation in usage patterns
			   4)There are differences in station preferences
			   5)Customers overcome the trips from Subscribers only on Saturdays, exclusively in summer months
			   6)Busiest day of the year is Wednesday and for month is July! That differs if we explore different quarters of the year independently
			   7)Most popular day for Customers is Saturday, and for Subsribers is Wednesday
