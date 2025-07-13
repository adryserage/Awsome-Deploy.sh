# Awsome-Deploy.sh - Scripts That Make Life Easier

Awsome-Deploy.sh is a collection of bash scripts designed to simplify system setup, Docker deployments, and application installations on Linux systems. Each script provides a menu-driven interface with comprehensive options for customization and configuration.

## Usage

```bash
git clone https://github.com/Allowebs/Awsome-Deploy.sh
chmod u+x Awsome-Deploy.sh/*
cd Awsome-Deploy.sh
```

Run any script with `./script_name.sh`

## Core Scripts

### Basic.sh

- Update System
- Install Homebrew
- Install Froxlor
- Install YunoHost
- Install DigitalOcean Monitor
- Change Time zone System
- Clean System

### Docker.sh

- Install Docker
- Install FTP
- Install Portainer
- Install Autoheal
- Install SSL for Apache
- Install Poste.io
- Install Nginx

## Application Deployment Scripts

All application scripts are located in the `apps/` directory.

### WordPress (apps/wordpress.sh)

- Docker-based WordPress installation with MySQL
- Configurable ports and credentials
- Persistent volume storage
- Automatic network setup

### NextCloud (apps/nextcloud.sh)

- Docker-based NextCloud with PostgreSQL backend
- Configurable admin credentials and ports
- Persistent data storage
- Automatic network configuration

### Gitea (apps/gitea.sh)

- Lightweight Git service with PostgreSQL backend
- Configurable HTTP and SSH ports
- Persistent data storage
- Automatic network setup

### Monitoring Tools (apps/monitoring.sh)

- Prometheus and Grafana stack deployment
- Configurable ports and volumes
- Pre-configured dashboards
- Persistent data storage

### Database Servers (apps/databases.sh)

- Menu-driven Docker deployment for:
  - MySQL
  - PostgreSQL
  - MongoDB
  - All databases together
- Randomized secure credentials
- Configurable ports
- Persistent data storage

### Ethibox (apps/ethibox.sh)

- Open-source web app hoster
- Configurable port settings
- Persistent data storage
- Error handling and status checks

### n8n (apps/n8n.sh)

- Workflow automation platform
- Configurable authentication and ports
- Persistent workflow storage
- Timezone configuration

### Nginx Proxy Manager (apps/nginx-proxy.sh)

- Automatic SSL certificate management
- Configurable HTTP, HTTPS, and admin ports
- Docker network integration
- Let's Encrypt integration

### OnTrack (apps/ontrack.sh)

- Personal expense tracking application
- Multiple installation methods (Docker, Homebrew, Manual)
- Database setup and configuration
- Persistent data storage

### WHMCS (apps/whmcs.sh)

- Web hosting billing & automation platform
- Docker or traditional LAMP stack installation
- Configurable database settings
- Comprehensive setup instructions

### YunoHost (apps/yunohost.sh)

- Self-hosting platform installation
- Multiple installation methods (Debian, Docker, VPS)
- Configurable ports and settings
- Post-installation guidance

## Security Scripts

All security scripts are located in the `security/` directory.

### Firewall (security/firewall.sh)

- UFW-based firewall configuration
- Predefined profiles (basic server, web server, mail server, database server)
- Custom rule management
- Enable/disable/status options

### Automatic Updates (security/auto_updates.sh)

- Configure unattended-upgrades package
- Options for security or full updates
- Email notification configuration
- Enable/disable/status options

### SSL Certificate Management (security/ssl_manager.sh)

- Certbot installation and certificate management
- Support for Apache, Nginx, standalone mode
- Wildcard certificate support with DNS providers
- Certificate renewal, revocation, and info display

### User Management (security/user_management.sh)

- User creation/deletion
- Group management
- Secure user creation
- Password policy enforcement
- SSH hardening
- Root login disabling
- File permission audits
- SUID/SGID audits
- System hardening measures

## Maintenance Scripts

All maintenance scripts are located in the `maintenance/` directory.

### Docker Backup (maintenance/backup.sh)

- Backup and restore Docker containers and volumes
- Schedule automatic backups with cron
- List and clean backups
- Configurable backup settings

## Requirements

- Debian/Ubuntu-based Linux system
- Bash shell
- Internet connection
- Root/sudo access

## Dependencies

Depending on the scripts you use, the following may be installed:

- Docker and Docker Compose
- Openssl
- jq (for JSON parsing)
- Certbot and plugins
- UFW
- unattended-upgrades
- Cron

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
