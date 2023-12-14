-- Define roof_construction_material_cost table
DROP TABLE IF EXISTS roof_construction_materials;
CREATE TABLE roof_construction_materials (
    id INT PRIMARY KEY,
    roof_construction_material VARCHAR(255) NOT NULL,
    average_cost DECIMAL(5, 2) CHECK (average_cost >= 0),
    unit VARCHAR(255) NOT NULL
);

-- Define wall_construction_material_cost table
DROP TABLE IF EXISTS wall_construction_materials;
CREATE TABLE wall_construction_materials (
    id INT PRIMARY KEY,
    wall_construction_material VARCHAR(255) NOT NULL,
    average_cost DECIMAL(5, 2) CHECK (average_cost >= 0),
    unit VARCHAR(255) NOT NULL
);

--Define principal_building_activity table
DROP TABLE IF EXISTS principal_building_activity;
CREATE TABLE principal_building_activity (
    id INT PRIMARY KEY,
    label VARCHAR(255) NOT NULL --40
);

--Define census_region table
DROP TABLE IF EXISTS census_regions;
CREATE TABLE census_regions (
    id INT PRIMARY KEY,
    label VARCHAR(255) NOT NULL --2
);

--Define building_owner_type table
DROP TABLE IF EXISTS building_owner_type;
CREATE TABLE building_owner_type (
    id INT PRIMARY KEY,
    label VARCHAR(255) NOT NULL --62
);

--Define complex_type table
DROP TABLE IF EXISTS complex_type;
CREATE TABLE complex_type (
    id INT PRIMARY KEY,
    label VARCHAR(255) NOT NULL --52
);

--Define year_of_construction_category table
DROP TABLE IF EXISTS year_of_construction_category;
CREATE TABLE year_of_construction_category (
    id INT PRIMARY KEY, --22
    lower_bound INT NOT NULL,
    upper_bound INT NOT NULL
);

-- Define buildings table
DROP TABLE IF EXISTS buildings;
CREATE TABLE buildings (
    id INT PRIMARY KEY, -- 1
    census_region INT, -- 2
    principal_building_activity INT, -- 3
    building_owner_type INT, -- 62
    square_footage INT CHECK (square_footage >= 0), -- 6
    wall_construction_material_id INT, -- 8
    roof_construction_material_id INT, -- 9
    type_of_complex INT,  -- 52
    year_of_construction_category INT, -- 22
    FOREIGN KEY (roof_construction_material_id) REFERENCES roof_construction_materials(id) ON DELETE SET NULL,
    FOREIGN KEY (wall_construction_material_id) REFERENCES wall_construction_materials(id) ON DELETE SET NULL,
    FOREIGN KEY (principal_building_activity) REFERENCES principal_building_activity(id) ON DELETE SET NULL,
    FOREIGN KEY (census_region) REFERENCES census_regions(id) ON DELETE SET NULL,
    FOREIGN KEY (building_owner_type) REFERENCES building_owner_type(id) ON DELETE SET NULL,
    FOREIGN KEY (type_of_complex) REFERENCES complex_type(id) ON DELETE SET NULL,
    FOREIGN KEY (year_of_construction_category) REFERENCES year_of_construction_category(id) ON DELETE SET NULL
);

-- Define accessibility_modes table
DROP TABLE IF EXISTS accessibility_modes;
CREATE TABLE accessibility_modes (
    building_id INT PRIMARY KEY, --1
    number_of_floors VARCHAR(10), --14
    number_of_elevators VARCHAR(10), --19
    number_of_escalators VARCHAR(10), --21
    FOREIGN KEY (building_id) REFERENCES buildings(id) ON DELETE CASCADE
);

-- Define went_under_renovations table
DROP TABLE IF EXISTS renovations_since_2000;
CREATE TABLE renovations_since_2000 (
    building_id INT PRIMARY KEY , --1
    cosmetic_improvements BOOLEAN,--24
    addition_or_annex BOOLEAN, --25
    reduced_floorspace BOOLEAN, --26
    wall_reconfig BOOLEAN, --27
    roof_replace BOOLEAN, --28
    window_replace BOOLEAN, --29
    hvac_equip_upgrade BOOLEAN, --30
    lighting_upgrade BOOLEAN, --31
    plumbing_system_upgrade BOOLEAN, --32
    electrical_upgrade BOOLEAN, --33
    insulation_upgrade BOOLEAN, --34
    fire_safety_upgrade BOOLEAN, --35
    structural_upgrade BOOLEAN, --36
    other_renovations BOOLEAN, --37
    FOREIGN KEY (building_id) REFERENCES buildings(id) ON DELETE CASCADE
);

-- Define energy_consumption table
DROP TABLE IF EXISTS annual_energy_consumption;
CREATE TABLE annual_energy_consumption(
    building_id INT PRIMARY KEY, --1
    electricity_consumption_thous_btu INT CHECK (electricity_consumption_thous_btu >= 0), -- 567
    electricity_expenditure_USD INT CHECK (electricity_expenditure_USD >= 0), -- 569
    natural_gas_consumption_thous_btu INT CHECK (natural_gas_consumption_thous_btu >= 0), -- 570
    natural_gas_expenditure_USD INT CHECK (natural_gas_expenditure_USD >= 0), -- 572
    fuel_oil_consumption_thous_btu INT CHECK (fuel_oil_consumption_thous_btu >= 0), -- 573
    fuel_oil_expenditure_USD INT CHECK (fuel_oil_expenditure_USD >= 0), -- 574
    FOREIGN KEY (building_id) REFERENCES buildings(id) ON DELETE CASCADE
);

-- Define serves_food table
DROP TABLE IF EXISTS serves_food;
CREATE TABLE serves_food (
    building_id INT PRIMARY KEY, -- 1
    food_service_seating INT, --44
    drive_thru_window BOOLEAN, --45
    food_court BOOLEAN, --40
    FOREIGN KEY (building_id) REFERENCES buildings(id) ON DELETE CASCADE
);

-- Define schedule table
DROP TABLE IF EXISTS schedules;
CREATE TABLE schedules (
    building_id INT PRIMARY KEY, -- 1
    open_during_week BOOLEAN, --75
    open_on_weekend BOOLEAN, --76
    total_hours_open_per_week INT,--77
    number_of_employees INT, --79
    FOREIGN KEY (building_id) REFERENCES buildings(id) ON DELETE CASCADE
);

-- Define energy_sources table
DROP TABLE IF EXISTS energy_sources;
CREATE TABLE energy_sources (
    id SERIAL PRIMARY KEY,
    fuel_source VARCHAR(255),
    average_carbon_output DECIMAL(5, 1) CHECK (average_carbon_output >= 0),
    unit VARCHAR(255) NOT NULL
);

--DEFINE energy_sources_used
DROP TABLE IF EXISTS energy_sources_used;
CREATE TABLE energy_sources_used (
    id SERIAL PRIMARY KEY,
    building_id INT,
    energy_source INT, --88-98
    FOREIGN KEY (building_id) REFERENCES buildings (id) ON DELETE CASCADE,
    FOREIGN KEY (energy_source) REFERENCES energy_sources (id) ON DELETE CASCADE
);

--DEFINE MAIN_AIR_CONDITIONIG_TYPE
DROP TABLE IF EXISTS main_air_conditioning_type;
CREATE TABLE main_air_conditioning_type (
    id INT PRIMARY KEY,
    label VARCHAR(255) NOT NULL -- 365
);

--DEFINE MAIN_HEATING_EQUIPMENT
DROP TABLE IF EXISTS main_heating_equipment;
CREATE TABLE main_heating_equipment (
    id INT PRIMARY KEY,
    label VARCHAR(255) NOT NULL --293
);

-- Define air_conditioning_info table
DROP TABLE IF EXISTS heating_and_ac_info;
CREATE TABLE heating_and_ac_info
(
    building_id                       INT PRIMARY KEY , --1
    has_smart_thermostat BOOLEAN,  -- 371
    main_air_conditioning_type INT, -- 365
    main_heating_equipment_type INT, -- 293
    FOREIGN KEY (building_id) REFERENCES buildings (id) ON DELETE CASCADE,
    FOREIGN KEY (main_air_conditioning_type) REFERENCES main_air_conditioning_type(id),
    FOREIGN KEY (main_heating_equipment_type) REFERENCES main_heating_equipment(id)
);


-- Define water_heating_equipment
DROP TABLE IF EXISTS water_heating_equipment;
CREATE TABLE water_heating_equipment
(
    id                                INT PRIMARY KEY,
    label      VARCHAR(255) --389
);

-- Define water_heating_info
DROP TABLE IF EXISTS water_heating_info;
CREATE TABLE water_heating_info
(
    building_id                       INT PRIMARY KEY,
    electricity_used    BOOLEAN, --379
    natural_gas_used    BOOLEAN,
    fuel_oil_used       BOOLEAN,
    propane_used        BOOLEAN,
    district_steam_used BOOLEAN,
    district_hot_water_used BOOLEAN,
    wood_used           BOOLEAN,
    coal_used           BOOLEAN,
    solar_thermal_used  BOOLEAN,
    other_fuel_used     BOOLEAN, -- 388
    water_heating_equipment_type INT,
    FOREIGN KEY (building_id) REFERENCES buildings (id) ON DELETE CASCADE,
    FOREIGN KEY (water_heating_equipment_type) REFERENCES water_heating_equipment(id)
);

--define window_types
DROP TABLE IF EXISTS window_types;
CREATE TABLE window_types (
    id INT PRIMARY KEY,
    label VARCHAR(255) NOT NULL --556
);

-- Define window_information table
DROP TABLE IF EXISTS window_information;
CREATE TABLE window_information (
    building_id INT PRIMARY KEY, --1
    window_type INT, --556
    has_tinted_windows BOOLEAN, --557
    has_reflective_windows BOOLEAN, --558
    FOREIGN KEY (building_id) REFERENCES buildings(id) ON DELETE CASCADE,
    FOREIGN KEY (window_type) REFERENCES window_types(id)
);

-- Define lighting_information table
DROP TABLE IF EXISTS lighting_information; --538-545
CREATE TABLE lighting_information (
    building_id INT PRIMARY KEY, --1
    percent_fluorescent decimal(5, 2) check(percent_fluorescent >= 0 and percent_fluorescent <= 100),--538
    percent_compact_fluorescent decimal(5, 2) check(percent_compact_fluorescent >= 0 and percent_compact_fluorescent <= 100),
    percent_incandescent decimal(5, 2) check(percent_incandescent >= 0 and percent_incandescent <= 100),
    percent_HID decimal(5, 2) check(percent_HID >= 0 and percent_HID <= 100),
    percent_LED decimal(5, 2) check(percent_LED >= 0 and percent_LED <= 100),
    percent_other decimal(5, 2) check(percent_other >= 0 and percent_other <= 100),
    has_light_scheduling BOOLEAN,
    has_occupancy_sensors BOOLEAN,--546
    percent_building_receiving_enough_daylight decimal(5, 2) check(percent_building_receiving_enough_daylight >= 0 and percent_building_receiving_enough_daylight <= 100), --561
    percent_building_lit_when_open decimal(5, 2) check(percent_building_lit_when_open >= 0 and percent_building_lit_when_open <= 100), --525
    percent_building_lit_when_closed decimal(5, 2) check(percent_building_lit_when_closed >= 0 and percent_building_lit_when_closed <= 100), --523
    percent_time_lights_off decimal(5, 2) check(percent_time_lights_off >= 0 and percent_time_lights_off <= 100), --528
    FOREIGN KEY (building_id) REFERENCES buildings(id) ON DELETE CASCADE
);




