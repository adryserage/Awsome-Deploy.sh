docker run -d \
  -p 80:80 \
  -v /root/my-local-conf.yml:/app/public/conf.yml \
  --name dashboard \
  --restart=always \
  lissy93/dashy:latest
