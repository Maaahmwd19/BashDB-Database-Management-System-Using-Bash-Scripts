#! /usr/bin/bash

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


function createTable()
{
    echo "create tables"
    touch file
}

function listTables()
{
    echo "list tables"
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

