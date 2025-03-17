#! /usr/bin/bash

# =================================== database validations ===================================
function validateDbName() {
    local dbName="$1"
    if [[ ! $dbName =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
    
        echo -e "${RED}Error: Database name must start with a letter and can only contain letters, numbers, and underscores.${REST}"
        return 1  
    fi
    return 0  
}

function databaseExists() {
    local dbName="$1"
    if [[ -d "/usr/lib/myDBMS_ITI/$dbName" ]]; then
    
        echo -e "${RED}Error: Database '$dbName' already exists.${REST}"
        return 0  
    fi
    return 1  
}

function databaseNotExists() {
    local dbName="$1"
    if [[ ! -d "/usr/lib/myDBMS_ITI/$dbName" ]]; then

        echo -e "${RED}Error: Database '$dbName' doesn't exist.${REST}"
        return 0 
    fi
    return 1  
}

#  =================================== Table validations ===================================

function validateTableName() {
    local tableName="$1"
    if [[ ! $tableName =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        
        echo -e "${RED}Error: Table name must start with a letter and can only contain letters, numbers, and underscores.${REST}"
        return 1  
    fi
    return 0  
}

function tableExists() {
    local tableName="$1"
    if [[ -f "/usr/lib/myDBMS_ITI/$dbName/$tableName" ]]; then
        
        echo -e "${RED}Error: Table '$tableName' already exists.${REST}"
        return 0  
    fi
    return 1  
}


function tableNotExists() {
    local tableName="$1"
    if [[ ! -f "/usr/lib/myDBMS_ITI/$dbName/$tableName" ]]; then
        
        echo -e "${RED}Error: Table '$tableName' doesn't exist.${REST}"
        return 0 
    fi
    return 1  
}


function validateColumnName() {
    local columnName="$1"
    if [[ ! $columnName =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        
        echo -e "${RED}Error: Column name must start with a letter and can only contain letters, numbers, and underscores.${REST}"
        rm -rf "$DB_DIR/$dbName/$tableName"*  

        return 1  
    fi
    return 0  
}

function validateColumNumber() {
    local tableColumns="$1"
    
    if ! [[ "$tableColumns" =~ ^[0-9]+$ && "$tableColumns" -gt 0 ]]; then
        
        echo -e "${RED}Invalid input. Please enter a positive number.${REST}"
        return 1  
    fi
    
    return 0 
}

function columnExists() {
    local columnName="$1"
    local metadataFile="$DB_DIR/$dbName/$tableName.metadata"
    
    if grep -q "^$columnName:" "$metadataFile"; then
        
        echo -e "${RED}Error: Column '$columnName' already exists in table '$tableName'.${REST}"
        rm -rf "$DB_DIR/$dbName/$tableName"*  
        return 0  
    fi
    return 1  
}
