-- CTEs

WITH CTE_Example AS
	(
	SELECT gender, AVG(salary) AS avg_sal, MAX(salary) AS max_sal, MIN(salary) AS min_sal, COUNT(salary) AS count_sal
	FROM employee_demographics AS dem
	JOIN employee_salary AS sal
		ON dem.employee_id = sal.employee_id
	GROUP BY gender
	)
SELECT AVG(avg_sal)
FROM CTE_Example
;
-- same but with subquery
SELECT AVG(avg_sal) 
FROM (
	SELECT gender, AVG(salary) AS avg_sal, MAX(salary) AS max_sal, MIN(salary) AS min_sal, COUNT(salary) AS count_sal
	FROM employee_demographics AS dem
	JOIN employee_salary AS sal
		ON dem.employee_id = sal.employee_id
	GROUP BY gender
	) AS example_subquery
;
--
SELECT AVG(avg_sal)
FROM CTE_Example;
--
WITH CTE_Example AS
	(
	SELECT employee_id, gender, birth_date
	FROM employee_demographics
    WHERE birth_date > '1985-01-01'
	),
	CTE_Example2 AS
		(
        SELECT employee_id, salary
        FROM employee_salary
        WHERE salary > 50000
        )
SELECT *
FROM CTE_Example
JOIN CTE_Example2 
	ON CTE_Example.employee_id = CTE_Example2.employee_id
;

WITH CTE_Example (Gender, AVG_sal, MAX_sal, MIN_sal, COUNT_sal) AS
	(
	SELECT gender, AVG(salary) AS avg_sal, MAX(salary) AS max_sal, MIN(salary) AS min_sal, COUNT(salary) AS count_sal
	FROM employee_demographics AS dem
	JOIN employee_salary AS sal
		ON dem.employee_id = sal.employee_id
	GROUP BY gender
	)
SELECT *
FROM CTE_Example
;