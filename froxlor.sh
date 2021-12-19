apt-get -y install apt-transport-https lsb-release ca-certificates gnupg
wget -O - https://deb.froxlor.org/froxlor.gpg | apt-key add -
echo "deb https://deb.froxlor.org/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/froxlor.list
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y

sudo curl -sSL https://repos.insights.digitalocean.com/install.sh | sudo bash

sudo apt autoremove -y
sudo apt-get clean -y
sudo apt-get autoremove --purge -yapt-get install froxlor
