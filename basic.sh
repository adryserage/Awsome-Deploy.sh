#!/bin/bash
# Bash Menu Script Example

PS3='Please enter your choice: '
options=("Update" "Homebrew" "Froxlor" "YunoHost" "DigitalOcean Monitor" "Change Time zone" "Clean" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Update")
            echo "Update System"
            sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
            ;;
        "Homebrew")
            echo "Install Homebrew"
            sudo useradd -m -p all0webs.cOm non-root
su non-root
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
su root
            ;;
        "Froxlor")
            echo "Install Froxlor"
            apt-get -y install apt-transport-https lsb-release ca-certificates gnupg
wget -O - https://deb.froxlor.org/froxlor.gpg | apt-key add -
echo "deb https://deb.froxlor.org/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/froxlor.list
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
sudo apt autoremove -y
sudo apt-get clean -y
sudo apt-get autoremove --purge -y
apt-get install froxlor
            ;;
        "YunoHost")
            echo "Install YunoHost"
            curl https://install.yunohost.org | bash
yunohost tools postinstall
            ;;
         "DigitalOcean Monitor")
            echo "Install DigitalOcean Monitor"
             sudo curl -sSL https://repos.insights.digitalocean.com/install.sh | sudo bash
            ;;
        "Change Time zone")
            echo "Change Time zone"
              dpkg-reconfigure tzdata 
            ;;
         "Clean")
            echo "Clean"
            sudo apt autoremove -y
sudo apt-get clean -y
sudo apt-get autoremove --purge -y
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
