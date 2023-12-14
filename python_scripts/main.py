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
    all_stmt = [f"--Insert into {table_name}", f"DELETE FROM {table_name};"]
    for val in row.split('\n'):
        id, val = val.split('=')
        stmt = (f'insert into {table_name} (id, label)\n'
                f'values {id, val};\n')
        all_stmt.append(stmt)

    id_label_inserts = '\n'.join(all_stmt)
    id_label_inserts += '\n'
    print(id_label_inserts)
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
    all_stmt = ["--Insert into year_of_construction_category", "DELETE FROM year_of_construction_category;"]
    for val in row.split('\n'):
        id, val = val.split('=')
        if 'to' not in val:
            lower = '0'
            upper = val.split(' ')[1]
        else:
            lower, upper = val.split('to')
        stmt = (f'insert into year_of_construction_category (id, lower_bound, upper_bound)\n'
                f'values {id, lower.strip(), upper.strip()};\n')
        all_stmt.append(stmt)

    id_label_inserts = '\n'.join(all_stmt)
    id_label_inserts += '\n'
    return id_label_inserts


def main():
    all_in = ""
    in1 = generate_insert_from_supp_info()
    in2 = generate_insert_for_id_label_tables()
    in3 = generate_insert_for_year_of_construction_category()
    all_in.join([in1, in2, in3])
    print(all_in)




if __name__ == "__main__":
    main()
