# Auto Ubuntu VPS Server Setup Script

This script is a tool designed to simplify the process of setting up your Ubuntu VPS server. It manages the installation of essential packages, Docker, Docker Compose, and, if you want, ERPNext.

This guide aims to assist absolute beginners in using the script.

## Preparations

Before you can use the setup script, you need to perform some initial configurations on your Ubuntu VPS server:

1. **Create a new user account with sudo privileges**:

   On your server, create a new user account and grant it sudo privileges. This will be the user account you'll use to run the script. Here is an example of creating a new user named `your_username` and adding it to the sudo group:

   ```bash
   adduser your_username
   usermod -aG sudo your_username
   ```

   Make sure to replace `your_username` with the username you want.

2. **Install Git on your server**:

   The setup script requires Git to clone the necessary repositories. Install Git by running:

   ```bash
   sudo apt update
   sudo apt install git
   ```

## How to use the script

After preparing your server, you can use the setup script as follows:

1. **Log in to your server using SSH**:

    To connect to your server, you will need a client application that supports the Secure Shell (SSH) protocol. For Windows users, PowerShell provides an easy way to use SSH. For macOS and Linux, the Terminal application has built-in SSH support.

    - **On Windows**: Press the Windows key, type 'PowerShell', and press 'Enter'. This will launch Windows PowerShell.

        You can generate an SSH key pair directly in PowerShell. Just paste the following command and press 'Enter':

        ```bash
        ssh-keygen
        ```

        It will ask for a location to save the keys and a passphrase for added security. You can press 'Enter' to accept the default location and skip the passphrase, but using a passphrase is recommended for added security.

        After generating the keys, copy your public key to your server with the command:

        ```bash
        type $env:USERPROFILE\.ssh\id_rsa.pub | ssh your_username@your_server_ip "cat >> .ssh/authorized_keys"
        ```

        Replace `your_username` and `your_server_ip` with your server's username and IP address respectively. The public key is now added to the list of authorized keys on your server. After this, you can log in to your server without a password.

        To login to your server, use the command:

        ```bash
        ssh your_username@your_server_ip
        ```

    - **On macOS and Linux**: Open Terminal and type the following command, then press 'Enter'. Replace `your_username` with your server's username and `your_server_ip` with the IP address of your server.

        ```bash
        ssh your_username@your_server_ip
        ```

        If you want to set up SSH key-based authentication, follow these commands:

        ```bash
        ssh-keygen
        ssh-copy-id your_username@your_server_ip
        ```

    The rest of the steps remain the same as mentioned in the previous guide.

2. **Clone the repository containing the script**:

   After logging in, clone the repository with the setup script:

   ```bash
   git clone git@github.com:NADOOIT/Auto-Ubuntu-VPS-Server-Setup-Script.git
   cd Auto-Ubuntu-VPS-Server-Setup-Script
   ```

3. **Make the script executable**:

   The next step is to give the file `setup.sh`, the permission to execute as a program. If you skip this step, the system will refuse to run the script and will give you a 'Permission Denied' error.

   ```bash
   chmod +x setup.sh
   ```

4. **Run the setup script**:

   Now you can run the script. This will install Docker, Docker Compose, and, if you choose, ERPNext.

   ```bash
   sudo ./setup.sh
   ```

   You will be asked if you want to install ERPNext. If you want to install it, type 'yes'; otherwise, type 'no'.

## Accessing Installed Applications

After the script is done:

- **Portainer**: You can access Portainer, which allows you to manage Docker containers, at `http://your-server-ip:9000` in a web browser.
- **ERPNext**: If you chose to install ERPNext, it's available at `http://your-server-ip` once the Docker containers are operational. If you can't access ERPNext, check whether the Docker containers are running properly.
