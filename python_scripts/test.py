import json
import os


def extract_codes(debug: str = False) -> dict:
    file_name = "codes_dict.json"
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


def main():
    codes_dict= extract_codes(debug=True)



if __name__ == "__main__":
    main()
