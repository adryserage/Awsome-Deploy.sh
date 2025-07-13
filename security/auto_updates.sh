#!/bin/bash
# Automatic Security Updates Configuration Script

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)"
  exit 1
fi

echo "Automatic Security Updates Configuration"
echo "========================================"
echo ""

# Menu options
PS3='Please select an option: '
options=(
  "Install Unattended Upgrades" 
  "Configure Security Updates Only" 
  "Configure All Updates" 
  "Configure Email Notifications" 
  "Enable Automatic Updates" 
  "Disable Automatic Updates" 
  "Show Status" 
  "Quit"
)

select opt in "${options[@]}"
do
  case $opt in
    "Install Unattended Upgrades")
      echo "Installing unattended-upgrades package..."
      apt-get update -y
      apt-get install -y unattended-upgrades apt-listchanges
      echo "Unattended-upgrades installed successfully!"
      ;;
      
    "Configure Security Updates Only")
      echo "Configuring automatic security updates only..."
      
      # Create configuration file
      cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
// Automatically upgrade packages from these (origin:archive) pairs
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}-security";
};

// List of packages to not update
Unattended-Upgrade::Package-Blacklist {
//    "vim";
//    "libc6";
//    "libc6-dev";
//    "libc6-i686";
};

// Split the upgrade into the smallest possible chunks so that
// they can be interrupted with SIGTERM.
Unattended-Upgrade::MinimalSteps "true";

// Automatically reboot *WITHOUT CONFIRMATION* if
// the file /var/run/reboot-required is found after the upgrade
Unattended-Upgrade::Automatic-Reboot "false";

// If automatic reboot is enabled and needed, reboot at the specific
// time instead of immediately
//Unattended-Upgrade::Automatic-Reboot-Time "02:00";
EOF
      
      # Enable automatic updates
      cat > /etc/apt/apt.conf.d/20auto-upgrades << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
      
      echo "Security updates configuration completed!"
      ;;
      
    "Configure All Updates")
      echo "Configuring automatic updates for all packages..."
      
      # Create configuration file
      cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
// Automatically upgrade packages from these (origin:archive) pairs
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}";
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}:\${distro_codename}-updates";
    "\${distro_id}:\${distro_codename}-proposed";
    "\${distro_id}:\${distro_codename}-backports";
};

// List of packages to not update
Unattended-Upgrade::Package-Blacklist {
//    "vim";
//    "libc6";
//    "libc6-dev";
//    "libc6-i686";
};

// Split the upgrade into the smallest possible chunks so that
// they can be interrupted with SIGTERM.
Unattended-Upgrade::MinimalSteps "true";

// Automatically reboot *WITHOUT CONFIRMATION* if
// the file /var/run/reboot-required is found after the upgrade
Unattended-Upgrade::Automatic-Reboot "false";

// If automatic reboot is enabled and needed, reboot at the specific
// time instead of immediately
//Unattended-Upgrade::Automatic-Reboot-Time "02:00";
EOF
      
      # Enable automatic updates
      cat > /etc/apt/apt.conf.d/20auto-upgrades << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
      
      echo "All updates configuration completed!"
      ;;
      
    "Configure Email Notifications")
      echo "Configuring email notifications for automatic updates..."
      
      # Prompt for email address
      read -p "Enter email address for notifications: " email_address
      
      # Update configuration file
      if [ -f /etc/apt/apt.conf.d/50unattended-upgrades ]; then
        # Check if email configuration already exists
        if grep -q "Unattended-Upgrade::Mail" /etc/apt/apt.conf.d/50unattended-upgrades; then
          # Replace existing email configuration
          sed -i "s/Unattended-Upgrade::Mail .*/Unattended-Upgrade::Mail \"$email_address\";/" /etc/apt/apt.conf.d/50unattended-upgrades
        else
          # Add email configuration
          sed -i "/Unattended-Upgrade::Automatic-Reboot /a Unattended-Upgrade::Mail \"$email_address\";" /etc/apt/apt.conf.d/50unattended-upgrades
        fi
        
        # Configure to send mail only on errors
        if grep -q "Unattended-Upgrade::MailOnlyOnError" /etc/apt/apt.conf.d/50unattended-upgrades; then
          # Replace existing setting
          sed -i "s/Unattended-Upgrade::MailOnlyOnError .*/Unattended-Upgrade::MailOnlyOnError \"true\";/" /etc/apt/apt.conf.d/50unattended-upgrades
        else
          # Add setting
          sed -i "/Unattended-Upgrade::Mail /a Unattended-Upgrade::MailOnlyOnError \"true\";" /etc/apt/apt.conf.d/50unattended-upgrades
        fi
        
        echo "Email notifications configured to: $email_address"
      else
        echo "Error: Configuration file not found. Please configure updates first."
      fi
      ;;
      
    "Enable Automatic Updates")
      echo "Enabling automatic updates..."
      
      # Create basic configuration if it doesn't exist
      if [ ! -f /etc/apt/apt.conf.d/20auto-upgrades ]; then
        cat > /etc/apt/apt.conf.d/20auto-upgrades << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
      fi
      
      # Ensure the service is enabled
      systemctl enable unattended-upgrades
      systemctl start unattended-upgrades
      
      echo "Automatic updates enabled!"
      ;;
      
    "Disable Automatic Updates")
      echo "Disabling automatic updates..."
      
      # Disable in configuration
      if [ -f /etc/apt/apt.conf.d/20auto-upgrades ]; then
        sed -i 's/APT::Periodic::Unattended-Upgrade "1";/APT::Periodic::Unattended-Upgrade "0";/' /etc/apt/apt.conf.d/20auto-upgrades
      fi
      
      # Stop and disable service
      systemctl stop unattended-upgrades
      systemctl disable unattended-upgrades
      
      echo "Automatic updates disabled!"
      ;;
      
    "Show Status")
      echo "Current automatic updates status:"
      
      echo "Configuration files:"
      echo "--------------------"
      if [ -f /etc/apt/apt.conf.d/20auto-upgrades ]; then
        echo "/etc/apt/apt.conf.d/20auto-upgrades:"
        cat /etc/apt/apt.conf.d/20auto-upgrades
      else
        echo "/etc/apt/apt.conf.d/20auto-upgrades: Not found"
      fi
      
      echo ""
      if [ -f /etc/apt/apt.conf.d/50unattended-upgrades ]; then
        echo "/etc/apt/apt.conf.d/50unattended-upgrades exists."
      else
        echo "/etc/apt/apt.conf.d/50unattended-upgrades: Not found"
      fi
      
      echo ""
      echo "Service status:"
      echo "--------------"
      systemctl status unattended-upgrades | grep -E "Active:|Loaded:"
      ;;
      
    "Quit")
      break
      ;;
      
    *) 
      echo "Invalid option $REPLY"
      ;;
  esac
done
