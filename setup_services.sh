#!/bin/bash

echo "Starting configuration..."

# --- Ollama Setup ---
if systemctl list-unit-files | grep -q ollama.service; then
    echo "✅ Found Ollama service. Enabling and starting..."
    systemctl enable --now ollama
else
    echo "⚠️ Ollama service not found. Is it installed?"
fi

# --- Open WebUI Setup ---
SERVICE_FILE="/etc/systemd/system/open-webui.service"

if command -v docker &> /dev/null && docker ps -a --format '{{.Names}}' | grep -q "^open-webui$"; then
    echo "✅ Found Open WebUI Docker container."
    
    cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Open WebUI Service (Docker)
After=docker.service
Requires=docker.service

[Service]
Restart=always
ExecStart=/usr/bin/docker start -a open-webui
ExecStop=/usr/bin/docker stop open-webui

[Install]
WantedBy=multi-user.target
EOF

    echo "Created $SERVICE_FILE"
    systemctl daemon-reload
    systemctl enable --now open-webui
    echo "✅ Open WebUI (Docker) enabled and started."

elif command -v open-webui &> /dev/null; then
    echo "✅ Found Open WebUI Python executable."
    
    # Get the user who invoked sudo
    REAL_USER=${SUDO_USER:-$(whoami)}
    USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    EXEC_PATH=$(command -v open-webui)

    cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Open WebUI Service (Python)
After=network.target

[Service]
User=$REAL_USER
WorkingDirectory=$USER_HOME
ExecStart=$EXEC_PATH serve
Restart=always
Environment=HOME=$USER_HOME

[Install]
WantedBy=multi-user.target
EOF

    echo "Created $SERVICE_FILE"
    systemctl daemon-reload
    systemctl enable --now open-webui
    echo "✅ Open WebUI (Python) enabled and started."

else
    echo "❌ Open WebUI not found. Please ensure:"
    echo "   1. If using Docker, the container is named 'open-webui'."
    echo "   2. If using Python, 'open-webui' is in the PATH."
fi

echo "Configuration complete."
