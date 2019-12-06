# Vault PoC

## Description
This demo deploys a Vault server in dev mode in AWS and another in GCP, and opens the required ports for communication.

### Disclaimer
Performance Replication can't be demonstrated in in remote servers in dev mode because it always uses TLS between the Vault clusters, and dev mode generates a certificate locally, for local ip address, without allowing to export.

This page describes the steps to deploy Vault in a real world scenario https://learn.hashicorp.com/vault/operations/ops-deployment-guide

The following section describes how to test Performance Replication where both servers are in a local machine

### Performance Replication

Execute the following commands:


```
# Shortcuts to start the two servers locally, in dev mode
alias vrd='VAULT_UI=true VAULT_REDIRECT_ADDR=http://127.0.0.1:8200 vault server -log-level=trace -dev -dev-root-token-id=root -dev-listen-address=127.0.0.1:8200 -dev-ha -dev-transactional'
alias vrd2="VAULT_UI=true VAULT_REDIRECT_ADDR=http://127.0.0.1:8202 vault server -log-level=trace -dev -dev-root-token-id=root -dev-listen-address=127.0.0.1:8202 -dev-ha -dev-transactional"

# Shortcut to execute command in second server
vault2 () {
  VAULT_ADDR=http://127.0.0.1:8202 ./vault $@
}

# Start the two servers locally, in different terminal windows

vrd
vrd2


# Open the UI of the two servers: 
http://127.0.0.1:8200  
http://127.0.0.1:8202  


# Ensure you have the following environment variables configured
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN=root

# Write the Enterprise license for both servers to avoid timeouts:
vault write sys/license text="LICENSE GOES HERE"
vault2 write sys/license text="LICENSE GOES HERE"

# Performance Replication ca be done through the UI or on terminal:
./vault write -f sys/replication/performance/primary/enable
sleep 10
PRIMARY_PERF_TOKEN=$(./vault write -format=json sys/replication/performance/primary/secondary-token id=vault2 \
  | jq --raw-output '.wrap_info .token' )
vault2 login root
vault2 write sys/replication/performance/secondary/enable token=${PRIMARY_PERF_TOKEN}

# Create a policy, mount or secret and confirm it replicated!
```

## Remote Servers Test
Use environment variables for your credentials:

```
export GOOGLE_CREDENTIALS=$(cat YOUR_GCP_CREDS_FILE.json)
export GOOGLE_PROJECT=stenio-vault-demo
export GOOGLE_REGION=us-east1

export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export AWS_DEFAULT_REGION=
```
And deploy using Terrform. This will create a server in AWS and another in GCP, both in dev mode.

### Sentinel
The root token is the only one that bypasses Sentinel policies, therefore we need to create different users:

### Create Admin user
-	Start Vault
-	Open in Browser http://0.0.0.0:8200
-	Log in as root
-	Create admin policy "admin"
```
path "*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

```
-	Enable userpass auth method
-	Create admin user associated with policy 
```
vault write auth/userpass/users/admin password=gf6iQdeLW4WMZyno policies=admin
```

### Test Sentinel Policies
- Login as Admin through the UI
#### Limit Access by IP
- Create the following Endpoint governing policy:
```
# Limit access by request IP
import "sockaddr"
import "strings"

# We expect requests to come only from our private IP range
cidrcheck = rule {
    sockaddr.is_contained(request.connection.remote_addr, "122.22.3.4/32")
}

main = rule {
    cidrcheck
}
```
- Set enforcement level to "hard-mandatory"
- Set path to "secret/*"
- Try to read/write a secret - it should fail
- Update policy for CIDR 0.0.0.0/0
- Now it should work
#### Limit Access by Day/time
- Another test, create this policy:
```
# Limit access by day/time
import "time"

# We expect requests to only happen during work days (0 for Sunday, 6 for Saturday)
workdays = rule {
    time.now.weekday > 5 and time.now.weekday < 6 
}

# We expect requests to only happen during work hours
workhours = rule {
    time.now.hour > 7 and time.now.hour < 18 
}

main = rule {
    workdays and workhours
}
```
- Set enforcement level to "hard-mandatory"
- Set path to "secret/*"
- Try to read/write a secret - it should fail
- Update policy for "weekday >0...
- Now it should work

Additional examples of Sentinel policies for Vault in https://github.com/hashicorp/vault-guides/tree/master/governance/sentinel



