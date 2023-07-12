# Auto Ubuntu VPS Server Setup Script

This script is designed to automate the setup of your Ubuntu VPS server. It provides a streamlined process for installing necessary packages, Docker, Docker Compose, and gives you the option to install ERPNext, a comprehensive and effective open-source web-based ERP solution. 

This script is ideal for users who want a hassle-free setup process, and is particularly useful for those who wish to use ERPNext alongside other Docker-based applications. It aims to reduce the time taken to manually configure these elements, thereby allowing you to focus on deploying your applications quickly.

## How to use the script

Follow the steps below to download, prepare and run the setup script:

1. **Log in to your server using SSH**:

    ```bash
    ssh your_username@your_server_ip
    ```

2. **Create the script file**:

    ```bash
    nano setup.sh
    ```

3. **Copy the script content**:

    Copy the content of the setup script and paste it into the `setup.sh` file you just created. Save and close the file (In `nano`, you can do this by pressing `Ctrl+X`, then `Y`, then `Enter`).

4. **Make the script executable**:

    ```bash
    chmod +x setup.sh
    ```

5. **Run the setup script**:

    ```bash
    sudo ./setup.sh
    ```

    When the script asks for a username, type the username you want to create. You will also be asked if you want to install ERPNext. Type 'yes' if you want to install it, otherwise type 'no'.

## Accessing Installed Applications

Once the setup is complete, you can access your applications:

- **Portainer**: It can be accessed at `http://your-server-ip:9000`. Use it to manage your Docker containers.
- **ERPNext**: If you chose to install it, it can be accessed at `http://your-server-ip` once the Docker containers are up and running.
