#!/bin/bash
# Firewall Configuration Script (UFW)

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)"
  exit 1
fi

# Menu options
PS3='Please select a firewall option: '
options=(
  "Install UFW" 
  "Basic Server Setup" 
  "Web Server Setup" 
  "Mail Server Setup" 
  "Database Server Setup" 
  "Custom Rule" 
  "Enable Firewall" 
  "Disable Firewall" 
  "Show Status" 
  "Reset Firewall" 
  "Quit"
)

select opt in "${options[@]}"
do
  case $opt in
    "Install UFW")
      echo "Installing UFW..."
      apt-get update -y
      apt-get install -y ufw
      echo "UFW installed successfully!"
      ;;
      
    "Basic Server Setup")
      echo "Setting up basic server firewall rules..."
      
      # Deny all incoming traffic by default
      ufw default deny incoming
      
      # Allow all outgoing traffic by default
      ufw default allow outgoing
      
      # Allow SSH
      ufw allow ssh
      
      echo "Basic server firewall rules configured!"
      echo "Remember to enable the firewall with 'Enable Firewall' option."
      ;;
      
    "Web Server Setup")
      echo "Setting up web server firewall rules..."
      
      # Allow SSH
      ufw allow ssh
      
      # Allow HTTP and HTTPS
      ufw allow 80/tcp
      ufw allow 443/tcp
      
      echo "Web server firewall rules configured!"
      echo "Remember to enable the firewall with 'Enable Firewall' option."
      ;;
      
    "Mail Server Setup")
      echo "Setting up mail server firewall rules..."
      
      # Allow SSH
      ufw allow ssh
      
      # Allow common mail ports
      ufw allow 25/tcp   # SMTP
      ufw allow 465/tcp  # SMTPS
      ufw allow 587/tcp  # Submission
      ufw allow 110/tcp  # POP3
      ufw allow 995/tcp  # POP3S
      ufw allow 143/tcp  # IMAP
      ufw allow 993/tcp  # IMAPS
      
      echo "Mail server firewall rules configured!"
      echo "Remember to enable the firewall with 'Enable Firewall' option."
      ;;
      
    "Database Server Setup")
      echo "Setting up database server firewall rules..."
      
      # Allow SSH
      ufw allow ssh
      
      # Prompt for which database ports to open
      echo "Which database ports would you like to open?"
      echo "1) MySQL/MariaDB (3306)"
      echo "2) PostgreSQL (5432)"
      echo "3) MongoDB (27017)"
      echo "4) All of the above"
      echo "5) None"
      read -p "Enter your choice (1-5): " db_choice
      
      case $db_choice in
        1)
          ufw allow 3306/tcp
          echo "MySQL/MariaDB port opened."
          ;;
        2)
          ufw allow 5432/tcp
          echo "PostgreSQL port opened."
          ;;
        3)
          ufw allow 27017/tcp
          echo "MongoDB port opened."
          ;;
        4)
          ufw allow 3306/tcp
          ufw allow 5432/tcp
          ufw allow 27017/tcp
          echo "All database ports opened."
          ;;
        5)
          echo "No database ports opened."
          ;;
        *)
          echo "Invalid choice. No database ports opened."
          ;;
      esac
      
      echo "Database server firewall rules configured!"
      echo "Remember to enable the firewall with 'Enable Firewall' option."
      ;;
      
    "Custom Rule")
      echo "Add a custom firewall rule..."
      
      # Prompt for protocol
      echo "Select protocol:"
      echo "1) TCP"
      echo "2) UDP"
      echo "3) Both"
      read -p "Enter your choice (1-3): " protocol_choice
      
      # Prompt for port
      read -p "Enter port number: " port_number
      
      # Prompt for action
      echo "Select action:"
      echo "1) Allow"
      echo "2) Deny"
      read -p "Enter your choice (1-2): " action_choice
      
      # Build and execute the command
      case $protocol_choice in
        1) protocol="tcp" ;;
        2) protocol="udp" ;;
        3) protocol="tcp,udp" ;;
        *) 
          echo "Invalid protocol choice."
          continue
          ;;
      esac
      
      case $action_choice in
        1) action="allow" ;;
        2) action="deny" ;;
        *) 
          echo "Invalid action choice."
          continue
          ;;
      esac
      
      ufw $action $port_number/$protocol
      echo "Custom rule added: $action port $port_number/$protocol"
      ;;
      
    "Enable Firewall")
      echo "Enabling UFW firewall..."
      echo "y" | ufw enable
      echo "Firewall enabled!"
      ;;
      
    "Disable Firewall")
      echo "Disabling UFW firewall..."
      ufw disable
      echo "Firewall disabled!"
      ;;
      
    "Show Status")
      echo "Current firewall status:"
      ufw status verbose
      ;;
      
    "Reset Firewall")
      echo "Resetting UFW firewall to default settings..."
      ufw reset
      echo "Firewall reset to defaults!"
      ;;
      
    "Quit")
      break
      ;;
      
    *) 
      echo "Invalid option $REPLY"
      ;;
  esac
done
