-- Active: 1775134706375@@127.0.0.1@3306@agri_coffee_db
DROP DATABASE IF EXISTS agri_coffee_db;

CREATE DATABASE agri_coffee_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE agri_coffee_db;

DROP TABLE IF EXISTS District;

CREATE TABLE District (
    DistrictID   INT          AUTO_INCREMENT PRIMARY KEY,
    DistrictName VARCHAR(100) NOT NULL UNIQUE
);

DROP TABLE IF EXISTS Village;

CREATE TABLE Village (
    VillageID   INT          AUTO_INCREMENT PRIMARY KEY,
    VillageName VARCHAR(100) NOT NULL,
    ParishName  VARCHAR(100),
    DistrictID  INT          NOT NULL,
    CONSTRAINT fk_village_district
        FOREIGN KEY (DistrictID) REFERENCES District(DistrictID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

DROP TABLE IF EXISTS Stakeholder;

CREATE TABLE Stakeholder (
    StakeholderID  INT          AUTO_INCREMENT PRIMARY KEY,
    NationalID     VARCHAR(20)  NOT NULL UNIQUE,
    FullName       VARCHAR(150) NOT NULL,
    Gender         ENUM('Male','Female','Other') NOT NULL,
    Phone          VARCHAR(20)  NOT NULL,
    RegisteredDate DATE         NOT NULL DEFAULT (CURDATE())
);

DROP TABLE IF EXISTS Farmer;

CREATE TABLE Farmer (
    StakeholderID  INT             PRIMARY KEY,
    HouseholdSize  TINYINT,
    LiteracyLevel  ENUM('None','Primary','Secondary','Tertiary'),
    TotalAcreage   DECIMAL(8,2)   NOT NULL,
    CONSTRAINT chk_farmer_acreage CHECK (TotalAcreage > 0),
    CONSTRAINT fk_farmer_stakeholder
        FOREIGN KEY (StakeholderID) REFERENCES Stakeholder(StakeholderID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

DROP TABLE IF EXISTS ExtensionProvider;

CREATE TABLE ExtensionProvider (
    ProviderID   INT AUTO_INCREMENT PRIMARY KEY,
    ProviderType ENUM('Government','NGO') NOT NULL
);

DROP TABLE IF EXISTS ExtensionWorker;

CREATE TABLE ExtensionWorker (
    StakeholderID         INT          PRIMARY KEY,
    Qualification         VARCHAR(100),  
    Extension_worker_Rank VARCHAR(50),  
    DistrictID            INT          NOT NULL,
    ProviderID            INT          NOT NULL, 

    CONSTRAINT fk_worker_stakeholder
        FOREIGN KEY (StakeholderID) REFERENCES Stakeholder(StakeholderID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_worker_district
        FOREIGN KEY (DistrictID) REFERENCES District(DistrictID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_worker_provider
        FOREIGN KEY (ProviderID) REFERENCES ExtensionProvider(ProviderID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

DROP TABLE IF EXISTS NurseryOperator;

CREATE TABLE NurseryOperator (
    StakeholderID   INT         PRIMARY KEY,
    LicenseNumber   VARCHAR(30) NOT NULL UNIQUE,
    NurseryCapacity INT,
    LicenseExpiry   DATE        NOT NULL,

    CONSTRAINT fk_nursop_stakeholder
        FOREIGN KEY (StakeholderID) REFERENCES Stakeholder(StakeholderID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

DROP TABLE IF EXISTS MinistryAdmin;

CREATE TABLE MinistryAdmin (
    StakeholderID   INT         PRIMARY KEY,
    Department      VARCHAR(100),
    PermissionLevel TINYINT     NOT NULL DEFAULT 1,

    CONSTRAINT fk_admin_stakeholder
        FOREIGN KEY (StakeholderID) REFERENCES Stakeholder(StakeholderID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

DROP TABLE IF EXISTS GovernmentDept;

CREATE TABLE GovernmentDept (
    DeptID         INT          AUTO_INCREMENT PRIMARY KEY,
    ProviderID     INT          NOT NULL,
    DeptName       VARCHAR(150) NOT NULL,
    MinistryBranch VARCHAR(100),

    CONSTRAINT fk_govtdept_provider
        FOREIGN KEY (ProviderID) REFERENCES ExtensionProvider(ProviderID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

DROP TABLE IF EXISTS NGO;

CREATE TABLE NGO (
    NGOID              INT          AUTO_INCREMENT PRIMARY KEY,
    ProviderID         INT          NOT NULL,
    NGOName            VARCHAR(150) NOT NULL,
    RegistrationNumber VARCHAR(50)  UNIQUE,

    CONSTRAINT fk_ngo_provider
        FOREIGN KEY (ProviderID) REFERENCES ExtensionProvider(ProviderID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

DROP TABLE IF EXISTS Nursery;

CREATE TABLE Nursery (
    NurseryID   INT          AUTO_INCREMENT PRIMARY KEY,
    OperatorID  INT          NOT NULL,
    NurseryName VARCHAR(150) NOT NULL,
    Location    VARCHAR(255),
    DistrictID  INT          NOT NULL,

    CONSTRAINT fk_nursery_operator
        FOREIGN KEY (OperatorID) REFERENCES NurseryOperator(StakeholderID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_nursery_district
        FOREIGN KEY (DistrictID) REFERENCES District(DistrictID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

DROP TABLE IF EXISTS SeedlingBatch;

CREATE TABLE SeedlingBatch (
    BatchID           INT          AUTO_INCREMENT PRIMARY KEY,
    NurseryID         INT          NOT NULL,
    Variety           VARCHAR(100) NOT NULL,
    QuantityAvailable INT          NOT NULL DEFAULT 0,
    CertifiedStatus   ENUM('Yes','No') NOT NULL DEFAULT 'No',
    CertDate          DATE,

    CONSTRAINT chk_certdate
        CHECK (CertifiedStatus = 'No' OR CertDate IS NOT NULL),

    CONSTRAINT fk_batch_nursery
        FOREIGN KEY (NurseryID) REFERENCES Nursery(NurseryID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

DROP TABLE IF EXISTS Plot;

CREATE TABLE Plot (
    PlotID        INT             AUTO_INCREMENT PRIMARY KEY,
    FarmerID      INT             NOT NULL,
    GPSLat        DECIMAL(10,7)   NOT NULL,
    GPSLong       DECIMAL(10,7)   NOT NULL,
    AreaHectares  DECIMAL(8,2),
    CONSTRAINT chk_plot_area CHECK (AreaHectares > 0),
    SoilType      VARCHAR(50),
    VillageID     INT,

    CONSTRAINT fk_plot_farmer
        FOREIGN KEY (FarmerID) REFERENCES Farmer(StakeholderID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_plot_village
        FOREIGN KEY (VillageID) REFERENCES Village(VillageID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

DROP TABLE IF EXISTS HarvestRecord;

CREATE TABLE HarvestRecord (
    HarvestID         INT             AUTO_INCREMENT PRIMARY KEY,
    PlotID            INT             NOT NULL,
    SeasonYear        YEAR            NOT NULL,
    QuantityKg        DECIMAL(10,2),
    CONSTRAINT chk_harvest_qty CHECK (QuantityKg > 0),
    ProcessingMethod  ENUM('Washed','Natural','Honey') NOT NULL,
    MoistureLevel     DECIMAL(4,2),
    CONSTRAINT chk_moisture CHECK (MoistureLevel <= 12.5),
    HarvestDate       DATE            NOT NULL,

    ComplianceStatus  ENUM('Compliant','Non-Compliant') NOT NULL DEFAULT 'Compliant',

    CONSTRAINT fk_harvest_plot
        FOREIGN KEY (PlotID) REFERENCES Plot(PlotID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

DROP TABLE IF EXISTS Distribution;

CREATE TABLE Distribution (
    DistributionID   INT  AUTO_INCREMENT PRIMARY KEY,
    BatchID          INT  NOT NULL,
    FarmerID         INT  NOT NULL,
    QuantityGiven    INT  NOT NULL,
    DistributionDate DATE NOT NULL,

    WorkerID         INT,                       
    PlotID           INT,                       
    Notes            TEXT,

    CONSTRAINT chk_dist_qty CHECK (QuantityGiven > 0),

    CONSTRAINT chk_dist_season
        CHECK (MONTH(DistributionDate) BETWEEN 6 AND 8),

    CONSTRAINT fk_dist_batch
        FOREIGN KEY (BatchID)   REFERENCES SeedlingBatch(BatchID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_dist_farmer
        FOREIGN KEY (FarmerID)  REFERENCES Farmer(StakeholderID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_dist_worker
        FOREIGN KEY (WorkerID)  REFERENCES ExtensionWorker(StakeholderID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_dist_plot
        FOREIGN KEY (PlotID)    REFERENCES Plot(PlotID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

DROP TABLE IF EXISTS AuditLog;

CREATE TABLE AuditLog (
    LogID           INT          AUTO_INCREMENT PRIMARY KEY,
    TableName       VARCHAR(50),
    ActionType      ENUM('INSERT','UPDATE','DELETE'),
    RecordID        INT,
    ChangedBy       VARCHAR(100) DEFAULT (CURRENT_USER()),
    ChangeTimestamp DATETIME     DEFAULT (NOW()),
    Notes           TEXT
);

DROP TABLE IF EXISTS Input;

CREATE TABLE Input (
    InputID       INT          AUTO_INCREMENT PRIMARY KEY,

    InputName     VARCHAR(150) NOT NULL,

    Category      ENUM('Fertiliser','Insecticide','Fungicide','Seedling','Machinery','Other') NOT NULL,

    UnitOfMeasure VARCHAR(30)  NOT NULL,

    Description   TEXT,

    IsRestricted  ENUM('Yes','No') NOT NULL DEFAULT 'No'
);

DROP TABLE IF EXISTS InputBatch;

CREATE TABLE InputBatch (
    BatchID           INT             AUTO_INCREMENT PRIMARY KEY,

    InputID           INT             NOT NULL,

    DistrictID        INT             NOT NULL,

    QuantityAvailable DECIMAL(10,2)   NOT NULL DEFAULT 0,
    CONSTRAINT chk_inputbatch_qty CHECK (QuantityAvailable >= 0),

    DateReceived      DATE            NOT NULL,

    ExpiryDate        DATE            NOT NULL,

    ApprovalStatus    ENUM('Approved','Pending','Rejected') NOT NULL DEFAULT 'Pending',

    SupplierName      VARCHAR(150),

    CONSTRAINT fk_inputbatch_input
        FOREIGN KEY (InputID)    REFERENCES Input(InputID)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_inputbatch_district
        FOREIGN KEY (DistrictID) REFERENCES District(DistrictID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

DROP TABLE IF EXISTS MachineryInventory;

CREATE TABLE MachineryInventory (
    MachineID           INT          AUTO_INCREMENT PRIMARY KEY,

    InputID             INT          NOT NULL,

    SerialNumber        VARCHAR(100) NOT NULL UNIQUE,

    Condition_of_machinery           ENUM('New','Good','Fair','Needs Repair') NOT NULL DEFAULT 'Good',
    AcquisitionDate     DATE         NOT NULL,

    DistrictID          INT          NOT NULL,
    AvailabilityStatus  ENUM('Available','In Use','Under Repair') NOT NULL DEFAULT 'Available',

    SupplierName        VARCHAR(150),

    CONSTRAINT fk_machinery_input
        FOREIGN KEY (InputID)    REFERENCES Input(InputID)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_machinery_district
        FOREIGN KEY (DistrictID) REFERENCES District(DistrictID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

DROP TABLE IF EXISTS InputDistribution;

CREATE TABLE InputDistribution (
    InputDistributionID INT             AUTO_INCREMENT PRIMARY KEY,

    BatchID             INT             NOT NULL,

    FarmerID            INT             NOT NULL,

    QuantityGiven       DECIMAL(10,2)   NOT NULL,
    CONSTRAINT chk_inputdist_qty CHECK (QuantityGiven > 0),

    DistributionDate    DATE            NOT NULL,

    PlotID              INT,

    WorkerID            INT,

    Notes               TEXT,

    CONSTRAINT fk_inputdist_batch
        FOREIGN KEY (BatchID)   REFERENCES InputBatch(BatchID)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_inputdist_farmer
        FOREIGN KEY (FarmerID)  REFERENCES Farmer(StakeholderID)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_inputdist_plot
        FOREIGN KEY (PlotID)    REFERENCES Plot(PlotID)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_inputdist_worker
        FOREIGN KEY (WorkerID)  REFERENCES ExtensionWorker(StakeholderID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

DELIMITER $$

DROP TRIGGER IF EXISTS trg_distribution_validate $$

CREATE TRIGGER trg_distribution_validate
BEFORE INSERT ON Distribution
FOR EACH ROW
BEGIN
    DECLARE v_certified      ENUM('Yes','No');
    DECLARE v_acreage        DECIMAL(8,2);
    DECLARE v_license_expiry DATE;

    SELECT CertifiedStatus
    INTO   v_certified
    FROM   SeedlingBatch
    WHERE  BatchID = NEW.BatchID;

    IF v_certified != 'Yes' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot distribute: this seedling batch is not certified.';
    END IF;

    SELECT TotalAcreage
    INTO   v_acreage
    FROM   Farmer
    WHERE  StakeholderID = NEW.FarmerID;

    IF NEW.QuantityGiven > (v_acreage * 1000) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot distribute: quantity exceeds the 1000-per-acre limit for this farmer.';
    END IF;

    SELECT no.LicenseExpiry
    INTO   v_license_expiry
    FROM   SeedlingBatch   sb
    JOIN   Nursery         n  ON n.NurseryID      = sb.NurseryID
    JOIN   NurseryOperator no ON no.StakeholderID = n.OperatorID
    WHERE  sb.BatchID = NEW.BatchID;

    IF v_license_expiry < CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot distribute: the nursery operator license has expired.';
    END IF;

END $$

DROP TRIGGER IF EXISTS trg_distribution_reduce_stock $$

CREATE TRIGGER trg_distribution_reduce_stock
AFTER INSERT ON Distribution
FOR EACH ROW
BEGIN

    UPDATE SeedlingBatch
    SET    QuantityAvailable = QuantityAvailable - NEW.QuantityGiven
    WHERE  BatchID = NEW.BatchID;
END $$

DROP TRIGGER IF EXISTS trg_harvest_compliance_check $$

CREATE TRIGGER trg_harvest_compliance_check
AFTER INSERT ON HarvestRecord
FOR EACH ROW
BEGIN
    IF NEW.MoistureLevel > 12.5 THEN
        UPDATE HarvestRecord
        SET    ComplianceStatus = 'Non-Compliant'
        WHERE  HarvestID = NEW.HarvestID;
    END IF;
END $$

DROP TRIGGER IF EXISTS trg_audit_farmer_insert $$

CREATE TRIGGER trg_audit_farmer_insert
AFTER INSERT ON Farmer
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (TableName, ActionType, RecordID, Notes)
    VALUES ('Farmer', 'INSERT', NEW.StakeholderID, 'New farmer registered.');
END $$

DROP TRIGGER IF EXISTS trg_audit_farmer_update $$

CREATE TRIGGER trg_audit_farmer_update
AFTER UPDATE ON Farmer
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (TableName, ActionType, RecordID, Notes)
    VALUES (
        'Farmer',
        'UPDATE',
        OLD.StakeholderID,
        CONCAT('Acreage changed from ', OLD.TotalAcreage, ' to ', NEW.TotalAcreage,
               '. Literacy changed from ', OLD.LiteracyLevel, ' to ', NEW.LiteracyLevel, '.')
    );
END $$

DROP TRIGGER IF EXISTS trg_audit_farmer_delete $$

CREATE TRIGGER trg_audit_farmer_delete
BEFORE DELETE ON Farmer
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (TableName, ActionType, RecordID, Notes)
    VALUES (
        'Farmer',
        'DELETE',
        OLD.StakeholderID,
        CONCAT('Farmer record deleted. Acreage was: ', OLD.TotalAcreage, ' acres.')
    );
END $$

DROP TRIGGER IF EXISTS trg_audit_distribution_insert $$

CREATE TRIGGER trg_audit_distribution_insert
AFTER INSERT ON Distribution
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (TableName, ActionType, RecordID, Notes)
    VALUES (
        'Distribution',
        'INSERT',
        NEW.DistributionID,
        CONCAT(NEW.QuantityGiven, ' seedlings distributed to FarmerID ', NEW.FarmerID,
               ' from BatchID ', NEW.BatchID,
               ' on ', NEW.DistributionDate,
               '. WorkerID: ', COALESCE(NEW.WorkerID, 'N/A'), '.')
    );
END $$

DROP TRIGGER IF EXISTS trg_audit_harvest_insert $$

CREATE TRIGGER trg_audit_harvest_insert
AFTER INSERT ON HarvestRecord
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (TableName, ActionType, RecordID, Notes)
    VALUES (
        'HarvestRecord',
        'INSERT',
        NEW.HarvestID,
        CONCAT(NEW.QuantityKg, ' kg harvested. Moisture: ', NEW.MoistureLevel,
               '%. Method: ', NEW.ProcessingMethod, '. Status: ', NEW.ComplianceStatus, '.')
    );
END $$

DROP TRIGGER IF EXISTS trg_inputdist_validate $$

CREATE TRIGGER trg_inputdist_validate
BEFORE INSERT ON InputDistribution
FOR EACH ROW
BEGIN
    DECLARE v_approval   ENUM('Approved','Pending','Rejected');
    DECLARE v_expiry     DATE;
    DECLARE v_available  DECIMAL(10,2);
    DECLARE v_restricted ENUM('Yes','No');

    SELECT ib.ApprovalStatus, ib.ExpiryDate, ib.QuantityAvailable,
           i.IsRestricted
    INTO   v_approval, v_expiry, v_available, v_restricted
    FROM   InputBatch ib
    JOIN   Input      i ON i.InputID = ib.InputID
    WHERE  ib.BatchID = NEW.BatchID;

    IF v_restricted = 'Yes' AND v_approval != 'Approved' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot distribute: this restricted input batch has not been approved.';
    END IF;

    IF v_expiry < CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot distribute: this input batch has expired.';
    END IF;

    IF NEW.QuantityGiven > v_available THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot distribute: quantity requested exceeds available stock.';
    END IF;

END $$

DROP TRIGGER IF EXISTS trg_inputdist_reduce_stock $$

CREATE TRIGGER trg_inputdist_reduce_stock
AFTER INSERT ON InputDistribution
FOR EACH ROW
BEGIN
    UPDATE InputBatch
    SET    QuantityAvailable = QuantityAvailable - NEW.QuantityGiven
    WHERE  BatchID = NEW.BatchID;
END $$

DROP TRIGGER IF EXISTS trg_audit_inputdist_insert $$

CREATE TRIGGER trg_audit_inputdist_insert
AFTER INSERT ON InputDistribution
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (TableName, ActionType, RecordID, Notes)
    VALUES (
        'InputDistribution',
        'INSERT',
        NEW.InputDistributionID,
        CONCAT(NEW.QuantityGiven, ' units distributed to FarmerID ',
               NEW.FarmerID, ' from InputBatchID ', NEW.BatchID,
               ' on ', NEW.DistributionDate,
               '. WorkerID: ', COALESCE(NEW.WorkerID, 'N/A'), '.')
    );
END $$

DROP TRIGGER IF EXISTS trg_audit_inputbatch_approval $$

CREATE TRIGGER trg_audit_inputbatch_approval
AFTER UPDATE ON InputBatch
FOR EACH ROW
BEGIN
    IF OLD.ApprovalStatus != NEW.ApprovalStatus THEN
        INSERT INTO AuditLog (TableName, ActionType, RecordID, Notes)
        VALUES (
            'InputBatch',
            'UPDATE',
            NEW.BatchID,
            CONCAT('Approval status changed from "', OLD.ApprovalStatus,
                   '" to "', NEW.ApprovalStatus, '".')
        );
    END IF;
END $$

DELIMITER ;

DELIMITER $$

DROP PROCEDURE IF EXISTS RegisterFarmer $$

CREATE PROCEDURE RegisterFarmer(
    IN p_NationalID    VARCHAR(20),
    IN p_FullName      VARCHAR(150),
    IN p_Gender        ENUM('Male','Female','Other'),
    IN p_Phone         VARCHAR(20),
    IN p_HouseholdSize TINYINT,
    IN p_LiteracyLevel ENUM('None','Primary','Secondary','Tertiary'),
    IN p_TotalAcreage  DECIMAL(8,2)
)
BEGIN
    DECLARE v_new_id INT;

    START TRANSACTION;

    INSERT INTO Stakeholder (NationalID, FullName, Gender, Phone)
    VALUES (p_NationalID, p_FullName, p_Gender, p_Phone);

    SET v_new_id = LAST_INSERT_ID();

    INSERT INTO Farmer (StakeholderID, HouseholdSize, LiteracyLevel, TotalAcreage)
    VALUES (v_new_id, p_HouseholdSize, p_LiteracyLevel, p_TotalAcreage);

    COMMIT;

    SELECT CONCAT('SUCCESS: Farmer registered with StakeholderID = ', v_new_id) AS Result;
END $$

DROP PROCEDURE IF EXISTS GetFarmerSummary $$

CREATE PROCEDURE GetFarmerSummary(
    IN p_FarmerID INT
)
BEGIN
    SELECT
        s.FullName                              AS FarmerName,
        COUNT(DISTINCT p.PlotID)                AS TotalPlots,
        COALESCE(SUM(h.QuantityKg), 0)          AS TotalHarvestKg,
        COALESCE(SUM(d.QuantityGiven), 0)       AS TotalSeedlingsReceived,
        SUM(CASE WHEN h.ComplianceStatus = 'Non-Compliant' THEN 1 ELSE 0 END)
                                                AS NonCompliantHarvests

    FROM       Stakeholder  s
    JOIN       Farmer       f  ON f.StakeholderID = s.StakeholderID
    LEFT JOIN  Plot         p  ON p.FarmerID       = f.StakeholderID
    LEFT JOIN  HarvestRecord h ON h.PlotID         = p.PlotID
    LEFT JOIN  Distribution  d ON d.FarmerID       = f.StakeholderID

    WHERE f.StakeholderID = p_FarmerID
    GROUP BY s.FullName;
END $$

DROP PROCEDURE IF EXISTS GetRegionalYieldReport $$

CREATE PROCEDURE GetRegionalYieldReport(
    IN p_DistrictID INT
)
BEGIN
    SELECT
        d.DistrictName,
        COUNT(DISTINCT f.StakeholderID)         AS TotalFarmers,
        COUNT(DISTINCT p.PlotID)                AS TotalPlots,
        COALESCE(SUM(h.QuantityKg), 0)          AS TotalHarvestKg,
        ROUND(AVG(h.QuantityKg / NULLIF(p.AreaHectares, 0)), 2) AS AvgYieldPerHectare

    FROM  District    d
    JOIN  Village     v  ON v.DistrictID    = d.DistrictID
    JOIN  Plot        p  ON p.VillageID     = v.VillageID
    JOIN  Farmer      f  ON f.StakeholderID = p.FarmerID
    LEFT JOIN HarvestRecord h ON h.PlotID   = p.PlotID

    WHERE d.DistrictID = p_DistrictID
    GROUP BY d.DistrictName;
END $$

DROP PROCEDURE IF EXISTS DistributeSeedlings $$

CREATE PROCEDURE DistributeSeedlings(
    IN p_BatchID  INT,
    IN p_FarmerID INT,
    IN p_Quantity INT,
    IN p_Date     DATE,
    IN p_WorkerID INT,
    IN p_PlotID   INT
)
BEGIN
    DECLARE v_certified ENUM('Yes','No');
    DECLARE v_stock     INT;
    DECLARE v_remaining INT;

    IF NOT EXISTS (SELECT 1 FROM Farmer WHERE StakeholderID = p_FarmerID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Farmer ID does not exist.';
    END IF;

    SELECT CertifiedStatus, QuantityAvailable
    INTO   v_certified, v_stock
    FROM   SeedlingBatch
    WHERE  BatchID = p_BatchID;

    IF v_certified != 'Yes' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Batch is not certified for distribution.';
    END IF;

    IF MONTH(p_Date) NOT BETWEEN 6 AND 8 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Distributions are only allowed between June and August.';
    END IF;

    INSERT INTO Distribution (BatchID, FarmerID, QuantityGiven, DistributionDate, WorkerID, PlotID)
    VALUES (p_BatchID, p_FarmerID, p_Quantity, p_Date, p_WorkerID, p_PlotID);

    SELECT QuantityAvailable INTO v_remaining
    FROM   SeedlingBatch WHERE BatchID = p_BatchID;

    SELECT CONCAT('SUCCESS: ', p_Quantity, ' seedlings distributed.',
                  ' Remaining stock for BatchID ', p_BatchID, ': ', v_remaining) AS Result;
END $$

DROP PROCEDURE IF EXISTS GetNurseryStockReport $$

CREATE PROCEDURE GetNurseryStockReport()
BEGIN
    SELECT
        n.NurseryName,
        s.FullName                              AS OperatorName,
        sb.Variety,
        sb.QuantityAvailable,
        sb.CertifiedStatus,
        no.LicenseExpiry,
        CASE
            WHEN no.LicenseExpiry < CURDATE() THEN 'EXPIRED'
            ELSE 'Active'
        END                                     AS LicenseStatus

    FROM  Nursery          n
    JOIN  NurseryOperator  no ON no.StakeholderID = n.OperatorID
    JOIN  Stakeholder      s  ON s.StakeholderID  = no.StakeholderID
    JOIN  SeedlingBatch    sb ON sb.NurseryID     = n.NurseryID

    ORDER BY LicenseStatus DESC, n.NurseryName ASC;
END $$

DROP PROCEDURE IF EXISTS GetFarmersByDistrict $$

CREATE PROCEDURE GetFarmersByDistrict(
    IN p_DistrictID INT
)
BEGIN
    SELECT
        s.FullName                              AS FarmerName,
        f.TotalAcreage,
        COUNT(DISTINCT p.PlotID)                AS NumberOfPlots,
        MAX(h.HarvestDate)                      AS LastHarvestDate

    FROM  District    d
    JOIN  Village     v  ON v.DistrictID    = d.DistrictID
    JOIN  Plot        p  ON p.VillageID     = v.VillageID
    JOIN  Farmer      f  ON f.StakeholderID = p.FarmerID
    JOIN  Stakeholder s  ON s.StakeholderID = f.StakeholderID
    LEFT JOIN HarvestRecord h ON h.PlotID   = p.PlotID

    WHERE d.DistrictID = p_DistrictID
    GROUP BY s.FullName, f.TotalAcreage
    ORDER BY s.FullName;
END $$

DROP PROCEDURE IF EXISTS GetNonCompliantHarvests $$

CREATE PROCEDURE GetNonCompliantHarvests()
BEGIN
    SELECT
        h.HarvestID,
        s.FullName          AS FarmerName,
        h.PlotID,
        h.SeasonYear,
        h.MoistureLevel,
        h.QuantityKg,
        h.HarvestDate,
        h.ComplianceStatus

    FROM  HarvestRecord  h
    JOIN  Plot           p ON p.PlotID        = h.PlotID
    JOIN  Farmer         f ON f.StakeholderID = p.FarmerID
    JOIN  Stakeholder    s ON s.StakeholderID = f.StakeholderID

    WHERE h.ComplianceStatus = 'Non-Compliant'
    ORDER BY h.HarvestDate DESC;
END $$

DROP PROCEDURE IF EXISTS GenerateDistributionSummary $$

CREATE PROCEDURE GenerateDistributionSummary(
    IN p_SeasonYear YEAR
)
BEGIN
    SELECT
        COUNT(DISTINCT d.FarmerID)  AS FarmersServed,
        SUM(d.QuantityGiven)        AS TotalSeedlingsDistributed,
        MIN(d.DistributionDate)     AS FirstDistribution,
        MAX(d.DistributionDate)     AS LastDistribution

    FROM  Distribution d
    WHERE YEAR(d.DistributionDate) = p_SeasonYear;

    SELECT
        sb.Variety,
        SUM(d.QuantityGiven)        AS QuantityByVariety

    FROM  Distribution  d
    JOIN  SeedlingBatch sb ON sb.BatchID = d.BatchID
    WHERE YEAR(d.DistributionDate) = p_SeasonYear
    GROUP BY sb.Variety
    ORDER BY QuantityByVariety DESC;

    SELECT
        dist.DistrictName,
        SUM(d.QuantityGiven)        AS TotalReceived

    FROM  Distribution d
    JOIN  Farmer       f    ON f.StakeholderID = d.FarmerID
    JOIN  Plot         p    ON p.FarmerID      = f.StakeholderID
    JOIN  Village      v    ON v.VillageID     = p.VillageID
    JOIN  District     dist ON dist.DistrictID = v.DistrictID

    WHERE YEAR(d.DistributionDate) = p_SeasonYear
    GROUP BY dist.DistrictName
    ORDER BY TotalReceived DESC
    LIMIT 5;
END $$

DROP PROCEDURE IF EXISTS GetInputStockReport $$

CREATE PROCEDURE GetInputStockReport()
BEGIN
    SELECT
        i.InputName,
        i.Category,
        i.UnitOfMeasure,
        i.IsRestricted,
        ib.BatchID,
        ib.SupplierName,
        ib.QuantityAvailable,
        ib.DateReceived,
        ib.ExpiryDate,
        ib.ApprovalStatus,
        d.DistrictName,
        CASE
            WHEN ib.ExpiryDate < CURDATE()           THEN 'EXPIRED'
            WHEN ib.ApprovalStatus = 'Rejected'      THEN 'REJECTED'
            WHEN ib.ApprovalStatus = 'Pending'
             AND i.IsRestricted   = 'Yes'            THEN 'AWAITING APPROVAL'
            WHEN ib.QuantityAvailable = 0            THEN 'OUT OF STOCK'
            ELSE 'Available'
        END AS BatchStatus

    FROM  InputBatch ib
    JOIN  Input      i  ON i.InputID    = ib.InputID
    JOIN  District   d  ON d.DistrictID = ib.DistrictID

    ORDER BY BatchStatus ASC, i.Category, i.InputName;
END $$

DROP PROCEDURE IF EXISTS GetFarmerInputHistory $$

CREATE PROCEDURE GetFarmerInputHistory(
    IN p_FarmerID INT
)
BEGIN
    SELECT
        s.FullName              AS FarmerName,
        i.InputName,
        i.Category,
        i.UnitOfMeasure,
        id.QuantityGiven,
        id.DistributionDate,
        id.PlotID,
        id.Notes                AS DistributionNotes,
        ib.ExpiryDate           AS BatchExpiry,
        ws.FullName             AS WorkerName

    FROM  InputDistribution  id
    JOIN  InputBatch         ib ON ib.BatchID       = id.BatchID
    JOIN  Input              i  ON i.InputID         = ib.InputID
    JOIN  Farmer             f  ON f.StakeholderID   = id.FarmerID
    JOIN  Stakeholder        s  ON s.StakeholderID   = f.StakeholderID
    LEFT JOIN Stakeholder    ws ON ws.StakeholderID  = id.WorkerID

    WHERE id.FarmerID = p_FarmerID
    ORDER BY id.DistributionDate DESC;
END $$

DELIMITER ;

DROP VIEW IF EXISTS vw_admin_full_farmer_profile;

CREATE VIEW vw_admin_full_farmer_profile AS
SELECT
    s.StakeholderID,
    s.FullName,
    s.NationalID,
    s.Gender,
    s.Phone,
    s.RegisteredDate,
    f.HouseholdSize,
    f.LiteracyLevel,
    f.TotalAcreage,
    v.VillageName,
    v.ParishName,
    d.DistrictName,
    COUNT(DISTINCT p.PlotID)         AS TotalPlots,
    COALESCE(SUM(h.QuantityKg), 0)  AS TotalHarvestKg

FROM  Stakeholder   s
JOIN  Farmer        f  ON f.StakeholderID = s.StakeholderID
LEFT JOIN Plot      p  ON p.FarmerID      = f.StakeholderID
LEFT JOIN Village   v  ON v.VillageID     = p.VillageID
LEFT JOIN District  d  ON d.DistrictID    = v.DistrictID
LEFT JOIN HarvestRecord h ON h.PlotID     = p.PlotID

GROUP BY
    s.StakeholderID, s.FullName, s.NationalID, s.Gender,
    s.Phone, s.RegisteredDate, f.HouseholdSize,
    f.LiteracyLevel, f.TotalAcreage,
    v.VillageName, v.ParishName, d.DistrictName;

DROP VIEW IF EXISTS vw_extension_worker_farmers;

CREATE VIEW vw_extension_worker_farmers AS
SELECT
    s.FullName          AS FarmerName,
    d.DistrictName,
    v.VillageName,
    v.ParishName,
    f.TotalAcreage,
    COUNT(DISTINCT p.PlotID) AS NumberOfPlots

FROM  Stakeholder   s
JOIN  Farmer        f  ON f.StakeholderID = s.StakeholderID
LEFT JOIN Plot      p  ON p.FarmerID      = f.StakeholderID
LEFT JOIN Village   v  ON v.VillageID     = p.VillageID
LEFT JOIN District  d  ON d.DistrictID    = v.DistrictID

GROUP BY
    s.FullName, d.DistrictName, v.VillageName,
    v.ParishName, f.TotalAcreage;

DROP VIEW IF EXISTS vw_nursery_operator_stock;

CREATE VIEW vw_nursery_operator_stock AS
SELECT
    n.NurseryID,
    n.NurseryName,
    s.FullName          AS OperatorName,
    sb.BatchID,
    sb.Variety,
    sb.QuantityAvailable,
    sb.CertifiedStatus,
    sb.CertDate

FROM  Nursery          n
JOIN  NurseryOperator  no ON no.StakeholderID = n.OperatorID
JOIN  Stakeholder      s  ON s.StakeholderID  = no.StakeholderID
JOIN  SeedlingBatch    sb ON sb.NurseryID     = n.NurseryID;

DROP VIEW IF EXISTS vw_farmer_self_view;

CREATE VIEW vw_farmer_self_view AS
SELECT
    s.FullName          AS FarmerName,
    p.PlotID,
    p.AreaHectares,
    p.SoilType,
    h.SeasonYear,
    h.HarvestDate,
    h.QuantityKg,
    h.ProcessingMethod,
    h.MoistureLevel,
    h.ComplianceStatus,
    d.QuantityGiven     AS SeedlingsReceived,
    d.DistributionDate

FROM  Stakeholder    s
JOIN  Farmer         f  ON f.StakeholderID = s.StakeholderID
LEFT JOIN Plot       p  ON p.FarmerID      = f.StakeholderID
LEFT JOIN HarvestRecord h ON h.PlotID      = p.PlotID
LEFT JOIN Distribution  d ON d.FarmerID    = f.StakeholderID;

DROP VIEW IF EXISTS vw_distribution_report;

CREATE VIEW vw_distribution_report AS
SELECT
    d.DistributionID,
    s.FullName          AS FarmerName,
    sb.Variety          AS SeedlingVariety,
    d.QuantityGiven,
    n.NurseryName,
    d.DistributionDate,
    ws.FullName         AS WorkerName

FROM  Distribution   d
JOIN  Farmer         f  ON f.StakeholderID = d.FarmerID
JOIN  Stakeholder    s  ON s.StakeholderID = f.StakeholderID
JOIN  SeedlingBatch  sb ON sb.BatchID      = d.BatchID
JOIN  Nursery        n  ON n.NurseryID     = sb.NurseryID
LEFT JOIN Stakeholder ws ON ws.StakeholderID = d.WorkerID

ORDER BY d.DistributionDate DESC;

DROP VIEW IF EXISTS vw_harvest_compliance_report;

CREATE VIEW vw_harvest_compliance_report AS
SELECT
    h.HarvestID,
    s.FullName          AS FarmerName,
    d.DistrictName,
    h.PlotID,
    h.SeasonYear,
    h.QuantityKg,
    h.MoistureLevel,
    h.ProcessingMethod,
    h.ComplianceStatus,
    h.HarvestDate

FROM  HarvestRecord  h
JOIN  Plot           p  ON p.PlotID        = h.PlotID
JOIN  Farmer         f  ON f.StakeholderID = p.FarmerID
JOIN  Stakeholder    s  ON s.StakeholderID = f.StakeholderID
LEFT JOIN Village    v  ON v.VillageID     = p.VillageID
LEFT JOIN District   d  ON d.DistrictID    = v.DistrictID

ORDER BY h.ComplianceStatus DESC, h.HarvestDate DESC;

DROP VIEW IF EXISTS vw_nursery_license_status;

CREATE VIEW vw_nursery_license_status AS
SELECT
    n.NurseryID,
    n.NurseryName,
    s.FullName              AS OperatorName,
    no.LicenseNumber,
    no.LicenseExpiry,
    CASE
        WHEN no.LicenseExpiry < CURDATE() THEN 'EXPIRED'
        ELSE 'Active'
    END                     AS LicenseStatus

FROM  Nursery          n
JOIN  NurseryOperator  no ON no.StakeholderID = n.OperatorID
JOIN  Stakeholder      s  ON s.StakeholderID  = no.StakeholderID

ORDER BY LicenseStatus DESC, n.NurseryName;

DROP VIEW IF EXISTS vw_audit_log_summary;

CREATE VIEW vw_audit_log_summary AS
SELECT
    LogID,
    TableName,
    ActionType,
    RecordID,
    ChangedBy,
    ChangeTimestamp,
    Notes

FROM AuditLog
ORDER BY ChangeTimestamp DESC;

DROP VIEW IF EXISTS vw_input_distribution_report;

CREATE VIEW vw_input_distribution_report AS
SELECT
    id.InputDistributionID,
    s.FullName           AS FarmerName,
    i.InputName,
    i.Category,
    i.UnitOfMeasure,
    id.QuantityGiven,
    id.DistributionDate,
    d.DistrictName       AS BatchDistrict,
    id.PlotID,
    id.Notes,
    ws.FullName          AS WorkerName

FROM  InputDistribution  id
JOIN  InputBatch         ib ON ib.BatchID       = id.BatchID
JOIN  Input              i  ON i.InputID         = ib.InputID
JOIN  Farmer             f  ON f.StakeholderID   = id.FarmerID
JOIN  Stakeholder        s  ON s.StakeholderID   = f.StakeholderID
JOIN  District           d  ON d.DistrictID      = ib.DistrictID
LEFT JOIN Stakeholder    ws ON ws.StakeholderID  = id.WorkerID

ORDER BY id.DistributionDate DESC;

DROP VIEW IF EXISTS vw_input_stock_alert;

CREATE VIEW vw_input_stock_alert AS
SELECT
    i.InputName,
    i.Category,
    ib.BatchID,
    ib.QuantityAvailable,
    ib.ExpiryDate,
    ib.ApprovalStatus,
    d.DistrictName,
    CASE
        WHEN ib.ExpiryDate < CURDATE()           THEN 'EXPIRED'
        WHEN ib.ApprovalStatus = 'Rejected'      THEN 'REJECTED'
        WHEN ib.ApprovalStatus = 'Pending'
         AND i.IsRestricted   = 'Yes'            THEN 'AWAITING APPROVAL'
        WHEN ib.QuantityAvailable = 0            THEN 'OUT OF STOCK'
        ELSE NULL
    END AS AlertReason

FROM  InputBatch ib
JOIN  Input      i ON i.InputID    = ib.InputID
JOIN  District   d ON d.DistrictID = ib.DistrictID

HAVING AlertReason IS NOT NULL

ORDER BY AlertReason, i.InputName;

DROP VIEW IF EXISTS vw_machinery_status;

CREATE VIEW vw_machinery_status AS
SELECT
    m.MachineID,
    i.InputName         AS MachineName,
    m.SerialNumber,
    m.`Condition_of_machinery`,
    m.AcquisitionDate,
    m.AvailabilityStatus,
    m.SupplierName,
    d.DistrictName      AS AssignedDistrict

FROM  MachineryInventory m
JOIN  Input              i ON i.InputID    = m.InputID
JOIN  District           d ON d.DistrictID = m.DistrictID

ORDER BY m.AvailabilityStatus, d.DistrictName, i.InputName;

DROP ROLE IF EXISTS role_admin;
DROP ROLE IF EXISTS role_extension_worker;
DROP ROLE IF EXISTS role_nursery_operator;
DROP ROLE IF EXISTS role_farmer;

CREATE ROLE role_admin;
CREATE ROLE role_extension_worker;
CREATE ROLE role_nursery_operator;
CREATE ROLE role_farmer;

GRANT ALL PRIVILEGES ON agri_coffee_db.* TO role_admin;

GRANT SELECT ON agri_coffee_db.vw_extension_worker_farmers     TO role_extension_worker;
GRANT SELECT ON agri_coffee_db.vw_harvest_compliance_report    TO role_extension_worker;
GRANT SELECT ON agri_coffee_db.vw_distribution_report          TO role_extension_worker;
GRANT SELECT ON agri_coffee_db.vw_input_distribution_report    TO role_extension_worker;

GRANT SELECT, INSERT, UPDATE ON agri_coffee_db.SeedlingBatch       TO role_nursery_operator;
GRANT SELECT ON agri_coffee_db.vw_nursery_operator_stock           TO role_nursery_operator;
GRANT SELECT ON agri_coffee_db.vw_nursery_license_status           TO role_nursery_operator;


DROP USER IF EXISTS '16admin_user'@'localhost';
DROP USER IF EXISTS '16worker_user'@'localhost';
DROP USER IF EXISTS '16nursery_user'@'localhost';

CREATE USER '16admin_user'@'localhost'   IDENTIFIED BY 'Admin@Secure2025!';
CREATE USER '16worker_user'@'localhost'  IDENTIFIED BY 'Worker@Secure2025!';
CREATE USER '16nursery_user'@'localhost' IDENTIFIED BY 'Nursery@Secure2025!';


GRANT role_admin             TO '16admin_user'@'localhost';
GRANT role_extension_worker  TO '16worker_user'@'localhost';
GRANT role_nursery_operator  TO '16nursery_user'@'localhost';
SET DEFAULT ROLE  role_admin           TO '16admin_user'@'localhost';
SET DEFAULT ROLE role_extension_worker TO '16worker_user'@'localhost';
SET DEFAULT ROLE role_nursery_operator TO '16nursery_user'@'localhost'; 

FLUSH PRIVILEGES;

INSERT INTO District (DistrictName) VALUES
    ('Masaka'),
    ('Mbarara'),
    ('Kampala');

INSERT INTO Village (VillageName, ParishName, DistrictID) VALUES
    ('Kyotera',   'Kyotera Parish',  1),
    ('Bukakata',  'Bukakata Parish', 1),
    ('Nyakayojo', 'Kakiika Parish',  2),
    ('Rubindi',   'Rubindi Parish',  2),
    ('Kasangati', 'Wakiso Parish',   3),
    ('Nansana',   'Nansana Parish',  3);

INSERT INTO Stakeholder (NationalID, FullName, Gender, Phone) VALUES
    ('CM90011001A', 'Apio Grace',     'Female', '0772100001'),
    ('CM90022002B', 'Otieno James',   'Male',   '0772100002'),
    ('CM90033003C', 'Nakato Harriet', 'Female', '0772100003'),
    ('CM90044004D', 'Mugisha Ronald', 'Male',   '0772100004'),
    ('CM90055005E', 'Ssemakula Fred', 'Male',   '0772100005'),
    ('CM90066006F', 'Namukasa Joan',  'Female', '0772100006');

INSERT INTO Farmer (StakeholderID, HouseholdSize, LiteracyLevel, TotalAcreage) VALUES
    (1, 5, 'Primary',   3.00),
    (2, 4, 'Secondary', 5.50),
    (3, 6, 'Primary',   2.00);

INSERT INTO ExtensionProvider (ProviderType) VALUES
    ('Government'),
    ('NGO');

INSERT INTO GovernmentDept (ProviderID, DeptName, MinistryBranch) VALUES
    (1, 'Directorate of Crop Resources', 'Ministry of Agriculture');

INSERT INTO NGO (ProviderID, NGOName, RegistrationNumber) VALUES
    (2, 'Uganda Coffee Farmers Alliance', 'NGO-REG-2019-4422');

INSERT INTO ExtensionWorker (StakeholderID, Qualification, Extension_worker_Rank, DistrictID, ProviderID) VALUES
    (4, 'BSc Agriculture', 'Senior Field Officer', 1, 1);

INSERT INTO NurseryOperator (StakeholderID, LicenseNumber, NurseryCapacity, LicenseExpiry) VALUES
    (5, 'NL-2025-0042', 50000, '2026-12-31');

INSERT INTO MinistryAdmin (StakeholderID, Department, PermissionLevel) VALUES
    (6, 'Crop Production and Marketing', 2);

INSERT INTO Nursery (OperatorID, NurseryName, Location, DistrictID) VALUES
    (5, 'Ssemakula Coffee Nursery A', 'Masaka Road, Km 12', 1),
    (5, 'Ssemakula Coffee Nursery B', 'Mbarara Industrial', 2);

INSERT INTO SeedlingBatch (NurseryID, Variety, QuantityAvailable, CertifiedStatus, CertDate) VALUES
    (1, 'Robusta Clone 1', 10000, 'Yes', '2025-04-15'),
    (1, 'Robusta Clone 2',  8000, 'Yes', '2025-04-20'),
    (1, 'Arabica SL14',     5000, 'No',  NULL),
    (2, 'Robusta Clone 1', 12000, 'Yes', '2025-05-01'),
    (2, 'Arabica SL28',     3000, 'Yes', '2025-05-10'),
    (2, 'Arabica SL14',     6000, 'No',  NULL);

INSERT INTO Plot (FarmerID, GPSLat, GPSLong, AreaHectares, SoilType, VillageID) VALUES
    (1, -0.4023000, 31.7340000, 1.50, 'Loam',       1),
    (1, -0.4028500, 31.7350000, 1.00, 'Clay Loam',  2),
    (2, -0.6052000, 30.6540000, 2.50, 'Sandy Loam', 3),
    (2, -0.6058000, 30.6550000, 3.00, 'Loam',       4),
    (3,  0.3990000, 32.5650000, 2.00, 'Red Earth',  5);

INSERT INTO HarvestRecord
    (PlotID, SeasonYear, QuantityKg, ProcessingMethod, MoistureLevel, HarvestDate) VALUES
    (1, 2024, 1200.00, 'Washed',  11.2, '2024-11-05'),
    (2, 2024,  800.00, 'Natural', 12.0, '2024-11-10'),
    (3, 2024, 2500.00, 'Washed',  10.8, '2024-11-15'),
    (4, 2024, 3100.00, 'Honey',   12.5, '2024-11-20'),
    (5, 2024, 1900.00, 'Washed',  11.5, '2024-11-25'),
    (1, 2023,  950.00, 'Natural', 12.3, '2023-10-30');

INSERT INTO Distribution (BatchID, FarmerID, QuantityGiven, DistributionDate, WorkerID, PlotID) VALUES
    (1, 1, 2000, '2025-06-15', 4, 1),
    (2, 2, 4000, '2025-07-01', 4, 3),
    (4, 3, 1500, '2025-07-20', 4, 5),
    (5, 1,  500, '2025-08-10', 4, 2);

INSERT INTO Input (InputName, Category, UnitOfMeasure, Description, IsRestricted) VALUES
    ('DAP Fertiliser',
     'Fertiliser', 'kg',
     'Di-Ammonium Phosphate. Applied at planting and early growth stage.',
     'No'),

    ('CAN Fertiliser',
     'Fertiliser', 'kg',
     'Calcium Ammonium Nitrate. Used for top-dressing during the growing season.',
     'No'),

    ('Copper Oxychloride Fungicide',
     'Fungicide', 'litres',
     'Broad-spectrum fungicide for controlling coffee leaf rust and berry disease.',
     'No'),

    ('Chlorpyrifos Insecticide',
     'Insecticide', 'litres',
     'Restricted organophosphate. Controls coffee stem borers. Requires Ministry approval.',
     'Yes'),

    ('Neem-Based Insecticide',
     'Insecticide', 'litres',
     'Organic, low-toxicity insecticide. Safe for use near water sources.',
     'No'),

    ('Organic Compost Booster',
     'Other', 'kg',
     'Microbial compost activator to improve soil health and nutrient retention.',
     'No'),

    ('Coffee Pulping Machine',
     'Machinery', 'units',
     'Motorised pulper for wet processing of coffee cherries. Capacity: 200 kg/hr.',
     'No');

INSERT INTO InputBatch
    (InputID, DistrictID, QuantityAvailable, DateReceived, ExpiryDate, ApprovalStatus, SupplierName)
VALUES
    (1, 1, 5000.00, '2025-03-01', '2027-03-01', 'Approved', 'Uganda Agro Supplies Ltd'),
    (2, 2, 3000.00, '2025-03-15', '2027-03-15', 'Approved', 'East Africa Agri Inputs'),
    (3, 1,  800.00, '2025-04-01', '2026-04-01', 'Approved', 'Uganda Agro Supplies Ltd'),
    (4, 2,  200.00, '2025-04-10', '2026-04-10', 'Pending',  'AgriChem East Africa'),
    (5, 3, 1500.00, '2025-05-01', '2026-05-01', 'Approved', 'Green Inputs Uganda'),
    (6, 1,10000.00, '2025-02-01', '2028-02-01', 'Approved', 'SoilLife Uganda'),
    (1, 3,  200.00, '2023-01-01', '2024-01-01', 'Approved', 'Old Supplier Co');

INSERT INTO MachineryInventory
    (InputID, SerialNumber, `Condition_of_machinery`, AcquisitionDate, DistrictID, AvailabilityStatus, SupplierName)
VALUES
    (7, 'CPM-2024-001', 'Good',        '2024-01-15', 1, 'Available',   'AgriMech Uganda Ltd'),
    (7, 'CPM-2024-002', 'Good',        '2024-01-15', 2, 'In Use',      'AgriMech Uganda Ltd'),
    (7, 'CPM-2023-003', 'Needs Repair','2023-06-01', 3, 'Under Repair','AgriMech Uganda Ltd');

INSERT INTO InputDistribution
    (BatchID, FarmerID, QuantityGiven, DistributionDate, PlotID, WorkerID, Notes)
VALUES
    (1, 1,  50.00, '2025-04-15', 1, 4,
     'Apply 50kg DAP at base of plants before onset of rains.'),

    (2, 2,  80.00, '2025-05-02', 3, 4,
     'Top-dress with CAN after first weeding. Split into two applications.'),

    (3, 3,  10.00, '2025-05-10', 5, 4,
     'Spray Copper Oxychloride fortnightly during wet season for leaf rust control.'),

    (5, 1,   5.00, '2025-05-20', 2, 4,
     'Dilute 1:10 with water. Spray on stems and undersides of leaves.'),

    (6, 2, 200.00, '2025-03-25', 4, 4,
     'Mix compost booster into topsoil around drip line of each tree.');

-- HOW TO BACK UP THIS DATABASE:
--   Open a terminal and run:
--   mysqldump -u root -p agri_coffee_db > backup_2025_08_01.sql
--
--   Replace the date in the filename with today's actual date.
--   This creates a .sql file containing the full database:
--   all table structures AND all data.
--
-- HOW TO RESTORE FROM A BACKUP:
--   mysql -u root -p agri_coffee_db < backup_2025_08_01.sql
--
-- STRUCTURE ONLY (no data):
--   mysqldump -u root -p --no-data agri_coffee_db > structure_only.sql
--
-- DATA ONLY (no table definitions):
--   mysqldump -u root -p --no-create-info agri_coffee_db > data_only.sql
--
-- RECOMMENDED SCHEDULE:
--   Run a full backup every day. Store the file on a separate
--   drive or upload to Google Drive / Dropbox as off-site backup.