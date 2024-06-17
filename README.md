### SecuredEnvSync README

# SecuredEnvSync

**SecuredEnvSync** is a cross-platform tool for securely managing and synchronizing encrypted environment variables. This project leverages ECC encryption to protect sensitive information and uses rclone to sync the encrypted data with Google Drive.

## Features

- **Cross-Platform**: Works on macOS, Linux, and Windows.
- **ECC Encryption**: Uses Elliptic Curve Cryptography (ECC) for secure encryption and decryption of environment variable values.
- **Google Drive Sync**: Utilizes rclone to sync the encrypted environment file with Google Drive.
- **Custom Scripts**: Provides custom scripts for encryption, decryption, and synchronization.

## Requirements

- **OpenSSL**: For generating ECC keys and performing encryption/decryption.
- **rclone**: For syncing the environment file with Google Drive.
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

Download and install OpenSSL from [OpenSSL for Windows](https://slproweb.com/products/Win32OpenSSL.html).

### rclone

#### macOS and Linux

```sh
# Install rclone
curl https://rclone.org/install.sh | sudo bash
```

#### Windows

Download and install rclone from [rclone downloads](https://rclone.org/downloads/).

## Setup

1. **Generate ECC Key Pair**

```sh
# Generate the ECC private key
openssl ecparam -genkey -name prime256v1 -noout -out ecc_private_key.pem

# Generate the ECC public key
openssl ec -in ecc_private_key.pem -pubout -out ecc_public_key.pem
```

2. **Move the Keys to Appropriate Locations**

#### macOS and Linux

```sh
# Move the keys to the .ssh directory
mv ecc_private_key.pem ~/.ssh/
mv ecc_public_key.pem ~/.ssh/
```

#### Windows

```powershell
# Move the keys to the .ssh directory
Move-Item ecc_private_key.pem $env:USERPROFILE\.ssh\
Move-Item ecc_public_key.pem $env:USERPROFILE\.ssh\
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

### macOS and Linux Script

```bash
#!/bin/bash

# Paths
SEC_ENV_PATH="$HOME/.config/sec_env/sec_env"
PRIVATE_KEY_PATH="$HOME/.ssh/ecc_private_key.pem"
PUBLIC_KEY_PATH="$HOME/.ssh/ecc_public_key.pem"
RCLONE_REMOTE="remote:backup"

# Encrypt a value using ECC public key
encrypt_value() {
    local value=$1
    echo -n "$value" | openssl pkeyutl -encrypt -inkey "$PUBLIC_KEY_PATH" -pubin -pkeyopt ec_scheme:ecdh | base64
}

# Decrypt a value using ECC private key
decrypt_value() {
    local encrypted_value=$1
    echo "$encrypted_value" | base64 --decode | openssl pkeyutl -decrypt -inkey "$PRIVATE_KEY_PATH"
}

# Add a key-value pair to sec_env
add_key_value() {
    local key=$1
    local value=$2
    local encrypted_value=$(encrypt_value "$value")
    echo "$key=$encrypted_value" >> "$SEC_ENV_PATH"
}

# Retrieve a value from sec_env
get_value() {
    local key=$1
    local encrypted_value=$(grep "^$key=" "$SEC_ENV_PATH" | cut -d '=' -f 2)
    decrypt_value "$encrypted_value"
}

# Sync sec_env from Google Drive
sync_sec_env_down() {
    if rclone copy "$RCLONE_REMOTE/sec_env" "$(dirname "$SEC_ENV_PATH")"; then
        echo "sec_env downloaded successfully."
    else
        echo "Failed to download sec_env." >&2
        exit 1
    fi
}

# Async sync sec_env to Google Drive
sync_sec_env_up() {
    if rclone copy "$SEC_ENV_PATH" "$RCLONE_REMOTE"; then
        echo "sec_env uploaded successfully."
    else
        echo "Failed to upload sec_env." >&2
        exit 1
    fi &
}

# Example usage
sync_sec_env_down
add_key_value "API_KEY" "my-secret-api-key"
sync_sec_env_up

# Wait for background tasks to complete before exiting
wait

value=$(get_value "API_KEY")
echo "Decrypted value: $value"
```

### Windows PowerShell Script

```powershell
# Paths
$secEnvPath = "C:\Users\$env:USERNAME\AppData\Local\sec_env\sec_env"
$privateKeyPath = "C:\Users\$env:USERNAME\.ssh\ecc_private_key.pem"
$publicKeyPath = "C:\Users\$env:USERNAME\.ssh\ecc_public_key.pem"
$rcloneRemote = "remote:backup"

# Encrypt a value using ECC public key
function Encrypt-Value {
    param (
        [string]$value
    )
    $encryptedValue = echo -n "$value" | openssl pkeyutl -encrypt -inkey $publicKeyPath -pubin -pkeyopt ec_scheme:ecdh | base64
    return $encryptedValue
}

# Decrypt a value using ECC private key
function Decrypt-Value {
    param (
        [string]$encryptedValue
    )
    $decryptedValue = echo "$encryptedValue" | base64 --decode | openssl pkeyutl -decrypt -inkey $privateKeyPath
    return $decryptedValue
}

# Add a key-value pair to sec_env
function Add-KeyValue {
    param (
        [string]$key,
        [string]$value
    )
    $encryptedValue = Encrypt-Value -value $value
    "$key=$encryptedValue" | Out-File -FilePath $secEnvPath -Append
}

# Retrieve a value from sec_env
function Get-Value {
    param (
        [string]$key
    )
    $line = Select-String -Path $secEnvPath -Pattern "^$key=" -SimpleMatch
    if ($line) {
        $encryptedValue = $line -replace "^$key=", ""
        $decryptedValue = Decrypt-Value -encryptedValue $encryptedValue
        return $decryptedValue
    } else {
        Write-Error "Key not found"
    }
}

# Sync sec_env from Google Drive
function Sync-SecEnvDown {
    $result = rclone copy $rcloneRemote\sec_env (Split-Path -Parent $secEnvPath)
    if ($LASTEXITCODE -eq 0) {
        Write-Output "sec_env downloaded successfully."
    } else {
        Write-Error "Failed to download sec_env."
        exit 1
    }
}

# Async sync sec_env to Google Drive
function Sync-SecEnvUp {
    Start-Job -ScriptBlock {
        rclone copy $using:secEnvPath $using:rcloneRemote
        if ($LASTEXITCODE -eq 0) {
            Write-Output "sec_env uploaded successfully."
        } else {
            Write-Error "Failed to upload sec_env."
            exit 1
        }
    } | Wait-Job
}

# Example usage
Sync-SecEnvDown
Add-KeyValue -key "API_KEY" -value "my-secret-api-key"
Sync-SecEnvUp

$value = Get-Value -key "API_KEY"
Write-Output "Decrypted value: $value"
```

## Contributing

Contributions are welcome! Please fork this repository and submit a pull request for any changes or improvements.

## License

This project is licensed under the MIT License. See the LICENSE file for details.