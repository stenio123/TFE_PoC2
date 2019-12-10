#!/usr/bin/env bash

sudo apt-get install unzip
curl ${vault_zip_url} -o vault.zip
unzip vault.zip
sudo cp vault /usr/local/bin/

# Config File for Agent
echo "
pid_file = \"./pidfile\"

vault {
   address = \"http://${vault_url}:8200\"
}

auto_auth {
   method {
      type = \"aws\" 
      config = {
            type =\"ec2\"
            role = \"dev-role\"
            region = \"us-east-1\"
            }
   }

   sink \"file\" {
       config = {
           path = \"vault-token-via-agent\"
       }
   }
}
template {
  source      = \"output.txt.tpl\"
  destination = \"output.txt\"
} " > config.hcl

echo "
Password is:
{{ with secret \"secret/client1\" }}
{{ .Data.data.password }}
{{ end }}" > output.txt.tpl

# vault agent -config=config.hcl