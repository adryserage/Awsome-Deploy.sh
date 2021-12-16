#!/bin/bash

# bash script to update Ubuntu Linux. Written on 16.04 LTS Server
# Written by Ted LeRoy with help from Google and the Linux community
# Follow or contribute on GitHub here:
# https://github.com/TedLeRoy/ubuntu-update.sh

# Defining Colors for text output
red=$( tput setaf 1 );
yellow=$( tput setaf 3 );
green=$( tput setaf 2 );
normal=$( tput sgr 0 );

# Defining Header
HEADER="
ubuntu-update.sh Copyright (C) 2018 Ted LeRoy

Easily update, upgrade, and clean up your Ubuntu system with this bash script.

This program comes with ABSOLUTELY NO WARRANTY see
https://github.com/TedLeRoy/ubuntu-update.sh/blob/master/LICENSE.md

This is free software, and you are welcome to redistribute it
under certain conditions.

See https://github.com/TedLeRoy/ubuntu-update.sh/blob/master/LICENSE.md
for details."

# Defining USAGE Variable to print usage for -h or undefined args

USAGE="
Usage: sudo bash ubuntu-update.sh [-ugdrh]
       No option - Run all options (recommended)
       -u Don't run apt-get update
       -g Don't run apt-get upgrade -y
       -d Don't run apt-get dist-upgrade -y
       -r Don't run apt-get auto-remove
       -h Display Usage and exit
"

# Evaluating Command Line args and setting case variables for later use

while getopts ":ugdrh" OPT; do
  case ${OPT} in
    u ) uOff=1
      ;;
    g ) gOff=1
      ;;
    d ) dOff=1
      ;;
    r ) rOff=1
      ;;
    h ) hOn=1
      ;;
    \?) noOpt=1
  esac
done

# Checking whether script is being run as root

if [[ ${UID} != 0 ]]; then
    echo "${red}
    This script must be run as root or with sudo permissions.
    Please run using sudo.${normal}
    "
    exit 1
fi

# Executing based on option selection

if [[ -n $hOn || $noOpt ]]; then
    echo "${red}$USAGE${normal}"
    exit 2
fi

# Display HEADER

echo "${red}$HEADER${normal}"

if [[ ! -n $uOff ]]; then
    echo -e "
\e[32m#############################
#     Updating Data Base    #
#############################\e[0m
"
apt-get update | tee /tmp/update-output.txt
curl -sSL https://repos.insights.digitalocean.com/install.sh | sudo bash | tee /tmp/update-output.txt
fi

if [[ ! -n $gOff ]]; then
    echo -e "
\e[32m##############################
# Upgrading Operating System #
##############################\e[0m
"
apt-get upgrade -y | tee -a /tmp/update-output.txt
fi

if [[ ! -n $dOff ]]; then
    echo -e "
\e[32m#############################
#   Starting Full Upgrade   #
#############################\e[0m
"
apt-get dist-upgrade -y | tee -a /tmp/update-output.txt
echo -e "
\e[32m#############################
#   Full Upgrade Complete   #
#############################\e[0m
"
fi

if [[ ! -n $rOff ]]; then
    echo -e "
\e[32m#############################
#    Starting Apt Clean     #
#############################\e[0m
"
apt autoremove | tee -a /tmp/update-output.txt
apt-get clean | tee -a /tmp/update-output.txt
echo -e "
\e[32m#############################
#     Apt Clean Complete    #
#############################\e[0m
"
fi

# Check for existence of update-output.txt and exit if not there.

if [ -f "/tmp/update-output.txt"  ]

then

# Search for issues user may want to see and display them at end of run.

  echo -e "
\e[32m#####################################################
#   Checking for actionable messages from install   #
#####################################################\e[0m
"
  egrep -wi --color 'warning|error|critical|reboot|restart|autoclean|autoremove' /tmp/update-output.txt | uniq
  echo -e "
\e[32m#############################
#    Cleaning temp files    #
#############################\e[0m
"

  rm /tmp/update-output.txt
  echo -e "
\e[32m#############################
#     Done with upgrade     #
#############################\e[0m
"

echo -e "
\e[32m#############################
#     Set up the repository    #
#############################\e[0m
"
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
echo -e "
\e[32m#############################
#     Add Docker’s official GPG key    #
#############################\e[0m
"
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo -e "
\e[32m#############################
#    set up the stable repository    #
#############################\e[0m
"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  
echo -e "
\e[32m#############################
#     Launch Full update    #
#############################\e[0m
"
bash update.sh

echo -e "
\e[32m#############################
#     Install Docker Engine   #
#############################\e[0m
"
sudo apt-get install docker-ce docker-ce-cli containerd.io

while getopts ":ugdrh" OPT; do
  case ${OPT} in
    u ) uOff=1
      ;;
    g ) gOff=1
      ;;
    d ) dOff=1
      ;;
    r ) rOff=1
      ;;
    h ) hOn=1
      ;;
    \?) noOpt=1
  esac
done

# Checking whether script is being run as root

if [[ ${UID} != 0 ]]; then
    echo "${red}
    This script must be run as root or with sudo permissions.
    Please run using sudo.${normal}
    "
    exit 1
fi

# Executing based on option selection

if [[ -n $hOn || $noOpt ]]; then
    echo "${red}$USAGE${normal}"
    exit 2
fi

# Display HEADER

echo "${red}$HEADER${normal}"

if [[ ! -n $gOff ]]; then
    echo -e "
\e[32m##############################
# Upgrading Operating System #
##############################\e[0m
"
apt-get update -y | tee -a /tmp/update-output.txt
apt-get upgrade -y | tee -a /tmp/update-output.txt
fi

if [[ ! -n $dOff ]]; then
    echo -e "
\e[32m#############################
#   Starting Full Upgrade   #
#############################\e[0m
"
apt-get dist-upgrade -y | tee -a /tmp/update-output.txt
echo -e "
\e[32m#############################
#   Full Upgrade Complete   #
#############################\e[0m
"
fi


if [[ ! -n $dOff ]]; then
    echo -e "
\e[32m#############################
#   Starting Portainer install   #
#############################\e[0m
"
docker volume create portainer_data | tee -a /tmp/update-output.txt

docker run -d -p 8000:8000 -p 9443:9443 --name portainer \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    cr.portainer.io/portainer/portainer-ce:latest | tee -a /tmp/update-output.txt
    
echo -e "
\e[32m#############################
#   Portainer install Complete   #
#############################\e[0m
"
fi


if [[ ! -n $rOff ]]; then
    echo -e "
\e[32m#############################
#    Starting Apt Clean     #
#############################\e[0m
"
apt autoremove | tee -a /tmp/update-output.txt
apt-get clean | tee -a /tmp/update-output.txt
echo -e "
\e[32m#############################
#     Apt Clean Complete    #
#############################\e[0m
"
fi

# Check for existence of update-output.txt and exit if not there.

if [ -f "/tmp/update-output.txt"  ]

then

# Search for issues user may want to see and display them at end of run.

  echo -e "
\e[32m#####################################################
#   Checking for actionable messages from install   #
#####################################################\e[0m
"
  egrep -wi --color 'warning|error|critical|reboot|restart|autoclean|autoremove' /tmp/update-output.txt | uniq
  echo -e "
\e[32m#############################
#    Cleaning temp files    #
#############################\e[0m
"

  rm /tmp/update-output.txt
  echo -e "
\e[32m#############################
#     Done with upgrade     #
#############################\e[0m
"

exit 0

else

# Exit with message if update-output.txt file is not there.

  echo -e "
\e[32m#########################################################
# No items to check given your chosen options. Exiting. #
#########################################################\e[0m
"

fi

exit 0
