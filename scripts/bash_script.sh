#!/bin/bash

# Paths
CONFIG_DIR="$HOME/.config/sec_env"
SEC_ENV_PATH="$CONFIG_DIR/sec_env"
LOG_PATH="$CONFIG_DIR/sync.log"
PRIVATE_KEY_PATH="$HOME/.ssh/rsa_private_key.pem"
PUBLIC_KEY_PATH="$HOME/.ssh/rsa_public_key.pem"
RCLONE_REMOTE="remote:backup"

# Encrypt a value using RSA public key
encrypt_value() {
    local value=$1
    echo -n "$value" | openssl pkeyutl -encrypt -pubin -inkey "$PUBLIC_KEY_PATH" | base64
}

# Decrypt a value using RSA private key
decrypt_value() {
    local encrypted_value=$1
    echo "$encrypted_value" | base64 --decode | openssl pkeyutl -decrypt -inkey "$PRIVATE_KEY_PATH"
}

# Add or replace a key-value pair in sec_env
add_key_value() {
    local key=$1
    local value=$2
    local encrypted_value=$(encrypt_value "$value")

    # Create sec_env file if it doesn't exist
    touch "$SEC_ENV_PATH"

    # Check if key exists and replace its value
    if grep -q "^$key=" "$SEC_ENV_PATH"; then
        sed -i "" "s|^$key=.*|$key=$encrypted_value|" "$SEC_ENV_PATH"
    else
        echo "$key=$encrypted_value" >> "$SEC_ENV_PATH"
    fi
}

# Retrieve a value from sec_env
get_value() {
    local key=$1
    if grep -q "^$key=" "$SEC_ENV_PATH"; then
        local line=$(awk -F= -v k="$key" '$1 == k {print $0}' "$SEC_ENV_PATH")
        local encrypted_value=${line#*=}
        decrypt_value "$encrypted_value"
    else
        echo -n ""
    fi
}

# Sync sec_env from remote storage silently and log output
sync_sec_env_down() {
    {
        rclone copy "$RCLONE_REMOTE/sec_env" "$(dirname "$SEC_ENV_PATH")" && echo "$(date): sec_env downloaded successfully." || echo "$(date): Failed to download sec_env." >&2
    } &>> "$LOG_PATH"
}

# Async sync sec_env to remote storage silently and log output
sync_sec_env_up() {
    (
        rclone copy "$SEC_ENV_PATH" "$RCLONE_REMOTE" &
        wait $!
        if [[ $? -eq 0 ]]; then
            echo "$(date): sec_env uploaded successfully."
        else
            echo "$(date): Failed to upload sec_env." >&2
        fi
    ) &>> "$LOG_PATH" &
}

# Example usage (commented out for sourcing)
# sync_sec_env_down
# add_key_value "API_KEY" "my-secret-api-key"
# sync_sec_env_up

# Wait for background tasks to complete before exiting (commented out for sourcing)
# wait

# value=$(get_value "API_KEY")
# echo "Decrypted value: $value"
