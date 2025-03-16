#! /usr/bin/bash
source utils.sh
tableMenu() {
    PS3="
ITI-DBMS [$dbName] >> " 
    header
    echo -e "Connected to Database '$dbName' successfully......!  \\n"

    echo "================================= Table Operations ================================="
    select choice in "Create Table" "List Tables" "Drop Table" "Insert into Table" "Select from Table" "Delete from Table" "Update Row"  "Back to Main Menu"
    do
        case $REPLY in  
            1) createTable ;;
            2) listTables ;;
            3) dropTable ;; 
            4) insertIntoTable ;;  
            5) selectFromTable ;;
            6) deleteFromTable ;;
            7) updateRow ;;
            8)cd ../..  
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



    for ((i = 1; i <= tableColumns; i++)); do
        read -p "Enter name of column $i: " columnName


        if ! validateColumnName "$columnName"; then
            return
        fi
        if columnExists "$columnName"; then
        return
        else
        read -p "Enter data type (str/int): " dataType

        if [[ "$dataType" != "int" && "$dataType" != "str" ]]; then
            echo "Invalid data type..."
            rm -rf "$DB_DIR/$dbName/$tableName"*  
            return
        else
            echo "$columnName:$dataType" >> "$DB_DIR/$dbName/$tableName.metadata"
        fi
        fi
    done

    echo -e "{$GREEN}Table '$tableName' created successfully with $tableColumns columns!{$REST}"
}



function listTables() {
    local dbPath="/usr/lib/myDBMS_ITI/$dbName"

    if [[ -d "$dbPath" && "$(ls -A "$dbPath")" ]]; then
        echo -e "${GREEN}Available Tables${REST}"
        echo -e "${GREEN}--------------------${REST}"
        ls -1 "$dbPath" | grep -v '\.metadata$' | awk '{print NR ") " $0}'
    else
        echo -e "${RED}Error: No Tables found.${REST}"
    fi
}


function dropTable()
{
    echo "Drop table"
}

function insertIntoTable()
{
    echo "selectFromTable"
}
function selectFromTable()
{
    echo "selectFromTable"
}
function deleteFromTable()
{
    echo "deleteFromTable"
}
function updateRow()
{
    echo "updateRow"
}

