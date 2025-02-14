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

# Download Node Exporter
echo "Downloading Node Exporter..."
wget https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz

# Extract Node Exporter
echo "Extracting Node Exporter..."
tar xvf node_exporter-1.3.1.linux-amd64.tar.gz

# Change to the extracted directory
cd node_exporter-1.3.1.linux-amd64

# Copy the node_exporter binary to /usr/local/bin
echo "Copying node_exporter to /usr/local/bin..."
sudo cp node_exporter /usr/local/bin

# Exit the current directory
cd ..

# Clean up the extracted files and tarball
echo "Cleaning up unnecessary files..."
rm -rf ./node_exporter-1.3.1.linux-amd64
rm -f node_exporter-1.3.1.linux-amd64.tar.gz

# Create node_exporter user
echo "Creating node_exporter user..."
sudo useradd --no-create-home --shell /bin/false node_exporter

# Set permissions for node_exporter binary
echo "Setting ownership for node_exporter binary..."
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Create Node Exporter Systemd Service file
echo "Creating Node Exporter systemd service..."
cat <<EOF | sudo tee /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start Node Exporter service
echo "Reloading systemd and starting Node Exporter service..."
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

echo "Node Exporter installation and service setup completed!"
