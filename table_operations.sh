#!/usr/bin/bash
source utils.sh

tableMenu() {
    echo $1
    dbName="$1"
    PS3="
ITI-DBMS [$dbName] >> "
    header
    echo -e "Connected to Database '$dbName' successfully......!  \\n"

    echo "================================= Table Operations ================================="
    select choice in "Create Table" "List Tables" "Drop Table" "Insert into Table" "Select from Table" "Delete from Table" "Update Row" "Select From Table (Bonus)" "Back to Main Menu"
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
            9) cd ../..; clear; mainMenu; exit ;;
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

    if (( PK == 0 )); then
        sed -i '1s/$/:pk/' "$DB_DIR/$dbName/$tableName.metadata"
    fi

    echo -e "${GREEN}Table '$tableName' created successfully with $tableColumns columns!${RESET}"
}

function listTables() {
    local dbPath="/usr/lib/myDBMS_ITI/$dbName"

    if [[ -d "$dbPath" && "$(ls -A "$dbPath")" ]]; then
        echo -e "${GREEN}\\nAvailable Tables${RESET}"
        echo -e "${GREEN}--------------------${RESET}"
        ls -1 "$dbPath" | grep -v '\.metadata$' | awk '{print NR ") " $0}'
    else
        echo -e "${RED}\\n$dbName/_db does not have any tables.....${RESET}"
    fi
}

function dropTable() {
    local dbPath="$DB_DIR/$dbName"
    read -p "Enter Table Name To drop: " tableName

    if tableNotExists "$tableName"; then
        return
    fi

    rm -rf "$dbPath/$tableName"*

    if [ ! -f "$dbPath/$tableName.meta" ]; then
        echo -e "${GREEN}Table '$tableName' deleted successfully.${RESET}"
    else
        echo -e "${RED}Error: Failed to delete table '$tableName'.${RESET}"
    fi
}

function selectFromTable() {
    local dbPath="/usr/lib/myDBMS_ITI/$dbName"

    read -p "Enter Table name to retrieve Data: " tableName
    if tableNotExists "$tableName"; then
        return
    fi

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

function insertIntoTable() {
    local dbPath="/usr/lib/myDBMS_ITI/$dbName"
    read -p "Enter Table name to Insert Data: " tableName

    if tableNotExists "$tableName"; then
        return
    fi

    declare -A columnTypes
    local columns=()
    local pkColumn=""

    while IFS=':' read -r colName colType colConstraint; do
        columns+=("$colName")
        columnTypes["$colName"]="$colType"
        if [[ "$colConstraint" == "pk" ]]; then
            pkColumn="$colName"
        fi
    done < "$tableName.metadata"

    if [[ -z "$pkColumn" ]]; then
        echo -e "${RED}Error: No primary key defined in metadata.${RESET}"
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
        local value
        while true; do
            read -p "Enter value for $col (${columnTypes[$col]}): " value

            if [[ "${columnTypes[$col]}" == "int" && ! "$value" =~ ^[0-9]+$ ]]; then
                echo -e "${RED}Error: $col must be an integer.${RESET}"
            elif [[ "${columnTypes[$col]}" == "str" && -z "$value" ]]; then
                echo -e "${RED}Error: $col cannot be empty.${RESET}"
            elif [[ "$col" == "$pkColumn" && -n "${existingPKs[$value]}" ]]; then
                echo -e "${RED}Error: Primary key value '$value' already exists.${RESET}"
            else
                break
            fi
        done
        values+=("$value")
    done

    local row=$(IFS=','; echo "${values[*]}")
    echo "$row" >> "$dbPath/$tableName"
    echo -e "${GREEN}Data inserted successfully into '$tableName'.${RESET}"

    exportTableToXML "$tableName"
    exportTableToJSON "$tableName"
}

function deleteFromTable() {
    local dbPath="/usr/lib/myDBMS_ITI/$dbName"
    read -p "Enter Table name to delete data from: " tableName

    if tableNotExists "$tableName"; then
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
    done < "$tableName.metadata"

    if [[ -z "$pkColumn" || "$pkIndex" -eq 0 ]]; then
        echo -e "${RED}Error: No primary key defined in metadata.${RESET}"
        return
    fi

    read -p "Enter $pkColumn value to delete: " pkValue

    if ! grep -E "^(.*?,){$((pkIndex-1))}$pkValue(,.*)?$" "$dbPath/$tableName" > /dev/null; then
        echo -e "${RED}Error: No record found with $pkColumn = $pkValue.${RESET}"
        return
    fi

    grep -v -E "^(.*?,){$((pkIndex-1))}$pkValue(,.*)?$" "$dbPath/$tableName" > temp || true

    > "$dbPath/$tableName"
    cat temp >> "$dbPath/$tableName"
    rm -f temp

    echo -e "${GREEN}Record deleted successfully.${RESET}"

    exportTableToXML "$tableName"
    exportTableToJSON "$tableName"
}

function updateRow() {
    local dbPath="/usr/lib/myDBMS_ITI/$dbName"
    read -p "Enter Table name to update data: " tableName

    if tableNotExists "$tableName"; then
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
    done < "$tableName.metadata"

    if [[ -z "$pkColumn" || "$pkIndex" -eq 0 ]]; then
        echo -e "${RED}Error: No primary key defined in metadata.${RESET}"
        return
    fi

    echo "Available columns: ${columns[*]}"
    read -p "Enter $pkColumn value to update: " pkValue

    if ! grep -E "^(.*?,){$((pkIndex-1))}$pkValue(,.*)?$" "$dbPath/$tableName" > /dev/null; then
        echo -e "${RED}Error: No record found with $pkColumn = $pkValue.${RESET}"
        return
    fi

    read -p "Enter Column name to update: " colName

    local colIndex=0
    for i in "${!columns[@]}"; do
        if [[ "${columns[$i]}" == "$colName" ]]; then
            colIndex=$((i + 1))
            break
        fi
    done

    if [[ "$colIndex" -eq 0 ]]; then
        echo -e "${RED}Error: Column '$colName' does not exist.${RESET}"
        return
    fi

    if [[ "$colName" == "$pkColumn" ]]; then
        echo -e "${RED}Error: Cannot update primary key column.${RESET}"
        return
    fi

    read -p "Enter new value for $colName (${columnTypes[$colName]}): " newValue

    if [[ "${columnTypes[$colName]}" == "int" && ! "$newValue" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Error: $colName must be an integer.${RESET}"
        return
    elif [[ "${columnTypes[$colName]}" == "str" && -z "$newValue" ]]; then
        echo -e "${RED}Error: $colName cannot be empty.${RESET}"
        return
    fi

    awk -F',' -v pk="$pkValue" -v colIndex="$colIndex" -v newVal="$newValue" -v OFS=',' '
    $'"$pkIndex"' == pk { $colIndex = newVal }
    { print }
    ' "$dbPath/$tableName" > temp && mv temp "$dbPath/$tableName"

    echo -e "${GREEN}Record updated successfully.${RESET}"

    exportTableToXML "$tableName"
    exportTableToJSON "$tableName"
}

# --- XML Exporter ---
function exportTableToXML() {
    local dbPath="/usr/lib/myDBMS_ITI/$dbName"
    local tableName="$1"

    if tableNotExists "$tableName"; then
        return
    fi

    local xmlFile="${dbPath}/${tableName}.xml"
    local tmpFile=$(mktemp)

    echo "<table name=\"$tableName\">" > "$tmpFile"

    mapfile -t columns < <(awk -F':' '{print $1}' "$dbPath/$tableName.metadata")

    while IFS=',' read -r line; do
        IFS=',' read -ra values <<< "$line"
        echo "  <row>" >> "$tmpFile"
        for i in "${!columns[@]}"; do
            echo "    <${columns[$i]}>${values[$i]}</${columns[$i]}>" >> "$tmpFile"
        done
        echo "  </row>" >> "$tmpFile"
    done < "$dbPath/$tableName"

    echo "</table>" >> "$tmpFile"

    mv "$tmpFile" "$xmlFile"
    echo -e "${GREEN}Table '$tableName' exported automatically to XML.${RESET}"
}

# --- JSON Exporter ---
function exportTableToJSON() {
    local dbPath="/usr/lib/myDBMS_ITI/$dbName"
    local tableName="$1"

    if tableNotExists "$tableName"; then
        return
    fi

    local jsonFile="${dbPath}/${tableName}.json"
    local tmpFile=$(mktemp)

    echo "{" > "$tmpFile"
    echo "  \"table\": \"$tableName\"," >> "$tmpFile"
    echo "  \"rows\": [" >> "$tmpFile"

    mapfile -t columns < <(awk -F':' '{print $1}' "$dbPath/$tableName.metadata")

    firstRow=true
    while IFS=',' read -r line; do
        if [[ "$firstRow" == false ]]; then
            echo "," >> "$tmpFile"
        fi
        firstRow=false
        
        IFS=',' read -ra values <<< "$line"
        echo "    {" >> "$tmpFile"
        for i in "${!columns[@]}"; do
            if [[ $i -gt 0 ]]; then
                echo "," >> "$tmpFile"
            fi
            printf "      \"%s\": \"%s\"" "${columns[$i]}" "${values[$i]}" >> "$tmpFile"
        done
        echo -e "\n    }" >> "$tmpFile"
    done < "$dbPath/$tableName"

    echo "  ]" >> "$tmpFile"
    echo "}" >> "$tmpFile"

    mv "$tmpFile" "$jsonFile"
    echo -e "${GREEN}Table '$tableName' exported automatically to JSON.${RESET}"
}
