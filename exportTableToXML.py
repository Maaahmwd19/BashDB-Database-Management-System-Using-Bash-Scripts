import os
import csv
import xml.etree.ElementTree as ET
import json

DB_PATH = "/usr/lib/myDBMS_ITI/"

def validate_db_exists(db_name):
    if not os.path.isdir(os.path.join(DB_PATH, db_name)):
        print(f"Error: Database '{db_name}' does not exist.")
        return False
    return True

def validate_table_exists(db_name, table_name):
    return os.path.isfile(os.path.join(DB_PATH, db_name, table_name))

def create_table(db_name):
    table_name = input("Enter Table Name: ").strip()
    table_path = os.path.join(DB_PATH, db_name, table_name)
    metadata_path = table_path + ".metadata"

    if os.path.exists(table_path):
        print("Error: Table already exists.")
        return

    num_columns = input("Enter number of columns: ").strip()
    if not num_columns.isdigit() or int(num_columns) <= 0:
        print("Invalid number of columns.")
        return
    num_columns = int(num_columns)

    columns = []
    primary_key_set = False

    for i in range(num_columns):
        col_name = input(f"Enter name of column {i+1}: ").strip()
        col_type = input(f"Enter type (str/int) for '{col_name}': ").strip().lower()

        if col_type not in ["str", "int"]:
            print("Invalid column type.")
            return

        if not primary_key_set:
            is_pk = input(f"Is '{col_name}' the Primary Key? (y/n): ").strip().lower()
            if is_pk == 'y':
                columns.append(f"{col_name}:{col_type}:pk")
                primary_key_set = True
                continue

        columns.append(f"{col_name}:{col_type}")

    if not primary_key_set:
        # Default first column as PK
        columns[0] = columns[0] + ":pk"

    # Save metadata
    os.makedirs(os.path.dirname(metadata_path), exist_ok=True)
    with open(metadata_path, "w") as meta_file:
        for col in columns:
            meta_file.write(col + "\n")

    open(table_path, 'w').close()  # create empty table file

    print(f"Table '{table_name}' created successfully.")

def insert_into_table(db_name):
    table_name = input("Enter Table Name to Insert: ").strip()
    table_path = os.path.join(DB_PATH, db_name, table_name)
    metadata_path = table_path + ".metadata"

    if not validate_table_exists(db_name, table_name):
        print("Table not found.")
        return

    columns = []
    types = []
    pk_col = None
    pk_index = -1

    with open(metadata_path, 'r') as meta_file:
        for idx, line in enumerate(meta_file):
            parts = line.strip().split(":")
            columns.append(parts[0])
            types.append(parts[1])
            if len(parts) > 2 and parts[2] == "pk":
                pk_col = parts[0]
                pk_index = idx

    data = []
    existing_pks = set()

    with open(table_path, 'r') as table_file:
        reader = csv.reader(table_file)
        for row in reader:
            if len(row) > pk_index:
                existing_pks.add(row[pk_index])

    for idx, col in enumerate(columns):
        while True:
            val = input(f"Enter value for {col} ({types[idx]}): ").strip()
            if types[idx] == "int" and not val.isdigit():
                print("Must be integer.")
                continue
            if idx == pk_index and val in existing_pks:
                print(f"Duplicate Primary Key '{val}' not allowed.")
                continue
            data.append(val)
            break

    with open(table_path, 'a', newline='') as table_file:
        writer = csv.writer(table_file)
        writer.writerow(data)

    print("Row inserted successfully.")
    export_table_to_xml(db_name, table_name)
    export_table_to_json(db_name, table_name)

def delete_from_table(db_name):
    table_name = input("Enter Table Name to Delete From: ").strip()
    table_path = os.path.join(DB_PATH, db_name, table_name)
    metadata_path = table_path + ".metadata"

    if not validate_table_exists(db_name, table_name):
        print("Table not found.")
        return

    columns = []
    pk_col = None
    pk_index = -1

    with open(metadata_path, 'r') as meta_file:
        for idx, line in enumerate(meta_file):
            parts = line.strip().split(":")
            columns.append(parts[0])
            if len(parts) > 2 and parts[2] == "pk":
                pk_col = parts[0]
                pk_index = idx

    pk_value = input(f"Enter {pk_col} to delete: ").strip()

    found = False
    new_rows = []

    with open(table_path, 'r') as table_file:
        reader = csv.reader(table_file)
        for row in reader:
            if len(row) > pk_index and row[pk_index] == pk_value:
                found = True
                continue
            new_rows.append(row)

    if not found:
        print("Record not found.")
        return

    with open(table_path, 'w', newline='') as table_file:
        writer = csv.writer(table_file)
        writer.writerows(new_rows)

    print("Row deleted successfully.")
    export_table_to_xml(db_name, table_name)
    export_table_to_json(db_name, table_name)

def update_row(db_name):
    table_name = input("Enter Table Name to Update: ").strip()
    table_path = os.path.join(DB_PATH, db_name, table_name)
    metadata_path = table_path + ".metadata"

    if not validate_table_exists(db_name, table_name):
        print("Table not found.")
        return

    columns = []
    types = []
    pk_col = None
    pk_index = -1

    with open(metadata_path, 'r') as meta_file:
        for idx, line in enumerate(meta_file):
            parts = line.strip().split(":")
            columns.append(parts[0])
            types.append(parts[1])
            if len(parts) > 2 and parts[2] == "pk":
                pk_col = parts[0]
                pk_index = idx

    pk_value = input(f"Enter {pk_col} to update: ").strip()

    rows = []
    found = False

    with open(table_path, 'r') as table_file:
        reader = csv.reader(table_file)
        for row in reader:
            if len(row) > pk_index and row[pk_index] == pk_value:
                found = True
                print(f"Available columns: {columns}")
                col_name = input("Enter Column Name to Update: ").strip()

                if col_name not in columns:
                    print("Invalid column name.")
                    return

                if col_name == pk_col:
                    print("Cannot update Primary Key.")
                    return

                col_idx = columns.index(col_name)
                new_val = input(f"Enter new value for {col_name} ({types[col_idx]}): ").strip()

                if types[col_idx] == "int" and not new_val.isdigit():
                    print("Must be integer.")
                    return

                row[col_idx] = new_val

            rows.append(row)

    if not found:
        print("Record not found.")
        return

    with open(table_path, 'w', newline='') as table_file:
        writer = csv.writer(table_file)
        writer.writerows(rows)

    print("Row updated successfully.")
    export_table_to_xml(db_name, table_name)
    export_table_to_json(db_name, table_name)

def export_table_to_xml(db_name, table_name):
    table_path = os.path.join(DB_PATH, db_name, table_name)
    metadata_path = table_path + ".metadata"
    xml_path = os.path.join(DB_PATH, db_name, f"{table_name}.xml")

    columns = []
    with open(metadata_path, 'r') as meta_file:
        for line in meta_file:
            columns.append(line.strip().split(":")[0])

    root = ET.Element("table", attrib={"name": table_name})

    with open(table_path, 'r') as table_file:
        reader = csv.reader(table_file)
        for row in reader:
            row_element = ET.SubElement(root, "row")
            for idx, val in enumerate(row):
                col_element = ET.SubElement(row_element, columns[idx])
                col_element.text = val

    tree = ET.ElementTree(root)
    tree.write(xml_path, encoding='utf-8', xml_declaration=True)

    print(f"Table '{table_name}' exported automatically to XML.")

def export_table_to_json(db_name, table_name):
    table_path = os.path.join(DB_PATH, db_name, table_name)
    metadata_path = table_path + ".metadata"
    json_path = os.path.join(DB_PATH, db_name, f"{table_name}.json")

    columns = []
    with open(metadata_path, 'r') as meta_file:
        for line in meta_file:
            columns.append(line.strip().split(":")[0])

    data = {
        "table": table_name,
        "rows": []
    }

    with open(table_path, 'r') as table_file:
        reader = csv.reader(table_file)
        for row in reader:
            row_data = {}
            for idx, val in enumerate(row):
                if idx < len(columns):
                    row_data[columns[idx]] = val
            data["rows"].append(row_data)

    with open(json_path, 'w') as json_file:
        json.dump(data, json_file, indent=2)

    print(f"Table '{table_name}' exported automatically to JSON.")

def main():
    db_name = input("Enter Database Name to connect: ").strip()
    if not validate_db_exists(db_name):
        return

    while True:
        print("\nSelect Operation:")
        print("1. Create Table")
        print("2. Insert Row")
        print("3. Delete Row")
        print("4. Update Row")
        print("5. Exit")

        choice = input("Choice: ").strip()

        if choice == "1":
            create_table(db_name)
        elif choice == "2":
            insert_into_table(db_name)
        elif choice == "3":
            delete_from_table(db_name)
        elif choice == "4":
            update_row(db_name)
        elif choice == "5":
            break
        else:
            print("Invalid choice.")

if __name__ == "__main__":
    main()
