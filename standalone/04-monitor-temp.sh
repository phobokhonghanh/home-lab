#!/bin/bash

# ==============================================================================
# System Status Monitor for Server Laptop
# ==============================================================================

# Initializes terminal color codes.
init_colors() {
    GREEN="\033[32m"
    YELLOW="\033[33m"
    RED="\033[31m"
    BLUE="\033[34m"
    RESET="\033[0m"
}

# Helper functions for logging (optional in this script but good for consistency)
# We are mainly formatting output directly here.

# Checks if the required 'sensors' command is available.
#
# @return Exits with 1 if lm-sensors is missing.
check_requirements() {
    if ! command -v sensors &>/dev/null; then
        printf "${RED}[ERROR] lm-sensors is not installed. Run 'sudo ./requirements.sh'${RESET}\n"
        exit 1
    fi
}

# Displays current RAM and Swap usage in a human-readable format.
display_memory() {
    printf "${BLUE}Memory Usage:${RESET}\n"
    free -h | awk '
        /^Mem:/ {print "  RAM:  Used: "$3" / Total: "$2}
        /^Swap:/ {print "  Swap: Used: "$3" / Total: "$2}
    '
}

# Displays disk usage for partitions mounted from /dev/.
display_disk() {
    printf "${BLUE}Disk usage:${RESET}\n"
    df -h | grep '^/dev/' | awk '{print "  " $6 ": Used: " $3 " / Total: " $2 " (" $5 ")"}'
}

# Extracts and displays CPU temperature with status colors.
# Status colors: <70°C (Green), 70-80°C (Yellow), >80°C (Red).
display_cpu_temp() {
    printf "${BLUE}CPU Temperature:${RESET}\n"
    local sensor_count=1
    sensors | grep -E 'Package|Package id|temp1|Tdie|Tctl' | while read -r line; do
        local temp
        temp=$(echo "$line" | grep -oP '[-+]?\d+(\.\d+)?(?=\s*°C|C)' | head -n 1 | tr -d '+')
        if [[ -z "$temp" ]]; then continue; fi

        local name
        if [[ "$line" == *"Package id 0"* ]]; then
            name="CPU Package"
        elif [[ "$line" == *"temp1"* ]]; then
            name="System Sensor $sensor_count"
            ((sensor_count++))
        else
            name=$(echo "$line" | cut -d: -f1)
        fi

        local temp_int=${temp%.*}
        local color=$GREEN
        local label="[INFO]"

        if [[ "$temp_int" -ge 80 ]]; then
            color=$RED
            label="[ERROR]"
        elif [[ "$temp_int" -ge 70 ]]; then
            color=$YELLOW
            label="[WARN]"
        fi

        printf "  ${color}%-8s %-20s %s°C${RESET}\n" "$label" "$name" "$temp_int"
    done
}

# Main loop to display system status components.
#
# @param $@ Array of arguments passed to script.
main() {
    printf "\n------------------------------------------------------------------------------------\n"
    init_colors
    check_requirements
    printf "Timestamp: %s\n" "$(date '+%Y-%m-%d %H:%M:%S')"
    display_memory
    display_disk
    display_cpu_temp
    printf "${BLUE}Summary: Safe < 70C | Warning 70-80C | Danger > 80C${RESET}"
    printf "\n------------------------------------------------------------------------------------\n"
}

main "$@"
