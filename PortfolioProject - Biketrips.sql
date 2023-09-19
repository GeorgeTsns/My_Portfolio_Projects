-- Goal: Find out how annual members and casual riders differ


-- To begin with, we need to do some data cleaning to better understand the data
-- We have already checked that there are no duplicates in excel

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
--Friday seems to be the busiest day of the week 

--Now we're going to calculate the average ride duration for each type of user: 

SELECT usertype, CAST(DATEADD( ms,AVG(CAST(DATEDIFF( ms, '00:00:00', ISNULL(ride_duration, '00:00:00')) as bigint)), '00:00:00' )  as TIME) as 'avg_time'
FROM biketripsQ1
WHERE usertype <> 'Dependent'
GROUP BY usertype
--Despite the fact that Subscribers do the most trips, we see that Casual Riders use the bikes longer.
--This can be explained because Subscribers mainly use bikes to commute to work rather than Casual Riders that use them for leisure

-- And to get it a little bit further let's find out the average ride duration by user type and day of the week 

SELECT usertype, day_of_the_week, CAST(DATEADD( ms,AVG(CAST(DATEDIFF( ms, '00:00:00', ISNULL(ride_duration, '00:00:00')) as bigint)), '00:00:00' )  as TIME) as 'avg_time'
FROM biketripsQ1
WHERE usertype <> 'Dependent'
GROUP BY usertype, day_of_the_week
ORDER BY 2,1


--Here we are going to calculate the percentage of casual rider and subscriber trips relative to the total number of trips 


WITH cte_rides AS ( SELECT
 COUNT(*) AS total_trips,
 SUM(CASE WHEN usertype = 'Customer' THEN 1 ELSE 0 END) AS customer_total_trips,
 SUM(CASE WHEN usertype = 'Subscriber' THEN 1 ELSE 0 END) AS subscriber_total_trips
FROM biketripsQ1
WHERE usertype <> 'Dependent'
)

SELECT
    (customer_total_trips * 100.0 / total_trips) AS customer_percentage,
    (subscriber_total_trips * 100.0 / total_trips) AS subscriber_percentage
FROM cte_rides;

--Here we see again that Subscribers take much more rides than Casual Riders, with Subscibers having 87.9% of the rides
--and Casual Riders having 12.1%

--Busiest Hours by User Type: We want to analyze the busiest hours of the day for subscribers and casual riders. 
--Do they have different peak usage times? 
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
 -- As we can see in the results table, Subscribers have the most action during 8:00am - 10:00am and 4:00pm - 6:00pm(commute to work and returning from work)
 -- On the other hand we notice that Casual Riders have different peak times which are between 12:00 and 6:00 in the afternoon.
 

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

 --and secondly the most popular ending stations

 SELECT TOP 5 usertype, to_station_name, COUNT(*) AS total_ride_startings
 FROM biketripsQ1 
 WHERE usertype = 'Customer'
 GROUP BY to_station_name, usertype
 ORDER BY 3 DESC 
 
 SELECT TOP 5 usertype, to_station_name, COUNT(*) AS total_ride_startings
 FROM biketripsQ1
 WHERE usertype = 'Subscriber'
 GROUP BY to_station_name, usertype
 ORDER BY 3 DESC 

 -- As we observe from these queries Subscribers and and Casual Riders differ at their popular starting stations 
 -- Also the most popular ending stations are the same for each category with their starting stations 






 