-- Active: 1775134706375@@127.0.0.1@3306@agri_coffee_db
-- ============================================================
-- SECTION 1: DATABASE SETUP
-- ============================================================
-- Drop database if it exists to allow for clean re-runs
DROP DATABASE IF EXISTS agri_coffee_db;
CREATE DATABASE agri_coffee_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE agri_coffee_db;

-- ============================================================
-- SECTION 2: TABLE STRUCTURE
-- ============================================================

-- 1. District: Stores high-level regional locations
CREATE TABLE District (
    DistrictID INT PRIMARY KEY AUTO_INCREMENT,
    DistrictName VARCHAR(100) UNIQUE NOT NULL
);

-- 2. Village: Stores local areas linked to Districts
CREATE TABLE Village (
    VillageID INT PRIMARY KEY AUTO_INCREMENT,
    VillageName VARCHAR(100) NOT NULL,
    ParishName VARCHAR(100),
    DistrictID INT NOT NULL,
    FOREIGN KEY (DistrictID) REFERENCES District(DistrictID) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 3. Stakeholder: Base table for all people (Superclass)
CREATE TABLE Stakeholder (
    StakeholderID INT AUTO_INCREMENT PRIMARY KEY,
    NationalID VARCHAR(20) UNIQUE NOT NULL,
    FullName VARCHAR(255) NOT NULL,
    Gender ENUM('Male', 'Female', 'Other'),
    Phone VARCHAR(20) NOT NULL,
    RegisteredDate DATE DEFAULT (CURDATE())
);

-- 4. Farmer: Subclass of Stakeholder
CREATE TABLE Farmer (
    StakeholderID INT PRIMARY KEY,
    HouseholdSize TINYINT,
    LiteracyLevel ENUM('None', 'Primary', 'Secondary', 'Tertiary'),
    TotalAcreage DECIMAL(8,2) NOT NULL CHECK (TotalAcreage > 0),
    FOREIGN KEY (StakeholderID) REFERENCES Stakeholder(StakeholderID) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 5. ExtensionWorker: Subclass of Stakeholder linked to a District
CREATE TABLE ExtensionWorker (
    StakeholderID INT PRIMARY KEY,
    Qualification VARCHAR(100),
    Extension_Rank VARCHAR(50),
    DistrictID INT NOT NULL,
    FOREIGN KEY (StakeholderID) REFERENCES Stakeholder(StakeholderID) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (DistrictID) REFERENCES District(DistrictID) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 6. NurseryOperator: Subclass of Stakeholder with licensing
CREATE TABLE NurseryOperator (
    StakeholderID INT PRIMARY KEY,
    LicenseNumber VARCHAR(30) UNIQUE NOT NULL,
    NurseryCapacity INT,
    LicenseExpiry DATE NOT NULL,
    FOREIGN KEY (StakeholderID) REFERENCES Stakeholder(StakeholderID) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 7. MinistryAdmin: Subclass of Stakeholder for system oversight
CREATE TABLE MinistryAdmin (
    StakeholderID INT PRIMARY KEY,
    Department VARCHAR(100),
    PermissionLevel TINYINT DEFAULT 1,
    FOREIGN KEY (StakeholderID) REFERENCES Stakeholder(StakeholderID) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 8. Nursery: Physical locations managed by Operators
CREATE TABLE Nursery (
    NurseryID INT AUTO_INCREMENT PRIMARY KEY,
    OperatorID INT NOT NULL,
    NurseryName VARCHAR(255) NOT NULL,
    Location VARCHAR(255),
    DistrictID INT NOT NULL,
    FOREIGN KEY (OperatorID) REFERENCES NurseryOperator(StakeholderID) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (DistrictID) REFERENCES District(DistrictID) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 9. SeedlingBatch: Inventory within a Nursery
CREATE TABLE SeedlingBatch (
    BatchID INT AUTO_INCREMENT PRIMARY KEY,
    NurseryID INT NOT NULL,
    Variety VARCHAR(100) NOT NULL,
    QuantityAvailable INT NOT NULL DEFAULT 0,
    CertifiedStatus ENUM('Yes', 'No') DEFAULT 'No',
    CertDate DATE,
    CONSTRAINT chk_certification CHECK (CertifiedStatus = 'No' OR CertDate IS NOT NULL),
    FOREIGN KEY (NurseryID) REFERENCES Nursery(NurseryID) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 10. Distribution: Records of farmers receiving seedlings
CREATE TABLE Distribution (
    DistributionID INT AUTO_INCREMENT PRIMARY KEY,
    BatchID INT NOT NULL,
    FarmerID INT NOT NULL,
    QuantityGiven INT NOT NULL,
    DistributionDate DATE NOT NULL,
    CONSTRAINT chk_distribution_month CHECK (MONTH(DistributionDate) BETWEEN 6 AND 8),
    CONSTRAINT chk_quantity_pos CHECK (QuantityGiven > 0),
    FOREIGN KEY (BatchID) REFERENCES SeedlingBatch(BatchID) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (FarmerID) REFERENCES Farmer(StakeholderID) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 11. Plot: Specific land parcels owned by Farmers
CREATE TABLE Plot (
    PlotID INT AUTO_INCREMENT PRIMARY KEY,
    FarmerID INT NOT NULL,
    GPSLat DECIMAL(10,7) NOT NULL,
    GPSLong DECIMAL(10,7) NOT NULL,
    AreaHectares DECIMAL(8,2) CHECK (AreaHectares > 0),
    SoilType VARCHAR(50),
    VillageID INT NOT NULL,
    FOREIGN KEY (FarmerID) REFERENCES Farmer(StakeholderID) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (VillageID) REFERENCES Village(VillageID) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 12. HarvestRecord: Records of coffee production
CREATE TABLE HarvestRecord (
    HarvestID INT AUTO_INCREMENT PRIMARY KEY,
    PlotID INT NOT NULL,
    SeasonYear YEAR NOT NULL,
    QuantityKg DECIMAL(10,2) CHECK (QuantityKg > 0),
    ProcessingMethod ENUM('Washed', 'Natural', 'Honey') NOT NULL,
    MoistureLevel DECIMAL(4,2) CHECK (MoistureLevel <= 12.5),
    HarvestDate DATE NOT NULL,
    ComplianceStatus ENUM('Compliant', 'Non-Compliant') DEFAULT 'Compliant',
    FOREIGN KEY (PlotID) REFERENCES Plot(PlotID) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 13. ExtensionProvider: Categories (Govt vs NGO)
CREATE TABLE ExtensionProvider (
    ProviderID INT AUTO_INCREMENT PRIMARY KEY,
    ProviderType ENUM('Government', 'NGO') NOT NULL
);

-- 14. GovernmentDept: Details for Govt providers
CREATE TABLE GovernmentDept (
    DeptID INT AUTO_INCREMENT PRIMARY KEY,
    ProviderID INT NOT NULL,
    DeptName VARCHAR(100) NOT NULL,
    MinistryBranch VARCHAR(100),
    FOREIGN KEY (ProviderID) REFERENCES ExtensionProvider(ProviderID) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 15. NGO: Details for NGO providers
CREATE TABLE NGO (
    NGOID INT AUTO_INCREMENT PRIMARY KEY,
    ProviderID INT NOT NULL,
    NGOName VARCHAR(100) NOT NULL,
    RegistrationNumber VARCHAR(50) UNIQUE,
    FOREIGN KEY (ProviderID) REFERENCES ExtensionProvider(ProviderID) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 16. AuditLog: System-wide tracking of changes
CREATE TABLE AuditLog (
    LogID INT AUTO_INCREMENT PRIMARY KEY,
    TableName VARCHAR(50),
    ActionType ENUM('INSERT', 'UPDATE', 'DELETE'),
    RecordID INT,
    ChangedBy VARCHAR(50) DEFAULT (CURRENT_USER()),
    ChangeTimestamp DATETIME DEFAULT (NOW()),
    Notes TEXT
);

-- ============================================================
-- SECTION 3: TRIGGERS
-- ============================================================
DELIMITER $$

-- T1: Validation before seedlings are given
CREATE TRIGGER trg_distribution_validate
BEFORE INSERT ON Distribution
FOR EACH ROW
BEGIN
    DECLARE v_certified VARCHAR(5);
    DECLARE v_acreage DECIMAL(8,2);
    DECLARE v_expiry DATE;

    -- a) Check certification
    SELECT CertifiedStatus INTO v_certified FROM SeedlingBatch WHERE BatchID = NEW.BatchID;
    IF v_certified = 'No' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Seedling batch is not certified.';
    END IF;

    -- b) Check quantity limit (1000 seedlings per acre)
    SELECT TotalAcreage INTO v_acreage FROM Farmer WHERE StakeholderID = NEW.FarmerID;
    IF NEW.QuantityGiven > (v_acreage * 1000) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Quantity exceeds allocation limit for farmer acreage.';
    END IF;

    -- c) Check License Expiry
    SELECT no.LicenseExpiry INTO v_expiry 
    FROM SeedlingBatch sb
    JOIN Nursery n ON sb.NurseryID = n.NurseryID
    JOIN NurseryOperator no ON n.OperatorID = no.StakeholderID
    WHERE sb.BatchID = NEW.BatchID;

    IF v_expiry < CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Nursery operator license has expired.';
    END IF;
END $$

-- T2: Reduce stock automatically
CREATE TRIGGER trg_distribution_reduce_stock
AFTER INSERT ON Distribution
FOR EACH ROW
BEGIN
    UPDATE SeedlingBatch 
    SET QuantityAvailable = QuantityAvailable - NEW.QuantityGiven
    WHERE BatchID = NEW.BatchID;
END $$

-- T3: Mark compliance automatically
CREATE TRIGGER trg_harvest_compliance_check
AFTER INSERT ON HarvestRecord
FOR EACH ROW
BEGIN
    IF NEW.MoistureLevel > 12.5 THEN
        UPDATE HarvestRecord SET ComplianceStatus = 'Non-Compliant' WHERE HarvestID = NEW.HarvestID;
    END IF;
END $$

-- Audit Triggers (T4 - T8)
CREATE TRIGGER trg_audit_farmer_insert AFTER INSERT ON Farmer FOR EACH ROW
BEGIN
    INSERT INTO AuditLog(TableName, ActionType, RecordID, Notes) VALUES ('Farmer', 'INSERT', NEW.StakeholderID, 'New farmer registered');
END $$

CREATE TRIGGER trg_audit_farmer_update AFTER UPDATE ON Farmer FOR EACH ROW
BEGIN
    INSERT INTO AuditLog(TableName, ActionType, RecordID, Notes) 
    VALUES ('Farmer', 'UPDATE', OLD.StakeholderID, CONCAT('Acreage changed from ', OLD.TotalAcreage, ' to ', NEW.TotalAcreage));
END $$

CREATE TRIGGER trg_audit_farmer_delete BEFORE DELETE ON Farmer FOR EACH ROW
BEGIN
    INSERT INTO AuditLog(TableName, ActionType, RecordID, Notes) VALUES ('Farmer', 'DELETE', OLD.StakeholderID, CONCAT('Farmer deleted: ', OLD.StakeholderID));
END $$

CREATE TRIGGER trg_audit_distribution_insert AFTER INSERT ON Distribution FOR EACH ROW
BEGIN
    INSERT INTO AuditLog(TableName, ActionType, RecordID, Notes) 
    VALUES ('Distribution', 'INSERT', NEW.DistributionID, CONCAT('Qty: ', NEW.QuantityGiven, ' to FarmerID: ', NEW.FarmerID));
END $$

CREATE TRIGGER trg_audit_harvest_insert AFTER INSERT ON HarvestRecord FOR EACH ROW
BEGIN
    INSERT INTO AuditLog(TableName, ActionType, RecordID, Notes) 
    VALUES ('HarvestRecord', 'INSERT', NEW.HarvestID, CONCAT(NEW.QuantityKg, 'kg, Moisture: ', NEW.MoistureLevel, '%'));
END $$

DELIMITER ;

-- ============================================================
-- SECTION 4: STORED PROCEDURES
-- ============================================================
DELIMITER $$

-- SP1: Register Farmer in a single transaction
CREATE PROCEDURE RegisterFarmer(
    IN p_NationalID VARCHAR(20), IN p_FullName VARCHAR(255), IN p_Gender VARCHAR(10), 
    IN p_Phone VARCHAR(20), IN p_HouseholdSize TINYINT, IN p_LiteracyLevel VARCHAR(20), IN p_TotalAcreage DECIMAL(8,2)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; END;
    START TRANSACTION;
        INSERT INTO Stakeholder(NationalID, FullName, Gender, Phone) VALUES (p_NationalID, p_FullName, p_Gender, p_Phone);
        INSERT INTO Farmer(StakeholderID, HouseholdSize, LiteracyLevel, TotalAcreage) VALUES (LAST_INSERT_ID(), p_HouseholdSize, p_LiteracyLevel, p_TotalAcreage);
    COMMIT;
    SELECT 'Farmer Registered Successfully' AS Message, LAST_INSERT_ID() AS NewID;
END $$

-- SP2: Summary of a Farmer's activities
CREATE PROCEDURE GetFarmerSummary(IN p_FarmerID INT)
BEGIN
    SELECT 
        s.FullName, 
        (SELECT COUNT(*) FROM Plot WHERE FarmerID = p_FarmerID) AS TotalPlots,
        SUM(hr.QuantityKg) AS TotalHarvestKg,
        SUM(d.QuantityGiven) AS TotalSeedlingsReceived
    FROM Stakeholder s
    JOIN Farmer f ON s.StakeholderID = f.StakeholderID
    LEFT JOIN Plot p ON f.StakeholderID = p.FarmerID
    LEFT JOIN HarvestRecord hr ON p.PlotID = hr.PlotID
    LEFT JOIN Distribution d ON f.StakeholderID = d.FarmerID
    WHERE s.StakeholderID = p_FarmerID
    GROUP BY s.StakeholderID;
END $$

-- SP3: Yield Report by District
CREATE PROCEDURE GetRegionalYieldReport(IN p_DistrictID INT)
BEGIN
    SELECT 
        d.DistrictName, 
        COUNT(DISTINCT f.StakeholderID) AS FarmerCount,
        COUNT(p.PlotID) AS PlotCount,
        SUM(hr.QuantityKg) AS TotalHarvest,
        AVG(hr.QuantityKg / p.AreaHectares) AS AvgYieldPerHectare
    FROM District d
    JOIN Village v ON d.DistrictID = v.DistrictID
    JOIN Plot p ON v.VillageID = p.VillageID
    JOIN Farmer f ON p.FarmerID = f.StakeholderID
    JOIN HarvestRecord hr ON p.PlotID = hr.PlotID
    WHERE d.DistrictID = p_DistrictID
    GROUP BY d.DistrictID;
END $$

-- SP4: Handle Seedling Distribution
CREATE PROCEDURE DistributeSeedlings(IN p_BatchID INT, IN p_FarmerID INT, IN p_Quantity INT, IN p_Date DATE)
BEGIN
    INSERT INTO Distribution(BatchID, FarmerID, QuantityGiven, DistributionDate) VALUES (p_BatchID, p_FarmerID, p_Quantity, p_Date);
    SELECT QuantityAvailable FROM SeedlingBatch WHERE BatchID = p_BatchID;
END $$

-- SP5: Nursery Stock Monitoring
CREATE PROCEDURE GetNurseryStockReport()
BEGIN
    SELECT 
        n.NurseryName, s.FullName AS OperatorName, sb.Variety, sb.QuantityAvailable, sb.CertifiedStatus,
        no.LicenseExpiry,
        CASE WHEN no.LicenseExpiry < CURDATE() THEN 'EXPIRED' ELSE 'Active' END AS LicenseStatus
    FROM Nursery n
    JOIN NurseryOperator no ON n.OperatorID = no.StakeholderID
    JOIN Stakeholder s ON no.StakeholderID = s.StakeholderID
    JOIN SeedlingBatch sb ON n.NurseryID = sb.NurseryID
    ORDER BY LicenseStatus, n.NurseryName;
END $$

-- SP6: Localized Farmer Lookup
CREATE PROCEDURE GetFarmersByDistrict(IN p_DistrictID INT)
BEGIN
    SELECT s.FullName, f.TotalAcreage, COUNT(p.PlotID) AS PlotCount, MAX(hr.HarvestDate) AS LastHarvest
    FROM District d
    JOIN Village v ON d.DistrictID = v.DistrictID
    JOIN Plot p ON v.VillageID = p.VillageID
    JOIN Farmer f ON p.FarmerID = f.StakeholderID
    JOIN Stakeholder s ON f.StakeholderID = s.StakeholderID
    LEFT JOIN HarvestRecord hr ON p.PlotID = hr.PlotID
    WHERE d.DistrictID = p_DistrictID
    GROUP BY s.StakeholderID;
END $$

-- SP7: Compliance Monitoring
CREATE PROCEDURE GetNonCompliantHarvests()
BEGIN
    SELECT s.FullName, hr.PlotID, hr.SeasonYear, hr.MoistureLevel, hr.QuantityKg
    FROM HarvestRecord hr
    JOIN Plot p ON hr.PlotID = p.PlotID
    JOIN Farmer f ON p.FarmerID = f.StakeholderID
    JOIN Stakeholder s ON f.StakeholderID = s.StakeholderID
    WHERE hr.ComplianceStatus = 'Non-Compliant'
    ORDER BY hr.HarvestDate DESC;
END $$

-- SP8: Annual Summary
CREATE PROCEDURE GenerateDistributionSummary(IN p_SeasonYear YEAR)
BEGIN
    SELECT 
        SUM(QuantityGiven) AS TotalDistributed,
        COUNT(DISTINCT FarmerID) AS FarmersServed,
        sb.Variety
    FROM Distribution d
    JOIN SeedlingBatch sb ON d.BatchID = sb.BatchID
    WHERE YEAR(DistributionDate) = p_SeasonYear
    GROUP BY sb.Variety;
END $$

DELIMITER ;

-- ============================================================
-- SECTION 5: VIEWS
-- ============================================================

-- V1: Admin Profile
CREATE OR REPLACE VIEW vw_admin_full_farmer_profile AS
SELECT s.*, f.HouseholdSize, f.LiteracyLevel, f.TotalAcreage, d.DistrictName
FROM Stakeholder s JOIN Farmer f ON s.StakeholderID = f.StakeholderID
JOIN Plot p ON f.StakeholderID = p.FarmerID JOIN Village v ON p.VillageID = v.VillageID
JOIN District d ON v.DistrictID = d.DistrictID;

-- V2: Extension Worker View (Public Info Only)
CREATE OR REPLACE VIEW vw_extension_worker_farmers AS
SELECT s.FullName, d.DistrictName, v.VillageName, f.TotalAcreage
FROM Stakeholder s JOIN Farmer f ON s.StakeholderID = f.StakeholderID
JOIN Plot p ON f.StakeholderID = p.FarmerID JOIN Village v ON p.VillageID = v.VillageID
JOIN District d ON v.DistrictID = d.DistrictID;

-- V3: Nursery Stock
CREATE OR REPLACE VIEW vw_nursery_operator_stock AS
SELECT n.OperatorID, sb.Variety, sb.QuantityAvailable, sb.CertifiedStatus, sb.CertDate
FROM Nursery n JOIN SeedlingBatch sb ON n.NurseryID = sb.NurseryID;

-- V4: Farmer Self-Service
CREATE OR REPLACE VIEW vw_farmer_self_view AS
SELECT s.FullName, s.StakeholderID, p.PlotID, hr.QuantityKg, d.QuantityGiven
FROM Stakeholder s LEFT JOIN Plot p ON s.StakeholderID = p.FarmerID
LEFT JOIN HarvestRecord hr ON p.PlotID = hr.PlotID
LEFT JOIN Distribution d ON s.StakeholderID = d.FarmerID;

-- V5-V8: Operational Reports
CREATE OR REPLACE VIEW vw_distribution_report AS SELECT d.*, s.FullName, sb.Variety FROM Distribution d JOIN Farmer f ON d.FarmerID = f.StakeholderID JOIN Stakeholder s ON f.StakeholderID = s.StakeholderID JOIN SeedlingBatch sb ON d.BatchID = sb.BatchID;
CREATE OR REPLACE VIEW vw_harvest_compliance_report AS SELECT hr.*, s.FullName, dst.DistrictName FROM HarvestRecord hr JOIN Plot p ON hr.PlotID = p.PlotID JOIN Farmer f ON p.FarmerID = f.StakeholderID JOIN Stakeholder s ON f.StakeholderID = s.StakeholderID JOIN Village v ON p.VillageID = v.VillageID JOIN District dst ON v.DistrictID = dst.DistrictID;
CREATE OR REPLACE VIEW vw_nursery_license_status AS SELECT n.NurseryName, s.FullName, no.LicenseNumber, no.LicenseExpiry FROM Nursery n JOIN NurseryOperator no ON n.OperatorID = no.StakeholderID JOIN Stakeholder s ON no.StakeholderID = s.StakeholderID;
CREATE OR REPLACE VIEW vw_audit_log_summary AS SELECT * FROM AuditLog ORDER BY ChangeTimestamp DESC;

-- ============================================================
-- SECTION 6: USER ROLES AND PRIVILEGES
-- ============================================================

-- Create Roles
CREATE ROLE IF NOT EXISTS role_admin, role_extension_worker, role_nursery_operator, role_farmer;

-- Assign Privileges
GRANT ALL PRIVILEGES ON agri_coffee_db.* TO role_admin;
GRANT SELECT ON vw_extension_worker_farmers TO role_extension_worker;
GRANT SELECT ON vw_harvest_compliance_report TO role_extension_worker;
GRANT SELECT ON vw_distribution_report TO role_extension_worker;
GRANT SELECT, INSERT, UPDATE ON SeedlingBatch TO role_nursery_operator;
GRANT SELECT ON vw_nursery_operator_stock TO role_nursery_operator;
GRANT SELECT ON vw_nursery_license_status TO role_nursery_operator;
GRANT SELECT ON vw_farmer_self_view TO role_farmer;

-- Create Users (Example Passwords Used)
CREATE USER IF NOT EXISTS 'admin_user'@'localhost' IDENTIFIED BY 'Admin@2026';
CREATE USER IF NOT EXISTS 'worker_user'@'localhost' IDENTIFIED BY 'Worker@2026';
CREATE USER IF NOT EXISTS 'nursery_user'@'localhost' IDENTIFIED BY 'Nursery@2026';
CREATE USER IF NOT EXISTS 'farmer_user'@'localhost' IDENTIFIED BY 'Farmer@2026';

-- Grant Roles
GRANT role_admin TO 'admin_user'@'localhost';
GRANT role_extension_worker TO 'worker_user'@'localhost';
GRANT role_nursery_operator TO 'nursery_user'@'localhost';
GRANT role_farmer TO 'farmer_user'@'localhost';

-- Set Roles as Default
SET DEFAULT ROLE ALL TO 'admin_user'@'localhost', 'worker_user'@'localhost', 'nursery_user'@'localhost', 'farmer_user'@'localhost';

-- ============================================================
-- SECTION 7: SAMPLE DATA
-- ============================================================

INSERT INTO District (DistrictName) VALUES ('Masaka'), ('Mbarara'), ('Kampala');
INSERT INTO Village (VillageName, ParishName, DistrictID) VALUES ('Kirimya', 'K Parish', 1), ('Nyaka', 'N Parish', 1), ('Banda', 'B Parish', 3);

-- Create Stakeholders for various roles
INSERT INTO Stakeholder (NationalID, FullName, Gender, Phone) VALUES 
('CM001', 'Opol Charis', 'Male', '0700000001'), 
('CM002', 'Extension Jane', 'Female', '0700000002'), 
('CM003', 'Operator Bob', 'Male', '0700000003'),
('CM004', 'Farmer John', 'Male', '0700000004'),
('CM005', 'Admin Sarah', 'Female', '0700000005');

INSERT INTO Farmer (StakeholderID, HouseholdSize, LiteracyLevel, TotalAcreage) VALUES (1, 4, 'Tertiary', 5.5), (4, 6, 'Primary', 2.0);
INSERT INTO ExtensionWorker (StakeholderID, Qualification, Extension_Rank, DistrictID) VALUES (2, 'BSc Agriculture', 'Senior', 1);
INSERT INTO NurseryOperator (StakeholderID, LicenseNumber, NurseryCapacity, LicenseExpiry) VALUES (3, 'LIC-12345', 5000, '2027-01-01');
INSERT INTO MinistryAdmin (StakeholderID, Department) VALUES (5, 'Operations');

INSERT INTO Nursery (OperatorID, NurseryName, Location, DistrictID) VALUES (3, 'Charis Green Nursery', 'Masaka Road', 1);
INSERT INTO SeedlingBatch (NurseryID, Variety, QuantityAvailable, CertifiedStatus, CertDate) VALUES (1, 'Arabica', 2000, 'Yes', '2026-01-01'), (1, 'Robusta', 1000, 'No', NULL);

-- Successful Distribution (Month 7 = July)
INSERT INTO Distribution (BatchID, FarmerID, QuantityGiven, DistributionDate) VALUES (1, 1, 500, '2026-07-15');

INSERT INTO Plot (FarmerID, GPSLat, GPSLong, AreaHectares, SoilType, VillageID) VALUES (1, 0.3476, 32.5825, 2.0, 'Loamy', 1);
INSERT INTO HarvestRecord (PlotID, SeasonYear, QuantityKg, ProcessingMethod, MoistureLevel, HarvestDate) VALUES (1, 2026, 120.5, 'Washed', 11.2, '2026-03-20');

-- ============================================================
-- SECTION 8: BACKUP STRATEGY
-- ============================================================
-- BACKUP COMMAND: 
-- mysqldump -u root -p agri_coffee_db > backup_2026_04_02.sql

-- RESTORE COMMAND:
-- mysql -u root -p agri_coffee_db < backup_2026_04_02.sql

-- SCHEDULE: 
-- Daily automated dumps are recommended. 
-- For structure only: mysqldump -u root -p --no-data agri_coffee_db > schema.sql
-- ============================================================