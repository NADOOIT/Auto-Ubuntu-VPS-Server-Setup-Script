#!/bin/bash

CURRENT_USER=$(logname)
USER_HOME=$(eval echo ~$CURRENT_USER)

# Start the SSH agent and add the SSH key
eval "$(ssh-agent -s)"
ssh-add "$USER_HOME/.ssh/nadooit_management_ed25519"

# Early option to disable password authentication
echo "Do you want to disable password authentication for increased security? (Y/n)"
read disable_password_auth

if [[ "$disable_password_auth" =~ ^([yY][eE][sS]|[yY])*$ ]]; then
  echo "Disabling password authentication."
  
  # Backup sshd_config file before modifying
  echo "Creating a backup of your sshd_config file..."
  sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
  echo "Backup created at /etc/ssh/sshd_config.bak."
  
  sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
  sudo systemctl restart sshd
  echo "Password authentication has been disabled."
fi

# Early option to skip to service installation
echo "Do you want to skip to service installation? (Y/n)"
read skip_to_service_install

if [[ "$skip_to_service_install" =~ ^([nN][oO]|[nN])$ ]]
then
    echo "Continuing with full setup script."

    # Install Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    echo "Docker has been installed."

    # Install Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose has been installed."

    # Pull and Run Portainer
    docker volume create portainer_data
    docker run -d -p 8001:8000 -p 9001:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce
    echo "Portainer has been pulled and run."

    echo "Finished system setup, moving to service installation."
fi

# Prompt for ERPNext installation
echo "Do you want to install ERPNext? (Y/n)"
read install_erpnext

if [[ "$install_erpnext" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
  # ERPNext Setup
  erpnext_dir="/home/$SUDO_USER/frappe_docker"
  
  # Ensure directory exists or create it
  if [ ! -d "$erpnext_dir" ]; then
    mkdir -p $erpnext_dir
  fi
  
  # Check if the easy-install.py script is present
  if [ ! -f "$erpnext_dir/easy-install.py" ]; then
    wget -O "$erpnext_dir/easy-install.py" https://raw.githubusercontent.com/frappe/bench/develop/easy-install.py
  else
    cd $erpnext_dir
    git pull
    cd -
  fi
  
  # Prompt for project name
  echo "Please enter your project name:"
  read project_name

  # Prompt for email
  echo "Please enter your email:"
  read email

  cd $erpnext_dir
  python3 easy-install.py --prod --project "$project_name" --email "$email"

  cp example.env .env
  echo "ERPNext has been installed."
fi

# Prompt for nadooit_management service installation
echo "Do you want to install nadooit_management service? (Y/n)"
read install_nadooit
if [[ "$install_nadooit" =~ ^([yY][eE][sS]|[yY])*$ ]]; then

    # Define the path for the nadooit_management SSH key
    ssh_key_path="$USER_HOME/.ssh/nadooit_management_ed25519"

    # Check if the SSH key already exists, generate if not
    if [ ! -f "$ssh_key_path" ]; then
        echo "Generating a new SSH key pair for nadooit_management..."
        read -p "Enter your email address for the SSH key: " email_address

        # Ensure the .ssh directory exists
        mkdir -p "$USER_HOME/.ssh"
        chown "$CURRENT_USER":"$CURRENT_USER" "$USER_HOME/.ssh"

        # Generate the SSH key
        sudo -u "$CURRENT_USER" ssh-keygen -t ed25519 -C "$email_address" -f "$ssh_key_path" -N ""

        echo "SSH key pair for nadooit_management generated."
    else
        echo "Existing SSH key pair for nadooit_management found."
    fi

    # Ensure the user can read the public key and give instructions for GitHub
    sudo -u "$CURRENT_USER" chmod 644 "$ssh_key_path.pub"
    echo "Public key for nadooit_management:"
    sudo -u "$CURRENT_USER" cat "$ssh_key_path.pub"

    echo "Add this public key as a deploy key to your GitHub repository for nadooit_management."
    echo "1. Go to your repository's Settings -> Deploy keys."
    echo "2. Click on 'Add deploy key', paste the public key, and give it a title."
    echo "3. Ensure 'Allow write access' is checked if write access is required."
    echo "4. Click 'Add key'."
    echo "This will allow the nadooit_management service on this server to interact with your repository."

    # Prompt user to continue after adding the SSH key
    read -p "Press enter to continue once you've added the deploy key to your GitHub repository."
    
    echo "Configuring SSH to use the generated deploy key for GitHub..."
    # Create or modify the SSH config file to use the specific key for GitHub
    echo -e "Host github.com\n\tHostName github.com\n\tIdentityFile $ssh_key_path\n\tIdentitiesOnly yes\n" >> "$USER_HOME/.ssh/config"

    # Ensure correct permissions on the config file
    chmod 600 "$USER_HOME/.ssh/config"
    chown "$CURRENT_USER":"$CURRENT_USER" "$USER_HOME/.ssh/config"

    # Clone the repository into the user's home directory
    echo "Cloning the repository..."
    nadooit_dir="$USER_HOME/NADOO-IT"
    if [ -d "$nadooit_dir" ]; then
        echo "Existing directory '$nadooit_dir' found, pulling latest changes..."
        cd "$nadooit_dir"
        git pull
    else
        git clone git@github.com:NADOOIT/NADOO-IT.git "$nadooit_dir"
        cd "$nadooit_dir"
    fi
    
    # Run setup.sh script from NADOO-IT
    if [ -f "./setup.sh" ]; then
        echo "Running setup.sh script from NADOO-IT..."
        bash ./setup.sh
    else
        echo "setup.sh script not found in the NADOO-IT directory."
    fi

    echo "nadooit_management service installation process has completed."
fi

# Prompt for RustDesk Server OSS installation
echo "Do you want to install RustDesk Server OSS using Docker Compose? (Y/n)"
read install_rustdesk

if [[ "$install_rustdesk" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    echo "Installing RustDesk Server OSS using Docker Compose..."

    # Navigate to the directory where the docker-compose file is located
    cd "$USER_HOME"

    # Check Docker and Docker Compose are installed
    if ! command -v docker &> /dev/null || ! command -v docker-compose &> /dev/null; then
        echo "Docker and Docker Compose are required but not found. Please install Docker and Docker Compose first."
        exit 1
    fi

    # Assuming the docker-compose file is named docker-compose-rustdesk.yml and located in the same directory as the setup script
    if [ -f "$USER_HOME/docker-compose-rustdesk.yml" ]; then
        echo "Starting RustDesk services using Docker Compose..."
        sudo docker-compose -f docker-compose-rustdesk.yml up -d
        echo "RustDesk Server OSS has been started."
    else
        echo "docker-compose-rustdesk.yml file not found. Please ensure the file is in $USER_HOME."
        exit 1
    fi
else
    echo "Skipping RustDesk Server OSS installation."
fi


echo "Setup completed."
