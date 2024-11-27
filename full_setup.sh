#!/bin/bash

# Enable error handling
set -e
trap 'echo "Error on line $LINENO. Exit code: $?"' ERR

# Function to handle timeouts and retries
wait_for_command() {
    local timeout=$1
    local command=$2
    local message=$3
    local retries=${4:-1}
    local wait_time=${5:-10}
    
    for ((i=1; i<=retries; i++)); do
        echo "$message (attempt $i/$retries)"
        if timeout $timeout bash -c "$command"; then
            return 0
        fi
        if [ $i -lt $retries ]; then
            echo "Command failed. Retrying in $wait_time seconds..."
            sleep $wait_time
        fi
    done
    return 1
}

# Function to check server availability
check_server() {
    local host=$1
    local user=$2
    local max_attempts=${3:-30}
    local wait_time=${4:-10}
    
    for ((i=1; i<=max_attempts; i++)); do
        if ssh -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no "$user@$host" "exit" >/dev/null 2>&1; then
            echo "Server is accessible"
            return 0
        fi
        echo "Attempt $i/$max_attempts: Server not yet accessible. Waiting $wait_time seconds..."
        sleep $wait_time
    done
    echo "Failed to connect to server after $max_attempts attempts"
    return 1
}

# Check if a config file exists
if [ -f server_setup.config ]; then
    echo "Config file found. Loading settings..."
    source server_setup.config
else
    # Prompt for server details with validation
    while true; do
        read -p "Enter your server IP: " server_ip
        if [[ $server_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            break
        fi
        echo "Invalid IP address format. Please try again."
    done
    
    while true; do
        read -p "Enter your new username: " new_username
        if [[ $new_username =~ ^[a-z_][a-z0-9_-]*[$]?$ ]]; then
            break
        fi
        echo "Invalid username format. Please use only lowercase letters, numbers, underscore, and hyphen."
    done
    
    while true; do
        echo "Enter your new user password (minimum 8 characters): "
        read -s new_user_password
        echo
        if [ ${#new_user_password} -ge 8 ]; then
            break
        fi
        echo "Password too short. Please use at least 8 characters."
    done
    
    read -p "Enter your email for the SSH key: " email
    
    while true; do
        echo "Enter root password (input will be hidden):"
        read -s root_password
        echo
        if [ ${#root_password} -gt 0 ]; then
            break
        fi
        echo "Password cannot be empty."
    done
fi

# Remove server from known_hosts to avoid SSH key fingerprint prompt
ssh-keygen -R "$server_ip" 2>/dev/null || true

# Create expect script for the initial setup
cat > /tmp/server_setup.exp << EOF
#!/usr/bin/expect -f
set timeout 300
log_user 1

# Handle SSH connection with retry mechanism
proc connect_ssh {max_attempts} {
    set attempt 1
    while {1} {
        if {$attempt > $max_attempts} {
            puts "Failed to connect after $max_attempts attempts"
            exit 1
        }
        
        puts "Attempt $attempt to connect..."
        
        spawn ssh root@$::env(server_ip)
        
        expect {
            timeout {
                puts "Connection timed out"
                incr attempt
                continue
            }
            "Connection refused" {
                puts "Connection refused"
                incr attempt
                sleep 10
                continue
            }
            "*yes/no*" {
                send "yes\r"
                exp_continue
            }
            "*?assword:*" {
                send "$::env(root_password)\r"
                break
            }
            eof {
                puts "Connection failed"
                incr attempt
                sleep 10
                continue
            }
        }
    }
    return 1
}

# Try to connect with retries
if {![connect_ssh 5]} {
    puts "Failed to establish SSH connection"
    exit 1
}

# Wait for the prompt and handle potential issues
expect {
    timeout {
        puts "Timeout waiting for prompt"
        exit 1
    }
    "*?assword:*" {
        send "$::env(root_password)\r"
        exp_continue
    }
    "#" {
        # Continue with setup
    }
}

# Create docker group and set up user
send "getent group docker || groupadd docker\r"
expect "#"

send "id -u $::env(new_username) &>/dev/null || adduser $::env(new_username) --gecos '' --disabled-password\r"
expect "#"

send "echo '$::env(new_username):$::env(new_user_password)' | chpasswd\r"
expect "#"

send "usermod -aG sudo $::env(new_username)\r"
expect "#"

send "usermod -aG docker $::env(new_username)\r"
expect "#"

# Update and install packages with proper error handling
send "export DEBIAN_FRONTEND=noninteractive\r"
expect "#"

send "apt-get update\r"
expect "#"

send "apt-get upgrade -y\r"
expect "#"

send "apt-get install -y git expect\r"
expect "#"

send "reboot\r"
expect eof
EOF

chmod +x /tmp/server_setup.exp

# Export variables for expect script
export server_ip new_username new_user_password email root_password

# Run the expect script
if ! wait_for_command 600 "/tmp/server_setup.exp" "Running initial server setup" 3 30; then
    echo "Initial server setup failed"
    rm -f /tmp/server_setup.exp
    exit 1
fi

rm -f /tmp/server_setup.exp

echo "Waiting for server to reboot..."
sleep 30

# Check server availability with proper timeout and retry mechanism
if ! check_server "$server_ip" "$new_username" 30 10; then
    echo "Failed to reconnect to server after reboot"
    exit 1
fi

# Continue with additional setup
echo "Server is back online. Proceeding with SSH key setup and additional configurations."

# Create a temporary script for the remaining setup
cat > /tmp/remaining_setup.sh << 'EOF'
#!/bin/bash
set -e
trap 'echo "Error on line $LINENO. Exit code: $?"' ERR

mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

if ! git clone https://github.com/NADOOIT/Auto-Ubuntu-VPS-Server-Setup-Script.git; then
    echo "Failed to clone repository"
    exit 1
fi

cd Auto-Ubuntu-VPS-Server-Setup-Script
chmod +x setup.sh
sudo ./setup.sh
EOF

# Copy and execute the remaining setup script
scp /tmp/remaining_setup.sh "$new_username@$server_ip:~/"
ssh -t "$new_username@$server_ip" "chmod +x ~/remaining_setup.sh && ~/remaining_setup.sh"

rm -f /tmp/remaining_setup.sh

echo "Setup completed successfully!"
