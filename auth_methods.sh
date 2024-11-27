#!/bin/bash

# Function to setup FIDO2/WebAuthn
setup_fido2() {
    local server_ip="$1"
    local admin_user="$2"
    
    echo -e "\n🔑 ${CYAN}Setting up FIDO2/WebAuthn Authentication${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════${NC}"
    
    # Install required packages
    echo -e "\n📦 Installing FIDO2 support packages..."
    ssh "$admin_user@$server_ip" "sudo apt-get update && sudo apt-get install -y libpam-u2f"
    
    # Generate FIDO2 credential
    echo -e "\n🔐 Setting up FIDO2 key..."
    echo -e "${YELLOW}Please insert your FIDO2 security key and touch it when it flashes${NC}"
    
    # Create directory for FIDO2 keys
    ssh "$admin_user@$server_ip" "mkdir -p ~/.config/Yubico"
    
    # Generate key mapping file
    ssh "$admin_user@$server_ip" "pamu2fcfg > ~/.config/Yubico/u2f_keys"
    
    # Configure PAM
    echo -e "\n⚙️ Configuring PAM for FIDO2..."
    ssh "$admin_user@$server_ip" "sudo bash -c 'echo \"auth sufficient pam_u2f.so\" >> /etc/pam.d/common-auth'"
    
    echo -e "\n${GREEN}✅ FIDO2 key setup complete${NC}"
}

# Function to setup Windows Hello
setup_windows_hello() {
    local server_ip="$1"
    local admin_user="$2"
    
    echo -e "\n🪟 ${CYAN}Setting up Windows Hello Authentication${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════${NC}"
    
    # Install required packages
    echo -e "\n📦 Installing Windows Hello support packages..."
    ssh "$admin_user@$server_ip" "sudo apt-get update && sudo apt-get install -y libpam-webauthn"
    
    # Configure PAM for Windows Hello
    echo -e "\n⚙️ Configuring PAM for Windows Hello..."
    # shellcheck disable=SC2029
    ssh "$admin_user@$server_ip" "sudo bash -c 'echo \"auth sufficient pam_webauthn.so\" >> /etc/pam.d/common-auth'"
    
    echo -e "\n${GREEN}✅ Windows Hello setup complete${NC}"
    echo -e "${YELLOW}Note: You'll need to use the Windows Hello for Business credentials on your Windows machine${NC}"
}

# Function to setup Passkeys
setup_passkeys() {
    local server_ip="$1"
    local admin_user="$2"
    
    echo -e "\n🔑 ${CYAN}Setting up Passkey Authentication${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════${NC}"
    
    # Install required packages
    echo -e "\n📦 Installing Passkey support packages..."
    ssh "$admin_user@$server_ip" "sudo apt-get update && sudo apt-get install -y libpam-webauthn"
    
    # Create WebAuthn configuration directory
    ssh "$admin_user@$server_ip" "mkdir -p ~/.config/webauthn"
    
    # Generate WebAuthn configuration
    echo -e "\n⚙️ Configuring Passkey..."
    echo -e "${YELLOW}Please follow the prompts to register your passkey${NC}"
    
    # Generate credential
    ssh "$admin_user@$server_ip" "webauthn-credential create > ~/.config/webauthn/credentials.json"
    
    # Configure PAM
    echo -e "\n⚙️ Configuring PAM for Passkeys..."
    # shellcheck disable=SC2029
    ssh "$admin_user@$server_ip" "sudo bash -c 'echo \"auth sufficient pam_webauthn.so credential_source=file:///home/\$admin_user/.config/webauthn/credentials.json\" >> /etc/pam.d/common-auth'"
    
    echo -e "\n${GREEN}✅ Passkey setup complete${NC}"
}

# Function to manage authentication methods
manage_auth_methods() {
    local server_ip="$1"
    local admin_user="$2"
    
    while true; do
        echo -e "\n🔐 ${CYAN}Authentication Method Management${NC}"
        echo -e "${PURPLE}═══════════════════════════════════════${NC}"
        echo -e "1) 🔑 Setup SSH Keys"
        echo -e "2) 🪟 Setup Windows Hello"
        echo -e "3) 🔐 Setup FIDO2/Security Key"
        echo -e "4) 📱 Setup Passkeys"
        echo -e "5) ⬅️  Back to Main Menu"
        
        read -r -p "Choose an option (1-5): " auth_choice
        
        case "$auth_choice" in
            1)
                setup_ssh_keys "$server_ip" "$admin_user"
                ;;
            2)
                setup_windows_hello "$server_ip" "$admin_user"
                ;;
            3)
                setup_fido2 "$server_ip" "$admin_user"
                ;;
            4)
                setup_passkeys "$server_ip" "$admin_user"
                ;;
            5)
                return 0
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                ;;
        esac
    done
}

# Function to select server for authentication management
select_server_for_auth() {
    echo -e "\n🔐 ${CYAN}Select server to manage authentication:${NC}"
    select_server
    local selected_server=$?
    
    if [ $selected_server -eq 0 ]; then
        local server_info
        server_info=$(get_server_info "$SELECTED_SERVER_IP")
        manage_auth_methods "$SELECTED_SERVER_IP" "$(echo "$server_info" | jq -r '.admin_user')"
    fi
}
