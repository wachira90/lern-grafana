#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

VERSION="1.10.1"

# Detect system architecture
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    ARCH="amd64"
elif [ "$ARCH" = "aarch64" ]; then
    ARCH="arm64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

echo "=================================================="
echo " Installing Node Exporter v$VERSION for $ARCH"
echo "=================================================="

# 1. Create a dedicated system user for Node Exporter (if it doesn't exist)
if ! id -u node_exporter > /dev/null 2>&1; then
    echo "Creating 'node_exporter' system user..."
    sudo useradd -rs /bin/false node_exporter
else
    echo "User 'node_exporter' already exists. Skipping..."
fi

# 2. Download the Node Exporter tarball
DOWNLOAD_URL="https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/node_exporter-${VERSION}.linux-${ARCH}.tar.gz"
echo "Downloading from $DOWNLOAD_URL..."
curl -sSL -O "$DOWNLOAD_URL"

# 3. Extract and install the binary
echo "Extracting the binary..."
tar -xzf "node_exporter-${VERSION}.linux-${ARCH}.tar.gz"

echo "Moving binary to /usr/local/bin/..."
sudo mv "node_exporter-${VERSION}.linux-${ARCH}/node_exporter" /usr/local/bin/

echo "Setting permissions..."
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

# 4. Clean up downloaded files
echo "Cleaning up temporary files..."
rm -rf "node_exporter-${VERSION}.linux-${ARCH}" "node_exporter-${VERSION}.linux-${ARCH}.tar.gz"

# 5. Create a systemd service file
echo "Creating systemd service at /etc/systemd/system/node_exporter.service..."
cat <<EOF | sudo tee /etc/systemd/system/node_exporter.service > /dev/null
[Unit]
Description=Prometheus Node Exporter
Documentation=https://github.com/prometheus/node_exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# 6. Reload systemd and start the service
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Enabling Node Exporter to start on boot..."
sudo systemctl enable node_exporter

echo "Starting Node Exporter service..."
sudo systemctl start node_exporter

echo "=================================================="
echo " Installation Complete!"
echo " Node Exporter should now be running on port 9100."
echo "=================================================="

# Show the current status of the service
sudo systemctl status node_exporter --no-pager | head -n 10
