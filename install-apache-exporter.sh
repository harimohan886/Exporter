#!/bin/bash

# Detect OS type
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS=$ID
else
  echo "OS detection failed!"
  exit 1
fi

echo "OS detected: $OS"

# Install dependencies based on OS
if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
  sudo apt update && sudo apt install -y wget curl
elif [ "$OS" == "centos" ] || [ "$OS" == "rhel" ] || [ "$OS" == "fedora" ]; then
  sudo yum -y install wget curl
else
  echo "Unsupported OS!"
  exit 1
fi

# Download Apache Exporter
echo "Downloading Apache Exporter..."
curl -s https://api.github.com/repos/Lusitaniae/apache_exporter/releases/latest | grep browser_download_url | grep linux-amd64 | cut -d '"' -f 4 | wget -qi -

# Extract Apache Exporter
echo "Extracting Apache Exporter..."
tar xvf apache_exporter-*.linux-amd64.tar.gz

# Copy the binary to /usr/local/bin
echo "Copying apache_exporter to /usr/local/bin..."
sudo cp apache_exporter-*.linux-amd64/apache_exporter /usr/local/bin

# Clean up extracted files
echo "Cleaning up unnecessary files..."
rm -rf apache_exporter-*.linux-amd64
rm -f apache_exporter-*.linux-amd64.tar.gz

# Create prometheus user and group
echo "Creating Prometheus user and group..."
sudo groupadd --system prometheus
sudo useradd -s /sbin/nologin --system -g prometheus prometheus

# Create systemd service for Apache Exporter
echo "Creating systemd service for Apache Exporter..."
sudo tee /etc/systemd/system/apache_exporter.service > /dev/null <<EOL
[Unit]
Description=Prometheus Apache Exporter
Documentation=https://github.com/Lusitaniae/apache_exporter
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecStart=/usr/local/bin/apache_exporter --insecure --scrape_uri=http://localhost/server-status/?auto --telemetry.endpoint=/metrics
SyslogIdentifier=apache_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd, enable and start the service
echo "Reloading systemd and starting Apache Exporter service..."
sudo systemctl daemon-reload
sudo systemctl enable apache_exporter
sudo systemctl start apache_exporter

echo "Apache Exporter installation and service setup completed!"
