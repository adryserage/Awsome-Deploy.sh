#!/bin/bash
# Bash Menu Script Example

PS3='Please enter your installation choice : '
options=("Docker" "FTP" "Portainer" "Autoheal" "SSL for Apache" "Poste.io" "Nginx" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Docker")
            echo "Install Docker"
            sudo apt-get update -y
apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
apt-get update -y
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose
            ;;
        "FTP")
            echo "Install FTP"
            docker run -d -p 20-21:20-21 -p 65500-65515:65500-65515 -v /tmp:/var/ftp:ro metabrainz/docker-anon-ftp
            ;;
        "Portainer")
            echo "Install Portainer"
            docker volume create portainer_data
docker run -d -p 9443:9443 --name portainer \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    cr.portainer.io/portainer/portainer-ce:latest
            ;;
            "Autoheal")
            echo "Install Autoheal"
            docker run -d \
    --name autoheal \
    --restart=always \
    -e AUTOHEAL_CONTAINER_LABEL=all \
    -v /var/run/docker.sock:/var/run/docker.sock \
    willfarrell/autoheal:latest
            ;;
            "SSL for Apache")
            echo "Install SSL for Apache"
               certbot --apache -d allowebs.com -d www.allowebs.com
            ;;
            "Poste.io")
            echo "Install Poste.io"
            docker run -d \
    -p 25:25 \
    -p 80:80 \
    -p 443:443 \
    -p 110:110 \
    -p 143:143 \
    -p 465:465 \
    -p 587:587 \
    -p 993:993 \
    -p 995:995 \
    -v /mail/data:/data \
    -t analogic/poste.io
            ;;
            "Nginx")
            echo "Install Nginx"
            docker run --detach \
    --name www \
    --env "VIRTUAL_HOST=allowebs.com" \
    --env "LETSENCRYPT_HOST=allowebs.com" \
    nginx
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
