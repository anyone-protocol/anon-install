FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    wget \
    debconf \
    net-tools \
    nyx \
    nano \
    ca-certificates \
    iproute2 \
    iptables \
    curl \
    tcpdump \
    iputils-ping &&\
    rm -rf /var/lib/apt/lists/*
    
RUN echo "anon anon/terms boolean true" | debconf-set-selections

RUN wget -qO- https://deb.en.anyone.tech/anon.asc | tee /etc/apt/trusted.gpg.d/anon.asc && \
    . /etc/os-release && \
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/anon.asc] https://deb.en.anyone.tech anon-live-$VERSION_CODENAME main" | tee /etc/apt/sources.list.d/anon.list

RUN apt-get update && \
    apt-get install -y anon && \
    apt-get autoremove && \
    apt-get clean

VOLUME ["/var/lib/anon", "/var/log/anon"]

CMD ["anon", "-f", "/etc/anon/anonrc"]
