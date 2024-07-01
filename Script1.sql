select * from salaries;
SELECT DISTINCT experience_level FROM salaries;
/*1.You're a Compensation analyst employed by a multinational corporation. 
Your Assignment is to Pinpoint Countries who give work fully remotely, 
for the title 'managers’ Paying salaries Exceeding $90,000 USD*/

SELECT DISTINCT(company_location) FROM salaries 
WHERE remote_ratio = 100 
AND job_title LIKE '%manager%'
AND salary_in_usd >= 90000;

/*2.AS a remote work advocate working for a progressive HR tech startup who 
place their freshers’ clients in large tech firms. You're tasked with 
identifying top 5 Country Having  greatest count of large(company size) number 
of companies.*/

SELECT company_location, COUNT(company_size) AS 'Large Company Count' FROM 
(SELECT * FROM salaries 
WHERE experience_level='EN' 
AND company_size = 'L') AS Fresher_table
GROUP BY company_location
ORDER BY COUNT(company_size) DESC
LIMIT 5;

/*3. Picture yourself as a data scientist working for a workforce management 
platform. Your objective is to calculate the percentage of employees, 
who enjoy fully remote roles with salaries Exceeding $100,000 USD, 
shedding light ON the attractiveness of high-paying remote positions in today's 
job market.*/

SET @Count = (SELECT COUNT(*) FROM salaries WHERE salary >= 100000);
SET @Remote = (SELECT COUNT(*) FROM salaries WHERE salary >= 100000 
AND remote_ratio = 100);
SET @Percentage = ROUND((SELECT @Remote/(SELECT @Count))*100,2);
SELECT @Percentage AS 'High Paying Remote(>100000$)';

/*4.Imagine you're a data analyst working for a global recruitment agency. Your Task is 
to identify the Locations where entry-level average salaries exceed the average salary 
for that job title in market for entry level,helping your agency guide candidates 
towards lucrative countries.*/
SELECT company_location,t.job_title,avg_salary,avg_salary_country FROM (
SELECT company_location,job_title,ROUND(AVG(salary_in_usd),2) AS avg_salary_country 
FROM salaries 
WHERE experience_level ='EN'
GROUP BY job_title,company_location 
) AS t 
INNER JOIN (
SELECT job_title,ROUND(AVG(salary_in_usd),2) AS avg_salary 
FROM salaries 
WHERE experience_level ='EN'
GROUP BY job_title ) AS m
ON t.job_title = m.job_title
WHERE avg_salary > avg_salary_country;

/*5. You've been hired by a big HR Consultancy to look at how much people get paid in 
different Countries. Your job is to find out for each job title which country pays the 
maximum average salary. This helps you to place your candidates in those countries.*/

SELECT job_title,avg_salary FROM 
(SELECT job_title,avg_salary,DENSE_RANK() OVER 
(PARTITION BY job_title ORDER BY avg_salary DESC) AS max_salary_rank 
FROM (
SELECT job_title,company_location,ROUND(AVG(salary_in_usd),2) AS avg_salary 
FROM salaries GROUP BY company_location,job_title) AS t)AS m
WHERE max_salary_rank = 1;

/*6.As a data-driven business consultant, you've been hired by a multinational corporation to analyze salary trends across different company 
locations. Your goal is to pinpoint locations where the average salary has consistently increased over the past few years (countries where data 
is available for 3 years only(this and past two years) providing alter into locations experiencing sustained salary growth.*/
WITH CTE AS (
SELECT * FROM salaries WHERE company_location IN(
SELECT company_location FROM (
SELECT company_location,ROUND(AVG(salary_in_usd),2) AS avg_salary,
COUNT(DISTINCT work_year) AS cnt
FROM salaries 
WHERE work_year > YEAR(CURRENT_DATE()) - 3
GROUP BY company_location 
HAVING cnt = 3)t))
SELECT company_location,
MAX(CASE WHEN work_year = 2022 THEN average END) AS avg_salary_2022,
MAX(CASE WHEN work_year = 2023 THEN average END) AS avg_salary_2023,
MAX(CASE WHEN work_year = 2024 THEN average END) AS avg_salary_2024
FROM(
SELECT company_location,work_year,AVG(salary_in_usd) AS average 
FROM CTE
GROUP BY company_location,work_year)m
GROUP BY company_location 
HAVING avg_salary_2024 > avg_salary_2023 AND avg_salary_2023 > avg_salary_2022;

/* 7.Picture yourself as a workforce strategist employed by a global HR tech startup. Your mission is to determine the percentage 
of fully remote work for each experience level in 2021 and compare it with the corresponding figures for 2024,highlighting any 
significant increases or decreases in remote work adoption over the years.*/
WITH CTE1 AS
(SELECT a.experience_level, total_remote ,total_2021, ROUND((((total_remote)/total_2021)*100),2) 
AS '2021 remote %' FROM
(SELECT experience_level, COUNT(experience_level) AS total_remote 
FROM salaries 
WHERE work_year=2021 AND remote_ratio = 100 
GROUP BY experience_level
)a
INNER JOIN(
SELECT  experience_level, COUNT(experience_level) AS total_2021 
FROM salaries 
WHERE work_year=2021 
GROUP BY experience_level)b 
ON a.experience_level= b.experience_level),
CTE2 AS 
(SELECT a.experience_level, total_remote ,total_2021, ROUND((((total_remote)/total_2021)*100),2) 
AS '2021 remote %' FROM
(SELECT experience_level, COUNT(experience_level) AS total_remote 
FROM salaries 
WHERE work_year=2021 AND remote_ratio = 100 
GROUP BY experience_level
)a
INNER JOIN(
SELECT  experience_level, COUNT(experience_level) AS total_2021 
FROM salaries 
WHERE work_year=2024 
GROUP BY experience_level)b 
ON a.experience_level= b.experience_level)
SELECT * FROM CTE1 INNER JOIN CTE2 ON CTE1.experience_level = CTE2.experience_level;
 
 /* 8. As a compensation specialist at a fortune 500 company, you're tasked with analyzing salary trends over time. Your objective 
is to calculate the average salary increase percentage for each experience level and job title between the years 2023 and 2024, 
helping the company stay competitive in the talent market.*/

WITH CTE AS
(SELECT experience_level,job_title,work_year,ROUND(AVG(salary_in_usd),2) AS avg_salary 
FROM salaries 
WHERE work_year >= YEAR(CURRENT_DATE())-1 
GROUP BY experience_level,job_title,work_year)

SELECT *,round((((avg_salary_2024-avg_salary_2023)/avg_salary_2023)*100),2) AS changes
FROM(
SELECT experience_level,job_title,
MAX(CASE WHEN work_year = 2024 THEN avg_salary END) AS avg_salary_2024,
MAX(CASE WHEN work_year = 2023 THEN avg_salary END) AS avg_salary_2023
FROM CTE
GROUP BY experience_level,job_title)t
WHERE (((AVG_salary_2024-AVG_salary_2023)/AVG_salary_2023)*100)  IS NOT NULL;

/* 9.You are working with an consultancy firm, your client comes to you with certain data and preferences such as 
(their year of experience , their employment type, company location and company size) and want to make an transaction into 
different domain in data industry(like  a person is working as a data analyst and want to move to some other domain such as data 
science or data engineering etc.)your work is to  guide them to which domain they should switch to base on  the input they 
provided, so that they can now update thier knowledge as  per the suggestion/..the suggestion should be based on average salary.*/

DELIMITER //
CREATE PROCEDURE GetAverageSalary(IN exp_lev VARCHAR(2), IN emp_type VARCHAR(3), IN comp_loc VARCHAR(2), IN comp_size VARCHAR(2))
BEGIN
    SELECT job_title, experience_level, company_location, company_size, employment_type, ROUND(AVG(salary), 2) AS avg_salary 
    FROM salaries 
    WHERE experience_level = exp_lev AND company_location = comp_loc AND company_size = comp_size AND employment_type = emp_type 
    GROUP BY experience_level, employment_type, company_location, company_size, job_title order by avg_salary desc ;
END//
DELIMITER ;
CALL GetAverageSalary('EN','FT','AU','M');
DROP PROCEDURE Getaveragesalary;

/*10.As a market researcher, your job is to investigate the job market for a company that analyzes workforce data. Your task is to 
know how many people were employed in different types of companies as per their size in 2021.*/
-- Select company size and count of employees for each size.

SELECT company_size, COUNT(company_size) AS 'COUNT of employees' 
FROM salaries 
WHERE work_year = 2021 
GROUP BY company_size;

/*11.Imagine you are a talent acquisition specialist working for an international recruitment agency. Your task is to identify 
the top 3 job titles that command the highest average salary among part-time positions in the year 2023.*/

SELECT job_title,ROUND(AVG(salary_in_usd),2) AS avg_salary  
FROM salaries 
WHERE employment_type = 'PT' 
AND work_year = 2023 
GROUP BY job_title
ORDER By avg_salary DESC
LIMIT 3;

/*12.As a database analyst you have been assigned the task to select countries where average mid-level salary is higher than 
overall mid-level salary for the year 2023.*/

SET @average = (SELECT ROUND(AVG(salary_in_usd),2) AS 'Mid Level(avg_salary)' 
FROM salaries 
WHERE experience_level= 'MI' 
AND work_year = 2023);

SELECT company_location,ROUND(AVG(salary_in_usd), 2) AS avg_salary 
FROM salaries 
WHERE experience_level = 'MI'
GROUP BY company_location
HAVING avg_salary > @average;

/*13. You're a financial analyst working for a leading HR consultancy, and your task is to assess the annual salary growth rate 
for various job titles.By calculating the percentage increase in salary from previous year to this year, you aim to provide 
valuable insights into salary trends within different job roles.*/
WITH CTE AS(
SELECT m.job_title,avg_salary_2023,avg_salary_2024 FROM  
(SELECT job_title,ROUND(AVG(salary_in_usd),2) AS avg_salary_2023
FROM salaries
WHERE work_year = 2023
GROUP BY job_title)t
INNER JOIN
(SELECT job_title,ROUND(AVG(salary_in_usd),2) AS avg_salary_2024
FROM salaries
WHERE work_year = 2024
GROUP BY job_title)m
ON t.job_title = m.job_title)

SELECT *,ROUND((((avg_salary_2024-avg_salary_2023)/avg_salary_2023)*100),2) AS percentage_change
FROM CTE;


/*14. You've been hired by a global HR consultancy to identify countries experiencing significant salary growth for entry-level 
roles.Your task is to list the top three countries with the highest salary growth rate from 2020 to 2023, helping multinational 
corporations identify emerging talent markets.*/

WITH t AS(
SELECT company_location,work_year,AVG(salary_in_usd) as average 
FROM salaries 
WHERE experience_level = 'EN' 
AND (work_year = 2021 OR work_year = 2023)
GROUP BY company_location, work_year)
SELECT *, (((AVG_salary_2023 - AVG_salary_2021) / AVG_salary_2021) * 100) AS changes
FROM(
    SELECT company_location,
        MAX(CASE WHEN work_year = 2021 THEN average END) AS AVG_salary_2021,
        MAX(CASE WHEN work_year = 2023 THEN average END) AS AVG_salary_2023
    FROM t 
    GROUP BY company_location
)a 
WHERE (((AVG_salary_2023 - AVG_salary_2021) / AVG_salary_2021) * 100) IS NOT NULL  
ORDER BY (((AVG_salary_2023 - AVG_salary_2021) / AVG_salary_2021) * 100) DESC 
LIMIT 3;

/*15. You have been hired by a market research agency where you been assigned the task to show the percentage of different 
employment type (full time, part time) in different job roles, in the format where each row will be job title, each column will 
be type of employment type and  cell value  for that row and column will show the % value*/

SELECT job_title,
    ROUND((SUM(CASE WHEN employment_type = 'PT' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS PT_percentage, 
    ROUND((SUM(CASE WHEN employment_type = 'FT' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS FT_percentage, 
    ROUND((SUM(CASE WHEN employment_type = 'CT' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS CT_percentage, 
    ROUND((SUM(CASE WHEN employment_type = 'FL' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS FL_percentage 
FROM salaries
GROUP BY job_title;







