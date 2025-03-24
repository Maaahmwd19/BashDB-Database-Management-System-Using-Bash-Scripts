#! /usr/bin/bash
source utils.sh
declare -f insertIntoTable

tableMenu() {
   echo $1
    dbName="$1"  
    PS3="
ITI-DBMS [$dbName] >> " 
    header
    echo -e "Connected to Database '$dbName' successfully......!  \\n"

    echo "================================= Table Operations ================================="
    select choice in "Create Table" "List Tables" "Drop Table" "Insert into Table" "Select from Table" "Delete from Table" "Update Row"  "Select From Table (Bonus)"  "Back to Main Menu"
    do
        case $REPLY in  
            1) createTable ;;
            2) listTables ;;
            3) dropTable ;; 
            4) insertIntoTable ;;  
            5) selectFromTable ;;
            6) deleteFromTable ;;
            7) updateRow ;;
            8) selectFromTableBouns ;;  
            9)  cd ../..  
                clear
                mainMenu 
                exit
                ;;
            *) echo "Invalid option, please try again." ;;
        esac
    done
}


function createTable() {
    read -p "Enter Table Name: " tableName

    if ! validateTableName "$tableName"; then
        return
    fi

    if tableExists "$tableName"; then
        return
    else
        touch "$DB_DIR/$dbName/$tableName.metadata" "$DB_DIR/$dbName/$tableName"
    fi

    read -p "Enter number of columns: " tableColumns
    if ! validateColumNumber "$tableColumns"; then
        rm -rf "$DB_DIR/$dbName/$tableName"*  
        return
    fi

    local PK=0 

    for ((i = 1; i <= tableColumns; i++)); do
        read -p "Enter name of column $i: " columnName

        if ! validateColumnName "$columnName"; then
            return
        fi

        if columnExists "$tableName" "$columnName"; then
            echo "Column '$columnName' already exists!"
            return
        fi

        read -p "Enter data type (str/int): " dataType

        if [[ "$dataType" != "int" && "$dataType" != "str" ]]; then
            echo "Invalid data type..."
            rm -rf "$DB_DIR/$dbName/$tableName"*
            return
        fi
 
        if (( PK == 0 )); then
            read -p "Is '$columnName' the Primary Key? (y/n): " pkValidation
            if [[ "$pkValidation" =~ ^[Yy] ]]; then  
                PK=1
                echo "$columnName:$dataType:pk" >> "$DB_DIR/$dbName/$tableName.metadata"
                continue  
            fi
        fi

        echo "$columnName:$dataType" >> "$DB_DIR/$dbName/$tableName.metadata"

    done

    # handel if no primary key is set ---> set first column is as a pk
    if (( PK == 0 )); then
        sed -i '1s/$/:pk/' "$DB_DIR/$dbName/$tableName.metadata"
    fi

    echo -e "${GREEN}Table '$tableName' created successfully with $tableColumns columns!${REST}"
}



function listTables() {
    local dbPath="/usr/lib/myDBMS_ITI/$dbName"

    if [[ -d "$dbPath" && "$(ls -A "$dbPath")" ]]; then
        echo -e "${GREEN}\\nAvailable Tables${REST}"
        echo -e "${GREEN}--------------------${REST}"
        ls -1 "$dbPath" | grep -v '\.metadata$' | awk '{print NR ") " $0}'
    else
        echo -e "${RED}\\n$dbName/_db dose not have any tables.....${REST}"
    fi
}


function dropTable()
{
    local dbPath="$DB_DIR/$dbName"
    read -p "Enter Table Name To drop: " tableName
    
    
    if tableNotExists "$tableName" ; then
    return
    fi

     rm -rf "$dbPath/$tableName"*

    if [ ! -f "$dbPath/$tableName.meta" ]; then
        echo -e "${GREEN}Table '$tableName' deleted successfully.${REST}"
    else
        echo -e "${RED}Error: Failed to delete table '$tableName'.${REST}"
    fi
}


function selectFromTable()
{
    local dbPath="/usr/lib/myDBMS_ITI/$dbName"

    read -p "Enter Table name to retrive Data: " tableName
    if tableNotExists "$tableName";then
    return
    fi

    # table header 
    # ============
    awk -F':' 'BEGIN {header = ""; border = "+"}

    {
        header = header sprintf("| %-10s ", $1);
        border = border "------------+"
    }

    END {
        print border;
        print header "|";
        print border;
    }' "$dbPath/$tableName.metadata"

    # table contant
    # ==============
    awk -F',' '
    {
        if (NR == 1) numCols = NF;  
        printf "|";
        for (i = 1; i <= NF; i++) {
            printf " %-10s |", $i;
        }
        print "";

        rowCount = NR;  
    }

    END {
        if (rowCount > 0) {
            # Print bottom border
            printf "+";
            for (i = 1; i <= numCols; i++) {
                printf "------------+";
            }
            print "";
            print rowCount " rows in set";
        } else {
            print "Table is empty";
        }
    }' "$dbPath/$tableName"


}

function selectFromTableBouns() {
    local dbPath="/usr/lib/myDBMS_ITI/$dbName"

    read -p "Enter Table name to retrieve Data: " tableName
    if tableNotExists "$tableName"; then
        return
    fi

    # Read available column names
    mapfile -t columns < <(awk -F':' '{print $1}' "$dbPath/$tableName.metadata")

    # Display column names
    echo "Available columns: ${columns[*]}"

    # Ask user for specific columns
    read -p "Enter column names (comma-separated, * for all): " selectedCols

    if [[ "$selectedCols" == "*" ]]; then
        selectedCols=$(IFS=,; echo "${columns[*]}")  # Convert array to comma-separated string
    fi

    # Convert selected columns to an array
    IFS=',' read -ra selectedArr <<< "$selectedCols"

    # Build indexes for selected columns
    declare -A colIndexes
    for i in "${!columns[@]}"; do
        colIndexes["${columns[$i]}"]=$((i + 1))
    done

    # Generate header and border
    header=""
    border="+"
    colIndexList=()
    
    for col in "${selectedArr[@]}"; do
        col=${col// /}  # Trim spaces
        if [[ -z "${colIndexes[$col]}" ]]; then
            echo "Error: Column '$col' does not exist."
            return
        fi
        colIndexList+=("${colIndexes[$col]}")
        header+="| $(printf "%-10s" "$col") "
        border+="------------+"
    done

    echo "$border"
    echo "$header|"
    echo "$border"

    # Print table data with selected columns
    awk -F',' -v cols="${colIndexList[*]}" '
    BEGIN {
        split(cols, selectedIndexes, " ")
    }
    {
        printf "|"
        for (i in selectedIndexes) {
            printf " %-10s |", $selectedIndexes[i]
        }
        print ""
        rowCount++
    }
    END {
        if (rowCount > 0) {
            print "'$border'"
            print rowCount " rows in set"
        } else {
            print "Table is empty"
        }
    }' "$dbPath/$tableName"
}

function insertIntoTable() {
    local dbPath="/usr/lib/myDBMS_ITI/$dbName"
    read -p "Enter Table Name to Insert Data: " tableName

    if tableNotExists "$tableName"; then
        echo -e "${RED}Table does not exist.${REST}"
        return
    fi

    local metaFile="$dbPath/$tableName.metadata"
    local dataFile="$dbPath/$tableName.csv"

    if [[ ! -f "$metaFile" ]]; then
        echo -e "${RED}Metadata file missing!${REST}"
        return
    fi

    # Extract column names and types from metadata
    mapfile -t columns < <(awk -F: '{print $1}' "$metaFile")
    mapfile -t types < <(awk -F: '{print $2}' "$metaFile")
    local pkColumn=$(awk -F: '$3 == "pk" {print $1}' "$metaFile")
    local pkIndex=$(awk -F: '$3 == "pk" {print NR-1}' "$metaFile")  # 0-based index

    local numCols=${#columns[@]}
    declare -a values

    echo -e "${GREEN}Insert Data into '$tableName':${REST}"

    # Loop through columns for user input
    for ((i = 0; i < numCols; i++)); do
        while true; do
            read -p "Enter value for ${columns[i]} (${types[i]}): " input

            # Validate data type
            case "${types[i]}" in
                int)  
                    [[ "$input" =~ ^[0-9]+$ ]] || { echo -e "${RED}Invalid input! Expected an integer.${REST}"; continue; }
                    ;;
                str)  
                    [[ "$input" =~ ^[a-zA-Z0-9_ ]+$ ]] || { echo -e "${RED}Invalid input! Expected a string.${REST}"; continue; }
                    ;;
                *)  
                    echo -e "${RED}Unknown data type '${types[i]}' in metadata.${REST}"
                    return
                    ;;
            esac

            values[i]="$input"
            break
        done
    done

    local pkValue=${values[$pkIndex]}

    # Check if the primary key already exists in the CSV file
    if [[ -f "$dataFile" ]] && awk -F, -v pk="$pkValue" -v col="$((pkIndex + 1))" 'NR > 1 && $col == pk {exit 1}' "$dataFile"; then
        echo -e "${RED}Error: Duplicate primary key value '${pkValue}'!${REST}"
        return
    fi

    # Append the new row to the CSV file
    echo "$(IFS=,; echo "${values[*]}")" >> "$dataFile"
    echo -e "${GREEN}Data inserted successfully!${REST}"
}


function deleteFromTable()
{
    local dbPath="/usr/lib/myDBMS_ITI/$dbName"

    read -p "Enter Table name to Delete from Data: " tableName
    if tableNotExists "$tableName";then
    return
    fi

    #continue

}

function updateRow()
{
    local dbPath="/usr/lib/myDBMS_ITI/$dbName"

    read -p "Enter Table name to Uodate on Data: " tableName
    if tableNotExists "$tableName";then
    return
    fi

    #continue
}

