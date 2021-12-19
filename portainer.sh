docker run -d -p 9443:9443 \
    --name portainer --restart always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer-data:/data \
    -v /etc/letsencrypt/live/app.allowebs.com:/certs/live/app.allowebs.com:ro \
    -v /etc/letsencrypt/archive/app.allowebs.com:/certs/archive/app.allowebs.com:ro \
    cr.portainer.io/portainer/portainer-ce:latest --sslcert /certs/live/app.allowebs.com/cert.pem --sslkey /certs/live/app.allowebs.com/privkey.pem
