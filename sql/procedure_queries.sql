-- Please follow the format of the example below.

--- Copy the question as the comment
--- write some sql code to answer the question
--- add a comment with some insights about data and maybe some recommendations for how to build ui to represent the data
--- We only need insights for the ui for like 5-10 questions. the rest can just be sql

-- Question: What is the average cost of roof and wall construction materials for buildings located in a selected region?
-- Input is the desired census region (ex. West)
DELIMITER //

CREATE PROCEDURE GetAvgCostsForCensusRegion(IN pCensusRegion VARCHAR(255))
BEGIN
    DECLARE validRegion BOOLEAN;
    -- Check if the input census region is valid
    SET validRegion = FALSE;
    IF pCensusRegion IN ('West', 'South', 'Midwest', 'Northeast') THEN
        SET validRegion = TRUE;
    END IF;
    IF validRegion THEN
        -- If the region is valid, proceed with the query
        SELECT
            AVG(rcm.average_cost) AS avg_roof_cost,
            AVG(wcm.average_cost) AS avg_wall_cost
        FROM
            buildings b
        JOIN
            census_regions cr ON b.census_region = cr.id
        JOIN
            roof_construction_materials rcm ON b.roof_construction_material_id = rcm.id
        JOIN
            wall_construction_materials wcm ON b.wall_construction_material_id = wcm.id
        WHERE
            cr.label = pCensusRegion;
    ELSE
        -- If the region is not valid, return an error message or handle it as needed
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid census region. Please use one of the following: WEST, SOUTH, MIDWEST, NORTHEAST';
    END IF;
END //

DELIMITER ;

-- Question: How does the average annual electricity and natural gas consumption compare across different principal building activities and building owner types?
-- Input is the principal building activity / industry
DELIMITER //

CREATE PROCEDURE GetAvgEnergyConsumptionForIndustry(IN pIndustry VARCHAR(255))
BEGIN
    SELECT
        AVG(ae.electricity_consumption_thous_btu::numeric) AS avg_electricity_consumption,
        AVG(ae.natural_gas_consumption_thous_btu::numeric) AS avg_natural_gas_consumption
    FROM
        buildings b
    JOIN
        principal_building_activity p ON b.principal_building_activity = p.id
    LEFT JOIN
        annual_energy_consumption ae ON b.id = ae.building_id
    WHERE
        p.label = pIndustry
    GROUP BY
        p.label;
END //

DELIMITER ;

-- Grouped by building owner type
-- Input is the building owner type
DELIMITER //

CREATE PROCEDURE GetAvgEnergyConsumptionForOwnerType(IN pOwnerType VARCHAR(255))
BEGIN
    SELECT
        AVG(aec.electricity_consumption_thous_btu) AS avg_electricity_consumption,
        AVG(aec.natural_gas_consumption_thous_btu) AS avg_natural_gas_consumption
    FROM
        buildings b
    JOIN
        building_owner_type bot ON b.building_owner_type = bot.id
    JOIN
        annual_energy_consumption aec ON b.id = aec.building_id
    WHERE
        bot.label = pOwnerType
    GROUP BY
        bot.label;
END //

DELIMITER ;

-- Question: What is the average electricity and natural gas consumption for buildings that have undergone specific types of renovations (like HVAC equipment upgrade, insulation upgrade) compared to those that haven't?
-- Input is whether one is querying for either comparisons involving HVAC Upgrade, Insulation Upgrade, or Fire Safety Upgrade
DELIMITER //

CREATE PROCEDURE GetAvgEnergyConsumptionForRenovationOptions(
    IN pHVACUpgrade BOOLEAN,
    IN pInsulationUpgrade BOOLEAN,
    IN pFireSafetyUpgrade BOOLEAN
)
BEGIN
    SELECT
        CASE
            WHEN r.building_id IS NOT NULL THEN 'With Renovation'
            ELSE 'Without Renovation'
        END AS renovation_status,
        AVG(aec.electricity_consumption_thous_btu) AS avg_electricity_consumption,
        AVG(aec.natural_gas_consumption_thous_btu) AS avg_natural_gas_consumption
    FROM
        annual_energy_consumption aec
    LEFT JOIN
        renovations_since_2000 r
    ON
        aec.building_id = r.building_id
        AND (
            (pHVACUpgrade AND r.hvac_equip_upgrade = TRUE)
            OR (pInsulationUpgrade AND r.insulation_upgrade = TRUE)
            OR (pFireSafetyUpgrade AND r.fire_safety_upgrade = TRUE)
        )
    GROUP BY
        renovation_status;
END //

DELIMITER ;

-- Question: What is the average electricity consumption per square foot for buildings, categorized by their construction year range? Usage type?
-- Query was broken into two parts, one for Construction Year Range, another for Usage Type
-- Input is the construction year category 
DELIMITER //

CREATE PROCEDURE GetAvgElectricityPerSqftByConstructionYear(
    IN pConstructionYearCategory INT
)
BEGIN
    SELECT
        CASE
            WHEN b.year_of_construction_category = 2 THEN 'Before 1946'
            WHEN b.year_of_construction_category = 3 THEN '1946-1959'
            WHEN b.year_of_construction_category = 4 THEN '1960-1969'
            WHEN b.year_of_construction_category = 5 THEN '1970-1979'
            WHEN b.year_of_construction_category = 6 THEN '1980-1989'
            WHEN b.year_of_construction_category = 7 THEN '1990-1999'
            WHEN b.year_of_construction_category = 8 THEN '2000-2012'
            WHEN b.year_of_construction_category = 9 THEN '2013-2018'
            ELSE 'Unknown'
        END AS construction_year_range,
        AVG(aec.electricity_consumption_thous_btu / b.square_footage) AS avg_electricity_per_sqft
    FROM
        buildings b
    JOIN
        annual_energy_consumption aec ON b.id = aec.building_id
    WHERE
        b.year_of_construction_category = pConstructionYearCategory
    GROUP BY
        construction_year_range;
END //

DELIMITER ;

-- Input is principal building activity
DELIMITER //

CREATE PROCEDURE GetAvgElectricityPerSqftByBuildingActivity(
    IN pBuildingActivity VARCHAR(255)
)
BEGIN
    SELECT
        pb.label AS principal_building_activity,
        AVG(aec.electricity_consumption_thous_btu / b.square_footage) AS avg_electricity_per_sqft
    FROM
        buildings b
    JOIN
        annual_energy_consumption aec ON b.id = aec.building_id
    JOIN
        principal_building_activity pb ON b.principal_building_activity = pb.id
    WHERE
        pb.label = pBuildingActivity
    GROUP BY
        pb.label;
END //

DELIMITER ;

-- Question:  What is the average electricity, natural electricity expenditure, natural gas consumption, and natural gas expenditure for buildings that have escalators and elevators compared to those that don't?
DELIMITER //

CREATE PROCEDURE GetAvgEnergyDataByAccesibility()
BEGIN
    WITH BuildingEnergy AS (
        SELECT
            a.building_id,
            ae.electricity_consumption_thous_btu AS electricity_consumption,
            ae.electricity_expenditure_USD AS electricity_expenditure,
            ae.natural_gas_consumption_thous_btu AS natural_gas_consumption,
            ae.natural_gas_expenditure_USD AS natural_gas_expenditure,
            CASE
                WHEN a.number_of_elevators IS NOT NULL OR a.number_of_escalators IS NOT NULL THEN 'With Elevators/Escalators'
                ELSE 'Without Elevators/Escalators'
            END AS building_type
        FROM
            accessibility_modes a
        LEFT JOIN
            annual_energy_consumption ae ON a.building_id = ae.building_id
    )
    
    SELECT
        building_type,
        AVG(electricity_consumption::numeric) AS avg_electricity_consumption,
        AVG(natural_gas_consumption::numeric) AS avg_natural_gas_consumption,
        AVG(electricity_expenditure::numeric) AS avg_electricity_expenditure,
        AVG(natural_gas_expenditure::numeric) AS avg_natural_gas_expenditure
    FROM
        BuildingEnergy
    GROUP BY
        building_type;
END //

DELIMITER ;

-- Question: Is there a correlation between the number of employees and electricity consumption in buildings?
DELIMITER //

CREATE PROCEDURE GetAvgElectricityConsumptionByEmployeeCategory()
BEGIN
    WITH BuildingEmployeeEnergy AS (
        SELECT
            b.id AS building_id,
            CASE
                WHEN s.number_of_employees BETWEEN 0 AND 100 THEN '0-100'
                WHEN s.number_of_employees BETWEEN 101 AND 1000 THEN '101-1000'
                WHEN s.number_of_employees BETWEEN 1001 AND 5000 THEN '1001-5000'
                WHEN s.number_of_employees BETWEEN 5001 AND 10000 THEN '5001-10000'
                -- Add more categories as needed
                ELSE 'Over 10000'
            END AS employee_category,
            ae.electricity_consumption_thous_btu AS electricity_consumption
        FROM
            buildings b
        LEFT JOIN
            schedules s ON b.id = s.building_id
        LEFT JOIN
            annual_energy_consumption ae ON b.id = ae.building_id
    )  
    SELECT
        employee_category,
        ROUND(AVG(electricity_consumption::numeric)) AS avg_electricity_consumption
    FROM
        BuildingEmployeeEnergy
    GROUP BY
        employee_category
    ORDER BY
        employee_category;
END //

DELIMITER ;
-- With the output, maybe try to calculate the correlation coefficient with scipy?

-- Question: For buildings that receive significant daylight (>50% daylight shining on the building), how does their electricity consumption for lighting compare to those with less daylight?
DELIMITER //

CREATE PROCEDURE GetDaylightBuildingsStatistics()
BEGIN
    -- Daylight Buildings
    WITH DaylightBuildings AS (
        SELECT
            b.id AS building_id,
            li.percent_building_receiving_enough_daylight
        FROM
            buildings b
        LEFT JOIN
            lighting_information li ON b.id = li.building_id
        WHERE
            li.percent_building_receiving_enough_daylight IS NOT NULL
            AND li.percent_building_receiving_enough_daylight > 50
    ),
    NoDaylightBuildings AS (
        SELECT
            b.id AS building_id,
            li.percent_building_receiving_enough_daylight
        FROM
            buildings b
        LEFT JOIN
            lighting_information li ON b.id = li.building_id
        WHERE
            li.percent_building_receiving_enough_daylight IS NOT NULL
            AND li.percent_building_receiving_enough_daylight <= 50
    )
    
    SELECT
        'Daylight' AS daylight_category,
        COUNT(*) AS num_buildings,
        ROUND(AVG(ae.electricity_consumption_thous_btu)) AS avg_electricity_consumption
    FROM
        DaylightBuildings db
    LEFT JOIN
        annual_energy_consumption ae ON db.building_id = ae.building_id

    UNION

    SELECT
        'No Daylight' AS daylight_category,
        COUNT(*) AS num_buildings,
        ROUND(AVG(ae.electricity_consumption_thous_btu)) AS avg_electricity_consumption
    FROM
        NoDaylightBuildings ndb
    LEFT JOIN
        annual_energy_consumption ae ON ndb.building_id = ae.building_id;
END //

DELIMITER ;

DELIMITER //

-- Procedure was broken into census region
CREATE PROCEDURE GetDaylightBuildingsStatisticsByRegion()
BEGIN
    -- Daylight Buildings
    WITH DaylightBuildings AS (
        SELECT
            b.id AS building_id,
            cr.label AS census_region,
            li.percent_building_receiving_enough_daylight
        FROM
            buildings b
        LEFT JOIN
            lighting_information li ON b.id = li.building_id
        LEFT JOIN
            census_regions cr ON b.census_region = cr.id
        WHERE
            li.percent_building_receiving_enough_daylight IS NOT NULL
            AND li.percent_building_receiving_enough_daylight > 50
    ),
    NoDaylightBuildings AS (
        SELECT
            b.id AS building_id,
            cr.label AS census_region,
            li.percent_building_receiving_enough_daylight
        FROM
            buildings b
        LEFT JOIN
            lighting_information li ON b.id = li.building_id
        LEFT JOIN
            census_regions cr ON b.census_region = cr.id
        WHERE
            li.percent_building_receiving_enough_daylight IS NOT NULL
            AND li.percent_building_receiving_enough_daylight <= 50
    )
    
    SELECT
        'Daylight' AS daylight_category,
        db.census_region,
        COUNT(*) AS num_buildings,
        ROUND(AVG(ae.electricity_consumption_thous_btu)) AS avg_electricity_consumption
    FROM
        DaylightBuildings db
    LEFT JOIN
        annual_energy_consumption ae ON db.building_id = ae.building_id
    GROUP BY
        db.census_region

    UNION

    SELECT
        'No Daylight' AS daylight_category,
        ndb.census_region,
        COUNT(*) AS num_buildings,
        ROUND(AVG(ae.electricity_consumption_thous_btu)) AS avg_electricity_consumption
    FROM
        NoDaylightBuildings ndb
    LEFT JOIN
        annual_energy_consumption ae ON ndb.building_id = ae.building_id
    GROUP BY
        ndb.census_region;
END //

DELIMITER ;
-- I think you can do a double bar plot here

-- Question: Compare the energy consumption of buildings with different types of heating and cooling systems. Find heating and cooling efficiency (energy consumption per square foot) for each type of system.
-- Analysis for Heating Systems
DELIMITER //

CREATE PROCEDURE GetAvgEnergyConsumptionByHeatingSystem()
BEGIN
    -- Heating Systems
    WITH HeatingSystems AS (
        SELECT
            b.id AS building_id,
            heat.label AS heating_system,
            ae.electricity_consumption_thous_btu AS electricity_consumption,
            b.square_footage
        FROM
            buildings b
        LEFT JOIN
            heating_and_ac_info hact ON b.id = hact.building_id
        LEFT JOIN
            main_heating_equipment heat ON hact.main_heating_equipment_type = heat.id
        LEFT JOIN
            annual_energy_consumption ae ON b.id = ae.building_id
    )
    
    SELECT
        heating_system,
        ROUND(AVG(electricity_consumption / square_footage), 2) AS avg_energy_consumption_per_sqft
    FROM
        HeatingSystems
    WHERE
        electricity_consumption IS NOT NULL
        AND square_footage IS NOT NULL
    GROUP BY
        heating_system
    ORDER BY
        avg_energy_consumption_per_sqft;
END //

DELIMITER ;

-- Analysis for Cooling Systems
DELIMITER //

CREATE PROCEDURE GetAvgEnergyConsumptionByCoolingSystem()
BEGIN
    -- Cooling Systems
    WITH CoolingSystems AS (
        SELECT
            b.id AS building_id,
            mact.label AS cooling_system,
            ae.electricity_consumption_thous_btu AS electricity_consumption,
            b.square_footage
        FROM
            buildings b
        LEFT JOIN
            heating_and_ac_info hact ON b.id = hact.building_id
        LEFT JOIN
            main_air_conditioning_type mact ON hact.main_air_conditioning_type = mact.id
        LEFT JOIN
            annual_energy_consumption ae ON b.id = ae.building_id
    )
    SELECT
        cooling_system,
        ROUND(AVG(electricity_consumption / square_footage), 2) AS avg_energy_consumption_per_sqft
    FROM
        CoolingSystems
    WHERE
        electricity_consumption IS NOT NULL
        AND square_footage IS NOT NULL
    GROUP BY
        cooling_system
    ORDER BY
        avg_energy_consumption_per_sqft;
END //

DELIMITER ;
-- Air conditioning equipment dominated at 313.75, while the next highest of fuel oil/diesel/kerosene chiller was 61

-- Question: What are the most common fuel types used for water heating in buildings across different census regions?
DELIMITER //

CREATE PROCEDURE GetWaterHeatingSystemStatistics()
BEGIN
    -- Water Heating Systems
    WITH WaterHeatingSystems AS (
        SELECT
            b.id AS building_id,
            CASE
                WHEN wh.electricity_used THEN 'Electricity'
                WHEN wh.natural_gas_used THEN 'Natural Gas'
                WHEN wh.fuel_oil_used THEN 'Fuel Oil'
                WHEN wh.propane_used THEN 'Propane'
                WHEN wh.district_steam_used THEN 'District Steam'
                WHEN wh.district_hot_water_used THEN 'District Hot Water'
                WHEN wh.wood_used THEN 'Wood'
                WHEN wh.coal_used THEN 'Coal'
                WHEN wh.solar_thermal_used THEN 'Solar Thermal'
                WHEN wh.other_fuel_used THEN 'Other Fuel'
                ELSE 'Unknown'
            END AS water_heating_system,
            cr.label AS census_region
        FROM
            buildings b
        LEFT JOIN
            water_heating_info wh ON b.id = wh.building_id
        LEFT JOIN
            census_regions cr ON b.census_region = cr.id
    )
    SELECT
        census_region,
        water_heating_system,
        COUNT(building_id) AS num_buildings
    FROM
        WaterHeatingSystems
    WHERE
        water_heating_system IS NOT NULL
    GROUP BY
        census_region,
        water_heating_system
    ORDER BY
        census_region,
        num_buildings DESC;
END //

DELIMITER ;

-- Question: Analyze how different window types (e.g., tinted, reflective) affect heating and cooling energy consumption.
DELIMITER //

CREATE PROCEDURE GetWindowEnergyConsumptionStatistics()
BEGIN
    -- Window Energy Consumption
    WITH WindowEnergyConsumption AS (
        SELECT
            b.id AS building_id,
            wt.label AS window_type,
            winfo.has_tinted_windows,
            winfo.has_reflective_windows,
            ae.electricity_consumption_thous_btu AS electricity_consumption,
            ae.natural_gas_consumption_thous_btu AS natural_gas_consumption
        FROM
            buildings b
        LEFT JOIN
            window_information winfo ON b.id = winfo.building_id
        LEFT JOIN
            window_types wt ON winfo.window_type = wt.id
        LEFT JOIN
            annual_energy_consumption ae ON b.id = ae.building_id
    )
    SELECT
        window_type,
        has_tinted_windows,
        has_reflective_windows,
        AVG(electricity_consumption) AS avg_electricity_consumption,
        AVG(natural_gas_consumption) AS avg_natural_gas_consumption
    FROM
        WindowEnergyConsumption
    WHERE
        window_type IS NOT NULL
    GROUP BY
        window_type,
        has_tinted_windows,
        has_reflective_windows
    ORDER BY
        window_type;
END //

DELIMITER ;

-- Question: Evaluate the impact of various lighting technologies (LED, fluorescent, etc.) on a building's electricity consumption.
-- Buildings that utilized a certain lighting technology more than 50% of the time were categorized into using that lighting techology
DELIMITER //

CREATE PROCEDURE GetLightingCategoryEnergyConsumption()
BEGIN
    -- Lighting Categories
    WITH LightingCategories AS (
        SELECT
            b.id AS building_id,
            CASE
                WHEN li.percent_fluorescent > 50 THEN 'More than 50% lighting is fluorescent'
                WHEN li.percent_compact_fluorescent > 50 THEN 'More than 50% lighting is compact fluorescent'
                WHEN li.percent_incandescent > 50 THEN 'More than 50% lighting is incandescent'
                WHEN li.percent_halogen > 50 THEN 'More than 50% lighting is halogen'
                WHEN li.percent_HID > 50 THEN 'More than 50% lighting is HID'
                WHEN li.percent_LED > 50 THEN 'More than 50% lighting is LED'
                ELSE 'Other'
            END AS lighting_category,
            ae.electricity_consumption_thous_btu AS electricity_consumption
        FROM
            buildings b
        LEFT JOIN
            lighting_information li ON b.id = li.building_id
        LEFT JOIN
            annual_energy_consumption ae ON b.id = ae.building_id
    )
    SELECT
        lighting_category,
        AVG(electricity_consumption) AS avg_electricity_consumption
    FROM
        LightingCategories
    WHERE
        lighting_category != 'Other' AND electricity_consumption IS NOT NULL
    GROUP BY
        lighting_category
    ORDER BY
        avg_electricity_consumption DESC;
END //

DELIMITER ;
-- Buildings with lighting more than 50% coming from LED had the highest, which is interesting because I thought
-- LEDs were advertised as energy efficient. Maybe it is that such buildings are able to be open for longer and thus
-- consume larger amount of electricity.

-- Question: How does energy consumption (electricity, natural gas) vary with the size of the building (square footage)? Does efficiency increase or decrease with building size?
-- Buildings were categorized into 8 categories based on square footage
DELIMITER //

CREATE PROCEDURE GetBuildingSizeEnergyConsumption()
BEGIN
    -- Building Size Energy Consumption
    WITH BuildingSizeEnergyConsumption AS (
        SELECT
            b.id AS building_id,
            CASE
                WHEN b.square_footage BETWEEN 1 AND 999 THEN '<1000'
                WHEN b.square_footage BETWEEN 1000 AND 5000 THEN '1000-5000'
                WHEN b.square_footage BETWEEN 5001 AND 10000 THEN '5001-10000'
                WHEN b.square_footage BETWEEN 10001 AND 50000 THEN '10001-50000'
                WHEN b.square_footage BETWEEN 50001 AND 100000 THEN '50001-100000'
                WHEN b.square_footage BETWEEN 100001 AND 500000 THEN '100001-500000'
                WHEN b.square_footage BETWEEN 500001 AND 1000000 THEN '500001-1000000'
                WHEN b.square_footage > 1000000 THEN '1000000+'
                ELSE 'Other'
            END AS square_footage_category,
            ae.electricity_consumption_thous_btu AS electricity_consumption,
            ae.natural_gas_consumption_thous_btu AS natural_gas_consumption,
            b.square_footage AS square_footage
        FROM
            buildings b
        LEFT JOIN
            annual_energy_consumption ae ON b.id = ae.building_id
    )
    SELECT
        square_footage_category,
        AVG(electricity_consumption) AS avg_electricity_consumption,
        AVG(electricity_consumption) / SUM(square_footage) AS avg_electricity_per_sqft,
        AVG(natural_gas_consumption) AS avg_natural_gas_consumption,
        AVG(natural_gas_consumption) / SUM(square_footage) AS avg_natural_gas_per_sqft
    FROM
        BuildingSizeEnergyConsumption
    WHERE
        square_footage_category != 'Other'
    GROUP BY
        square_footage_category
    ORDER BY
       avg_electricity_consumption DESC;
END //

DELIMITER ;

-- Question: Does the year of construction affect the materials chosen for either roofs or walls?
-- Query was split into two parts, one for Roof Construction materials, one for Walls Construction materials
-- For Roof Construction
DELIMITER //

CREATE PROCEDURE GetRoofConstructionStatisticsByConstructionYear()
BEGIN
    -- Roof Construction
    WITH RoofConstruction AS (
        SELECT
            b.id AS building_id,
            CASE
                WHEN b.year_of_construction_category = 2 THEN 'Before 1946'
                WHEN b.year_of_construction_category = 3 THEN '1946-1959'
                WHEN b.year_of_construction_category = 4 THEN '1960-1969'
                WHEN b.year_of_construction_category = 5 THEN '1970-1979'
                WHEN b.year_of_construction_category = 6 THEN '1980-1989'
                WHEN b.year_of_construction_category = 7 THEN '1990-1999'
                WHEN b.year_of_construction_category = 8 THEN '2000-2012'
                WHEN b.year_of_construction_category = 9 THEN '2013-2018'
                ELSE 'Unknown'
            END AS construction_year_range,
            rcmt.roof_construction_material AS roof_material
        FROM
            buildings b
        LEFT JOIN
            roof_construction_materials rcmt ON b.roof_construction_material_id = rcmt.id
    )
    SELECT
        construction_year_range,
        roof_material,
        COUNT(building_id) AS building_count,
        (COUNT(building_id) * 100.0 / SUM(COUNT(building_id)) OVER (PARTITION BY construction_year_range)) AS percentage
    FROM
        RoofConstruction
    GROUP BY
        construction_year_range, roof_material
    ORDER BY
        construction_year_range, building_count DESC;
END //

DELIMITER ;

-- For Wall Construction
DELIMITER //

CREATE PROCEDURE GetWallConstructionStatisticsByConstructionYear()
BEGIN
    -- Wall Construction
    WITH WallConstruction AS (
        SELECT
            b.id AS building_id,
            CASE
                WHEN b.year_of_construction_category = 2 THEN 'Before 1946'
                WHEN b.year_of_construction_category = 3 THEN '1946-1959'
                WHEN b.year_of_construction_category = 4 THEN '1960-1969'
                WHEN b.year_of_construction_category = 5 THEN '1970-1979'
                WHEN b.year_of_construction_category = 6 THEN '1980-1989'
                WHEN b.year_of_construction_category = 7 THEN '1990-1999'
                WHEN b.year_of_construction_category = 8 THEN '2000-2012'
                WHEN b.year_of_construction_category = 9 THEN '2013-2018'
                ELSE 'Unknown'
            END AS construction_year_range,
            wcm.wall_construction_material AS wall_material
        FROM
            buildings b
        LEFT JOIN
            wall_construction_materials wcm ON b.wall_construction_material_id = wcm.id
    )
    SELECT
        construction_year_range,
        wall_material,
        COUNT(building_id) AS building_count,
        (COUNT(building_id) * 100.0 / SUM(COUNT(building_id)) OVER (PARTITION BY construction_year_range)) AS percentage
    FROM
        WallConstruction
    GROUP BY
        construction_year_range, wall_material
    ORDER BY
        construction_year_range, building_count DESC;
END //

DELIMITER ;

-- Question: What are the most common types of air conditioning and heating systems used in buildings, and how do they correlate with building size and complex type?
-- Query was broken up into two parts, one for air conditioning, another for heating systems
-- For Air Conditioning Information
DELIMITER //

CREATE PROCEDURE GetAirConditioningStatistics()
BEGIN
    -- Air Conditioning Information
    WITH AirConditioningInformation AS (
        SELECT
            b.id AS building_id,
            ainfo.has_smart_thermostat,
            mat.label AS air_conditioning_type,
            ct.label AS complex_type,
            b.square_footage
        FROM
            heating_and_ac_info ainfo
        JOIN
            main_air_conditioning_type mat ON ainfo.main_air_conditioning_type = mat.id
        JOIN
            buildings b ON ainfo.building_id = b.id
        LEFT JOIN
            complex_type ct ON b.type_of_complex = ct.id
        WHERE
            ct.label IS NOT NULL
    )
    
    SELECT
        complex_type,
        air_conditioning_type,
        COUNT(building_id) AS building_count,
        (COUNT(building_id) * 100.0 / SUM(COUNT(building_id)) OVER (PARTITION BY complex_type)) AS percentage_within_complex,
        AVG(square_footage) AS avg_building_size
    FROM
        AirConditioningInformation
    GROUP BY
        complex_type, air_conditioning_type
    ORDER BY
        complex_type, building_count DESC;
END //

DELIMITER ;

-- For Heating Information
DELIMITER //

CREATE PROCEDURE GetHeatingStatistics()
BEGIN
    -- Heating Information
    WITH HeatingInformation AS (
        SELECT
            b.id AS building_id,
            ainfo.has_smart_thermostat,
            mhet.label AS heating_type,
            ct.label AS complex_type,
            b.square_footage
        FROM
            heating_and_ac_info ainfo
        JOIN
            main_heating_equipment mhet ON ainfo.main_heating_equipment_type = mhet.id
        JOIN
            buildings b ON ainfo.building_id = b.id
        LEFT JOIN
            complex_type ct ON b.type_of_complex = ct.id
        WHERE
            ct.label IS NOT NULL
    )
    SELECT
        complex_type,
        heating_type,
        COUNT(building_id) AS building_count,
        (COUNT(building_id) * 100.0 / SUM(COUNT(building_id)) OVER (PARTITION BY complex_type)) AS percentage_within_complex,
        AVG(square_footage) AS avg_building_size
    FROM
        HeatingInformation
    GROUP BY
        complex_type, heating_type
    ORDER BY
        complex_type, building_count DESC;
END //

DELIMITER ;

-- Question: What are the most common roof and wall construction materials used in buildings owned by different types of entities (e.g., private, government, non-profit)?
-- Query was broken up into two parts, one for roof, another for wall
-- For Roof Construction
DELIMITER //

CREATE PROCEDURE GetRoofConstructionMaterialStatisticsByOwnerType()
BEGIN
    -- Roof Construction Materials
    WITH RoofConstructionMaterials AS (
        SELECT
            b.id AS building_id,
            b.building_owner_type,
            rcm.roof_construction_material AS roof_material
        FROM
            buildings b
        LEFT JOIN
            roof_construction_materials rcm ON b.roof_construction_material_id = rcm.id
    )
    SELECT
        bot.label AS owner_type,
        roof_material,
        (COUNT(building_id) * 100.0 / SUM(COUNT(building_id)) OVER (PARTITION BY bot.label)) AS percentage_within_owner_type
    FROM
        RoofConstructionMaterials rcm
    JOIN
        building_owner_type bot ON rcm.building_owner_type = bot.id
    GROUP BY
        bot.label, roof_material
    ORDER BY
        bot.label, percentage_within_owner_type DESC;
END //

DELIMITER ;
-- Private academic institutions loved Plastic, rubber, or synthetic sheeting

-- For wall construction 
DELIMITER //

CREATE PROCEDURE GetWallConstructionMaterialStatisticsByOwnerType()
BEGIN
    -- Wall Construction Materials
    WITH WallConstructionMaterials AS (
        SELECT
            b.id AS building_id,
            b.building_owner_type,
            wcm.wall_construction_material AS wall_material
        FROM
            buildings b
        LEFT JOIN
            wall_construction_materials wcm ON b.wall_construction_material_id = wcm.id
    )
    SELECT
        bot.label AS owner_type,
        wall_material,
        COUNT(building_id) AS building_count,
        (COUNT(building_id) * 100.0 / SUM(COUNT(building_id)) OVER (PARTITION BY bot.label)) AS percentage_within_owner_type
    FROM
        WallConstructionMaterials wcm
    JOIN
        building_owner_type bot ON wcm.building_owner_type = bot.id
    GROUP BY
        bot.label, wall_material
    ORDER BY
        bot.label, percentage_within_owner_type DESC;
END //

DELIMITER ;

-- Question: In buildings with food service facilities, how does the usage of natural gas and electricity vary compared to buildings without such facilities?
DELIMITER //

CREATE PROCEDURE GetEnergyConsumptionForFoodService()
BEGIN
    -- Energy Consumption
    WITH EnergyConsumption AS (
        SELECT
            b.id AS building_id,
            CASE
                WHEN b.principal_building_activity = 4 THEN 'With Food Service Facilities'
                ELSE 'Without Food Service Facilities'
            END AS facility_type,
            ae.electricity_consumption_thous_btu AS electricity_consumption,
            ae.natural_gas_consumption_thous_btu AS natural_gas_consumption
        FROM
            buildings b
        LEFT JOIN
            annual_energy_consumption ae ON b.id = ae.building_id
        WHERE
            b.principal_building_activity IN (4, 5) -- Assuming 4 represents buildings with food service facilities
    )
    SELECT
        facility_type,
        AVG(electricity_consumption) AS avg_electricity_consumption,
        AVG(natural_gas_consumption) AS avg_natural_gas_consumption
    FROM
        EnergyConsumption
    GROUP BY
        facility_type;
END //

DELIMITER ;

-- Question: What is the average carbon output for different principal building activities across all fuel sources?
DELIMITER //

CREATE PROCEDURE GetAvgCarbonOutputByBuildingActivity()
BEGIN
    -- Carbon By Building Activity
    WITH CarbonByBuildingActivity AS (
        SELECT
            b.id AS building_id,
            pba.label AS building_activity,
            es.fuel_source,
            es.average_carbon_output
        FROM
            energy_sources_used esu
        JOIN
            energy_sources es ON esu.energy_source = es.id
        JOIN
            buildings b ON esu.building_id = b.id
        JOIN
            principal_building_activity pba ON b.principal_building_activity = pba.id
    )
    SELECT
        building_activity,
        AVG(average_carbon_output) AS avg_carbon_output
    FROM
        CarbonByBuildingActivity
    GROUP BY
        building_activity
    ORDER BY
        avg_carbon_output DESC;
END //

DELIMITER ;

-- Question: What is the average carbon output for buildings with elevators, buildings with escalators, buildings with both, and buildings with neither?
DELIMITER //

CREATE PROCEDURE GetAvgCarbonOutputByAccessibilityModes()
BEGIN
    -- Carbon By Accessibility Modes
    WITH CarbonByAccessibilityModes AS (
        SELECT
            b.id AS building_id,
            am.number_of_elevators,
            am.number_of_escalators,
            es.fuel_source,
            es.average_carbon_output
        FROM
            energy_sources_used esu
        JOIN
            energy_sources es ON esu.energy_source = es.id
        JOIN
            buildings b ON esu.building_id = b.id
        LEFT JOIN
            accessibility_modes am ON b.id = am.building_id
    )
    SELECT
        CASE
            WHEN number_of_elevators IS NOT NULL AND number_of_escalators IS NOT NULL THEN 'Buildings with Both'
            WHEN number_of_elevators IS NOT NULL THEN 'Buildings with Elevators'
            WHEN number_of_escalators IS NOT NULL THEN 'Buildings with Escalators'
            ELSE 'Buildings with Neither'
        END AS accessibility_category,
        AVG(average_carbon_output) AS avg_carbon_output
    FROM
        CarbonByAccessibilityModes
    GROUP BY
        accessibility_category
    ORDER BY
        avg_carbon_output DESC;
END //

DELIMITER ;

-- Question: What is the distribution of energy sources used in buildings across different census regions, and what is the percentage of each energy source within each census region?
DROP FUNCTION IF EXISTS GetConsolidatedEnergySourceUsage;
CREATE OR REPLACE FUNCTION GetConsolidatedEnergySourceUsage()
RETURNS TABLE (
    census_region VARCHAR,
    fuel_source_name VARCHAR,
    building_count BIGINT,
    percentage NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH EnergySourceUsage AS (
        SELECT
            b.id AS building_id,
            esu.energy_source,
            cr.label AS census_region
        FROM
            energy_sources_used esu
        JOIN
            energy_sources es ON esu.energy_source = es.id
        JOIN
            buildings b ON esu.building_id = b.id
        JOIN
            census_regions cr ON b.census_region = cr.id
    )
    SELECT
        eu.census_region,
        es.fuel_source AS fuel_source_name,
        COUNT(DISTINCT eu.building_id) AS building_count,
        (COUNT(DISTINCT eu.building_id) * 100.0 / SUM(COUNT(DISTINCT eu.building_id)) OVER (PARTITION BY eu.census_region)) AS percentage
    FROM
        EnergySourceUsage eu
    JOIN
        energy_sources es ON eu.energy_source = es.id
    GROUP BY
        eu.census_region, es.fuel_source
    ORDER BY
        eu.census_region, building_count DESC;
END;
$$;




SELECT * FROM building_owner_type;

