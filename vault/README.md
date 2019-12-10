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

----
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

-----
### Dynamic Secrets
- Deploy using Terraform
- Validate can connect to RDS by using MySQL Workbench
- SSH to AWS instance
- Execute
```
export VAULT_ADDR=http://0.0.0.0:8200
export VAULT_TOKEN=root
cd /
# Validate license ok
./vault read sys/license

# Mount secret engine
./vault secrets enable database

# Configure MySQL connection
./vault write database/config/mysql \
    plugin_name=mysql-legacy-database-plugin \
    connection_url="vault:VAULT_RDS_PASSWORD_HERE@tcp(RDS_ENDPOINT_WITH_PORT_HERE)/" \
    allowed_roles=*

./vault write database/config/mysql \
    plugin_name=mysql-legacy-database-plugin \
    connection_url="vault:FpC2JbAr8ZaecVxx@tcp(terraform-20191209185922959300000001.cd2ntnfz8tii.us-east-1.rds.amazonaws.com:3306)/" \
    allowed_roles=*

    

# Create role
./vault write database/roles/super \
    db_name=mysql \
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';" \
    default_ttl="2m" \
    max_ttl="24h"

    # Create role
./vault write database/roles/readonly \
    db_name=mysql \
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON Stenio_Vault_PoC.tasks TO '{{name}}'@'%';" \
    default_ttl="2m" \
    max_ttl="24h"
```
On MySQL, create the tables and enter values:
```
use  Stenio_Vault_PoC;

CREATE TABLE IF NOT EXISTS tasks (
    task_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)  ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS locations (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)  ENGINE=INNODB;

INSERT INTO tasks (title, description)
VALUES ('My task 1', 'This is an example task1');
INSERT INTO tasks (title, description)
VALUES ('My task 2', 'This is an example task2');
INSERT INTO tasks (title, description)
VALUES ('My task 3', 'This is an example task3');

INSERT INTO locations (title, description)
VALUES ('Peru', 'This is an example location1');
INSERT INTO tasks (title, description)
VALUES ('Brazil', 'This is an example location2');
INSERT INTO tasks (title, description)
VALUES ('USA', 'This is an example location3');

```
Test Execution
```
# Create dynamic creds with readonly role
vault read database/creds/readonly

# Validate use this user for connecting to DB (remember to specify schema "Stenio_Vault_PoC")
select * from tasks
# Ok

select * from location
# Fails

# Now create a super user
vault read database/creds/super

select * from tasks
# Ok

select * from location
# Ok

# Validate users revoked after 2 minutes

```
-----
### Control Groups

For this test, we will use:
- 3 Users: Andrew (requests secret), Brian and Nico (approves secret)
- Two user groups - "Processors", who will be the users requesting secrets, and "Controllers", the users approving access
- Two secrets: One that can be accessed directly by someone with permission, the other that needs approval to access
- An ACL policy to manage the above permissions

The majority of the following commands will only need to be executed once, when creating the user groups. The process is:
- Create a user with any of the auth methods
- Create an "entity", which is an object in Vault that allows attaching users defined in multiple auth methods
- Create a "group" - for this you need a reference id of the auth method and of the entity

Execute the following:
```
# Install jq app to make operations easier
sudo apt-get install jq

# Create second secret mount and write secrets
vault secrets enable -path EU_GDPR_data kv
vault kv put EU_GDPR_data/UK foo=bar
vault kv put secret/foo bar=baz

# Enable userpass authentication (any auth works)
vault auth enable userpass
USERPASS_ACCESSOR=$(curl -H "X-Vault-Token: ${VAULT_TOKEN}" \
  --request GET http://127.0.0.1:8200/v1/sys/auth | jq -r '.["userpass/"].accessor') 


##################
# Create ACL Policy with Control Group
##################
echo '
path "EU_GDPR_data/*" {
    capabilities = ["read"]
    control_group = {
        factor "Dual Controllers" {
            identity {
                group_names = ["controllers"]
                approvals = 2
            }
        }
    }
}
path "secret/*" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}'| vault policy write gdpr -

##################
# Setup for the role "Processors" - User AndrewK
##################
# Create Andrew K entity
echo '
{
  "name": "andrewkHcorp",
  "metadata": {
    "team": "processors"
  },
  "policies": ["gdpr"]
}' > andrewk-entity.json

ANDREWK_ENTITY_ID=$(curl -H "X-Vault-Token: ${VAULT_TOKEN}" \
   --request POST \
   --data @andrewk-entity.json  http://127.0.0.1:8200/v1/identity/entity | jq -r '.data.id')

___
# Note: You can use curl or the CLI, the above command is the same as
# ANDREWK_ENTITY_ID=$(vault write identity/entity name="andrewkHcorp" policies="gdpr" | jq -r '.data.id')
____

# Configure Entity to allow assigning a user defined with userpass auth method
echo "{
  \"name\": \"andrew\",
  \"canonical_id\": \"$ANDREWK_ENTITY_ID\",
  \"mount_accessor\": \"$USERPASS_ACCESSOR\"
}" > andrewk-userpass-entity-alias.json

# Get Entity Alias id, and create a user group with this entity, and the ACL policy created at the start
ANDREWK_ENTITY_ALIAS_ID=$(curl -H "X-Vault-Token: ${VAULT_TOKEN}" \
   --request POST \
   --data @andrewk-userpass-entity-alias.json  http://127.0.0.1:8200/v1/identity/entity-alias | jq -r '.data.id')

echo "{
  \"name\": \"processors\",
  \"member_entity_ids\": [ \"${ANDREWK_ENTITY_ID}\" ],
  \"policies\": [\"gdpr\"]
}" > processors.json

vault write identity/group @processors.json

##################
# Setup for the role "Controllers" - Users BrianG and Nico
##################
echo '
#For authorization
path "/sys/control-group/authorize" {
    capabilities = ["create", "update"]
}
#admin test
path "*" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}'| vault policy write controllers -

# Create Brian G entity
echo '
{
  "name": "briangHcorp",
  "metadata": {
    "team": "controllers"
  },
  "policies": ["controllers"]
}' > briang-entity.json

BRIANG_ENTITY_ID=$(curl -H "X-Vault-Token: ${VAULT_TOKEN}" \
  --request POST \
  --data @briang-entity.json  http://127.0.0.1:8200/v1/identity/entity | jq -r '.data.id')

# Create entity alias for Brian to the userpass backend
echo "{
  \"name\": \"brian\",
  \"canonical_id\": \"$BRIANG_ENTITY_ID\",
  \"mount_accessor\": \"$USERPASS_ACCESSOR\"
}" > briang-userpass-entity-alias.json

BRIANG_ENTITY_ALIAS_ID=$(curl -H "X-Vault-Token: ${VAULT_TOKEN}" \
  --request POST \
  --data @briang-userpass-entity-alias.json  http://127.0.0.1:8200/v1/identity/entity-alias | jq -r '.data.id')

#Create Nico entity
echo '
{
  "name": "nicoHcorp",
  "metadata": {
    "team": "controllers"
  },
  "policies": ["controllers"]
}' > nico-entity.json

NICO_ENTITY_ID=$(curl -H "X-Vault-Token: ${VAULT_TOKEN}" \
  --request POST \
  --data @nico-entity.json  http://127.0.0.1:8200/v1/identity/entity | jq -r '.data.id')

#Create entity alias for Nico to the userpass backend
echo "{
  \"name\": \"nico\",
  \"canonical_id\": \"$NICO_ENTITY_ID\",
  \"mount_accessor\": \"$USERPASS_ACCESSOR\"
}" > nico-userpass-entity-alias.json

NICO_ENTITY_ALIAS_ID=$(curl -H "X-Vault-Token: ${VAULT_TOKEN}" \
  --request POST \
  --data @nico-userpass-entity-alias.json  http://127.0.0.1:8200/v1/identity/entity-alias | jq -r '.data.id')

echo "{
  \"name\": \"controllers\",
  \"member_entity_ids\": [ \"${BRIANG_ENTITY_ID}\", \"${NICO_ENTITY_ID}\" ],
  \"policies\": [\"controllers\"]
}" > controllers.json

vault write identity/group @controllers.json

##################
# Create Users: AndrewK, BrianG and Nico
##################
vault write auth/userpass/users/andrew password=vault
vault write auth/userpass/users/brian password=vault
vault write auth/userpass/users/nico password=vault


##################
# Example Workflow
##################
#Login as Andrew
# unset VAULT_TOKEN
#$ vault login -method=userpass username=andrew
#
#Read the secret
#$ vault read EU_GDPR_data/UK
#Key                              Value
#---                              -----
#wrapping_token:                  a8ca9e0e-c086-85ae-40da-1b5bd500a873
#wrapping_accessor:               e1a58a15-31cd-ca1d-0c10-7613b24e38f3
#wrapping_token_ttl:              24h
#wrapping_token_creation_time:    2018-03-10 16:08:03 -0600 CST

# Now Login as Brian
#$ vault login -method=userpass username=brian
#$ vault write sys/control-group/authorize accessor=e1a58a15-31cd-ca1d-0c10-7613b24e38f3

# Now Login as Nico
#$ vault login -method=userpass username=nico
#$ vault write sys/control-group/authorize accessor=e1a58a15-31cd-ca1d-0c10-7613b24e38f3

# Switch back to Andrew and try to unwrap the token
#$ vault login -method=userpass username=andrew
#vault unwrap a8ca9e0e-c086-85ae-40da-1b5bd500a873
#Key                 Value
#---                 -----
#refresh_interval    768h
#foo                 bar
```
-----
### AWS Authentication
#### Create Admin User
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

##### Create Client (machine) user and write secret
-	Enable AWS auth method in UI
- Enter AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
-	Create secret and a ACL policy to access secret 
```
vault kv put secret/client1 password=test
echo '
path "secret/*" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}'| vault policy write client1 -

vault write auth/aws/role/dev-role auth_type=ec2 bound_ami_id=ami-000b3a073fc20e415 policies=client1
```
- Configure Vault agent on an AWS Server - check file client_bootstrap_demo.sh
- ssh into the instance, execute
```
vault agent -config=config.hcl
```

Validate output.txt has secret.

This is just for demo purposes, usually the workflow to configure Vault and configure client are independent so everything could be automated.