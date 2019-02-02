/*
Query Practice:  Data Manipulation, Self Joins and Compound Queries
Carl-Oscar Gustafson
*/

/*
1.   Find the answer to the following questions.  Try to do these as a single query.  Return the exact result where shown.

a.  List the actor who played a role called Jayne Cobb.  Return the exact result.

b.  List all the male actors not named Jayne who played a character named Jayne.  
List them in alphabetical order by last name.  Return the exact result.

c.  Of all movies that have a lead role identified (there is an actor with Position = 1) what fraction are women? (you can compute 
the result from the result of the query – the actual result does not need to be done on a single row)
*/

-- Question 1a
SELECT DISTINCT FirstName, LastName
FROM Actors
WHERE Role='Jayne Cobb';


-- Question 1b
SELECT DISTINCT FirstName, LastName
FROM Actors
WHERE Role LIKE 'Jayne %' AND Gender='M' AND FirstName <> 'Jayne'
ORDER BY LastName

-- Question 1c
SELECT COUNT(RoleID) AS LeadRoleCount, Gender
FROM Actors
WHERE Position=1
GROUP BY Gender WITH ROLLUP

/*
2.  What Sci-Fi movie  (that has an MPAA rating) has  Jewel Staite acted in?  Return an exact result set for each appearance including 
her first and last name, the movie, and the name of her role. Use EXISTS in the WHERE clause to identify if a movie has an MPAA rating.
*/

SELECT FirstName, LastName, Movie, Role
FROM Actors JOIN Genre ON
Actors.MovieKey = Genre.MovieKey
JOIN MovieMaster ON
Actors.MovieKey = MovieMaster.MovieKey
WHERE FirstName='Jewel' AND LastName='Staite' AND Genre='Sci-Fi' AND EXISTS
(SELECT *
FROM Mpaa
WHERE Actors.MovieKey = Mpaa.MovieKey)

/*
3.  Analyze the relationship between gross revenue and budget. (Beware: the Business table has many different types of records;  not all 
fields are used for each record type).

	a.  Identifying ‘Flops’ (movies with big budgets and wide distribution that didn’t earn much on opening weekend). (Note:  the 
	intermediate queries may return results that are obviously data errors… don’t worry about this unless if affects your final result)

		i.  Write a query that identifies all movies with a budget greater than $100 million in US dollars – it should return name, 
		budget and MovieKey. When you use it later for part iii you will only use the MovieKey.

		ii. Write another query that identifies the 5 lowest gross that opened on at least 1000 screens (restrict the set to the 
		US opening).  It should contain the name, budget and review rating.

		iii.  Connect these two queries to find the list of movies that are low gross (query ii) and also had a large budget 
		(query i). Use a where clause with IN and a subquery based in part i. The final result set should contain five movies 
		with their name, opening gross and review rating.
*/

-- Question 3ai
SELECT Movie, Amount AS Budget, Business.MovieKey
FROM Business
JOIN MovieMaster ON Business.MovieKey = MovieMaster.MovieKey
WHERE Code ='BT' AND Currency = 'USD' AND Amount >= 100000000
ORDER BY Amount DESC

-- Question 3aii
SELECT Movie, Amount AS Budget, AvgRating AS Rating
FROM Business
JOIN MovieMaster ON MovieMaster.MovieKey = Business.MovieKey
JOIN Ratings ON Ratings.MovieKey = Business.MovieKey
WHERE Code='BT' AND Business.MovieKey IN 
	(SELECT TOP 5 Business1.MovieKey
	FROM Business AS Business1
	WHERE Screens >= 1000 AND Country = 'USA' AND Code='OW' AND EXISTS 
		(SELECT *
		FROM Business AS Business2
		WHERE Code='BT' AND Business1.MovieKey=Business2.MovieKey)
	ORDER BY Amount)

--Question 3aiii
SELECT Movie, Amount AS Gross, AvgRating AS Rating
FROM Business
JOIN MovieMaster ON MovieMaster.MovieKey = Business.MovieKey
JOIN Ratings ON Ratings.MovieKey = Business.MovieKey
WHERE Code='OW' AND Country='USA' AND Business.MovieKey IN 
	-- 5 movies with lowest gross revenue on opening on at least 1000 screens 
	(SELECT TOP 5 Business1.MovieKey
	FROM Business AS Business1
	WHERE Screens >= 1000 AND Code='OW' AND EXISTS 
		-- Movies with budget of over $100 million
		(SELECT *
		FROM Business AS Business2
		WHERE Code='BT' AND Amount >= 100000000 AND Currency='USD' AND Business1.MovieKey=Business2.MovieKey)
	ORDER BY Amount)
ORDER BY Amount

/*
3. 
	b. In Hollywood Economics, Edward DeVany noted that the distribution of the ratio of Gross Revenue to Budget is rather unusual. 
	Write a query that returns the Movie Name, Budget, Gross Revenue, and the ratio of Gross Revenue to Budget.  It should be ordered 
	by the ratio (high to low).  Restrict your analysis to movies that were dated in the 1990s, and have revenues and budgets reported 
	in US dollars.

		i.  First write the query to find the US gross for a movie.  Since gross increases over time and there are multiple 
		observations, the true US gross is the maximum of all values for a given MovieKey

		ii.  Write a query that returns the name of a movie and its budget restricted to the dates and currency shown above.

		iii.  Start with query ii, and use the result of query i as the right hand part of a join condition (note: you will 
		need to give it a correlation name).  Add the computations to the field list and the ORDER BY to get the result.

		iv.  Answer the question:  What movie in the 1990s had the highest ratio of Gross Revenue to Budget?

		v. Copy the result set to Excel and make a histogram of your result (the histogram can be a bar chart or scatterplot). 
		What is odd about the distribution you get?
*/

--Question 3bi
SELECT Movie, Amount AS Gross
FROM Business AS B1 
JOIN MovieMaster ON B1.MovieKey=MovieMaster.MovieKey
WHERE Code='GR' AND Currency='USD' AND Amount>=(SELECT MAX(Amount) FROM Business AS B2 WHERE B1.MovieKey=B2.MovieKey AND B2.Currency='USD' AND Code='GR')
											
--Question 3bii
SELECT Movie, Amount AS Budget
FROM Business
JOIN MovieMaster ON MovieMaster.MovieKey=Business.MovieKey
WHERE Currency='USD' AND Code='BT' AND MovieMaster.Date BETWEEN 1990 AND 1999

--Question 3biii
SELECT Movie, B1.Amount AS Budget, B2.Amount AS Gross, B2.Amount/B1.Amount AS Ratio, B2.Currency AS Currency
FROM Business AS B1
JOIN Business AS B2 ON B1.MovieKey = B2.MovieKey
JOIN MovieMaster ON MovieMawster.MovieKey=B1.MovieKey
WHERE B1.Currency='USD' AND B1.Code='BT' AND B2.Code='GR' AND B2.Currency='USD' AND MovieMaster.Date BETWEEN 1990 AND 1999 AND B2.Amount>=(
SELECT MAX(Amount) FROM Business AS B3 WHERE B1.MovieKey=B3.MovieKey AND B3.Code='GR' AND B3.Currency='USD')
ORDER BY Ratio DESC

/*
4. In the famous ‘Six Degrees of Kevin Bacon’ game your task is find an actor who is as ‘far’ from Kevin Bacon as possible, where far 
is measured by the minimum number of other actors needed to connect your choice to Kevin Bacon (a connection is when they appear in 
the same movie or show).  For instance, John Belushi is a Bacon Number 1, because he was in Animal House with Kevin Bacon.  Dan Akroyd
has a Bacon number of 2 because he was in the Blues Brothers with John Belushi, but Dan Akroyd never appeared in a movie with Kevin Bacon.  
It is quite hard to find actors with Bacon numbers much greater than 4. (Note:  in doing these counts you can exclude or include Kevin 
himself depending on what is convenient).  Also… make sure you have the right  Kevin Bacon.

	a.  How many actors have a Bacon Number of 1? (In network analysis this is referred to as Kevin Bacon’s  degree).

	b.  How does Kevin Bacon’s degree (you computed above) compare to the degree of Denzel Washington, Harrison Ford and Paul Reubens?

	c.  How many movies (using the database provided) are connected to actors with a Bacon Number of 1?
*/

--Question 4a
SELECT COUNT(DISTINCT ActorID)
FROM Actors
WHERE ActorID <> 59004 AND MovieKey IN (SELECT DISTINCT MovieKey FROM Actors WHERE ActorID=59004)
--Result: 5729

--Query used to find ActorID for Kevin Bacon
SELECT DISTINCT ActorID, FirstName, LastName 
FROM Actors 
WHERE LastName LIKE 'Bacon%' AND FirstName LIKE 'Kevin%'
--ActorID: 59004

--Question 4b
--Denzel Washington's Degree
SELECT COUNT(DISTINCT ActorID)
FROM Actors
WHERE ActorID <> 1260404 AND MovieKey IN (SELECT DISTINCT MovieKey FROM Actors WHERE ActorID=1260404)
--Result: 7023

--Query used to find ActorID for Denzel Washington
SELECT DISTINCT ActorID, FirstName, LastName 
FROM Actors 
WHERE LastName LIKE 'Washington%' AND FirstName LIKE 'Denzel%'
--ActorID: 1260404

--Harrison Ford's Degree
SELECT COUNT(DISTINCT ActorID)
FROM Actors
WHERE ActorID <> 383522 AND MovieKey IN (SELECT DISTINCT MovieKey FROM Actors WHERE ActorID=383522)
--Result: 6666

--Query used to find ActorID for Harrison Ford
SELECT DISTINCT ActorID, FirstName, LastName 
FROM Actors 
WHERE LastName LIKE 'Ford%' AND FirstName LIKE 'Harrison%'
--ActorID: 383522

--Paul Reubens' Degree
SELECT COUNT(DISTINCT ActorID)
FROM Actors
WHERE ActorID <> 988666 AND MovieKey IN (SELECT DISTINCT MovieKey FROM Actors WHERE ActorID=988666)
--Result: 3133

--Query used to find ActorID for Paul Reubens
SELECT DISTINCT ActorID, FirstName, LastName 
FROM Actors 
WHERE LastName LIKE 'Reubens%' AND FirstName LIKE 'Paul%'
--ActorID: 988666

--Question 4c
SELECT COUNT(DISTINCT MovieKey)
FROM Actors
WHERE ActorID IN (SELECT DISTINCT ActorID 
	FROM Actors
	WHERE ActorID <> 59004 AND MovieKey IN (SELECT DISTINCT MovieKey FROM Actors WHERE ActorID=59004))
-- Result: 293964




