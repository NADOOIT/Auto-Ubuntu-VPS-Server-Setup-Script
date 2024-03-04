# Auto Ubuntu VPS Server Setup Script

This script is a tool designed to simplify the process of setting up your Ubuntu VPS server. It manages the installation of essential packages, Docker, Docker Compose, and, if you want, ERPNext.

This guide aims to assist absolute beginners in using the script.

## Preparations

Before you can use the setup script, you need to perform some initial configurations on your Ubuntu VPS server:

1. **Log in to your server using SSH**:

    To connect to your server, you will need a client application that supports the Secure Shell (SSH) protocol. For Windows users, PowerShell provides an easy way to use SSH. For macOS and Linux, the Terminal application has built-in SSH support.

    - **On Windows**: Press the Windows key, type 'PowerShell', and press 'Enter'. This will launch Windows PowerShell. Use the following command to connect to your server:

        ```bash
        ssh root@your_server_ip
        ```

        Replace `your_server_ip` with the IP address of your server. The initial user is usually 'root', but if you are using a GDPR-compliant provider like IONOS, you can find the initial user and password in your VPS overview.

        If you encounter an error message saying `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!`, this is due to the SSH client recognizing that the server's fingerprint doesn't match the one it has recorded in the `known_hosts` file. This typically happens when you've reinstalled or reset your server. To resolve this, remove the offending key with this command:

        ```bash
        ssh-keygen -R "your_server_ip"
        ```

        After running this command, you should be able to connect to your server again.

    - **On macOS and Linux**: Open Terminal and type the following command, then press 'Enter'. Replace `root` with your server's username and `your_server_ip` with the IP address of your server.

        ```bash
        ssh root@your_server_ip
        ```

        If you encounter an error similar to `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!`, you can use the following command to remove the offending key:

        ```bash
        ssh-keygen -R "your_server_ip"
        ```

2. **Create a new user account with sudo privileges**:

   On your server, create a new user account and grant it sudo privileges. This will be the user account you'll use to run the script. Here is an example of creating a new user named `your_username` and adding it to the sudo group:

   ```bash
    adduser your_username
    usermod -aG sudo your_username
    usermod -aG docker your_username
   ```

   Make sure to replace `your_username` with the username you want.

3. **Install Git on your server**:

   The setup script requires Git to clone the necessary repositories. Install Git by running:

   ```bash
   sudo apt update
   sudo apt upgrade
   sudo apt install git
   reboot
   ```

## How to use the script

After preparing your server, you can use the setup script as follows:

1. **Log in to your server using SSH**:

    To connect to your server, you will need a client application that supports the Secure Shell (SSH) protocol. For Windows users, PowerShell provides an easy way to use SSH. For macOS and Linux, the Terminal application has built-in SSH support.

    - **On Windows**: Press the Windows key, type 'PowerShell', and press 'Enter'. This will launch Windows PowerShell.

        You can generate an SSH key pair directly in PowerShell. Just paste the following command and press 'Enter':

        ⚠️ WARNING: If an SSH key already exists at the default location, DO NOT overwrite it. Doing so could invalidate your key on any systems where it's currently in use and potentially lock you out. So if asked to overwirte the key, type 'n' and press 'Enter'.
        Just skip to the next step if you already have an SSH key pair.

        ```bash
        ssh-keygen
        ```

        It will ask for a location to save the keys and a passphrase for added security. You can press 'Enter' to accept the default location and skip the passphrase, but using a passphrase is recommended for added security.

        Next, log in to your server and create the `.ssh` directory and the `authorized_keys` file if they don't exist. Use this command:

        ```bash
        ssh your_username@your_server_ip "mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys"
        ```

        After that, you can copy your public key to your server with the command:

        ```bash
        type $env:USERPROFILE\.ssh\id_rsa.pub | ssh your_username@your_server_ip "cat >> .ssh/authorized_keys"
        ```

        Replace `your_username` and `your_server_ip` with your server's username and IP address respectively. The public key is now added to the list of authorized keys on your server. After this, you can log in to your server without a password.

        To login to your server, use the command:

        ```bash
        ssh your_username@your_server_ip
        ```

    - **On macOS and Linux**: Open Terminal and type the following command, then press 'Enter'. Replace `your_username` with your server's username and `your_server_ip` with the IP address of your server.

        ⚠️ WARNING: If an SSH key already exists at the default location, DO NOT overwrite it. Doing so could invalidate your key on any systems where it's currently in use and potentially lock you out. So if asked to overwirte the key, type 'n' and press 'Enter'.
        Just skip to the next step if you already have an SSH key pair.

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
        git clone https://github.com/NADOOIT/Auto-Ubuntu-VPS-Server-Setup-Script.git
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

## Installing RustDesk Server OSS with Docker

This script also supports setting up RustDesk Server OSS, a comprehensive remote desktop software, using Docker. Follow these steps to install RustDesk Server on your Ubuntu VPS.

### RustDesk Server OSS Requirements

Ensure Docker is installed on your server. RustDesk Server requires specific ports to be open:

- **TCP Ports**: 21115, 21116, 21117, 21118, 21119
- **UDP Port**: 21116

These ports facilitate various RustDesk services, including NAT testing, ID registration, heartbeat service, TCP hole punching, connection service, and relay services. Ports 21118 and 21119 are for web client support and can be disabled if not needed.

### Installation Steps

1. **Open Required Ports**:

   Open the required ports in your server's firewall to enable RustDesk functionality and external connectivity.

2. **Deploy RustDesk using Docker Compose**:

   Navigate to the directory containing the `docker-compose-rustdesk.yml` file. Run the Docker Compose file to start RustDesk Server OSS components in detached mode:

   ```bash
   sudo docker-compose -f docker-compose-rustdesk.yml up -d
