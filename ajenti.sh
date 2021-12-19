echo "deb http://security.ubuntu.com/ubuntu xenial-security main universe" | sudo tee -a /etc/apt/sources.listapt upgrade

bash update

wget -O- https://raw.github.com/ajenti/ajenti/1.x/scripts/install-ubuntu.sh | sudo sh

