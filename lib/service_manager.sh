#!/bin/bash

# Service management functions

# List of available services
AVAILABLE_SERVICES=(
    "docker"
    "docker-compose"
    "nginx-proxy-manager"
    "portainer"
    "wordpress"
    "erpnext"
    "nadoo-it"
    "rustdesk"
)

# Function to install a service
install_service() {
    local server=$1
    local service=$2
    local server_ip=$(jq -r --arg name "$server" '.servers[] | select(.name == $name).ip' "$SERVERS_CONFIG")
    local ssh_user=$(jq -r --arg name "$server" '.servers[] | select(.name == $name).user' "$SERVERS_CONFIG")
    
    echo "Installing $service on $server..."
    
    case $service in
        "docker")
            ssh "$ssh_user@$server_ip" "curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh"
            ;;
        "docker-compose")
            ssh "$ssh_user@$server_ip" '
                COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep "tag_name" | cut -d\" -f4)
                sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                sudo chmod +x /usr/local/bin/docker-compose
            '
            ;;
        "nginx-proxy-manager")
            scp "../docker-compose-nginx-proxy-manager.yml" "$ssh_user@$server_ip:~/"
            ssh "$ssh_user@$server_ip" "docker-compose -f docker-compose-nginx-proxy-manager.yml up -d"
            ;;
        "portainer")
            scp "../docker-compose-portainer.yml" "$ssh_user@$server_ip:~/"
            ssh "$ssh_user@$server_ip" "docker-compose -f docker-compose-portainer.yml up -d"
            ;;
        "wordpress")
            # TODO: Implement WordPress installation
            ;;
        "erpnext")
            # TODO: Implement ERPNext installation
            ;;
        "nadoo-it")
            # TODO: Implement NADOO-IT installation
            ;;
        "rustdesk")
            scp "../docker-compose-rustdesk.yml" "$ssh_user@$server_ip:~/"
            ssh "$ssh_user@$server_ip" "docker-compose -f docker-compose-rustdesk.yml up -d"
            ;;
        *)
            echo "Unknown service: $service"
            return 1
            ;;
    esac
    
    # Update server configuration
    local temp_file=$(mktemp)
    jq --arg name "$server" --arg service "$service" '
        .servers = [
            .servers[] | 
            if .name == $name then
                .services += [$service]
            else
                .
            end
        ]
    ' "$SERVERS_CONFIG" > "$temp_file"
    mv "$temp_file" "$SERVERS_CONFIG"
}

# Function to remove a service
remove_service() {
    local server=$1
    local service=$2
    local server_ip=$(jq -r --arg name "$server" '.servers[] | select(.name == $name).ip' "$SERVERS_CONFIG")
    local ssh_user=$(jq -r --arg name "$server" '.servers[] | select(.name == $name).user' "$SERVERS_CONFIG")
    
    echo "Removing $service from $server..."
    
    case $service in
        "docker")
            ssh "$ssh_user@$server_ip" "sudo apt-get remove -y docker docker-engine docker.io containerd runc"
            ;;
        "docker-compose")
            ssh "$ssh_user@$server_ip" "sudo rm /usr/local/bin/docker-compose"
            ;;
        "nginx-proxy-manager")
            ssh "$ssh_user@$server_ip" "docker-compose -f docker-compose-nginx-proxy-manager.yml down -v"
            ssh "$ssh_user@$server_ip" "rm docker-compose-nginx-proxy-manager.yml"
            ;;
        "portainer")
            ssh "$ssh_user@$server_ip" "docker-compose -f docker-compose-portainer.yml down -v"
            ssh "$ssh_user@$server_ip" "rm docker-compose-portainer.yml"
            ;;
        "wordpress")
            ssh "$ssh_user@$server_ip" "docker-compose -f docker-compose-wordpress.yml down -v"
            ssh "$ssh_user@$server_ip" "rm docker-compose-wordpress.yml"
            ;;
        "erpnext")
            # TODO: Implement ERPNext removal
            ;;
        "nadoo-it")
            # TODO: Implement NADOO-IT removal
            ;;
        "rustdesk")
            ssh "$ssh_user@$server_ip" "docker-compose -f docker-compose-rustdesk.yml down -v"
            ssh "$ssh_user@$server_ip" "rm docker-compose-rustdesk.yml"
            ;;
        *)
            echo "Unknown service: $service"
            return 1
            ;;
    esac
    
    # Update server configuration
    local temp_file=$(mktemp)
    jq --arg name "$server" --arg service "$service" '
        .servers = [
            .servers[] | 
            if .name == $name then
                .services -= [$service]
            else
                .
            end
        ]
    ' "$SERVERS_CONFIG" > "$temp_file"
    mv "$temp_file" "$SERVERS_CONFIG"
}

# Function to list installed services
list_services() {
    local server=$1
    jq -r --arg name "$server" '.servers[] | select(.name == $name).services[]' "$SERVERS_CONFIG"
}

# Function to check if a service is installed
is_service_installed() {
    local server=$1
    local service=$2
    jq -r --arg name "$server" --arg service "$service" '
        .servers[] | 
        select(.name == $name).services | 
        contains([$service])
    ' "$SERVERS_CONFIG"
}
