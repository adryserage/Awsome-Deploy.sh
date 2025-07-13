#!/bin/bash
# User Management and Permission Hardening Script

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)"
  exit 1
fi

echo "User Management and Permission Hardening"
echo "========================================"
echo ""

# Menu options
PS3='Please select an option: '
options=(
  "Create User" 
  "Delete User" 
  "Add User to Group" 
  "Create Secure User" 
  "Password Policy" 
  "Secure SSH" 
  "Disable Root Login" 
  "File Permission Audit" 
  "SUID/SGID Audit" 
  "System Hardening" 
  "Show User Info" 
  "List All Users" 
  "Quit"
)

select opt in "${options[@]}"
do
  case $opt in
    "Create User")
      echo "Creating a new user..."
      
      read -p "Enter username: " username
      
      # Check if user already exists
      if id "$username" &>/dev/null; then
        echo "User $username already exists!"
        continue
      fi
      
      # Create user
      useradd -m "$username"
      
      # Set password
      passwd "$username"
      
      echo "User $username created successfully!"
      ;;
      
    "Delete User")
      echo "Deleting a user..."
      
      read -p "Enter username to delete: " username
      
      # Check if user exists
      if ! id "$username" &>/dev/null; then
        echo "User $username does not exist!"
        continue
      fi
      
      read -p "Delete home directory? (y/n): " delete_home
      
      if [ "$delete_home" = "y" ] || [ "$delete_home" = "Y" ]; then
        userdel -r "$username"
        echo "User $username and home directory deleted."
      else
        userdel "$username"
        echo "User $username deleted. Home directory preserved."
      fi
      ;;
      
    "Add User to Group")
      echo "Adding user to group..."
      
      read -p "Enter username: " username
      
      # Check if user exists
      if ! id "$username" &>/dev/null; then
        echo "User $username does not exist!"
        continue
      fi
      
      # Show available groups
      echo "Available groups:"
      getent group | cut -d: -f1
      
      read -p "Enter group name: " groupname
      
      # Check if group exists
      if ! getent group "$groupname" &>/dev/null; then
        read -p "Group $groupname does not exist. Create it? (y/n): " create_group
        
        if [ "$create_group" = "y" ] || [ "$create_group" = "Y" ]; then
          groupadd "$groupname"
          echo "Group $groupname created."
        else
          echo "Operation cancelled."
          continue
        fi
      fi
      
      # Add user to group
      usermod -aG "$groupname" "$username"
      echo "User $username added to group $groupname."
      ;;
      
    "Create Secure User")
      echo "Creating a secure user with limited permissions..."
      
      read -p "Enter username: " username
      
      # Check if user already exists
      if id "$username" &>/dev/null; then
        echo "User $username already exists!"
        continue
      fi
      
      # Create user with no login shell
      useradd -m -s /usr/sbin/nologin "$username"
      
      # Generate strong password
      password=$(openssl rand -base64 12)
      echo "$username:$password" | chpasswd
      
      # Set password expiry
      passwd -e "$username"
      
      echo "Secure user $username created with password: $password"
      echo "The user cannot log in via SSH but can switch to with 'su $username'"
      echo "Password will expire on first use."
      ;;
      
    "Password Policy")
      echo "Configuring system password policy..."
      
      # Check if libpam-pwquality is installed
      if ! dpkg -l | grep -q libpam-pwquality; then
        echo "Installing libpam-pwquality..."
        apt-get update -y
        apt-get install -y libpam-pwquality
      fi
      
      # Configure password policy
      echo "Setting password policy..."
      
      # Backup original file
      cp /etc/security/pwquality.conf /etc/security/pwquality.conf.bak
      
      # Update password policy
      cat > /etc/security/pwquality.conf << EOF
# Password quality configuration
# min_length: minimum password length
# dcredit: credit for digits
# ucredit: credit for uppercase
# lcredit: credit for lowercase
# ocredit: credit for other characters
# difok: number of characters that must be different from old password
# enforce_for_root: apply policy to root user as well

minlen = 12
dcredit = -1
ucredit = -1
lcredit = -1
ocredit = -1
difok = 3
enforce_for_root
EOF
      
      # Configure login.defs for password aging
      sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs
      sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   1/' /etc/login.defs
      sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   7/' /etc/login.defs
      
      echo "Password policy configured successfully!"
      echo "- Minimum length: 12 characters"
      echo "- Requires: uppercase, lowercase, digit, and special character"
      echo "- Password expiry: 90 days"
      echo "- Warning before expiry: 7 days"
      ;;
      
    "Secure SSH")
      echo "Securing SSH configuration..."
      
      # Backup original SSH config
      cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
      
      # Update SSH configuration
      cat > /etc/ssh/sshd_config.d/hardening.conf << EOF
# SSH Security Hardening

# Disable root login
PermitRootLogin no

# Use SSH Protocol 2
Protocol 2

# Disable password authentication (use key-based auth)
PasswordAuthentication no

# Limit authentication attempts
MaxAuthTries 3

# Disable empty passwords
PermitEmptyPasswords no

# Disable X11 forwarding
X11Forwarding no

# Set idle timeout (5 minutes)
ClientAliveInterval 300
ClientAliveCountMax 0

# Restrict SSH to specific users (uncomment and add users)
# AllowUsers user1 user2

# Use strong ciphers and MACs
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com

# Disable less secure key exchange algorithms
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
EOF
      
      echo "SSH hardening configuration created at /etc/ssh/sshd_config.d/hardening.conf"
      echo "NOTE: Password authentication is now DISABLED. Make sure you have SSH keys set up!"
      echo "To enable password authentication, edit the file and set PasswordAuthentication yes"
      
      read -p "Do you want to restart SSH service now? (y/n): " restart_ssh
      if [ "$restart_ssh" = "y" ] || [ "$restart_ssh" = "Y" ]; then
        systemctl restart sshd
        echo "SSH service restarted."
      else
        echo "Remember to restart SSH service to apply changes: systemctl restart sshd"
      fi
      ;;
      
    "Disable Root Login")
      echo "Disabling root login..."
      
      # Lock root account
      passwd -l root
      
      # Disable root login in SSH
      if [ -f /etc/ssh/sshd_config ]; then
        sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
        
        read -p "Restart SSH service to apply changes? (y/n): " restart_ssh
        if [ "$restart_ssh" = "y" ] || [ "$restart_ssh" = "Y" ]; then
          systemctl restart sshd
          echo "SSH service restarted."
        else
          echo "Remember to restart SSH service to apply changes: systemctl restart sshd"
        fi
      fi
      
      echo "Root login disabled."
      echo "Use sudo for administrative tasks."
      ;;
      
    "File Permission Audit")
      echo "Auditing file permissions..."
      
      echo "Checking for world-writable files in system directories..."
      find /etc /bin /sbin /usr -type f -perm -0002 -exec ls -l {} \;
      
      echo ""
      echo "Checking for files with no owner..."
      find / -nouser -o -nogroup -exec ls -l {} \; 2>/dev/null
      
      echo ""
      echo "Checking for world-writable directories..."
      find / -type d -perm -0002 -exec ls -ld {} \; 2>/dev/null
      
      echo ""
      echo "File permission audit completed."
      ;;
      
    "SUID/SGID Audit")
      echo "Auditing SUID/SGID binaries..."
      
      echo "Finding SUID binaries..."
      find / -type f -perm -4000 -exec ls -l {} \; 2>/dev/null
      
      echo ""
      echo "Finding SGID binaries..."
      find / -type f -perm -2000 -exec ls -l {} \; 2>/dev/null
      
      echo ""
      echo "SUID/SGID audit completed."
      echo "Review these binaries carefully as they can be security risks."
      ;;
      
    "System Hardening")
      echo "Applying system hardening measures..."
      
      # Secure shared memory
      echo "Securing shared memory..."
      if ! grep -q "/run/shm" /etc/fstab; then
        echo "tmpfs /run/shm tmpfs defaults,noexec,nosuid,nodev 0 0" >> /etc/fstab
      fi
      
      # Secure /tmp
      echo "Securing /tmp..."
      if ! grep -q " /tmp " /etc/fstab; then
        echo "tmpfs /tmp tmpfs defaults,noexec,nosuid,nodev 0 0" >> /etc/fstab
      fi
      
      # Disable core dumps
      echo "Disabling core dumps..."
      echo "* hard core 0" >> /etc/security/limits.conf
      echo "fs.suid_dumpable = 0" >> /etc/sysctl.conf
      
      # Restrict access to compilers
      echo "Restricting access to compilers..."
      if command -v gcc &> /dev/null; then
        chmod o-x "$(which gcc)"
      fi
      
      # Enable address space layout randomization
      echo "Enabling ASLR..."
      echo "kernel.randomize_va_space = 2" >> /etc/sysctl.conf
      
      # Disable uncommon network protocols
      echo "Disabling uncommon network protocols..."
      cat > /etc/modprobe.d/disable-protocols.conf << EOF
install dccp /bin/true
install sctp /bin/true
install rds /bin/true
install tipc /bin/true
EOF
      
      # Apply sysctl changes
      sysctl -p
      
      echo "System hardening measures applied."
      echo "Some changes require a reboot to take full effect."
      ;;
      
    "Show User Info")
      echo "Showing user information..."
      
      read -p "Enter username: " username
      
      # Check if user exists
      if ! id "$username" &>/dev/null; then
        echo "User $username does not exist!"
        continue
      fi
      
      echo "User information for $username:"
      echo "------------------------------"
      id "$username"
      
      echo ""
      echo "Groups:"
      groups "$username"
      
      echo ""
      echo "Login information:"
      lastlog -u "$username"
      
      echo ""
      echo "Password status:"
      passwd -S "$username"
      
      echo ""
      echo "Home directory:"
      ls -la "/home/$username"
      ;;
      
    "List All Users")
      echo "Listing all users on the system..."
      
      echo "System users (UID < 1000):"
      awk -F: '$3 < 1000 {print $1, $3, $6, $7}' /etc/passwd | column -t
      
      echo ""
      echo "Regular users (UID >= 1000):"
      awk -F: '$3 >= 1000 {print $1, $3, $6, $7}' /etc/passwd | column -t
      
      echo ""
      echo "Users who can login with a shell:"
      grep -v '/nologin\|/false' /etc/passwd | awk -F: '{print $1, $7}' | column -t
      ;;
      
    "Quit")
      break
      ;;
      
    *) 
      echo "Invalid option $REPLY"
      ;;
  esac
done
