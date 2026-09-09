-- Having vs Where

SELECT gender, AVG(age)
FROM employee_demographics
GROUP BY gender
HAVING AVG(age) > 40
;

SELECT occupation, AVG(salary)
FROM employee_salary
WHERE occupation LIKE '%mana%'
GROUP BY occupation
HAVING AVG(salary) > 75000
;