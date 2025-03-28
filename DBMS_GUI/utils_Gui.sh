#!/usr/bin/bash

function validateDbName() {
    [[ ! "$1" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]] && whiptail --msgbox "Invalid database name!" 8 40 && return 1
    return 0
}

function databaseExists() {
    [[ -d "$DB_DIR/$1" ]] && whiptail --msgbox "Database already exists!" 8 40 && return 0
    return 1
}

function databaseNotExists() {
    [[ ! -d "$DB_DIR/$1" ]] && whiptail --msgbox "Database does not exist!" 8 40 && return 0
    return 1
}

function tableExists() {
    [[ -f "$DB_DIR/$1/$2" ]] && whiptail --msgbox "Table already exists!" 8 40 && return 0
    return 1
}

function tableNotExists() {
    local dbName="$1"
    local tableName="$2"
    local dbPath="$DB_DIR/$dbName"

    # Ensure the database exists
    if [[ ! -d "$dbPath" ]]; then
        whiptail --title "Error" --msgbox "Database '$dbName' does not exist." 10 50
        return 0  # Return true (table does not exist)
    fi

    # Ensure the table file exists (without metadata)
    if [[ ! -f "$dbPath/$tableName" ]]; then
        whiptail --title "Error" --msgbox "Table '$tableName' does not exist." 10 50
        return 0  # Return true (table does not exist)
    fi

    return 1  # Return false (table exists)
}

