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
  : "${SSH_PORT:=2222}"; \
  # Assicura valori sensati
  echo "Starting container - SSH internal port: $SSH_PORT"; \
  # Appendi/configura le opzioni SSH (override sicuro)
  grep -q "^Port " /etc/ssh/sshd_config && sed -i "s/^Port .*/Port $SSH_PORT/" /etc/ssh/sshd_config || echo "Port $SSH_PORT" >> /etc/ssh/sshd_config; \
  grep -q "^PasswordAuthentication " /etc/ssh/sshd_config && sed -i "s/^PasswordAuthentication .*/PasswordAuthentication yes/" /etc/ssh/sshd_config || echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config; \
  grep -q "^PubkeyAuthentication " /etc/ssh/sshd_config && sed -i "s/^PubkeyAuthentication .*/PubkeyAuthentication yes/" /etc/ssh/sshd_config || echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config; \
  # Non permettere login root via password per sicurezza (ma puoi cambiare)
  grep -q "^PermitRootLogin " /etc/ssh/sshd_config && sed -i "s/^PermitRootLogin .*/PermitRootLogin prohibit-password/" /etc/ssh/sshd_config || echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config; \
  # Se fornisci USER_NAME, crea l'utente e imposta password se fornita
  if [ -n \"$USER_NAME\" ]; then \
    if ! id -u \"$USER_NAME\" >/dev/null 2>&1; then \
      useradd -m -s /bin/bash \"$USER_NAME\"; \
      echo \"Created user: $USER_NAME\"; \
    fi; \
    if [ -n \"$USER_PASSWORD\" ]; then \
      echo \"$USER_NAME:$USER_PASSWORD\" | chpasswd; \
      echo \"Password set for $USER_NAME\"; \
    fi; \
    # permette sudo all'utente (opzionale)
    usermod -aG sudo \"$USER_NAME\"; \
  fi; \
  # Se PUBLIC_KEY è fornita, aggiungila a ~/.ssh/authorized_keys dell'utente (o di root se USER_NAME non fornito)
  if [ -n \"$PUBLIC_KEY\" ]; then \
    if [ -n \"$USER_NAME\" ]; then \
      mkdir -p /home/$USER_NAME/.ssh; \
      echo \"$PUBLIC_KEY\" > /home/$USER_NAME/.ssh/authorized_keys; \
      chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.ssh; \
      chmod 700 /home/$USER_NAME/.ssh; chmod 600 /home/$USER_NAME/.ssh/authorized_keys; \
      echo \"Added PUBLIC_KEY for $USER_NAME\"; \
    else \
      mkdir -p /root/.ssh; \
      echo \"$PUBLIC_KEY\" > /root/.ssh/authorized_keys; \
      chmod 700 /root/.ssh; chmod 600 /root/.ssh/authorized_keys; \
      echo \"Added PUBLIC_KEY for root\"; \
    fi; \
  fi; \
  # Avvia sshd in foreground
  /usr/sbin/sshd -D -e \
'

