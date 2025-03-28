#!/usr/bin/bash
source $GuiPath/utils_Gui.sh
source $GuiPath/table_operations_Gui.sh



function get_terminal_size() {
    local size=$(stty size)
    TERMINAL_HEIGHT=$(echo "$size" | awk '{print $1}')
    TERMINAL_WIDTH=$(echo "$size" | awk '{print $2}')
    ((MENU_HEIGHT = TERMINAL_HEIGHT - 4))
    ((MENU_WIDTH = TERMINAL_WIDTH - 10))
}

function createDb() {
    get_terminal_size
    dbName=$(whiptail --inputbox "Enter Database Name:"  10 50 3>&1 1>&2 2>&3)

    [[ $? -ne 0 ]] && return

    dbName=$(echo "$dbName" | awk '{print tolower($0)}' | tr -d ' ')

    if ! validateDbName "$dbName"; then return; fi
    if databaseExists "$dbName"; then return; fi

    mkdir -p "$DB_DIR/$dbName"
    whiptail --msgbox " Database '$dbName' created successfully!" "$MENU_HEIGHT" "$MENU_WIDTH"
}

function listDb() {
    get_terminal_size
    dbList=$(ls -1 "$DB_DIR" 2>/dev/null | nl)
    [[ -z "$dbList" ]] && dbList=" No databases found."
    
    whiptail --title "Available Databases" --msgbox "$dbList" "$MENU_HEIGHT" "$MENU_WIDTH"
}

function connectDb() {
    get_terminal_size
    dbName=$(whiptail --inputbox "Enter Database Name to Connect:" 10 50 3>&1 1>&2 2>&3)
    
    [[ $? -ne 0 ]] && return

    dbName=$(echo "$dbName" | awk '{print tolower($0)}' | tr -d ' ')

    if databaseNotExists "$dbName"; then return; fi

    tableMenu "$dbName"
}

function dropDb() {
    get_terminal_size
    dbName=$(whiptail --inputbox "Enter Database Name to Drop:" 10 50 3>&1 1>&2 2>&3)
    
    [[ $? -ne 0 ]] && return

    if databaseNotExists "$dbName"; then return; fi

    rm -rf "$DB_DIR/$dbName"
    whiptail --msgbox "Database '$dbName' deleted successfully!" 10 50
}

function renameDb() {
    get_terminal_size
    dbName=$(whiptail --inputbox "Enter Database Name to Rename:" 10 50 3>&1 1>&2 2>&3)
    
    [[ $? -ne 0 ]] && return

    if databaseNotExists "$dbName"; then return; fi

    newNameDb=$(whiptail --inputbox "Enter New Database Name:" 10 50 3>&1 1>&2 2>&3)
    
    [[ $? -ne 0 ]] && return

    newNameDb=$(echo "$newNameDb" | awk '{print tolower($0)}' | tr -d ' ')

    if databaseExists "$newNameDb"; then return; fi

    mv "$DB_DIR/$dbName" "$DB_DIR/$newNameDb"
    whiptail --msgbox " Database '$dbName' renamed to '$newNameDb' successfully!" 10 50
}
