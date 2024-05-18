use sakila;

/* Query 1  List all listings along with their host details and neighborhood information. */

SELECT l.Listing_ID, h.Host_Name, h.Host_Since, n.Neighbourhood_Name
FROM Listings l
JOIN Hosts h ON l.Host_ID = h.Host_ID
JOIN Neighborhoods n ON l.Neighbourhood_ID = n.Neighbourhood_ID;

/* Query 2   View - Create a view to show listings with their property and room types. */
CREATE VIEW ListingsDetails AS
SELECT l.Listing_ID, pt.Property_Type_name, rt.Room_Type_name
FROM Listings l
JOIN Property_Types pt ON l.Property_Type_ID = pt.Property_Type_ID
JOIN Room_Types rt ON l.Room_Type_ID = rt.Room_Type_ID;
-- WHERE pt.Property_type_name = "" -- Customer selection
-- AND rt.Room_Type_name = "" -- Customer Selection;
select * from ListingsDetails limit 20;

/* Query 3 Which month has the max reviews */
SELECT n.Neighbourhood_Name, max(month(r.date)) as month_number
FROM Reviews1 r
JOIN Listings l ON r.Listing_ID = l.Listing_ID
JOIN Neighborhoods n ON l.Neighbourhood_ID = n.Neighbourhood_ID
GROUP BY n.Neighbourhood_Name
ORDER BY month_number DESC;

SELECT 
  n.Neighbourhood_Name, 
  MAX(MONTH(r.date)) AS month_number
FROM 
  Reviews r
JOIN 
  Listings l ON r.Listing_ID = l.Listing_ID
JOIN 
  Neighborhoods n ON l.Neighbourhood_ID = n.Neighbourhood_ID
WHERE 
  r.date IS NOT NULL
GROUP BY 
  n.Neighbourhood_Name;



/* Query 4 Indexing - Create an index on the review scores to optimize search queries. */

CREATE INDEX idx_review_score ON Reviews (listing_id);

/* Query 5 Advanced Join - List guests and their reviews for properties in a specific neighborhood.*/
SELECT g.Guest_Name, r.date,r.comments, n.Neighbourhood_Name
FROM Guests g
JOIN Reviews r ON g.Guest_ID = r.Guest_ID
JOIN Listings l ON r.Listing_ID = l.Listing_ID
JOIN Neighborhoods n ON l.Neighbourhood_ID = n.Neighbourhood_ID
WHERE n.Neighbourhood_Name = 'District 1'
order by r.date desc
limit 20; /* User can enter Values from District 1 to District 14*/

/* Query 6 View - Create a view for the most popular property types based on the number of listings*/
CREATE VIEW PopularPropertyTypes AS
SELECT pt.Property_Type_name, COUNT(l.Listing_ID) AS Listing_Count
FROM Property_Types pt
JOIN Listings l ON pt.Property_Type_ID = l.Property_Type_ID
GROUP BY pt.Property_Type_name
ORDER BY Listing_Count DESC;
select * from PopularPropertyTypes;

/* Query 7 - Show listings with their most recent review*/

SELECT l.Listing_ID, l.name, r.Comments, r.Date
FROM Listings l
JOIN Reviews r ON l.Listing_ID = r.Listing_ID
WHERE r.Date = (SELECT MAX(Date) FROM Reviews WHERE Listing_ID = l.Listing_ID)
limit 50;

/* Query 8 Join Listings with Reviews to get average scores by Neighborhood */
SELECT Neighbourhood_Name, ROUND(AVG(Review_Scores_rating),2) AS AverageScore /* can ry with other review scores columns*/
FROM Listings
JOIN Reviews ON listings.Listing_ID = Reviews.Listing_ID
JOIN Neighborhoods ON Listings.Neighbourhood_ID = neighborhoods.Neighbourhood_ID
GROUP BY Neighbourhood_Name
ORDER BY AverageScore DESC;

/* Query 9 Rank Listings by Review Scores within Each Neighborhood*/

SELECT 
  l.Neighbourhood_ID, 
  r.comments,
  l.review_scores_rating,
  RANK() OVER (PARTITION BY l.Neighbourhood_ID ORDER BY l.review_scores_rating DESC) AS Rank_In_Neighborhood
FROM 
  Listings l
JOIN 
  Reviews r ON l.Listing_ID = r.Listing_ID
WHERE 
  (l.Neighbourhood_ID, l.review_scores_rating) IN (
    SELECT 
      Neighbourhood_ID, 
      MIN(review_scores_rating)
    FROM 
      Listings
    GROUP BY 
      Neighbourhood_ID
  )
ORDER BY 
  l.Neighbourhood_ID DESC; /* Unable to Get 1 result per neighbourhood */
  
 WITH cte_check AS (
  SELECT 
    listing_id, 
    neighbourhood_id, 
    review_scores_rating, 
    RANK() OVER (
      PARTITION BY neighbourhood_id 
      ORDER BY review_scores_rating DESC
    ) AS in_district_rank
  FROM 
    listings
)

SELECT 
  listing_id, 
  neighbourhood_id, 
  review_scores_rating
FROM 
  cte_check
WHERE 
  in_district_rank = 1;

  
  
  /* Query 10 Find the Next and Previous Review Scores for Each Listing */
  
 WITH Scores AS (
  SELECT 
    Listing_ID, 
    Review_Scores_rating,
    LAG(Review_Scores_rating) OVER (
      PARTITION BY Listing_ID 
      ORDER BY last_Review
    ) AS Previous_Score,
    LEAD(Review_Scores_rating) OVER (
      PARTITION BY Listing_ID 
      ORDER BY last_Review
    ) AS Next_Score
  FROM 
    listings
)

SELECT *
FROM Scores
WHERE Previous_Score IS NOT NULL AND Next_Score IS NOT NULL; /* not even one listing is reviewed twice*/
-- The above issue is because you are using the listings table. We should refer to the Reviews table. 
-- Let's exclude this question since our reviews file has been reduced. 

/* Query 11 Assign Listings to Quartiles Based on Price within Each Property Type */

SELECT Listing_ID, Property_Type_ID, Price,
       NTILE(4) OVER (PARTITION BY Property_Type_ID ORDER BY Price) AS Price_Quartile
FROM Listings
WHERE price != ""; 

/* Query 12 Calculate Cumulative Distribution of Review Scores Across All Listings */
WITH Distribution AS (
  SELECT 
    Listing_ID, 
    comments,
    CUME_DIST() OVER (ORDER BY comments) AS Cumulative_Distribution
  FROM 
    Reviews
    ORDER BY Listing_ID
)
SELECT *
FROM Distribution
WHERE Cumulative_Distribution = ROUND(Cumulative_Distribution / 0.05) * 0.05; 

/* Identify the First and Last Review Dates for Each Listing*/
SELECT distinct(Listing_ID),
       FIRST_VALUE(date) OVER (PARTITION BY Listing_ID ORDER BY date) AS First_Review_Date,
       LAST_VALUE(date) OVER (PARTITION BY Listing_ID ORDER BY Date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS Last_Review_Date
FROM sakila.Reviews
limit 20;



SELECT Listing_ID, Name
FROM sakila.Listings
WHERE Name REGEXP '^Condo'; /* Can try combinations of Home, Townhouse, Guesthouse etc*/

SELECT ID, REGEXP_SUBSTR(Comments, '^[^ ]+') AS First_Word
FROM sakila.Reviews
limit 100;

SELECT ID, Comments
FROM sakila.Reviews
WHERE Comments REGEXP '\\?$';

/* No of digits in Name */
SELECT Listing_ID, Name, LENGTH(Name) - LENGTH(REGEXP_REPLACE(Name, '\\d', '')) AS Digit_Count
FROM sakila.Listings
limit 100;

SELECT Listing_ID, Name
FROM sakila.Listings
WHERE Name REGEXP '^.{50}$';

SELECT listing_id,date, Comments
FROM sakila.Reviews
WHERE Comments RLIKE 'excellent|wonderful|amazing';

/* Extract Year from Free-Form Text Dates in Reviews */
SELECT ID, REGEXP_SUBSTR(Comments, '\\b(19|20)\\d{2}\\b') AS Year_Extracted
FROM sakila.Reviews
ORDER BY Year_Extracted DESC
LIMIT 75;

/* Cleaned Comments*/
SELECT ID, REGEXP_REPLACE(Comments, '\\s+', ' ') AS Cleaned_Comment
FROM Reviews;

/*Trying to filter properties with numbers in titles like 500 south street etc, but very bad data - comments i mean*/
SELECT Listing_ID, name
FROM sakila.Listings
WHERE name REGEXP '\\d+';


/*Guests with the Longest Time Between Reviews*/
SELECT guest_id, MAX(date) - MIN(date) AS time_between_reviews
FROM Reviews1
GROUP BY guest_id
ORDER BY time_between_reviews DESC;

/* Guest Name with max number of reviews*/
SELECT Guests.Guest_id, Guests.guest_name AS Guest_name, COUNT(*) AS Total_reviews
FROM Guests
JOIN Reviews ON Guests.Guest_id = Reviews.guest_id
GROUP BY Guests.Guest_id, guests.Guest_name
ORDER BY Total_reviews DESC
LIMIT 3;






