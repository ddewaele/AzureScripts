#!/bin/bash
set -euo pipefail

SERVICE_NAME="azure-demo-server"
INSTALL_DIR="/opt/azure-demo-server"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

if [[ $EUID -ne 0 ]]; then
    echo "Run as root: sudo $0"
    exit 1
fi

if systemctl is-active --quiet "$SERVICE_NAME"; then
    systemctl stop "$SERVICE_NAME"
    echo "Stopped $SERVICE_NAME."
fi

if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
    systemctl disable "$SERVICE_NAME"
    echo "Disabled $SERVICE_NAME."
fi

if [[ -f "$SERVICE_FILE" ]]; then
    rm "$SERVICE_FILE"
    systemctl daemon-reload
    echo "Removed $SERVICE_FILE."
fi

if [[ -d "$INSTALL_DIR" ]]; then
    rm -rf "$INSTALL_DIR"
    echo "Removed $INSTALL_DIR."
fi

echo "Done. Web server fully removed."
