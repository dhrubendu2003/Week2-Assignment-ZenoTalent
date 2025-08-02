-- Projects table
CREATE TABLE week2_assignment.Projects (
    project_id INT PRIMARY KEY,
    project_name VARCHAR(255) NOT NULL,
    start_date DATE,
    end_date DATE,
    budget DECIMAL(15, 2)
);

INSERT INTO Projects (project_id, project_name, start_date, end_date, budget) VALUES
(1, 'Website Redesign', '2024-01-15', '2024-06-30', 50000.00),
(2, 'Mobile App Launch', '2024-03-01', '2024-12-15', 120000.00),
(3, 'Data Migration', '2024-02-01', '2024-08-20', 75000.00),
(4, 'AI Chatbot', '2024-04-10', '2024-11-30', 95000.00),
(5, 'Internal Tool Upgrade', '2024-01-01', '2024-05-31', 30000.00);


-- Teams Table
CREATE TABLE Teams (
    team_id INT PRIMARY KEY,
    team_name VARCHAR(255) NOT NULL,
    team_lead_id INT
);

INSERT INTO Teams (team_id, team_name, team_lead_id) VALUES
(1, 'Frontend Team', 101),
(2, 'Backend Team', 102),
(3, 'DevOps Team', 103),
(4, 'AI/ML Team', 104);


-- Tasks table
CREATE TABLE Tasks (
    task_id INT PRIMARY KEY,
    project_id INT,
    assigned_to INT,
    task_name VARCHAR(255) NOT NULL,
    status VARCHAR(50),
    due_date DATE,
    FOREIGN KEY (project_id) REFERENCES Projects(project_id)
);

INSERT INTO Tasks (task_id, project_id, assigned_to, task_name, status, due_date) VALUES
(1, 1, 201, 'Design Homepage', 'Completed', '2024-02-10'),
(2, 1, 202, 'Implement Contact Form', 'Completed', '2024-02-20'),
(3, 1, 203, 'Optimize Images', 'Pending', '2024-03-15'),
(4, 2, 204, 'Develop Login Feature', 'Completed', '2024-04-05'),
(5, 2, 205, 'Integrate Payment Gateway', 'Pending', '2024-05-10'),
(6, 2, 201, 'Write Unit Tests', 'Pending', '2024-06-01'),
(7, 3, 206, 'Extract Data from Old System', 'Completed', '2024-03-01'),
(8, 3, 207, 'Transform Data', 'Completed', '2024-03-20'),
(9, 3, 208, 'Load Data into New System', 'Pending', '2024-04-10'),
(10, 4, 209, 'Train Initial Model', 'Completed', '2024-05-20'),
(11, 4, 210, 'Fine-tune Model', 'Pending', '2024-06-15'),
(12, 4, 211, 'Deploy Model', 'Pending', '2024-07-10'),
(13, 5, 212, 'Update Dependencies', 'Completed', '2024-02-15'),
(14, 5, 213, 'Refactor Core Module', 'Pending', '2024-03-25'),
(15, 1, 201, 'SEO Optimization', 'Pending', '2024-04-05');


-- Model_Training table
CREATE TABLE Model_Training (
    training_id INT PRIMARY KEY,
    project_id INT,
    model_name VARCHAR(255),
    accuracy DECIMAL(5, 4),
    training_date DATE,
    FOREIGN KEY (project_id) REFERENCES Projects(project_id)
);

INSERT INTO Model_Training (training_id, project_id, model_name, accuracy, training_date) VALUES
(1, 4, 'Chatbot v1.0', 0.8567, '2024-05-15'),
(2, 4, 'Chatbot v1.1', 0.8923, '2024-05-25'),
(3, 4, 'Chatbot v1.2', 0.9156, '2024-06-05');


-- Data_Sets table
CREATE TABLE Data_Sets (
    dataset_id INT PRIMARY KEY,
    project_id INT,
    dataset_name VARCHAR(255),
    size_gb DECIMAL(10, 2),
    last_updated DATE,
    FOREIGN KEY (project_id) REFERENCES Projects(project_id)
);

INSERT INTO Data_Sets (dataset_id, project_id, dataset_name, size_gb, last_updated) VALUES
(1, 4, 'Chat Logs Q1', 15.50, '2024-06-01'),
(2, 4, 'Chat Logs Q2', 12.30, '2024-06-05'),
(3, 2, 'User Analytics', 8.75, '2024-05-28'),
(4, 3, 'Legacy DB Dump', 25.00, '2024-05-20'),
(5, 1, 'Website Analytics', 5.20, '2024-04-15');


-- 1.
WITH TaskCounts AS (
    SELECT
        project_id,
        COUNT(*) AS total_tasks,
        COUNT(CASE WHEN status = 'Completed' THEN 1 END) AS completed_tasks
    FROM Tasks
    GROUP BY project_id
)
SELECT
    p.project_name,
    COALESCE(tc.total_tasks, 0) AS total_tasks,
    COALESCE(tc.completed_tasks, 0) AS completed_tasks
FROM Projects p
LEFT JOIN TaskCounts tc ON p.project_id = tc.project_id
ORDER BY p.project_name;


-- 2.
WITH MemberTaskCount AS (
    SELECT
        assigned_to,
        COUNT(*) AS task_count
    FROM Tasks
    GROUP BY assigned_to
),
RankedMembers AS (
    SELECT
        assigned_to,
        task_count,
        ROW_NUMBER() OVER (ORDER BY task_count DESC) AS rn
    FROM MemberTaskCount
)
SELECT assigned_to, task_count
FROM RankedMembers
WHERE rn <= 2;


-- 3.
SELECT t1.task_id, t1.task_name, t1.due_date, t1.project_id
FROM Tasks t1
WHERE t1.due_date < (
    SELECT AVG(t2.due_date)
    FROM Tasks t2
    WHERE t2.project_id = t1.project_id
);


-- 4. 
SELECT project_id, project_name, budget
FROM Projects
WHERE budget = (SELECT MAX(budget) FROM Projects);


-- 5.
SELECT
    p.project_id,
    p.project_name,
    COUNT(t.task_id) AS total_tasks,
    COUNT(CASE WHEN t.status = 'Completed' THEN 1 END) AS completed_tasks,
    CASE
        WHEN COUNT(t.task_id) = 0 THEN 0
        ELSE (COUNT(CASE WHEN t.status = 'Completed' THEN 1 END) * 100.0) / COUNT(t.task_id)
    END AS completion_percentage
FROM Projects p
LEFT JOIN Tasks t ON p.project_id = t.project_id
GROUP BY p.project_id, p.project_name
ORDER BY p.project_name;


-- 6.
SELECT
    task_id,
    assigned_to,
    task_name,
    COUNT(*) OVER (PARTITION BY assigned_to) AS tasks_assigned_count
FROM Tasks
ORDER BY assigned_to, task_id;


-- 7.
SELECT t.task_id, t.task_name, t.assigned_to, t.due_date
FROM Tasks t
JOIN Teams tm ON t.assigned_to = tm.team_lead_id
WHERE t.status != 'Completed'
  AND t.due_date BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE, INTERVAL 15 DAY);


-- 8. 
SELECT p.project_id, p.project_name
FROM Projects p
LEFT JOIN Tasks t ON p.project_id = t.project_id
WHERE t.project_id IS NULL;


-- 9.
WITH RankedModels AS (
    SELECT
        mt.project_id,
        mt.model_name,
        mt.accuracy,
        ROW_NUMBER() OVER (PARTITION BY mt.project_id ORDER BY mt.accuracy DESC) AS rn
    FROM Model_Training mt
)
SELECT
    p.project_name,
    rm.model_name,
    rm.accuracy
FROM Projects p
JOIN RankedModels rm ON p.project_id = rm.project_id
WHERE rm.rn = 1;


-- 10.
SELECT DISTINCT
    p.project_id,
    p.project_name
FROM Projects p
JOIN Data_Sets ds ON p.project_id = ds.project_id
WHERE ds.size_gb > 10
  AND ds.last_updated >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY);

