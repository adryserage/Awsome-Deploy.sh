#!/bin/bash

docker volume create portainer_data

docker run -d -p 9443:9443 -p 8000:8000 \
    --name portainer --restart always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    -v /certs:/certs \
    cr.portainer.io/portainer/portainer-ce:2.9.3 --sslcert /certs/portainer.crt --sslkey /certs/portainer.key
