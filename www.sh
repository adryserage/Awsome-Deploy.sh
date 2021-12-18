docker run --detach \
    --name www \
    --env "VIRTUAL_HOST=allowebs.com" \
    --env "LETSENCRYPT_HOST=allowebs.com" \
    nginx
