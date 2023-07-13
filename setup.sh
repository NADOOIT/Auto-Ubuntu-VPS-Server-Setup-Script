#!/bin/bash
CURRENT_USER=$(whoami)
USER_HOME=$(eval echo ~$CURRENT_USER)

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
    docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce
    echo "Portainer has been pulled and run."

    echo "Finished system setup, moving to service installation."
fi

# Prompt for ERPNext installation
echo "Do you want to install ERPNext? (Y/n)"
read install_erpnext

if [[ "$install_erpnext" =~ ^([yY][eE][sS]|[yY])*$ ]]; then
  # ERPNext Setup
  erpnext_dir=$USER_HOME/frappe_docker
  if [ -d "$erpnext_dir" ]; then
    echo "Existing directory '$erpnext_dir' found, pulling latest changes..."
    cd $erpnext_dir
    git pull
    cd -
  else
    git clone https://github.com/frappe/frappe_docker.git $erpnext_dir
  fi
  cd $erpnext_dir
  cp example.env .env
  echo "ERPNext has been installed."
fi

# Prompt for nadooit_management service installation
echo "Do you want to install nadooit_management service? (Y/n)"
read install_nadooit
if [[ "$install_nadooit" =~ ^([yY][eE][sS]|[yY])*$ ]]; then

    # Generate an SSH key pair if it doesn't already exist
    if [ ! -f "~/.ssh/id_ed25519" ]; then
        echo "Generating a new SSH key pair..."
        read -p "Enter your email address: " email_address
        ssh-keygen -t ed25519 -C "$email_address"
        echo "SSH key pair generated."
    else
        echo "Existing SSH key pair found."
    fi

    # Display the public key
    echo "Public key:"
    cat ~/.ssh/id_ed25519.pub
    echo "Add this public key to your GitHub account before continuing. Go to your GitHub account settings, click on SSH and GPG keys, and click on the New SSH key button. Paste the copied public key into the Key field, give it a meaningful title, and click on Add SSH key."

    # Prompt user to continue after adding the SSH key
    read -p "Press enter to continue once you've added the SSH key to your GitHub account."

    # Clone the repository into user's home directory
    echo "Cloning the repository..."
    nadooit_dir=$HOME/nadooit_managmentsystem
    if [ -d "$nadooit_dir" ]; then
        echo "Existing directory '$nadooit_dir' found, pulling latest changes..."
        cd $nadooit_dir
        git pull
        cd -
    else
        git clone git@github.com:NADOOITChristophBa/nadooit_managmentsystem.git $nadooit_dir
    fi
    cd $nadooit_dir
    cp .env.example .env

    echo "The .env file has been copied. It's recommended to update this file with real production values."

    # Ask the user if they want to update the .env file now
    echo "Do you want to update the .env file now? (Y/n)"
    read update_env

    # If user wants to update .env file
    if [[ "$update_env" =~ ^([yY][eE][sS]|[yY])*$ ]]; then
        echo "Please enter the following values for the .env file:"
        read -p "DJANGO_SECRET_KEY: " django_secret_key
        read -p "DOMAIN (for DJANGO_CSRF_TRUSTED_ORIGINS): " domain
        read -p "ACME_DEFAUT_EMAIL: " acme_default_email
        read -p "COCKROACH_DB_HOST: " cockroach_db_host
        read -p "COCKROACH_DB_NAME: " cockroach_db_name
        read -p "COCKROACH_DB_PORT: " cockroach_db_port
        read -p "COCKROACH_DB_USER: " cockroach_db_user
        read -p "COCKROACH_DB_PASSWORD: " cockroach_db_password
        read -p "COCKROACH_DB_OPTIONS: " cockroach_db_options
        read -p "NADOOIT__API_KEY: " nadooit_api_key
        read -p "NADOOIT__USER_CODE: " nadooit_user_code
        read -p "OPENAI_API_KEY: " openai_api_key

        sed -i "s/your_secret_key/$django_secret_key/" .env
        sed -i "s/your_domain/$domain/" .env
        sed -i "s/your_email/$acme_default_email/" .env
        sed -i "s/your_openai_api_key/$openai_api_key/" .env
        sed -i "s/your_cockroach_db_host/$cockroach_db_host/" .env
        sed -i "s/your_cockroach_db_name/$cockroach_db_name/" .env
        sed -i "s/your_cockroach_db_port/$cockroach_db_port/" .env
        sed -i "s/your_cockroach_db_user/$cockroach_db_user/" .env
        sed -i "s/your_cockroach_db_password/$cockroach_db_password/" .env
        sed -i "s/your_cockroach_db_options/$cockroach_db_options/" .env
        sed -i "s/your_nadooit_api_key/$nado" .env
        sed -i "s/your_nadooit_api_key/$nadooit_api_key/" .env
        sed -i "s/your_nadooit_user_code/$nadooit_user_code/" .env
        echo ".env file has been updated with the values you entered."
    else
        echo "You chose not to update the .env file. Don't forget to do this before you run your application."
    fi
    echo "nadooit_management service has been installed."
fi
echo "Setup completed."
