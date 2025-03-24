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

    local PK=0 

    for ((i = 1; i <= tableColumns; i++)); do
        read -p "Enter name of column $i: " columnName

        if ! validateColumnName "$columnName"; then
            return
        fi

        if columnExists "$tableName" "$columnName"; then
            echo "Column '$columnName' already exists!"
            return
        fi

        read -p "Enter data type (str/int): " dataType

        if [[ "$dataType" != "int" && "$dataType" != "str" ]]; then
            echo "Invalid data type..."
            rm -rf "$DB_DIR/$dbName/$tableName"*
            return
        fi
 
        if (( PK == 0 )); then
            read -p "Is '$columnName' the Primary Key? (y/n): " pkValidation
            if [[ "$pkValidation" =~ ^[Yy] ]]; then  
                PK=1
                echo "$columnName:$dataType:pk" >> "$DB_DIR/$dbName/$tableName.metadata"
                continue  
            fi
        fi

        echo "$columnName:$dataType" >> "$DB_DIR/$dbName/$tableName.metadata"

    done

    # handel if no primary key is set ---> set first column is as a pk
    if (( PK == 0 )); then
        sed -i '1s/$/:pk/' "$DB_DIR/$dbName/$tableName.metadata"
    fi

    echo -e "${GREEN}Table '$tableName' created successfully with $tableColumns columns!${REST}"
}



function listTables() {
    local dbPath="/usr/lib/myDBMS_ITI/$dbName"

    if [[ -d "$dbPath" && "$(ls -A "$dbPath")" ]]; then
        echo -e "${GREEN}\\nAvailable Tables${REST}"
        echo -e "${GREEN}--------------------${REST}"
        ls -1 "$dbPath" | grep -v '\.metadata$' | awk '{print NR ") " $0}'
    else
        echo -e "${RED}\\n$dbName/_db dose not have any tables.....${REST}"
    fi
}


function dropTable()
{
    local dbPath="$DB_DIR/$dbName"
    read -p "Enter Table Name To drop: " tableName
    
    
    if tableNotExists "$tableName" ; then
    return
    fi

     rm -rf "$dbPath/$tableName"*

    if [ ! -f "$dbPath/$tableName.meta" ]; then
        echo -e "${GREEN}Table '$tableName' deleted successfully.${REST}"
    else
        echo -e "${RED}Error: Failed to delete table '$tableName'.${REST}"
    fi
}


function selectFromTable()
{
    local dbPath="/usr/lib/myDBMS_ITI/$dbName"

    read -p "Enter Table name to retrive Data: " tableName
    if tableNotExists "$tableName";then
    return
    fi

    # table header 
    # ============
    awk -F':' 'BEGIN {header = ""; border = "+"}

    {
        header = header sprintf("| %-10s ", $1);
        border = border "------------+"
    }

    END {
        print border;
        print header "|";
        print border;
    }' "$dbPath/$tableName.metadata"

    # table contant
    # ==============
    awk -F',' '
    {
        if (NR == 1) numCols = NF;  
        printf "|";
        for (i = 1; i <= NF; i++) {
            printf " %-10s |", $i;
        }
        print "";

        rowCount = NR;  
    }

    END {
        if (rowCount > 0) {
            # Print bottom border
            printf "+";
            for (i = 1; i <= numCols; i++) {
                printf "------------+";
            }
            print "";
            print rowCount " rows in set";
        } else {
            print "Table is empty";
        }
    }' "$dbPath/$tableName"


}

function insertIntoTable() {
    local dbPath="/usr/lib/myDBMS_ITI/$dbName"
    read -p "Enter Table name to Insert Data: " tableName

   
    if tableNotExists "$tableName";then
    return
    fi
    # قراءة الـ meta data (الأعمدة وأنواع البيانات)
    declare -A columnTypes
    local columns=()
    
    while IFS=':' read -r colName colType; do
        columns+=("$colName")
        columnTypes["$colName"]="$colType"
    done < "$tableName.metadata"

    declare -a values
    for col in "${columns[@]}"; do
        local value
        while true; do
            read -p "Enter value for $col (${columnTypes[$col]}): " value

            # التحقق من نوع البيانات
            if [[ "${columnTypes[$col]}" == "int" && ! "$value" =~ ^[0-9]+$ ]]; then
                echo "⚠️ Error: $col must be an integer."
            elif [[ "${columnTypes[$col]}" == "float" && ! "$value" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                echo "⚠️ Error: $col must be a float."
            elif [[ "${columnTypes[$col]}" == "string" && -z "$value" ]]; then
                echo "⚠️ Error: $col cannot be empty."
            else
                break  # إذا كان الإدخال صحيحًا، نخرج من الحلقة
            fi
        done
        values+=("$value")
    done

    # تكوين السطر الجديد
    local row=$(IFS=','; echo "${values[*]}")

    # إدراج الصف الجديد باستخدام `sed`
    sudo sed -i "\$a$row" "$dbPath/$tableName"

    echo "✅ Data inserted successfully into '$tableName'."
}


function deleteFromTable()
{
    local dbPath="/usr/lib/myDBMS_ITI/$dbName"

    read -p "Enter Table name to Delete from Data: " tableName
    if tableNotExists "$tableName";then
    return
    fi

    #continue

}

function updateRow()
{
    local dbPath="/usr/lib/myDBMS_ITI/$dbName"

    read -p "Enter Table name to Uodate on Data: " tableName
    if tableNotExists "$tableName";then
    return
    fi

    #continue
}

