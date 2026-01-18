#!/bin/bash

# RPi Agent Server Setup Script
# Based on: rpi_agent_server.md
# Author: Chang Luo

set -e  # Exit immediately if a command exits with a non-zero status.

# Variables
USER_NAME=$(whoami)
USER_HOME=$HOME
PROJ_DIR="$USER_HOME/proj"
JUPYTER_DIR="$PROJ_DIR/jupyter"
AGENT_DIR="$PROJ_DIR/agent-server"

echo "=========================================="
echo "   Starting RPi Agent Server Setup"
echo "=========================================="

# 1. Environment Configuration
echo "[1/7] Updating system packages..."
sudo apt update
sudo apt upgrade -y

echo "[2/7] Installing pipx and uv..."
if ! command -v pipx &> /dev/null; then
    sudo apt install -y pipx
else
    echo "pipx is already installed."
fi

if ! command -v uv &> /dev/null; then
    pipx install uv
    # Add uv to PATH for the current session
    export PATH="$USER_HOME/.local/bin:$PATH"
else
    echo "uv is already installed."
fi
# Ensure PATH is updated in .bashrc if not present
if ! grep -q "$USER_HOME/.local/bin" "$USER_HOME/.bashrc"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$USER_HOME/.bashrc"
fi

# 2. Install JupyterLab
echo "[3/7] Installing JupyterLab..."
mkdir -p "$JUPYTER_DIR"
cd "$JUPYTER_DIR"

if [ ! -d ".venv" ]; then
    uv venv
fi

# Activate venv and install
source .venv/bin/activate
uv pip install jupyterlab -i https://mirrors.cloud.tencent.com/pypi/simple/

# 3. Configure JupyterLab Service
echo "[4/7] Configuring JupyterLab Systemd Service..."
SERVICE_FILE="/etc/systemd/system/jupyterlab.service"

# Create service file content
cat <<EOF > jupyterlab.service.tmp
[Unit]
Description=JupyterLab Service
After=network.target

[Service]
Type=simple
User=$USER_NAME
Group=$USER_NAME
WorkingDirectory=$USER_HOME
ExecStart=/bin/bash -c 'source $JUPYTER_DIR/.venv/bin/activate && \
  $JUPYTER_DIR/.venv/bin/jupyter-lab \
  --ip=0.0.0.0 \
  --port=8888 \
  --no-browser \
  --notebook-dir=$USER_HOME'

[Install]
WantedBy=multi-user.target
EOF

sudo mv jupyterlab.service.tmp "$SERVICE_FILE"
sudo chown root:root "$SERVICE_FILE"

# Reload and start service
sudo systemctl daemon-reload
sudo systemctl enable jupyterlab.service
sudo systemctl start jupyterlab.service

echo "JupyterLab service status:"
sudo systemctl status jupyterlab.service --no-pager | head -n 10

# 4. Install Docker
echo "[5/7] Installing Docker..."
if ! command -v docker &> /dev/null; then
    sudo mkdir -p /etc/apt/keyrings
    if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
    fi
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
    echo "Docker is already installed."
fi

# Configure Docker Mirrors
echo "Configuring Docker mirrors..."
if [ ! -f /etc/docker/daemon.json ]; then
    cat <<EOF > daemon.json.tmp
{
  "registry-mirrors": [
    "https://dc.j8.work",
    "https://docker.m.daocloud.io",
    "https://dockerproxy.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://docker.nju.edu.cn"
  ]
}
EOF
    sudo mkdir -p /etc/docker
    sudo mv daemon.json.tmp /etc/docker/daemon.json
    sudo systemctl restart docker
fi

# Add user to docker group
sudo usermod -aG docker "$USER_NAME"

# 5. Setup Agent Application
echo "[6/7] Setting up Agent Application..."
mkdir -p "$PROJ_DIR"
cd "$PROJ_DIR"

if [ ! -d "agent-server" ]; then
    if [ ! -d "dive-into-langgraph" ]; then
        git clone https://github.com/luochang212/dive-into-langgraph.git
    fi
    # Check if app directory exists before moving
    if [ -d "dive-into-langgraph/app" ]; then
        mv dive-into-langgraph/app agent-server
        rm -rf dive-into-langgraph
    else
        echo "Error: 'app' directory not found in cloned repo."
        exit 1
    fi
else
    echo "agent-server directory already exists."
fi

# Configure .env
if [ -d "agent-server" ]; then
    cd agent-server
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            echo "Creating .env from .env.example..."
            cp .env.example .env
        else
            echo "Warning: .env.example not found."
        fi
    else
        echo ".env already exists."
    fi
    cd ..
fi

echo "=========================================="
echo "   Setup Finished!"
echo "=========================================="
echo ""
echo "JupyterLab Access:"
echo "  http://$(hostname -I | awk '{print $1}'):8888"
echo ""
echo "Agent Application:"
echo "  Location: $AGENT_DIR"
echo "  Action Required:"
echo "    1. Configure API keys: vim $AGENT_DIR/.env"
echo "    2. Start the service:  cd $AGENT_DIR && sudo docker compose up -d"
echo "    3. View logs:          cd $AGENT_DIR && sudo docker compose logs -f"
echo ""
echo "Please restart your session or run 'newgrp docker' to use docker without sudo."
