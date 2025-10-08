#!/bin/sh

SSH_PORT="${SSH_PORT:=2222}"
USER_NAME="${USER_NAME:-}"
USER_PASSWORD="${USER_PASSWORD:-}"
PUBLIC_KEY="${PUBLIC_KEY:-}"

# Configura sshd
sed -i "s/^#Port .*/Port $SSH_PORT/" /etc/ssh/sshd_config || echo "Port $SSH_PORT" >> /etc/ssh/sshd_config
sed -i "s/^#PasswordAuthentication .*/PasswordAuthentication yes/" /etc/ssh/sshd_config || true
sed -i "s/^#PubkeyAuthentication .*/PubkeyAuthentication yes/" /etc/ssh/sshd_config || true
sed -i "s/^#PermitRootLogin .*/PermitRootLogin prohibit-password/" /etc/ssh/sshd_config || true

# Crea utente se fornito
if [ -n "$USER_NAME" ]; then
    if ! id -u "$USER_NAME" >/dev/null 2>&1; then
        useradd -m -s /bin/bash "$USER_NAME"
        echo "Created user: $USER_NAME"
    fi
    if [ -n "$USER_PASSWORD" ]; then
        echo "$USER_NAME:$USER_PASSWORD" | chpasswd
        echo "Password set for $USER_NAME"
    fi
    usermod -aG sudo "$USER_NAME"
    echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
fi

# Configura chiave pubblica
TARGET_USER="${USER_NAME:-root}"
if [ -n "$PUBLIC_KEY" ]; then
    mkdir -p /home/$TARGET_USER/.ssh
    echo "$PUBLIC_KEY" > /home/$TARGET_USER/.ssh/authorized_keys
    chown -R $TARGET_USER:$TARGET_USER /home/$TARGET_USER/.ssh
    chmod 700 /home/$TARGET_USER/.ssh
    chmod 600 /home/$TARGET_USER/.ssh/authorized_keys
    echo "Added PUBLIC_KEY for $TARGET_USER"
fi

# Avvia sshd
/usr/sbin/sshd -D -e
