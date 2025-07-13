#!/bin/bash

# Utility script to detect server IP address
# This can be sourced by other scripts to replace localhost with actual IP

# Function to get the primary IP address of the server
get_server_ip() {
    # Try multiple methods to get the IP address
    
    # Method 1: Using hostname command
    local ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    
    # Method 2: Using ip command if Method 1 failed
    if [ -z "$ip" ] || [ "$ip" = "127.0.0.1" ] || [ "$ip" = "::1" ]; then
        ip=$(ip -4 addr show scope global | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
    fi
    
    # Method 3: Using ifconfig command if Method 2 failed
    if [ -z "$ip" ] || [ "$ip" = "127.0.0.1" ] || [ "$ip" = "::1" ]; then
        ip=$(ifconfig 2>/dev/null | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n 1)
    fi
    
    # Method 4: Using external service if all local methods failed
    if [ -z "$ip" ] || [ "$ip" = "127.0.0.1" ] || [ "$ip" = "::1" ]; then
        # Try to get external IP using a public service
        # Only use this as a last resort as it requires internet connection
        ip=$(curl -s https://api.ipify.org 2>/dev/null || wget -qO- https://api.ipify.org 2>/dev/null)
    fi
    
    # Return the IP address
    if [ -n "$ip" ] && [ "$ip" != "127.0.0.1" ] && [ "$ip" != "::1" ]; then
        echo "$ip"
        return 0
    else
        echo "localhost"
        return 1
    fi
}

# Function to replace localhost in a string with server IP
replace_localhost() {
    local input_string="$1"
    local server_ip=$(get_server_ip)
    
    if [ "$server_ip" != "localhost" ]; then
        echo "${input_string//localhost/$server_ip}"
    else
        echo "$input_string"
    fi
}

# If this script is run directly (not sourced), display the server IP
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    server_ip=$(get_server_ip)
    echo "Detected server IP: $server_ip"
fi
