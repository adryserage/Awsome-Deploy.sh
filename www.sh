docker run --detach \
    --name www \
    --env "VIRTUAL_HOST=subdomain.yourdomain.tld" \
    --env "LETSENCRYPT_HOST=subdomain.yourdomain.tld" \
    nginx
