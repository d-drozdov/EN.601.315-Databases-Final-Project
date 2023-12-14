import json
import os

import pandas as pd

CODEBOOK_VALUE_COLUMN_NAME = 'Values/Format codes'


def load_json_file(file_name: str) -> dict:
    current_directory = os.getcwd()
    file_path = os.path.join(current_directory, file_name)
    try:
        with open(file_path, 'r') as file:
            json_data = file.read()
        json_object = json.loads(json_data)
        return json_object
    except FileNotFoundError:
        print(f"File not found: {file_path}")
    except Exception as e:
        print(f"An error occurred: {e}")


def generate_insert_from_supp_info() -> str:
    file_name = "supplementary_info.json"
    json_object = load_json_file(file_name)
    all_stmts = ["--Insert into roof_construction_materials", "TRUNCATE TABLE roof_construction_materials CASCADE ;"]

    for id, value in json_object["roofMatAvg"].items():
        con_mat = value["name"]
        unit = value["unit"]
        cost = value["cost"]
        stmt = (f'insert into roof_construction_materials (id, roof_construction_material, average_cost, unit)\n'
                f'values {id, con_mat, cost, unit};\n')
        all_stmts.append(stmt)

    all_stmts.extend(["\n--Insert into wall_construction_materials", "TRUNCATE TABLE wall_construction_materials CASCADE;"])
    for id, value in json_object["WallConstructionMaterial"].items():
        con_mat = value["name"]
        unit = value["unit"]
        cost = value["cost"]
        stmt = (f'insert into wall_construction_materials (id, wall_construction_material, average_cost, unit)\n'
                f'values {id, con_mat, cost, unit};\n')
        all_stmts.append(stmt)

    all_stmts.extend(["\n--Insert into carbon_output_of_fuel", "TRUNCATE TABLE energy_sources CASCADE;"])
    for id, (key, value) in enumerate(json_object["EnergySources"]["FuelSource"].items()):
        source = key
        unit = value["unit"]
        carbon_out = value["AverageCarbonOutput"]
        stmt = (f'insert into energy_sources (id, fuel_source, average_carbon_output, unit)\n'
                f'values {id + 1, source, carbon_out, unit};\n')
        all_stmts.append(stmt)

    insert_stmts = '\n'.join(all_stmts)
    insert_stmts += '\n'
    return insert_stmts


def load_codebook() -> pd.DataFrame:
    file_name = "2018microdata_codebook.xlsx"
    file_dir = '../raw_data'
    file_path = os.path.join(file_dir, file_name)

    df = pd.read_excel(file_path, sheet_name='2018 CBECS microdata codebook')

    df.columns = df.iloc[0]
    df = df.drop(df.index[0])
    df = df.set_index('Variable\norder')

    return df


def generate_insert_for_id_label_table(table_name, row_id) -> str:
    df = load_codebook()
    row = df.loc[row_id, CODEBOOK_VALUE_COLUMN_NAME]
    all_stmt = [f"--Insert into {table_name}", f"TRUNCATE TABLE {table_name} CASCADE;",
                f'insert into {table_name} (id, label)\n'
                f'values']
    for val in row.split('\n'):
        id, val = val.split('=')
        if id == 'Missing':
            continue
        stmt = f'{id, val},'
        all_stmt.append(stmt)

    id_label_inserts = '\n'.join(all_stmt)
    id_label_inserts = id_label_inserts[:-1] + ';'
    id_label_inserts += '\n\n'
    return id_label_inserts


def generate_insert_for_id_label_tables() -> str:
    tables_dict = {
        "principal_building_activity": 40,
        "census_regions": 2,
        "building_owner_type": 62,
        "complex_type": 52,
        "main_air_conditioning_type": 365,
        "main_heating_equipment": 293,
        "water_heating_equipment": 389,
        "window_types": 556
    }
    all_stmt = []
    for table_name, row_id in tables_dict.items():
        stmt = generate_insert_for_id_label_table(table_name, row_id)
        all_stmt.append(stmt)
    return '\n'.join(all_stmt)


def generate_insert_for_year_of_construction_category() -> str:
    df = load_codebook()
    row = df.loc[22, CODEBOOK_VALUE_COLUMN_NAME]
    all_stmt = ["--Insert into year_of_construction_category", "TRUNCATE TABLE year_of_construction_category CASCADE;",
                f'insert into year_of_construction_category (id, lower_bound, upper_bound) \n'
                f'values'
                ]
    for val in row.split('\n'):
        id, val = val.split('=')
        if 'to' not in val:
            lower = '0'
            upper = val.split(' ')[1]
        else:
            lower, upper = val.split('to')
        stmt = f'{id, lower.strip(), upper.strip()},'
        all_stmt.append(stmt)

    id_label_inserts = '\n'.join(all_stmt)
    id_label_inserts = id_label_inserts[:-1] + ';'
    id_label_inserts += '\n\n'
    return id_label_inserts


def load_all_data() -> pd.DataFrame:
    file_name = "all_data.csv"
    file_dir = '../raw_data'
    file_path = os.path.join(file_dir, file_name)

    df = pd.read_csv(file_path)
    return df


def generate_insert_for_buildings() -> str:
    df = load_all_data()
    relevant_columns = {
        'PUBID': 'id',
        'REGION': 'census_region',
        'CENDIV': 'principal_building_activity',
        'OWNTYPE': 'building_owner_type',
        'SQFT': 'square_footage',
        'WLCNS': 'wall_construction_material_id',
        'RFCNS': 'roof_construction_material_id',
        'FACACT': 'type_of_complex',
        'YRCONC': 'year_of_construction_category'
    }
    df = df[relevant_columns.keys()]
    df = df.rename(columns=relevant_columns)

    all_stmt = ["-- Insert into buildings", "TRUNCATE TABLE buildings CASCADE;",
                "insert into buildings "
                "(id, census_region, principal_building_activity, building_owner_type, square_footage, "
                "wall_construction_material_id, roof_construction_material_id, type_of_complex, "
                "year_of_construction_category)\n"
                "values"
                ]

    for _, row in df.iterrows():
        values = []
        for item in row:
            if pd.isna(item):
                values.append("NULL")
            else:
                values.append(str(int(item)))
        val = f"({', '.join(values)}),"
        all_stmt.append(val)

    in_stmt = '\n'.join(all_stmt)
    in_stmt = in_stmt[:-1] + ';'
    in_stmt += '\n\n'
    return in_stmt


def generate_insert_for_accessibility_modes() -> str:
    df = load_all_data()
    relevant_columns = {
        'PUBID': 'building_id',
        'NFLOOR': 'number_of_floors',
        'NELVTR': 'number_of_elevators',
        'NESLTR': 'number_of_escalators'
    }
    df = df[relevant_columns.keys()]

    all_stmt = ["-- Insert into accessibility_modes", "TRUNCATE TABLE accessibility_modes;",
                "insert into accessibility_modes (building_id, number_of_floors, number_of_elevators, number_of_escalators)\n"
                "values"
                ]

    for _, row in df.iterrows():
        values = []
        for column in df.columns:
            item = row[column]
            if column == 'NFLOOR':
                if item == 994.0:
                    values.append("'10-14'")
                    continue
                elif item == 995.0:
                    values.append("'15+'")
                    continue
            elif column == 'NELVTR':
                if item == 995.0:
                    values.append("'30+'")
                    continue
            elif column == 'NESLTR':
                if item == 995.0:
                    values.append("'10+'")
                    continue
            if pd.isna(item):
                values.append("NULL")
            else:
                values.append(f"'{str(int(item))}'")
        val = f"({', '.join(values)}),"

        all_stmt.append(val)

    in_stmt = '\n'.join(all_stmt)
    in_stmt = in_stmt[:-1] + ';'
    in_stmt += '\n\n'
    return in_stmt


def generate_insert_for_renovations() -> str:
    df = load_all_data()
    relevant_columns = {
        'PUBID': 'building_id',
        'RENCOS': 'cosmetic_improvements',
        'RENADD': 'addition_or_annex',
        'RENRDC': 'reduced_floorspace',
        'RENINT': 'wall_reconfig',
        'RENRFF': 'roof_replace',
        'RENWIN': 'window_replace',
        'RENHVC': 'hvac_equip_upgrade',
        'RENLGT': 'lighting_upgrade',
        'RENPLB': 'plumbing_system_upgrade',
        'RENELC': 'electrical_upgrade',
        'RENINS': 'insulation_upgrade',
        'RENSAF': 'fire_safety_upgrade',
        'RENSTR': 'structural_upgrade',
        'RENOTH': 'other_renovations'
    }
    df = df[relevant_columns.keys()]

    all_stmt = ["-- Insert into renovations_since_2000", "TRUNCATE TABLE renovations_since_2000;",
                "insert into renovations_since_2000 (building_id, cosmetic_improvements, addition_or_annex, reduced_floorspace, wall_reconfig, roof_replace, window_replace, hvac_equip_upgrade, lighting_upgrade, plumbing_system_upgrade, electrical_upgrade, insulation_upgrade, fire_safety_upgrade, structural_upgrade, other_renovations)\n"
                "values"
                ]

    for _, row in df.iterrows():
        values = []
        for column in df.columns:
            item = row[column]
            if column == 'PUBID':
                values.append(str(int(item)))
                continue
            if pd.isna(item):
                values.append("NULL")
            elif item == 1.0:
                values.append("'True'")
            else:
                values.append("'False'")
        val = f"({', '.join(values)}),"

        all_stmt.append(val)

    in_stmt = '\n'.join(all_stmt)
    in_stmt = in_stmt[:-1] + ';'
    in_stmt += '\n\n'
    return in_stmt


def get_df_with_cols(col_nums) -> pd.DataFrame:
    df = load_all_data()
    codebook = load_codebook()
    relevant_columns = []
    for num in col_nums:
        relevant_columns.append(codebook.loc[num, 'Variable\nname'])

    return df[relevant_columns]


def generate_annual_energy_consumption_inserts() -> str:
    relevant_columns_nums = [1, 567, 569, 570, 572, 573, 574]
    df = get_df_with_cols(relevant_columns_nums)

    all_stmt = ["-- Insert into annual_energy_consumption", "TRUNCATE TABLE annual_energy_consumption;",
                ("insert into "
                 "annual_energy_consumption(building_id, electricity_consumption_thous_btu, electricity_expenditure_usd,"
                 "natural_gas_consumption_thous_btu, natural_gas_expenditure_usd,"
                 "fuel_oil_consumption_thous_btu, fuel_oil_expenditure_usd)\n"
                 "values")]

    for _, row in df.iterrows():
        values = []
        for column in df.columns:
            item = row[column]
            if pd.isna(item):
                values.append("NULL")
            else:
                values.append(str(int(item)))
        val = f"({', '.join(values)}),"
        all_stmt.append(val)

    in_stmt = '\n'.join(all_stmt)
    in_stmt = in_stmt[:-1] + ';'
    in_stmt += '\n\n'
    return in_stmt


def generate_serves_food_inserts() -> str:
    relevant_columns_nums = [1, 44, 45, 49]
    df = get_df_with_cols(relevant_columns_nums)

    all_stmt = ["-- Insert into serves_food", "TRUNCATE TABLE serves_food;",
                ("insert into serves_food (building_id, food_service_seating, drive_thru_window, food_court)\n"
                 "values")]

    for _, row in df.iterrows():
        values = []
        count_nulls = 0
        for column in df.columns:
            item = row[column]
            if pd.isna(item):
                values.append("NULL")
                count_nulls += 1
            elif column == 'PUBID' or column == 'FDSEAT':
                values.append(str(int(item)))
            elif item == 1.0:
                values.append("'True'")
            else:
                values.append("'False'")
        if count_nulls == 3:
            continue
        val = f"({', '.join(values)}),"

        all_stmt.append(val)

    in_stmt = '\n'.join(all_stmt)
    in_stmt = in_stmt[:-1] + ';'
    in_stmt += '\n\n'
    return in_stmt


def generate_insert_for_schedules() -> str:
    relevant_cols = [1, 75, 76, 77, 79]
    df = get_df_with_cols(relevant_cols)

    all_stmt = ["-- Insert into schedules", "TRUNCATE TABLE schedules;",
                (
                    "insert into schedules (building_id, open_during_week, open_on_weekend, total_hours_open_per_week, number_of_employees)\n"
                    "values")]

    for _, row in df.iterrows():
        values = []
        for column in df.columns:
            item = row[column]
            if pd.isna(item):
                values.append("NULL")
            elif column in ['PUBID', 'WKHRS', 'NWKER']:
                values.append(str(int(item)))
            elif column == 'OPNMF':
                if item < 3:
                    values.append("'True'")
                else:
                    values.append("'False'")
            elif item == 1.0:
                values.append("'True'")
            else:
                values.append("'False'")
        val = f"({', '.join(values)}),"
        all_stmt.append(val)

    in_stmt = '\n'.join(all_stmt)
    in_stmt = in_stmt[:-1] + ';'
    in_stmt += '\n\n'
    return in_stmt


def generate_insert_for_energy_sources_used() -> str:
    relevant_columns_nums = [1]
    relevant_columns_nums.extend([x for x in range(88, 98 + 1)])
    df = get_df_with_cols(relevant_columns_nums)

    all_stmt = ["-- Insert into energy_sources_used", "TRUNCATE TABLE energy_sources_used;",
                ("insert into energy_sources_used (building_id, energy_source)\n"
                 "values")]

    for _, row in df.iterrows():
        for i, column in enumerate(df.columns[1:]):
            values = [f"{row['PUBID']}"]
            item = row[column]
            if pd.isna(item) or item != 1:
                continue
            else:
                values.append(f"{i + 1}")

            val = f"({', '.join(values)}),"
            all_stmt.append(val)

    in_stmt = '\n'.join(all_stmt)
    in_stmt = in_stmt[:-1] + ';'
    in_stmt += '\n\n'
    return in_stmt


def generate_insert_for_heating_and_ac_info() -> str:
    relevant_columns_nums = [1, 371, 365, 293]
    df = get_df_with_cols(relevant_columns_nums)

    all_stmt = ["-- Insert into heating_and_ac_info", "TRUNCATE TABLE heating_and_ac_info;",
                (
                    "insert into heating_and_ac_info (building_id, has_smart_thermostat, main_air_conditioning_type, main_heating_equipment_type)\n"
                    "values")]

    for _, row in df.iterrows():
        values = []
        for column in df.columns:
            item = row[column]
            if pd.isna(item):
                values.append("NULL")
            elif column == 'SMRTTHRM':
                if item == 1.0:
                    values.append("'True'")
                else:
                    values.append("'False'")
            else:
                values.append(str(int(item)))
        val = f"({', '.join(values)}),"
        all_stmt.append(val)

    in_stmt = '\n'.join(all_stmt)
    in_stmt = in_stmt[:-1] + ';'
    in_stmt += '\n\n'
    return in_stmt


def generate_water_heating_info() -> str:
    relevant_columns_nums = [1]
    relevant_columns_nums.extend([x for x in range(379, 389 + 1)])
    df = get_df_with_cols(relevant_columns_nums)

    all_stmt = ["-- Insert into water_heating_info", "TRUNCATE TABLE water_heating_info;",
                (
                    "insert into water_heating_info (building_id, electricity_used, natural_gas_used, fuel_oil_used, propane_used,"
                    "district_steam_used, district_hot_water_used, wood_used, coal_used, solar_thermal_used, other_fuel_used, water_heating_equipment_type)\n"
                    "values")]

    for _, row in df.iterrows():
        values = []
        for column in df.columns:
            item = row[column]
            if pd.isna(item):
                values.append("NULL")
            elif column in ['WTHTEQ', 'PUBID']:
                values.append(str(int(item)))
            elif item == 1.0:
                values.append("'True'")
            else:
                values.append("'False'")

        val = f"({', '.join(values)}),"
        all_stmt.append(val)

    in_stmt = '\n'.join(all_stmt)
    in_stmt = in_stmt[:-1] + ';'
    in_stmt += '\n\n'
    return in_stmt

def generate_insert_for_window_information() -> str:
    relevant_columns_nums = [1,556,557,558]
    df = get_df_with_cols(relevant_columns_nums)

    all_stmt = ["-- Insert into window_information", "TRUNCATE TABLE window_information;",
                (
                    "insert into window_information (building_id, window_type, has_reflective_windows, has_tinted_windows)\n"
                    "values")]

    for _, row in df.iterrows():
        values = []
        for column in df.columns:
            item = row[column]
            if pd.isna(item):
                values.append("NULL")
            elif column in ['PUBID', 'WINTYP']:
                values.append(str(int(item)))
            elif item == 1.0:
                values.append("'True'")
            else:
                values.append("'False'")

        val = f"({', '.join(values)}),"
        all_stmt.append(val)

    in_stmt = '\n'.join(all_stmt)
    in_stmt = in_stmt[:-1] + ';'
    in_stmt += '\n\n'
    return in_stmt

def generate_insert_for_lighting_information() -> str:
    relevant_columns_nums = [1]
    relevant_columns_nums.extend([x for x in range(538, 546 + 1)])
    relevant_columns_nums.extend([561, 525, 523, 528])

    df = get_df_with_cols(relevant_columns_nums)

    all_stmt = ["-- Insert into lighting_information", "TRUNCATE TABLE lighting_information;",
                (
                    "insert into lighting_information (building_id, percent_fluorescent, percent_compact_fluorescent, percent_incandescent, "
                    "percent_halogen, percent_hid, percent_led, percent_other, has_light_scheduling, has_occupancy_sensors, percent_building_receiving_enough_daylight, "
                    "percent_building_lit_when_open, percent_building_lit_when_closed, percent_time_lights_off)\n"
                    "values")]

    for _, row in df.iterrows():
        values = []
        for column in df.columns:
            item = row[column]
            if pd.isna(item):
                values.append("NULL")
            elif column == 'PUBID':
                values.append(str(int(item)))
            elif column in ('SCHED','OCSN'):
                if item == 1.0:
                    values.append("'True'")
                else:
                    values.append("'False'")
            else:
                values.append(str(float(item)))

        val = f"({', '.join(values)}),"
        all_stmt.append(val)

    in_stmt = '\n'.join(all_stmt)
    in_stmt = in_stmt[:-1] + ';'
    in_stmt += '\n\n'
    return in_stmt

def main():
    in1 = generate_insert_from_supp_info()
    in2 = generate_insert_for_id_label_tables()
    in3 = generate_insert_for_year_of_construction_category()
    in4 = generate_insert_for_buildings()
    in5 = generate_insert_for_accessibility_modes()
    in6 = generate_insert_for_renovations()
    in7 = generate_annual_energy_consumption_inserts()
    in8 = generate_serves_food_inserts()
    in9 = generate_insert_for_schedules()
    in10 = generate_insert_for_energy_sources_used()
    in11 = generate_insert_for_heating_and_ac_info()
    in12 = generate_water_heating_info()
    in13 = generate_insert_for_window_information()
    in14 = generate_insert_for_lighting_information()
    all_in = "".join([in1, in2, in3, in4, in5, in6, in7, in8, in9, in10, in11, in12, in13, in14])
    # print(all_in)
    file_dir = '../sql'
    file_path = os.path.join(file_dir, 'insert_statements.sql')
    with open(file_path, 'w') as file:
        file.write(all_in)

    print("SQL inserts generated :)")

if __name__ == "__main__":
    main()
