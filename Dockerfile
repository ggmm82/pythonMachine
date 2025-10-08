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
CMD sh -c 'echo "$PUBLIC_KEY" > /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys && /usr/sbin/sshd -D'

