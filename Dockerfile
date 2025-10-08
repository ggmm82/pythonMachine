FROM python:3.12-slim

# Aggiornamento e installazione pacchetti di sistema necessari
RUN apt-get update && apt-get install -y \
    openssh-server \
    build-essential \
    vim \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Creazione cartelle necessarie
RUN mkdir -p /var/run/sshd /root/.ssh && chmod 700 /root/.ssh

# Permetti login root via SSH
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Installazione librerie Python
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir numpy pandas scipy scikit-learn matplotlib seaborn jupyter

# Espone porta SSH
EXPOSE 22

# Avvio SSH e setup chiave pubblica letta da variabile d'ambiente
#CMD sh -c 'echo "$PUBLIC_KEY" > /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys && /usr/sbin/sshd -D'

# Avvio: crea utente se fornito, imposta password, autorizza chiave pubblica, configura sshd e avvia
CMD sh -c '\
SSH_PORT="${SSH_PORT:=2222}" && \
echo "Starting container - SSH internal port: $SSH_PORT" && \
sed -i "s/^#Port .*/Port $SSH_PORT/" /etc/ssh/sshd_config || echo "Port $SSH_PORT" >> /etc/ssh/sshd_config && \
sed -i "s/^#PasswordAuthentication .*/PasswordAuthentication yes/" /etc/ssh/sshd_config || true && \
sed -i "s/^#PubkeyAuthentication .*/PubkeyAuthentication yes/" /etc/ssh/sshd_config || true && \
sed -i "s/^#PermitRootLogin .*/PermitRootLogin prohibit-password/" /etc/ssh/sshd_config || true && \
\
if [ -n "$USER_NAME" ]; then \
  if ! id -u "$USER_NAME" >/dev/null 2>&1; then useradd -m -s /bin/bash "$USER_NAME"; fi && \
  if [ -n "$USER_PASSWORD" ]; then echo "$USER_NAME:$USER_PASSWORD" | chpasswd; fi && \
  usermod -aG sudo "$USER_NAME" && \
  echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers; \
fi && \
\
TARGET_USER="${USER_NAME:-root}" && \
if [ -n "$PUBLIC_KEY" ]; then \
  echo "$PUBLIC_KEY" > /root/.ssh/authorized_keys && \
  chmod 600 /root/.ssh/authorized_keys; \
fi && \
\
/usr/sbin/sshd -D -e \
'
