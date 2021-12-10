#!/bin/bash

docker volume create portainer_data
docker run -d -p 9443:9443 -p 8000:8000 \
    --name portainer --restart always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer-data:/data \
    -v /etc/letsencrypt/live/app.allowebs.com:/certs/live/yourdomain:ro \
    -v /etc/letsencrypt/archive/app.allowebs.com:/certs/archive/yourdomain:ro \
    cr.portainer.io/portainer/portainer-ce:2.9.3 --sslcert /certs/live/app.allowebs.com/cert.pem --sslkey /certs/live/app.allowebs.com/privkey.pem
