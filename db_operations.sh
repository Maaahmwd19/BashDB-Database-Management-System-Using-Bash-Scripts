#!/usr/bin/bash
source utils.sh

function createDb()
{
    read -p "Enter Database Name: " dbName
    dbName=$(echo "$dbName" | awk '{print tolower($0)}')
    dbName=${dbName// /_}

    if ! validateDbName "$dbName"; then
        return
    fi

    if databaseExists "$dbName"; then
        return
    else
        mkdir -p "$DB_DIR/$dbName"
        echo -e "${GREEN}Database '$dbName' created successfully${RESET}."
    fi
}


listDb() {
    if [[ -d "$DB_DIR" && "$(ls -A "$DB_DIR")" ]]; then
        echo -e "${GREEN}Available Databases${RESET}"
        echo -e "${GREEN}--------------------${RESET}"
        ls -1 "$DB_DIR" | awk '{print NR ") " $0}'
    else
        echo -e "${RED}Error: No databases found.${RESET}"
    fi
}



function connectDb()
{
    read -p "Enter Database Name to Connect: " dbName
    
    dbName=$(echo "$dbName" | awk '{print tolower($0)}')
    dbName=${dbName// /_}

    if ! validateDbName "$dbName"; then
        return
    fi

    if databaseNotExists "$dbName"; then
        return
    fi

    cd "$DB_DIR/$dbName" || exit
        source "table_operations.sh"
    clear
    tableMenu
}


function dropDb()
{
    read -p "Enter Name of Database to Drop : " dbName

    if databaseNotExists "$dbName"; then
        return  
    fi

    rm -rf "$DB_DIR/$dbName"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Database '$dbName' deleted successfully.${RESET}"
    else
        echo -e "${RED}Error: Failed to delete database '$dbName'.${RESET}"
    fi
}

renameDb()
{
    read -p "Enter Name of Database to rename : " dbName
     if databaseNotExists "$dbName"; then
        return
    else
        read -p "Enter New name of database : " newNameDb
            
        newNameDb=$(echo "$newNameDb" | awk '{print tolower($0)}')
        newNameDb=${newNameDb// /_}

        if ! validateDbName "$newNameDb"; then
        return
        fi

        if databaseExists "$newNameDb"; then
        return
        else
        mv "$DB_DIR/$dbName" "$DB_DIR/$newNameDb"
        echo -e "${GREEN}Database '$dbName' renamed to '$newNameDb' successfully.${RESET}"
        fi
    fi
}

