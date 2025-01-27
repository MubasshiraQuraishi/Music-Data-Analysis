CREATE DATABASE Music;
USE music;
ALTER TABLE Artist
MODIFY COLUMN artist_id BIGINT AUTO_INCREMENT;
-- 1. Basic Queries
-- Venues:
-- Find the total number of venues by venue type.
SELECT vt.venue_type AS Venue_Types, COUNT(v.venue_id) AS venue_count FROM Venue v
JOIN venue_type vt ON vt.venue_Type_id = v.venue_type_id
GROUP BY vt.venue_type
ORDER BY venue_count DESC;

-- Retrieve details of venues that have been demolished after 2000.
SELECT Venue AS Venues, Demolition_date FROM Venue
WHERE YEAR(Demolition_date) >= 2000;

-- Shows:
-- Count the number of shows held per venue.
SELECT v.venue, COUNT(*) AS number_of_shows FROM shows s
JOIN Venue v ON v.venue_id = s.venue_id
GROUP BY v.Venue
ORDER BY 2 DESC;

-- Find the total revenue generated by each venue.
SELECT v.Venue, SUM(s.revenue) AS Total_revenue FROM shows s
JOIN Venue v ON v.venue_id = s.venue_id
GROUP BY 1;

-- List all cancelled shows and their reasons.
SELECT * FROM shows
WHERE Cancellation_reason IS NOT NULL;

-- Tours:
-- Retrieve all tours conducted by a specific artist.
SELECT * FROM Tour t
JOIN artist a ON a.artist_id = t.artist_id
WHERE a.artist = 'Bruno Mars';

-- List the top 5 tours by revenue generated.
SELECT Tour_name, SUM(s.revenue) AS Total_revenue FROM Tour t
JOIN Shows s ON s.tour_id = t.tour_id
GROUP BY Tour_name
ORDER BY Total_revenue DESC
LIMIT 5;

-- Artists:
-- Find the total number of artists grouped by artist type.
SELECT artist_Type, COUNT(*) AS Artist_count FROM Artist
GROUP BY artist_Type;

-- Identify artists who formed before a specific year and are still active.
SELECT Artist, artist_type, year_formed
FROM Artist
WHERE year_disbanded IS NULL;

-- Albums:
-- Find the album with the highest US Billboard 200 peak for each artist.
WITH Rankedalbums AS (
	SELECT a.artist AS artist_name,
		al.Title AS album_title,
        al.US_Billboard_200_peak AS US_Billboard_200_peak,
        ROW_NUMBER() OVER(PARTITION BY a.artist_id ORDER BY al.US_Billboard_200_peak ASC) AS ranks
		FROM album al
        JOIN Artist a ON a.artist_id = al.artist_id
        WHERE al.US_Billboard_200_peak IS NOT NULL
	)

SELECT * FROM Rankedalbums
WHERE ranks = 1
ORDER BY US_Billboard_200_peak ASC;

-- Calculate the total album playtime in minutes for each artist.
SELECT a.artist AS singer_name, SUM(Album_mins) as playtime FROM Album al
JOIN Artist a ON a.artist_id = al.artist_id
GROUP BY a.artist;

-- 2. Intermediate Queries
-- Revenue Analysis:
-- Calculate the revenue per ticket sold for each show.
SELECT Show_id, Tickets_sold, Revenue, ROUND((revenue / Tickets_sold),2) AS revenue_per_ticket
FROM SHOWS
WHERE Tickets_sold > 0
ORDER BY 4 DESC;	

-- Identify the venues with ticket sales exceeding 90% of their capacity.
WITH percent AS (
	SELECT v.venue_id, v.Venue as Venues, V.Capacity AS Total_Capacity, (v.Capacity * 0.9) AS ninety_percent, SUM(s.tickets_sold) AS Total_tickets_sold FROM Venue v
    JOIN Shows s ON s.venue_id = v.venue_id
    GROUP BY v.Venue_id, v.Venue, v.capacity)
    
SELECT * FROM percent
WHERE Total_tickets_sold > ninety_percent;

SELECT g.genre AS Genre, SUM(Revenue) AS Total_revenue FROM Shows s
JOIN Tour t ON t.tour_id = s.tour_id
JOIN Artist a ON a.artist_id = t.artist_id
JOIN Album al ON al.artist_id = a.artist_id
JOIN Subgenre sg ON sg.subgenre_id = al.subgenre_id
JOIN Genre g ON g.genre_id = sg.genre_id
GROUP BY Genre
ORDER BY Total_revenue DESC;

-- Tour Insights:
-- Find the artist with the most tours.
SELECT a.Artist AS Artist_name, COUNT(tour_id) AS tours
FROM Tour t JOIN Artist a ON a.artist_id = t.artist_id
GROUP BY a.Artist
ORDER BY tours DESC
LIMIT 1;

-- Geographical Insights:
-- Find the number of venues in each country and continent.
SELECT Country, COUNT(v.venue_id) AS venue_per_country
FROM Venue v
JOIN City c ON c.city_id = v.city_id
JOIN Country ON Country.Country_id = c.country_id
GROUP BY Country;

SELECT Continent, COUNT(v.venue_id) AS venue_per_continent
FROM Venue v
JOIN City c ON c.city_id = v.city_id
JOIN Country ON Country.Country_id = c.country_id
JOIN Continent ON Continent.Continent_ID = Country.Continent_id
GROUP BY Continent;

-- Retrieve the list of countries where more than 50 shows have been conducted.
SELECT Country.Country AS Countries, Count(show_id) AS total_shows
FROM Shows s 
JOIN Venue v ON v.venue_id = s.venue_id
JOIN City c ON c.city_id = v.city_id
JOIN Country ON Country.Country_id = c.country_id
GROUP BY Country.Country
HAVING Count(show_id) > 50
ORDER BY total_shows DESC;

-- Artist Insights:
-- Identify the artists with the highest album sales across all tours.
SELECT ar.artist AS Artist_name, a.US_Sales AS Sales_in_millions 
FROM Tour t
JOIN Album a ON a.album_id = t.album_id
JOIN Artist ar ON ar.artist_id = t.artist_id
HAVING a.US_Sales = (SELECT MAX(US_Sales) FROM Album JOIN Tour ON Tour.album_id = album.album_Id);

-- List artists whose tours include more than 5 legs.
SELECT DISTINCT(a.artist) AS Artist_name, t.legs AS legs FROM Artist a
JOIN Tour t ON t.artist_id = a.artist_id
HAVING t.legs > 5
ORDER BY legs DESC;

-- Album Insights:
-- Calculate the average track length for albums released in a specific year.
SELECT AVG(Album_mins) FROM Album WHERE YEAR(Release_date) = 2003;

-- 3. Advanced Queries
-- Predictive Analysis:
-- Predict potential ticket sales for a future show based on historical data for the same venue.

-- Forecast revenue for the next year based on current trends.
-- Cancellation Analysis:
-- Analyze cancellation reasons to determine the most common causes of show cancellations.
SELECT Cancellation_reason, Count(*) AS Cancellation_count FROM Shows
WHERE Cancellation_reason IS NOT NULL
GROUP BY Cancellation_reason
ORDER BY Cancellation_count DESC
LIMIT 5;
-- Profitability Analysis:
-- Calculate the profit margin for tours by subtracting construction costs (if venue owned) from revenue.
SELECT v.Venue AS Venues, ROUND(SUM(s.revenue - construction_cost_$m),2) AS Profit_margin
FROM Shows s
JOIN Venue v ON v.venue_id = s.venue_id
GROUP BY Venues
ORDER BY 2 DESC
LIMIT 7;

-- Determine the ROI (return on investment) for venues hosting tours over the last decade.
SELECT v.venue AS venues, SUM(tour_gross - construction_cost_$m) AS ROI
FROM Shows s
JOIN Venue v ON v.venue_id = s.venue_id
JOIN Tour t ON t.tour_id = s.tour_id
WHERE v.opening_date > 2000
GROUP BY Venues
HAVING SUM(tour_gross - construction_cost_$m) > 0


-- Genre/Subgenre Analysis:
-- Find the most popular genre or subgenre based on album sales and tour attendance.
WITH popular_subgenre AS (
		SELECT s.subgenre, 
        SUM(US_Sales) AS Total_album_sales_in_millions,
        SUM(t.attendance) AS Total_tour_attendance,
        ROW_NUMBER() OVER(PARTITION BY s.subgenre_id ORDER BY (SUM(a.us_sales) + SUM(t.attendance)) DESC) AS ranks
        FROM Album a 
        JOIN Subgenre s ON s.subgenre_id = a.subgenre_id
        JOIN Tour t ON t.album_id = a.album_id
		GROUP BY s.subgenre_id, s.subgenre
        )
SELECT subgenre, Total_Album_Sales, Total_Tour_Attendance
FROM popular_subgenre
WHERE ranks = 1;
 
-- Identify the record labels associated with the highest-grossing albums.

WITH highest_grossing_tours AS (
		SELECT tour_id, album_id, MAX(tour_gross) AS max_tour_gross
        FROM Tour
        GROUP BY tour_id, album_id
		HAVING MAX(tour_gross)
        
)
SELECT r.record_labels AS Record_label, alt.album_type AS Album_type, hgt.max_tour_gross AS Highest_gross
FROM highest_grossing_tours hgt
JOIN album a ON a.album_id = hgt.album_id
JOIN Record_label r ON r.record_label_id = a.record_label_id
JOIN Album_type alt ON alt.album_type_id = a.album_type_id
LIMIT 1;

-- Tour Optimization:
-- Suggest cities for future tours based on attendance trends
SELECT c.city AS City, SUM(t.attendance) AS Total_attendance
FROM Tour t
JOIN Shows s ON s.tour_id = t.tour_id
JOIN Venue v ON v.venue_id = s.venue_id
JOIN City c ON c.city_id = v.city_id
GROUP BY c.city
ORDER BY SUM(t.attendance) DESC
LIMIT 6;

-- Determine the most optimal time of year for tours based on attendance and revenue data.
-- 4. Multi-Step Queries for Stored Procedures
-- Dynamic Data Updates:
-- Create a stored procedure to update venue capacity dynamically based on construction/renovation.
DROP PROCEDURE IF EXISTS venu_capacity_update;
DELIMITER $$
CREATE PROCEDURE venu_capacity_update(p_venue TEXT, p_capacity DOUBLE)
BEGIN
	UPDATE Venue
    SET Capacity = p_capacity
    WHERE venue = p_venue;
END $$

CALL venu_capacity_update('Rogers Centre', 60000);

-- Write a procedure to insert new tour details, including associated shows, venues, and artists.
DROP PROCEDURE IF EXISTS new_artist;
DELIMITER $$
CREATE PROCEDURE new_artist(p_artist TEXT, p_artist_type TEXT, p_year_formed BIGINT)
BEGIN
	INSERT INTO Artist (artist, artist_type, year_formed)
    Values (p_artist, p_artist_type, p_year_formed);
END $$

CALL new_artist('Linkin Park', 'Band', 1996);

DROP PROCEDURE IF EXISTS new_album;
DELIMITER $$
CREATE PROCEDURE new_album(p_title TEXT, p_artist TEXT, p_release_date DATETIME, p_album_mins BIGINT, p_album_secs BIGINT, p_tracks BIGINT,
								p_artist_subgenre TEXT, p_labels TEXT , p_album_type TEXT, p_US_Billboard_200_peak DOUBLE,
								p_US_Billboard_200_year_end	DOUBLE, p_US_Sales DOUBLE)
BEGIN
	DECLARE v_artist_id BIGINT;
    DECLARE v_subgenre_id BIGINT;
    DECLARE v_record_label_id BIGINT;
    DECLARE v_album_type_id BIGINT;
	SELECT artist_id INTO v_artist_id
    FROM artist
    WHERE artist = p_artist;
    
    SELECT subgenre_id INTO v_subgenre_id
    FROM subgenre
    WHERE subgenre = p_artist_subgenre;
    
    SELECT record_label_id INTO v_record_label_id
    FROM record_label
    WHERE record_labels = p_labels;
    
    SELECT album_type_id INTO v_album_type_id
    FROM album_Type
    WHERE album_Type = p_album_type;
    
	INSERT INTO album (title, artist_id, release_date, album_mins, album_secs, tracks, subgenre_id, record_label_id, album_type_id,
					US_Billboard_200_peak, US_Billboard_200_year_end, US_Sales)
    Values (p_title, v_artist_id, p_release_date, p_album_mins, p_album_secs, p_tracks,v_subgenre_id, v_record_label_id, v_album_type_id, 
			p_US_Billboard_200_peak, p_US_Billboard_200_year_end, p_US_Sales);
END $$

CALL new_album('Minutes to Midnight', 'Linkin Park', '2007-05-14 00:00:00', 43, 23, 12,'Alternative rock', 'Warner', 'Studio', 1, 154, 4);

DROP PROCEDURE IF EXISTS new_track;
DELIMITER $$
CREATE PROCEDURE new_track(p_title TEXT, p_track_order BIGINT, p_track_name TEXT, p_Track_mins BIGINT, p_Track_secs BIGINT, p_Single_release_date DATE, 
							 p_US_sales BIGINT)
                            
BEGIN
	DECLARE v_album_id	BIGINT;
    
    SELECT album_id INTO v_album_id
    FROM Album
    WHERE title = p_title;
    
    INSERT INTO Track (Album_ID, Track_order, Track_name, Track_mins, Track_secs, Single_release_date, US_sales)
	VALUES (v_album_id, p_track_order, p_track_name, p_Track_mins, p_Track_secs, p_Single_release_date, p_US_sales);
END $$

CALL new_track('Minutes to Midnight', 1, "Wake", 1, 41, '2007-07-25',0.02);
CALL new_track('Minutes to Midnight', 2, "Given Up", 3, 09, '2008-03-05',0.03);
CALL new_track('Minutes to Midnight', 3, "Leave Out All the Rest", 3, 29, '2008-06-03',0.04);
CALL new_track('Minutes to Midnight', 4, "Bleed it Out", 2, 44, '2007-08-21',0.06)
CALL new_track('Minutes to Midnight', 5, "Shadow of the Day", 4, 50, '2007-10-18',0.10)
CALL new_track('Minutes to Midnight', 6, "What I've done", 3, 26, '2007-04-04',0.12)
CALL new_track('Minutes to Midnight', 7, "Hands Held High", 3, 53, '2015-03-28',0.05)
CALL new_track('Minutes to Midnight', 8, "No More Sorrow", 3, 42, '2015-03-28',0.2)
CALL new_track('Minutes to Midnight', 9, "Valentine's Day", 3, 17, '2015-03-28',0.10)
CALL new_track('Minutes to Midnight', 10, "In Between", 3, 17, '2015-03-28',0.06)
CALL new_track('Minutes to Midnight', 11, "In Pieces", 3, 38, '2015-03-28',0.03)
CALL new_track('Minutes to Midnight', 12, "the little things give you away", 6, 24, '2015-03-28',0.08);

DROP PROCEDURE IF EXISTS new_tour;
DELIMITER $$
CREATE PROCEDURE new_tour(p_artist_name TEXT, p_tour_name TEXT, p_start_date DATE, p_end_date DATE, p_legs BIGINT, p_shows BIGINT, p_album_name TEXT)
BEGIN
	DECLARE v_artist_id	BIGINT;
    DECLARE v_album_id	BIGINT;
    
	SELECT artist_id INTO v_artist_id
    FROM Artist
    WHERE artist = p_artist_name;
    
    SELECT album_id INTO v_album_id
    FROM Album
    WHERE title = p_album_name;
    
    INSERT INTO Tour (artist_id, tour_name, start_date, end_date, legs, shows, album_id)
    VALUES (v_artist_id, p_tour_name, p_start_date, p_end_date, p_legs, p_shows, v_album_id);
END $$
CALL new_tour("Linkin Park", 'Minutes to Midnight World Tour', '2007-04-28', '2008-07-13', 5, 93, "Minutes to Midnight");

-- Complex Aggregations:
-- Create a stored procedure to calculate annual revenue trends for each artist.
DROP PROCEDURE IF EXISTS artist_Revenue_trend;
DELIMITER $$
CREATE PROCEDURE artist_Revenue_trend()
BEGIN
    
	SELECT a.Artist AS artist_name, YEAR(s.show_date) AS year_performed, SUM(s.revenue) as Total_revenue
    FROM Shows s
    JOIN Tour t ON t.tour_id = s.tour_id
    JOIN Artist a ON a.artist_id = t.artist_id
    GROUP BY a.artist, YEAR(s.show_date)
    ORDER BY Year_performed ASC, Artist_name ASC;
    
END $$
CALL artist_Revenue_trend();

-- Develop a procedure to analyze attendance trends across different continents.
Parameterized Procedures:
-- Write a stored procedure to fetch all shows based on parameters like date and venue
DROP PROCEDURE IF EXISTS fetch_shows;
DELIMITER $$
CREATE PROCEDURE fetch_shows(p_date DATE, p_venue_name TEXT)
BEGIN
	SELECT show_id, tour_id, leg, s.venue_id, tickets_sold, tickets_available, revenue, 
			s.show_date AS Show_date,
			v.venue AS Venue_name
	FROM Shows s
    JOIN Venue v ON v.venue_id = s.venue_id
    WHERE
		(s.show_date = p_date) AND (v.venue = p_venue_name);

END $$
CALL fetch_shows ('2008-12-21', 'Gainbridge Fieldhouse')
-- Create a procedure to generate a report on album sales, taking the artist ID or album type as input.
DROP PROCEDURE IF EXISTS album_sales;
DELIMITER $$
CREATE PROCEDURE album_sales (p_album_type TEXT)
BEGIN
	SELECT at.album_type AS album_type, SUM(a.US_Sales) AS total_sales_in_millions
    FROM album_Type at
    JOIN Album a ON a.album_type_id = at.album_type_id
    WHERE at.album_Type = p_album_type
    GROUP BY 1;
END $$
CALL album_sales ('Studio')
-- Chained Analysis:
-- Create a stored procedure to calculate the impact of cancelled shows on total tour revenue.
DROP PROCEDURE IF EXISTS negative_impacted_tours;
DELIMITER $$
CREATE PROCEDURE negative_impacted_tours ()
BEGIN
	SELECT COUNT(s.tour_id) AS total_cancelled_shows, SUM(t.tour_gross) AS Gross_loss
    FROM Shows s
    JOIN Tour t ON t.tour_id = s.tour_id
    WHERE s.cancelled = 1;
END $$
CALL negative_impacted_tours ();