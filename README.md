# Auto Ubuntu VPS Server Setup Script

This script is a tool designed to simplify the process of setting up your Ubuntu VPS server. It manages the installation of essential packages, Docker, Docker Compose, and, if you want, ERPNext.

This guide aims to assist absolute beginners in using the script.

## How to use the script

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

2. **Create the script file**:

    After logging in, you're now at the home directory of your server. Create a new file named `setup.sh` using `nano`, a command-line text editor. If you prefer, you could use other text editors like `vi` or `emacs`.

    ```bash
    nano setup.sh
    ```

3. **Copy the script content**:

    Now, copy the content of the setup script provided. Go back to your terminal window, right-click to paste the script into the `setup.sh` file. Save and close the file by pressing `Ctrl+X`, then `Y`, then `Enter`. If you see any errors at this stage, they might be due to a problem with the script content.

4. **Make the script executable**:

    The next step is to give the file you created, `setup.sh`, the permission to execute as a program. If you skip this step, the system will refuse to run the script and will give you a 'Permission Denied' error.

    ```bash
    chmod +x setup.sh
    ```

5. **Run the setup script**:

    Now you can run the script. This will install the necessary packages, Docker, Docker Compose and, if you choose, ERPNext. 

    ```bash
    sudo ./setup.sh
    ```

    The script will ask for a username to create a new user account. You will also be asked if you want to install ERPNext. If you want to install it, type 'yes'; otherwise, type 'no'.

## Accessing Installed Applications

After the script is done:

- **Portainer**: You can access Portainer, which allows you to manage Docker containers, at `http://your-server-ip:9000` in a web browser.
- **ERPNext**: If you chose to install ERPNext, it's available at `http://your-server-ip` once the Docker containers are operational. If you can't access ERPNext, check whether the Docker containers are running properly.
