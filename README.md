# Auto Ubuntu VPS Server Setup Script

This script is a comprehensive tool for managing multiple Ubuntu VPS servers. It handles installation and management of essential services, including Docker, Docker Compose, ERPNext, and NADOO-IT services.

## Quick Start

1. Clone this repository:
```bash
git clone https://github.com/NADOOIT/Auto-Ubuntu-VPS-Server-Setup-Script.git
cd Auto-Ubuntu-VPS-Server-Setup-Script
```

2. Make the scripts executable:
```bash
chmod +x manage_servers.sh lib/service_manager.sh
```

3. Run the management interface:
```bash
./manage_servers.sh
```

## Features

- **Multiple Server Management**
  - Add and remove servers
  - Store server configurations
  - Track installed services per server

- **Service Management**
  - Docker and Docker Compose
  - NGINX Proxy Manager
  - Portainer
  - WordPress
  - ERPNext
  - NADOO-IT Services
  - RustDesk Server

- **NADOO-IT Service Management**
  - Automated backups
  - Safe updates with rollback capability
  - Database management

- **SSH Key Management**
  - Automatic key generation and distribution
  - Password-less authentication
  - Secure connection management

## Prerequisites

Before using the script, ensure you have:
- A Unix-like operating system (Linux/macOS)
- SSH client installed
- `jq` command-line JSON processor
- `expect` for handling interactive prompts
- `sqlite3` for database management

The script will automatically check for and install missing requirements.

## Using the Management Interface

1. **Adding a Server**
   - Select "Add Server" from the main menu
   - Enter server details (name, IP, SSH user)
   - The system will automatically configure SSH access

2. **Managing Services**
   - Select "Manage Server Services" from the main menu
   - Choose a server to manage
   - Install or remove services as needed
   - Update and backup NADOO-IT services

3. **SSH Access**
   - The system automatically manages SSH keys
   - First-time connection requires password
   - Subsequent connections are password-less
   - Keys are stored securely in `~/.ssh/`

## SSH Key Management

The script handles SSH key management automatically:

1. **First-time Setup**
   ```bash
   ./manage_servers.sh
   ```
   - Select "Add Server"
   - Enter server details
   - The system will:
     - Generate SSH key if needed
     - Copy public key to server
     - Configure password-less authentication

2. **Manual SSH Access**
   ```bash
   ./manage_servers.sh ssh <server-name>
   ```
   Or use the interactive menu:
   - Select "SSH to Server" from the main menu
   - Choose the server to connect to

## Backup and Update Procedures

### NADOO-IT Services

1. **Backup**
   - Automatically performed before updates
   - Stored in `config/backups/`
   - Includes SQLite database
   - Timestamped for easy reference

2. **Update**
   - Creates backup automatically
   - Stashes local changes
   - Pulls latest updates
   - Automatic rollback on failure

### Service Configuration

All service configurations are stored in:
- `config/servers.json` - Server configurations
- `config/backups/` - Service backups
- Docker Compose files in the root directory

## Troubleshooting

1. **SSH Connection Issues**
   - Check server IP and credentials
   - Ensure SSH service is running
   - Verify firewall settings
   - Use "Reset SSH Key" option if needed

2. **Service Installation Failures**
   - Check server connectivity
   - Verify system requirements
   - Check disk space
   - Review logs in `config/logs/`

3. **Update Failures**
   - Automatic rollback will restore previous state
   - Check backup directory for database restore
   - Review update logs
   - Contact support if needed

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
