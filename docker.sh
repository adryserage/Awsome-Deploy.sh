#!/bin/bash

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
