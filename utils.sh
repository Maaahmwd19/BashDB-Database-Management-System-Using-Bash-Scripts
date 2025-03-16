#! /usr/bin/bash
function validateDbName() {
    local dbName="$1"
    if [[ ! $dbName =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        echo -e "${RED}Error: Database name must start with a letter and can only contain letters, numbers, and underscores.${REST}"
        return 1  
    fi
    return 0  
}

databaseExists() {
    local dbName="$1"
    if [[ -d "$path/databases/$dbName" ]]; then
        echo -e "${RED}Error: Database '$dbName' already exists.${REST}"
        return 0  
    fi
    return 1  
}

databaseNotExists() {
    local dbName="$1"
    if [[ ! -d "$path/databases/$dbName" ]]; then
        echo -e "${RED}Error: Database '$dbName' doesn't exist.${REST}"
        return 0 
    fi
    return 1  
}