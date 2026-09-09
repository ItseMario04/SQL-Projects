-- Window Functions

SELECT gender, AVG(salary) AS avg_salary
FROM employee_demographics AS dem
JOIN employee_salary AS sal
	ON dem.employee_id = sal.employee_id
GROUP BY gender;

SELECT dem.first_name, dem.last_name, gender, 
AVG(salary) OVER(PARTITION BY gender)
FROM employee_demographics AS dem
JOIN employee_salary AS sal
	ON dem.employee_id = sal.employee_id;

SELECT dem.first_name, dem.last_name, gender, salary,
SUM(salary) OVER(PARTITION BY gender ORDER BY dem.employee_id) AS Rolling_Total
FROM employee_demographics AS dem
JOIN employee_salary AS sal
	ON dem.employee_id = sal.employee_id;
    
SELECT dem.employee_id, dem.first_name, dem.last_name, gender, salary,
ROW_NUMBER() OVER(PARTITION BY gender ORDER BY salary DESC) AS row_num, 
RANK() OVER(PARTITION BY gender ORDER BY salary DESC) AS rank_num,
DENSE_RANK() OVER(PARTITION BY gender ORDER BY salary DESC) AS dense_rank_num
FROM employee_demographics AS dem
JOIN employee_salary AS sal
	ON dem.employee_id = sal.employee_id;