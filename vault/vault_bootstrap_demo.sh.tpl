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
./vault write sys/license text="${vault_license}"