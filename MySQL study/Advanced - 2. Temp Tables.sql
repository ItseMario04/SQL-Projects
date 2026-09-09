-- Temporary Tables

CREATE TEMPORARY TABLE temp_table
(first_name varchar(50),
last_name varchar(50),
favorite_movie varchar(100)
);

SELECT *
FROM temp_table;

INSERT INTO temp_table
VALUES('Mykola', 'Herasymchuk', 'Batman');

CREATE TEMPORARY TABLE salary_over_50k
SELECT *
FROM employee_salary
where salary >= 50000;

SELECT *
FROM salary_over_50k;