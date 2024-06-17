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
