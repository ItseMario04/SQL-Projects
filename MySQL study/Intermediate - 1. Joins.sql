-- Joins

SELECT *
FROM employee_demographics;
SELECT *
FROM employee_salary;

-- Inner Joins

SELECT *
FROM employee_demographics AS dem
INNER JOIN employee_salary AS sal
	ON dem.employee_id = sal.employee_id
;
SELECT dem.employee_id, age, occupation
FROM employee_demographics AS dem
INNER JOIN employee_salary AS sal
	ON dem.employee_id = sal.employee_id
;

-- Outer Joins

SELECT *
FROM employee_demographics AS dem
RIGHT JOIN employee_salary AS sal
	ON dem.employee_id = sal.employee_id
;

-- Self join 

SELECT emp1.employee_id AS emp_santa, 
emp1.first_name AS first_name_santa,
emp1.last_name AS last_name_santa,
emp2.employee_id AS emp_name, 
emp2.first_name AS first_name_emp,
emp2.last_name AS last_name_emp
FROM employee_salary AS emp1
JOIN employee_salary AS emp2
	ON emp1.employee_id + 1 = emp2.employee_id
;

-- Joining multiple table together

SELECT *
FROM employee_demographics AS dem
INNER JOIN employee_salary AS sal
	ON dem.employee_id = sal.employee_id
INNER JOIN parks_departments AS pd
	ON sal.dept_id = pd.department_id
;
SELECT *
FROM parks_departments;