FROM ubuntu:latest

ENV PATH="/opt:${PATH}"

RUN apt update \
    && apt upgrade -y \
    && apt install -y --no-install-recommends \
        curl \
        unzip \
        git \
        groff \
        jq \
    && apt install -y python3 python3-pip \
    && apt remove -y g++ x11-common xauth openssh-client manpages manpages-dev make imagemagick g++-7 build-essential binutils-x86-64-linux-gnu binutils --allow-remove-essential \
    && rm -rf /var/lib/apt/lists/* \
    && apt clean && apt auto-remove -y \
    && mkdir -p /root/.aws 

RUN pip3 install awscli \
    && curl https://releases.hashicorp.com/terraform/0.12.8/terraform_0.12.8_linux_amd64.zip --output /opt/terraform.zip \
    && cd /opt \
    && unzip terraform.zip \
    && rm /opt/terraform.zip \

WORKDIR /pro/src