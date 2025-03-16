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
        mkdir -p "$path/databases/$dbName"
        echo -e "${GREEN}Database '$dbName' created successfully${REST}."
    fi
}

# Define Colors
GREEN='\e[32m'
RED='\e[31m'
REST='\e[0m'  # Reset color

listDb() {
    if [[ -d "$path/databases" && "$(ls -A "$path/databases")" ]]; then
        echo -e "${GREEN}Available Databases${REST}"
        echo -e "${GREEN}--------------------${REST}"
        ls -1 "$path/databases" | awk '{print NR ") " $0}'
    else
        echo -e "${RED}Error: No databases found.${REST}"
    fi
}



function connectDb()
{
    read -p "Enter Database Name to Connect: " dbName
    dbName=$(echo "$dbName" | awk '{print tolower($0)}')
    dbName=${dbName// /_}

    if ! validateDbName "$newNameDb"; then
        return
    fi

    if databaseExists "$newNameDb"; then
        return
    else
        cd  $path/databases/$dbName || exit
        source "$path/table_operations.sh"
        clear
        tableMenu
    fi
}


function dropDb()
{
    read -p "Enter Name of Database to Drop : " dbName
     if ! databaseNotExists "$dbName"; then
        return
    else
        rm -rf  $path/databases/$dbName || exit
        echo -e "${GREEN}$dbName Deleted successfully${REST}"
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
        mv "$path/databases/$dbName" "$path/databases/$newNameDb"
        echo -e "${GREEN}Database '$dbName' renamed to '$newNameDb' successfully.${REST}"
        fi
    fi
}

