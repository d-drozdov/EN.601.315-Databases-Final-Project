import json
import os

import pandas as pd

CODEBOOK_VALUE_COLUMN_NAME = 'Values/Format codes'


def load_json_file(file_name: str, debug: bool = False) -> dict:
    current_directory = os.getcwd()
    file_path = os.path.join(current_directory, file_name)
    try:
        with open(file_path, 'r') as file:
            json_data = file.read()
        json_object = json.loads(json_data)
        if debug:
            json_formatted_str = json.dumps(json_object, indent=2)
            print(json_formatted_str)
        return json_object
    except FileNotFoundError:
        print(f"File not found: {file_path}")
    except Exception as e:
        print(f"An error occurred: {e}")


def generate_insert_from_supp_info(debug: bool = False) -> str:
    file_name = "supplementary_info.json"
    json_object = load_json_file(file_name, debug=debug)
    all_stmts = ["--Insert into roof_construction_materials", "DELETE FROM roof_construction_materials;"]

    for id, value in json_object["roofMatAvg"].items():
        con_mat = value["name"]
        unit = value["unit"]
        cost = value["cost"]
        stmt = (f'insert into roof_construction_materials (id, roof_construction_material, average_cost, unit)\n'
                f'values {id, con_mat, cost, unit};\n')
        all_stmts.append(stmt)

    all_stmts.extend(["\n--Insert into wall_construction_materials", "DELETE FROM wall_construction_materials;"])
    for id, value in json_object["WallConstructionMaterial"].items():
        con_mat = value["name"]
        unit = value["unit"]
        cost = value["cost"]
        stmt = (f'insert into wall_construction_materials (id, wall_construction_material, average_cost, unit)\n'
                f'values {id, con_mat, cost, unit};\n')
        all_stmts.append(stmt)

    all_stmts.extend(["\n--Insert into carbon_output_of_fuel", "DELETE FROM energy_sources;"])
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
    all_stmt = [f"--Insert into {table_name}", f"DELETE FROM {table_name};",
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


def generate_insert_for_id_label_tables():
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


def generate_insert_for_year_of_construction_category():
    df = load_codebook()
    row = df.loc[22, CODEBOOK_VALUE_COLUMN_NAME]
    all_stmt = ["--Insert into year_of_construction_category", "DELETE FROM year_of_construction_category;",
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


def load_all_data():
    file_name = "all_data.csv"
    file_dir = '../raw_data'
    file_path = os.path.join(file_dir, file_name)

    df = pd.read_csv(file_path)
    return df


import pandas as pd


def generate_insert_for_buildings():
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

    all_stmt = ["-- Insert into buildings", "DELETE FROM buildings;",
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

def generate_insert_for_accessibility_modes():
    df = load_all_data()
    relevant_columns = {
    'PUBID': 'building_id',
    'NFLOOR': 'number_of_floors',
    'NELVTR': 'number_of_elevators',
    'NESLTR': 'number_of_escalators'
    }
    df = df[relevant_columns.keys()]


    all_stmt = ["-- Insert into accessibility_modes", "DELETE FROM accessibility_modes;",
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

def generate_insert_for_renovations():
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

    all_stmt = ["-- Insert into renovations_since_2000", "DELETE FROM renovations_since_2000;",
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



def main():
    in1 = generate_insert_from_supp_info()
    in2 = generate_insert_for_id_label_tables()
    in3 = generate_insert_for_year_of_construction_category()
    in4 = generate_insert_for_buildings()
    in5 = generate_insert_for_accessibility_modes()
    in6 = generate_insert_for_renovations()
    all_in = "".join([in1, in2, in3, in4, in5, in6])
    print(all_in)
    with open('inserts.sql', 'w') as file:
        file.write(all_in)


if __name__ == "__main__":
    main()
