CREATE DATABASE company_constraints;

-- Usar o banco de dados recém-criado
USE company_constraints;

CREATE TABLE employee (
    Fname VARCHAR(15) NOT NULL,
    Mint CHAR,
    Lname VARCHAR(15) NOT NULL,
    Ssn CHAR(9) NOT NULL,
    Bdate DATE,
    Address VARCHAR(30),
    Sex CHAR,
    Salary DECIMAL(10,2),
    Super_ssn CHAR(9),
    Dno INT NOT NULL,
    CONSTRAINT chk_salary_employee CHECK (Salary > 2000.0),
    CONSTRAINT pk_employee PRIMARY KEY (Ssn)
);

-- Adicionar a foreign key para a tabela employee
ALTER TABLE employee
    ADD CONSTRAINT fk_employee
    FOREIGN KEY (Super_ssn) REFERENCES employee(Ssn)
    ON DELETE SET NULL
    ON UPDATE CASCADE;

-- Criar a tabela department
CREATE TABLE department (
    Dname VARCHAR(15) NOT NULL,
    Dnumber INT NOT NULL,
    Mgr_ssn CHAR(9),
    Mgr_start_date DATE,
    Dept_create_date DATE,
    CONSTRAINT chk_date_dpt CHECK (Dept_create_date < Mgr_start_date),
    CONSTRAINT chk_dept PRIMARY KEY (Dnumber),
    CONSTRAINT unique_name_dept UNIQUE (Dname),
    FOREIGN KEY (Mgr_ssn) REFERENCES employee(Ssn)
);

-- Adicionar a foreign key para a tabela department
ALTER TABLE department
    ADD CONSTRAINT fk_dept
    FOREIGN KEY (Mgr_ssn) REFERENCES employee(Ssn)
    ON UPDATE CASCADE;

-- Criar a tabela dept_locations
CREATE TABLE dept_locations (
    Dnumber INT NOT NULL,
    Dlocation VARCHAR(15) NOT NULL,
    CONSTRAINT pk_dept_locations PRIMARY KEY (Dnumber, Dlocation),
    CONSTRAINT fk_dept_locations FOREIGN KEY (Dnumber) REFERENCES department(Dnumber)
);

-- Criar a tabela project
CREATE TABLE project (
    Pname VARCHAR(15) NOT NULL,
    Pnumber INT NOT NULL,
    Plocation VARCHAR(15),
    Dnum INT NOT NULL,
    PRIMARY KEY (Pnumber),
    CONSTRAINT unique_project UNIQUE (Pname),
    CONSTRAINT fk_project FOREIGN KEY (Dnum) REFERENCES department(Dnumber)
);

-- Criar a tabela works_on
CREATE TABLE works_on (
    Essn CHAR(9) NOT NULL,
    Pno INT NOT NULL,
    Hours DECIMAL(3,1) NOT NULL,
    PRIMARY KEY (Essn, Pno),
    CONSTRAINT fk_employee_works_on FOREIGN KEY (Essn) REFERENCES employee(Ssn),
    CONSTRAINT fk_project_works_on FOREIGN KEY (Pno) REFERENCES project(Pnumber)
);

-- Criar a tabela dependent
CREATE TABLE dependent (
    Essn CHAR(9) NOT NULL,
    Dependent_name VARCHAR(15) NOT NULL,
    Sex CHAR,
    Bdate DATE,
    Relationship VARCHAR(8),
    PRIMARY KEY (Essn, Dependent_name),
    CONSTRAINT fk_dependent FOREIGN KEY (Essn) REFERENCES employee(Ssn)
);

-- View para número de empregados por departamento e localidade
CREATE OR REPLACE VIEW EmpregadosPorDepartamentoELocalidade AS
SELECT 
    d.Dname AS Departamento,
    l.Dlocation AS Localidade,
    COUNT(e.Ssn) AS NumeroEmpregados
FROM 
    department d
JOIN 
    dept_locations l ON d.Dnumber = l.Dnumber
LEFT JOIN 
    employee e ON d.Dnumber = e.Dno
GROUP BY 
    d.Dname, l.Dlocation;

-- View para lista de departamentos e seus gerentes
CREATE OR REPLACE VIEW DepartamentosEGerentes AS
SELECT 
    d.Dname AS Departamento,
    e.Fname AS GerenteNome,
    e.Lname AS GerenteSobrenome
FROM 
    department d
LEFT JOIN 
    employee e ON d.Mgr_ssn = e.Ssn;

-- View para projetos com maior número de empregados
CREATE OR REPLACE VIEW ProjetosComMaisEmpregados AS
SELECT 
    p.Pname AS Projeto,
    COUNT(w.Essn) AS NumeroEmpregados
FROM 
    project p
LEFT JOIN 
    works_on w ON p.Pnumber = w.Pno
GROUP BY 
    p.Pname
ORDER BY 
    NumeroEmpregados DESC;

-- View para lista de projetos, departamentos e gerentes
CREATE OR REPLACE VIEW ProjetosDepartamentosEGerentes AS
SELECT 
    p.Pname AS Projeto,
    d.Dname AS Departamento,
    e.Fname AS GerenteNome,
    e.Lname AS GerenteSobrenome
FROM 
    project p
JOIN 
    department d ON p.Dnum = d.Dnumber
LEFT JOIN 
    employee e ON d.Mgr_ssn = e.Ssn;

-- View para empregados com dependentes e se são gerentes
CREATE OR REPLACE VIEW EmpregadosComDependentesEGerentes AS
SELECT 
    e.Fname AS NomeEmpregado,
    e.Lname AS SobrenomeEmpregado,
    d.Dependent_name AS NomeDependente,
    CASE 
        WHEN e.Ssn IN (SELECT Mgr_ssn FROM department) THEN 'Sim'
        ELSE 'Não'
    END AS EGerente
FROM 
    employee e
LEFT JOIN 
    dependent d ON e.Ssn = d.Essn;
    
    -- Criar usuário gerente
CREATE USER 'gerente'@'localhost' IDENTIFIED BY 'senha_gerente';

-- Criar usuário empregado
CREATE USER 'empregado'@'localhost' IDENTIFIED BY 'senha_empregado';

-- Conceder permissões ao usuário gerente
GRANT SELECT ON company_constraints.employee TO 'gerente'@'localhost';
GRANT SELECT ON company_constraints.department TO 'gerente'@'localhost';

-- Conceder permissões ao usuário empregado
GRANT SELECT ON company_constraints.employee TO 'empregado'@'localhost';

-- Aplicar as mudanças
FLUSH PRIVILEGES;
