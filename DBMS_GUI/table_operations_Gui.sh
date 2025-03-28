#!/usr/bin/bash
source $GuiPath/utils_Gui.sh

# Function to get full terminal size dynamically
function get_terminal_size() {
    local size=$(stty size)
    TERMINAL_HEIGHT=$(echo "$size" | awk '{print $1}')
    TERMINAL_WIDTH=$(echo "$size" | awk '{print $2}')
    ((MENU_HEIGHT = TERMINAL_HEIGHT - 7))
    ((MENU_WIDTH = TERMINAL_WIDTH - 100))
}

function tableMenu() {
    local dbName="$1"
    
    while true; do
        get_terminal_size

        CHOICE=$(whiptail --title "Table Operations [${dbName}]" --menu "Choose an option:" \
            "$MENU_HEIGHT" "$MENU_WIDTH" 10 \
            "1" "Create Table" \
            "2" "List Tables" \
            "3" "Drop Table" \
            "4" "Select from Table" \
            "5" "Insert into Table" \
            "6" "Delete from Table" \
            "7" "Update Row" \
            "8" "Back to Main Menu" 3>&1 1>&2 2>&3)


        case $CHOICE in
            1) createTable "$dbName" ;;
            2) listTables "$dbName" ;;
            3) dropTable "$dbName" ;;
            4) selectFromTable "$dbName" ;;
            5) insertIntoTable "$dbName" ;;
            6) deleteFromTable "$dbName" ;;
            7) updateRow "$dbName" ;;
            8) return ;;
        esac
    done
}

function createTable() {
    local dbName="$1"
    get_terminal_size
    tableName=$(whiptail --inputbox "Enter Table Name:" 10 50 3>&1 1>&2 2>&3)
    [[ $? -ne 0 ]] && return 

    if tableExists "$dbName" "$tableName"; then return; fi

    touch "$DB_DIR/$dbName/$tableName"
    whiptail --msgbox "Table '$tableName' created successfully!" "$MENU_HEIGHT" "$MENU_WIDTH"
}

function listTables() {
    local dbName="$1"
    get_terminal_size
    tablesList=$(ls "$DB_DIR/$dbName" 2>/dev/null | grep -v '\.metadata$' | nl)
    [[ -z "$tablesList" ]] && tablesList="No tables found."

    whiptail --title "Available Tables" --msgbox "$tablesList" "$MENU_HEIGHT" "$MENU_WIDTH"
}

function dropTable() {
    local dbName="$1"
    get_terminal_size
    tableName=$(whiptail --inputbox "Enter Table Name to Drop:" 10 50 3>&1 1>&2 2>&3)
    [[ $? -ne 0 ]] && return

    if tableNotExists "$dbName" "$tableName"; then return; fi

    rm -f "$DB_DIR/$dbName/$tableName"
    whiptail --msgbox "Table '$tableName' deleted successfully!" "$MENU_HEIGHT" "$MENU_WIDTH"
}


function selectFromTable() {
    local dbName="$1"
    local dbPath="$DB_DIR/$dbName"

    # Ask user for table name
    tableName=$(whiptail --title "Select Table" --inputbox "Enter Table name to retrieve Data:" 10 50 3>&1 1>&2 2>&3)
    [[ $? -ne 0 || -z "$tableName" ]] && return  # Exit if user cancels

    if tableNotExists "$dbName" "$tableName"; then return; fi

    local tableFile="$dbPath/$tableName"
    local metadataFile="$dbPath/$tableName.metadata"
    local outputFile="/tmp/table_output.txt"

    if [[ ! -s "$tableFile" ]]; then
        whiptail --title "Table: $tableName" --msgbox "Table is empty." 10 50
        return
    fi

    # Clear previous output file
    > "$outputFile"

    # Generate header from metadata
    awk -F':' '
    BEGIN {border="+"}
    {
        header = header sprintf("| %-14s ", $1);  
        border = border "----------------+"
    }
    END {
        print border >> "'$outputFile'";
        print header "|" >> "'$outputFile'";
        print border >> "'$outputFile'";
    }' "$metadataFile"

    # Append table data
    awk -F',' '
    {
        printf "|";
        for (i = 1; i <= NF; i++) {
            printf " %-14s |", $i;
        }
        print "";
    }
    END {
        if (NR > 0) {
            printf "+";
            for (i = 1; i <= NF; i++) {
                printf "----------------+";
            }
            print "";
            print NR " rows in set";
        }
    }' "$tableFile" >> "$outputFile"

    # Use `whiptail --textbox` to display the output with scrolling support
    whiptail --title "Table: $tableName" --scrolltext --textbox "$outputFile" 30 100
}



function insertIntoTable() {
    local dbName="$1"
    local dbPath="$DB_DIR/$dbName"
    get_terminal_size

    tableName=$(whiptail --inputbox "Enter Table name to Insert Data:" 10 503>&1 1>&2 2>&3)
    [[ $? -ne 0 ]] && return

    if tableNotExists "$tableName"; then
        whiptail --title "Error" --msgbox "Table '$tableName' does not exist." "$MENU_HEIGHT" "$MENU_WIDTH"
        return
    fi

    columns=($(awk -F':' '{print $1}' "$dbPath/$tableName.metadata"))

    rowData=""
    for col in "${columns[@]}"; do
        value=$(whiptail --inputbox "Enter value for '$col':" 10 503>&1 1>&2 2>&3)
        [[ $? -ne 0 ]] && return
        rowData+="$value,"
    done

    rowData=${rowData::-1}
    echo "$rowData" >> "$dbPath/$tableName"

    whiptail --title "Success" --msgbox "Data inserted successfully!" "$MENU_HEIGHT" "$MENU_WIDTH"
}

function deleteFromTable() {
    local dbName="$1"
    local dbPath="$DB_DIR/$dbName"
    get_terminal_size

    tableName=$(whiptail --inputbox "Enter Table name to delete data from:" 10 503>&1 1>&2 2>&3)
    [[ $? -ne 0 ]] && return

    if tableNotExists "$tableName"; then
        whiptail --title "Error" --msgbox "Table '$tableName' does not exist." "$MENU_HEIGHT" "$MENU_WIDTH"
        return
    fi

    deleteCondition=$(whiptail --inputbox "Enter value to delete from table '$tableName':" 10 503>&1 1>&2 2>&3)
    [[ $? -ne 0 ]] && return

    tempFile=$(mktemp)
    grep -v "^$deleteCondition," "$dbPath/$tableName" > "$tempFile"
    mv "$tempFile" "$dbPath/$tableName"

    whiptail --title "Success" --msgbox "Data deleted successfully!" "$MENU_HEIGHT" "$MENU_WIDTH"
}


function deleteFromTable() {
    local dbName="$1"
    local dbPath="$DB_DIR/$dbName"
    get_terminal_size

    tableName=$(whiptail --inputbox "Enter Table name to delete data from:" 10 50 3>&1 1>&2 2>&3)
    [[ $? -ne 0 ]] && return

    if tableNotExists "$dbName" "$tableName"; then
        whiptail --title "Error" --msgbox "Table '$tableName' does not exist." "$MENU_HEIGHT" "$MENU_WIDTH"
        return
    fi

    local pkColumn=""
    local pkIndex=0
    local index=1

    while IFS=':' read -r colName colType colConstraint; do
        if [[ "$colConstraint" == "pk" ]]; then
            pkColumn="$colName"
            pkIndex=$index
            break
        fi
        ((index++))
    done < "$dbPath/$tableName.metadata"

    if [[ -z "$pkColumn" || "$pkIndex" -eq 0 ]]; then
        whiptail --title "Error" --msgbox "No primary key defined in metadata." "$MENU_HEIGHT" "$MENU_WIDTH"
        return
    fi

    pkValue=$(whiptail --inputbox "Enter $pkColumn value to delete:" 10 50 3>&1 1>&2 2>&3)
    [[ $? -ne 0 ]] && return

    if ! grep -E "^(.*?,){$((pkIndex-1))}$pkValue(,.*)?$" "$dbPath/$tableName" > /dev/null; then
        whiptail --title "Error" --msgbox "No record found with $pkColumn = $pkValue." "$MENU_HEIGHT" "$MENU_WIDTH"
        return
    fi

    tempFile=$(mktemp)
    grep -v -E "^(.*?,){$((pkIndex-1))}$pkValue(,.*)?$" "$dbPath/$tableName" > "$tempFile"
    mv "$tempFile" "$dbPath/$tableName"

    whiptail --title "Success" --msgbox "Record deleted successfully!" "$MENU_HEIGHT" "$MENU_WIDTH"
}


function updateRow() {
    local dbName="$1"
    local dbPath="$DB_DIR/$dbName"
    get_terminal_size

    tableName=$(whiptail --inputbox "Enter Table name to update data:" 10 50 3>&1 1>&2 2>&3)
    [[ $? -ne 0 ]] && return

    if tableNotExists "$dbName" "$tableName"; then
        whiptail --title "Error" --msgbox "Table '$tableName' does not exist." "$MENU_HEIGHT" "$MENU_WIDTH"
        return
    fi

    declare -A columnTypes
    local columns=()
    local pkColumn=""
    local pkIndex=0
    local index=1

    while IFS=':' read -r colName colType colConstraint; do
        columns+=("$colName")
        columnTypes["$colName"]="$colType"
        if [[ "$colConstraint" == "pk" ]]; then
            pkColumn="$colName"
            pkIndex=$index
        fi
        ((index++))
    done < "$dbPath/$tableName.metadata"

    if [[ -z "$pkColumn" || "$pkIndex" -eq 0 ]]; then
        whiptail --title "Error" --msgbox "No primary key defined in metadata." "$MENU_HEIGHT" "$MENU_WIDTH"
        return
    fi

    pkValue=$(whiptail --inputbox "Enter $pkColumn value to update:" 10 50 3>&1 1>&2 2>&3)
    [[ $? -ne 0 ]] && return

    if ! grep -E "^(.*?,){$((pkIndex-1))}$pkValue(,.*)?$" "$dbPath/$tableName" > /dev/null; then
        whiptail --title "Error" --msgbox "No record found with $pkColumn = $pkValue." "$MENU_HEIGHT" "$MENU_WIDTH"
        return
    fi

    colName=$(whiptail --inputbox "Enter Column name to update:" 10 50 3>&1 1>&2 2>&3)
    [[ $? -ne 0 ]] && return

    local colIndex=0
    for i in "${!columns[@]}"; do
        if [[ "${columns[$i]}" == "$colName" ]]; then
            colIndex=$((i + 1))
            break
        fi
    done

    if [[ "$colIndex" -eq 0 ]]; then
        whiptail --title "Error" --msgbox "Column '$colName' does not exist." "$MENU_HEIGHT" "$MENU_WIDTH"
        return
    fi

    if [[ "$colName" == "$pkColumn" ]]; then
        whiptail --title "Error" --msgbox "Cannot update primary key column." "$MENU_HEIGHT" "$MENU_WIDTH"
        return
    fi

    newValue=$(whiptail --inputbox "Enter new value for $colName (${columnTypes[$colName]}):" 10 50 3>&1 1>&2 2>&3)
    [[ $? -ne 0 ]] && return

    if [[ "${columnTypes[$colName]}" == "int" && ! "$newValue" =~ ^[0-9]+$ ]]; then
        whiptail --title "Error" --msgbox "$colName must be an integer." "$MENU_HEIGHT" "$MENU_WIDTH"
        return
    elif [[ "${columnTypes[$colName]}" == "str" && -z "$newValue" ]]; then
        whiptail --title "Error" --msgbox "$colName cannot be empty." "$MENU_HEIGHT" "$MENU_WIDTH"
        return
    fi

    awk -F',' -v pk="$pkValue" -v colIndex="$colIndex" -v newVal="$newValue" -v OFS=',' '
    $'"$pkIndex"' == pk { $colIndex = newVal }
    { print }
    ' "$dbPath/$tableName" > temp && mv temp "$dbPath/$tableName"

    whiptail --title "Success" --msgbox "Record updated successfully!" "$MENU_HEIGHT" "$MENU_WIDTH"
}
function insertIntoTable() {
    local dbName="$1"
    local dbPath="$DB_DIR/$dbName"
    get_terminal_size

    tableName=$(whiptail --inputbox "Enter Table name to Insert Data:" 10 50 3>&1 1>&2 2>&3)
    [[ $? -ne 0 ]] && return  # Exit if user cancels

    if tableNotExists "$dbName" "$tableName"; then
        whiptail --title "Error" --msgbox "Table '$tableName' does not exist." "$MENU_HEIGHT" "$MENU_WIDTH"
        return
    fi

    declare -A columnTypes
    local columns=()
    local pkColumn=""

    # Read metadata
    while IFS=':' read -r colName colType colConstraint; do
        columns+=("$colName")
        columnTypes["$colName"]="$colType"
        [[ "$colConstraint" == "pk" ]] && pkColumn="$colName"
    done < "$dbPath/$tableName.metadata"

    if [[ -z "$pkColumn" ]]; then
        whiptail --title "Error" --msgbox "No primary key defined in metadata." "$MENU_HEIGHT" "$MENU_WIDTH"
        return
    fi

    pkIndex=$(echo "${columns[@]}" | tr ' ' '\n' | grep -n "^$pkColumn$" | cut -d: -f1)

    declare -A existingPKs
    while IFS=',' read -r line; do
        pkValue=$(echo "$line" | cut -d',' -f"$pkIndex")
        existingPKs["$pkValue"]=1
    done < "$dbPath/$tableName"

    declare -a values
    for col in "${columns[@]}"; do
        local value=""
        while true; do
            value=$(whiptail --inputbox "Enter value for $col (${columnTypes[$col]}):" 10 50 3>&1 1>&2 2>&3)
            [[ $? -ne 0 ]] && return  # Exit if user cancels

            # Input validation
            if [[ "${columnTypes[$col]}" == "int" && ! "$value" =~ ^[0-9]+$ ]]; then
                whiptail --title "Error" --msgbox "Invalid input! $col must be an integer." "$MENU_HEIGHT" "$MENU_WIDTH"
            elif [[ "${columnTypes[$col]}" == "str" && -z "$value" ]]; then
                whiptail --title "Error" --msgbox "Invalid input! $col cannot be empty." "$MENU_HEIGHT" "$MENU_WIDTH"
            elif [[ "$col" == "$pkColumn" && -n "${existingPKs[$value]}" ]]; then
                whiptail --title "Error" --msgbox "Primary key value '$value' already exists." "$MENU_HEIGHT" "$MENU_WIDTH"
            else
                break
            fi
        done
        values+=("$value")
    done

    # Save data to the table
    local row=$(IFS=','; echo "${values[*]}")
    echo "$row" >> "$dbPath/$tableName"

    whiptail --title "Success" --msgbox "Data inserted successfully into '$tableName'!" "$MENU_HEIGHT" "$MENU_WIDTH"
}








