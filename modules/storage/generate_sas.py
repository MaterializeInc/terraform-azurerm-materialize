# #!/usr/bin/env python3

import sys
import json
import datetime
from azure.identity import DefaultAzureCredential
from azure.storage.blob import generate_account_sas, ResourceTypes, AccountSasPermissions
from azure.mgmt.storage import StorageManagementClient
from azure.keyvault.secrets import SecretClient

# Load input variables from Terraform
input_data = json.load(sys.stdin)

STORAGE_ACCOUNT_NAME = input_data["storage_account_name"]
RESOURCE_GROUP = input_data["resource_group"]
KEY_VAULT_NAME = input_data["key_vault_name"]
SAS_SECRET_NAME = input_data["sas_secret_name"]
SAS_EXPIRY_SECRET_NAME = input_data["sas_expiry_secret_name"]
SAS_EXPIRATION_THRESHOLD = 7  # Days before expiry to regenerate SAS

# Authenticate using Managed Identity or Azure CLI login
credential = DefaultAzureCredential()

# Initialize Azure Clients
storage_client = StorageManagementClient(credential, input_data["subscription_id"])
keyvault_client = SecretClient(vault_url=f"https://{KEY_VAULT_NAME}.vault.azure.net/", credential=credential)

# Retrieve Storage Account Key
keys = storage_client.storage_accounts.list_keys(RESOURCE_GROUP, STORAGE_ACCOUNT_NAME)
storage_account_key = keys.keys[0].value  # Primary key

# Retrieve existing SAS token and expiration from Azure Key Vault
try:
    existing_sas_token = keyvault_client.get_secret(SAS_SECRET_NAME).value
    existing_sas_expiry = keyvault_client.get_secret(SAS_EXPIRY_SECRET_NAME).value
except:
    existing_sas_token = ""
    existing_sas_expiry = "2000-01-01T00:00:00Z"  # Default old date

# Convert SAS expiry to a datetime object
try:
    sas_expiry_date = datetime.datetime.strptime(existing_sas_expiry, "%Y-%m-%dT%H:%M:%SZ").astimezone(datetime.timezone.utc)
except ValueError:
    sas_expiry_date = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=1)

# Check if we need to regenerate the SAS token
current_time = datetime.datetime.now(datetime.timezone.utc)
needs_regeneration = (sas_expiry_date - current_time).days < SAS_EXPIRATION_THRESHOLD

if needs_regeneration:
    # Define SAS token expiration (1 year from now)
    expiry_time = current_time + datetime.timedelta(days=365)

    # Generate SAS token using `generate_account_sas`
    sas_token = generate_account_sas(
        account_name=STORAGE_ACCOUNT_NAME,
        account_key=storage_account_key,
        resource_types=ResourceTypes(service=True, container=True, object=True),
        permission=AccountSasPermissions(read=True, write=True, delete=True, list=True, add=True, create=True, update=True, process=True),
        expiry=expiry_time,
        start=current_time - datetime.timedelta(minutes=5),  # Handle clock skew
        protocol="https"
    )

    sas_expiry = expiry_time.strftime("%Y-%m-%dT%H:%M:%SZ")
    # Store the new SAS token in Key Vault
    keyvault_client.set_secret(SAS_SECRET_NAME, sas_token)
    keyvault_client.set_secret(SAS_EXPIRY_SECRET_NAME, sas_expiry)
else:
    # Use the existing SAS token
    sas_token = existing_sas_token
    sas_expiry = existing_sas_expiry

# Output the SAS token and expiration back to Terraform
output = {
    "sas_token": sas_token,
    "sas_expiry": sas_expiry
}
print(json.dumps(output))

