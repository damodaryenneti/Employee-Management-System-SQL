create database SQL_Project;
USE SQL_Project;

# Table 1: JobDepartment

CREATE TABLE JobDepartment (
Job_ID INT PRIMARY KEY,
jobdept VARCHAR(50),
name VARCHAR(100),
description TEXT,
salaryrange VARCHAR(50)
);
select * from JobDepartment;

# Table 2: SalaryBonus

CREATE TABLE SalaryBonus (
salary_ID INT PRIMARY KEY,
Job_ID INT,
amount DECIMAL(10,2),
annual DECIMAL(10,2),
bonus DECIMAL(10,2),
CONSTRAINT fk_salary_job FOREIGN KEY (job_ID) REFERENCES JobDepartment(Job_ID)
ON DELETE CASCADE ON UPDATE CASCADE
);
select * from SalaryBonus;

# Table 3: Employee
CREATE TABLE Employee (
emp_ID INT PRIMARY KEY,
firstname VARCHAR(50),
lastname VARCHAR(50),
gender VARCHAR(10),
age INT,
contact_add VARCHAR(100),
emp_email VARCHAR(100) UNIQUE,
emp_pass VARCHAR(50),
Job_ID INT,
CONSTRAINT fk_employee_job FOREIGN KEY (Job_ID)
REFERENCES JobDepartment(Job_ID)
ON DELETE SET NULL
ON UPDATE CASCADE
);

SELECT * FROM Employee;

# Table 4: Qualification

CREATE TABLE Qualification (
QualID INT PRIMARY KEY,
Emp_ID INT,
Position VARCHAR(50),
Requirements VARCHAR(255),
Date_In DATE,
CONSTRAINT fk_qualification_emp FOREIGN KEY (Emp_ID)
REFERENCES Employee(emp_ID)
ON DELETE CASCADE
ON UPDATE CASCADE
);
select * from Qualification;

# Table 5: Leaves

CREATE TABLE Leaves (
leave_ID INT PRIMARY KEY,
emp_ID INT,
date DATE,
reason TEXT,
CONSTRAINT fk_leave_emp FOREIGN KEY (emp_ID) REFERENCES Employee(emp_ID)
ON DELETE CASCADE ON UPDATE CASCADE
);
select * from leaves;

# Table 6: Payroll

CREATE TABLE Payroll (
payroll_ID INT PRIMARY KEY,
emp_ID INT,
job_ID INT,
salary_ID INT,
leave_ID INT,
date DATE,
report TEXT,
total_amount DECIMAL(10,2),
CONSTRAINT fk_payroll_emp FOREIGN KEY (emp_ID) REFERENCES Employee(emp_ID)
ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT fk_payroll_job FOREIGN KEY (job_ID) REFERENCES JobDepartment(job_ID)
ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT fk_payroll_salary FOREIGN KEY (salary_ID) REFERENCES
SalaryBonus(salary_ID)
ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT fk_payroll_leave FOREIGN KEY (leave_ID) REFERENCES Leaves(leave_ID)
ON DELETE SET NULL ON UPDATE CASCADE
);
select * from payroll;

# 1.Employee Insights

# How many unique employees are in the system?
SELECT 
    COUNT(DISTINCT emp_ID) AS total_employees
FROM
    Employee;

# Which departments have the highest number of employees?
WITH dept_count AS (
    SELECT 
        jd.jobdept AS department,
        COUNT(e.emp_ID) AS employee_count
    FROM Employee e
    JOIN JobDepartment jd
        ON e.Job_ID = jd.Job_ID
    GROUP BY jd.jobdept
)
SELECT *
FROM dept_count
WHERE employee_count = (
    SELECT MAX(employee_count)
    FROM dept_count
);

# What is the average salary per department?
SELECT 
    jd.jobdept AS department,
    ROUND(AVG(sb.annual), 2) AS avg_annual_salary
FROM JobDepartment jd
JOIN SalaryBonus sb
    ON jd.Job_ID = sb.Job_ID
GROUP BY jd.jobdept
ORDER BY avg_annual_salary DESC;

# Who are the top 5 highest-paid employees?
WITH ranked_employees AS (
    SELECT 
        e.emp_ID,
        CONCAT(e.firstname, ' ', e.lastname) AS employee_name,
        jd.name AS job_role,
        sb.annual AS annual_salary,
        ROW_NUMBER() OVER (ORDER BY sb.annual DESC) AS salary_rank
    FROM Employee e
    JOIN JobDepartment jd
        ON e.Job_ID = jd.Job_ID
    JOIN SalaryBonus sb
        ON e.Job_ID = sb.Job_ID
)
SELECT *
FROM ranked_employees
WHERE salary_rank <= 5;

# What is the total salary expenditure across the company?
SELECT 
    ROUND(SUM(sb.annual), 2) AS total_salary_expenditure
FROM Employee e
JOIN SalaryBonus sb
    ON e.Job_ID = sb.Job_ID;

#
# 2. Job Role and Department Analysis.

# How many different job roles exist in each department?
SELECT 
    jobdept AS department,
    COUNT(DISTINCT name) AS total_job_roles
FROM JobDepartment
GROUP BY jobdept
ORDER BY total_job_roles DESC;

# What is the average salary range per department?
SELECT 
    jobdept AS department,
    ROUND(
        AVG(
            CAST(
                SUBSTRING_INDEX(
                    REPLACE(salaryrange, '$', ''),
                    ' - ',
                    -1
                ) AS DECIMAL(10,2)
            )
        )
        -
        AVG(
            CAST(
                SUBSTRING_INDEX(
                    REPLACE(salaryrange, '$', ''),
                    ' - ',
                    1
                ) AS DECIMAL(10,2)
            )
        ),
        2
    ) AS salary_range
FROM JobDepartment
GROUP BY jobdept;
# Which job roles offer the highest salary?
SELECT 
    jd.name AS job_role,
    jd.jobdept AS department,
    sb.annual AS annual_salary
FROM JobDepartment jd
JOIN SalaryBonus sb
    ON jd.Job_ID = sb.Job_ID
WHERE sb.annual = (
    SELECT MAX(annual)
    FROM SalaryBonus
);

# Which departments have the highest total salary allocation?
WITH dept_salary AS (
    SELECT 
        jd.jobdept AS department,
        SUM(sb.annual) AS total_annual_allocation
    FROM JobDepartment jd
    JOIN SalaryBonus sb
        ON jd.Job_ID = sb.Job_ID
    GROUP BY jd.jobdept
)
SELECT *
FROM dept_salary
WHERE total_annual_allocation = (
    SELECT MAX(total_annual_allocation)
    FROM dept_salary
);

#3. Qualification and Skills Analysis.

# How many employees have at least one qualification listed?
SELECT COUNT(*) AS employees_with_qualification
FROM (
    SELECT DISTINCT Emp_ID
    FROM Qualification
) AS qualified_employees;

# Which positions require the most qualifications?
SELECT Position, total_qualifications
FROM (
    SELECT 
        Position,
        COUNT(QualID) AS total_qualifications,
        RANK() OVER (ORDER BY COUNT(QualID) DESC) AS position_rank
    FROM Qualification
    GROUP BY Position
) t
WHERE position_rank <= 5
ORDER BY position_rank;

# Which employees have the highest number of qualifications?
WITH employee_qualification AS (
    SELECT 
        e.emp_ID,
        CONCAT(e.firstname, ' ', e.lastname) AS full_name,
        COUNT(q.QualID) AS total_qualifications
    FROM Employee e
    LEFT JOIN Qualification q
        ON e.emp_ID = q.Emp_ID
    GROUP BY 
        e.emp_ID,
        e.firstname,
        e.lastname
),
ranked_employees AS (
    SELECT *,
           RANK() OVER (
               ORDER BY total_qualifications DESC
           ) AS qualification_rank
    FROM employee_qualification
)
SELECT 
    emp_ID,
    full_name,
    total_qualifications
FROM ranked_employees
WHERE qualification_rank <= 10
ORDER BY qualification_rank;

# 4: Leave and Absence Patterns.

# Which year had the most employees taking leaves?
SELECT YEAR(date) AS leave_year,
COUNT(DISTINCT emp_ID) AS employees_on_leave
FROM Leaves
GROUP BY YEAR(date)
ORDER BY employees_on_leave DESC
LIMIT 1;

# What is the average number of leave days taken by employees per department?
SELECT 
    jd.jobdept AS department,
    ROUND(AVG(emp_leave.leave_days), 2) AS avg_leave_days
FROM JobDepartment jd
JOIN Employee e
    ON jd.Job_ID = e.Job_ID
LEFT JOIN (
    SELECT 
        emp_ID,
        COUNT(leave_ID) AS leave_days
    FROM Leaves
    GROUP BY emp_ID
) emp_leave
    ON e.emp_ID = emp_leave.emp_ID
GROUP BY jd.jobdept
ORDER BY avg_leave_days DESC;

# Which employees have taken the most leaves?
SELECT 
    e.emp_ID,
    CONCAT(e.firstname, ' ', e.lastname) AS full_name,
    COUNT(l.leave_ID) AS total_leaves
FROM Employee e
JOIN Leaves l ON e.emp_ID = l.emp_ID
GROUP BY e.emp_ID, e.firstname, e.lastname
ORDER BY total_leaves DESC;

# What is the total number of leave days company-wide?
CREATE VIEW vw_total_leave_days AS
SELECT 
    COUNT(leave_ID) AS total_leave_days
FROM Leaves;
SELECT * 
FROM vw_total_leave_days;

# How do leave days correlate with payroll amounts?
WITH employee_data AS (
    SELECT 
        e.emp_ID,
        (SELECT COUNT(*) 
         FROM Leaves l 
         WHERE l.emp_ID = e.emp_ID) AS leave_days,
        (SELECT COALESCE(SUM(p.total_amount), 0) 
         FROM Payroll p 
         WHERE p.emp_ID = e.emp_ID) AS payroll_amount
    FROM Employee e
)
SELECT 
    ROUND(
        (AVG(leave_days * payroll_amount) - AVG(leave_days) * AVG(payroll_amount))
        / (STDDEV_POP(leave_days) * STDDEV_POP(payroll_amount)),
        4
    ) AS correlation
FROM employee_data;

# 5: Payroll and Compensation Analysis.

# What is the total monthly payroll processed?
SELECT DATE_FORMAT(date, '%Y-%m') AS payroll_month,
SUM(total_amount) AS total_monthly_payroll
FROM Payroll
GROUP BY DATE_FORMAT(date, '%Y-%m')
ORDER BY payroll_month;

#  What is the average bonus given per department?
SELECT 
    jd.jobdept AS department,
    ROUND(AVG(sb.bonus), 2) AS avg_bonus
FROM JobDepartment jd
JOIN SalaryBonus sb
    ON jd.Job_ID = sb.Job_ID
GROUP BY jd.jobdept
ORDER BY avg_bonus DESC;

# Which department receives the highest total bonuses?
WITH department_bonus AS (
    SELECT 
        jd.jobdept AS department,
        SUM(sb.bonus) AS total_bonus
    FROM JobDepartment jd
    JOIN SalaryBonus sb
        ON jd.Job_ID = sb.Job_ID
    GROUP BY jd.jobdept
),
ranked_bonus AS (
    SELECT *,
           RANK() OVER (
               ORDER BY total_bonus DESC
           ) AS bonus_rank
    FROM department_bonus
)
SELECT 
    department,
    total_bonus
FROM ranked_bonus
WHERE bonus_rank = 1;

# What is the average value of total_amount after considering leave deductions?
SELECT 
    ROUND(AVG(total_amount), 2) AS avg_net_payroll
FROM Payroll;






