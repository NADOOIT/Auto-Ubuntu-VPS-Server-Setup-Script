#!/bin/bash

# Check if a config file exists
if [ -f server_setup.config ]; then
  echo "Config file found. Loading settings..."
  source server_setup.config
else
  # Prompt for server details
  read -p "Enter your server IP: " server_ip
  read -p "Enter your new username: " new_username
  echo "Enter your new user password: "
  read -s new_user_password
  echo "Enter your email for the SSH key: "
  read email
  echo "Enter root password (input will be hidden):"
  read -s root_password
fi

# Remove server from known_hosts to avoid SSH key fingerprint prompt
ssh-keygen -R "$server_ip"

# Use expect to automate SSH login and initial setup
expect <<EOF
set timeout -1

# Spawn SSH session
spawn ssh root@$server_ip

# Handle SSH key fingerprint verification
expect {
    "*yes/no*" {
        send "yes\r"
        expect "*?assword:" { send "$root_password\r" }
    }
    "*?assword:" {
        send "$root_password\r"
    }
}

# Wait for the prompt
expect "#"

# Create docker group manually if it doesn't exist
send "getent group docker || groupadd docker\r"
expect "#"

# Add the new user to the sudo and docker groups
send "id -u $new_username &>/dev/null || adduser $new_username --gecos '' --disabled-password\r"
expect "#"
send "echo '${new_username}:${new_user_password}' | chpasswd\r"
expect "#"
send "usermod -aG sudo $new_username\r"
expect "#"
send "usermod -aG docker $new_username\r"
expect "#"

# Update, upgrade, install git, and reboot
send "apt update && apt upgrade -y && apt install git -y && reboot\r"
expect "#"

# Exit
send "exit\r"
expect eof
EOF

echo "Waiting for server to reboot..."
sleep 60 # Adjust this based on the typical reboot time of your server

# Check server availability and log back in
while true; do
  # Try to establish an SSH connection; no operation is performed on the server
  ssh -o ConnectTimeout=5 $new_username@$server_ip "echo 'Server is up'" > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "Server is back online. Proceeding with SSH key setup and additional configurations."
    break
  else
    echo "Waiting for server to come back online..."
    sleep 10
  fi
done


# SSH to the server and continue with the setup
ssh -t $new_username@$server_ip <<'EOF'
mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys
echo "SSH directory and authorized_keys file created."
# Generate a new SSH key or use an existing one, then add it to authorized_keys here, if necessary

# Clone the repository and run additional setup scripts
git clone https://github.com/NADOOIT/Auto-Ubuntu-VPS-Server-Setup-Script.git
cd Auto-Ubuntu-VPS-Server-Setup-Script
chmod +x setup.sh
./setup.sh # or sudo ./setup.sh if not logged in as root

EOF
