# AzureScripts

Utility scripts for Azure VM demo and testing purposes. Clone the repo on a VM and run whichever script you need, or execute a script in one shot directly from GitHub.

## One-shot execution from GitHub

No clone needed — pipe the raw script straight into bash:

```bash
curl -fsSL https://raw.githubusercontent.com/<your-username>/AzureScripts/main/webserver/setup.sh | sudo bash
```

> Make sure port 80 is open in your Azure Network Security Group before running.

To use a custom port (e.g. 8080):

```bash
curl -fsSL https://raw.githubusercontent.com/<your-username>/AzureScripts/main/webserver/setup.sh | sudo bash -s -- 8080
```

## Scripts

### `webserver/setup.sh` — Simple HTTP info page

Sets up a lightweight web server that displays the VM's hostname, internal IP, external IP, and current datetime. Persists across reboots via systemd.

**Requirements:** Python 3 (pre-installed on most Azure VM images), root access.

**Run on the VM:**

```bash
sudo bash webserver/setup.sh          # port 80
sudo bash webserver/setup.sh 8080     # custom port
```

**Manage the service:**

```bash
sudo systemctl status azure-demo-server
sudo systemctl stop azure-demo-server
sudo systemctl disable azure-demo-server
```

**Uninstall:**

```bash
sudo systemctl disable --now azure-demo-server
sudo rm /etc/systemd/system/azure-demo-server.service
sudo rm -rf /opt/azure-demo-server
```
