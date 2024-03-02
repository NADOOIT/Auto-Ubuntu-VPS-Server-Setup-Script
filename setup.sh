#!/bin/bash

CURRENT_USER=$(logname)
USER_HOME=$(eval echo ~$CURRENT_USER)

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

    # Generate an SSH key pair if it doesn't already exist
    ssh_key_path="$USER_HOME/.ssh/id_ed25519"
    if [ ! -f "$ssh_key_path" ]; then
        echo "Generating a new SSH key pair..."
        read -p "Enter your email address: " email_address
        ssh-keygen -t ed25519 -C "$email_address" -f "$ssh_key_path"
        echo "SSH key pair generated."
    else
        echo "Existing SSH key pair found."
    fi

    # Display the public key
    echo "Public key:"
    cat "$ssh_key_path.pub"
    echo "Add this public key to your GitHub account before continuing. Go to your GitHub account settings, click on SSH and GPG keys, and click on the New SSH key button. Paste the copied public key into the Key field, give it a meaningful title, and click on Add SSH key."

    # Prompt user to continue after adding the SSH key
    read -p "Press enter to continue once you've added the SSH key to your GitHub account."

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
echo "Setup completed."
