apt-get -y install apt-transport-https lsb-release ca-certificates gnupg
wget -O - https://deb.froxlor.org/froxlor.gpg | apt-key add -
echo "deb https://deb.froxlor.org/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/froxlor.list
bash update
apt-get install froxlor
