#!/bin/bash

# Progress Indicators Utility Script
# This script provides various progress indicator functions for long-running operations

# Color definitions
RED='\e[1;31m'
GREEN='\e[1;32m'
BLUE='\e[1;34m'
YELLOW='\e[1;33m'
NC='\e[0m' # No Color

# Function to display a simple spinner
# Usage: show_spinner function_to_run [args...]
show_spinner() {
    local pid
    local delay=0.1
    local spinstr='|/-\'
    
    # Run the command in the background
    "$@" &
    pid=$!
    
    # Show spinner while command is running
    local i=0
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
        ((i++))
    done
    
    # Wait for command to finish
    wait $pid
    return $?
}

# Function to display a progress bar with percentage
# Usage: show_progress_bar total_items current_item "Message"
show_progress_bar() {
    local total=$1
    local current=$2
    local message=$3
    local bar_length=40
    local progress=$((current * 100 / total))
    local filled_length=$((progress * bar_length / 100))
    
    # Create the progress bar
    local bar=""
    for ((i=0; i<filled_length; i++)); do
        bar="${bar}#"
    done
    
    for ((i=filled_length; i<bar_length; i++)); do
        bar="${bar} "
    done
    
    # Print the progress bar
    printf "\r${message} [${GREEN}${bar}${NC}] ${progress}%% ($current/$total)"
    
    # Print newline if complete
    if [ $current -eq $total ]; then
        echo ""
    fi
}

# Function to display a countdown timer
# Usage: show_countdown seconds "Message"
show_countdown() {
    local seconds=$1
    local message=$2
    
    for ((i=seconds; i>=0; i--)); do
        printf "\r${message} ${i}s remaining..."
        sleep 1
    done
    echo ""
}

# Function to display a pulsing progress indicator
# Usage: show_pulse seconds "Message"
show_pulse() {
    local seconds=$1
    local message=$2
    local delay=0.1
    local elapsed=0
    
    while [ $(echo "$elapsed < $seconds" | bc) -eq 1 ]; do
        for pulse in "▁" "▂" "▃" "▄" "▅" "▆" "▇" "█" "▇" "▆" "▅" "▄" "▃" "▂"; do
            printf "\r${message} ${pulse}"
            sleep $delay
            elapsed=$(echo "$elapsed + $delay" | bc)
            
            if [ $(echo "$elapsed >= $seconds" | bc) -eq 1 ]; then
                break
            fi
        done
    done
    echo ""
}

# Function to display a loading bar with custom character
# Usage: show_loading_bar seconds "Message" "Character"
show_loading_bar() {
    local seconds=$1
    local message=$2
    local char=${3:-"#"}
    local bar_length=40
    local delay=$(echo "scale=3; $seconds / $bar_length" | bc)
    
    printf "${message} ["
    for ((i=0; i<bar_length; i++)); do
        printf "${GREEN}${char}${NC}"
        sleep $delay
    done
    printf "] Done!\n"
}

# Function to display a progress indicator for a command
# Usage: run_with_progress "Command" "Message"
run_with_progress() {
    local command=$1
    local message=$2
    
    # Start command in background
    eval "$command" &
    local pid=$!
    
    # Show spinner while command is running
    local spinstr='|/-\'
    local delay=0.1
    local i=0
    
    printf "${message} "
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf "[%c]" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b"
        ((i++))
    done
    
    # Wait for command to finish
    wait $pid
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        printf " ${GREEN}✓${NC}\n"
    else
        printf " ${RED}✗${NC}\n"
    fi
    
    return $exit_code
}

# Function to display a progress indicator for a file download
# Usage: show_download_progress url output_file
show_download_progress() {
    local url=$1
    local output_file=$2
    
    if command -v wget &>/dev/null; then
        wget -q --show-progress -O "$output_file" "$url"
    elif command -v curl &>/dev/null; then
        curl -L --progress-bar -o "$output_file" "$url"
    else
        echo "Neither wget nor curl is available. Cannot download file."
        return 1
    fi
}

# Function to display a progress indicator for a Docker pull operation
# Usage: docker_pull_with_progress image_name
docker_pull_with_progress() {
    local image=$1
    
    if ! command -v docker &>/dev/null; then
        echo "Docker is not installed. Cannot pull image."
        return 1
    fi
    
    docker pull "$image"
}

# Function to display a progress indicator for a Docker build operation
# Usage: docker_build_with_progress directory tag
docker_build_with_progress() {
    local directory=$1
    local tag=$2
    
    if ! command -v docker &>/dev/null; then
        echo "Docker is not installed. Cannot build image."
        return 1
    fi
    
    docker build -t "$tag" "$directory"
}

# Function to display a progress indicator for a Docker compose operation
# Usage: docker_compose_with_progress command
docker_compose_with_progress() {
    local command=$1
    
    if ! command -v docker-compose &>/dev/null; then
        echo "Docker Compose is not installed. Cannot run command."
        return 1
    fi
    
    docker-compose $command
}

# Function to display a progress indicator for apt operations
# Usage: apt_with_progress command packages
apt_with_progress() {
    local command=$1
    shift
    local packages=$@
    
    if ! command -v apt-get &>/dev/null; then
        echo "apt-get is not available. Cannot install packages."
        return 1
    fi
    
    case $command in
        update)
            apt-get update -y
            ;;
        install)
            apt-get install -y $packages
            ;;
        upgrade)
            apt-get upgrade -y $packages
            ;;
        remove)
            apt-get remove -y $packages
            ;;
        *)
            echo "Unknown apt command: $command"
            return 1
            ;;
    esac
}

# Example usage (if script is run directly)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Progress Indicators Demo"
    echo "----------------------"
    echo ""
    
    echo "1. Simple Spinner:"
    show_spinner sleep 3
    echo "Done!"
    echo ""
    
    echo "2. Progress Bar:"
    total=10
    for ((i=1; i<=total; i++)); do
        show_progress_bar $total $i "Processing items"
        sleep 0.5
    done
    echo ""
    
    echo "3. Countdown Timer:"
    show_countdown 5 "Starting in"
    echo "Started!"
    echo ""
    
    echo "4. Pulsing Indicator:"
    show_pulse 3 "Loading"
    echo "Loaded!"
    echo ""
    
    echo "5. Loading Bar:"
    show_loading_bar 3 "Installing" "▓"
    echo ""
    
    echo "6. Command Progress:"
    run_with_progress "sleep 2" "Processing"
    echo ""
    
    echo "7. Download Progress (if URL is valid):"
    show_download_progress "https://example.com/index.html" "/tmp/example.html"
    echo ""
    
    echo "Demo completed!"
fi
