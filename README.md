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
sudo systemctl start azure-demo-server
```

**Uninstall:**

```bash
sudo bash webserver/teardown.sh
```

Or in one shot from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/<your-username>/AzureScripts/main/webserver/teardown.sh | sudo bash
```

The teardown script stops the service, disables it, removes the systemd unit file, and deletes `/opt/azure-demo-server`.

---

### `demo-vm/setup.sh` — Private VM with VNet

Creates a full demo environment from scratch:

| Resource | Value |
|---|---|
| Resource group | `my-rg` |
| VNet | `my-vnet` — `10.4.0.0/16` |
| Subnet1 | `my-subnet1` — `10.4.1.0/24` |
| Subnet2 | `my-subnet2` — `10.4.2.0/24` |
| VM | `my-vm` — Standard_B1s, Ubuntu 22.04 LTS Gen2, private only |

**Requirements:** [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed and logged in (`az login`).

**Run:**

```bash
bash demo-vm/setup.sh                        # deploys to westeurope
LOCATION=northeurope bash demo-vm/setup.sh   # custom location
ADMIN_USER=myuser bash demo-vm/setup.sh      # custom admin username
```

Or in one shot from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/<your-username>/AzureScripts/main/demo-vm/setup.sh | bash
```

SSH keys are generated automatically (`~/.ssh/id_rsa`) if none exist. The VM has no public IP — access it via Azure Bastion or a jump box on the same VNet.

**Teardown** (deletes the entire resource group and everything in it):

```bash
bash demo-vm/teardown.sh
```

Or from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/<your-username>/AzureScripts/main/demo-vm/teardown.sh | bash
```
