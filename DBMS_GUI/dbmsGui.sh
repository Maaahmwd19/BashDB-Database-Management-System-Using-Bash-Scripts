#!/usr/bin/bash

source $GuiPath/db_operations_Gui.sh
declare -f listDb

# Database directory
export DB_DIR="/usr/lib/myDBMS_ITI"


# Function to get terminal size safely
function get_terminal_size() {
    local size=$(stty size) 
    TERMINAL_HEIGHT=$(echo "$size" | awk '{print $1}') 
    TERMINAL_WIDTH=$(echo "$size" | awk '{print $2}') 

    # Adjust for whiptail (ensure minimum sizes)
    MENU_HEIGHT=$((TERMINAL_HEIGHT - 7))
    MENU_WIDTH=$((TERMINAL_WIDTH > 100 ? TERMINAL_WIDTH - 20 : 80))

    # Ensure minimum dimensions
    if [[ $MENU_HEIGHT -lt 15 ]]; then MENU_HEIGHT=15; fi
    if [[ $MENU_WIDTH -lt 50 ]]; then MENU_WIDTH=50; fi
}

# Main Menu Function
function mainMenu() {
    while true; do
        get_terminal_size # Get updated terminal size dynamically

        CHOICE=$(whiptail --title "ITI DBMS Project" --menu "Choose an option:" \
            "$MENU_HEIGHT" "$MENU_WIDTH" 7 \
            "1" "Create Database" \
            "2" "List Databases" \
            "3" "Connect to Database" \
            "4" "Drop Database" \
            "5" "Rename Database" \
            "6" "Exit" 3>&1 1>&2 2>&3)

        EXIT_STATUS=$?
        if [ $EXIT_STATUS -ne 0 ]; then
            exit
        fi

        case $CHOICE in
            1) createDb ;;
            2) listDb ;;
            3) connectDb ;;
            4) dropDb ;;
            5) renameDb ;;
            6) whiptail --title "Goodbye" --msgbox "Goodbye ^_^" 10 50 ; exit;;
        esac
    done
}

# Ensure whiptail is installed
if ! command -v whiptail &> /dev/null; then
    echo "Error: whiptail is not installed. Install it using: sudo yum install -y newt"
    exit 1
fi

# Run the main menu
mainMenu
