#!/usr/bin/env bash

sudo apt-get install unzip
curl ${vault_zip_url} -o vault.zip
unzip vault.zip
./vault server \
      -dev \
      -dev-root-token-id=root \
      -dev-listen-address=0.0.0.0:8200\
      -dev-ha \
      -dev-transactional \
       &

export VAULT_ADDR=http://0.0.0.0:8200
export VAULT_TOKEN=root
./vault write sys/license text=${vault_license}

## For the demo we can do the following manually, but this shows how we could automate configuring dynamic secrets

# Authenticate to Vault
#vault auth root

# Mount database backend
#vault mount database

# Configure MySQL connection
#vault write database/config/mysql \
#    plugin_name=mysql-legacy-database-plugin \
#    connection_url="${db_user}:${db_password}@tcp${db_endpoint})/" \
#    allowed_roles="readonly"

# Create MySQL readonly role
#vault write database/roles/readonly \
#    db_name=Stenio_Vault_PoC \
#    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';" \
#    default_ttl="30m" \
#    max_ttl="24h"
