-- Active: 1775134706375@@127.0.0.1@3306@agri_coffee_db
-- ============================================================
-- SECTION 1: DATABASE SETUP
-- ============================================================

DROP DATABASE IF EXISTS agri_coffee_db_1;

CREATE DATABASE agri_coffee_db
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE agri_coffee_db;


-- ============================================================
-- SECTION 2: TABLES
-- ============================================================

-- 1. District
DROP TABLE IF EXISTS District;
CREATE TABLE District (
    DistrictID INT AUTO_INCREMENT PRIMARY KEY,
    DistrictName VARCHAR(100) NOT NULL UNIQUE
);

-- 2. Village
DROP TABLE IF EXISTS Village;
CREATE TABLE Village (
    VillageID INT AUTO_INCREMENT PRIMARY KEY,
    VillageName VARCHAR(100) NOT NULL,
    ParishName VARCHAR(100),
    DistrictID INT NOT NULL,
    FOREIGN KEY (DistrictID) REFERENCES District(DistrictID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 3. Stakeholder
DROP TABLE IF EXISTS Stakeholder;
CREATE TABLE Stakeholder (
    StakeholderID INT AUTO_INCREMENT PRIMARY KEY,
    NationalID VARCHAR(20) NOT NULL UNIQUE,
    FullName VARCHAR(150) NOT NULL,
    Gender ENUM('Male','Female','Other'),
    Phone VARCHAR(20) NOT NULL,
    RegisteredDate DATE DEFAULT (CURDATE())
);

-- 4. Farmer
DROP TABLE IF EXISTS Farmer;
CREATE TABLE Farmer (
    StakeholderID INT PRIMARY KEY,
    HouseholdSize TINYINT,
    LiteracyLevel ENUM('None','Primary','Secondary','Tertiary'),
    TotalAcreage DECIMAL(8,2) NOT NULL CHECK (TotalAcreage > 0),
    FOREIGN KEY (StakeholderID) REFERENCES Stakeholder(StakeholderID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 5. ExtensionWorker
DROP TABLE IF EXISTS ExtensionWorker;
CREATE TABLE ExtensionWorker (
    StakeholderID INT PRIMARY KEY,
    Qualification VARCHAR(100),
    Rank VARCHAR(50),
    DistrictID INT NOT NULL,
    FOREIGN KEY (StakeholderID) REFERENCES Stakeholder(StakeholderID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (DistrictID) REFERENCES District(DistrictID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 6. NurseryOperator
DROP TABLE IF EXISTS NurseryOperator;
CREATE TABLE NurseryOperator (
    StakeholderID INT PRIMARY KEY,
    LicenseNumber VARCHAR(30) NOT NULL UNIQUE,
    NurseryCapacity INT,
    LicenseExpiry DATE NOT NULL,
    FOREIGN KEY (StakeholderID) REFERENCES Stakeholder(StakeholderID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 7. MinistryAdmin
DROP TABLE IF EXISTS MinistryAdmin;
CREATE TABLE MinistryAdmin (
    StakeholderID INT PRIMARY KEY,
    Department VARCHAR(100),
    PermissionLevel TINYINT DEFAULT 1,
    FOREIGN KEY (StakeholderID) REFERENCES Stakeholder(StakeholderID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 8. Nursery
DROP TABLE IF EXISTS Nursery;
CREATE TABLE Nursery (
    NurseryID INT AUTO_INCREMENT PRIMARY KEY,
    OperatorID INT,
    NurseryName VARCHAR(150) NOT NULL,
    Location VARCHAR(255),
    DistrictID INT,
    FOREIGN KEY (OperatorID) REFERENCES NurseryOperator(StakeholderID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (DistrictID) REFERENCES District(DistrictID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 9. SeedlingBatch
DROP TABLE IF EXISTS SeedlingBatch;
CREATE TABLE SeedlingBatch (
    BatchID INT AUTO_INCREMENT PRIMARY KEY,
    NurseryID INT,
    Variety VARCHAR(100) NOT NULL,
    QuantityAvailable INT NOT NULL DEFAULT 0,
    CertifiedStatus ENUM('Yes','No') DEFAULT 'No',
    CertDate DATE,
    CHECK (CertifiedStatus = 'No' OR CertDate IS NOT NULL),
    FOREIGN KEY (NurseryID) REFERENCES Nursery(NurseryID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 10. Distribution
DROP TABLE IF EXISTS Distribution;
CREATE TABLE Distribution (
    DistributionID INT AUTO_INCREMENT PRIMARY KEY,
    BatchID INT,
    FarmerID INT,
    QuantityGiven INT NOT NULL CHECK (QuantityGiven > 0),
    DistributionDate DATE NOT NULL,
    CHECK (MONTH(DistributionDate) BETWEEN 6 AND 8),
    FOREIGN KEY (BatchID) REFERENCES SeedlingBatch(BatchID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (FarmerID) REFERENCES Farmer(StakeholderID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 11. Plot
DROP TABLE IF EXISTS Plot;
CREATE TABLE Plot (
    PlotID INT AUTO_INCREMENT PRIMARY KEY,
    FarmerID INT,
    GPSLat DECIMAL(10,7) NOT NULL,
    GPSLong DECIMAL(10,7) NOT NULL,
    AreaHectares DECIMAL(8,2) CHECK (AreaHectares > 0),
    SoilType VARCHAR(50),
    VillageID INT,
    FOREIGN KEY (FarmerID) REFERENCES Farmer(StakeholderID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (VillageID) REFERENCES Village(VillageID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 12. HarvestRecord
DROP TABLE IF EXISTS HarvestRecord;
CREATE TABLE HarvestRecord (
    HarvestID INT AUTO_INCREMENT PRIMARY KEY,
    PlotID INT,
    SeasonYear YEAR NOT NULL,
    QuantityKg DECIMAL(10,2) CHECK (QuantityKg > 0),
    ProcessingMethod ENUM('Washed','Natural','Honey') NOT NULL,
    MoistureLevel DECIMAL(4,2) CHECK (MoistureLevel <= 12.5),
    HarvestDate DATE NOT NULL,
    ComplianceStatus ENUM('Compliant','Non-Compliant') DEFAULT 'Compliant',
    FOREIGN KEY (PlotID) REFERENCES Plot(PlotID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 13. ExtensionProvider
DROP TABLE IF EXISTS ExtensionProvider;
CREATE TABLE ExtensionProvider (
    ProviderID INT AUTO_INCREMENT PRIMARY KEY,
    ProviderType ENUM('Government','NGO') NOT NULL
);

-- 14. GovernmentDept
DROP TABLE IF EXISTS GovernmentDept;
CREATE TABLE GovernmentDept (
    DeptID INT AUTO_INCREMENT PRIMARY KEY,
    ProviderID INT,
    DeptName VARCHAR(150) NOT NULL,
    MinistryBranch VARCHAR(100),
    FOREIGN KEY (ProviderID) REFERENCES ExtensionProvider(ProviderID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 15. NGO
DROP TABLE IF EXISTS NGO;
CREATE TABLE NGO (
    NGOID INT AUTO_INCREMENT PRIMARY KEY,
    ProviderID INT,
    NGOName VARCHAR(150) NOT NULL,
    RegistrationNumber VARCHAR(50) UNIQUE,
    FOREIGN KEY (ProviderID) REFERENCES ExtensionProvider(ProviderID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 16. AuditLog
DROP TABLE IF EXISTS AuditLog;
CREATE TABLE AuditLog (
    LogID INT AUTO_INCREMENT PRIMARY KEY,
    TableName VARCHAR(50),
    ActionType ENUM('INSERT','UPDATE','DELETE'),
    RecordID INT,
    ChangedBy VARCHAR(50) DEFAULT (CURRENT_USER()),
    ChangeTimestamp DATETIME DEFAULT NOW(),
    Notes TEXT
);


-- ============================================================
-- SECTION 3: TRIGGERS
-- ============================================================

DELIMITER $$

-- T1: Validate Distribution
DROP TRIGGER IF EXISTS trg_distribution_validate $$
CREATE TRIGGER trg_distribution_validate
BEFORE INSERT ON Distribution
FOR EACH ROW
BEGIN
    DECLARE v_cert VARCHAR(3);
    DECLARE v_acre DECIMAL(8,2);
    DECLARE v_exp DATE;

    SELECT CertifiedStatus INTO v_cert FROM SeedlingBatch WHERE BatchID = NEW.BatchID;
    IF v_cert = 'No' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Batch not certified';
    END IF;

    SELECT TotalAcreage INTO v_acre FROM Farmer WHERE StakeholderID = NEW.FarmerID;
    IF NEW.QuantityGiven > v_acre * 1000 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quantity exceeds acreage limit';
    END IF;

    SELECT no.LicenseExpiry INTO v_exp
    FROM SeedlingBatch sb
    JOIN Nursery n ON sb.NurseryID = n.NurseryID
    JOIN NurseryOperator no ON n.OperatorID = no.StakeholderID
    WHERE sb.BatchID = NEW.BatchID;

    IF v_exp < CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'License expired';
    END IF;
END $$

-- T2: Reduce stock
DROP TRIGGER IF EXISTS trg_distribution_reduce_stock $$
CREATE TRIGGER trg_distribution_reduce_stock
AFTER INSERT ON Distribution
FOR EACH ROW
BEGIN
    UPDATE SeedlingBatch
    SET QuantityAvailable = QuantityAvailable - NEW.QuantityGiven
    WHERE BatchID = NEW.BatchID;
END $$

-- T3: Compliance
DROP TRIGGER IF EXISTS trg_harvest_compliance_check $$
CREATE TRIGGER trg_harvest_compliance_check
AFTER INSERT ON HarvestRecord
FOR EACH ROW
BEGIN
    IF NEW.MoistureLevel > 12.5 THEN
        UPDATE HarvestRecord
        SET ComplianceStatus = 'Non-Compliant'
        WHERE HarvestID = NEW.HarvestID;
    END IF;
END $$

-- Audit triggers
DROP TRIGGER IF EXISTS trg_audit_farmer_insert $$
CREATE TRIGGER trg_audit_farmer_insert
AFTER INSERT ON Farmer
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog(TableName, ActionType, RecordID, Notes)
    VALUES ('Farmer','INSERT',NEW.StakeholderID,'New farmer registered');
END $$

DROP TRIGGER IF EXISTS trg_audit_distribution_insert $$
CREATE TRIGGER trg_audit_distribution_insert
AFTER INSERT ON Distribution
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog(TableName, ActionType, RecordID, Notes)
    VALUES ('Distribution','INSERT',NEW.DistributionID,
            CONCAT('Qty: ',NEW.QuantityGiven));
END $$

DELIMITER ;


-- ============================================================
-- SECTION 4: STORED PROCEDURES
-- ============================================================

DELIMITER $$

DROP PROCEDURE IF EXISTS RegisterFarmer $$
CREATE PROCEDURE RegisterFarmer(
    IN p_NationalID VARCHAR(20),
    IN p_FullName VARCHAR(100),
    IN p_Gender VARCHAR(10),
    IN p_Phone VARCHAR(20),
    IN p_HouseholdSize INT,
    IN p_LiteracyLevel VARCHAR(20),
    IN p_TotalAcreage DECIMAL(8,2)
)
BEGIN
    DECLARE v_id INT;

    START TRANSACTION;

    INSERT INTO Stakeholder(NationalID,FullName,Gender,Phone)
    VALUES(p_NationalID,p_FullName,p_Gender,p_Phone);

    SET v_id = LAST_INSERT_ID();

    INSERT INTO Farmer VALUES(v_id,p_HouseholdSize,p_LiteracyLevel,p_TotalAcreage);

    COMMIT;

    SELECT v_id AS NewFarmerID;
END $$

DELIMITER ;


-- ============================================================
-- SECTION 5: VIEWS
-- ============================================================

CREATE OR REPLACE VIEW vw_distribution_report AS
SELECT s.FullName, sb.Variety, d.QuantityGiven, n.NurseryName, d.DistributionDate
FROM Distribution d
JOIN Farmer f ON d.FarmerID = f.StakeholderID
JOIN Stakeholder s ON f.StakeholderID = s.StakeholderID
JOIN SeedlingBatch sb ON d.BatchID = sb.BatchID
JOIN Nursery n ON sb.NurseryID = n.NurseryID;


-- ============================================================
-- SECTION 6: ROLES
-- ============================================================

CREATE ROLE IF NOT EXISTS role_admin;
GRANT ALL PRIVILEGES ON agri_coffee_db.* TO role_admin;

CREATE USER IF NOT EXISTS 'admin_user'@'localhost' IDENTIFIED BY 'Admin@123';
GRANT role_admin TO 'admin_user'@'localhost';
SET DEFAULT ROLE role_admin TO 'admin_user'@'localhost';


-- ============================================================
-- SECTION 7: SAMPLE DATA
-- ============================================================

INSERT INTO District (DistrictName) VALUES ('Masaka'),('Mbarara'),('Kampala');

INSERT INTO Village (VillageName,ParishName,DistrictID) VALUES
('VillageA','Parish1',1),
('VillageB','Parish2',2);

INSERT INTO Stakeholder (NationalID,FullName,Gender,Phone) VALUES
('CF001','John Farmer','Male','0700000001'),
('CF002','Mary Farmer','Female','0700000002');

INSERT INTO Farmer VALUES (1,5,'Primary',2.5),(2,4,'Secondary',3.0);


-- ============================================================
-- SECTION 8: BACKUP STRATEGY
-- ============================================================

-- BACKUP:
-- mysqldump -u root -p agri_coffee_db > backup_YYYY_MM_DD.sql

-- RESTORE:
-- mysql -u root -p agri_coffee_db < backup_YYYY_MM_DD.sql

-- Schedule: Daily backups recommended