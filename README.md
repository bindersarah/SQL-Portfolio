# SQL-Portfolio
Projects to showcase my self-taught SQL skills

##"Burning building? Call 911. Burning question? Call 311."
The 311 Dataset is provided by NYC Open Data. The entire dataset includs all service requests from 2010 to present, and is updated daily. However, for my project I chose to limit my analysis to entries made in the year 2019, in order to decrease the file size that I would be processing. 

The full dataset, table schema, and data dictionary can be found at: https://data.cityofnewyork.us/Social-Services/311-Service-Requests-from-2010-to-Present/erm2-nwe9

###Modifications I made to the dataset
In addition to limiting the data I worked with to service requests created in 2019, I also downloaded the data in separate sections in order to create 2 tables. I organized the data sections by "general"-- consisting of the information like the unique key, the dates created and closed, the agency handling the request, and the complaint type and description and "location" -- consisting of information like borough, zipcode, address etc.

##Operations Performed
-GROUP BY, HAVING
-JOINS
-BASIC SUBQUERIES IN SELECT, FROM, and WHERE
-COMPLEX SUBQUERIES: CORRELATETD and NESTED
-CASE WHEN: BASIC, use with WHERE CLAUSE, with AGGREGATES
-DATE & TIME
-CTE or TEMP TABLE
-WINDOW FUNCTIONS: BASIC, SLIDING, ADVANCED

##Limitations
1. Most fields in this dataset are TEXT datatype. This limited by ability to perform mathematical operations.
2. Since I divided one dataset into two tables using just one primary key, I was limited in the types of JOINS I could perform, as well as set operations like UNION.

##Outcomes
The purpose of this project was exploratory data analysis. The main findings include...
