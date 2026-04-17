#!/bin/bash
set -euo pipefail

RG="my-rg"

if ! az group show --name "$RG" &>/dev/null; then
    echo "Resource group '$RG' not found. Nothing to remove."
    exit 0
fi

echo "==> Deleting resource group '$RG' and all its resources..."
echo "    (this may take a few minutes)"
az group delete \
    --name "$RG" \
    --yes \
    --no-wait

echo "Done. Deletion is running in the background."
echo "Track progress: az group show --name $RG --query properties.provisioningState -o tsv"
