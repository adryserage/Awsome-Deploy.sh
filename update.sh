#!/bin/bash

sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
sudo curl -sSL https://repos.insights.digitalocean.com/install.sh | sudo bash
sudo apt autoremove -y
sudo apt-get clean -y
sudo apt-get autoremove --purge -y



