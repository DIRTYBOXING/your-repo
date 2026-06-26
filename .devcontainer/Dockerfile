FROM mcr.microsoft.com/vscode/devcontainers/base:ubuntu-22.04

# Install common tools
RUN apt-get update && apt-get install -y \
    curl git python3 python3-pip unzip build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Dart SDK
RUN apt-get update && apt-get install -y apt-transport-https gnupg \
    && curl -sSL https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'wget -qO- https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list' \
    && apt-get update && apt-get install -y dart

# Make dart available on PATH for non-login shells
ENV PATH="/usr/lib/dart/bin:${PATH}"

# Install pip packages used by KPI scripts
RUN pip3 install numpy

# Create a non-root user (vscode is default in base image)
USER vscode
WORKDIR /workspace
