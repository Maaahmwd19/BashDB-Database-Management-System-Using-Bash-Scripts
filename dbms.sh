#!/usr/bin/bash

export path=$PWD

# Colors
export RED='\e[31m'
export GREEN='\e[32m'
export YELLOW='\e[33m'
export BLUE='\e[34m'
export RESET='\e[0m'

# Ensure the database directory exists
if [[ ! -d "$path/databases" ]]; then
    mkdir "$path/databases"
    echo -e "${GREEN}DBMS Created Successfully....${RESET}"
fi

# Function to display header
function header() {
    echo -e "\\n${BLUE}+--------------------------------------------------------------------+"
    echo        "|                      ITI DBMS Project Telecom 45                   |"
    echo -e    "+--------------------------------------------------------------------+${RESET}\\n"
}

# Function for the main menu
function mainMenu() {
PS3="
ITI-DBMS [Select the option] >> "
   
    header
    source db_operations.sh
    echo  -e "======================== Database Operations ========================\\n"

    select option in "Create Database" "List all Databases" "Connect to Database" "Drop Database" "Rename Database" "Refresh Menu" "Exit"; do
        case $option in 
            "Create Database") createDb ;;
            "List all Databases") listDb ;; 
            "Connect to Database") connectDb ;; 
            "Drop Database") dropDb ;;
            "Rename Database") renameDb ;;
            "Refresh Menu") clear; mainMenu; exit ;;
            "Exit")
                echo -e "${GREEN}Goodbye ^_^${RESET}\\n"
                break
                ;;
            *)
                echo -e "${RED}Invalid Input... Try Again.${RESET}"
                ;;
        esac
    done
}

# Run the main menu
mainMenu
