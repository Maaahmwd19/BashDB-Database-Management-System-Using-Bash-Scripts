# BashDB:Database Management System (DBMS) Using Bash Script 
ITI project for Database Management System Using Bash Scripts-- Telecom Intake 45

## Project Overview
This project is a simple yet advanced Database Management System (DBMS) implemented using Bash shell scripting. It allows users to create, manage, and interact with databases stored on disk using a command-line interface (CLI). The system organizes databases as directories and tables as files (CSV, JSON, or XML).

---

## Features

### **Main Menu**
- **Create Database** – Creates a new database (stored as a directory).
- **List Databases** – Displays all available databases.
- **Connect to Database** – Allows users to select and interact with a database.
- **Drop Database** – Deletes an existing database.

### **Database Menu (After Connecting to a Database)**
- **Create Table** – Defines a new table with column metadata and data storage.
- **List Tables** – Shows all tables in the database.
- **Drop Table** – Deletes a table.
- **Insert into Table** – Adds new records to a table.
- **Select From Table** – Displays stored records in a well-formatted way.
- **Delete From Table** – Removes specific records using the primary key.
- **Update Row** – Modifies existing records while maintaining data integrity.

---

## Implementation Details
- **Database Structure**:
  - Databases are represented as directories inside the script’s working directory.
  - Tables are stored as files in formats like CSV, JSON, or XML.
  - Each database has its own directory, and each table exists as a separate file.

- **Table Metadata**:
  - When a table is created, metadata is stored to define:
    - Table name
    - Number of columns
    - Column names and data types
  - Metadata is stored either in a separate file or as part of the table file.

- **Data Handling**:
  - The **first column** in every table is treated as a **Primary Key** to ensure unique identification of records.
  - Data is validated based on the specified column data types (e.g., numeric or string values).
  - The system ensures that the primary key cannot be duplicated.

- **Query Execution**:
  - User input is processed through menu options to perform operations like insertion, selection, deletion, and updates.
  - Selected data is displayed in a structured and readable format.

---

## **Bonus Features**
- **SQL Query Support**:
  - Instead of navigating the menu, users can enter SQL-like commands.
  - The system will interpret and execute these commands.

- **Graphical User Interface (GUI)**:
  - A GUI version may be developed in addition to the CLI version.
  - This would provide a more user-friendly experience with point-and-click operations.

---

## **Requirements**
- **Operating System**: Linux-based (tested on CentOS 9)
- **Shell**: Bash
- **Utilities Required**:
  - `awk`, `sed`, `grep` (for text processing)
  - `dialog` (optional, for better CLI menu interfaces)

---

## **Installation and Steps to Run**
1. **Clone the Repository**:
   ```bash
   https://github.com/Maaahmwd19/BashDB-Database-Management-System-Using-Bash-Scripts.git
   cd BashDB-Database-Management-System-Using-Bash-Scripts

2. **Make the Script Executable**:
```bash
chmod y+x *.sh
```

3. **Run the Script**:
```bash
./dbms.sh
```

### **Follow the On-Screen Menu**:
The script will display a menu where you can create databases, manage tables, and insert/select data.

## **Usage Examples**

### **Creating a Database**
```
Main Menu:
1. Create Database
2. List Databases
3. Connect to Database
4. Drop Database
5.rename Datebase
Enter your choice: 1

Enter database name: students_db
Database 'students_db' created successfully.
```

### **Creating a Table**
```
Database: students_db
1. Create Table
2. List Tables
3. Drop Table
4. Insert into Table
5. Select From Table
6. Delete From Table
7. Update Row
Enter your choice: 1

Enter table name: students
Enter number of columns: 3
Enter column 1 name : id
Enter column 1 data type (int/str): int
Enter column 2 name: name
Enter column 2 data type (int/str): str
Enter column 3 name: grade
Enter column 3 data type (int/str): int
Table 'students' created successfully.
```

### **Inserting Data into a Table**
```
Database: students_db > students table
1. Insert into Table
2. Select From Table
3. Delete From Table
4. Update Row
Enter your choice: 1

Enter id: 101
Enter name: Alice
Enter grade: 90
Record inserted successfully.
```

### **Selecting Data**
```
Database: students_db > students table
1. Insert into Table
2. Select From Table
3. Delete From Table
4. Update Row
Enter your choice: 2

+-----+-------+-------+
| id  | name  | grade |
+-----+-------+-------+
| 101 | Alice |  90   |
+-----+-------+-------+
```

### **Updating Data**
```
Enter the primary key (id) of the record to update: 101
Enter column to update: grade
Enter new value: 95
Record updated successfully.
```

### **Deleting a Record**
```
Enter the primary key (id) of the record to delete: 101
Record deleted successfully.
```

