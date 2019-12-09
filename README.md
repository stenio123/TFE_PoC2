# Demos
Code snippets to execute demos/ PoCs

## Terraform
Deploy:
- VPN with public subnet
- 3 ec2 instances, where 2 are private and one is the bastion
- Load balancer to access private instances
- Code snippet in the instances to listen on port 2299
- Security group which only allows traffic for ports 22, 443 and 2299

### Sentinel
You can use the TFE UI, follow instructions here https://www.terraform.io/docs/cloud/sentinel/manage-policies.html
## Vault
- Deploy one Vault in AWS and another in GCP, in demo mode

### Sentinel
You can use the Vault UI, follow instructions here https://www.vaultproject.io/docs/enterprise/sentinel/examples.html