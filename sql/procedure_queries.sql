-- Please follow the format of the example below.

--- Copy the question as the comment
--- write some sql code to answer the question
--- add a comment with some insights about data and maybe some recommendations for how to build ui to represent the data
--- We only need insights for the ui for like 5-10 questions. the rest can just be sql

-- Question: What is the average cost of roof and wall construction materials for buildings located in a selected region?
-- Input is the desired census region (ex. West)
DROP FUNCTION IF EXISTS get_avg_costs_for_census_region();
CREATE OR REPLACE FUNCTION get_avg_costs_for_census_region()
RETURNS TABLE (
    census_region varchar(255),
    avg_roof_cost_in_USD_per_sqft numeric,
    avg_wall_cost_in_USD_per_sqft numeric
)
AS $$
BEGIN
        RETURN QUERY
        SELECT
            cr.label as census_region,
            ROUND(AVG(rcm.average_cost),2) AS avg_roof_cost_in_USD_per_sqft,
            ROUND(AVG(wcm.average_cost),2) AS avg_wall_cost_in_USD_per_sqft
        FROM
            buildings b
        JOIN
            census_regions cr ON b.census_region = cr.id
        JOIN
            roof_construction_materials rcm ON b.roof_construction_material_id = rcm.id
        JOIN
            wall_construction_materials wcm ON b.wall_construction_material_id = wcm.id
        GROUP BY
            cr.label;

END;
$$ LANGUAGE plpgsql;

-- Question: How does the average annual electricity and natural gas consumption compare across different principal building activities and building owner types?
-- Input is the principal building activity / industry
DROP FUNCTION IF EXISTS get_avg_energy_consumption_for_industry();
CREATE OR REPLACE FUNCTION get_avg_energy_consumption_for_industry()
RETURNS TABLE (
    building_activity varchar(255),
    avg_electricity_consumption_in_thousands_btu numeric,
    avg_natural_gas_consumption_in_thousands_btu numeric
)
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.label as building_activity,
        ROUND(AVG(ae.electricity_consumption_thous_btu::numeric),2) AS avg_electricity_consumption_in_thousands_btu,
        ROUND(AVG(ae.natural_gas_consumption_thous_btu::numeric),2) AS avg_natural_gas_consumption_in_thousands_btu
    FROM
        buildings b
    JOIN
        principal_building_activity p ON b.principal_building_activity = p.id
    LEFT JOIN
        annual_energy_consumption ae ON b.id = ae.building_id
    GROUP BY
        p.label
    ORDER BY building_activity;
END;
$$ LANGUAGE plpgsql;

-- Grouped by building owner type
DROP FUNCTION IF EXISTS get_avg_energy_consumption_for_owner_type();
CREATE OR REPLACE FUNCTION get_avg_energy_consumption_for_owner_type()
RETURNS TABLE (
    owner_type  varchar(255),
    avg_electricity_consumption_in_thousands_btu numeric,
    avg_natural_gas_consumption_in_thousands_btu numeric
)
AS $$
BEGIN
    RETURN QUERY
    SELECT
        bot.label as owner_type,
        ROUND(AVG(aec.electricity_consumption_thous_btu),2) AS avg_electricity_consumption_in_thousands_btu,
        ROUND(AVG(aec.natural_gas_consumption_thous_btu),2) AS avg_natural_gas_consumption_in_thousands_btu
    FROM
        buildings b
    JOIN
        building_owner_type bot ON b.building_owner_type = bot.id
    JOIN
        annual_energy_consumption aec ON b.id = aec.building_id
    GROUP BY
        bot.label
    order by owner_type;
END;
$$ LANGUAGE plpgsql;


-- Question: What is the average electricity and natural gas consumption for buildings that have undergone specific types of renovations (like HVAC equipment upgrade, insulation upgrade) compared to those that haven't?
-- Input is whether one is querying for either comparisons involving HVAC Upgrade, Insulation Upgrade, or Fire Safety Upgrade
DROP FUNCTION IF EXISTS get_avg_energy_consumption_for_renovation_options(BOOLEAN, BOOLEAN, BOOLEAN);
CREATE OR REPLACE FUNCTION get_avg_energy_consumption_for_renovation_options()
RETURNS TABLE (
    renovation_status VARCHAR(50),
    hvac_equip_upgrade BOOLEAN,
    fire_safety_upgrade BOOLEAN,
    insulation_upgrade BOOLEAN,
    avg_electricity_consumption_in_thousands_btu numeric,
    avg_natural_gas_consumption_in_thousands_btu numeric
)
AS $$
BEGIN
    RETURN QUERY
    SELECT
        CASE
            WHEN r.building_id IS NOT NULL THEN 'With Renovation'::VARCHAR(50)
            ELSE 'Without Renovation'::VARCHAR(50)
        END AS renovation_status,
        r.hvac_equip_upgrade,
        r.fire_safety_upgrade,
        r.insulation_upgrade,
        AVG(aec.electricity_consumption_thous_btu) AS avg_electricity_consumption_in_thousands_btu,
        AVG(aec.natural_gas_consumption_thous_btu) AS avg_natural_gas_consumption_in_thousands_btu
    FROM
        annual_energy_consumption aec
    LEFT JOIN
        renovations_since_2000 r
    ON
        aec.building_id = r.building_id
        AND (
            ( r.hvac_equip_upgrade = TRUE)
            OR ( r.insulation_upgrade = TRUE)
            OR ( r.fire_safety_upgrade = TRUE)
        )
    GROUP BY
        renovation_status, r.hvac_equip_upgrade, r.insulation_upgrade, r.fire_safety_upgrade
    ORDER BY renovation_status, r.hvac_equip_upgrade,r.insulation_upgrade, r.fire_safety_upgrade desc;
END;
$$ LANGUAGE plpgsql;

-- Question: What is the average electricity consumption per square foot for buildings, categorized by their construction year range? Usage type?
-- Query was broken into two parts, one for Construction Year Range, another for Usage Type
-- Input is the construction year category
DROP FUNCTION IF EXISTS get_avg_electricity_per_sqft_by_construction_year();
CREATE OR REPLACE FUNCTION get_avg_electricity_per_sqft_by_construction_year()
RETURNS TABLE (
    construction_year_range VARCHAR(50),
    avg_electricity_in_thousands_btu_per_sqft numeric
)
AS $$
BEGIN
    RETURN QUERY
    SELECT
        CASE
            WHEN b.year_of_construction_category = 2 THEN 'Before 1946'::VARCHAR(50)
            WHEN b.year_of_construction_category = 3 THEN '1946-1959'::VARCHAR(50)
            WHEN b.year_of_construction_category = 4 THEN '1960-1969'::VARCHAR(50)
            WHEN b.year_of_construction_category = 5 THEN '1970-1979'::VARCHAR(50)
            WHEN b.year_of_construction_category = 6 THEN '1980-1989'::VARCHAR(50)
            WHEN b.year_of_construction_category = 7 THEN '1990-1999'::VARCHAR(50)
            WHEN b.year_of_construction_category = 8 THEN '2000-2012'::VARCHAR(50)
            WHEN b.year_of_construction_category = 9 THEN '2013-2018'::VARCHAR(50)
            ELSE 'Unknown'::VARCHAR(50)
        END AS construction_year_range,
        ROUND(AVG(aec.electricity_consumption_thous_btu / b.square_footage),2) AS avg_electricity_in_thousands_btu_per_sqft
    FROM
        buildings b
    JOIN
        annual_energy_consumption aec ON b.id = aec.building_id
    GROUP BY
        year_of_construction_category
    ORDER BY year_of_construction_category;
END;
$$ LANGUAGE plpgsql;

-- Input is principal building activity
DROP FUNCTION IF EXISTS get_avg_electricity_per_sqft_by_building_activity();
CREATE OR REPLACE FUNCTION get_avg_electricity_per_sqft_by_building_activity()
RETURNS TABLE (
    principal_building_activity VARCHAR(255),
    avg_electricity_in_thousands_btu_per_sqft numeric
)
AS $$
BEGIN
    RETURN QUERY
    SELECT
        pb.label AS principal_building_activity,
        ROUND(AVG(aec.electricity_consumption_thous_btu / b.square_footage),2) AS avg_electricity_in_thousands_btu_per_sqft
    FROM
        buildings b
    JOIN
        annual_energy_consumption aec ON b.id = aec.building_id
    JOIN
        principal_building_activity pb ON b.principal_building_activity = pb.id
    GROUP BY
        pb.label;
END;
$$ LANGUAGE plpgsql;

-- Question: What is the average electricity, natural electricity expenditure, natural gas consumption, and natural gas expenditure for buildings that have escalators and elevators compared to those that don't?
-- Create or replace the function
DROP FUNCTION IF EXISTS calculate_avg_energy_consumption();
CREATE OR REPLACE FUNCTION calculate_avg_energy_consumption()
RETURNS TABLE (
    building_type TEXT,
    avg_electricity_consumption_in_thousands_btu NUMERIC,
    avg_natural_gas_consumption_in_thousands_btu NUMERIC,
    avg_electricity_expenditure_in_USD NUMERIC,
    avg_natural_gas_expenditure_in_USD NUMERIC
)
AS $$
BEGIN
    RETURN QUERY
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
        BuildingEnergy.building_type,
        AVG(BuildingEnergy.electricity_consumption::numeric) AS avg_electricity_consumption_in_thousands_btu,
        AVG(BuildingEnergy.natural_gas_consumption::numeric) AS avg_natural_gas_consumption_in_thousands_btu,
        AVG(BuildingEnergy.electricity_expenditure::numeric) AS avg_electricity_expenditure_in_USD,
        AVG(BuildingEnergy.natural_gas_expenditure::numeric) AS avg_natural_gas_expenditure_in_USD
    FROM
        BuildingEnergy
    GROUP BY
        BuildingEnergy.building_type;
END;
$$ LANGUAGE plpgsql;

-- Question: Is there a correlation between the number of employees and electricity consumption in buildings?
DROP FUNCTION IF EXISTS get_avg_electricity_consumption_by_employee_category();
CREATE OR REPLACE FUNCTION get_avg_electricity_consumption_by_employee_category()
RETURNS TABLE (
    employee_category TEXT,
    avg_electricity_consumption_in_thousands_btu NUMERIC
)
AS $$
BEGIN
    RETURN QUERY
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
        BuildingEmployeeEnergy.employee_category,
        ROUND(AVG(BuildingEmployeeEnergy.electricity_consumption::numeric)) AS avg_electricity_consumption_in_thousands_btu
    FROM
        BuildingEmployeeEnergy
    GROUP BY
        BuildingEmployeeEnergy.employee_category
    ORDER BY
        BuildingEmployeeEnergy.employee_category;
END;
$$ LANGUAGE plpgsql;

-- Question: For buildings that receive significant daylight (>50% daylight shining on the building), how does their electricity consumption for lighting compare to those with less daylight?
DROP FUNCTION IF EXISTS calculate_daylight_statistics();
CREATE OR REPLACE FUNCTION calculate_daylight_statistics()
RETURNS TABLE (
    daylight_category TEXT,
    num_buildings BIGINT,
    avg_electricity_consumption_in_thousands_btu NUMERIC
)
AS $$
BEGIN
    RETURN QUERY
    WITH daylight_buildings AS (
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
    no_daylight_buildings AS (
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
        ROUND(AVG(ae.electricity_consumption_thous_btu)) AS avg_electricity_consumption_in_thousands_btu
    FROM
        daylight_buildings db
    LEFT JOIN
        annual_energy_consumption ae ON db.building_id = ae.building_id

    UNION

    SELECT
        'No Daylight' AS daylight_category,
        COUNT(*) AS num_buildings,
        ROUND(AVG(ae.electricity_consumption_thous_btu)) AS avg_electricity_consumption_in_thousands_btu
    FROM
        no_daylight_buildings ndb
    LEFT JOIN
        annual_energy_consumption ae ON ndb.building_id = ae.building_id;
END;
$$ LANGUAGE plpgsql;

-- Split up analysis to also look by census region
DROP FUNCTION IF EXISTS get_daylight_buildings_statistics_by_region();
CREATE OR REPLACE FUNCTION get_daylight_buildings_statistics_by_region()
RETURNS TABLE (
    daylight_category TEXT,
    census_region CHARACTER VARYING(255),
    num_buildings BIGINT,
    avg_electricity_consumption_in_thousands_btu NUMERIC
)
AS $$
BEGIN
    RETURN QUERY
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
        ROUND(AVG(ae.electricity_consumption_thous_btu)) AS avg_electricity_consumption_in_thousands_btu
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
        ROUND(AVG(ae.electricity_consumption_thous_btu)) AS avg_electricity_consumption_in_thousands_btu
    FROM
        NoDaylightBuildings ndb
    LEFT JOIN
        annual_energy_consumption ae ON ndb.building_id = ae.building_id
    GROUP BY
        ndb.census_region;
END;
$$ LANGUAGE plpgsql;

-- Question: Compare the energy consumption of buildings with different types of heating and cooling systems. Find heating and cooling efficiency (energy consumption per square foot) for each type of system.
-- Analysis for Heating Systems
DROP FUNCTION IF EXISTS get_avg_energy_consumption_by_heating_system();
CREATE OR REPLACE FUNCTION get_avg_energy_consumption_by_heating_system()
RETURNS TABLE (
    heating_system VARCHAR(255),
    avg_energy_consumption_in_thousands_btu_per_sqft NUMERIC
)
AS $$
BEGIN
    RETURN QUERY
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
        HeatingSystems.heating_system,
        ROUND(AVG(HeatingSystems.electricity_consumption / HeatingSystems.square_footage), 2) AS avg_energy_consumption_in_thousands_btu_per_sqft
    FROM
        HeatingSystems
    WHERE
        HeatingSystems.electricity_consumption IS NOT NULL
        AND HeatingSystems.square_footage IS NOT NULL
    GROUP BY
        HeatingSystems.heating_system
    ORDER BY
        avg_energy_consumption_in_thousands_btu_per_sqft;
END;
$$ LANGUAGE plpgsql;

-- Analysis for Cooling Systems
DROP FUNCTION IF EXISTS get_avg_energy_consumption_by_cooling_system();
CREATE OR REPLACE FUNCTION get_avg_energy_consumption_by_cooling_system()
RETURNS TABLE (
    cooling_system VARCHAR(255),
    avg_energy_consumption_in_thousands_btu_per_sqft NUMERIC
)
AS $$
BEGIN
    RETURN QUERY
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
        CoolingSystems.cooling_system,
        ROUND(AVG(CoolingSystems.electricity_consumption / CoolingSystems.square_footage), 2) AS avg_energy_consumption_in_thousands_btu_per_sqft
    FROM
        CoolingSystems
    WHERE
        CoolingSystems.electricity_consumption IS NOT NULL
        AND CoolingSystems.square_footage IS NOT NULL
    GROUP BY
        CoolingSystems.cooling_system
    ORDER BY
        avg_energy_consumption_in_thousands_btu_per_sqft;
END;
$$ LANGUAGE plpgsql;
-- Air conditioning equipment dominated at 313.75, while the next highest of fuel oil/diesel/kerosene chiller was 61

-- Question: What are the most common fuel types used for water heating in buildings across different census regions?
DROP FUNCTION IF EXISTS get_water_heating_system_statistics();
CREATE OR REPLACE FUNCTION get_water_heating_system_statistics()
RETURNS TABLE (
    census_region VARCHAR(255),
    water_heating_system TEXT,
    num_buildings BIGINT
)
AS $$
BEGIN
    RETURN QUERY
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
        WaterHeatingSystems.census_region,
        WaterHeatingSystems.water_heating_system,
        COUNT(WaterHeatingSystems.building_id) AS num_buildings
    FROM
        WaterHeatingSystems
    WHERE
        WaterHeatingSystems.water_heating_system IS NOT NULL
    GROUP BY
        WaterHeatingSystems.census_region,
        WaterHeatingSystems.water_heating_system
    ORDER BY
        WaterHeatingSystems.census_region,
        num_buildings DESC;
END;
$$ LANGUAGE plpgsql;

-- Question: Analyze how different window types (e.g., tinted, reflective) affect heating and cooling energy consumption.
DROP FUNCTION IF EXISTS get_window_energy_consumption_statistics();
CREATE OR REPLACE FUNCTION get_window_energy_consumption_statistics()
RETURNS TABLE (
    window_type VARCHAR(255),
    has_tinted_windows BOOLEAN,
    has_reflective_windows BOOLEAN,
    avg_electricity_consumption_in_thousands_btu NUMERIC,
    avg_natural_gas_consumption_in_thousands_btu NUMERIC
)
AS $$
BEGIN
    RETURN QUERY
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
        WindowEnergyConsumption.window_type,
        WindowEnergyConsumption.has_tinted_windows,
        WindowEnergyConsumption.has_reflective_windows,
        AVG(WindowEnergyConsumption.electricity_consumption) AS avg_electricity_consumption_in_thousands_btu,
        AVG(WindowEnergyConsumption.natural_gas_consumption) AS avg_natural_gas_consumption_in_thousands_btu
    FROM
        WindowEnergyConsumption
    WHERE
        WindowEnergyConsumption.window_type IS NOT NULL
    GROUP BY
        WindowEnergyConsumption.window_type,
        WindowEnergyConsumption.has_tinted_windows,
        WindowEnergyConsumption.has_reflective_windows
    ORDER BY
        WindowEnergyConsumption.window_type;
END;
$$ LANGUAGE plpgsql;

-- Question: Evaluate the impact of various lighting technologies (LED, fluorescent, etc.) on a building's electricity consumption.
-- Buildings that utilized a certain lighting technology more than 50% of the time were categorized into using that lighting techology
DROP FUNCTION IF EXISTS get_lighting_category_energy_consumption();
CREATE OR REPLACE FUNCTION get_lighting_category_energy_consumption()
RETURNS TABLE (
    lighting_category TEXT,
    avg_electricity_consumption_in_thousands_btu NUMERIC
)
AS $$
BEGIN
    RETURN QUERY
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
        lc.lighting_category,
        AVG(lc.electricity_consumption) AS avg_electricity_consumption_in_thousands_btu
    FROM
        LightingCategories lc
    WHERE
        lc.lighting_category != 'Other' AND lc.electricity_consumption IS NOT NULL
    GROUP BY
        lc.lighting_category
    ORDER BY
        avg_electricity_consumption_in_thousands_btu DESC;
END;
$$ LANGUAGE plpgsql;

-- Question: How does energy consumption (electricity, natural gas) vary with the size of the building (square footage)? Does efficiency increase or decrease with building size?
-- Buildings were categorized into 8 categories based on square footage
DROP FUNCTION IF EXISTS get_building_size_energy_consumption();
CREATE OR REPLACE FUNCTION get_building_size_energy_consumption()
RETURNS TABLE (
    square_footage_category TEXT,
    avg_electricity_consumption_in_thousands_btu NUMERIC,
    avg_electricity_in_thousands_btu_per_sqft NUMERIC,
    avg_natural_gas_consumption_in_thousands_btu NUMERIC,
    avg_natural_gas_in_thousands_btu_per_sqft NUMERIC
)
AS $$
BEGIN
    RETURN QUERY
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
        BuildingSizeEnergyConsumption.square_footage_category,
        AVG(BuildingSizeEnergyConsumption.electricity_consumption) AS avg_electricity_consumption_in_thousands_btu,
        AVG(BuildingSizeEnergyConsumption.electricity_consumption) / SUM(BuildingSizeEnergyConsumption.square_footage) AS avg_electricity_in_thousands_btu_per_sqft,
        AVG(BuildingSizeEnergyConsumption.natural_gas_consumption) AS avg_natural_gas_consumption_in_thousands_btu,
        AVG(BuildingSizeEnergyConsumption.natural_gas_consumption) / SUM(BuildingSizeEnergyConsumption.square_footage) AS avg_natural_gas_in_thousands_btu_per_sqft
    FROM
        BuildingSizeEnergyConsumption
    WHERE
        BuildingSizeEnergyConsumption.square_footage_category != 'Other'
    GROUP BY
        BuildingSizeEnergyConsumption.square_footage_category
    ORDER BY
        avg_electricity_consumption_in_thousands_btu DESC;
END;
$$ LANGUAGE plpgsql;

-- Question: Does the year of construction affect the materials chosen for either roofs or walls?
-- Query was split into two parts, one for Roof Construction materials, one for Walls Construction materials
-- For Roof Construction
DROP FUNCTION IF EXISTS get_roof_construction_statistics_by_construction_year();
CREATE OR REPLACE FUNCTION get_roof_construction_statistics_by_construction_year()
RETURNS TABLE (
    construction_year_range TEXT,
    roof_material VARCHAR(255),
    building_count BIGINT,
    percentage NUMERIC
)
AS $$
BEGIN
    RETURN QUERY
    WITH RoofConstruction AS (
    SELECT
        b.id AS building_id,
        b.year_of_construction_category,
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
    RoofConstruction.construction_year_range,
    RoofConstruction.roof_material,
    COUNT(RoofConstruction.building_id) AS building_count,
    (COUNT(RoofConstruction.building_id) * 100.0 / SUM(COUNT(RoofConstruction.building_id)) OVER (PARTITION BY RoofConstruction.year_of_construction_category)) AS percentage
FROM
    RoofConstruction
GROUP BY
    RoofConstruction.year_of_construction_category, RoofConstruction.construction_year_range, RoofConstruction.roof_material
ORDER BY
    RoofConstruction.year_of_construction_category, building_count DESC;
END;
$$ LANGUAGE plpgsql;

-- For Wall Construction
DROP FUNCTION IF EXISTS get_wall_construction_statistics_by_construction_year();
CREATE OR REPLACE FUNCTION get_wall_construction_statistics_by_construction_year()
RETURNS TABLE (
    construction_year_range TEXT,
    wall_material VARCHAR(255),
    building_count BIGINT,
    percentage NUMERIC
)
AS $$
BEGIN
    RETURN QUERY
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
            wcm.wall_construction_material AS wall_material,
            b.year_of_construction_category
        FROM
            buildings b
        LEFT JOIN
            wall_construction_materials wcm ON b.wall_construction_material_id = wcm.id
    )
    SELECT
        WallConstruction.construction_year_range,
        WallConstruction.wall_material,
        COUNT(WallConstruction.building_id) AS building_count,
        (COUNT(WallConstruction.building_id) * 100.0 / SUM(COUNT(WallConstruction.building_id)) OVER (PARTITION BY WallConstruction.construction_year_range)) AS percentage
    FROM
        WallConstruction
    GROUP BY
        year_of_construction_category, WallConstruction.construction_year_range, WallConstruction.wall_material
    ORDER BY
       year_of_construction_category, WallConstruction.construction_year_range, building_count DESC;
END;
$$ LANGUAGE plpgsql;

-- Question: What are the most common types of air conditioning and heating systems used in buildings, and how do they correlate with building size and complex type?
-- Query was broken up into two parts, one for air conditioning, another for heating systems
-- For Air Conditioning Information
DROP FUNCTION IF EXISTS get_air_conditioning_statistics();
CREATE OR REPLACE FUNCTION get_air_conditioning_statistics()
RETURNS TABLE (
    complex_type VARCHAR(255),
    air_conditioning_type VARCHAR(255),
    building_count BIGINT,
    percentage_within_complex NUMERIC,
    avg_building_size_in_sqft NUMERIC
)
AS $$
BEGIN
    RETURN QUERY
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
        AirConditioningInformation.complex_type,
        AirConditioningInformation.air_conditioning_type,
        COUNT(AirConditioningInformation.building_id) AS building_count,
        (COUNT(AirConditioningInformation.building_id) * 100.0 / SUM(COUNT(AirConditioningInformation.building_id)) OVER (PARTITION BY AirConditioningInformation.complex_type)) AS percentage_within_complex,
        AVG(AirConditioningInformation.square_footage) AS avg_building_size_in_sqft
    FROM
        AirConditioningInformation
    GROUP BY
        AirConditioningInformation.complex_type, AirConditioningInformation.air_conditioning_type
    ORDER BY
        AirConditioningInformation.complex_type, building_count DESC;
END;
$$ LANGUAGE plpgsql;

-- For Heating Information
DROP FUNCTION IF EXISTS get_heating_statistics();
CREATE OR REPLACE FUNCTION get_heating_statistics()
RETURNS TABLE (
    complex_type VARCHAR(255),
    heating_type VARCHAR(255),
    building_count BIGINT,
    percentage_within_complex NUMERIC,
    avg_building_size_in_sqft NUMERIC
)
AS $$
BEGIN
    RETURN QUERY
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
        HeatingInformation.complex_type,
        HeatingInformation.heating_type,
        COUNT(HeatingInformation.building_id) AS building_count,
        (COUNT(HeatingInformation.building_id) * 100.0 / SUM(COUNT(HeatingInformation.building_id)) OVER (PARTITION BY HeatingInformation.complex_type)) AS percentage_within_complex,
        AVG(HeatingInformation.square_footage) AS avg_building_size_in_sqft
    FROM
        HeatingInformation
    GROUP BY
        HeatingInformation.complex_type, HeatingInformation.heating_type
    ORDER BY
        HeatingInformation.complex_type, building_count DESC;
END;
$$ LANGUAGE plpgsql;

-- Question: What are the most common roof and wall construction materials used in buildings owned by different types of entities (e.g., private, government, non-profit)?
-- Query was broken up into two parts, one for roof, another for wall
-- For Roof Construction
DROP FUNCTION IF EXISTS get_roof_construction_material_statistics_by_owner_type();
CREATE OR REPLACE FUNCTION get_roof_construction_material_statistics_by_owner_type()
RETURNS TABLE (
    owner_type VARCHAR(255),
    roof_material VARCHAR(255),
    percentage_within_owner_type NUMERIC
)
AS $$
BEGIN
    RETURN QUERY
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
        rcm.roof_material,
        (COUNT(rcm.building_id) * 100.0 / SUM(COUNT(rcm.building_id)) OVER (PARTITION BY bot.label)) AS percentage_within_owner_type
    FROM
        RoofConstructionMaterials rcm
    JOIN
        building_owner_type bot ON rcm.building_owner_type = bot.id
    GROUP BY
        bot.label, rcm.roof_material
    ORDER BY
        bot.label, percentage_within_owner_type DESC;
END;
$$ LANGUAGE plpgsql;

-- For wall construction
DROP FUNCTION IF EXISTS get_wall_construction_material_statistics_by_owner_type();
CREATE OR REPLACE FUNCTION get_wall_construction_material_statistics_by_owner_type()
RETURNS TABLE (
    owner_type VARCHAR(255),
    wall_material VARCHAR(255),
    building_count BIGINT,
    percentage_within_owner_type NUMERIC
)
AS $$
BEGIN
    RETURN QUERY
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
        wcm.wall_material,
        COUNT(wcm.building_id) AS building_count,
        (COUNT(wcm.building_id) * 100.0 / SUM(COUNT(wcm.building_id)) OVER (PARTITION BY bot.label)) AS percentage_within_owner_type
    FROM
        WallConstructionMaterials wcm
    JOIN
        building_owner_type bot ON wcm.building_owner_type = bot.id
    GROUP BY
        bot.label, wcm.wall_material
    ORDER BY
        bot.label, percentage_within_owner_type DESC;
END;
$$ LANGUAGE plpgsql;

-- Question: In buildings with food service facilities, how does the usage of natural gas and electricity vary compared to buildings without such facilities?
DROP FUNCTION IF EXISTS get_energy_consumption_for_food_service();
CREATE OR REPLACE FUNCTION get_energy_consumption_for_food_service()
RETURNS TABLE (
    facility_type TEXT,
    avg_electricity_consumption_in_thousands_btu NUMERIC,
    avg_natural_gas_consumption_in_thousands_btu NUMERIC
)
AS $$
BEGIN
    RETURN QUERY
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
        EnergyConsumption.facility_type,
        AVG(EnergyConsumption.electricity_consumption) AS avg_electricity_consumption_in_thousands_btu,
        AVG(EnergyConsumption.natural_gas_consumption) AS avg_natural_gas_consumption_in_thousands_btu
    FROM
        EnergyConsumption
    GROUP BY
        EnergyConsumption.facility_type;
END;
$$ LANGUAGE plpgsql;

-- Question: What is the average carbon output for different principal building activities across all fuel sources?
DROP FUNCTION IF EXISTS get_avg_carbon_output_by_building_activity();
CREATE OR REPLACE FUNCTION get_avg_carbon_output_by_building_activity()
RETURNS TABLE (
    building_activity VARCHAR(255),
    avg_carbon_output_in_gCO2e_per_kWh NUMERIC
)
AS $$
BEGIN
    RETURN QUERY
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
        CarbonByBuildingActivity.building_activity,
        AVG(CarbonByBuildingActivity.average_carbon_output) AS avg_carbon_output_in_gCO2e_per_kWh
    FROM
        CarbonByBuildingActivity
    GROUP BY
        CarbonByBuildingActivity.building_activity
    ORDER BY
        avg_carbon_output_in_gCO2e_per_kWh DESC;
END;
$$ LANGUAGE plpgsql;

-- Question: What is the average carbon output for buildings with elevators, buildings with escalators, buildings with both, and buildings with neither?
DROP FUNCTION IF EXISTS get_avg_carbon_output_by_accessibility_modes();
CREATE OR REPLACE FUNCTION get_avg_carbon_output_by_accessibility_modes()
RETURNS TABLE (
    accessibility_category TEXT,
    avg_carbon_output_in_gCO2e_per_kWh NUMERIC
)
AS $$
BEGIN
    RETURN QUERY
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
            WHEN CarbonByAccessibilityModes.number_of_elevators IS NOT NULL AND CarbonByAccessibilityModes.number_of_escalators IS NOT NULL THEN 'Buildings with Both'
            WHEN CarbonByAccessibilityModes.number_of_elevators IS NOT NULL THEN 'Buildings with Elevators'
            WHEN CarbonByAccessibilityModes.number_of_escalators IS NOT NULL THEN 'Buildings with Escalators'
            ELSE 'Buildings with Neither'
        END AS accessibility_category,
        AVG(CarbonByAccessibilityModes.average_carbon_output) AS avg_carbon_output_in_gCO2e_per_kWh
    FROM
        CarbonByAccessibilityModes
    GROUP BY
        accessibility_category
    ORDER BY
        avg_carbon_output_in_gCO2e_per_kWh DESC;
END;
$$ LANGUAGE plpgsql;

-- Question: What is the distribution of energy sources used in buildings across different census regions, and what is the percentage of each energy source within each census region?
DROP FUNCTION IF EXISTS get_consolidated_energy_source_usage();
CREATE OR REPLACE FUNCTION get_consolidated_energy_source_usage()
RETURNS TABLE (
    census_region VARCHAR(255),
    fuel_source_name VARCHAR(255),
    building_count BIGINT,
    percentage NUMERIC
)
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
$$ LANGUAGE plpgsql;

SELECT * FROM  get_consolidated_energy_source_usage();