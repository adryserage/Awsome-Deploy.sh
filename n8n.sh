docker pull n8nio/n8n \
docker run -d \
	--name n8n \
	-p 5678:5678 \
-v n8n \
	-e N8N_BASIC_AUTH_ACTIVE="true" \
	-e N8N_BASIC_AUTH_USER="allowebs" \
	-e N8N_BASIC_AUTH_PASSWORD="yasmina1" \
	n8nio/n8n
