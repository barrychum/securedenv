# SecuredEnvSync

**SecuredEnvSync** is a cross-platform tool for securely managing and synchronizing encrypted environment variables. This project leverages RSA encryption to protect sensitive information and uses rclone to sync the encrypted data with any rclone supported targets.

## Features

- **Cross-Platform**: Works on macOS, Linux, and Windows.
- **RSA Encryption**: Uses RSA encryption for secure encryption and decryption of environment variable values.
- **Flexible Sync**: Utilizes rclone to sync the encrypted environment file with various cloud storage providers (Google Drive, Dropbox, OneDrive, etc.).
- **Custom Scripts**: Provides custom scripts for encryption, decryption, and synchronization.
- **Security**: Ensures sensitive data is encrypted and securely stored.

## Requirements

- **OpenSSL**: For generating RSA keys and performing encryption/decryption.
- **rclone**: For syncing the environment file with cloud storage providers.
- **Bash**: For macOS and Linux scripts.
- **PowerShell**: For Windows scripts.

## Installation

### OpenSSL

#### macOS and Linux

```sh
# Install OpenSSL if not already installed
sudo apt-get install openssl  # Debian/Ubuntu
sudo yum install openssl      # CentOS/RHEL
brew install openssl          # macOS (with Homebrew)
```

#### Windows

You can install OpenSSL using either `winget` or `Chocolatey`.

**Using winget**:
```powershell
# Search for OpenSSL
winget search openssl

# Install OpenSSL
winget install ShiningLight.OpenSSL
```

**Using Chocolatey**:
```powershell
# Install OpenSSL
choco install openssl

# Confirm installation
choco list --local-only openssl
```

### rclone

#### macOS and Linux

```sh
# Install rclone
curl https://rclone.org/install.sh | sudo bash
```

#### Windows

Download and install rclone from [rclone downloads](https://rclone.org/downloads/).

## Setup

1. **Generate RSA Key Pair**

```sh
# Generate the RSA private key
openssl genpkey -algorithm RSA -out rsa_private_key.pem -pkeyopt rsa_keygen_bits:2048

# Generate the RSA public key
openssl rsa -pubout -in rsa_private_key.pem -out rsa_public

_key.pem
```

2. **Move the Keys to Appropriate Locations**

#### macOS and Linux

```sh
# Move the keys to the .ssh directory
mv rsa_private_key.pem ~/.ssh/
mv rsa_public_key.pem ~/.ssh/
```

#### Windows

```powershell
# Move the keys to the .ssh directory
Move-Item rsa_private_key.pem $env:USERPROFILE\.ssh\
Move-Item rsa_public_key.pem $env:USERPROFILE\.ssh\
```

3. **Create the sec_env File**

Create a directory for the `sec_env` file and place it there.

#### macOS and Linux

```sh
mkdir -p ~/.config/sec_env
touch ~/.config/sec_env/sec_env
```

#### Windows

```powershell
New-Item -Path $env:USERPROFILE\AppData\Local\sec_env -ItemType Directory
New-Item -Path $env:USERPROFILE\AppData\Local\sec_env\sec_env -ItemType File
```

## Usage

Refer to the provided scripts for usage examples. These scripts handle encryption, decryption, and synchronization of environment variables.

- **macOS and Linux Script**: See [bash_script.sh](scripts/bash_script.sh)
- **Windows PowerShell Script**: See [powershell_script.ps1](scripts/powershell_script.ps1)

## License

This project is licensed under the MIT License. See the LICENSE file for details.