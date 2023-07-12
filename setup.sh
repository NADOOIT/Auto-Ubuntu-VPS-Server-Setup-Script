# Prompt for username
echo "Please enter the username you want to create:"
read username

# Add new user
sudo adduser $username
sudo usermod -aG sudo $username

# Install required packages
sudo apt-get update
sudo apt-get install -y git curl apt-transport-https ca-certificates gnupg-agent software-properties-common

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Add user to docker group
sudo usermod -aG docker $username

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Pull and Run Portainer
docker volume create portainer_data
docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce

# Prompt for ERPNext installation
echo "Do you want to install ERPNext? (yes/no):"
read install_erpnext

if [[ $install_erpnext == 'yes' ]]; then
  # ERPNext Setup
  git clone https://github.com/frappe/frappe_docker.git ~/frappe_docker
  cd ~/frappe_docker
  cp env-example .env
fi
