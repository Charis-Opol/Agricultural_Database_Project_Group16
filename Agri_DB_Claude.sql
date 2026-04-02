-- Active: 1775134706375@@127.0.0.1@3306@agri_coffee_db
-- ============================================================
-- PROJECT : Agricultural Services Database
--           Ministry of Agriculture — Coffee Farmer Management System
-- COURSE  : Database Programming | Uganda Christian University
-- TARGET  : MySQL 8.0+
-- ============================================================
-- HOW TO USE THIS FILE
-- Open your terminal (or MySQL Workbench) and run:
--   mysql -u root -p < agri_coffee_db.sql
-- That will create the database and everything inside it from scratch.
--
-- Every line in this file has a comment above or beside it so you
-- can explain exactly what it does and why it is there.
-- ============================================================


-- ============================================================
-- SECTION 1: DATABASE SETUP
-- ============================================================

-- Drop the database if it already exists so we can start clean.
-- This is useful during development when you want to rebuild.
DROP DATABASE IF EXISTS agri_coffee_db;

-- Create the database.
-- utf8mb4 means it can store any character in the world (including emojis).
-- unicode_ci means text comparisons are case-insensitive.
CREATE DATABASE agri_coffee_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Tell MySQL to use this database for all commands that follow.
USE agri_coffee_db;


-- ============================================================
-- SECTION 2: TABLES
-- We create tables in a specific order because some tables
-- reference (link to) other tables using Foreign Keys (FK).
-- The table being referenced must exist first.
-- Order: District → Village → Stakeholder → subclasses →
--        Nursery → SeedlingBatch → Distribution →
--        Plot → HarvestRecord → ExtensionProvider →
--        GovernmentDept → NGO → AuditLog
-- ============================================================


-- ------------------------------------------------------------
-- TABLE 1: District
-- Stores the districts where farmers and workers operate.
-- This is the top of the location hierarchy.
-- ------------------------------------------------------------
DROP TABLE IF EXISTS District;

CREATE TABLE District (
    -- DistrictID is the unique number that identifies each district.
    -- AUTO_INCREMENT means MySQL assigns it automatically (1, 2, 3, ...).
    -- PRIMARY KEY means no two districts can have the same ID.
    DistrictID INT AUTO_INCREMENT PRIMARY KEY,

    -- DistrictName stores the name of the district (e.g., "Masaka").
    -- NOT NULL means you cannot leave this blank.
    -- UNIQUE means no two rows can have the same district name.
    DistrictName VARCHAR(100) NOT NULL UNIQUE
);


-- ------------------------------------------------------------
-- TABLE 2: Village
-- Each district contains multiple villages.
-- A village belongs to exactly one district (many-to-one).
-- ------------------------------------------------------------
DROP TABLE IF EXISTS Village;

CREATE TABLE Village (
    VillageID    INT          AUTO_INCREMENT PRIMARY KEY,
    VillageName  VARCHAR(100) NOT NULL,

    -- ParishName is the administrative unit between district and village.
    ParishName   VARCHAR(100),

    -- DistrictID links this village to its parent district.
    -- REFERENCES District(DistrictID) is the Foreign Key (FK) — it means
    -- you cannot enter a DistrictID that does not exist in the District table.
    DistrictID   INT NOT NULL,
    CONSTRAINT fk_village_district
        FOREIGN KEY (DistrictID) REFERENCES District(DistrictID)
        ON DELETE RESTRICT   -- Prevent deleting a District that still has Villages
        ON UPDATE CASCADE    -- If the DistrictID changes, update it here too
);


-- ------------------------------------------------------------
-- TABLE 3: Stakeholder (SUPERCLASS)
-- This is the parent table for all people in the system.
-- Every farmer, worker, nursery operator, and admin is first
-- stored here, then in their specific subclass table.
-- This is the "Generalization / Specialization" from the EERD.
-- ------------------------------------------------------------
DROP TABLE IF EXISTS Stakeholder;

CREATE TABLE Stakeholder (
    StakeholderID  INT          AUTO_INCREMENT PRIMARY KEY,

    -- NationalID is Uganda's national identification number.
    -- UNIQUE ensures no person registers twice.
    NationalID     VARCHAR(20)  NOT NULL UNIQUE,

    FullName       VARCHAR(150) NOT NULL,

    -- ENUM means only the listed values are accepted.
    -- MySQL will reject anything else (e.g., 'Unknown').
    Gender         ENUM('Male','Female','Other') NOT NULL,

    Phone          VARCHAR(20)  NOT NULL,

    -- DEFAULT CURDATE() automatically fills in today's date
    -- if you do not provide one during INSERT.
    RegisteredDate DATE         NOT NULL DEFAULT (CURDATE())
);


-- ------------------------------------------------------------
-- TABLE 4: Farmer (SUBCLASS of Stakeholder)
-- A farmer IS a stakeholder, so StakeholderID is both the
-- Primary Key of this table AND a Foreign Key linking back
-- to the Stakeholder table. This is the "shared PK" pattern.
-- ------------------------------------------------------------
DROP TABLE IF EXISTS Farmer;

CREATE TABLE Farmer (
    -- StakeholderID is the PK AND FK at the same time.
    -- It connects each Farmer row to exactly one Stakeholder row.
    StakeholderID  INT             PRIMARY KEY,

    -- HouseholdSize: how many people live with the farmer.
    HouseholdSize  TINYINT,       -- TINYINT stores whole numbers 0–127

    LiteracyLevel  ENUM('None','Primary','Secondary','Tertiary'),

    -- TotalAcreage: total land area owned by the farmer.
    -- DECIMAL(8,2) stores numbers like 12.50 (up to 6 digits before decimal).
    -- CHECK constraint ensures acreage is always a positive number.
    TotalAcreage   DECIMAL(8,2)   NOT NULL,
    CONSTRAINT chk_farmer_acreage CHECK (TotalAcreage > 0),

    -- This is the Foreign Key linking Farmer back to Stakeholder.
    CONSTRAINT fk_farmer_stakeholder
        FOREIGN KEY (StakeholderID) REFERENCES Stakeholder(StakeholderID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);


-- ------------------------------------------------------------
-- TABLE 5: ExtensionWorker (SUBCLASS of Stakeholder)
-- An extension worker is a field officer who advises farmers.
-- They are assigned to one specific district.
-- ------------------------------------------------------------
DROP TABLE IF EXISTS ExtensionWorker;

CREATE TABLE ExtensionWorker (
    StakeholderID  INT          PRIMARY KEY,
    Qualification  VARCHAR(100),  -- e.g., "BSc Agriculture"
    Rank           VARCHAR(50),   -- e.g., "Senior Officer"

    -- The district this worker is responsible for.
    DistrictID     INT          NOT NULL,

    CONSTRAINT fk_worker_stakeholder
        FOREIGN KEY (StakeholderID) REFERENCES Stakeholder(StakeholderID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_worker_district
        FOREIGN KEY (DistrictID) REFERENCES District(DistrictID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);


-- ------------------------------------------------------------
-- TABLE 6: NurseryOperator (SUBCLASS of Stakeholder)
-- A nursery operator grows and supplies coffee seedlings.
-- They must have a valid government license.
-- ------------------------------------------------------------
DROP TABLE IF EXISTS NurseryOperator;

CREATE TABLE NurseryOperator (
    StakeholderID   INT         PRIMARY KEY,

    -- LicenseNumber is the unique license issued by the Ministry.
    LicenseNumber   VARCHAR(30) NOT NULL UNIQUE,

    -- How many seedlings the nursery can hold at once.
    NurseryCapacity INT,

    -- The date the license expires. Must be provided.
    LicenseExpiry   DATE        NOT NULL,

    CONSTRAINT fk_nursop_stakeholder
        FOREIGN KEY (StakeholderID) REFERENCES Stakeholder(StakeholderID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);


-- ------------------------------------------------------------
-- TABLE 7: MinistryAdmin (SUBCLASS of Stakeholder)
-- Ministry administrators manage the system and have the
-- highest level of access.
-- ------------------------------------------------------------
DROP TABLE IF EXISTS MinistryAdmin;

CREATE TABLE MinistryAdmin (
    StakeholderID   INT         PRIMARY KEY,
    Department      VARCHAR(100),           -- e.g., "Crop Production Dept"

    -- PermissionLevel: 1 = standard admin, 2 = super admin.
    -- DEFAULT 1 means every new admin starts at level 1.
    PermissionLevel TINYINT     NOT NULL DEFAULT 1,

    CONSTRAINT fk_admin_stakeholder
        FOREIGN KEY (StakeholderID) REFERENCES Stakeholder(StakeholderID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);


-- ------------------------------------------------------------
-- TABLE 8: Nursery
-- A physical nursery location owned by a NurseryOperator.
-- One operator can own multiple nurseries.
-- ------------------------------------------------------------
DROP TABLE IF EXISTS Nursery;

CREATE TABLE Nursery (
    NurseryID   INT          AUTO_INCREMENT PRIMARY KEY,

    -- OperatorID links this nursery to its owner.
    OperatorID  INT          NOT NULL,

    NurseryName VARCHAR(150) NOT NULL,
    Location    VARCHAR(255),

    -- The district where this nursery is physically located.
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


-- ------------------------------------------------------------
-- TABLE 9: SeedlingBatch
-- A batch is a group of seedlings of a specific coffee variety
-- produced by a nursery. It must be certified before distribution.
-- ------------------------------------------------------------
DROP TABLE IF EXISTS SeedlingBatch;

CREATE TABLE SeedlingBatch (
    BatchID            INT          AUTO_INCREMENT PRIMARY KEY,

    -- Which nursery produced this batch.
    NurseryID          INT          NOT NULL,

    -- The coffee variety in this batch (e.g., "Robusta Clone 1").
    Variety            VARCHAR(100) NOT NULL,

    -- How many seedlings are currently available.
    -- DEFAULT 0 means a new batch starts with zero until stock is entered.
    QuantityAvailable  INT          NOT NULL DEFAULT 0,

    -- Has this batch been tested and approved for distribution?
    CertifiedStatus    ENUM('Yes','No') NOT NULL DEFAULT 'No',

    -- Date the batch was certified. Only required if CertifiedStatus = 'Yes'.
    CertDate           DATE,

    -- Business Rule: If a batch is marked 'Yes' (certified),
    -- then CertDate MUST be filled in. We cannot certify without a date.
    CONSTRAINT chk_certdate
        CHECK (CertifiedStatus = 'No' OR CertDate IS NOT NULL),

    CONSTRAINT fk_batch_nursery
        FOREIGN KEY (NurseryID) REFERENCES Nursery(NurseryID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);


-- ------------------------------------------------------------
-- TABLE 10: Distribution
-- Records when seedlings are given to a farmer.
-- Two CHECK constraints and one cross-table rule (via trigger).
-- ------------------------------------------------------------
DROP TABLE IF EXISTS Distribution;

CREATE TABLE Distribution (
    DistributionID   INT  AUTO_INCREMENT PRIMARY KEY,

    -- Which batch of seedlings is being distributed.
    BatchID          INT  NOT NULL,

    -- Which farmer is receiving the seedlings.
    FarmerID         INT  NOT NULL,

    -- How many seedlings are being given.
    QuantityGiven    INT  NOT NULL,

    -- The date of distribution.
    DistributionDate DATE NOT NULL,

    -- Business Rule 1: Quantity must be a positive number.
    CONSTRAINT chk_dist_qty CHECK (QuantityGiven > 0),

    -- Business Rule 2: Distributions can only happen during the planting season.
    -- MONTH() extracts the month number from a date.
    -- June = 6, August = 8. BETWEEN 6 AND 8 means June, July, or August only.
    CONSTRAINT chk_dist_season
        CHECK (MONTH(DistributionDate) BETWEEN 6 AND 8),

    -- NOTE: The rule "QuantityGiven <= TotalAcreage * 1000" cannot be written
    -- as a CHECK constraint because it needs data from the Farmer table.
    -- MySQL CHECK constraints cannot reach into other tables.
    -- We handle this in Trigger T1 (trg_distribution_validate) below.

    CONSTRAINT fk_dist_batch
        FOREIGN KEY (BatchID) REFERENCES SeedlingBatch(BatchID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_dist_farmer
        FOREIGN KEY (FarmerID) REFERENCES Farmer(StakeholderID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);


-- ------------------------------------------------------------
-- TABLE 11: Plot
-- A single piece of farmland owned by a farmer.
-- One farmer can have many plots.
-- ------------------------------------------------------------
DROP TABLE IF EXISTS Plot;

CREATE TABLE Plot (
    PlotID        INT             AUTO_INCREMENT PRIMARY KEY,

    -- The farmer who owns this plot.
    FarmerID      INT             NOT NULL,

    -- GPS coordinates stored as decimal degrees.
    -- DECIMAL(10,7) allows precision like -0.3035890 (7 decimal places).
    GPSLat        DECIMAL(10,7)   NOT NULL,
    GPSLong       DECIMAL(10,7)   NOT NULL,

    -- Size of the plot in hectares. Must be greater than zero.
    AreaHectares  DECIMAL(8,2),
    CONSTRAINT chk_plot_area CHECK (AreaHectares > 0),

    SoilType      VARCHAR(50),

    -- The village where this plot is located.
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


-- ------------------------------------------------------------
-- TABLE 12: HarvestRecord
-- Records a single coffee harvest from a specific plot
-- in a specific season.
-- ------------------------------------------------------------
DROP TABLE IF EXISTS HarvestRecord;

CREATE TABLE HarvestRecord (
    HarvestID         INT             AUTO_INCREMENT PRIMARY KEY,

    -- The plot that produced this harvest.
    PlotID            INT             NOT NULL,

    -- The year the coffee was harvested (stored as a 4-digit year).
    SeasonYear        YEAR            NOT NULL,

    -- Total weight of coffee harvested in kilograms.
    QuantityKg        DECIMAL(10,2),
    CONSTRAINT chk_harvest_qty CHECK (QuantityKg > 0),

    -- How the coffee was processed after picking.
    ProcessingMethod  ENUM('Washed','Natural','Honey') NOT NULL,

    -- Moisture percentage of the coffee. Must not exceed 12.5%.
    -- Anything above 12.5% fails the international export standard.
    MoistureLevel     DECIMAL(4,2),
    CONSTRAINT chk_moisture CHECK (MoistureLevel <= 12.5),

    HarvestDate       DATE            NOT NULL,

    -- Whether this harvest meets quality standards.
    -- Trigger T3 will automatically set this to 'Non-Compliant'
    -- if MoistureLevel is too high.
    ComplianceStatus  ENUM('Compliant','Non-Compliant') NOT NULL DEFAULT 'Compliant',

    CONSTRAINT fk_harvest_plot
        FOREIGN KEY (PlotID) REFERENCES Plot(PlotID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);


-- ------------------------------------------------------------
-- TABLE 13: ExtensionProvider (CATEGORY / UNION TYPE from EERD)
-- Extension services can come from either a Government Department
-- or an NGO. This table is the "union" that connects both.
-- It is a category entity — GovernmentDept and NGO both point to it.
-- ------------------------------------------------------------
DROP TABLE IF EXISTS ExtensionProvider;

CREATE TABLE ExtensionProvider (
    ProviderID   INT AUTO_INCREMENT PRIMARY KEY,

    -- What type of provider this is.
    ProviderType ENUM('Government','NGO') NOT NULL
);


-- ------------------------------------------------------------
-- TABLE 14: GovernmentDept
-- A government department that provides extension services.
-- It links to ExtensionProvider through ProviderID.
-- ------------------------------------------------------------
DROP TABLE IF EXISTS GovernmentDept;

CREATE TABLE GovernmentDept (
    DeptID INT AUTO_INCREMENT PRIMARY KEY,

    -- Links to ExtensionProvider (the category/union table).
    ProviderID INT NOT NULL,

    DeptName  VARCHAR(150) NOT NULL,
    MinistryBranch VARCHAR(100),

    CONSTRAINT fk_govtdept_provider
        FOREIGN KEY (ProviderID) REFERENCES ExtensionProvider(ProviderID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);


-- ------------------------------------------------------------
-- TABLE 15: NGO
-- A Non-Governmental Organisation that provides extension services.
-- It also links to ExtensionProvider through ProviderID.
-- ------------------------------------------------------------
DROP TABLE IF EXISTS NGO;

CREATE TABLE NGO (
    NGOID              INT         AUTO_INCREMENT PRIMARY KEY,
    ProviderID         INT         NOT NULL,
    NGOName            VARCHAR(150) NOT NULL,

    -- NGOs must have a unique government registration number.
    RegistrationNumber VARCHAR(50) UNIQUE,

    CONSTRAINT fk_ngo_provider
        FOREIGN KEY (ProviderID) REFERENCES ExtensionProvider(ProviderID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);


-- ------------------------------------------------------------
-- TABLE 16: AuditLog
-- This table is never filled in manually.
-- Triggers (see Section 3) automatically write a record here
-- every time something important changes in the database.
-- This is how the Ministry tracks who changed what and when.
-- ------------------------------------------------------------
DROP TABLE IF EXISTS AuditLog;

CREATE TABLE AuditLog (
    LogID            INT          AUTO_INCREMENT PRIMARY KEY,

    -- Which table was affected (e.g., 'Farmer', 'Distribution').
    TableName        VARCHAR(50),

    -- What kind of change happened.
    ActionType       ENUM('INSERT','UPDATE','DELETE'),

    -- The ID of the row that was changed.
    RecordID         INT,

    -- CURRENT_USER() is a MySQL function that returns the name of the
    -- currently logged-in database user.
    ChangedBy        VARCHAR(100) DEFAULT (CURRENT_USER()),

    -- NOW() returns the exact date and time of the change.
    ChangeTimestamp  DATETIME     DEFAULT (NOW()),

    -- Extra details about what changed (written by each trigger).
    Notes            TEXT
);


-- ============================================================
-- SECTION 3: TRIGGERS
-- A trigger is code that runs AUTOMATICALLY when something
-- happens in a table (INSERT, UPDATE, or DELETE).
-- You never call a trigger directly — MySQL fires it for you.
--
-- DELIMITER $$ changes the statement terminator from ; to $$
-- so MySQL does not get confused by the semicolons inside the
-- trigger body.
-- ============================================================

DELIMITER $$


-- ------------------------------------------------------------
-- TRIGGER T1: trg_distribution_validate
-- Fires: BEFORE a row is inserted into Distribution.
-- Purpose: Enforce three business rules that CHECK constraints
--          cannot handle because they need data from other tables.
-- If any rule fails, SIGNAL SQLSTATE raises an error and the
-- INSERT is cancelled completely.
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_distribution_validate $$

CREATE TRIGGER trg_distribution_validate
BEFORE INSERT ON Distribution
FOR EACH ROW
BEGIN
    -- Declare variables to hold values we will look up.
    DECLARE v_certified     ENUM('Yes','No');
    DECLARE v_acreage       DECIMAL(8,2);
    DECLARE v_license_expiry DATE;

    -- Step 1: Look up the CertifiedStatus of the batch being distributed.
    -- NEW.BatchID refers to the BatchID value in the row being inserted.
    SELECT CertifiedStatus
    INTO   v_certified
    FROM   SeedlingBatch
    WHERE  BatchID = NEW.BatchID;

    -- Rule: The batch must be certified before it can be distributed.
    IF v_certified != 'Yes' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot distribute: this seedling batch is not certified.';
    END IF;

    -- Step 2: Look up how many acres the farmer owns.
    SELECT TotalAcreage
    INTO   v_acreage
    FROM   Farmer
    WHERE  StakeholderID = NEW.FarmerID;

    -- Rule: The quantity given cannot exceed 1000 seedlings per acre.
    -- Example: A farmer with 2 acres can get at most 2000 seedlings.
    IF NEW.QuantityGiven > (v_acreage * 1000) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot distribute: quantity exceeds the 1000-per-acre limit for this farmer.';
    END IF;

    -- Step 3: Check that the nursery operator license has not expired.
    -- We trace: Distribution → SeedlingBatch → Nursery → NurseryOperator.
    SELECT no.LicenseExpiry
    INTO   v_license_expiry
    FROM   SeedlingBatch  sb
    JOIN   Nursery        n  ON n.NurseryID   = sb.NurseryID
    JOIN   NurseryOperator no ON no.StakeholderID = n.OperatorID
    WHERE  sb.BatchID = NEW.BatchID;

    -- Rule: We cannot distribute from a nursery with an expired license.
    IF v_license_expiry < CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot distribute: the nursery operator license has expired.';
    END IF;

END $$


-- ------------------------------------------------------------
-- TRIGGER T2: trg_distribution_reduce_stock
-- Fires: AFTER a row is successfully inserted into Distribution.
-- Purpose: Automatically subtract the distributed quantity from
--          the seedling batch stock. This keeps inventory accurate
--          without requiring anyone to update it manually.
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_distribution_reduce_stock $$

CREATE TRIGGER trg_distribution_reduce_stock
AFTER INSERT ON Distribution
FOR EACH ROW
BEGIN
    -- Subtract QuantityGiven from the batch that was just distributed.
    UPDATE SeedlingBatch
    SET    QuantityAvailable = QuantityAvailable - NEW.QuantityGiven
    WHERE  BatchID = NEW.BatchID;
END $$


-- ------------------------------------------------------------
-- TRIGGER T3: trg_harvest_compliance_check
-- Fires: AFTER a new HarvestRecord row is inserted.
-- Purpose: If the moisture level is above the export threshold,
--          automatically flag the harvest as Non-Compliant.
-- Note: The CHECK constraint already blocks values above 12.5
--       at the SQL level. This trigger handles the status flag
--       as an extra safety net and for audit clarity.
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_harvest_compliance_check $$

CREATE TRIGGER trg_harvest_compliance_check
AFTER INSERT ON HarvestRecord
FOR EACH ROW
BEGIN
    -- Only update if moisture is dangerously high.
    IF NEW.MoistureLevel > 12.5 THEN
        UPDATE HarvestRecord
        SET    ComplianceStatus = 'Non-Compliant'
        WHERE  HarvestID = NEW.HarvestID;
    END IF;
END $$


-- ------------------------------------------------------------
-- TRIGGER T4: trg_audit_farmer_insert
-- Fires: AFTER a new Farmer row is inserted.
-- Purpose: Write a record to AuditLog so the Ministry can see
--          exactly when a new farmer was registered and by whom.
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_audit_farmer_insert $$

CREATE TRIGGER trg_audit_farmer_insert
AFTER INSERT ON Farmer
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (TableName, ActionType, RecordID, Notes)
    VALUES ('Farmer', 'INSERT', NEW.StakeholderID, 'New farmer registered.');
END $$


-- ------------------------------------------------------------
-- TRIGGER T5: trg_audit_farmer_update
-- Fires: AFTER any Farmer row is updated.
-- Purpose: Record what changed. OLD refers to the values BEFORE
--          the update; NEW refers to the values AFTER.
-- ------------------------------------------------------------
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
        -- CONCAT joins strings together into one message.
        CONCAT('Acreage changed from ', OLD.TotalAcreage, ' to ', NEW.TotalAcreage,
               '. Literacy changed from ', OLD.LiteracyLevel, ' to ', NEW.LiteracyLevel, '.')
    );
END $$


-- ------------------------------------------------------------
-- TRIGGER T6: trg_audit_farmer_delete
-- Fires: BEFORE a Farmer row is deleted.
-- Purpose: Write the deletion to AuditLog BEFORE the row
--          disappears, so we still have the farmer's ID on record.
-- ------------------------------------------------------------
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


-- ------------------------------------------------------------
-- TRIGGER T7: trg_audit_distribution_insert
-- Fires: AFTER a new Distribution row is inserted.
-- Purpose: Log every seedling distribution event for accountability.
-- ------------------------------------------------------------
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
               ' from BatchID ', NEW.BatchID, ' on ', NEW.DistributionDate, '.')
    );
END $$


-- ------------------------------------------------------------
-- TRIGGER T8: trg_audit_harvest_insert
-- Fires: AFTER a new HarvestRecord row is inserted.
-- Purpose: Log every harvest record so the Ministry can track
--          production history and compliance over time.
-- ------------------------------------------------------------
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


-- Restore the normal semicolon terminator.
DELIMITER ;


-- ============================================================
-- SECTION 4: STORED PROCEDURES
-- A stored procedure is a saved block of SQL code that you can
-- call by name, just like a function in Python.
-- It keeps complex logic in one place so it can be reused
-- without rewriting it every time.
-- ============================================================

DELIMITER $$


-- ------------------------------------------------------------
-- SP1: RegisterFarmer
-- Registers a new farmer in one single call.
-- It inserts into Stakeholder first, then into Farmer.
-- Both inserts are wrapped in a TRANSACTION so if one fails,
-- both are cancelled (rolled back) — preventing partial data.
-- ------------------------------------------------------------
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
    -- DECLARE a variable to store any error that occurs.
    DECLARE v_new_id INT;

    -- Start the transaction. Changes are NOT saved until COMMIT.
    START TRANSACTION;

    -- Insert the person's general info into the Stakeholder table.
    INSERT INTO Stakeholder (NationalID, FullName, Gender, Phone)
    VALUES (p_NationalID, p_FullName, p_Gender, p_Phone);

    -- LAST_INSERT_ID() gives us the StakeholderID that was just created.
    SET v_new_id = LAST_INSERT_ID();

    -- Now insert the farmer-specific details using that same ID.
    INSERT INTO Farmer (StakeholderID, HouseholdSize, LiteracyLevel, TotalAcreage)
    VALUES (v_new_id, p_HouseholdSize, p_LiteracyLevel, p_TotalAcreage);

    -- Everything worked — save the changes permanently.
    COMMIT;

    -- Return a message confirming the registration.
    SELECT CONCAT('SUCCESS: Farmer registered with StakeholderID = ', v_new_id) AS Result;
END $$


-- ------------------------------------------------------------
-- SP2: GetFarmerSummary
-- Pulls a complete profile for a single farmer:
-- their name, how many plots they have, total harvest,
-- total seedlings received, and any compliance issues.
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS GetFarmerSummary $$

CREATE PROCEDURE GetFarmerSummary(
    IN p_FarmerID INT
)
BEGIN
    SELECT
        -- Get the farmer's full name from the Stakeholder table.
        s.FullName                              AS FarmerName,

        -- COUNT(DISTINCT) counts unique PlotIDs for this farmer.
        COUNT(DISTINCT p.PlotID)                AS TotalPlots,

        -- SUM adds up all kilograms harvested across all plots and seasons.
        COALESCE(SUM(h.QuantityKg), 0)          AS TotalHarvestKg,

        -- SUM adds up all seedlings this farmer has ever received.
        COALESCE(SUM(d.QuantityGiven), 0)       AS TotalSeedlingsReceived,

        -- COUNT how many harvests were flagged as non-compliant.
        SUM(CASE WHEN h.ComplianceStatus = 'Non-Compliant' THEN 1 ELSE 0 END)
                                                AS NonCompliantHarvests

    FROM       Stakeholder  s

    -- JOIN connects two tables using a shared column.
    -- Here we join Farmer to get TotalAcreage etc.
    JOIN       Farmer       f  ON f.StakeholderID = s.StakeholderID

    -- LEFT JOIN means: include the farmer even if they have no plots.
    LEFT JOIN  Plot         p  ON p.FarmerID = f.StakeholderID
    LEFT JOIN  HarvestRecord h ON h.PlotID   = p.PlotID
    LEFT JOIN  Distribution  d ON d.FarmerID = f.StakeholderID

    -- Filter to only the requested farmer.
    WHERE f.StakeholderID = p_FarmerID

    GROUP BY s.FullName;
END $$


-- ------------------------------------------------------------
-- SP3: GetRegionalYieldReport
-- Produces a yield report for all farmers in a given district.
-- Useful for the Ministry to compare performance by region.
-- ------------------------------------------------------------
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

        -- AVG calculates the average yield per hectare across all plots.
        -- NULLIF prevents division by zero if AreaHectares is 0.
        ROUND(AVG(h.QuantityKg / NULLIF(p.AreaHectares, 0)), 2) AS AvgYieldPerHectare

    FROM  District    d
    JOIN  Village     v  ON v.DistrictID   = d.DistrictID
    JOIN  Plot        p  ON p.VillageID    = v.VillageID
    JOIN  Farmer      f  ON f.StakeholderID = p.FarmerID
    LEFT JOIN HarvestRecord h ON h.PlotID  = p.PlotID

    WHERE d.DistrictID = p_DistrictID

    GROUP BY d.DistrictName;
END $$


-- ------------------------------------------------------------
-- SP4: DistributeSeedlings
-- A safe way to record a seedling distribution.
-- It manually checks the same rules as Trigger T1 and gives
-- a clear confirmation message with remaining stock.
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS DistributeSeedlings $$

CREATE PROCEDURE DistributeSeedlings(
    IN p_BatchID  INT,
    IN p_FarmerID INT,
    IN p_Quantity INT,
    IN p_Date     DATE
)
BEGIN
    DECLARE v_certified      ENUM('Yes','No');
    DECLARE v_stock          INT;
    DECLARE v_remaining      INT;

    -- Check 1: Does the farmer exist?
    IF NOT EXISTS (SELECT 1 FROM Farmer WHERE StakeholderID = p_FarmerID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Farmer ID does not exist.';
    END IF;

    -- Check 2: Is the batch certified?
    SELECT CertifiedStatus, QuantityAvailable
    INTO   v_certified, v_stock
    FROM   SeedlingBatch
    WHERE  BatchID = p_BatchID;

    IF v_certified != 'Yes' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Batch is not certified for distribution.';
    END IF;

    -- Check 3: Is the date within the planting season (June–August)?
    IF MONTH(p_Date) NOT BETWEEN 6 AND 8 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Distributions are only allowed between June and August.';
    END IF;

    -- All checks passed — insert the distribution record.
    -- Trigger T1 will also run at this point for extra safety.
    -- Trigger T2 will automatically reduce the stock.
    INSERT INTO Distribution (BatchID, FarmerID, QuantityGiven, DistributionDate)
    VALUES (p_BatchID, p_FarmerID, p_Quantity, p_Date);

    -- Calculate remaining stock AFTER the trigger has updated it.
    SELECT QuantityAvailable INTO v_remaining
    FROM SeedlingBatch WHERE BatchID = p_BatchID;

    -- Return a success message showing remaining stock.
    SELECT CONCAT('SUCCESS: ', p_Quantity, ' seedlings distributed.',
                  ' Remaining stock for BatchID ', p_BatchID, ': ', v_remaining) AS Result;
END $$


-- ------------------------------------------------------------
-- SP5: GetNurseryStockReport
-- Shows all nurseries, their seedling stock, and whether
-- the operator license is still active or expired.
-- ------------------------------------------------------------
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

        -- CASE WHEN is like an IF statement inside a SELECT.
        -- It adds a computed column based on a condition.
        CASE
            WHEN no.LicenseExpiry < CURDATE() THEN 'EXPIRED'
            ELSE 'Active'
        END                                     AS LicenseStatus

    FROM  Nursery          n
    JOIN  NurseryOperator  no ON no.StakeholderID = n.OperatorID
    JOIN  Stakeholder      s  ON s.StakeholderID  = no.StakeholderID
    JOIN  SeedlingBatch    sb ON sb.NurseryID      = n.NurseryID

    -- Show expired licenses at the top so admins see them first.
    ORDER BY LicenseStatus DESC, n.NurseryName ASC;
END $$


-- ------------------------------------------------------------
-- SP6: GetFarmersByDistrict
-- Returns all farmers whose plots are in a given district.
-- Includes acreage, plot count, and most recent harvest date.
-- ------------------------------------------------------------
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


-- ------------------------------------------------------------
-- SP7: GetNonCompliantHarvests
-- Lists all harvests that failed the moisture quality standard.
-- Ordered by most recent first so the Ministry sees the latest
-- problems at the top.
-- ------------------------------------------------------------
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


-- ------------------------------------------------------------
-- SP8: GenerateDistributionSummary
-- Produces a season-level summary of all seedling distributions:
-- total seedlings out, farmers served, breakdown by variety,
-- and which districts received the most.
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS GenerateDistributionSummary $$

CREATE PROCEDURE GenerateDistributionSummary(
    IN p_SeasonYear YEAR
)
BEGIN
    -- Summary totals for the season.
    SELECT
        COUNT(DISTINCT d.FarmerID)  AS FarmersServed,
        SUM(d.QuantityGiven)        AS TotalSeedlingsDistributed,
        MIN(d.DistributionDate)     AS FirstDistribution,
        MAX(d.DistributionDate)     AS LastDistribution

    FROM  Distribution d
    WHERE YEAR(d.DistributionDate) = p_SeasonYear;

    -- Breakdown by variety.
    SELECT
        sb.Variety,
        SUM(d.QuantityGiven)        AS QuantityByVariety

    FROM  Distribution  d
    JOIN  SeedlingBatch sb ON sb.BatchID = d.BatchID

    WHERE YEAR(d.DistributionDate) = p_SeasonYear
    GROUP BY sb.Variety
    ORDER BY QuantityByVariety DESC;

    -- Top 5 districts by seedlings received.
    SELECT
        dist.DistrictName,
        SUM(d.QuantityGiven)        AS TotalReceived

    FROM  Distribution d
    JOIN  Farmer       f   ON f.StakeholderID = d.FarmerID
    JOIN  Plot         p   ON p.FarmerID      = f.StakeholderID
    JOIN  Village      v   ON v.VillageID     = p.VillageID
    JOIN  District     dist ON dist.DistrictID = v.DistrictID

    WHERE YEAR(d.DistributionDate) = p_SeasonYear
    GROUP BY dist.DistrictName
    ORDER BY TotalReceived DESC
    LIMIT 5;
END $$


DELIMITER ;


-- ============================================================
-- SECTION 5: VIEWS
-- A view is a saved SELECT query that looks and behaves like
-- a table. We use views to control what each type of user can
-- see. Users query the view — they never touch the base tables
-- directly (unless their role permits it).
-- ============================================================


-- ------------------------------------------------------------
-- V1: vw_admin_full_farmer_profile  [Ministry Admin]
-- Full farmer details including location and harvest totals.
-- Only admin users should be granted access to this view.
-- ------------------------------------------------------------
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
LEFT JOIN HarvestRecord h ON h.PlotID    = p.PlotID

GROUP BY
    s.StakeholderID, s.FullName, s.NationalID, s.Gender,
    s.Phone, s.RegisteredDate, f.HouseholdSize,
    f.LiteracyLevel, f.TotalAcreage,
    v.VillageName, v.ParishName, d.DistrictName;


-- ------------------------------------------------------------
-- V2: vw_extension_worker_farmers  [Extension Worker]
-- A safe view for extension workers — shows farmer names,
-- location, and plot count. Sensitive data (NationalID,
-- household info) is deliberately excluded.
-- ------------------------------------------------------------
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


-- ------------------------------------------------------------
-- V3: vw_nursery_operator_stock  [Nursery Operator]
-- Shows seedling batch stock for all nurseries.
-- In production, an app layer would filter by the logged-in
-- operator's ID so they only see their own stock.
-- ------------------------------------------------------------
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


-- ------------------------------------------------------------
-- V4: vw_farmer_self_view  [Farmer / Portal Access]
-- Read-only view of a farmer's own records: plots,
-- harvests, and distributions. Personal portal use.
-- ------------------------------------------------------------
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
LEFT JOIN HarvestRecord h ON h.PlotID     = p.PlotID
LEFT JOIN Distribution  d ON d.FarmerID   = f.StakeholderID;


-- ------------------------------------------------------------
-- V5: vw_distribution_report  [Admin + Extension Workers]
-- Complete history of all seedling distributions.
-- Useful for Ministry reporting and accountability.
-- ------------------------------------------------------------
DROP VIEW IF EXISTS vw_distribution_report;

CREATE VIEW vw_distribution_report AS
SELECT
    d.DistributionID,
    s.FullName          AS FarmerName,
    sb.Variety          AS SeedlingVariety,
    d.QuantityGiven,
    n.NurseryName,
    d.DistributionDate

FROM  Distribution   d
JOIN  Farmer         f  ON f.StakeholderID = d.FarmerID
JOIN  Stakeholder    s  ON s.StakeholderID = f.StakeholderID
JOIN  SeedlingBatch  sb ON sb.BatchID      = d.BatchID
JOIN  Nursery        n  ON n.NurseryID     = sb.NurseryID

ORDER BY d.DistributionDate DESC;


-- ------------------------------------------------------------
-- V6: vw_harvest_compliance_report  [Admin + Extension Workers]
-- All harvest records with compliance status highlighted.
-- Non-Compliant harvests are easy to identify for intervention.
-- ------------------------------------------------------------
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


-- ------------------------------------------------------------
-- V7: vw_nursery_license_status  [Admin]
-- Shows every nursery with a computed Active/EXPIRED badge
-- so admins can immediately spot compliance issues.
-- ------------------------------------------------------------
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


-- ------------------------------------------------------------
-- V8: vw_audit_log_summary  [Admin only]
-- Full audit trail of every recorded change in the database.
-- Ordered newest first so the most recent activity shows first.
-- ------------------------------------------------------------
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


-- ============================================================
-- SECTION 6: USER ROLES AND PRIVILEGES
-- MySQL roles let us group privileges and assign them to users.
-- Instead of granting privileges one-by-one to every user,
-- we grant to the ROLE, then assign the role to users.
-- ============================================================

-- Drop roles if they already exist (for clean re-runs).
DROP ROLE IF EXISTS role_admin;
DROP ROLE IF EXISTS role_extension_worker;
DROP ROLE IF EXISTS role_nursery_operator;
DROP ROLE IF EXISTS role_farmer;

-- Create the four roles.
CREATE ROLE role_admin;
CREATE ROLE role_extension_worker;
CREATE ROLE role_nursery_operator;
CREATE ROLE role_farmer;

-- ── role_admin ──────────────────────────────────────────────
-- Admin gets ALL privileges on the entire database.
-- They can SELECT, INSERT, UPDATE, DELETE anything.
GRANT ALL PRIVILEGES ON agri_coffee_db.* TO role_admin;

-- ── role_extension_worker ───────────────────────────────────
-- Extension workers are read-only. They can only SELECT from
-- the views assigned to their role. No access to base tables.
GRANT SELECT ON agri_coffee_db.vw_extension_worker_farmers     TO role_extension_worker;
GRANT SELECT ON agri_coffee_db.vw_harvest_compliance_report    TO role_extension_worker;
GRANT SELECT ON agri_coffee_db.vw_distribution_report          TO role_extension_worker;

-- ── role_nursery_operator ────────────────────────────────────
-- Nursery operators can manage their own seedling batches
-- and view stock/license information. No farmer data access.
GRANT SELECT, INSERT, UPDATE ON agri_coffee_db.SeedlingBatch       TO role_nursery_operator;
GRANT SELECT ON agri_coffee_db.vw_nursery_operator_stock           TO role_nursery_operator;
GRANT SELECT ON agri_coffee_db.vw_nursery_license_status           TO role_nursery_operator;

-- ── role_farmer ──────────────────────────────────────────────
-- Farmers can only read their own data through the self-view.
GRANT SELECT ON agri_coffee_db.vw_farmer_self_view                 TO role_farmer;


-- Drop users if they already exist (for clean re-runs).
DROP USER IF EXISTS 'admin_user'@'localhost';
DROP USER IF EXISTS 'worker_user'@'localhost';
DROP USER IF EXISTS 'nursery_user'@'localhost';
DROP USER IF EXISTS 'farmer_user'@'localhost';

-- Create the four user accounts with strong passwords.
-- Change these passwords before deploying to a real server.
CREATE USER 'admin_user'@'localhost'   IDENTIFIED BY 'Admin@Secure2025!';
CREATE USER 'worker_user'@'localhost'  IDENTIFIED BY 'Worker@Secure2025!';
CREATE USER 'nursery_user'@'localhost' IDENTIFIED BY 'Nursery@Secure2025!';
CREATE USER 'farmer_user'@'localhost'  IDENTIFIED BY 'Farmer@Secure2025!';

-- Assign each user their role.
GRANT role_admin             TO 'admin_user'@'localhost';
GRANT role_extension_worker  TO 'worker_user'@'localhost';
GRANT role_nursery_operator  TO 'nursery_user'@'localhost';
GRANT role_farmer            TO 'farmer_user'@'localhost';

-- Set the default active role for each user so they do not
-- need to manually activate the role each time they log in.
SET DEFAULT ROLE role_admin            FOR 'admin_user'@'localhost';
SET DEFAULT ROLE role_extension_worker FOR 'worker_user'@'localhost';
SET DEFAULT ROLE role_nursery_operator FOR 'nursery_user'@'localhost';
SET DEFAULT ROLE role_farmer           FOR 'farmer_user'@'localhost';

-- Apply all privilege changes immediately.
FLUSH PRIVILEGES;


-- ============================================================
-- SECTION 7: SAMPLE DATA
-- We insert realistic data for Uganda coffee context.
-- Order matters: parent tables must be filled before child tables.
-- ============================================================

-- ── Districts ────────────────────────────────────────────────
INSERT INTO District (DistrictName) VALUES
    ('Masaka'),
    ('Mbarara'),
    ('Kampala');

-- ── Villages (2 per district) ────────────────────────────────
INSERT INTO Village (VillageName, ParishName, DistrictID) VALUES
    ('Kyotera',     'Kyotera Parish',    1),  -- Masaka villages
    ('Bukakata',    'Bukakata Parish',   1),
    ('Nyakayojo',   'Kakiika Parish',    2),  -- Mbarara villages
    ('Rubindi',     'Rubindi Parish',    2),
    ('Kasangati',   'Wakiso Parish',     3),  -- Kampala villages
    ('Nansana',     'Nansana Parish',    3);

-- ── Stakeholders (general info for all 6 people) ─────────────
INSERT INTO Stakeholder (NationalID, FullName, Gender, Phone) VALUES
    ('CM90011001A', 'Apio Grace',       'Female', '0772100001'),  -- Farmer 1
    ('CM90022002B', 'Otieno James',     'Male',   '0772100002'),  -- Farmer 2
    ('CM90033003C', 'Nakato Harriet',   'Female', '0772100003'),  -- Farmer 3
    ('CM90044004D', 'Mugisha Ronald',   'Male',   '0772100004'),  -- Extension Worker
    ('CM90055005E', 'Ssemakula Fred',   'Male',   '0772100005'),  -- Nursery Operator
    ('CM90066006F', 'Namukasa Joan',    'Female', '0772100006');  -- Ministry Admin

-- ── Farmer subclass rows ──────────────────────────────────────
INSERT INTO Farmer (StakeholderID, HouseholdSize, LiteracyLevel, TotalAcreage) VALUES
    (1, 5, 'Primary',   3.00),   -- Apio Grace owns 3 acres
    (2, 4, 'Secondary', 5.50),   -- Otieno James owns 5.5 acres
    (3, 6, 'Primary',   2.00);   -- Nakato Harriet owns 2 acres

-- ── ExtensionWorker subclass row ─────────────────────────────
INSERT INTO ExtensionWorker (StakeholderID, Qualification, Rank, DistrictID) VALUES
    (4, 'BSc Agriculture', 'Senior Field Officer', 1);  -- Assigned to Masaka

-- ── NurseryOperator subclass row ─────────────────────────────
INSERT INTO NurseryOperator (StakeholderID, LicenseNumber, NurseryCapacity, LicenseExpiry) VALUES
    (5, 'NL-2025-0042', 50000, '2026-12-31');  -- License valid until end of 2026

-- ── MinistryAdmin subclass row ───────────────────────────────
INSERT INTO MinistryAdmin (StakeholderID, Department, PermissionLevel) VALUES
    (6, 'Crop Production and Marketing', 2);  -- Super admin (level 2)

-- ── Nurseries ────────────────────────────────────────────────
INSERT INTO Nursery (OperatorID, NurseryName, Location, DistrictID) VALUES
    (5, 'Ssemakula Coffee Nursery A', 'Masaka Road, Km 12',  1),  -- In Masaka
    (5, 'Ssemakula Coffee Nursery B', 'Mbarara Industrial',  2);  -- In Mbarara

-- ── Seedling Batches (3 per nursery, mixed certification) ────
INSERT INTO SeedlingBatch (NurseryID, Variety, QuantityAvailable, CertifiedStatus, CertDate) VALUES
    (1, 'Robusta Clone 1', 10000, 'Yes', '2025-04-15'),  -- Certified
    (1, 'Robusta Clone 2',  8000, 'Yes', '2025-04-20'),  -- Certified
    (1, 'Arabica SL14',     5000, 'No',  NULL),           -- Not yet certified
    (2, 'Robusta Clone 1', 12000, 'Yes', '2025-05-01'),  -- Certified
    (2, 'Arabica SL28',     3000, 'Yes', '2025-05-10'),  -- Certified
    (2, 'Arabica SL14',     6000, 'No',  NULL);           -- Not yet certified

-- ── Extension Providers ──────────────────────────────────────
INSERT INTO ExtensionProvider (ProviderType) VALUES
    ('Government'),  -- ProviderID = 1
    ('NGO');         -- ProviderID = 2

INSERT INTO GovernmentDept (ProviderID, DeptName, MinistryBranch) VALUES
    (1, 'Directorate of Crop Resources', 'Ministry of Agriculture');

INSERT INTO NGO (ProviderID, NGOName, RegistrationNumber) VALUES
    (2, 'Uganda Coffee Farmers Alliance', 'NGO-REG-2019-4421');

-- ── Plots (5 plots across the 3 farmers) ─────────────────────
INSERT INTO Plot (FarmerID, GPSLat, GPSLong, AreaHectares, SoilType, VillageID) VALUES
    (1, -0.4023000, 31.7340000, 1.50, 'Loam',       1),  -- Apio: Plot 1
    (1, -0.4028500, 31.7350000, 1.00, 'Clay Loam',  2),  -- Apio: Plot 2
    (2, -0.6052000, 30.6540000, 2.50, 'Sandy Loam', 3),  -- Otieno: Plot 3
    (2, -0.6058000, 30.6550000, 3.00, 'Loam',       4),  -- Otieno: Plot 4
    (3, 0.3990000,  32.5650000, 2.00, 'Red Earth',  5);  -- Nakato: Plot 5

-- ── Harvest Records ──────────────────────────────────────────
-- We include one record with MoistureLevel at max (12.5%) and
-- one that would fail (we use 12.5 as the cap; the CHECK blocks > 12.5).
INSERT INTO HarvestRecord
    (PlotID, SeasonYear, QuantityKg, ProcessingMethod, MoistureLevel, HarvestDate) VALUES
    (1, 2024, 1200.00, 'Washed',  11.2, '2024-11-05'),  -- Good harvest
    (2, 2024,  800.00, 'Natural', 12.0, '2024-11-10'),  -- Fine — within limit
    (3, 2024, 2500.00, 'Washed',  10.8, '2024-11-15'),  -- Excellent
    (4, 2024, 3100.00, 'Honey',   12.5, '2024-11-20'),  -- Exactly at limit
    (5, 2024, 1900.00, 'Washed',  11.5, '2024-11-25'),  -- Good
    (1, 2023,  950.00, 'Natural', 12.3, '2023-10-30');  -- Previous season record

-- ── Distributions (4 records — all in season: June–August) ───
-- Trigger T1 will validate certification and acreage limits.
-- Trigger T2 will reduce QuantityAvailable automatically.
INSERT INTO Distribution (BatchID, FarmerID, QuantityGiven, DistributionDate) VALUES
    (1, 1, 2000, '2025-06-15'),  -- Apio gets 2000 from Batch 1 (she has 3 acres → max 3000)
    (2, 2, 4000, '2025-07-01'),  -- Otieno gets 4000 from Batch 2 (5.5 acres → max 5500)
    (4, 3, 1500, '2025-07-20'),  -- Nakato gets 1500 from Batch 4 (2 acres → max 2000)
    (5, 1, 500,  '2025-08-10');  -- Apio gets 500 more from Batch 5


-- ============================================================
-- SECTION 8: BACKUP AND RECOVERY STRATEGY
-- ============================================================
--
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
--   Keep at least 7 days of backups before overwriting old ones.
--
-- ============================================================
-- END OF agri_coffee_db.sql
-- Agricultural Services Database | Uganda Christian University
-- ============================================================