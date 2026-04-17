#!/bin/bash
set -euo pipefail

LOCATION="${LOCATION:-westeurope}"
RG="my-rg"
VNET="my-vnet"
VNET_PREFIX="10.4.0.0/16"
SUBNET1="my-subnet1"
SUBNET1_PREFIX="10.4.1.0/24"
SUBNET2="my-subnet2"
SUBNET2_PREFIX="10.4.2.0/24"
VM_NAME="my-vm"
VM_SIZE="Standard_B1s"
IMAGE="Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest"
ADMIN_USER="${ADMIN_USER:-azureuser}"

echo "==> Creating resource group: $RG ($LOCATION)"
az group create \
    --name "$RG" \
    --location "$LOCATION" \
    --output none

echo "==> Creating VNet: $VNET ($VNET_PREFIX)"
az network vnet create \
    --resource-group "$RG" \
    --name "$VNET" \
    --address-prefixes "$VNET_PREFIX" \
    --output none

echo "==> Creating subnets"
az network vnet subnet create \
    --resource-group "$RG" \
    --vnet-name "$VNET" \
    --name "$SUBNET1" \
    --address-prefixes "$SUBNET1_PREFIX" \
    --output none

az network vnet subnet create \
    --resource-group "$RG" \
    --vnet-name "$VNET" \
    --name "$SUBNET2" \
    --address-prefixes "$SUBNET2_PREFIX" \
    --output none

echo "==> Creating VM: $VM_NAME (private, no public IP)"
az vm create \
    --resource-group "$RG" \
    --name "$VM_NAME" \
    --location "$LOCATION" \
    --size "$VM_SIZE" \
    --image "$IMAGE" \
    --vnet-name "$VNET" \
    --subnet "$SUBNET1" \
    --public-ip-address "" \
    --admin-username "$ADMIN_USER" \
    --generate-ssh-keys \
    --output none

PRIVATE_IP=$(az vm list-ip-addresses \
    --resource-group "$RG" \
    --name "$VM_NAME" \
    --query "[0].virtualMachine.network.privateIpAddresses[0]" \
    --output tsv)

echo ""
echo "Done."
echo ""
echo "  Resource group : $RG"
echo "  VNet           : $VNET ($VNET_PREFIX)"
echo "  Subnet1        : $SUBNET1 ($SUBNET1_PREFIX)"
echo "  Subnet2        : $SUBNET2 ($SUBNET2_PREFIX)"
echo "  VM             : $VM_NAME — $PRIVATE_IP (private only)"
echo "  Admin user     : $ADMIN_USER"
echo ""
echo "Access via Azure Bastion or a jump box on the same VNet."
