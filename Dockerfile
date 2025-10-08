FROM python:3.12-slim

# Aggiornamento e installazione pacchetti di sistema necessari
RUN apt-get update && apt-get install -y \
    openssh-server \
    build-essential \
    vim \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Creazione cartella per SSH
RUN mkdir /var/run/sshd
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh

RUN echo "$PUBLIC_KEY" > /root/.ssh/authorized_keys \
    && chmod 600 /root/.ssh/authorized_keys \
    && chown root:root /root/.ssh/authorized_keys

# Permetti login root via SSH
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Installazione librerie Python
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir numpy pandas scipy scikit-learn matplotlib seaborn jupyter

# Espone porta SSH
EXPOSE 2222

CMD ["/usr/sbin/sshd", "-D"]
