#!/bin/bash

# Ensure the script is run with sufficient privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Capture the username of the user who initiated the sudo command
REAL_USER=$(logname)
USER_HOME=$(eval echo ~$REAL_USER)

# Start the SSH agent for the real user and add the specific SSH key
sudo -H -u $REAL_USER bash -c 'eval "$(ssh-agent -s)" && ssh-add "$HOME/.ssh/nadooit_management_ed25519"'


# Start the SSH agent and add the SSH key
eval "$(ssh-agent -s)"
ssh-add "$USER_HOME/.ssh/nadooit_management_ed25519"

# Disabling password authentication
echo "Do you want to disable password authentication for increased security? (Y/n)"
read -r disable_password_auth

if [[ "$disable_password_auth" =~ ^([yY][eE][sS]|[yY])*$ ]]; then
    echo "Disabling password authentication."
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
    systemctl restart sshd
    echo "Password authentication has been disabled."
fi

# Docker, Docker Compose, and Portainer installation
echo "This script will install Docker, Docker Compose, and set up Portainer for managing Docker containers. Do you want to proceed with this setup? (Y/n)"
read -r proceed_with_initial_setup

if [[ "$proceed_with_initial_setup" =~ ^([yY][eE][sS]|[yY])*$ ]]; then
    echo "Continuing with Docker and Portainer setup."
    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh

    # Install Docker Compose
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    sudo curl -L "https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    # Setting up Portainer
    if [ ! -f "$USER_HOME/docker-compose-portainer.yml" ]; then
        echo "docker-compose-portainer.yml file not found in $USER_HOME. Skipping Portainer setup."
    else
        sudo -H -u $REAL_USER bash -c 'docker-compose -f "$HOME/docker-compose-portainer.yml" up -d'
        echo "Portainer has been started with Docker Compose for easy Docker container management."
    fi
    echo "Finished setting up Docker and Portainer."
else
    echo "Setup of Docker and Portainer has been skipped."
fi

# NGINX Proxy Manager installation
echo "Do you want to install NGINX Proxy Manager? This will be skipped by default. (y/N)"
read -r install_nginx_proxy_manager

if [[ "$install_nginx_proxy_manager" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    if [ ! -f "$USER_HOME/docker-compose-nginx-proxy-manager.yml" ]; then
        echo "docker-compose-nginx-proxy-manager.yml file not found in $USER_HOME. Skipping NGINX Proxy Manager setup."
    else
        sudo -H -u $REAL_USER bash -c 'docker-compose -f "$HOME/docker-compose-nginx-proxy-manager.yml" up -d'
        echo "NGINX Proxy Manager has been started with Docker Compose."
    fi
else
    echo "NGINX Proxy Manager installation has been skipped."
fi

echo "Do you want to install WordPress using Docker Compose? (y/N)"
read install_wordpress

if [[ "$install_wordpress" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    echo "Preparing to install WordPress..."
    
    # Prompt for environment variable values
    echo "Please enter the WordPress database host (default 'db'):"
    read wordpress_db_host
    wordpress_db_host=${wordpress_db_host:-db}

    echo "Please enter the WordPress database username:"
    read wordpress_db_user

    echo "Please enter the WordPress database password:"
    read wordpress_db_password

    echo "Please enter the WordPress database name:"
    read wordpress_db_name

    echo "Please enter the MySQL root password:"
    read mysql_root_password

    # Additional MySQL environment variables
    echo "Please enter the MySQL user (default 'wordpressuser'):"
    read mysql_user
    mysql_user=${mysql_user:-wordpressuser}

    echo "Please enter the MySQL password:"
    read mysql_password

    echo "Please enter the MySQL database (default 'wordpressdb'):"
    read mysql_database
    mysql_database=${mysql_database:-wordpressdb}

    echo "Please enter the port for WordPress (default '8000'):"
    read wordpress_port
    wordpress_port=${wordpress_port:-8000}

    echo "Please enter the port for phpMyAdmin (default '8080'):"
    read phpmyadmin_port
    phpmyadmin_port=${phpmyadmin_port:-8080}

    # Create .env file with input values
    echo "Creating .env file..."
    cat << EOF > .env
WORDPRESS_DB_HOST=$wordpress_db_host
WORDPRESS_DB_USER=$wordpress_db_user
WORDPRESS_DB_PASSWORD=$wordpress_db_password
WORDPRESS_DB_NAME=$wordpress_db_name
MYSQL_ROOT_PASSWORD=$mysql_root_password
MYSQL_USER=$mysql_user
MYSQL_PASSWORD=$mysql_password
MYSQL_DATABASE=$mysql_database
WORDPRESS_PORT=$wordpress_port
PHPMYADMIN_PORT=$phpmyadmin_port
EOF

    echo ".env file created successfully."

    # The rest of your script follows
    if [ -f "./docker-compose-wordpress.yml" ]; then
        echo "Starting WordPress services using Docker Compose..."
        sudo docker-compose -f docker-compose-wordpress.yml up -d
        echo "WordPress has been started."
    else
        echo "docker-compose-wordpress.yml file not found."
        exit 1
    fi
else
    echo "Skipping WordPress installation."
fi



# Ask if the user wants to proceed with ERPNext installation
echo "Do you want to proceed with ERPNext installation? (Y/n)"
read install_erpnext

if [[ "$install_erpnext" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
  # ERPNext Setup
  REAL_USER=$(logname)
  USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6) # More reliable method to get the home directory
  erpnext_dir="$USER_HOME/frappe_docker"
  
  # Ensure directory exists or create it
  sudo -u "$REAL_USER" mkdir -p "$erpnext_dir"
  
  # Check if the easy-install.py script is present
  if [ ! -f "$erpnext_dir/easy-install.py" ]; then
    sudo -u "$REAL_USER" wget -O "$erpnext_dir/easy-install.py" https://raw.githubusercontent.com/frappe/bench/develop/easy-install.py
  else
    sudo -u "$REAL_USER" bash -c "cd $erpnext_dir && git pull"
  fi
  
  # Prompt for project name and email
  echo "Please enter your project name:"
  read project_name
  echo "Please enter your email:"
  read email

  # Running the installation as the real user
  sudo -u "$REAL_USER" bash -c "cd $erpnext_dir && python3 easy-install.py --prod --project \"$project_name\" --email \"$email\""
  
  echo "ERPNext has been installed."
else
  echo "ERPNext installation skipped."
fi




# Prompt for NADOO-IT service installation
echo "Do you want to install the NADOO-IT service? (Y/n)"
read install_nadoo_it
if [[ "$install_nadoo_it" =~ ^([yY][eE][sS]|[yY])*$ ]]; then

    REAL_USER=$(logname)
    USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    ssh_key_path="$USER_HOME/.ssh/nadoo_it_ed25519"

    # Check if the SSH key already exists, generate if not
    if [ ! -f "$ssh_key_path" ]; then
        echo "Generating a new SSH key pair for NADOO-IT..."
        read -p "Enter your email address for the SSH key: " email_address

        # Ensure the .ssh directory exists
        sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.ssh"

        # Generate the SSH key
        sudo -u "$REAL_USER" ssh-keygen -t ed25519 -C "$email_address" -f "$ssh_key_path" -N ""

        echo "SSH key pair for NADOO-IT generated."
    else
        echo "Existing SSH key pair for NADOO-IT found."
    fi

    # Ensure the user can read the public key and give instructions for GitHub
    echo "Public key for NADOO-IT:"
    cat "$ssh_key_path.pub"

    echo "Add this public key as a deploy key to your GitHub repository for NADOO-IT."
    echo "1. Go to your repository's Settings -> Deploy keys."
    echo "2. Click on 'Add deploy key', paste the public key, and give it a title."
    echo "3. Ensure 'Allow write access' is checked if write access is required."
    echo "4. Click 'Add key'."
    echo "This will allow the NADOO-IT service on this server to interact with your repository."

    # Prompt user to continue after adding the SSH key
    read -p "Press enter to continue once you've added the deploy key to your GitHub repository."
    
    echo "Configuring SSH to use the generated deploy key for GitHub..."
    # Create or modify the SSH config file to use the specific key for GitHub
    echo -e "Host github.com\n\tHostName github.com\n\tIdentityFile $ssh_key_path\n\tIdentitiesOnly yes\n" >> "$USER_HOME/.ssh/config"

    # Adding GitHub's SSH host key to known_hosts to avoid manual intervention
    ssh-keyscan github.com >> "$USER_HOME/.ssh/known_hosts"

    # Add a delay to ensure changes have propagated
    echo "Waiting for changes to propagate..."
    sleep 10  # This will pause the script for 10 seconds

    # Proceed with cloning the repository
    nadoo_it_dir="$USER_HOME/NADOO-IT"
    if [ -d "$nadoo_it_dir" ]; then
        echo "Existing directory '$nadoo_it_dir' found, pulling latest changes..."
        cd "$nadoo_it_dir"
        git pull
    else
        echo "Attempting to clone the NADOO-IT repository..."
        sudo -u "$REAL_USER" git clone git@github.com:NADOOIT/NADOO-IT.git "$nadoo_it_dir" && cd "$nadoo_it_dir" || {
            echo "Failed to clone the repository. Please check your SSH key configuration and try again."
            exit 1
        }
    fi
    
    # Run setup.sh script from NADOO-IT
    if [ -f "$nadoo_it_dir/setup.sh" ]; then
        echo "Running setup.sh script from NADOO-IT..."
        sudo -u "$REAL_USER" bash "$nadoo_it_dir/setup.sh"
    else
        echo "setup.sh script not found in the NADOO-IT directory."
    fi

    echo "NADOO-IT service installation process has completed."
else
    echo "NADOO-IT service installation skipped."
fi



# Prompt for RustDesk Server OSS installation
echo "Do you want to install RustDesk Server OSS using Docker Compose? (Y/n)"
read install_rustdesk

if [[ "$install_rustdesk" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    echo "Installing RustDesk Server OSS using Docker Compose..."

    # Check Docker and Docker Compose are installed
    if ! command -v docker &> /dev/null || ! command -v docker-compose &> /dev/null; then
        echo "Docker and Docker Compose are required but not found. Please install Docker and Docker Compose first."
        exit 1
    fi

    # Assuming the docker-compose file is named docker-compose-rustdesk.yml and located in the same directory as the setup script
    if [ -f "./docker-compose-rustdesk.yml" ]; then
        echo "Starting RustDesk services using Docker Compose..."
        sudo docker-compose -f docker-compose-rustdesk.yml up -d
        echo "RustDesk Server OSS has been started."
    else
        echo "docker-compose-rustdesk.yml file not found."
        exit 1
    fi
else
    echo "Skipping RustDesk Server OSS installation."
fi


echo "Setup completed."
