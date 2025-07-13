#!/bin/bash
# SSL Certificate Management Script using Let's Encrypt/Certbot

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)"
  exit 1
fi

echo "SSL Certificate Management"
echo "=========================="
echo ""

# Menu options
PS3='Please select an option: '
options=(
  "Install Certbot" 
  "Obtain Certificate (Apache)" 
  "Obtain Certificate (Nginx)" 
  "Obtain Certificate (Standalone)" 
  "Obtain Wildcard Certificate" 
  "Renew Certificates" 
  "Auto-Renewal Setup" 
  "List Certificates" 
  "Revoke Certificate" 
  "Show Certificate Info" 
  "Quit"
)

select opt in "${options[@]}"
do
  case $opt in
    "Install Certbot")
      echo "Installing Certbot and dependencies..."
      
      # Detect OS
      if [ -f /etc/debian_version ]; then
        # Debian/Ubuntu
        apt-get update -y
        apt-get install -y certbot python3-certbot-apache python3-certbot-nginx
      elif [ -f /etc/redhat-release ]; then
        # CentOS/RHEL
        yum install -y epel-release
        yum install -y certbot python3-certbot-apache python3-certbot-nginx
      else
        echo "Unsupported OS. Please install Certbot manually."
        continue
      fi
      
      echo "Certbot installed successfully!"
      ;;
      
    "Obtain Certificate (Apache)")
      echo "Obtaining SSL certificate for Apache..."
      
      read -p "Enter domain name (e.g., example.com): " domain
      read -p "Include www subdomain? (y/n): " include_www
      
      if [ "$include_www" = "y" ] || [ "$include_www" = "Y" ]; then
        certbot --apache -d "$domain" -d "www.$domain"
      else
        certbot --apache -d "$domain"
      fi
      
      echo "Certificate process completed!"
      ;;
      
    "Obtain Certificate (Nginx)")
      echo "Obtaining SSL certificate for Nginx..."
      
      read -p "Enter domain name (e.g., example.com): " domain
      read -p "Include www subdomain? (y/n): " include_www
      
      if [ "$include_www" = "y" ] || [ "$include_www" = "Y" ]; then
        certbot --nginx -d "$domain" -d "www.$domain"
      else
        certbot --nginx -d "$domain"
      fi
      
      echo "Certificate process completed!"
      ;;
      
    "Obtain Certificate (Standalone)")
      echo "Obtaining SSL certificate in standalone mode..."
      echo "Note: This will temporarily use port 80. Make sure it's not in use."
      
      read -p "Enter domain name (e.g., example.com): " domain
      read -p "Include www subdomain? (y/n): " include_www
      
      if [ "$include_www" = "y" ] || [ "$include_www" = "Y" ]; then
        certbot certonly --standalone -d "$domain" -d "www.$domain"
      else
        certbot certonly --standalone -d "$domain"
      fi
      
      echo "Certificate process completed!"
      echo "Certificate files are located in /etc/letsencrypt/live/$domain/"
      ;;
      
    "Obtain Wildcard Certificate")
      echo "Obtaining wildcard SSL certificate..."
      echo "Note: This requires DNS verification."
      
      read -p "Enter base domain (e.g., example.com): " domain
      
      echo "Select DNS provider for verification:"
      echo "1) Manual (you'll need to create TXT records manually)"
      echo "2) Cloudflare"
      echo "3) Route53 (AWS)"
      echo "4) DigitalOcean"
      read -p "Enter choice (1-4): " dns_choice
      
      case $dns_choice in
        1)
          # Manual DNS verification
          certbot certonly --manual --preferred-challenges=dns -d "$domain" -d "*.$domain" \
            --server https://acme-v02.api.letsencrypt.org/directory
          ;;
        2)
          # Cloudflare
          apt-get install -y python3-certbot-dns-cloudflare
          echo "You need to create a Cloudflare API token with Zone:DNS:Edit permissions"
          read -p "Press Enter when ready to continue..."
          
          # Create credentials file
          mkdir -p /etc/letsencrypt/cloudflare
          echo "# Cloudflare API token" > /etc/letsencrypt/cloudflare/cloudflare.ini
          read -p "Enter Cloudflare API token: " cf_token
          echo "dns_cloudflare_api_token = $cf_token" >> /etc/letsencrypt/cloudflare/cloudflare.ini
          chmod 600 /etc/letsencrypt/cloudflare/cloudflare.ini
          
          certbot certonly --dns-cloudflare \
            --dns-cloudflare-credentials /etc/letsencrypt/cloudflare/cloudflare.ini \
            -d "$domain" -d "*.$domain" \
            --server https://acme-v02.api.letsencrypt.org/directory
          ;;
        3)
          # AWS Route53
          apt-get install -y python3-certbot-dns-route53
          echo "You need AWS credentials with Route53 permissions"
          read -p "Press Enter when ready to continue..."
          
          # Check for AWS credentials
          if [ ! -f ~/.aws/credentials ]; then
            mkdir -p ~/.aws
            echo "[default]" > ~/.aws/credentials
            read -p "Enter AWS Access Key ID: " aws_access_key
            read -p "Enter AWS Secret Access Key: " aws_secret_key
            echo "aws_access_key_id = $aws_access_key" >> ~/.aws/credentials
            echo "aws_secret_access_key = $aws_secret_key" >> ~/.aws/credentials
            chmod 600 ~/.aws/credentials
          fi
          
          certbot certonly --dns-route53 \
            -d "$domain" -d "*.$domain" \
            --server https://acme-v02.api.letsencrypt.org/directory
          ;;
        4)
          # DigitalOcean
          apt-get install -y python3-certbot-dns-digitalocean
          echo "You need a DigitalOcean API token"
          read -p "Press Enter when ready to continue..."
          
          # Create credentials file
          mkdir -p /etc/letsencrypt/digitalocean
          echo "# DigitalOcean API token" > /etc/letsencrypt/digitalocean/digitalocean.ini
          read -p "Enter DigitalOcean API token: " do_token
          echo "dns_digitalocean_token = $do_token" >> /etc/letsencrypt/digitalocean/digitalocean.ini
          chmod 600 /etc/letsencrypt/digitalocean/digitalocean.ini
          
          certbot certonly --dns-digitalocean \
            --dns-digitalocean-credentials /etc/letsencrypt/digitalocean/digitalocean.ini \
            -d "$domain" -d "*.$domain" \
            --server https://acme-v02.api.letsencrypt.org/directory
          ;;
        *)
          echo "Invalid choice."
          continue
          ;;
      esac
      
      echo "Wildcard certificate process completed!"
      echo "Certificate files are located in /etc/letsencrypt/live/$domain/"
      ;;
      
    "Renew Certificates")
      echo "Renewing all certificates..."
      certbot renew
      echo "Renewal process completed!"
      ;;
      
    "Auto-Renewal Setup")
      echo "Setting up automatic certificate renewal..."
      
      # Check if cron is installed
      if ! command -v crontab &> /dev/null; then
        echo "Installing cron..."
        apt-get update -y
        apt-get install -y cron
      fi
      
      # Add cron job for renewal
      (crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet") | crontab -
      
      echo "Auto-renewal has been set up to run daily at 3:00 AM."
      echo "You can verify with: crontab -l"
      ;;
      
    "List Certificates")
      echo "Listing all certificates..."
      certbot certificates
      ;;
      
    "Revoke Certificate")
      echo "Revoking a certificate..."
      
      # List certificates first
      echo "Available certificates:"
      certbot certificates
      
      read -p "Enter domain name of certificate to revoke: " revoke_domain
      
      # Confirm revocation
      read -p "Are you sure you want to revoke the certificate for $revoke_domain? (y/n): " confirm
      if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        certbot revoke --cert-name "$revoke_domain"
        echo "Certificate for $revoke_domain has been revoked."
      else
        echo "Revocation cancelled."
      fi
      ;;
      
    "Show Certificate Info")
      echo "Showing certificate information..."
      
      read -p "Enter domain name: " cert_domain
      
      # Check if certificate exists
      if [ -d "/etc/letsencrypt/live/$cert_domain" ]; then
        echo "Certificate information for $cert_domain:"
        echo "----------------------------------------"
        openssl x509 -in "/etc/letsencrypt/live/$cert_domain/cert.pem" -text -noout
      else
        echo "Certificate for $cert_domain not found."
      fi
      ;;
      
    "Quit")
      break
      ;;
      
    *) 
      echo "Invalid option $REPLY"
      ;;
  esac
done
