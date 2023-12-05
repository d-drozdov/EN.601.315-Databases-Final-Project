-- Define RoofConstructionMaterialCost table
DROP TABLE RoofConstructionMaterialCost;
CREATE TABLE RoofConstructionMaterialCost (
    ID INT PRIMARY KEY,
    RoofConstructionMaterial VARCHAR(255) NOT NULL,
    AverageCost DECIMAL(5, 2) CHECK (AverageCost >= 0),
    AverageCarbonOutput DECIMAL(5, 2) CHECK (AverageCarbonOutput >= 0)
);

-- Define WallConstructionMaterialCost table
DROP TABLE WallConstructionMaterialCost;
CREATE TABLE WallConstructionMaterialCost (
    ID INT PRIMARY KEY,
    WallConstructionMaterial VARCHAR(255) NOT NULL,
    AverageCost DECIMAL(5, 2) CHECK (AverageCost >= 0),
    AverageCarbonOutput DECIMAL(5, 2) CHECK (AverageCarbonOutput >= 0)
);

-- Define Buildings table
DROP TABLE Buildings;
CREATE TABLE Buildings (
    ID INT PRIMARY KEY,
    CensusRegion VARCHAR(255) NOT NULL,
    CensusDivision VARCHAR(255) NOT NULL,
    PrincipalBuildingActivity VARCHAR(255) NOT NULL,
    PrivateOrPublic VARCHAR(255) NOT NULL,
    SquareFootage INT NOT NULL CHECK (SquareFootage >= 0),
    SquareFootageCategory VARCHAR(255) NOT NULL,
    WallConstructionMaterialID INT NOT NULL,
    RoofConstructionMaterialID INT NOT NULL,
    BuildingShape VARCHAR(255),
    TypeOfComplex VARCHAR(255),
    FOREIGN KEY (RoofConstructionMaterialID) REFERENCES RoofConstructionMaterialCost(ID),
    FOREIGN KEY (WallConstructionMaterialID) REFERENCES WallConstructionMaterialCost(ID)
);

-- Define AccessibilityModes table
DROP TABLE AccessibilityModes;
CREATE TABLE AccessibilityModes (
    ID INT PRIMARY KEY,
    BuildingID INT,
    NumberOfFloors INT CHECK (NumberOfFloors >= 0),
    NumberOfElevators INT CHECK (NumberOfElevators >= 0),
    NumberOfEscalators INT CHECK (NumberOfEscalators >= 0),
    FOREIGN KEY (BuildingID) REFERENCES Buildings(ID)
);

-- Define WentUnderRenovations table
DROP TABLE WentUnderRenovations;
CREATE TABLE WentUnderRenovations (
    ID INT PRIMARY KEY,
    BuildingID INT,
    YearOfConstructionCategory VARCHAR(255),
    Renovations VARCHAR(255),
    FOREIGN KEY (BuildingID) REFERENCES Buildings(ID)
);

-- Define MoreSpecificBuildingActivity table
DROP TABLE MoreSpecificBuildingActivity;
CREATE TABLE MoreSpecificBuildingActivity (
    ID INT PRIMARY KEY,
    BuildingID INT,
    SpecificBuildingID VARCHAR(255),
    FOREIGN KEY (BuildingID) REFERENCES Buildings(ID)
);

-- Define EnergyConsumption table
DROP TABLE EnergyConsumption;
CREATE TABLE EnergyConsumption (
    ID INT PRIMARY KEY,
    BuildingID INT,
    AnnualElectricityConsumption_kWh DECIMAL CHECK (AnnualElectricityConsumption_kWh >= 0),
    AnnualElectricityConsumption_BTU DECIMAL CHECK (AnnualElectricityConsumption_BTU >= 0),
    FOREIGN KEY (BuildingID) REFERENCES Buildings(ID)
);

-- Define OffersMedicalAssistance table
DROP TABLE OffersMedicalAssistance;
CREATE TABLE OffersMedicalAssistance (
    BuildingID INT PRIMARY KEY,
    LicensedInpatientBeds INT,
    LicensedNursingBeds INT,
    PercentOfOutpatientSpace DECIMAL(5, 2),
    FOREIGN KEY (BuildingID) REFERENCES Buildings(ID)
);

-- Define ServesFood table
DROP TABLE ServesFood;
CREATE TABLE ServesFood (
    ID INT PRIMARY KEY,
    BuildingID INT,
    FoodServiceSeating INT,
    DriveThruWindow BOOLEAN,
    FoodCourt BOOLEAN,
    FOREIGN KEY (BuildingID) REFERENCES Buildings(ID)
);

-- Define Schedule table
DROP TABLE Schedule;
CREATE TABLE Schedule (
    ID INT PRIMARY KEY,
    BuildingID INT,
    OpenDuringWeek BOOLEAN,
    OpenOnWeekend BOOLEAN,
    TotalHoursOpenPerWeek INT,
    NumberOfEmployees INT,
    NumberOfEmployeesCategory VARCHAR(255),
    FOREIGN KEY (BuildingID) REFERENCES Buildings(ID)
);

-- Define HeatingEnergyUsage table
DROP TABLE HeatingEnergyUsage;
CREATE TABLE HeatingEnergyUsage (
    ID INT PRIMARY KEY,
    BuildingID INT,
    EnergyUsedForMainHeating DECIMAL,
    EnergyUsedForSecondaryHeating DECIMAL,
    EnergyUsedForCooling DECIMAL,
    EnergySourceUsedID INT,
    FuelSourceUsedID INT,
    FOREIGN KEY (BuildingID) REFERENCES Buildings(ID),
    FOREIGN KEY (EnergySourceUsedID) REFERENCES CarbonOutputOfEnergy(ID),
    FOREIGN KEY (FuelSourceUsedID) REFERENCES CarbonOutputOfFuel(ID)
);

-- Define HasTypeOfHeatPump table
DROP TABLE HasTypeOfHeatPump;
CREATE TABLE HasTypeOfHeatPump (
    ID INT PRIMARY KEY,
    BuildingID INT,
    HeatPumpType VARCHAR(255),
    FOREIGN KEY (BuildingID) REFERENCES Buildings(ID)
);

-- Define PoweredAirConditioning table
DROP TABLE PoweredAirConditioning;
CREATE TABLE PoweredAirConditioning (
    ID INT PRIMARY KEY,
    BuildingID INT,
    PowerType VARCHAR(255),
    FOREIGN KEY (BuildingID) REFERENCES Buildings(ID)
);

-- Define CarbonOutputOfEnergy table
DROP TABLE CarbonOutputOfEnergy;
CREATE TABLE CarbonOutputOfEnergy (
    ID INT PRIMARY KEY,
    EnergySource VARCHAR(255),
    AverageCarbonOutput DECIMAL(5, 2) CHECK (AverageCarbonOutput >= 0)
);

-- Define CarbonOutputOfFuel table
DROP TABLE CarbonOutputOfFuel;
CREATE TABLE CarbonOutputOfFuel (
    ID INT PRIMARY KEY,
    FuelSource VARCHAR(255),
    AverageCarbonOutput DECIMAL(5, 2) CHECK (AverageCarbonOutput >= 0)
);

-- Define PoweredAppliances table
DROP TABLE PoweredAppliances;
CREATE TABLE PoweredAppliances (
    ID INT PRIMARY KEY,
    BuildingID INT,
    EnergySourceUsed VARCHAR(255),
    AppliancesPowered VARCHAR(255),
    FOREIGN KEY (BuildingID) REFERENCES Buildings(ID)
);

-- Define CookingEnergyUsed table
DROP TABLE CookingEnergyUsed;
CREATE TABLE CookingEnergyUsed (
    ID INT PRIMARY KEY,
    BuildingID INT,
    EnergySourceUsed VARCHAR(255),
    FOREIGN KEY (BuildingID) REFERENCES Buildings(ID)
);

-- Define PoweredAppliances table
DROP TABLE PoweredAppliances;
CREATE TABLE PoweredAppliances (
    ID INT PRIMARY KEY,
    BuildingID INT,
    EnergySourceUsed VARCHAR(255),
    AppliancesPowered VARCHAR(255),
    FOREIGN KEY (BuildingID) REFERENCES Buildings(ID)
);