#!/bin/bash
set -euo pipefail

PORT=${1:-80}
INSTALL_DIR="/opt/azure-demo-server"
SERVICE_NAME="azure-demo-server"

if [[ $EUID -ne 0 ]]; then
    echo "Run as root: sudo $0"
    exit 1
fi

if ! command -v python3 &>/dev/null; then
    echo "Python3 is required but not installed."
    exit 1
fi

mkdir -p "$INSTALL_DIR"

cat > "$INSTALL_DIR/server.py" << 'PYEOF'
#!/usr/bin/env python3
import http.server
import socket
import datetime
import urllib.request
import os

PORT = int(os.environ.get("SERVER_PORT", 80))


def get_internal_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "unavailable"


def get_external_ip():
    # Try Azure instance metadata service first (no internet needed)
    try:
        req = urllib.request.Request(
            "http://169.254.169.254/metadata/instance/network/interface/0"
            "/ipv4/ipAddress/0/publicIpAddress"
            "?api-version=2021-02-01&format=text",
            headers={"Metadata": "true"},
        )
        with urllib.request.urlopen(req, timeout=2) as r:
            ip = r.read().decode().strip()
            if ip:
                return ip
    except Exception:
        pass
    # Fallback: public echo service
    try:
        with urllib.request.urlopen("https://api.ipify.org", timeout=3) as r:
            return r.read().decode().strip()
    except Exception:
        return "unavailable"


HTML = """<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Azure VM</title>
  <style>
    * {{ box-sizing: border-box; margin: 0; padding: 0; }}
    body {{
      font-family: 'Segoe UI', monospace;
      background: #0d1117;
      color: #c9d1d9;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      padding: 40px 0;
    }}
    .card {{
      background: #161b22;
      border: 1px solid #30363d;
      border-radius: 10px;
      padding: 40px 56px;
      min-width: 400px;
      width: 640px;
    }}
    h1 {{ color: #58a6ff; font-size: 1.4rem; margin-bottom: 28px; letter-spacing: 1px; }}
    h2 {{ color: #58a6ff; font-size: 0.95rem; margin: 32px 0 16px; letter-spacing: 1px; text-transform: uppercase; }}
    table {{ width: 100%; border-collapse: collapse; }}
    tr:not(:last-child) td {{ border-bottom: 1px solid #21262d; }}
    td {{ padding: 10px 0; vertical-align: top; }}
    td:first-child {{ color: #8b949e; font-size: 0.85rem; width: 180px; white-space: nowrap; }}
    td:last-child {{ color: #e6edf3; font-weight: 500; padding-left: 16px; word-break: break-all; }}
  </style>
</head>
<body>
  <div class="card">
    <h1>Azure VM</h1>
    <table>
      <tr><td>Hostname</td><td>{hostname}</td></tr>
      <tr><td>Internal IP</td><td>{internal_ip}</td></tr>
      <tr><td>External IP</td><td>{external_ip}</td></tr>
      <tr><td>Date / Time</td><td>{now}</td></tr>
    </table>
    <h2>Request Headers</h2>
    <table>
      {header_rows}
    </table>
  </div>
</body>
</html>"""


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        header_rows = "\n      ".join(
            f"<tr><td>{k}</td><td>{v}</td></tr>"
            for k, v in self.headers.items()
        )
        body = HTML.format(
            hostname=socket.gethostname(),
            internal_ip=get_internal_ip(),
            external_ip=get_external_ip(),
            now=datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            header_rows=header_rows,
        ).encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        pass  # silence access logs; systemd journal captures stderr if needed


if __name__ == "__main__":
    server = http.server.HTTPServer(("", PORT), Handler)
    print(f"Listening on port {PORT}", flush=True)
    server.serve_forever()
PYEOF

chmod +x "$INSTALL_DIR/server.py"

cat > "/etc/systemd/system/$SERVICE_NAME.service" << SVCEOF
[Unit]
Description=Azure Demo Web Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 $INSTALL_DIR/server.py
Environment=SERVER_PORT=$PORT
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl restart "$SERVICE_NAME"

echo ""
echo "Done. Web server is $(systemctl is-active $SERVICE_NAME) on port $PORT."
echo "Check status:  sudo systemctl status $SERVICE_NAME"
echo "Stop server:   sudo systemctl stop $SERVICE_NAME"
echo "Remove:        sudo systemctl disable $SERVICE_NAME && sudo rm /etc/systemd/system/$SERVICE_NAME.service"
