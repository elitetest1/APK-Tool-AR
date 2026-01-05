#!/bin/bash
DIR_INPUT="./input"
DIR_WORK="./work"
DIR_SIGN="./sign"
DIR_OUTPUT="./output"

KEY_PK8="platform.pk8"
CERT_PEM="platform.x509.pem"

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

init_check_folders() {
    required_dirs=("$DIR_INPUT" "$DIR_WORK" "$DIR_SIGN" "$DIR_OUTPUT")
    created_any=false

    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            echo -e "${YELLOW}[Info] Folder '$dir' not found. Creating it...${NC}"
            mkdir -p "$dir"
            created_any=true
        fi
    done

    if [ "$created_any" = false ]; then
         : 
    fi
}

pause() {
    echo -e "${YELLOW}Press [ENTER] to continue...${NC}"
    read -r
}

check_dependencies() {
    for cmd in apktool apksigner zipalign; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${RED}[Error] $cmd is not installed or not in your PATH.${NC}"
            exit 1
        fi
    done
}

decompile_apk() {
    echo -e "${CYAN}--- Decompile APK ---${NC}"
    
    count=$(ls -1 "$DIR_INPUT"/*.apk 2>/dev/null | wc -l)
    if [ "$count" -eq 0 ]; then
        echo -e "${RED}Folder '$DIR_INPUT' is empty. Place your .apk files there.${NC}"
        return
    fi

    echo "Select APK to decompile:"
    select apk_path in "$DIR_INPUT"/*.apk; do
        if [ -n "$apk_path" ]; then
            filename=$(basename -- "$apk_path")
            dirname="${filename%.*}"
            
            if [ -d "$DIR_WORK/$dirname" ]; then
                echo -e "${YELLOW}Work folder '$dirname' already exists. Overwrite? (y/n)${NC}"
                read -r resp
                if [[ $resp == "y" || $resp == "Y" ]]; then
                    rm -rf "$DIR_WORK/$dirname"
                else
                    echo "Operation cancelled."
                    break
                fi
            fi

            echo -e "${GREEN}Decompiling $filename...${NC}"
            apktool d --no-debug-info -f "$apk_path" -o "$DIR_WORK/$dirname"
            echo -e "${GREEN}Done.${NC}"
            break
        else
            echo "Invalid option."
        fi
    done
}

compile_apk() {
    echo -e "${CYAN}--- Build APK ---${NC}"
    
    if [ -z "$(ls -A $DIR_WORK)" ]; then
        echo -e "${RED}No projects found in '$DIR_WORK'. Decompile something first.${NC}"
        return
    fi

    echo "Select folder to build:"
    select project_path in "$DIR_WORK"/*/; do
        if [ -n "$project_path" ]; then
            project_path=${project_path%/}
            project_name=$(basename "$project_path")
            
            if [ ! -f "$project_path/apktool.yml" ]; then
                echo -e "${RED}Error: '$project_name' does not look like a valid apktool project.${NC}"
                break
            fi

            output_apk="$DIR_WORK/${project_name}_unsigned.apk"
            
            echo -e "${GREEN}Building $project_name...${NC}"
            apktool b -j 4 -srp "$project_path" -o "$output_apk"
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Build successful: ${NC}$output_apk"
            else
                echo -e "${RED}Build failed.${NC}"
            fi
            break
        else
            echo "Invalid option."
        fi
    done
}

sign_apk() {
    echo -e "${CYAN}--- Sign & Zipalign ---${NC}"
    
    KEY_PATH="$DIR_SIGN/$KEY_PK8"
    CERT_PATH="$DIR_SIGN/$CERT_PEM"
    
    if [[ ! -f "$KEY_PATH" || ! -f "$CERT_PATH" ]]; then
        echo -e "${RED}Error: Keys missing in '$DIR_SIGN'.${NC}"
        echo -e "Expected to find:\n - $KEY_PK8\n - $CERT_PEM"
        return
    fi

    count=$(ls -1 "$DIR_WORK"/*_unsigned.apk 2>/dev/null | wc -l)
    if [ "$count" -eq 0 ]; then
        echo -e "${RED}No unsigned APKs (*_unsigned.apk) found in '$DIR_WORK'.${NC}"
        return
    fi

    echo "Select APK to sign:"
    select apk_path in "$DIR_WORK"/*_unsigned.apk; do
        if [ -n "$apk_path" ]; then
            filename=$(basename -- "$apk_path")
            base_name="${filename%_unsigned.apk}"
            
            signed_apk="$DIR_WORK/${base_name}_firmado.apk"
            final_apk="$DIR_OUTPUT/${base_name}.apk"
            
            echo -e "${GREEN}>>> Signing...${NC}"
            apksigner sign --key "$KEY_PATH" --cert "$CERT_PATH" --out "$signed_apk" "$apk_path"
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}>>> Aligning (Zipalign)...${NC}"
                zipalign -p -f 4 "$signed_apk" "$final_apk"
                
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}Finished! Final file at:${NC} $final_apk"
                    rm "$signed_apk"
                else
                    echo -e "${RED}Zipalign error.${NC}"
                fi
            else
                echo -e "${RED}Signing error (apksigner).${NC}"
            fi
            break
        else
            echo "Invalid option."
        fi
    done
}

init_check_folders
check_dependencies

while true; do
    clear
    
    echo -e "\n${CYAN}APK-Tool AR${NC}"
    echo -e "${CYAN}=============================${NC}"
    echo "1) Decompile (input -> work)"
    echo "2) Build (work -> unsigned.apk)"
    echo "3) Sign (unsigned -> output)"
    echo "4) Exit"
    echo -e "${CYAN}=============================${NC}"
    
    read -p "Choose option: " opt
    case $opt in
        1) decompile_apk; pause ;;
        2) compile_apk; pause ;;
        3) sign_apk; pause ;;
        4) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option." ;;
    esac
done